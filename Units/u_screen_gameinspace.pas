unit u_screen_gameinspace;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes, BGRAPath,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon,
  u_ProceduralPlanet, u_procedural_starnest, u_procedural_interstellarjump;

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

{  FInterStellarJumpRenderer: TInterStellarJumpRenderer;
  FInterStellarJump: TInterStellarJump;  }


  FsndSpaceShipAmbiance: TALSSound;

  procedure ResetVariables;
  procedure CreateLevel;
public
  procedure DefineSubTextures(aAtlas: TAtlas); override;
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenInSpace: TScreenInSpace;

implementation
uses Forms, Graphics, u_app, u_mousepointer, u_screen_map, u_utils, u_resourcestring,
  u_sprite_lr4dir, u_sprite_wolf, u_sprite_granny,
  u_robotw7, u_wolfmothership;

var
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

{  FInterStellarJumpRenderer := TInterStellarJumpRenderer.Create(Fscene, True);
  FInterStellarJump := TInterStellarJump.Create(FScene, FInterStellarJumpRenderer);
  FScene.Add(FInterStellarJump, LAYER_BG3);
  FInterStellarJump.SetSize(FScene.Width, FScene.Height);   }


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

  // seats
  FMainBridge.CreateSeats(LAYER_WOLF);

  FMarcus := TWolfMarcus.Create(False, LAYER_WOLF);
  FMarcus.IdleRight;
  FMainBridge.RightSeat.SetCharacter(FMarcus);

  FPenelope := TWolfPenelope.Create(False, LAYER_WOLF);
  FPenelope.IdleLeft;
  FMainBridge.LeftSeat.SetCharacter(FPenelope);

  FFather := TWolfFather.Create(False, LAYER_WOLF);
  FFather.BodyBottomY := ScaleH(645);
  FFather.X.Value := ScaleW(280);
  FFather.IdleLeft;

  // desk center
  FMainBridge.CreateDeskCenter(LAYER_WOLF);

  fd.Create('Arial', FScene.Height div 10, [fsBold], BGRA(0,0,0, 0), BGRA(255,255,0), 2.5);
  fd.ComputeMaxHeightFor(sToBeContinued, Rect(0, 0, ScaleW(240), ScaleH(40)));
  with TSprite.Create(FScene, fd, sToBeContinued, NIL) do begin
    MoveToLayer(LAYER_BG3);
    CenterX := FScene.Width*0.5;
    BottomY := ScaleH(428);
  end;
end;

procedure TScreenInSpace.DefineSubTextures(aAtlas: TAtlas);
begin
  AdditionnalScale := 0.9;
  LoadLR4DirTextures(aAtlas, False);
  LoadGranMaTextures(aAtlas);
  AdditionnalScale := 1.0;
  LoadWolfTextures(aAtlas);
  LoadPenelopeTextures(aAtlas);
  LoadMarcusTextures(aAtlas);
  LoadFatherTextures(aAtlas);
  LoadMotherTextures(aAtlas);
  LoadRobotW7Textures(aAtlas);
  LoadWolfMotherShipMainBridgeTextures(aAtlas);

  AddSphereParticleToAtlas(aAtlas);

  // ui
  CreateGameFontNumber(aAtlas); // < must be first !
  // font for button in pause panel
  FFontText := CreateGameFontText(aAtlas);
  LoadGameDialogTextures(aAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(aAtlas);
  LoadMousePointerTexture(aAtlas);
end;

procedure TScreenInSpace.CreateObjects;
begin
  GameState := gsUndefined;
  Audio.PauseMusicTitleMap(3.0);

  FsndSpaceShipAmbiance := Audio.AddSound('spaceship-ambi-roomtone.ogg', 0.0, True);
  FsndSpaceShipAmbiance.FadeIn(0.8, 3.0);

{  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;    }
  CheckAtlas(FAtlas, 'inspace.atlas');
{  FAtlas.TryToPack;
  FAtlas.Build;
  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;   }


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
{  FInterStellarJumpRenderer.Free;
  FInterStellarJumpRenderer := NIL;    }

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

