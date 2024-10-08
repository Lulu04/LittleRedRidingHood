unit u_screen_gamevolcanoentrance;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_common_ui, u_gamescreentemplate,
  u_ui_panels, u_sprite_lr4dir, u_sprite_lrcommon, u_audio;

type

{ TScreenGameVolcanoEntrance }

TScreenGameVolcanoEntrance = class(TGameScreenTemplate)
private type TGameState=(gsUndefined=0, gsIdle, gsExaminingDigicode, gsNoiseBehindDoor,
                         gsAfterNoiseBehindDoor, gsLRLost,
                         gsHideBehindTree, gsLRGoesToDigicode, gsDecodingDigicode,
                         gsWalkingToTheCave);
  var FGameState: TGameState;
private
  FsndWind,
  FsndAlarm: TALSSound;
  FInGamePausePanel: TInGamePausePanel;

  FDifficulty: integer;
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
  procedure ProcessCallbackPickUpSomethingWhenBendDown({%H-}aPickUpToTheRight: boolean);
  procedure OpenDoor;
  procedure CloseDoor;
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property Difficulty: integer write FDifficulty;
end;

var ScreenGameVolcanoEntrance: TScreenGameVolcanoEntrance;

implementation
uses Forms, LCLType, u_app, u_sprite_wolf, u_screen_workshop, u_resourcestring,
  u_sprite_def,
  u_screen_map, u_screen_gamevolcanoinner, u_utils;

type

{ TInGameInventoryPanel }

TInGameInventoryPanel = class(TBaseInGamePanel)
  procedure AddPlan;
end;

TManufacturingPlanSprite = class(TSpriteThatGoInInventory)
  constructor Create;
end;

var FAtlas: TOGLCTextureAtlas;
  FFontText: TTexturedFont;
  texBG, texBGMountainLeft, texPineTree,
  texRockForWolf, texWolfCrate,
  texDigicode, texDoorFrame, texDoorLeft, texDoorRight: PTexture;

  FDoorFrame: TSprite;
  FDoorRight, FDoorLeft: TDeformationGrid;
  BDigicode, BPineToHide, BWolfCrate: TImageButton;
  FLR: TLR4Direction;
  FWolf: TWolf;

  FPanelDecodingDigicode: TPanelDecodingDigicode;
  FPosWolfBehindDoor, FPosLRHidden, FPosPlanCrate, FPosWolfPissing: TPointF;
  FTimeAccu: single;

  FInGameinventory: TInGameInventoryPanel;

// compare function to sort sprite by BottomY values, like in rpg.
function LayerPlayerSortCompare(Item1, Item2: Pointer): Integer;
var yBottom1, yBottom2: single;
begin
  if Item1 = Pointer(FLR) then yBottom1 := FLR.GetYBottom else yBottom1 := TSimpleSurfaceWithEffect(Item1).ScaledBottomY;
  if Item2 = Pointer(FLR) then yBottom2 := FLR.GetYBottom else yBottom2 := TSimpleSurfaceWithEffect(Item2).ScaledBottomY;
  Result := Trunc(yBottom1 - yBottom2);
end;

{ TInGameInventoryPanel }

procedure TInGameInventoryPanel.AddPlan;
begin
  AddItem(TUIManufacturerPlan.Create);
end;

{ TManufacturingPlanSprite }

constructor TManufacturingPlanSprite.Create;
var p1, p2: TPointF;
begin
  p1 := FLR.GetXY+PointF(0,-FLR.DeltaYToTop);
  p2 := FInGameinventory.GetXY+PointF(FInGameinventory.Width*0.5, FInGameinventory.Height*0.5);
  inherited Create(texIconManufacturingPlan, LAYER_GAMEUI, p1, p2);
end;

{ TScreenGameVolcanoEntrance }

procedure TScreenGameVolcanoEntrance.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  if Sender = BPineToHide then begin
    BPineToHide.MouseInteractionEnabled := False;
    BDigicode.MouseInteractionEnabled := False;
    FGameState := gsHideBehindTree;
    PostMessage(100); // anim hide behind tree
  end else
  if Sender = BDigicode then begin
    BDigicode.MouseInteractionEnabled := False;
    if PlayerInfo.Volcano.DigicodeDecoder.Owned then begin
      FGameState := gsLRGoesToDigicode;
      PostMessage(350);
    end else begin
      FGameState := gsExaminingDigicode;
      PostMessage(10);
    end;
  end else
  if Sender = BWolfCrate then begin
    BWolfCrate.MouseInteractionEnabled := False;
    PostMessage(200); // anim LR take a plan from the crate
  end;
end;

procedure TScreenGameVolcanoEntrance.ProcessCallbackPickUpSomethingWhenBendDown(aPickUpToTheRight: boolean);
begin
  PostMessage(203);
end;

procedure TScreenGameVolcanoEntrance.OpenDoor;
var snd: TALSSound;
begin
  snd := Audio.AddSound('spaceship-compartment-doorOPEN.ogg');
  snd.Volume.Value := 0.8;
  snd.ApplyEffect(Audio.FXReverbShort);
  snd.SetEffectDryWetVolume(Audio.FXReverbLong, 0.6);
  snd.PlayThenKill(True);

  FDoorLeft.DeformationSpeed.Value := PointF(FScene.Width*0.1, 0);
  FDoorRight.DeformationSpeed.Value := PointF(FScene.Width*0.1, 0);
  FDoorLeft.ApplyDeformation(dtWindingLeft);
  FDoorRight.ApplyDeformation(dtWindingRight);
end;

procedure TScreenGameVolcanoEntrance.CloseDoor;
var snd: TALSSound;
begin
  snd := Audio.AddSound('spaceship-compartment-doorCLOSE.ogg');
  snd.Volume.Value := 0.7;
  snd.ApplyEffect(Audio.FXReverbShort);
  snd.SetEffectDryWetVolume(Audio.FXReverbLong, 0.6);
  snd.PlayThenKill(True);

  FDoorLeft.DeformationSpeed.Value := PointF(-FScene.Width*0.1, 0);
  FDoorRight.DeformationSpeed.Value := PointF(-FScene.Width*0.1, 0);
end;

procedure TScreenGameVolcanoEntrance.CreateObjects;
var path: string;
  ima: TBGRABitmap;
  o: TSprite;
  sky1, sky2: TMultiColorRectangle;
begin
  FGameState := gsUndefined;
  Audio.PauseMusicTitleMap;
  FsndWind := Audio.AddSound('larrun_mountains_medwind.ogg');
  FsndWind.Loop := True;
  FsndWind.Volume.Value := 0.8;
  FsndWind.Play(True);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 1;

  LoadLR4DirTextures(FAtlas, False);
  LoadWolfTextures(FAtlas);
  FAtlas.Add(ParticleFolder+'sphere_particle.png');

  CreateGameFontNumber(FAtlas);
  LoadCoinTexture(FAtlas);
  LoadWatchTexture(FAtlas);
  LoadIconManufacturingPlanTexture(FAtlas);
  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);
  LoadGameDialogTextures(FAtlas);

  path := SpriteGameVolcanoEntranceFolder;
  texBG := FAtlas.AddFromSVG(path+'BG.svg', -1, ScaleH(769));
  texBGMountainLeft := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'BGMountainLeft.svg', ScaleW(350), -1);
  texPineTree := FAtlas.AddFromSVG(SpriteBGFolder+'TreePine.svg', ScaleW(137), -1);
  texRockForWolf := FAtlas.AddFromSVG(path+'RockToHideWolf.svg', ScaleW(68), -1);
  texWolfCrate := FAtlas.AddFromSVG(path+'WolfCrate.svg', ScaleW(47), -1);
  texDigicode := FAtlas.AddFromSVG(path+'Digicode.svg', ScaleW(36), -1);
  texDoorFrame := FAtlas.AddFromSVG(path+'DoorFrame.svg', ScaleW(160), -1);
  texDoorLeft := FAtlas.AddFromSVG(path+'DoorLeft.svg', ScaleW(80), -1);
  texDoorRight := FAtlas.AddFromSVG(path+'DoorRight.svg', ScaleW(80), -1);

  FAtlas.AddScaledPPI(ParticleFolder+'Cloud128x128.png');

  TPanelDecodingDigicode.LoadTextures(FAtlas);

  // load arrow for button panels
  AddBlueArrowToAtlas(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;
  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  // left mountain BG
  o := TSprite.Create(texBGMountainLeft, False);
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(-47), ScaleH(56));

  // sky
  sky1 := TMultiColorRectangle.Create(FScene.Width div 2, (FScene.Height-ScaleH(184)) div 2);
  FScene.Add(sky1, LAYER_BG2);
  sky1.SetTopColors(BGRA(255,255,255,0));
  sky1.SetBottomColors(BGRA(11,166,200));
  sky1.SetCoordinate(0, ScaleH(184));
  sky2 := TMultiColorRectangle.Create(FScene.Width div 2, (FScene.Height-ScaleH(184)) div 2);
  FScene.Add(sky2, LAYER_BG2);
  sky2.SetTopColors(BGRA(11,166,200));
  sky2.SetBottomColors(BGRA(11,166,200));
  sky2.SetCoordinate(0, sky1.BottomY);

  // BG
  o := TSprite.Create(texBG, False);
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(171), ScaleH(-1));

  // fog
  CreateFogRightToLeft(FAtlas, True, 30, 20);

  // door frame
  FDoorFrame := TSprite.Create(texDoorFrame, False);
  FScene.Add(FDoorFrame, LAYER_PLAYER); //LAYER_BG2);
  FDoorFrame.SetCoordinate(ScaleW(578), ScaleH(416));
  // door left
  FDoorLeft := TDeformationGrid.Create(texDoorLeft, False);
  FDoorFrame.AddChild(FDoorLeft, -1);
  FDoorLeft.SetCoordinate(0, 0);
  FDoorLeft.SetGrid(1, 10);
  // door right
  FDoorRight := TDeformationGrid.Create(texDoorRight, False);
  FDoorFrame.AddChild(FDoorRight, -1);
  FDoorRight.SetCoordinate(FDoorRight.Width-1, 0);
  FDoorRight.SetGrid(1, 10);

  // digicode button
  BDigicode := TImageButton.Create(texDigicode);
  FScene.Add(BDigicode, LAYER_GROUND);
  BDigicode.SetCoordinate(ScaleW(747), ScaleH(487));
  BDigicode.OnClick := @ProcessButtonClick;

  // panel decoding digicode
  FPanelDecodingDigicode := TPanelDecodingDigicode.Create;

  // wolf crate
//  FWolfCrate := TImageButton.Create(texWolfCrate);
//  FWolfCrate.SetCoordinate(ScaleW(747), ScaleH(487));
//  FWolfCrate.OnClick := @ProcessButtonClick;

  // rock to hide wolf
  o := TSprite.Create(texRockForWolf, False);
  FScene.Add(o, LAYER_ARROW);
  o.SetCoordinate(ScaleW(222), ScaleH(599));

  // button small pine right
  BPineToHide := TImageButton.Create(texPineTree);
  FScene.Add(BPineToHide, LAYER_PLAYER);
  BPineToHide.SetCoordinate(ScaleW(796), ScaleH(372));
  BPineToHide.OnClick := @ProcessButtonClick;
  BPineToHide.MouseInteractionEnabled := not PlayerInfo.Volcano.HaveDecoderPlan;

  // big pine right
  o := TSprite.Create(texPineTree, False);
  FScene.Add(o, LAYER_PLAYER);
  o.Scale.Value := PointF(1.47, 1.47);
  o.ScaledX := ScaleW(879);
  o.ScaledY := ScaleH(327);

  // install a compare function to sort the sprite in the layer player
  FScene.Layer[LAYER_PLAYER].OnSortCompare := @LayerPlayerSortCompare;

  // LR 4 direction
  FLR := TLR4Direction.Create;
  FLR.SetCoordinate(FScene.Width*0.5, FScene.Height*0.8);
  FLR.SetWindSpeed(0.5);
  FLR.SetFaceType(lrfSmile);
  FLR.IdleRight;
  FLR.CallbackPickUpSomethingWhenBendDown := @ProcessCallbackPickUpSomethingWhenBendDown;
  FLR.TimeMultiplicator := 0.8;

  if not PlayerInfo.Volcano.HaveDecoderPlan then begin
    FWolf := TWolf.Create(False);
    FScene.RemoveSurfaceFromLayer(FWolf, LAYER_WOLF);
    FScene.Add(FWolf, LAYER_PLAYER);
    FWolf.SetCoordinate(ScaleW(665), ScaleH(546));
    FWolf.Atlas := FAtlas;
    FWolf.DialogAuthorName := sWolf;
    FWolf.TimeMultiplicator := 0.8;

    BWolfCrate := TImageButton.Create(texWolfCrate);
    FWolf.SetAsCarryingAnObject(BWolfCrate);
    BWolfCrate.MouseInteractionEnabled := False;
    BWolfCrate.OnClick := @ProcessButtonClick;
  end;

  FPosWolfBehindDoor := PointF(ScaleW(665), ScaleH(546));
  FPosLRHidden := PointF(ScaleW(925), ScaleH(585));
  FPosWolfPissing := PointF(ScaleW(253), ScaleH(629));
  FPosPlanCrate := PointF(ScaleW(400), ScaleH(629));

  if not PlayerInfo.Volcano.HaveDecoderPlan then begin
    PostMessage(50, 1.0);  // message wolf have walled up the cave entrance
    BDigicode.MouseInteractionEnabled := False;
    BPineToHide.MouseInteractionEnabled := False;
  end else if PlayerInfo.Volcano.DigicodeDecoder.Owned then begin
    BDigicode.MouseInteractionEnabled := True;
    BPineToHide.MouseInteractionEnabled := False;
  end else begin
    BDigicode.MouseInteractionEnabled := False;
    BPineToHide.MouseInteractionEnabled := False;
    PostMessage(300);
  end;
  FTimeAccu := 0;

  // in game inventory panel
  FInGameinventory := TInGameInventoryPanel.Create;
  // pause panel
  FInGamePausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  // show how to play (one frame deferred)
  if not (PlayerInfo.Volcano.HaveDecoderPlan and not PlayerInfo.Volcano.DigicodeDecoder.Owned) then
    PostMessage(5);
end;

procedure TScreenGameVolcanoEntrance.FreeObjects;
begin
  Audio.ResumeMusicTitleMap;
  FsndWind.FadeOutThenKill(3.0);
  if FsndAlarm <> NIL then FsndAlarm.FadeOutThenKill(3.0);

  FScene.Layer[LAYER_PLAYER].OnSortCompare := NIL;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
end;

procedure TScreenGameVolcanoEntrance.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // MESS A NOISE BEHIND THE DOOR
    0: begin
      FLR.ShowDialog(sIHaveToHide, FFontText, Self, 1);
    end;
    1: begin
      FGameState := gsAfterNoiseBehindDoor;
    end;

    // show how to play
    5: ShowGameInstructions(PlayerInfo.Volcano.HelpText);

    // MESS EXAMINING DIGICODE
    10: begin
      FLR.ShowDialog(sDamnACodedDoor, FFontText, Self, 11);
    end;
    11: begin
      FGameState := gsIdle;
    end;

    // ANIM wolf catch LR
    20: begin
      BPineToHide.MouseInteractionEnabled := False;
      OpenDoor;
      PostMessage(21, 1);
    end;
    21: begin
      FLR.SetFaceType(lrfNotHappy);
      FWolf.ShowExclamationMark;
      FWolf.Head.SetMouthSurprise;
      PostMessage(22, 0.5);
    end;
    22: begin
      FsndAlarm := Audio.AddSound('alert.ogg');
      FsndAlarm.Volume.Value := 0.6;
      FsndAlarm.Loop := True;
      FsndAlarm.Play(True);
      PostMessage(23, 2.5);
    end;
    23: begin
      FScene.RunScreen(ScreenMap);
    end;

    50: begin
      FLR.ShowDialog(sWolveHaveWalledUpCaveEntrance, FFontText, Self, 51);
    end;
    51: begin
      BDigicode.MouseInteractionEnabled := True;
      BPineToHide.MouseInteractionEnabled := True;
      FGameState := gsIdle;
    end;

    // ANIM HIDE BEHIND TREE
    100: begin
      FLR.WalkHorizontallyTo(FPosLRHidden.x, Self, 101);
    end;
    101: begin
      FLR.WalkVerticallyTo(FPosLRHidden.y, Self, 102);
    end;
    102: begin
      FLR.State := lr4sLeftIdle;
      PostMessage(103, 0.5);
    end;
    103: begin
      with TInfoPanel.Create(sWolfInTheCave, sAgain, FFontText, Self, 104) do
        SetCenterCoordinate(ScaleW(656), ScaleH(365));
    end;
    104: begin
      with TInfoPanel.Create(sWolfInTheCave, sErIHaveToGo, FFontText, Self, 105) do
        SetCenterCoordinate(ScaleW(656), ScaleH(365));
    end;
    105: begin
      OpenDoor;
      PostMessage(106, 2.0);
    end;
    106: begin
      FWolf.State := wsCarryingIdle;
      FWolf.Y.ChangeTo(FPosWolfPissing.y, 1.5, idcSinusoid);
      FWolf.WalkHorizontallyTo(FPosPlanCrate.x, Self, 107);
    end;
    107: begin  // wolf put object on ground
      FWolf.State := wsPutObjectToGround;
      PostMessage(108);
    end;
    108: begin  // wait the object to be on the ground
      if FWolf.State <> wsIdle then PostMessage(108)
        else PostMessage(109);
    end;
    109: begin
      FWolf.WalkHorizontallyTo(FPosWolfPissing.x, Self, 110);
    end;
    110: begin
      FWolf.State := wsIdle;
      PostMessage(111, 0.5);
    end;
    111: begin
      FWolf.ShowDialog(sThisPlaceIsBeautiful, FFontText, Self, 112);
    end;
    112: begin  // wolf start pissing
      FWolf.State := wsPissing;
      PostMessage(113, 1);
    end;
    113: begin
      with TInfoPanel.Create(sWolfInTheCave, sNotWaiting, FFontText, Self, 114) do
        SetCenterCoordinate(ScaleW(656), ScaleH(365));
    end;
    114: begin
      BWolfCrate.MouseInteractionEnabled := True;
    end;

    // LR TAKE A PLAN FROM THE CRATE
    200: begin
      FLR.SetFaceType(lrfWorry);
      FLR.WalkVerticallyTo(FPosWolfPissing.y+FWolf.DeltaYToBottom, Self, 201);
    end;
    201: begin   // LR go to the left
      FLR.WalkHorizontallyTo(BWolfCrate.RightX+FLR.BodyWidth*0.5, Self, 202);
    end;
    202: begin   // check if LR reach the crate
      FLR.State := lr4sBendDown;
      //PostMessage(203);
    end;
    203: begin
      TInfoPanel.Create('', sYouTakeAPlan, FFontText, Self, 204);
    end;
    204: begin // anim plan goes into inventory
      FInGameinventory.AddPlan;
      Audio.PlayMusicSuccessShort1;
      TManufacturingPlanSprite.Create;
      PostMessage(210, 3);
    end;

    210: begin   // the wolf fart
      FLR.ShowQuestionMark;
      FWolf.State := wsFart;
      PostMessage(211, 2);
    end;
    211: begin
      FLR.HideMark;
      FLR.SetFaceType(lrfVomit);
      PostMessage(212, 3);
    end;
    212: begin
      FLR.State := lr4sBendUp;
      PostMessage(213, 2);
    end;
    213: begin     // walk to the right
      FLR.WalkHorizontallyTo(FPosLRHidden.x, Self, 214);
    end;
    214: begin
      FLR.WalkVerticallyTo(FPosLRHidden.y, Self, 215);
    end;
    215: begin
      FLR.State := lr4sLeftIdle;
      PostMessage(216);
    end;
    216: begin     // wolf stop pissing
      FWolf.State := wsIdle;
      PostMessage(217, 1);
    end;
    217: begin  // wolf walk to the crate
      FWolf.WalkHorizontallyTo(BWolfCrate.X.Value, Self, 218);
    end;
    218: begin   // wolf take the crate
      FWolf.ObjectToCarry := BWolfCrate;
      FWolf.State := wsTakeObjectFromGround; // bug car on enleve une surface d'un layer alors qu'on l'update
      PostMessage(219);
    end;
    219: begin
      if FWolf.State = wsCarryingIdle then begin
        FWolf.WalkHorizontallyTo(FPosWolfBehindDoor.x, Self, 221);  // wolf walk to the right
        PostMessage(220);
      end else PostMessage(219);
    end;
    220: begin  // check if wolf reach 3/4 path to go up
      if FWolf.X.Value >= (FPosWolfBehindDoor.x-FPosPlanCrate.x)*0.75+FPosPlanCrate.x then begin
        FWolf.Y.ChangeTo(FPosWolfBehindDoor.y, 1, idcSinusoid);
      end else PostMessage(220);
    end;
    221: begin
      CloseDoor;
      FWolf.State := wsCarryingIdle;
      PostMessage(222, 1);
    end;
    222: begin   // LR come to scene center
      FLR.WalkVerticallyTo(FPosWolfPissing.y+FWolf.DeltaYToBottom, Self, 223);
    end;
    223: begin
      FLR.WalkHorizontallyTo(FScene.Width*0.5, Self, 224);
    end;
    224: begin
      FLR.IdleDown;
      FLR.ShowDialog(sGoToWorkshopToExaminThePlan, FFontText, Self, 225);
    end;
    225: begin
      PlayerInfo.Volcano.HaveDecoderPlan := True;
      FSaveGame.Save;
      FScene.RunScreen(ScreenWorkShop);
    end;

    // mess sMakeTheDecoderBefore
    300: begin
      FLR.ShowDialog(sMakeTheDecoderBefore, FFontText, Self, 301);
    end;
    301: begin
      FScene.RunScreen(ScreenWorkShop);
    end;

    // LR goes to the digicode to decode it
    350: begin
      FLR.WalkHorizontallyTo(BDigicode.CenterX, Self, 351);
    end;
    351: begin
      //FLR.WalkVerticallyTo(BDigicode.CenterY+FLR.DeltaYToTop*0.75, Self, 352);
      FLR.WalkVerticallyTo(FDoorFrame.BottomY+PPIScale(10)+FLR.DeltaYToBottom, Self, 352);
     // PostMessage(352);
    end;
    352: begin
      FLR.IdleUp;
      PostMessage(353, 0.5);
    end;
    353: begin
      FGameState := gsDecodingDigicode;
      FPanelDecodingDigicode.Show;
    end;

    // LR enter the cave
    400: begin
      FLR.IdleRight;
      OpenDoor;
      PostMessage(401, 0.5);
    end;
    401: begin
      FLR.WalkHorizontallyTo(FDoorFrame.CenterX, Self, 402);
    end;
    402: begin
      FLR.WalkVerticallyTo(FDoorFrame.BottomY-2, Self, 403);
    end;
    403: begin
      FLR.Scale.ChangeTo(PointF(0.7,0.7), 2);
      CloseDoor;
      PostMessage(404, 2);
    end;
    404: begin
      PlayerInfo.Volcano.VolcanoEntranceIsDone := True;
      FSaveGame.Save;
      PlayerInfo.Volcano.StepPlayed := 1;
      FScene.RunScreen(ScreenGameVolcanoInner);
    end;
  end;//case
end;

procedure TScreenGameVolcanoEntrance.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  // check if player pause the game
  if Input.PausePressed then begin
    FInGamePausePanel.ShowModal;
  end;

  case FGameState of
    gsIdle: begin
      FTimeAccu := FTimeAccu + aElapsedTime;
      if FTimeAccu >= 8 then begin
        FGameState := gsNoiseBehindDoor;
        FTimeAccu := 0;
        PostMessage(0);
      end;
    end;

    gsAfterNoiseBehindDoor: begin
      FTimeAccu := FTimeAccu + aElapsedTime;
      if FTimeAccu >= 5 then begin
        FGameState := gsLRLost;
        PostMessage(20);
      end;
    end;

    gsDecodingDigicode: begin
      if FPanelDecodingDigicode.ScanIsDone then begin
        FPanelDecodingDigicode.Hide(True);
        PlayerInfo.Volcano.VolcanoEntranceIsDone := True;
        FSaveGame.Save;
        FGameState := gsWalkingToTheCave;
        PostMessage(400);
      end;
    end;
  end;//case
end;

end.

