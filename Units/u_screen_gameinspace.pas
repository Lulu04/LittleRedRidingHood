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
  texInnerMainBridge, texSeat, texSeatArmrest: PTexture;
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
  FMars.SetSize(ScaleW(25), ScaleW(25));
  FMars.SetCoordinate(ScaleW(916), ScaleH(268));


  // main bridge bg   LAYER_GROUND
  FMainBridge := TMainBridgeBG.Create(LAYER_GROUND);

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
  FW7.X.Value := ScaleW(683);
  FW7.BodyBottomY := ScaleH(739);
  FW7.IdleLeft;

  FLR := TLR4Direction.Create(LAYER_PLAYER);
  FLR.X.Value := ScaleW(497);
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

  fd.Create('Arial', FScene.Height div 10, [fsBold], BGRA(0,0,0, 0), BGRA(255,255,0), 2.5);
  fd.ComputeMaxHeightFor(sToBeContinued, Rect(0, 0, ScaleW(240), ScaleH(56)));
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
  inherited ProcessMessage(UserValue);
end;

procedure TScreenInSpace.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  // check if player pause the game
  if Input.PausePressed then
    FPausePanel.ShowModal;
end;

end.

