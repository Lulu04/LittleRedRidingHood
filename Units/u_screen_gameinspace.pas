unit u_screen_gameinspace;

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



{ TScreenInSpace }

TScreenInSpace = class(TGameScreenTemplate)
private type TGameState=(gsUndefined, gsRunning);
var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FPausePanel: TInGamePausePanel;

  FPlanetRenderer: TOGLCPlanetRenderer;
  FHearth, FMoon, FMars: TOGLCSpritePlanet;

  FStarRenderer: TStarNestRenderer;
  FStars: TStarNest;

  FsndSpaceShipAmbiance: TALSSound;

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

var ScreenInSpace: TScreenInSpace;

implementation
uses Forms, Graphics, u_app, u_mousepointer, u_screen_map, u_utils, u_resourcestring,
  u_sprite_def2, u_sprite_lr4dir, u_sprite_wolf, u_sprite_granny, u_submarine,
  u_transporterwk510, u_robotw7, u_wolfmothership, Math;

type

{ TScreenAnim }

TScreenAnimType = (satNone, satRotate, satFlipH, satFlipV);
TScreenAnim = class(TSprite)
private
  FInverse: TSprite;
  procedure CreateFlippedH(aTex: PTexture);
  procedure CreateFlippedV(aTex: PTexture);
public
  constructor Create(aTex: PTexture; aX, aY: single; aWidth, aHeight: integer; aAnimType: TScreenAnimType;
    aLayerIndex: integer);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

TMainBridgeBG = class(TSprite)
  constructor Create(aLayerIndex: integer);
end;

{ TSeatWithCharacter }

TSeatWithCharacter = class(TSprite)
private
  FArmrest: TSprite;
  FSeatedCharacter: TWolf;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  constructor Create(aLayerIndex: integer);
  procedure SetCharacter(aWolfCharacter: TWolf);
  procedure RaiseCharacter(aLayerIndex: integer);
end;

var
  texInnerMainBridge, texSeat, texSeatArmrest, texDeskCenter,
  texScreen1, texScreen2, texScreen3, texScreen4: PTexture;
  FLR: TLR4Direction;
  FMarcus: TWolfMarcus;
  FPenelope: TWolfPenelope;
  FFather: TWolfFather;
  FMother: TWolfMother;
  FGranny: TGranny;
  FW7: TRobotW74Direction;
  FAtlas: TAtlas;
  FFontText: TTexturedFont;
  FMainBridge: TMainBridgeBG;
  FLeftSeat, FRightSeat: TSeatWithCharacter;
  FDeskCenter: TSprite;

{ TScreenAnim }

procedure TScreenAnim.CreateFlippedH(aTex: PTexture);
begin
  FInverse := TSprite.Create(aTex, False);
  AddChild(FInverse, -1);
  FInverse.FlipH := True;
  FInverse.X.Value := Width*0.5;
  FInverse.Y.Value := 0;
end;

procedure TScreenAnim.CreateFlippedV(aTex: PTexture);
begin
  FInverse := TSprite.Create(aTex, False);
  AddChild(FInverse, -1);
  FInverse.FlipV := True;
  FInverse.Y.Value := Height*0.5;
  FInverse.X.Value := 0;
end;

constructor TScreenAnim.Create(aTex: PTexture; aX, aY: single; aWidth,
  aHeight: integer; aAnimType: TScreenAnimType; aLayerIndex: integer);
begin
  inherited Create(aTex, False);
  SetCoordinate(aX, aY);
  SetSize(aWidth, aHeight);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  case aAnimType of
    satRotate: Angle.AddConstant(180);
    satFlipH: begin
      CreateFlippedH(aTex);
      PostMessage(0);
    end;
    satFlipV: begin
      CreateFlippedV(aTex);
      PostMessage(50);
    end;
  end;
end;

procedure TScreenAnim.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // anim flipped H
    0: begin
      MoveXRelative(Width*0.5, 1.5, idcSinusoid);
      FInverse.MoveXRelative(-Width, 1.5, idcSinusoid);
      PostMessage(5, 1.5);
    end;
    5: begin
      MoveXRelative(-Width*0.5, 1.5, idcSinusoid);
      FInverse.MoveXRelative(Width, 1.5, idcSinusoid);
      PostMessage(0, 1.5);
    end;

    // anim flipped V
    50: begin
      MoveYRelative(Height*0.5, 1.5, idcSinusoid);
      FInverse.MoveYRelative(-Height, 1.5, idcSinusoid);
      PostMessage(55, 1.5);
    end;
    55: begin
      MoveYRelative(-Height*0.5, 1.5, idcSinusoid);
      FInverse.MoveYRelative(Height, 1.5, idcSinusoid);
      PostMessage(50, 1.5);
    end;
  end;
end;

{ TSeatWithCharacter }

procedure TSeatWithCharacter.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FArmrest.FlipH := AValue;
  if FSeatedCharacter <> NIL then
    FSeatedCharacter.FlipH := AValue;
end;

procedure TSeatWithCharacter.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FArmrest.FlipV := AValue;
  if FSeatedCharacter <> NIL then
    FSeatedCharacter.FlipV := AValue;
end;

constructor TSeatWithCharacter.Create(aLayerIndex: integer);
begin
  inherited Create(texSeat, False);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);

  FArmrest := CreateSpriteChild(texSeatArmrest, False, 1);
  FArmrest.SetCoordinate(0.378*Width, 0.389*Height);
  FArmrest.ApplySymmetryWhenFlip := True;
end;

procedure TSeatWithCharacter.SetCharacter(aWolfCharacter: TWolf);
begin
  FSeatedCharacter := aWolfCharacter;
  FSeatedCharacter.SetChildOf(Self, 0);
  FSeatedCharacter.X.Value := Width*0.40;
  FSeatedCharacter.Y.Value := Height*0.60;
  FSeatedCharacter.State := wsSeatOnChair;
end;

procedure TSeatWithCharacter.RaiseCharacter(aLayerIndex: integer);
begin
  if FSeatedCharacter = NIL then exit;
  FSeatedCharacter.Y.Value := FSeatedCharacter.Y.Value + Height*0.20;
  if aLayerIndex <> -1 then FSeatedCharacter.MoveToLayer(aLayerIndex);
  FSeatedCharacter.Idle(True);
  FSeatedCharacter := NIL;
end;

{ TMainBridgeBG }

constructor TMainBridgeBG.Create(aLayerIndex: integer);
begin
  inherited Create(texInnerMainBridge, False);
  SetSize(FScene.Width, FScene.Height);
  if aLayerIndex <> -1 then begin
    FScene.Add(Self, aLayerIndex);
    CenterOnScene;
  end;
end;

{ TScreenInSpace }

procedure TScreenInSpace.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;
end;

procedure TScreenInSpace.ResetVariables;
begin

end;

procedure TScreenInSpace.CreateLevel;
var fd: TFontDescriptor;
  o: TTileEngine;
begin
  // stars   LAYER_BG3
  FStarRenderer := TStarNestRenderer.Create(FScene, True);
  FStars := TStarNest.Create(FScene, FStarRenderer);
  FScene.Add(FStars, LAYER_BG3);
  FStars.SetSize(FScene.Width, FScene.Height div 2);
  FStars.SetCoordinate(0, ScaleH(111));
  FStars.LoadParamsFromString(STARNEST_SIMPLEHOT);
  FStars.OpacityThreshold := 1.0;
  FStars.ScrollingAngle.AddConstant(0.3);

  // hearth + moon  LAYER_BG3
  FPlanetRenderer := TOGLCPlanetRenderer.Create(FScene, True);
  FHearth := TOGLCSpritePlanet.Create(FScene, FPlanetRenderer);
  FScene.Add(FHearth, LAYER_BG3);
  FHearth.LoadParamsFromString(PLANET_HEARTH);
  FHearth.SetSize(ScaleW(205), ScaleW(205));
  FHearth.SetCoordinate(ScaleW(200), ScaleH(215));
  FMoon := TOGLCSpritePlanet.Create(FScene, FPlanetRenderer);
  FMoon.SetChildOf(FHearth, 0);
  FMoon.LoadParamsFromString(PLANET_PINKY_MOON);
  FMoon.SetSize(ScaleW(72), ScaleW(72));
  FMoon.SetCoordinate(FHearth.Width*0.75, FHearth.Height*0.5);

  FMars := TOGLCSpritePlanet.Create(FScene, FPlanetRenderer);
  FScene.Add(FMars, LAYER_BG3);
  FMars.LoadParamsFromString(PLANET_MARS);
  FMars.SetSize(ScaleW(15), ScaleW(15));
  FMars.SetCoordinate(ScaleW(916), ScaleH(268));


  // main bridge bg   LAYER_GROUND
  FMainBridge := TMainBridgeBG.Create(LAYER_GROUND);
  // animation on screens LAYER_GROUND
  // screen 1
  TScreenAnim.Create(texScreen3, ScaleW(25), ScaleH(505), ScaleW(23), ScaleH(23), satRotate, LAYER_GROUND);
  // screen 3
  with TScreenAnim.Create(texScreen2, ScaleW(323), ScaleH(454), ScaleW(25), ScaleH(21), satFlipH, LAYER_GROUND) do
    Angle.Value := -2.7;
  // screen 5
  TScreenAnim.Create(texScreen1, ScaleW(588), ScaleH(448), ScaleW(40), ScaleH(15), satFlipV, LAYER_GROUND);
  // screen 6
  with TScreenAnim.Create(texScreen2, ScaleW(667), ScaleH(454), ScaleW(25), ScaleH(21), satFlipH, LAYER_GROUND) do
    Angle.Value := 2.7;
  // screen 7
  with TScreenAnim.Create(texScreen1, ScaleW(874), ScaleH(476), ScaleW(26), ScaleH(15), satFlipV, LAYER_GROUND) do
    Angle.Value := 17;
  // screen 2
  o := TTileEngine.Create(Fscene);
  FScene.Add(o, LAYER_GROUND);
  o.LoadMapFile(FolderSpriteInSpace+'Screen4Main_Map.map', [texScreen4]);
  o.SetCoordinate(ScaleW(153), ScaleH(470));
  o.SetViewSize(ScaleW(35), ScaleH(29));
  o.ScrollSpeed.Y.Value := FScene.Height*0.01;
  o.Angle.Value := -18;
  o.Tint.Value := BGRA(255,0,255,80);
  // screen 4
  o := TTileEngine.Create(Fscene);
  FScene.Add(o, LAYER_GROUND);
  o.LoadMapFile(FolderSpriteInSpace+'Screen4Main_Map.map', [texScreen4]);
  o.SetCoordinate(ScaleW(393), ScaleH(447));
  o.SetViewSize(ScaleW(48), ScaleH(28));
  o.ScrollSpeed.Y.Value := -FScene.Height*0.01;

  // characters
  FMother := TWolfMother.Create(False, LAYER_PLAYER);
  FMother.BodyBottomY := ScaleH(743);
  FMother.X.Value := ScaleW(148);
  FMother.IdleLeft;

  FGranny := TGranny.Create(LAYER_PLAYER);
  FGranny.X.Value := ScaleW(59);
  FGranny.BodyBottomY := ScaleH(743);
  FGranny.IdleRight;

  FW7 := TRobotW74Direction.Create(LAYER_PLAYER);
  FW7.X.Value := ScaleW(571);
  FW7.BodyBottomY := ScaleH(739);
  FW7.IdleLeft;

  FLR := TLR4Direction.Create(LAYER_PLAYER);
  FLR.X.Value := ScaleW(462);
  FLR.BodyBottomY := ScaleH(739);
  FLR.SetWindSpeed(0);
  FLR.IdleRight;

  FMarcus := TWolfMarcus.Create(False, LAYER_WOLF);
  FMarcus.IdleRight;
  FRightSeat := TSeatWithCharacter.Create(LAYER_WOLF);
  FRightSeat.SetCoordinate(ScaleW(748), ScaleH(493));
  FRightSeat.FlipH := True;
  FRightSeat.SetCharacter(FMarcus);

  FPenelope := TWolfPenelope.Create(False, LAYER_WOLF);
  FPenelope.IdleLeft;
  FLeftSeat := TSeatWithCharacter.Create(LAYER_WOLF);
  FLeftSeat.SetCoordinate(ScaleW(172), ScaleH(487));
  FLeftSeat.SetCharacter(FPenelope);

  FFather := TWolfFather.Create(False, LAYER_WOLF);
  FFather.BodyBottomY := ScaleH(645);
  FFather.X.Value := ScaleW(280);
  FFather.IdleLeft;

  // desk center
  FDeskCenter := FScene.AddSprite(texDeskCenter, False, LAYER_WOLF);
  FDeskCenter.SetCoordinate(ScaleW(401), ScaleH(619));

  fd.Create('Arial', FScene.Height div 10, [fsBold], BGRA(0,0,0, 0), BGRA(255,255,0), 2.5);
  fd.ComputeMaxHeightFor(sToBeContinued, Rect(0, 0, ScaleW(240), ScaleH(40)));
  with TSprite.Create(FScene, fd, sToBeContinued, NIL) do begin
    MoveToLayer(LAYER_BG3);
    CenterX := FScene.Width*0.5;
    BottomY := ScaleH(428);
  end;
end;

procedure TScreenInSpace.CreateObjects;
var path: string;
  ima: TBGRABitmap;
begin
  GameState := gsUndefined;
  Audio.PauseMusicTitleMap(3.0);

  FsndSpaceShipAmbiance := Audio.AddSound('spaceship-ambi-roomtone.ogg', 0.0, True);
  FsndSpaceShipAmbiance.FadeIn(0.8, 3.0);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  AdditionnalScale := 0.9;
  LoadLR4DirTextures(FAtlas, False);
  LoadGranMaTextures(FAtlas);
  AdditionnalScale := 1.0;
  LoadWolfTextures(FAtlas);
  LoadPenelopeTextures(FAtlas);
  LoadMarcusTextures(FAtlas);
  LoadFatherTextures(FAtlas);
  LoadMotherTextures(FAtlas);
  LoadRobotW7Textures(FAtlas);

  path := FolderSpriteInSpace;
  texInnerMainBridge := FAtlas.AddFromSVG(path+'MainBridgeInner.svg', ScaleW(768), -1);
  texSeat := FAtlas.AddFromSVG(path+'Seat.svg', ScaleW(120), -1);
  texSeatArmrest := FAtlas.AddFromSVG(path+'SeatArmrest.svg', ScaleW(69), -1);
  texDeskCenter := FAtlas.AddFromSVG(path+'DeskCenter.svg', ScaleW(222), -1);
  texScreen1 := FAtlas.AddFromSVG(path+'Screen1.svg', ScaleW(40), -1);
  texScreen2 := FAtlas.AddFromSVG(path+'Screen2.svg', ScaleW(25), -1);
  texScreen3 := FAtlas.AddFromSVG(path+'Screen3.svg', ScaleW(23), -1);
  texScreen4 := FAtlas.AddFromSVG(path+'Screen4.svg', ScaleW(44), -1);

  AddSphereParticleToAtlas(FAtlas);

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

  // pause panel
  FPausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  CustomizeMousePointer(False);
  PostMessage(0); // wolf father anim
end;

procedure TScreenInSpace.FreeObjects;
begin
  FPlanetRenderer.Free;
  FPlanetRenderer := NIL;
  FStarRenderer.Free;
  FStarRenderer := NIL;

  if FsndSpaceShipAmbiance <> NIL then FsndSpaceShipAmbiance.FadeOutThenKill(2.0);
  FsndSpaceShipAmbiance := NIL;

  if FScene.RequestedScreen = ScreenMap then
    Audio.ResumeMusicTitleMap;

  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
  ChallengeMode := False;
end;

procedure TScreenInSpace.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // father go to Penelope then Marcus and loop
    0: begin
      FFather.WalkHorizontallyTo(ScaleW(280), Self, 5);
    end;
    5: begin
      FFather.IdleLeft;
      PostMessage(10, 8.0);
    end;
    10: FFather.WalkHorizontallyTo(ScaleW(753), Self, 15);
    15: begin
      FFather.IdleRight;
      PostMessage(0, 8.0);
    end;
  end;
end;

procedure TScreenInSpace.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  // check if player pause the game
  if Input.PausePressed then
    FPausePanel.ShowModal;
end;

end.

