unit u_screen_forest_amara;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_sprite_gameforest, u_common_ui, u_gamescreentemplate,
  u_ui_panels, u_gamebackground, u_audio, u_sprite_lr4dir, u_sprite_def,
  u_proceduralcloud;

type

{ TScreenForestAmara }

TScreenForestAmara = class(TGameScreenTemplate)
private type TGameState=(gsUndefined=0, gsRunning, gsSorcirellaAppears,
                         gsWaitUntilLRExit, gsReturnToMap);
  var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FMusic: TALSSound;
  FAtlas: TOGLCTextureAtlas;
  texPine, texGrassLarge, texFlower, texRock: PTexture;
  FAmara: TAmara;

  FInGamePanel: TInGamePanel;
  FInGamePausePanel: TInGamePausePanel;
  FFontText: TTexturedFont;

  property GameState: TGameState read FGameState write SetGameState;
private
  FCloudsRenderer: TOGLCCloudsRenderer;
  procedure CreatePine(aCenterX, aBottomY: single; aHeight: integer);
  procedure CreateSky;
  procedure CreateForest;
public
  procedure DefineSubTextures(aAtlas: TAtlas); override;
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;
end;

var ScreenForestAmara: TScreenForestAmara;

implementation

uses Forms, u_mousepointer, u_app, u_sprite_lrcommon, u_utils, u_screen_map,
  u_resourcestring, Math;

type

{ TGameInventory }

TGameInventory = class(TInGameInventoryPanel)
private
public
  Coin: TUICoinCounter;
  Hammer: TUIHammerCounter;
  StormCloud: TUIStormCloudCounter;
  constructor Create;
  procedure AddHammer;
  procedure AddStormCloud;
end;

{ THammerThatGoToTheInventory }

THammerThatGoToTheInventory = class(TSpriteThatGoInInventory)
  constructor Create(UserValue: TUserMessageValue);
end;

{ TStormCloudThatGoToTheInventory }

TStormCloudThatGoToTheInventory = class(TSpriteThatGoInInventory)
  constructor Create(UserValue: TUserMessageValue);
end;

var
  FGameInventory: TGameInventory;
  FLR: TLR4Direction;
  texArrowYellow: PTexture;
  FDirectionnalArrow: TDirectionnalArrow;

// sort the surfaces by Y value
function SortSprite(Item1, Item2: Pointer): Integer;
var o1, o2: TSimpleSurfaceWithEffect;
  y1, y2: integer;
begin
  o1 := TSimpleSurfaceWithEffect(Item1);
  o2 := TSimpleSurfaceWithEffect(Item2);

  if o1 is TBaseComplexContainer then begin
    with TBaseComplexContainer(o1) do y1 := Trunc(Y.Value + DeltaYToBottom)
  end {else if o1 is TPine then begin
    with TPine(o1) do y1 := Trunc(o1.ScaledBottomY)
  end} else y1 := Trunc(o1.ScaledBottomY);

  if o2 is TBaseComplexContainer then begin
    with TBaseComplexContainer(o2) do y2 := Trunc(Y.Value + DeltaYToBottom)
  end {else if o2 is TPine then begin
    with TPine(o2) do y1 := Trunc(o2.ScaledBottomY)
  end} else y2 := Trunc(o2.ScaledBottomY);

  if y1 > y2 then Result := 1
  else if y1 < y2 then Result := -1
  else Result := 0;
end;

{ TStormCloudThatGoToTheInventory }

constructor TStormCloudThatGoToTheInventory.Create(UserValue: TUserMessageValue);
begin
  inherited Create(texIconStormCloud, LAYER_GAMEUI, FLR, FGameinventory, ScreenForestAmara, UserValue);
end;

{ THammerThatGoToTheInventory }

constructor THammerThatGoToTheInventory.Create(UserValue: TUserMessageValue);
begin
  inherited Create(texIconHammer, LAYER_GAMEUI, FLR, FGameinventory, ScreenForestAmara, UserValue);
end;

{ TGameInventory }

constructor TGameInventory.Create;
begin
  inherited Create;
  if PlayerInfo.Forest.Hammer.Owned then begin
    Hammer := TUIHammerCounter.Create;
    AddItem(Hammer);
    Hammer.Count := PlayerInfo.Forest.Hammer.UsesCount;
  end;

  Coin := TUICoinCounter.Create;
  Coin.Count := PlayerInfo.CoinCount;
  AddItem(Coin);
end;

procedure TGameInventory.AddHammer;
begin
  Hammer := TUIHammerCounter.Create;
  AddItem(Hammer);
  Hammer.Count := PlayerInfo.Forest.Hammer.UsesCount;
end;

procedure TGameInventory.AddStormCloud;
begin
  StormCloud := TUIStormCloudCounter.Create;
  AddItem(StormCloud);
  StormCloud.Count := PlayerInfo.Forest.StormCloud.UsesCount;
end;


{ TScreenForestAmara }

procedure TScreenForestAmara.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then Exit;
  FGameState := AValue;
  case GameState of
    gsSorcirellaAppears: PostMessage(100);
    gsReturnToMap: PostMessage(400);
  end;
end;

procedure TScreenForestAmara.CreatePine(aCenterX, aBottomY: single;
  aHeight: integer);
var o: TSprite;
  sw, sh, v: single;
begin
  o := FScene.AddSprite(texPine, False, LAYER_GROUND);

  sh := aHeight/texPine^.FrameHeight;
  sw := sh + Random*0.25*sh-0.125*sh;
  o.Scale.Value := PointF(sw, sh);
  o.CenterX := aCenterX;
  o.ScaledBottomY := aBottomY;

  v := 1.0 - EnsureRange((o.ScaledBottomY-FScene.Height*0.5)/(FScene.Height*0.20) , 0.0, 1.0);
  o.Tint.Value := BGRA(0,0,0, Round(v*255));
end;

procedure TScreenForestAmara.CreateSky;
const CLOUDS_PRESET =
          'Color|r,255,g,255,b,255,a,255|Fragmentation|2.0000|Transformation|0.0700|Relief|'+
          'false|Density|0.0700|TranslationSpeed|-0.0100|ThresholdTop|0.4651|ThresholdBotto'+
          'm|0.0851|ThresholdRight|0.0001|ThresholdLeft|0.0001';
var sky: TQuad4Color;
  clouds: TOGLCSpriteClouds;
begin
  sky := TQuad4Color.Create(FScene);
  sky.SetSize(FScene.Width, ScaleH(422));
  sky.SetTopColors(BGRA(110,142,255));
  sky.SetBottomColors(BGRA(13,31,178));
  FScene.Add(sky, LAYER_BG3);

  FCloudsRenderer := TOGLCCloudsRenderer.Create(FScene, True);

  clouds := TOGLCSpriteClouds.Create(FScene, FCloudsRenderer);
  clouds.SetSize(FScene.Width, ScaleH(422));
  FScene.Add(clouds, LAYER_BG3);
  clouds.LoadParamsFromString(CLOUDS_PRESET);
end;

procedure TScreenForestAmara.CreateForest;
var gradient: TGradientRectangle;
  sprite: TSprite;
  xx, yy: single;
  g: TGrassLarge;
begin
  // green ground
  gradient := TGradientRectangle.Create(FScene);
  FScene.Add(gradient, LAYER_BG3);
  gradient.Gradient.CreateVertical([BGRA(3,53,0), BGRA(19,127,12), BGRA(19,127,0)], [0, 0.5, 1]);
  gradient.SetSize(FScene.Width, ScaleH(346));
  gradient.SetCoordinate(0, ScaleH(423));

  // grass
  yy := ScaleH(445);       //ScaleH(508);
  repeat
    xx :=-ScaleW(10)-Random*texGrassLarge^.FrameWidth*0.25;
    repeat
      g := TGrassLarge.Create(texGrassLarge, xx, yy, LAYER_GROUND);
      g.Amplitude.X.Value := 0.4;
      g.DeformationSpeed.Value := PointF(1.2, 0);
      g.Tint.Value := BGRA(32,64,0,Random(100)+155);
      g.Opacity.Value := Random(100)+155;
      g.Opacity.Value := Round(g.Opacity.Value*(1-EnsureRange((ScaleH(508)-yy)/(ScaleH(508)-ScaleH(445)), 0,1)));
      xx := xx + texGrassLarge^.FrameWidth - Random*texGrassLarge^.FrameWidth*0.25;
    until xx > FScene.Width+texGrassLarge^.FrameWidth*0.25;
    yy := yy + texGrassLarge^.FrameHeight*0.6;
  until yy > FScene.Height;

  // flowers left
  TFlower.Create(texFlower, ScaleW(143), ScaleH(705), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(186), ScaleH(697), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(216), ScaleH(689), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(238), ScaleH(707), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(262), ScaleH(690), LAYER_GROUND);
  // flowers right
  TFlower.Create(texFlower, ScaleW(718), ScaleH(683), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(749), ScaleH(700), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(810), ScaleH(682), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(837), ScaleH(658), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(845), ScaleH(700), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(879), ScaleH(673), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(900), ScaleH(709), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(925), ScaleH(686), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(945), ScaleH(715), LAYER_GROUND);

  // rocks
  sprite := FScene.AddSprite(texRock, False, LAYER_GROUND);
  sprite.SetCoordinate(ScaleW(63), ScaleH(602));
  sprite := FScene.AddSprite(texRock, False, LAYER_GROUND);
  sprite.SetCoordinate(ScaleW(923), ScaleH(631));
  // pines
  CreatePine(ScaleW(41), ScaleH(533), 281);
  CreatePine(ScaleW(104), ScaleH(585), 309);
  CreatePine(ScaleW(154), ScaleH(514), 323);
  CreatePine(ScaleW(198), ScaleH(484), 161);
  CreatePine(ScaleW(246), ScaleH(566), 309);
  CreatePine(ScaleW(328), ScaleH(506), 231);
  CreatePine(ScaleW(394), ScaleH(522), 300);
  CreatePine(ScaleW(437), ScaleH(488), 111);
  CreatePine(ScaleW(467), ScaleH(465), 69);
  CreatePine(ScaleW(495), ScaleH(461), 111);
  CreatePine(ScaleW(541), ScaleH(517), 291);
  CreatePine(ScaleW(592), ScaleH(482), 161);
  CreatePine(ScaleW(635), ScaleH(528), 304);
  CreatePine(ScaleW(665), ScaleH(487), 109);
  CreatePine(ScaleW(698), ScaleH(572), 354);
  CreatePine(ScaleW(767), ScaleH(494), 161);
  CreatePine(ScaleW(833), ScaleH(510), 281);
  CreatePine(ScaleW(864), ScaleH(596), 309);
  CreatePine(ScaleW(962), ScaleH(531), 328);
  CreatePine(ScaleW(990), ScaleH(580), 245);

end;

procedure TScreenForestAmara.DefineSubTextures(aAtlas: TAtlas);
begin
end;

procedure TScreenForestAmara.CreateObjects;
var ima: TBGRABitmap;
  path: string;
  h: Integer;
begin
  FGameState := gsUndefined;
  Audio.PauseMusicTitleMap;

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  AdditionnalScale := 1.0;
  LoadLR4DirTextures(FAtlas, False);
  path := SpriteBGFolder;
  texPine := FAtlas.AddFromSVG(SpriteBGFolder+'TreePine.svg', ScaleW(234), -1);
  texGrassLarge := FAtlas.AddFromSVG(path+'GrassLarge.svg', ScaleW(212), -1);
  texFlower := FAtlas.AddFromSVG(path+'Flower1.svg', ScaleW(31), -1);
  texRock := FAtlas.AddFromSVG(path+'Rock1.svg', ScaleW(229), -1);
  TAmara.LoadTexture(FAtlas);
  AddCrossParticleToAtlas(FAtlas);

  CreateGameFontNumber(FAtlas);
  LoadCoinTexture(FAtlas);
  h := IconHeight;
  texIconHammer := FAtlas.AddFromSVG(SpriteCommonFolder+'HammerHead.svg', -1, h);
  texIconStormCloud := FAtlas.AddFromSVG(SpriteCommonFolder+'StormCloud.svg', -1, h);
  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);
  LoadGameDialogTextures(FAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(FAtlas);
  texArrowYellow := FAtlas.AddFromSVG(SpriteUIFolder+'ArrowYellow.svg', ScaleW(40), -1);
  LoadMousePointerTexture(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;
  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  CreateSky;
  CreateForest;

  // sort the layer LAYER_GROUND to have the right ZOrder according BottomY coordinate of the surfaces.
  FScene.Layer[LAYER_GROUND].OnSortCompare := @SortSprite;

  // directionnal arrow
  FDirectionnalArrow := TDirectionnalArrow.Create(d4Right, texArrowYellow, LAYER_ARROW);
  FDirectionnalArrow.SetCoordinate(ScaleW(850), ScaleH(460));
  FDirectionnalArrow.Hide;

  // LR 4 direction
  FLR := TLR4Direction.Create;
  FLR.TimeMultiplicator := 0.7; // accelerate a little bit LR moves.
  FLR.X.Value := FLR.BodyWidth;
  FLR.BodyBottomY := ScaleH(658);
  FLR.SetWindSpeed(0.5);
  FLR.SetFaceType(lrfSmile);
  FLR.IdleRight;
  FLR.MoveToLayer(LAYER_GROUND);

  // amara
  FAmara := TAmara.Create(LAYER_GROUND);

  // In game inventory panel
  FGameInventory := TGameInventory.Create;

  // pause panel
  FInGamePausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  GameState := gsRunning;

  CustomizeMousePointer(False);
end;

procedure TScreenForestAmara.FreeObjects;
begin
  FreeMousePointer;
  FCloudsRenderer.Free;
  FCloudsRenderer := NIL;
  if FScene.RequestedScreen = ScreenMap then
    Audio.ResumeMusicTitleMap;


  FScene.ClearAllLayer;
  FAtlas.Free;
  ResetSceneCallbacks;
end;

procedure TScreenForestAmara.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // ANIM sorcirella appears from the forest
    100: begin
      FLR.IdleUp;
      FLR.ShowQuestionMark;
      FAmara.StartAnimComesFromTheForest;
      PostMessage(105);
      PostMessage(102, 2.0);
    end;
    102: FLR.HideMark;
    105: if FAmara.AnimComesFromTheForestIsDone then PostMessage(110)
      else PostMessage(105);
    110: begin
      FLR.IdleRight;
      FLR.SetFaceType(lrfWorry);
      if not PlayerInfo.Forest.Hammer.Owned then begin
        if PlayerInfo.Forest.AmaraHaveAlreadyAskForTheHammer
          then PostMessage(190, 3.0)
          else PostMessage(200, 3.0);
      end else begin
        if PlayerInfo.Forest.AmaraHaveAlreadyAskForTheStormCloud
          then PostMessage(290, 3.0)
          else PostMessage(300, 3.0);
      end;
    end;

    // SHORT DIALOG TO SELL THE HAMMER
    190: FAmara.ShowDialog(sSoHaveYouThoughtAboutHammer, FFontText, Self, 230);
    // DIALOG TO SELL THE HAMMER
    200: FAmara.ShowDialog(sSomethingTellMeYouNeedMyHelp, FFontText, Self, 205);
    205: FLR.ShowDialog(sWhoAreYou, FFontText, Self, 210);
    210: FAmara.ShowDialog(SMyNameIsAmara, FFontText, Self, 215);
    215: FLR.ShowDialog(sINeedToGetThroughThisForest, FFontText, Self, 220);
    220: FAmara.ShowDialog(sThenYouWillHaveToEquipBetter, FFontText, Self, 225);
    225: FAmara.ShowDialog(Format(sProposeHammer, [PlayerInfo.Forest.Hammer.PriceForNextLevel[0].Count]),
                                FFontText, Self, 230);
    230: begin
      PlayerInfo.Forest.AmaraHaveAlreadyAskForTheHammer := True;
      DialogQuestion(Format(sBuyTheHammer, [PlayerInfo.Forest.Hammer.PriceForNextLevel[0].Count]),
                      sYes, sNo, FFontText, Self, 235, 245, FAtlas);
    end;
    235: begin
      Audio.PlayMusicSuccessShort1;
      THammerThatGoToTheInventory.Create(236);
      FGameInventory.Coin.Count := FGameInventory.Coin.Count - PlayerInfo.Forest.Hammer.PriceForNextLevel[0].Count;
      PlayerInfo.Forest.Hammer.IncLevel;
      PlayerInfo.Forest.Hammer.BuyNextLevel;
      FSaveGame.Save;
      PostMessage(239, 2.0);
    end;
    236: FGameInventory.AddHammer;
    239: FAmara.ShowDialog(sSometimeItMissesTheMark, FFontText, Self, 250);
    245: FAmara.ShowDialog(sAsYouWishButIThink, FFontText, Self, 250);

    // ANIM AMARA go away
    250: begin
      FAmara.AnimDisapearsToTheLeft;
      PostMessage(252, 0.6);
    end;
    252: begin
      FLR.IdleLeft;
      FLR.SetWindSpeed(3.0);
      PostMessage(255, 1.5);
    end;
    255: begin
      FLR.SetWindSpeed(0.6);
      FDirectionnalArrow.Show;
      FLR.SetFaceType(lrfSmile);
      GameState := gsWaitUntilLRExit;
    end;

    // SHORT DIALOG TO SELL THE STORM CLOUDS
    290: FAmara.ShowDialog(sSoHaveYouThoughtAboutStormCloud, FFontText, Self, 325);

    // DIALOG TO SELL THE STORM CLOUDS
    300: FAmara.ShowDialog(sWellDoneYouAreMakingGood, FFontText, Self, 305);
    305: FAmara.ShowDialog(sIHaveGotSomethingElseThatMightHelp, FFontText, Self, 310);
    310: FLR.ShowDialog(sSoWhyDidYouSellMeTheHammer, FFontText, Self, 315);
    315: FAmara.ShowDialog(sBusinessIsBusiness, FFontText, Self, 320);
    320: FAmara.ShowDialog(Format(sIAmSeriousTheLightning, [PlayerInfo.Forest.StormCloud.PriceForNextLevel[0].Count]), FFontText, Self, 325);
    325: begin
      PlayerInfo.Forest.AmaraHaveAlreadyAskForTheStormCloud := True;
      DialogQuestion(Format(sBuyTheStormCloud, [PlayerInfo.Forest.StormCloud.PriceForNextLevel[0].Count]),
                        sYes, sNo, FFontText, Self, 330, 345, FAtlas);
    end;
    330: begin
      Audio.PlayMusicSuccessShort1;
      TStormCloudThatGoToTheInventory.Create(332);
      FGameInventory.Coin.Count := FGameInventory.Coin.Count - PlayerInfo.Forest.StormCloud.PriceForNextLevel[0].Count;
      PlayerInfo.Forest.StormCloud.IncLevel;
      PlayerInfo.Forest.StormCloud.BuyNextLevel;
      FSaveGame.Save;
      PostMessage(335, 2.0);
    end;
    332: FGameInventory.AddStormCloud;
    335: FAmara.ShowDialog(sItsAGreatDeal, FFontText, Self, 337);
    337: FAmara.ShowDialog(sBecauseYouHaveBoughtItems, FFontText, Self, 338);
    338: FLR.ShowDialog(sUhIAlreadyDid, FFontText, Self, 340);
    340: FAmara.ShowDialog(sWellTmOff, FFontText, Self, 250);
    345: FAmara.ShowDialog(sAsYouWishButIThink, FFontText, Self, 250);

    // return to map
    400: begin
      FLR.WalkHorizontallyTo(FScene.Width+FLR.BodyWidth*5, Self, 99999);
      PostMessage(405, 1.0);
    end;
    405: FScene.RunScreen(ScreenMap);
  end;
end;

procedure TScreenForestAmara.Update(const aElapsedTime: single);
var flagPlayerIdle: Boolean;
begin
  inherited Update(aElapsedTime);

  case FGameState of
    gsRunning, gsWaitUntilLRExit: begin
      flagPlayerIdle := True;

      if Input.LeftPressed and flagPlayerIdle and (FLR.X.Value > FLR.BodyWidth) then begin
        FLR.State := lr4sLeftWalking;
        flagPlayerIdle := False;
      end;

      if Input.RightPressed and flagPlayerIdle then begin
        FLR.State := lr4sRightWalking;
        flagPlayerIdle := False;
      end;

      if flagPlayerIdle then FLR.SetIdlePosition;

      if (GameState = gsRunning) and (FLR.X.Value > ScaleW(380)) then
        GameState := gsSorcirellaAppears;

      if (GameState = gsWaitUntilLRExit) and (FLR.X.Value > FScene.Width-FLR.BodyWidth*2) then
        GameState := gsReturnToMap;

    end;
  end;//case

  // check if player pause the game
  if Input.PausePressed then
    FInGamePausePanel.ShowModal;
end;

end.

