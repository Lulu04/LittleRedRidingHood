unit u_screen_gamecastle;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon;

type



{ TScreenWolfCastle }

  TScreenWolfCastle = class(TGameScreenTemplate)
private type TGameState=(gsUndefined, gsRunning);
var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FPausePanel: TInGamePausePanel;

  procedure ResetVariables;
  procedure CreateLevel;
public
  //procedure DefineSubTextures(aAtlas: TAtlas); override;
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenWolfCastle: TScreenWolfCastle;

implementation
uses Forms, u_app, u_mousepointer, u_screen_map, u_utils, u_resourcestring,
  u_sprite_def2, u_sprite_lr4dir, u_sprite_wolf, u_sprite_granny, u_submarine,
  u_transporterwk510, Math;

var FWorldArea, FViewArea: TRectF;

type

TCloud = class(TSprite)
  constructor Create(aX, aY: single);
  procedure Update(const aElapsedTime: single); override;
end;

TMountain = class(TSprite)
  constructor Create(aX, aY: single; aFlipH: boolean);
end;

TPontoon = class(TSprite)
  constructor Create(aX, aY: single; aLayerIndex: integer);
end;

TPalmTree1 = class(TDeformationGrid) // LAYER_BG1
  constructor Create(aX, aY, aScale: single; aFlipH: boolean);
end;
TPalmTree2 = class(TSprite) // LAYER_BG2
  constructor Create(aX, aY: single);
end;


var
  texPontoon, texPontoonPillar, texWave1, texPalmTree1, texPalmTree2, texMountain,
  texSubmarineWaterBorder, texCastle: PTexture;
  FAtlas: TAtlas;
  FFontText: TTexturedFont;
  FSubmarine: TSubmarine;
  FLR: TLR4Direction;
  FMarcus: TWolfMarcus;
  FPenelope: TWolfPenelope;
  TFather: TWolfFather;
  TMother: TWolfMother;
  FGranny: TGranny;
  FTransporter: TTransporterWK510;
  FCamera: TOGLCCamera;

{ TMountain }

constructor TMountain.Create(aX, aY: single; aFlipH: boolean);
begin
  inherited Create(texMountain, False);
  FScene.Add(Self, LAYER_BG2);
  SetCoordinate(aX, aY);
  FlipH := aFlipH;
end;

{ TPalmTree2 }

constructor TPalmTree2.Create(aX, aY: single);
begin
  inherited Create(texPalmTree2, False);
  FScene.Add(Self, LAYER_BG2);
  SetCoordinate(aX, aY);
  with CreateSpriteChild(texPalmTree2, False, -1) do begin
    Scale.Value := PointF(0.8, 0.8);
    ScaledX := -ScaledWidth*0.6;
    ScaledY := (Height-ScaledHeight)*0.5;
    FlipH := True;
  end;
end;

{ TPalmTree1 }

constructor TPalmTree1.Create(aX, aY, aScale: single; aFlipH: boolean);
begin
  inherited Create(texPalmTree1, False);
  FScene.Add(Self, LAYER_BG1);
  Scale.Value := PointF(aScale, aScale);
  ScaledX := aX;
  ScaledY := aY;
  FlipH := aFlipH;
  SetGrid(10, 10);
  Amplitude.Value := PointF(0.6*Random*0.2, 0.6+Random*0.2);
  DeformationSpeed.Value := PointF(0.8+Random*0.2, 0.6+Random*0.3);

  ApplyDeformation(dtBasic); //dtTumultuousWater);      dtBasic
  SetDeformationAmountOnColumn(3, 0);
  SetDeformationAmountOnColumn(4, 0);
  SetDeformationAmountOnColumn(5, 0);
  SetDeformationAmountOnColumn(6, 0);
  SetDeformationAmountOnColumn(7, 0);
  Update(Random);
  Update(Random);
  Update(Random);
end;

{ TPontoon }

constructor TPontoon.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(texPontoon, False);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);

  with CreateSpriteChild(texPontoon, False, 0) do
    SetCoordinate(ScaleW(117), 0);
  with CreateSpriteChild(texPontoon, False, 0) do
    SetCoordinate(ScaleW(117)*2, 0);
  with CreateSpriteChild(texPontoon, False, 0) do
    SetCoordinate(ScaleW(117)*3, 0);

  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(30), ScaleH(56));
  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(242), ScaleH(56));
  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(422), ScaleH(56));

  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(55), ScaleH(6));
  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(264), ScaleH(6));
  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(460), ScaleH(6));
end;

{ TCloud }

constructor TCloud.Create(aX, aY: single);
begin
  inherited create(FAtlas.RetrieveTextureByFileName('Cloud128x128.png'), False);
  FScene.Add(Self, LAYER_BG2);
  SetSize(ScaleW(255), ScaleH(204));
  SetCoordinate(aX, aY-Height*0.156);
  FlipH := Random > 0.5;
  FlipV := Random > 0.5;
  Speed.X.Value := -(FScene.Width*0.01+Random*FScene.Width*0.01);
  Opacity.Value := 150+Random*50;
end;

procedure TCloud.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if RightX <= 0 then X.Value := FScene.Width*4;
end;

{ TScreenWolfCastle }

procedure TScreenWolfCastle.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;
end;

procedure TScreenWolfCastle.ResetVariables;
begin

end;

procedure TScreenWolfCastle.CreateLevel;
var path: TOGLCPath;
  seaSide: TUIPanel;
  sea, sky: TQuad4Color;
  ground: TGradientRectangle;
  xx, yy: single;
  cloud: TCloud;
  o: TSprite;
begin
  FWorldArea := RectF(0, 0, FScene.Width*4, FScene.Height);
  // constrained size for the camera
  FViewArea.Left := FWorldArea.Left + FScene.Width*0.5;
  FViewArea.Top := FWorldArea.Top + FScene.Height*0.5;
  FViewArea.Right := FWorldArea.Right - FScene.Width*0.5;
  FViewArea.Bottom := FWorldArea.Bottom - FScene.Height*0.5;

  // sky   LAYER_BG3
  sky := TQuad4Color.Create(FScene);
  FScene.Add(sky, LAYER_BG3);
  sky.SetSize(FScene.Width*4, FScene.Height-ScaleH(296));
  sky.SetTopColors(BGRA(157,226,252));
  sky.SetBottomColors(BGRA(64,121,212));

  // clouds
  xx := 0;
  while xx < FScene.Width*4 do begin
    yy := Random*ScaleH(102);
    cloud := TCloud.Create(xx, yy);
    xx := xx + cloud.ScaledWidth*0.5 + Random*cloud.ScaledWidth;
  end;

  // sea   LAYER_BG3
  sea := TQuad4Color.Create(FScene);
  FScene.Add(sea, LAYER_BG3);
  sea.SetSize(FScene.Width, ScaleH(296));
  sea.SetTopColors(BGRA(25,83,169));
  sea.SetBottomColors(BGRA(37,154,233));
  sea.Y.Value := sky.BottomY;

  // waves
  TWave1.Create(texWave1, ScaleW(22), ScaleH(714), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(179), ScaleH(727), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(85), ScaleH(680), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(224), ScaleH(686), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(3), ScaleH(656), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(69), ScaleH(624), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(7), ScaleH(574), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(186), ScaleH(569), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(115), ScaleH(538), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(299), ScaleH(550), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(398), ScaleH(536), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(7), ScaleH(518), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(214), ScaleH(511), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(87), ScaleH(496), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(165), ScaleH(484), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(343), ScaleH(492), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(430), ScaleH(480), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(491), ScaleH(505), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(591), ScaleH(492), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(673), ScaleH(501), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(720), ScaleH(478), LAYER_BG3);
  TWave1.Create(texWave1, ScaleW(843), ScaleH(482), LAYER_BG3);

  // sea side   LAYER_BG3
  path := NIL;
  path.ConcatPoints([PointF(ScaleW(0), ScaleH(295)), PointF(ScaleW(3), ScaleH(281)),
                     PointF(ScaleW(14), ScaleH(255)), PointF(ScaleW(26), ScaleH(231)),
                     PointF(ScaleW(43), ScaleH(202)), PointF(ScaleW(64), ScaleH(184)),
                     PointF(ScaleW(105), ScaleH(149)), PointF(ScaleW(153), ScaleH(115)),
                     PointF(ScaleW(217), ScaleH(89)), PointF(ScaleW(256), ScaleH(84)),
                     PointF(ScaleW(318), ScaleH(70)), PointF(ScaleW(384), ScaleH(57)),
                     PointF(ScaleW(479), ScaleH(46)), PointF(ScaleW(547), ScaleH(17)),
                     PointF(ScaleW(612), ScaleH(0)), PointF(ScaleW(612), ScaleH(295)),
                     PointF(ScaleW(0), ScaleH(295))]);
  seaSide := TUIPanel.Create(FScene);
  FScene.Add(seaSide, LAYER_BG3);
  seaSide.BodyShape.SetCustomShape(path, 0.0);
  seaSide.BackGradient.CreateVertical([BGRA(186,163,66), BGRA(206,191,130), BGRA(179,153,60)], [0, 0.5, 1.0]);
  seaSide.SetCoordinate(ScaleW(416), ScaleH(473));
  seaSide.MouseInteractionEnabled := False;

  // ground   LAYER_BG3
  ground := TGradientRectangle.Create(FScene);
  FScene.Add(ground, LAYER_BG3);
  ground.Gradient.CreateVertical([BGRA(186,163,66), BGRA(206,191,130), BGRA(179,153,60)], [0, 0.5, 1.0]);
  ground.SetSize(FScene.Width*3, ScaleH(296));
  ground.SetCoordinate(FScene.Width, sky.BottomY);

  // pontoon LAYER_BG2
  TPontoon.Create(ScaleW(172), ScaleH(593), LAYER_BG1);

  // mountain
  with TMountain.Create(ScaleW(1237), ScaleH(360), False) do
    SetSize(ScaleW(293), ScaleH(134));
  with TMountain.Create(ScaleW(1942), ScaleH(351), False) do
    SetSize(ScaleW(229), ScaleH(132));
  with TMountain.Create(ScaleW(1598), ScaleH(288), False) do
    SetSize(ScaleW(362), ScaleH(210));
  with TMountain.Create(ScaleW(2116), ScaleH(246), True) do
    SetSize(ScaleW(435), ScaleH(252));
  with TMountain.Create(ScaleW(2634), ScaleH(355), False) do
    SetSize(ScaleW(229), ScaleH(132));
  with TMountain.Create(ScaleW(3032), ScaleH(262), True) do
    SetSize(ScaleW(344), ScaleH(249));
  with TMountain.Create(ScaleW(3588), ScaleH(292), False) do
    SetSize(ScaleW(488), ScaleH(211));
  with TMountain.Create(ScaleW(3387), ScaleH(371), False) do
    SetSize(ScaleW(232), ScaleH(134));

  // LAYER_BG2
  TPalmTree2.Create(ScaleW(1521), ScaleH(334));
  TPalmTree2.Create(ScaleW(1993), ScaleH(334));
  TPalmTree2.Create(ScaleW(2379), ScaleH(334));
  TPalmTree2.Create(ScaleW(3034), ScaleH(334));
  TPalmTree2.Create(ScaleW(3688), ScaleH(334));

  // LAYER_BG1
  TPalmTree1.Create(ScaleW(993), ScaleH(414), 0.6, False);
  TPalmTree1.Create(ScaleW(884), ScaleH(389), 0.83, True);
  TPalmTree1.Create(ScaleW(732), ScaleH(384), 1, False);
  TPalmTree1.Create(ScaleW(1102), ScaleH(356), 1, True);
  TPalmTree1.Create(ScaleW(1607), ScaleH(414), 0.569, False);
  TPalmTree1.Create(ScaleW(1687), ScaleH(356), 1, True);
  TPalmTree1.Create(ScaleW(3305), ScaleH(394), 0.77, True);
  TPalmTree1.Create(ScaleW(3142), ScaleH(361), 1, False);

  //castle
  o := FScene.AddSprite(texCastle, False, LAYER_GROUND);
  o.SetCoordinate(ScaleW(2516), ScaleH(157));
end;

procedure TScreenWolfCastle.CreateObjects;
var path: string;
  ima: TBGRABitmap;
  water: TDeformationGrid;
begin
  GameState := gsUndefined;
  Audio.PauseMusicTitleMap(3.0);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  AdditionnalScale := 0.6;
  LoadLR4DirTextures(FAtlas, False);
  LoadGranMaTextures(FAtlas);
  LoadWolfTextures(FAtlas);
  LoadPenelopeTextures(FAtlas);
  LoadMarcusTextures(FAtlas);
  LoadFatherTextures(FAtlas);
  LoadMotherTextures(FAtlas);
  AdditionnalScale := 1.5;
  TSubmarine.LoadTexture(FAtlas, AdditionnalScale);
  AdditionnalScale := 1.0;
  TTransporterWK510.LoadTexture(FAtlas);

  path := FolderSpriteGameMermaidsPort;
  texPontoon := FAtlas.AddFromSVG(path+'WoodenPontoon.svg', ScaleW(157), -1);
  texPontoonPillar := FAtlas.AddFromSVG(path+'WoodenPillar.svg', ScaleW(36), -1);
  texWave1 := FAtlas.AddFromSVG(path+'SeaWave1.svg', ScaleW(81), -1);

  texMountain := FAtlas.AddFromSVG(SpriteBGFolder+'Rock1.svg', ScaleW(362), -1);
  texCastle := FAtlas.AddFromSVG(SpriteBGFolder+'WolfCastle.svg', ScaleW(557), -1);

  path := FolderSpriteWolfCastle;
  texSubmarineWaterBorder := FAtlas.AddFromSVG(path+'SubmarineWaterBorder.svg', ScaleW(266), -1);
  texPalmTree1 := FAtlas.AddFromSVG(path+'PalmTree1.svg', ScaleW(216), -1);
  texPalmTree2 := FAtlas.AddFromSVG(path+'PalmTree2.svg', ScaleW(162), -1);

  AddCloud128x128ParticleToAtlas(FAtlas);
  AddBubbleParticleToAtlas(FAtlas);

  // ui
  CreateGameFontNumber(FAtlas); // < must be first !
  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);
  LoadGameDialogTextures(FAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(FAtlas);
  LoadMousePointerTexture(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;
  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  CreateLevel;

  // submarine
  FSubmarine := TSubmarine.Create(LAYER_BG2);
  FSubmarine.Y.Value :=ScaleH(468);
  FSubmarine.X.Value := -FSubmarine.Width*2;
  FSubmarine.Posture_Idle(0);
  water := TDeformationGrid.Create(texSubmarineWaterBorder, False);
  water.SetChildOf(FSubmarine, 1);
  water.SetCoordinate(FSubmarine.Width*0.08, FSubmarine.Height-water.Height*0.8);
  water.SetGrid(2, 8);
  //water.SetSize(FSubmarine.Width, water.Height);
  water.ApplyDeformation(dtTumultuousWater);
  water.SetDeformationAmountOnRow(2, 0);
  water.SetDeformationAmountOnColumn(0, 0);
  water.SetDeformationAmountOnColumn(8, 0);

  // LR
  FLR := TLR4Direction.Create(-1);

  FMarcus := TWolfMarcus.Create(False, LAYER_WOLF);
  FMarcus.BodyBottomY := ScaleH(619);
  FMarcus.X.Value := ScaleW(3015);
  FMarcus.IdleLeft;

  FPenelope := TWolfPenelope.Create(False, LAYER_WOLF);
  FPenelope.BodyBottomY := ScaleH(636);
  FPenelope.X.Value := ScaleW(2956);
  FPenelope.IdleLeft;

  TFather := TWolfFather.Create(False, LAYER_WOLF);
  TFather.BodyBottomY := ScaleH(614);
  TFather.X.Value := ScaleW(2839);
  TFather.IdleLeft;

  TMother := TWolfMother.Create(False, LAYER_WOLF);
  TMother.BodyBottomY := ScaleH(619);
  TMother.X.Value := ScaleW(2895);
  TMother.IdleLeft;

  FGranny := TGranny.Create(LAYER_WOLF);
  FGranny.BodyBottomY := ScaleH(621);
  FGranny.X.Value := ScaleW(2763);
  FGranny.SetIdlePosition(True);

  // camera
  FCamera := FScene.CreateCamera;
  FCamera.Pivot := PointF(0.5, 1.0); // camera attached to the bottom of the screen
  FCamera.AssignToLayerRange(LAYER_PLAYER, LAYER_BG3);
  FCamera.AutoFollow.Bounds := FViewArea;

  // pause panel
  FPausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  CustomizeMousePointer(False);
  PostMessage(0); // submarine arrival
end;

procedure TScreenWolfCastle.FreeObjects;
begin
  FScene.KillCamera(FCamera);
  if FScene.RequestedScreen = ScreenMap then
    Audio.ResumeMusicTitleMap;

  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
  ChallengeMode := False;
end;

procedure TScreenWolfCastle.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // submarine arrival
    0: begin  // lr is in the cockpit
      FLR.SetChildOf(FSubmarine, -1);
      FLR.Scale.Value := PointF(0.9, 0.9);
      FLR.BodyBottomY := FLR.BodyHeight*1.1;
      FLR.X.Value := FSubMarine.Width*0.75;
      FLR.IdleLeft;
      FSubmarine.X.ChangeTo(ScaleW(201), 10.0, idcSinusoid);
      FSubmarine.StartFloating;
      PostMessage(5, 10.0);
    end;
    5: begin
      PostMessage(10, 1.5);
    end;
    10: begin
      FSubmarine.Posture_OpenDoor(1.0);
      PostMessage(15, 1.5);
    end;
    15: FLR.WalkHorizontallyTo(FSubmarine.Width*0.5, Self, 20);
    20: begin
      FLR.Speed.Value := PointF(0, 0);
      FLR.IdleDown;
      FLR.MoveToLayer(LAYER_PLAYER);
      FLR.Scale.ChangeTo(PointF(1, 1), 1.0);
      FLR.WalkVerticallyTo(ScaleH(633), Self, 25);
    end;
    25: begin
      FLR.IdleRight;
      PostMessage(30, 1.0);
    end;
    30: FLR.ShowDialog(sImFinallyOnTheIsland, FFontText, Self, 35);
    35: FLR.ShowDialog(sLetsGoToTheCastle, FFontText, Self, 40);
    40: begin
      FLR.TimeMultiplicator := 0.6;
      FLR.JumpDeltaX := FScene.Width*0.115;
      FCamera.AutoFollow.SetTargetSurface(FLR, False);
      GameState := gsRunning;
    end;
  end;
end;

procedure TScreenWolfCastle.Update(const aElapsedTime: single);
var
  flagPlayerIdle: Boolean;
begin
  inherited Update(aElapsedTime);
  case GameState of
    gsRunning: begin
      flagPlayerIdle := True;
      if Input.LeftPressed and flagPlayerIdle and (FLR.X.Value > ScaleW(245)) then begin
        FLR.State := lr4sLeftWalking;
        flagPlayerIdle := False;
      end;

      if Input.RightPressed and flagPlayerIdle then begin
        FLR.State := lr4sRightWalking;
        flagPlayerIdle := False;
      end;

      if flagPlayerIdle then FLR.SetIdlePosition;

      //if FLR.X.Value > ScaleW(245) then FLR.X.Value := ScaleW(245);

    end;
  end;

  // check if player pause the game
  if Input.PausePressed then
    FPausePanel.ShowModal;
end;

end.

