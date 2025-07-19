unit u_screen_gamecastle;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes, BGRAPath,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon,
  u_proceduralcloud, u_ProceduralPlanet, u_procedural_starnest;

type



{ TScreenWolfCastle }

  TScreenWolfCastle = class(TGameScreenTemplate)
private type TGameState=(gsUndefined, gsRunning, gsStartCinematic);
var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FPausePanel: TInGamePausePanel;
  FArrivalCount: integer;
  FCloudsRenderer: TOGLCCloudsRenderer;
  FClouds: TOGLCSpriteClouds;
  FCloudsDensity: TFParam;
  FSkyHigh: TQuad4Color;
  FsndSeaSideAmbiance, FsndTropicalBird,
  FsndMusic, FsndMainPropulsor, FsndEngineIdle: TALSSound;

  FPlanetRenderer: TOGLCPlanetRenderer;
  FHearth, FMoon: TOGLCSpritePlanet;

  FStarRenderer: TStarNestRenderer;
  FStars: TStarNest;

  procedure ResetVariables;
  procedure CreateLevel;
  procedure SetSkyHighColorTo(aCol: TBGRAPixel; aDuration: single);
  procedure ToggleViewFromSpace;
  procedure KillSeaWaves;
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
  u_sprite_def2, u_sprite_lr4dir, u_sprite_wolf, u_sprite_granny,
  u_screen_gameinspace, u_submarine, u_transporterwk510, u_robotw7,
  u_wolfmothership, Math;

var FWorldArea, FViewArea: TRectF;

const CLOUDS_PRESET =
          'Color|r,255,g,255,b,255,a,255|Fragmentation|3.6000|Transformation|0.0000|Relief|'+
          'false|Density|0.5900|TranslationSpeed|-1.0000|ThresholdTop|0.0001|ThresholdBotto'+
          'm|0.0001|ThresholdRight|0.0001|ThresholdLeft|0.0001';
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
  texPontoon, texPontoonPillar, texWave1, texPalmTree1, texPalmTree2, texRock2, texMountain,
  texCastle, texShipFrontView, texTransporterWhole: PTexture;
  FAtlas: TAtlas;
  FFontText: TTexturedFont;
  FSubmarine: TSubmarine;
  FLR: TLR4Direction;
  FMarcus: TWolfMarcus;
  FPenelope: TWolfPenelope;
  FFather: TWolfFather;
  FMother: TWolfMother;
  FGranny: TGranny;
  FW7: TRobotW74Direction;
  FTransporter: TTransporterWK510;
  FCamera, FCameraInSpace: TOGLCCamera;
  FCastle: TSprite;
  FShipFrontView: TSprite;
  FMotherShip: TMotherShip;
  FTransporterWhole: TSprite;

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
var i: integer;
begin
  inherited Create(texPontoon, False);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);

  for i:=1 to 6 do
    with CreateSpriteChild(texPontoon, False, 0) do
      SetCoordinate(aX+ScaleW(117)*i, 0);

  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(73), ScaleH(56));
  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(281), ScaleH(56));
  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(493), ScaleH(56));
  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(673), ScaleH(56));

  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(109), ScaleH(6));
  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(316), ScaleH(6));
  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(529), ScaleH(6));
  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(709), ScaleH(6));
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

  if RightX <= 0 then X.Value := FWorldArea.Right;
end;

{ TScreenWolfCastle }

procedure TScreenWolfCastle.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;
  case AValue of
    gsStartCinematic: PostMessage(100);
  end;
end;

procedure TScreenWolfCastle.ResetVariables;
begin
  FCloudsRenderer := NIL;
  FClouds := NIL;
end;

procedure TScreenWolfCastle.CreateLevel;
var path: TOGLCPath;
  seaSide: TUIPanel;
  sea, sky, groundSeaside: TQuad4Color;
  ground: TGradientRectangle;
  xx, yy: single;
  cloud: TCloud;
begin
  FWorldArea := RectF(0, -FScene.Height*3, FScene.Width*5, FScene.Height);
  // constrained size for the camera
  FViewArea.Left := FWorldArea.Left + FScene.Width*0.5;
  FViewArea.Top := FWorldArea.Top + FScene.Height*0.5;
  FViewArea.Right := FWorldArea.Right - FScene.Width*0.5;
  FViewArea.Bottom := FWorldArea.Bottom - FScene.Height*0.5;

  // sky (high part)  LAYER_BG3
  FSkyHigh := TQuad4Color.Create(FScene);
  FScene.Add(FSkyHigh, LAYER_BG3);
  FSkyHigh.SetCoordinate(0, -FScene.Height*3);
  FSkyHigh.SetAllColorsTo(BGRA(58,134,255));
  FSkyHigh.SetSize(FScene.Width*5, FScene.Height*3);

  // sky   LAYER_BG3
  sky := TQuad4Color.Create(FScene);
  FScene.Add(sky, LAYER_BG3);
  sky.SetSize(FScene.Width*5, FScene.Height-ScaleH(296));
  sky.SetTopColors(BGRA(58,134,255));
  sky.SetBottomColors(BGRA(157,226,252));

  // clouds   LAYER_BG2
  xx := 0;
  while xx < FWorldArea.Right do begin
    yy := Random*ScaleH(102)-ScaleH(102);
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

  // ground seaside  LAYER_BG3
  groundSeaside := TQuad4Color.Create(FScene);
  FScene.Add(groundSeaside, LAYER_BG3);
  groundSeaside.SetSize(ScaleW(527), ScaleH(136));
  groundSeaside.SetCoordinate(0, ScaleH(632));
  groundSeaside.SetTopColors(BGRA(202,186,121));
  groundSeaside.SetBottomColors(BGRA(179,153,60));


  // ground   LAYER_BG3
  ground := TGradientRectangle.Create(FScene);
  FScene.Add(ground, LAYER_BG3);
  ground.Gradient.CreateVertical([BGRA(186,163,66), BGRA(206,191,130), BGRA(179,153,60)], [0, 0.5, 1.0]);
  ground.SetSize(FScene.Width*4, ScaleH(296));
  ground.SetCoordinate(FScene.Width, sky.BottomY);

  // pontoon LAYER_BG2
  TPontoon.Create(ScaleW(-61), ScaleH(593), LAYER_BG1);

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
  TPalmTree2.Create(ScaleW(2854), ScaleH(334));
  TPalmTree2.Create(ScaleW(3687), ScaleH(334));
  TPalmTree2.Create(ScaleW(4104), ScaleH(334));
  TPalmTree2.Create(ScaleW(4710), ScaleH(334));

  // rock2    LAYER_BG2 or  LAYER_GROUND
  TResizedSprite.Create(texRock2, 1054, 480, 136, 54, LAYER_BG2);
  TResizedSprite.Create(texRock2, 1347, 535, 74, 29, LAYER_BG2);
  with TResizedSprite.Create(texRock2, 1452, 524, 74, 29, LAYER_BG2) do FlipH := True;
  with TResizedSprite.Create(texRock2, 1638, 555, 126, 49, LAYER_GROUND) do FlipH := True;
  TResizedSprite.Create(texRock2, 1833, 496, 63, 24, LAYER_BG2);
  with TResizedSprite.Create(texRock2, 2247, 543, 103, 40, LAYER_BG2) do FlipH := True;
  TResizedSprite.Create(texRock2, 2549, 539, 110, 42, LAYER_BG2);
  TResizedSprite.Create(texRock2, 2726, 497, 62, 24, LAYER_BG2);
  with TResizedSprite.Create(texRock2, 3815, 531, 102, 40, LAYER_BG2) do FlipH := True;
  with TResizedSprite.Create(texRock2, 4032, 549, 75, 29, LAYER_BG2) do FlipH := True;
  TResizedSprite.Create(texRock2, 3962, 554, 110, 42, LAYER_BG2);
  TResizedSprite.Create(texRock2, 4509, 587, 102, 40, LAYER_BG2);

  // LAYER_BG1
  TPalmTree1.Create(ScaleW(993), ScaleH(414), 0.6, False);
  TPalmTree1.Create(ScaleW(884), ScaleH(389), 0.83, True);
  TPalmTree1.Create(ScaleW(732), ScaleH(384), 1, False);
  TPalmTree1.Create(ScaleW(1102), ScaleH(356), 1, True);
  TPalmTree1.Create(ScaleW(1607), ScaleH(414), 0.569, False);
  TPalmTree1.Create(ScaleW(1687), ScaleH(356), 1, True);
  TPalmTree1.Create(ScaleW(2008), ScaleH(388), 0.85, True);
  TPalmTree1.Create(ScaleW(2589), ScaleH(413), 0.77, False);
  TPalmTree1.Create(ScaleW(2426), ScaleH(381), 1.0, True);
  TPalmTree1.Create(ScaleW(4289), ScaleH(414), 0.57, False);
  TPalmTree1.Create(ScaleW(4180), ScaleH(389), 0.85, True);
  TPalmTree1.Create(ScaleW(4028), ScaleH(384), 1.0, False);
  TPalmTree1.Create(ScaleW(4398), ScaleH(356), 0.57, True);


  //castle
  FCastle := FScene.AddSprite(texCastle, False, LAYER_GROUND);
  FCastle.SetCoordinate(ScaleW(3034), ScaleH(157));

   // clouds (atmospher)
  FCloudsRenderer := TOGLCCloudsRenderer.Create(FScene, True);
  FClouds := TOGLCSpriteClouds.Create(FScene, FCloudsRenderer);
  FScene.Add(FClouds, LAYER_FXANIM);
  FClouds.SetCoordinate(ScaleW(2948), 0);
  FClouds.LoadParamsFromString(CLOUDS_PRESET);
  FClouds.Visible := False;
  FCloudsDensity := TFParam.Create;

  // hearth planet  LAYER_ARROW
  FPlanetRenderer := TOGLCPlanetRenderer.Create(FScene, True);
  FMoon := TOGLCSpritePlanet.Create(FScene, FPlanetRenderer);
  FScene.Add(FMoon, LAYER_ARROW);
  FMoon.LoadParamsFromString(PLANET_PINKY_MOON);
  FMoon.SetSize(ScaleW(85), ScaleW(85));
  FMoon.SetCoordinate(ScaleW(109), ScaleH(297));
  FMoon.Visible := False;

  FHearth := TOGLCSpritePlanet.Create(FScene, FPlanetRenderer);
  FScene.Add(FHearth, LAYER_ARROW);
  FHearth.LoadParamsFromString(PLANET_HEARTH);
  FHearth.SetSize(ScaleW(454), ScaleW(454));
  FHearth.SetCoordinate(ScaleW(260), ScaleH(10));
  FHearth.Visible := False;
  // ship front view
  FShipFrontView := TSprite.Create(texShipFrontView, False);
  FScene.Add(FShipFrontView, LAYER_ARROW);
  FShipFrontView.Pivot := PointF(0, 0);
  FShipFrontView.SetCoordinate(ScaleW(371), ScaleH(331));
  FShipFrontView.Visible := False;
  // LAYER_ARROW is not yet visible
  FScene.Layer[LAYER_ARROW].Visible := False;

  // stars
  FStarRenderer := TStarNestRenderer.Create(FScene, True);
  FStars := TStarNest.Create(FScene, FStarRenderer);
  FScene.Add(FStars, LAYER_FXANIM);    // LAYER_ARROW      bg3
  FStars.SetSize(FScene.Width, FScene.Height);
  FStars.LoadParamsFromString(STARNEST_VERYSIMPLE);
  FStars.OpacityThreshold := 1.0;
  FStars.Visible := False;

  // wolf mother ship
  FMotherShip := TMotherShip.Create(LAYER_ARROW, FAtlas);
  FMotherShip.SetCoordinate(ScaleW(545), ScaleH(265));
  FMotherShip.Visible := False;

  // whole transporter
  FTransporterWhole := TSprite.Create(texTransporterWhole, False);
  FScene.Add(FTransporterWhole, LAYER_ARROW);
  FTransporterWhole.Visible := False;
end;

procedure TScreenWolfCastle.SetSkyHighColorTo(aCol: TBGRAPixel; aDuration: single);
begin
  FSkyHigh.TopLeftColor.ChangeTo(aCol, aDuration);
  FSkyHigh.TopRightColor.ChangeTo(aCol, aDuration);
  FSkyHigh.BottomLeftColor.ChangeTo(aCol, aDuration);
  FSkyHigh.BottomRightColor.ChangeTo(aCol, aDuration);
end;

procedure TScreenWolfCastle.ToggleViewFromSpace;
var i: integer;
begin
  FScene.Layer[LAYER_ARROW].Visible := True;
  for i:=LAYER_PLAYER to LAYER_BG3 do
    FScene.Layer[i].Visible := False;
end;

procedure TScreenWolfCastle.KillSeaWaves;
var i: integer;
begin
  for i:=0 to FScene.Layer[LAYER_BG3].SurfaceCount-1 do
    if FScene.Layer[LAYER_BG3].Surface[i] is TWave1 then
      FScene.Layer[LAYER_BG3].Surface[i].Kill;
end;

procedure TScreenWolfCastle.CreateObjects;
var path: string;
  ima: TBGRABitmap;
begin
  GameState := gsUndefined;
  Audio.PauseMusicTitleMap(3.0);

  FsndSeaSideAmbiance := Audio.AddSound('tropical-island.ogg', 0.0, True);
  FsndSeaSideAmbiance.FadeIn(0.8, 2.0);

  FsndTropicalBird := Audio.AddSound('tropical-island-dawn.ogg', 0.0, True);
  FsndTropicalBird.Play(True);

  FsndMusic := Audio.AddMusic('TheMachine.ogg', True);
  FsndMusic.SetLoopBounds(114.871, FsndMusic.TotalDuration);
  FsndMainPropulsor := Audio.AddSound('rocket-launch-boost-and-burning.ogg', 0.80, True);
  FsndEngineIdle := Audio.AddSound('spaceship-engine-idle-2.ogg', 0.80, True);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  //AdditionnalScale := 0.6;
  AdditionnalScale := 1.0;
  LoadLR4DirTextures(FAtlas, False);
  LoadGranMaTextures(FAtlas);
  LoadWolfTextures(FAtlas);
  LoadPenelopeTextures(FAtlas);
  LoadMarcusTextures(FAtlas);
  LoadFatherTextures(FAtlas);
  LoadMotherTextures(FAtlas);
  LoadRobotW7Textures(FAtlas);
  AdditionnalScale := 1.5;
  TSubmarine.LoadTexture(FAtlas, AdditionnalScale);
  AdditionnalScale := 1.0;
  TTransporterWK510.LoadTexture(FAtlas);
  TMotherShip.LoadTexture(FAtlas);

  path := FolderSpriteGameMermaidsPort;
  texPontoon := FAtlas.AddFromSVG(path+'WoodenPontoon.svg', ScaleW(157), -1);
  texPontoonPillar := FAtlas.AddFromSVG(path+'WoodenPillar.svg', ScaleW(36), -1);
  texWave1 := FAtlas.AddFromSVG(path+'SeaWave1.svg', ScaleW(81), -1);

  texMountain := FAtlas.AddFromSVG(SpriteBGFolder+'Rock1.svg', ScaleW(362), -1);
  texCastle := FAtlas.AddFromSVG(SpriteBGFolder+'WolfCastle.svg', ScaleW(557), -1);

  path := FolderSpriteWolfCastle;
  texPalmTree1 := FAtlas.AddFromSVG(path+'PalmTree1.svg', ScaleW(216), -1);
  texPalmTree2 := FAtlas.AddFromSVG(path+'PalmTree2.svg', ScaleW(162), -1);
  texRock2 := FAtlas.AddFromSVG(path+'Rock2.svg', ScaleW(103), -1);
  texShipFrontView := FAtlas.AddFromSVG(path+'ShipFrontView.svg', ScaleW(460), -1);
  texTransporterWhole := FAtlas.AddFromSVG(path+'TransporterWhole.svg', ScaleW(153), -1);

  AddCloud128x128ParticleToAtlas(FAtlas);
  //AddBubbleParticleToAtlas(FAtlas);
  AddSphereParticleToAtlas(FAtlas);
  AddDustParticleToAtlas(FAtlas);

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

  FW7 := TRobotW74Direction.Create(LAYER_WOLF);
  FW7.X.Value := ScaleW(2798);
  FW7.BodyBottomY := ScaleH(607);
  FW7.IdleDown;
  FW7.Scale.Value := PointF(0.6, 0.6);

  // LR
  FLR := TLR4Direction.Create(-1);
  FLR.Scale.Value := PointF(0.6, 0.6);

  FMarcus := TWolfMarcus.Create(False, LAYER_WOLF);
  FMarcus.BodyBottomY := ScaleH(619);
  FMarcus.X.Value := ScaleW(3027);
  FMarcus.IdleLeft;
  FMarcus.Scale.Value := PointF(0.6, 0.6);

  FPenelope := TWolfPenelope.Create(False, LAYER_WOLF);
  FPenelope.BodyBottomY := ScaleH(636);
  FPenelope.X.Value := ScaleW(2970);
  FPenelope.IdleLeft;
  FPenelope.Scale.Value := PointF(0.6, 0.6);

  FFather := TWolfFather.Create(False, LAYER_WOLF);
  FFather.BodyBottomY := ScaleH(614);
  FFather.X.Value := ScaleW(2856);
  FFather.IdleLeft;
  FFather.Scale.Value := PointF(0.6, 0.6);

  FMother := TWolfMother.Create(False, LAYER_WOLF);
  FMother.BodyBottomY := ScaleH(619);
  FMother.X.Value := ScaleW(2909);
  FMother.IdleLeft;
  FMother.Scale.Value := PointF(0.6, 0.6);

  FGranny := TGranny.Create(LAYER_WOLF);  // wait LR
  FGranny.X.Value := ScaleW(2017);
  FGranny.BodyBottomY := ScaleH(631);
  FGranny.IdleLeft;
  FGranny.Scale.Value := PointF(0.6, 0.6);

  // camera
  FCamera := FScene.CreateCamera;
  FCamera.Pivot := PointF(0.5, 1.0); // camera attached to the bottom of the screen
  FCamera.AssignToLayerRange(LAYER_PLAYER, LAYER_BG3);
  FCamera.AutoFollow.Bounds := FViewArea;

  // pause panel
  FPausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  CustomizeMousePointer(False);
  PostMessage(0); // submarine arrival

{// direct à l'appel du transporteur
FGranny.Y.Value := ScaleH(621)-FGranny.DeltaYToBottom;
FGranny.X.Value := ScaleW(2742);
FGranny.IdleRight;
FLR.MoveToLayer(LAYER_PLAYER);
FLR.TimeMultiplicator := 1.15;
FLR.Y.Value := ScaleH(630)-FLR.DeltaYToBottom;
FLR.X.Value := ScaleW(2677);
FLR.IdleRight;
FCamera.AutoFollow.Speed := 0.02;
FCamera.AutoFollow.SetTargetSurface(FFather, True);
FCamera.Scale.Value := PointF(1.5,1.5);
PostMessage(420);  }


// direct dans l'espace
{FLR.MoveToLayer(LAYER_PLAYER);
FLR.X.Value := ScaleW(2677);
FLR.BodyBottomY := ScaleH(630);
FLR.TimeMultiplicator:=1.15;
FGranny.Y.Value := ScaleH(621)-FGranny.DeltaYToBottom;
FGranny.X.Value := ScaleW(2742);
FGranny.FlipH:=False;
FCamera.AutoFollow.Speed := 0.02;
FCamera.AutoFollow.SetTargetSurface(FFather, True);
FCamera.Scale.ChangeTo(PointF(1.5,1.5), 6.0, idcSinusoid);
PostMessage(420);  }


end;

procedure TScreenWolfCastle.FreeObjects;
begin
  FCloudsRenderer.Free;
  FCloudsRenderer := NIL;
  FreeAndNil(FCloudsDensity);
  FPlanetRenderer.Free;
  FPlanetRenderer := NIL;
  FStarRenderer.Free;
  FStarRenderer := NIL;
  FScene.KillCamera(FCamera);
  FScene.KillCamera(FCameraInSpace);

  if FsndSeaSideAmbiance <> NIL then FsndSeaSideAmbiance.FadeOutThenKill(2.0);
  FsndSeaSideAmbiance := NIL;
  if FsndTropicalBird <> NIL then FsndTropicalBird.FadeOutThenKill(2.0);
  FsndTropicalBird := NIL;
  if FsndMusic <> NIL then FsndMusic.FadeOutThenKill(2.0);
  FsndMusic := NIL;
  if FsndEngineIdle <> NIL then FsndEngineIdle.FadeOutThenKill(2.0);
  FsndEngineIdle := NIL;
  if FsndMainPropulsor <> NIL then FsndMainPropulsor.FadeOutThenKill(2.0);
  FsndMainPropulsor := NIL;
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
var
  r: TRectF;
  p: TPointF;
  v: Single;
begin
  case UserValue of
    // submarine arrival
    0: begin  // lr is in the cockpit
      FLR.SetChildOf(FSubmarine, -1);
      FLR.Scale.Value := PointF(0.6, 0.6);
      FLR.BodyBottomY := FSubMarine.Height*0.70;
      FLR.X.Value := FSubMarine.Width*0.75;
      FLR.IdleLeft;
      FLR.TimeMultiplicator := 1.2;
      FSubmarine.X.ChangeTo(ScaleW(201), 10.0, idcSinusoid);   //10
      FSubmarine.StartFloating;
      PostMessage(10, 12.5);
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
      FLR.WalkVerticallyTo(ScaleH(633), Self, 25);
    end;
    25: begin
      FLR.IdleRight;
      PostMessage(30, 1.0);
    end;
    30: FLR.ShowDialog(sImFinallyOnTheIsland, FFontText, Self, 35);
    35: FLR.ShowDialog(sLetsGoToTheCastle, FFontText, Self, 40);
    40: begin
      FLR.TimeMultiplicator := 0.8;
      FLR.JumpDeltaX := FScene.Width*0.115;
      FCamera.AutoFollow.SetTargetSurface(FLR, False);
      GameState := gsRunning;
    end;

    // main cinematic: the big meeting
    100: begin
      FLR.IdleRight;
      FLR.ShowExclamationMark;
      FLR.SetFaceType(lrfHappy);
      PostMessage(105, 1.0);
    end;
    105: begin   // kill the sea waves
      KillSeaWaves;
      FLR.HideMark;
      FLR.ShowDialog(sGrannyQuestion, FFontText, Self, 110);
    end;
    110: begin
      FLR.TimeMultiplicator := 0.4;
      FLR.WalkHorizontallyTo(ScaleW(1935), Self, 115);
    end;
    115: begin
      FLR.TimeMultiplicator := 0.6;
      FLR.IdleRight;
      FLR.ShowDialog(sFinallyIFoundYou, FFontText, Self, 120);
    end;
    120: FGranny.ShowDialog(Format(sIKnewYouWouldMakeIt, [PlayerInfo.Name]), FFontText, Self, 140);
    140: FLR.ShowDialog(sAreYouOkTheyDidnt, FFontText, Self, 145);
    145: FGranny.ShowDialog(sNotAtAllEveryone, FFontText, Self, 150);
    150: FGranny.ShowDialog(sComeOnLetsGoMeetThem, FFontText, Self, 155);
    155: begin
      FLR.SetFaceType(lrfWorry);
      FGranny.IdleRight;
      PostMessage(160, 0.5);
    end;
    160: FGranny.WalkHorizontallyTo(ScaleW(2170), Self, 165);
    165: begin
      FGranny.IdleRight;
      PostMessage(170, 1.0);
    end;
    170: begin
      FGranny.IdleLeft;
      PostMessage(175, 0.5);
    end;
    175: FGranny.ShowDialog(sTheresNothingToFear, FFontText, Self, 180);
    180: begin
      FLR.SetFaceType(lrfSmile);
      PostMessage(185, 0.5);
    end;
    185: begin
      FGranny.IdleRight;
      PostMessage(187, 0.5);
    end;
    187: begin
      FGranny.Y.ChangeTo(ScaleH(621)-FGranny.DeltaYToBottom, 2.0);
      FGranny.WalkHorizontallyTo(ScaleW(2742), Self, 99999);
      PostMessage(190, 0.5);
    end;
    190: begin
      FLR.TimeMultiplicator := 1.15;
      FLR.Y.ChangeTo(ScaleH(630)-FLR.DeltaYToBottom, 2.0);
      FLR.WalkHorizontallyTo(ScaleW(2677), Self, 200);
    end;
    200: begin
      FLR.IdleRight;
      FCamera.AutoFollow.Speed := 0.01;
      FCamera.AutoFollow.SetTargetSurface(FFather, False);

      TCharacterWithDialogPanel.DialogIsChildOfCharacter := True;

      FCamera.Scale.ChangeTo(PointF(1.5,1.5), 6.0, idcSinusoid);
      PostMessage(205, 6.0);
    end;
    205:begin
      FFather.ShowDialog(Format(sWelcomePlayerTAmFather, [PlayerInfo.Name]), FFontText, Self, 210);
    end;
    210: FMother.ShowDialog(Format(sHelloPlayerMother, [PlayerInfo.Name]), FFontText, Self, 215);
    215: begin
      FLR.SetFaceType(lrfWorry);
      FLR.ShowDialog(sHiButImNotSure, FFontText, Self, 220);
    end;
    220: FFather.ShowDialog(sYoureOwedSomeExplanations, FFontText, Self, 225);
    225: FFather.ShowDialog(sTheSituationIsDire, FFontText, Self, 230);
    230: FMother.ShowDialog(sYouOnlyNeedToTurnOn, FFontText, Self, 235);
    235: FFather.ShowDialog(sOurResearchShows, FFontText, Self, 240);
    240: FFather.ShowDialog(sAnAncientManuscript, FFontText, Self, 245);
    245: FMother.ShowDialog(sTheBookAlsoSays, FFontText, Self, 250);
    250: FLR.ShowDialog(sMeWhyNotOneOfYou, FFontText, Self, 255);
    255: FMarcus.ShowDialog(sWeRunFactories, FFontText, Self, 260);
    260: FFather.ShowDialog(sWeMakeMoney, FFontText, Self, 265);
    265: FPenelope.ShowDialog(sWeLikeBeeingInCharge, FFontText, Self, 270);
    270: FMother.ShowDialog(sAsYouCanSeeWere, FFontText, Self, 275);
    275: FLR.ShowDialog('...', FFontText, Self, 280);
    280: FFather.ShowDialog(sWeKidnappedYour, FFontText, Self, 285);
    285: FLR.ShowDialog(sYouMeanThisWas, FFontText, Self, 290);
    290: FFather.ShowDialog(sInAWayYes, FFontText, Self, 295);
    295: FPenelope.ShowDialog(sThanksToUsYouLearned, FFontText, Self, 300);
    300: FFather.ShowDialog(sYouOvercameYourFear, FFontText, Self, 305);
    305: FMarcus.ShowDialog(sYouLearnedToMove, FFontText, Self, 310);
    310: FMother.ShowDialog(sAndYouShowedCourage, FFontText, Self, 315);
    315: FLR.ShowDialog('...', FFontText, Self, 320);
    320: FLR.ShowDialog(sSoLetMeGetThisStraight, FFontText, Self, 325);
    325: FMother.ShowDialog(sYouHaveToYoure, FFontText, Self, 330);
    330: FFather.ShowDialog(sThereIsntMuchTime, FFontText, Self, 333);
    333: begin
      FGranny.IdleLeft;
      PostMessage(335, 0.5);
    end;
    335: FGranny.ShowDialog(Format(sPlayerIveBeenTreated,[PlayerInfo.Name]), FFontText, Self, 340);
    340: FLR.ShowDialog('...', FFontText, Self, 345);
    345: FLR.ShowDialog(sWellIveComeThisFar, FFontText, Self, 350);
    350: FLR.ShowDialog(sOkIllDoItIllGo, FFontText, Self, 353);
    353: begin
      FGranny.IdleRight;
      PostMessage(355, 0.5);
    end;
    355: FFather.ShowDialog(sWhatCondition, FFontText, Self, 360);
    360: FLR.ShowDialog(sIllGoIfYouLiftTheBan, FFontText, Self, 365);
    365: FMarcus.ShowDialog(sWhatQuestionExclamation, FFontText, Self, 370);
    370: FLR.ShowDialog(sBanningPeople, FFontText, Self, 375);
    375: FMarcus.ShowDialog('...', FFontText, Self, 380);
    380: FMother.ShowDialog(sThatsANobleRequest, FFontText, Self, 385);
    385: begin
      FLR.SetFaceType(lrfSmile);
      FFather.ShowDialog(sYourRequestIsGranted, FFontText, Self, 387);
    end;
    387: FFather.ShowDialog(sW7Question, FFontText, Self, 390);
    390: FW7.ShowDialog(sYesSirQuestion, FFontText, Self, 395);
    395: FFather.ShowDialog(sYouHeardThatUpdate, FFontText, Self, 400);
    400: FW7.ShowDialog(sDoneSir, FFontText, Self, 405);
    405: FFather.ShowDialog(Format(sPlayerAnythingElse, [PlayerInfo.Name]), FFontText, Self, 410);
    410: FLR.ShowDialog(sNoThankYou, FFontText, Self, 415);
    415: FFather.ShowDialog(sThenLetsSummonTheTransporter, FFontText, Self, 420);
    420: FW7.ShowDialog(sTransporterIsOnItsWay, FFontText, Self, 421);
    421: begin // everybody turn to the right (not at the same time)
      FsndTropicalBird.FadeOutThenKill(10.0);
      FsndTropicalBird := NIL;
      FsndMusic.Play(True);
      PostMessage(422, 2.5);
      PostMessage(423, 2.0);
      PostMessage(424, 1.6);
      PostMessage(425, 1.7);
      PostMessage(426, 1.3);
      PostMessage(429, 1.0);
    end;
    422: FFather.IdleRight;
    423: FMother.IdleRight;
    424: FMarcus.WalkHorizontallyTo(FMarcus.X.Value - FMarcus.BodyWidth, Self, 427);
    425: FPenelope.IdleRight;
    426: FW7.IdleRight;
    427: FMarcus.IdleRight;
    429: begin  // transporter arrival
//////////////////////////////
//PostMessage(520);
//exit;
/////////////////////////////
      FTransporter := TTransporterWK510.Create(FAtlas, LAYER_FXANIM);
      FTransporter.Posture_InAir(0);
      FTransporter.SetCoordinate(ScaleW(4255), ScaleH(-1161));  //4673
      FTransporter.Angle.Value := 15;
      FTransporter.MoveTo(ScaleH(2948), ScaleH(-33), 12.0, idcSinusoid);
      FCamera.Scale.ChangeTo(PointF(0.5, 0.5), 0.0, idcSinusoid);   //8.0
      FCamera.AutoFollow.SetTargetSurfaceCenter(FCastle, True);
      FCamera.AutoFollow.Speed := 0.01;  // previous 0.02
      FsndEngineIdle.FadeIn(0.6, 5.0);
      FsndEngineIdle.Pan.Value := 0.8;
      FsndEngineIdle.Pan.ChangeTo(0, 5.0);
      PostMessage(430, 3.0);
    end;
    430: begin
      PostMessage(432, 7.0); // transporter angle to 0
      PostMessage(435, 8.5);
    end;
    432: FTransporter.Angle.ChangeTo(0, 2.0, idcSinusoid); // horizontal
    435: begin // landing
      FTransporter.Y.ChangeTo(ScaleH(284), 4.0, idcSinusoid);
      FTransporter.Posture_OnlyLegs(4.0);
      PostMessage(440, 4.0);
    end;
    440: begin // dust + sound impact
      FTransporter.DoLandingShockAbsorberAnim;
      FTransporter.ShootDustWhenLanding;
      with Audio.AddSound('CollisionPunchShort.ogg', 0.3, False) do begin
        ApplyEffect(Audio.FXReverbLong);
        SetEffectDryWetVolume(Audio.FXReverbLong, 0.4);
        Pitch.Value := 0.6;
        PlayThenKill(True);
      end;
      PostMessage(445, 3.0);
    end;
    445: FTransporter.OpenPlatform(Self, 460, 0.5);
    460: begin // zoom in + people go on the platform
      FCamera.Scale.ChangeTo(PointF(1, 1), 8.0, idcSinusoid);
      FFather.SetWalkMode;
      FMother.SetWalkMode;
      FPenelope.SetWalkMode;
      FMarcus.SetWalkMode;
      FArrivalCount := 0;

      FFather.SetChildOf(FTransporter.Platform, 2);
      FMother.SetChildOf(FTransporter.Platform, 5);
      FPenelope.SetChildOf(FTransporter.Platform, 6);
      FMarcus.SetChildOf(FTransporter.Platform, 4);
      FW7.SetChildOf(FTransporter.Platform, 1);
      FGranny.SetChildOf(FTransporter.Platform, 3);
      FLR.SetChildOf(FTransporter.Platform, 7);

      FFather.WalkHorizontallyTo(FTransporter.Platform.Width*0.275, Self, 461);
      FFather.Y.ChangeTo(FTransporter.Platform.Height*0.77-FFather.DeltaYToBottom, 1.0);
      FMother.WalkHorizontallyTo(FTransporter.Platform.Width*0.60, Self, 462);
      FMother.Y.ChangeTo(FTransporter.Platform.Height*0.80-FMother.DeltaYToBottom, 1.0);
      FPenelope.WalkHorizontallyTo(FTransporter.Platform.Width*0.71, Self, 463);
      FPenelope.Y.ChangeTo(FTransporter.Platform.Height*0.89-FPenelope.DeltaYToBottom, 1.0);
      FMarcus.WalkHorizontallyTo(FTransporter.Platform.Width*0.82, Self, 464);
      FMarcus.Y.ChangeTo(FTransporter.Platform.Height*0.78-FMarcus.DeltaYToBottom, 1.0);
      FGranny.WalkHorizontallyTo(FTransporter.Platform.Width*0.149, Self, 466);
      FGranny.Y.ChangeTo(FTransporter.Platform.Height*0.85-FGranny.DeltaYToBottom, 1.0);
      FW7.WalkHorizontallyTo(FTransporter.Platform.Width*0.38, Self, 465);
      FW7.Y.ChangeTo(FTransporter.Platform.Height*0.75-FW7.DeltaYToBottom, 1.0);
      FLR.WalkHorizontallyTo(FTransporter.Platform.Width*0.48, Self, 467);
      FLR.Y.ChangeTo(FTransporter.Platform.Height*0.90-FLR.DeltaYToBottom, 1.0);

      FTransporter.Platform.ZOrderAsChild := 0;   // previous -2

      PostMessage(473); // wait everybody
    end;
    461: begin
      FFather.IdleRight;
      inc(FArrivalCount);
    end;
    462: begin
      FMother.IdleLeft;
      inc(FArrivalCount);
    end;
    463: begin
      FPenelope.IdleLeft;
      inc(FArrivalCount);
    end;
    464: begin
      FMarcus.IdleLeft;
      inc(FArrivalCount);
    end;
    465: begin
      FW7.IdleDown;
      inc(FArrivalCount);
    end;
    466: begin
      FGranny.IdleRight;
      inc(FArrivalCount);
    end;
    467: begin
      FLR.IdleDown;
      inc(FArrivalCount);
    end;
    473: if FArrivalCount = 7 then PostMessage(474, 1.0)
           else PostMessage(473);
    474: begin // platform close
      FTransporter.Platform.ZOrderAsChild := -2;
      FTransporter.ClosePlatform(Self, 480, 0.5);
    end;
    480: begin // take off + dust + zoom out + scale transporter
      FTransporter.ShootDustWhenLanding;
      FTransporter.Posture_InAir(2.0);
      PostMessage(482, 3.0);
    end;
    482: begin
      FTransporter.Y.ChangeTo(ScaleH(-190), 6.0, idcSinusoid);
      FCamera.Scale.ChangeTo(PointF(0.5, 0.5), 3.0, idcSinusoid);
      FTransporter.Scale.ChangeTo(PointF(0.65, 0.65), 3.0, idcSinusoid);
      FCamera.AutoFollow.SetTargetSurface(FTransporter, PointF(FTransporter.Width*0.5, FTransporter.Height*0.5), False);
      PostMessage(485, 6.0);
    end;
    485: begin // kill everybody + transporter rotate to the vertical
      FFather.Kill;
      FMother.Kill;
      FMarcus.Kill;
      FPenelope.Kill;
      FW7.Kill;
      FGranny.Kill;
      FLR.Kill;
      FTransporter.Angle.ChangeTo(90, 3.0, idcSinusoid);
      PostMessage(490, 3.5);
    end;
    490: begin // start main propulsor
      FCamera.AutoFollow.SetTargetSurface(FTransporter, PointF(FTransporter.Width*0.75, FTransporter.Height*0.5), False);
      FsndMainPropulsor.FadeIn(1.0, 1.0);
      FsndEngineIdle.FadeOut(8.0);
      FTransporter.StartMainPropulsor;
      FCamera.Shaker.Start(PPIScale(6), PPIScale(6), 0.05, False);
      FCamera.Shaker.FadeIn(1.0, 8.0);
      FTransporter.Y.ChangeTo(ScaleH(-1107), 4.0, idcDrop);
      PostMessage(495, 4.0);
    end;
    495: begin // kill unused sprites + clouds centered + clouds scrolling
      FScene.Layer[LAYER_BG2].KillAll;
      r := FCamera.GetViewRect;
      v := Max(r.Width, r.Height)*1.5;
      FClouds.SetSize(Round(v), Round(v)); // adjust the size of the clouds surface (90°)
      FClouds.SetCenterCoordinate(r.Width*0.5+r.Left, r.Height*0.5+r.Top);
      FClouds.Angle.Value := 90;
      FClouds.Visible := True;
      FClouds.TranslationSpeed := 1.0;
      FCloudsDensity.Value := 0.0;
      FClouds.Opacity.Value := 0;
      FClouds.Opacity.ChangeTo(255, 3.0);

      FStars.SetSize(Round(v), Round(v)); // adjust the size of the stars surface
      FStars.SetCenterCoordinate(r.Width*0.5+r.Left, r.Height*0.5+r.Top);

      PostMessage(800); // update params for clouds
      PostMessage(497, 3.0);
    end;
    497: begin  // clouds more dense
      FCloudsDensity.ChangeTo(1.0, 8.0);
      PostMessage(500, 8.0);
    end;
    500: begin  // cloud less dense + black blue
      SetSkyHighColorTo(BGRA(3,0,92), 8.0);
      FCloudsDensity.ChangeTo(0.0, 8.0);
      PostMessage(505, 8.0);
    end;
    505: begin  // no more clouds
      FClouds.Opacity.ChangeTo(0, 4.0);
      PostMessage(510, 4.0);
    end;
    510: begin // space + kill clouds
      FClouds.Kill;
      FClouds := NIL;
      SetSkyHighColorTo(BGRA(0,0,0), 6.0);
      PostMessage(515, 1.0);
    end;
    515: begin // stop main propulsor + stop snd + stop camera shaker + stars appears
      FTransporter.StopMainPropulsor;
      FsndMainPropulsor.FadeOutThenKill(7.0);
      FsndMainPropulsor := NIL;
      FCamera.Shaker.FadeOut(6.0);
      FStars.Visible := True;     // they are on LAYER_FXANIM
      FStars.Opacity.Value := 0;
      FStars.Opacity.ChangeTo(255, 5.0, idcStartSlowEndFast);
      FStars.ScrollingAngle.Value := 90;   // scrolling top to bottom
      FStars.ScrollingSpeed.Value := 0.001;
      PostMessage(520, 7.0);
    end;
    520: begin // view from space -> ship comes from hearth
      ToggleViewFromSpace;
      FStars.InsertToLayer(0, LAYER_ARROW);
      FStars.SetSize(FScene.Width, FScene.Height);
      FStars.CenterOnScene;
      FStars.ScrollingSpeed.Value := 0.0;
      FShipFrontView.Visible := True;
      FHearth.Visible := True;
      FShipFrontView.Scale.Value := PointF(0.097, 0.097);
      FShipFrontView.Scale.ChangeTo(PointF(2.0, 2.0), 6.0, idcDrop);
      PostMessage(525, 5.0);
    end;
    525: begin // black out
      FScene.Layer[LAYER_ARROW].Visible := False;
      PostMessage(530, 0.25)
    end;
    530: begin  // contruct last scene hearth + moon + transporter + mother ship + stars
      FShipFrontView.Kill;
      FShipFrontView := NIL;
      FScene.Layer[LAYER_ARROW].Visible := True;

      FCameraInSpace := FScene.CreateCamera;
      FCameraInSpace.AssignToLayer(LAYER_ARROW);
      FCameraInSpace.Angle.Value := 20;
      FCameraInSpace.Angle.ChangeTo(0, 25, idcSinusoid);

      FStars.Visible := True;
      v := Max(FScene.Width, FScene.Height)*1.5;
      FStars.SetSize(Round(v), Round(v));
      FStars.CenterOnScene;
      FStars.ScrollingAngle.AddConstant(-0.3);
      FMoon.Visible := True;
      FHearth.SetSize(ScaleW(343), ScaleH(343));
      FHearth.SetCoordinate(ScaleW(125), ScaleH(40));
      FMotherShip.Visible := True;
      FTransporterWhole.Visible := True;
      p := FMotherShip.SurfaceToScene(FMotherShip.GetLocalTransporterBayCenter);
      FTransporterWhole.Scale.Value := PointF(1.2, 1.2);
      FTransporterWhole.CenterX := -FTransporterWhole.Width*1.2*2;
      FTransporterWhole.CenterY := p.y;
      FTransporterWhole.SetChildOf(FMotherShip, 1);
      FTransporterWhole.MoveCenterTo(FMotherShip.GetLocalTransporterBayCenter, 14.0, idcSinusoid);
      PostMessage(535, 15);
    end;
    535: begin // transporter rotate
      FTransporterWhole.Angle.ChangeTo(-90, 2.5, idcSinusoid);
      PostMessage(540, 3.0);
    end;
    540: begin  //  transporter land on mother ship
      FTransporterWhole.Scale.ChangeTo(PointF(1.0, 1.0), 2.0, idcSinusoid);
      PostMessage(545);
    end;
    545: begin
      PlayerInfo.WolfCastle.IncCurrentStep;
      FSaveGame.Save;
      FsndMusic.FadeOutThenKill(10.0);
      FsndMusic := NIL;
      PostMessage(550, 8.0);
    end;
    550: begin // end
      //FScene.RunScreen(ScreenMap);
      FScene.RunScreen(ScreenInSpace);
    end;


    // update periodically the clouds density
    800: begin
      if FClouds = NIL then exit;
      FClouds.Density := FCloudsDensity.Value;
      PostMessage(800, 0.05);
    end;
  end;
end;

procedure TScreenWolfCastle.Update(const aElapsedTime: single);
var x1, x2: integer;
  flagPlayerIdle: Boolean;
  v: Single;
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

      // check the position to toggle the tropical bird ambiance
      // transition made between 900..1300
      x1 := ScaleW(900);
      x2 := ScaleW(1300);
      if InRange(Round(FLR.X.Value), x1, x2) then begin
        v := (FLR.X.Value-x1) / (x2-x1);
        v := v*v;
        FsndTropicalBird.Volume.Value := v;
        FsndSeaSideAmbiance.Volume.Value := (1.0-v)*0.8;
      end;

      // check the position of LR to trigger the cinematic
      if FLR.X.Value > ScaleW(1556) then begin
        FsndSeaSideAmbiance.Kill;
        FsndSeaSideAmbiance := NIL;
        GameState := gsStartCinematic;
      end;

    end;
  end;

  // update param for clouds
  FCloudsDensity.OnElapse(aElapsedTime);

  // check if player pause the game
  if Input.PausePressed then
    FPausePanel.ShowModal;
end;

end.

