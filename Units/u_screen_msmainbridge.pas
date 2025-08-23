unit u_screen_msmainbridge;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes, BGRAPath,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon,
  u_ProceduralPlanet, u_procedural_starnest;

type

{ TScreenMotherShipMainBridge }

TScreenMotherShipMainBridge = class(TGameScreenTemplate)
private type TGameState=(gsUndefined, gsRunning);
var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FPausePanel: TInGamePausePanel;

  FPlanetRenderer: TOGLCPlanetRenderer;
  FHearth, FMoon: TOGLCSpritePlanet;

  FsndSpaceShipAmbiance,
  FsndMainPropulsor,
  FsndMilitaryBriefing, FAlarm,
  FsndMusic: TALSSound;

  FArrivalCount: Integer;
  FBlackScreen: TQuad4Color;

  procedure ResetVariables;
  procedure CreateLevelStep1;
  procedure CreateLevelStep3;
  procedure CreateLevelStep8;
  procedure CreateLevelStep10;
  procedure CreateLevelStep13;
  procedure CreateLevel;
public
  procedure DefineSubTextures(aAtlas: TAtlas); override;
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenMotherShipMainBridge: TScreenMotherShipMainBridge;

implementation
uses Forms, Graphics, u_app, u_mousepointer, u_screen_map, u_utils,
  u_resourcestring, u_sprite_lr4dir, u_sprite_wolf, u_sprite_granny,
  u_sprite_def, u_screen_msconstruction, u_screen_msharvesting,
  u_screen_msmeteorstorm, u_robotw7, u_wolfmothership;

var
  texMessDanger, texMessRadiation, texLittleRobotBroom: PTexture;
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
  FStarsBG: TStarsBG;
  FLittleRobot: TLittleRobot;
  FBroom: TSprite;
  FCamera: TOGLCCamera;
  FAsteroidBelt: TAsteroidBeltViewFromShip;
  FMeteor: TSprite;
  FMeteorImpact: TBigFire;
  FGate: THyperSpaceGate;


{ TScreenMotherShipMainBridge }

procedure TScreenMotherShipMainBridge.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;
end;

procedure TScreenMotherShipMainBridge.ResetVariables;
begin

end;

procedure TScreenMotherShipMainBridge.CreateLevelStep1;
begin
  // stars   LAYER_BG3
  FStarsBG := TStarsBG.Create(LAYER_BG3);
  FStarsBG.Starnest.LoadParamsFromString(STARNEST_SIMPLEHOT);
  FStarsBG.Starnest.ScrollingAngle.AddConstant(0.3);

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

  // main bridge bg   LAYER_GROUND
  FMainBridge := TMainBridgeBG.Create(LAYER_GROUND);

  // characters
  FMother := TWolfMother.Create(False, LAYER_PLAYER);
  FMother.BodyBottomY := ScaleH(711);
  FMother.X.Value := ScaleW(142);
  FMother.IdleRight;

  FGranny := TGranny.Create(LAYER_PLAYER);
  FGranny.X.Value := ScaleW(66);
  FGranny.BodyBottomY := ScaleH(748);
  FGranny.IdleRight;

  FW7 := TRobotW74Direction.Create(LAYER_PLAYER);
  FW7.X.Value := ScaleW(645);
  FW7.BodyBottomY := ScaleH(598);
  FW7.IdleDown;

  FLR := TLR4Direction.Create(LAYER_PLAYER);
  FLR.X.Value := ScaleW(920);
  FLR.BodyBottomY := ScaleH(706);
  FLR.SetWindSpeed(0);
  FLR.IdleLeft;

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

  PostMessage(100); // debriefing

{  fd.Create('Arial', FScene.Height div 10, [fsBold], BGRA(0,0,0, 0), BGRA(255,255,0), 2.5);
  fd.ComputeMaxHeightFor(sToBeContinued, Rect(0, 0, ScaleW(240), ScaleH(40)));
  with TSprite.Create(FScene, fd, sToBeContinued, NIL) do begin
    MoveToLayer(LAYER_BG3);
    CenterX := FScene.Width*0.5;
    BottomY := ScaleH(428);
  end;   }
end;

procedure TScreenMotherShipMainBridge.CreateLevelStep3;
begin
  // stars   LAYER_BG3
  FStarsBG := TStarsBG.Create(LAYER_BG3);
  FStarsBG.Starnest.LoadParamsFromString(STARNEST_SIMPLEHOT);
  FStarsBG.Starnest.ScrollingAngle.AddConstant(0.3);

  // asteroid belt
  FAsteroidBelt := TAsteroidBeltViewFromShip.Create(LAYER_BG2);
  FAsteroidBelt.Opacity.Value := 0;
  FCamera := FScene.CreateCamera;
  FCamera.AssignToLayer(LAYER_BG2);
  FCamera.Scale.Value := PointF(0.25, 0.25);

  // main bridge bg   LAYER_GROUND
  FMainBridge := TMainBridgeBG.Create(LAYER_GROUND);

  // characters
  FMother := TWolfMother.Create(False, LAYER_PLAYER);
  FMother.BodyBottomY := ScaleH(711);
  FMother.X.Value := ScaleW(142);
  FMother.IdleRight;

  FGranny := TGranny.Create(LAYER_PLAYER);
  FGranny.X.Value := ScaleW(66);
  FGranny.BodyBottomY := ScaleH(748);
  FGranny.IdleRight;

  FW7 := TRobotW74Direction.Create(LAYER_PLAYER);
  FW7.X.Value := ScaleW(645);
  FW7.BodyBottomY := ScaleH(598);
  FW7.IdleDown;


  // seats
  FMainBridge.CreateSeats(LAYER_WOLF);

  FLR := TLR4Direction.Create(LAYER_PLAYER);
  FLR.X.Value := FScene.Width + FLR.BodyWidth;
  FLR.BodyBottomY := ScaleH(717);
  FLR.SetWindSpeed(0);
  FLR.IdleLeft;

  FMarcus := TWolfMarcus.Create(False, LAYER_PLAYER);
  FMarcus.X.Value := FScene.Width + FMarcus.BodyWidth;
  FMarcus.BodyBottomY := ScaleH(743);
  FMarcus.IdleLeft;

  FPenelope := TWolfPenelope.Create(False, LAYER_WOLF);
  FPenelope.IdleLeft;
  FMainBridge.LeftSeat.SetCharacter(FPenelope);

  FFather := TWolfFather.Create(False, LAYER_WOLF);
  FFather.BodyBottomY := ScaleH(645);
  FFather.X.Value := ScaleW(280);
  FFather.IdleLeft;

  // desk center
  FMainBridge.CreateDeskCenter(LAYER_WOLF);

  PostMessage(300); // debriefing
end;

procedure TScreenMotherShipMainBridge.CreateLevelStep8;
begin
  // stars   LAYER_BG3
  FStarsBG := TStarsBG.Create(LAYER_BG3);
  FStarsBG.Starnest.LoadParamsFromString(STARNEST_SIMPLEHOT);
  FStarsBG.Starnest.ScrollingAngle.AddConstant(0.3);

  // asteroid belt
  FAsteroidBelt := TAsteroidBeltViewFromShip.Create(LAYER_BG2);

  // main bridge bg   LAYER_GROUND
  FMainBridge := TMainBridgeBG.Create(LAYER_GROUND);

  // characters
  FMother := TWolfMother.Create(False, LAYER_FXANIM);
  FMother.BodyBottomY := ScaleH(711);
  FMother.X.Value := ScaleW(142);
  FMother.IdleRight;

  FGranny := TGranny.Create(LAYER_FXANIM);
  FGranny.X.Value := ScaleW(66);
  FGranny.BodyBottomY := ScaleH(748);
  FGranny.IdleRight;

  FW7 := TRobotW74Direction.Create(LAYER_PLAYER);
  FW7.X.Value := ScaleW(645);
  FW7.BodyBottomY := ScaleH(598);
  FW7.IdleDown;

  // seats
  FMainBridge.CreateSeats(LAYER_WOLF);

  FLR := TLR4Direction.Create(LAYER_PLAYER);
  FLR.X.Value := FScene.Width + FLR.BodyWidth;
  FLR.BodyBottomY := ScaleH(717);
  FLR.SetWindSpeed(0);
  FLR.IdleLeft;

  FMarcus := TWolfMarcus.Create(False, LAYER_PLAYER);
  FMarcus.X.Value := FScene.Width + FMarcus.BodyWidth;
  FMarcus.BodyBottomY := ScaleH(743);
  FMarcus.IdleLeft;

  FPenelope := TWolfPenelope.Create(False, LAYER_WOLF);

  FFather := TWolfFather.Create(False, LAYER_FXANIM);
  FFather.BodyBottomY := ScaleH(645);
  FFather.X.Value := ScaleW(280);
  FFather.IdleLeft;

  // desk center
  FMainBridge.CreateDeskCenter(LAYER_WOLF);

  PostMessage(500); // debriefing
end;

procedure TScreenMotherShipMainBridge.CreateLevelStep10;
begin
  // stars   LAYER_BG3
  FStarsBG := TStarsBG.Create(LAYER_BG3);
  FStarsBG.Starnest.LoadParamsFromString(STARNEST_SIMPLEHOT);

  // main bridge bg   LAYER_GROUND
  FMainBridge := TMainBridgeBG.Create(LAYER_GROUND);

  // characters
  FMother := TWolfMother.Create(False, LAYER_FXANIM);
  FMother.BodyBottomY := ScaleH(610);
  FMother.X.Value := ScaleW(339);
  FMother.IdleRight;

  FFather := TWolfFather.Create(False, LAYER_FXANIM);
  FFather.BodyBottomY := ScaleH(596);
  FFather.X.Value := ScaleW(499);
  FFather.IdleLeft;

  FW7 := TRobotW74Direction.Create(LAYER_PLAYER);
  FW7.X.Value := ScaleW(645);
  FW7.BodyBottomY := ScaleH(603);
  FW7.IdleLeft;

  // seats
  FMainBridge.CreateSeats(LAYER_WOLF);

  FLR := TLR4Direction.Create(LAYER_PLAYER);
  FLR.X.Value := ScaleW(756);
  FLR.BodyBottomY := ScaleH(721);
  FLR.SetWindSpeed(0);
  FLR.IdleLeft;

  FMarcus := TWolfMarcus.Create(False, LAYER_PLAYER);
  FMarcus.X.Value := ScaleW(831);
  FMarcus.BodyBottomY := ScaleH(749);
  FMarcus.IdleLeft;

  FPenelope := TWolfPenelope.Create(False, LAYER_WOLF);
  FPenelope.IdleRight;
  FMainBridge.LeftSeat.FlipH := True;
  FMainBridge.LeftSeat.SetCharacter(FPenelope);

  FGranny := TGranny.Create(LAYER_FXANIM);
  FGranny.X.Value := ScaleW(113);
  FGranny.BodyBottomY := ScaleH(743);
  FGranny.IdleRight;

  // desk center
  FMainBridge.CreateDeskCenter(LAYER_WOLF);

  // gate
  FGate := THyperSpaceGate.Create(FScene.Width*0.5, ScaleH(333), LAYER_BG1, FAtlas);

  // black screen
  FBlackScreen := TQuad4Color.Create(FScene);
  FScene.Add(FBlackScreen, LAYER_TOP);
  FBlackScreen.SetSize(FScene.Width, FScene.Height);
  FBlackScreen.SetAllColorsTo(BGRABlack);

  PostMessage(700); // debriefing 4
end;

procedure TScreenMotherShipMainBridge.CreateLevelStep13;
begin
  // stars   LAYER_BG3
  FStarsBG := TStarsBG.Create(LAYER_BG3);
  FStarsBG.Starnest.LoadParamsFromString(STARNEST_SIMPLEHOT);
  FStarsBG.StarJump.ZSpeed.Value := 0;
  FStarsBG.StarJump.Opacity.Value := 100;

  // main bridge bg   LAYER_GROUND
  FMainBridge := TMainBridgeBG.Create(LAYER_GROUND);

  // characters
  FMother := TWolfMother.Create(False, LAYER_FXANIM);
  FMother.BodyBottomY := ScaleH(605);
  FMother.X.Value := ScaleW(370);
  FMother.IdleRight;

  FFather := TWolfFather.Create(False, LAYER_FXANIM);
  FFather.BodyBottomY := ScaleH(595);
  FFather.X.Value := ScaleW(498);
  FFather.IdleLeft;

  FW7 := TRobotW74Direction.Create(LAYER_FXANIM);
  FW7.X.Value := ScaleW(624);
  FW7.BodyBottomY := ScaleH(603);
  FW7.IdleDown;

  // seats
  FMainBridge.CreateSeats(LAYER_WOLF);
  FMainBridge.LeftSeat.FlipH := True;
  FMainBridge.RightSeat.FlipH := False;

  FPenelope := TWolfPenelope.Create(False, LAYER_WOLF);
  FPenelope.X.Value := ScaleW(718);
  FPenelope.BodyBottomY := ScaleH(633);
  FPenelope.IdleLeft;

  FMarcus := TWolfMarcus.Create(False, LAYER_PLAYER);
  FMarcus.X.Value := ScaleW(821);
  FMarcus.BodyBottomY := ScaleH(676);
  FMarcus.IdleLeft;

  FGranny := TGranny.Create(LAYER_FXANIM);
  FGranny.X.Value := ScaleW(81);
  FGranny.BodyBottomY := ScaleH(691);
  FGranny.IdleRight;

  FLR := TLR4Direction.Create(LAYER_PLAYER);
  FLR.X.Value := ScaleW(233);
  FLR.BodyBottomY := ScaleH(745);
  FLR.SetWindSpeed(0);
  FLR.IdleRight;

  // desk center
  FMainBridge.CreateDeskCenter(LAYER_WOLF);

  // gate
  FGate := THyperSpaceGate.Create(FScene.Width*0.5, ScaleH(333), LAYER_BG1, FAtlas);
  FGate.Scale.Value := PointF(0.35, 0.35);

  // white screen
  FBlackScreen := TQuad4Color.Create(FScene);
  FScene.Add(FBlackScreen, LAYER_TOP);
  FBlackScreen.SetSize(FScene.Width, FScene.Height);
  FBlackScreen.SetAllColorsTo(BGRAWhite);
  FBlackScreen.Visible := False;

  PostMessage(900); // debriefing 5 + hyperspace jump
end;

procedure TScreenMotherShipMainBridge.CreateLevel;
begin
  case PlayerInfo.InSpace.StepPlayed of
    1: CreateLevelStep1;
    3: CreateLevelStep3;
    8: CreateLevelStep8;
    10: CreateLevelStep10;
    13: CreateLevelStep13;
    else raise exception.create('bug');
  end;
end;

procedure TScreenMotherShipMainBridge.DefineSubTextures(aAtlas: TAtlas);
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
  LoadMainBridgeTextures(aAtlas);
  AdditionnalScale := 0.7; //35;
  LoadHyperSpaceGateTextures(aAtlas);
  AdditionnalScale := 1.0;
  texMessDanger := aAtlas.AddString(sDanger, TMainBridgeBG.GetMessFontDescriptor(sDanger), NIL);
  texMessRadiation := aAtlas.AddString(sRadiation, TMainBridgeBG.GetMessFontDescriptor(sRadiation), NIL);

  TLittleRobot.LoadTexture(aAtlas);
  texLittleRobotBroom := aAtlas.AddFromSVG(SpriteGameVolcanoInnerFolder+'LittleRobotBroom.svg', -1, ScaleH(34));

  AddSphereParticleToAtlas(aAtlas);
  AddCloud128x128ParticleToAtlas(aAtlas);

  // ui
  CreateGameFontNumber(aAtlas); // < must be first !
  // font for button in pause panel
  FFontText := CreateGameFontText(aAtlas);
  LoadGameDialogTextures(aAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(aAtlas);
  LoadMousePointerTexture(aAtlas);
end;

procedure TScreenMotherShipMainBridge.CreateObjects;
begin
  GameState := gsUndefined;
  Audio.PauseMusicTitleMap(3.0);

  FsndSpaceShipAmbiance := Audio.AddSound('spaceship-ambi-roomtone.ogg', 0.0, True);
  FsndSpaceShipAmbiance.FadeIn(0.8, 3.0);
  FsndMainPropulsor := Audio.AddSound('rocket-launch-boost-and-burning.ogg', 0.60, True);
  FsndMilitaryBriefing := Audio.AddMusic('MilitaryBriefing.ogg', True);
  FsndMilitaryBriefing.SetLoopBounds(24.0, FsndMilitaryBriefing.TotalDuration);
  FsndMilitaryBriefing.Play;

{  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;    }
  CheckAtlas(FAtlas, 'spacemainbridge.atlas');
{  FAtlas.TryToPack;
  FAtlas.Build;
  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;   }


  CreateLevel;

  // pause panel
  FPausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  CustomizeMousePointer(False);
  SetGameInstructions(PlayerInfo.InSpace.HelpText);
end;

procedure TScreenMotherShipMainBridge.FreeObjects;
begin
  FScene.PostProcessing.StopEngine;
  FScene.KillCamera(FCamera);
  FPlanetRenderer.Free;
  FPlanetRenderer := NIL;

  if FsndSpaceShipAmbiance <> NIL then FsndSpaceShipAmbiance.FadeOutThenKill(2.0);
  FsndSpaceShipAmbiance := NIL;
  if FsndMainPropulsor <> NIL then FsndMainPropulsor.FadeOutThenKill(2.0);
  FsndMainPropulsor := NIL;
  if FsndMilitaryBriefing <> NIL then FsndMilitaryBriefing.FadeOutThenKill(2.0);
  FsndMilitaryBriefing := NIL;
  if FAlarm <> NIL then FAlarm.FadeOutThenKill(2.0);
  FAlarm := NIL;
  if FsndMusic <> NIL then FsndMusic.FadeOutThenKill(2.0);
  FsndMusic := NIL;

  if FScene.RequestedScreen = ScreenMap then
    Audio.ResumeMusicTitleMap;

  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
  ChallengeMode := False;
end;

procedure TScreenMotherShipMainBridge.ProcessMessage(UserValue: TUserMessageValue);
var sndRobot: TALSSound;
  c: TBGRAPixel;
  procedure ShowNarratorMessage(const aMess: string; aDuration: single);
  begin
    with TInfoPanel.Create('', aMess, FFontText, aDuration) do begin
      RightX := FScene.Width;
      BottomY := FScene.Height;
    end;
  end;

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

    // briefing departure to the asteroids belt
    100: begin
      FStarsBG.Starnest.ScrollingAngle.Value := 0;
      FStarsBG.StarJump.Opacity.Value := 255;
      FStarsBG.StarJump.ZSpeed.Value := 0;
      FMainBridge.LeftSeat.FlipH := True;
      FMainBridge.RightSeat.FlipH := False;
      FFather.X.Value := FScene.Width*0.5;
      FFather.BodyBottomY := ScaleH(608);
      FFather.IdleRight;
      PostMessage(220);  // anim little robot sweep the floor
      PostMessage(105, 3.0);
    end;
    105: FMother.ShowDialog(sHereWeAreInOrbit, FFontText, Self, 107);
    107: FGranny.ShowDialog(sItsBreathtaking, FFontText, Self, 110);
    110: FFather.ShowDialog(sTheOldBookSpeaksOfAPortal, FFontText, Self, 115);
    115: FFather.ShowDialog(sAccordingToOurResearch, FFontText, Self, 117, 0.5);
    117: begin
      FFather.IdleLeft;
      PostMessage(120, 1.0);
    end;
    120: FFather.ShowDialog(sPSetACourse, FFontText, Self, 125);
    125: FPenelope.ShowDialog(sOnIt, FFontText, Self, 130);
    130: begin
      FMainBridge.LeftSeat.FlipH := False;  // penelope turns to the dashboard
      PostMessage(200, 0.5); // anim ship pivots and accelerates forward
      PostMessage(133, 0.5);
      PostMessage(132, 0.5);
    end;
    132: FFather.IdleRight;
    133: FMarcus.ShowDialog(sWaitFatherYouKnown, FFontText, Self, 135);
    135: begin
      FMainBridge.LeftSeat.FlipH := True;
      PostMessage(136, 0.5);
    end;
    136: begin
      PostMessage(138, 0.5);
      FPenelope.ShowDialog(sAndThatsOnlyProblem, FFontText, Self, 140);
    end;
    138: FFather.IdleLeft;
    140: FFather.ShowDialog(sYoureBothRight, FFontText, Self, 145);
    145: FPenelope.ShowDialog(sSolvedHow, FFontText, Self, 150);
    150: FFather.ShowDialog(sThoseRocksAreLoaded, FFontText, Self, 155);
    155: begin
      PostMessage(156, 0.5);
      FMarcus.ShowDialog(sAndHowAreWeSupposed, FFontText, Self, 160);
    end;
    156: FFather.IdleRight;
    160: FFather.ShowDialog(sPCarryingaWhole, FFontText, Self, 161);
    161: begin // little robot stop sweeping the floor + exclamation mark
      FLittleRobot.Tag2 := False;
      FLittleRobot.CancelWalk;
      FLittleRobot.Speed.Value := PointF(0, 0);
      FLittleRobot.StopAnimSweepTheFloor;
      FLittleRobot.ShowExclamationMark;
      PostMessage(165, 1.5);
    end;
    165: begin  // little robot escape with sound
      sndRobot := Audio.AddSound('ai_yes.ogg', 0.45, False);
      if FLittleRobot.CenterX >= FScene.Width*0.5 then begin
        FLittleRobot.FlipH := False;
        FLittleRobot.Speed.x.Value := -FScene.Width;
        sndRobot.Pan.ChangeTo(-1.0, 1.0);
      end else begin
        FLittleRobot.FlipH := True;
        FLittleRobot.Speed.x.Value := FScene.Width;
        sndRobot.Pan.ChangeTo(1.0, 1.0);
      end;
      sndRobot.PlayThenKill;
      FLittleRobot.HideMark;
      FLittleRobot.KillDefered(2.0);
      FLittleRobot := NIL;
      PostMessage(169, 2.0);
    end;

    169: FMarcus.ShowDialog(sWedStillNeedADocking, FFontText, Self, 170);
    170: FFather.ShowDialog(Format(sExactlyHereThePlan,[PlayerInfo.Name]), FFontText, Self, 175);
    175: FFather.ShowDialog(sWeWillRegroupFor, FFontText, Self, 180);
    180: FLR.ShowDialog(sGotItComeOnM, FFontText, Self, 185);
    185: begin
      PlayerInfo.InSpace.IncCurrentStep;
      FSaveGame.Save;
      PlayerInfo.InSpace.StepPlayed := PlayerInfo.InSpace.StepPlayed + 1;
      FScene.RunScreen(ScreenMotherShipConstruction);
    end;

    // anim ship run forward
    200: begin
      FsndMainPropulsor.FadeIn(1.0, 2.0);
      FHearth.X.ChangeTo(-FHearth.Width*2.2, 20.0, idcSinusoid);
      FHearth.Scale.ChangeTo(PointF(2,2), 20, idcSinusoid);
      FMoon.MoveXRelative(FMoon.Width*0.5, 20.0, idcSinusoid);
      FStarsBG.StarJump.ParticleSize.Value := 0.015; // star without trail
      FStarsBG.StarJump.ZSpeed.ChangeTo(0.5, 12.0, idcSinusoid);
      FStarsBG.Starnest.ScrollingAngle.AddConstant(0.5);
      PostMessage(205, 6.0);
    end;
    205: begin
      FsndMainPropulsor.Volume.ChangeTo(0.85, 10.0);
    end;

    // anim little robot sweep the floor
    220: begin
      FLittleRobot := TLittleRobot.Create(ScaleW(380), ScaleH(758), LAYER_ARROW);
      FLittleRobot.Speed.x.Value := FScene.Width*0.06;
      FBroom := TSprite.Create(texLittleRobotBroom, False);
      FBroom.ApplySymmetryWhenFlip := True;
      FLittleRobot.AddObjectInHand(FBroom, PointF(-FBroom.Width*0.1, FBroom.Height*0.20), -1);
      FLittleRobot.FlipH := True;
      FLittleRobot.Tag2 := True;  // = mode sweeping the floor
      FLittleRobot.FArm.Angle.Value := 68;
      PostMessage(225);
    end;
    225: begin
      if not FLittleRobot.Tag2 then exit;
      //FLittleRobot.StartAnimSweepTheFloor;
      FLittleRobot.WalkHorizontallyTo(ScaleW(722), Self, 230);
    end;
    230: begin
      if not FLittleRobot.Tag2 then exit;
      //FLittleRobot.StopAnimSweepTheFloor;
      PostMessage(233, 1.0);
    end;
    233: begin
      if not FLittleRobot.Tag2 then exit;
      FLittleRobot.FlipH := False;
      PostMessage(235, 1.0);
    end;
    235: begin
      if not FLittleRobot.Tag2 then exit;
      //FLittleRobot.StartAnimSweepTheFloor;
      FLittleRobot.WalkHorizontallyTo(ScaleW(295), Self, 240);
    end;
    240: begin
      if not FLittleRobot.Tag2 then exit;
      //FLittleRobot.StopAnimSweepTheFloor;
      PostMessage(245, 1.0);
    end;
    245: begin
      if not FLittleRobot.Tag2 then exit;
      FLittleRobot.FlipH := True;
      PostMessage(225, 1.0);
    end;


    // briefing 2 arrival to the asteroid belt
    300: begin
      FStarsBG.Starnest.ScrollingAngle.Value := 0;
      FStarsBG.StarJump.Opacity.Value := 255;
      FStarsBG.StarJump.ZSpeed.Value := 0.5;
      FMainBridge.LeftSeat.FlipH := False;
      FMainBridge.RightSeat.FlipH := False;
      FFather.X.Value := FScene.Width*0.5;
      FFather.BodyBottomY := ScaleH(608);
      FFather.IdleRight;
      PostMessage(305, 3.0);
    end;
    305: begin  // LR and Marcus enter
      FLR.WalkHorizontallyTo(ScaleW(836), Self, 306);
      FMarcus.WalkHorizontallyTo(ScaleW(905), Self, 307);
      FArrivalCount := 0;
      PostMessage(310);
    end;
    306: begin
      inc(FArrivalCount);
      FLR.IdleLeft;
    end;
    307: begin
      inc(FArrivalCount);
      FMarcus.IdleLeft;
    end;
    310: if FArrivalCount < 2 then PostMessage(310) else PostMessage(315);
    315: FMarcus.ShowDialog(sTheDockingBayAndThe, FFontText, Self, 320);
    320: FFather.ShowDialog(sExcellentExclamation, FFontText, Self, 325);
    325: FPenelope.ShowDialog(sWereApproachingThe, FFontText, Self, 330);
    330: begin  // asteroid belt appear
      FAsteroidBelt.Opacity.ChangeTo(255, 3.0);
      FCamera.Scale.Value := PointF(0.25, 0.25);
      FCamera.Scale.ChangeTo(PointF(1.0, 1.0), 10.0, idcSinusoid);
      FStarsBG.StarJump.ZSpeed.ChangeTo(0, 10.0, idcSinusoid);
      PostMessage(335,10.0);
    end;
    335: FPenelope.ShowDialog(sThatsItWeCantGoAny, FFontText, Self, 340);
    340: FFather.ShowDialog(sUnderstoodWellDeploy, FFontText, Self, 345);
    345: begin
      FFather.IdleLeft;
      PostMessage(350, 0.5);
    end;
    350: begin
      PostMessage(353, 0.6);
      FFather.ShowDialog(sPYourJobWillBe, FFontText, Self, 355);
    end;
    353: FMainBridge.LeftSeat.FlipH := True;
    355: FFather.ShowDialog(sWeNeedNewTechToBuid, FFontText, Self, 360);
    360: FPenelope.ShowDialog(sIllDoMyBest, FFontText, Self, 363, 0.5);
    363: begin
      FFather.IdleRight;
      PostMessage(365, 0.5);
    end;
    365: FFather.ShowDialog(sMYouWillOverseeThe, FFontText, Self, 370);
    370: FMarcus.ShowDialog(sYesFather, FFontText, Self, 375);
    375: FFather.ShowDialog(Format(sAndFinallyIfYoureUp, [PlayerInfo.Name]), FFontText, Self, 380);
    380: FLR.ShowDialog(sAwesomeImIn, FFontText, Self, 385);
    385: FGranny.ShowDialog(sItsGoingToBeDangerous, FFontText, Self, 390);
    390: FLR.ShowDialog(sDontWorryGIllBe, FFontText, Self, 395);
    395: FFather.ShowDialog(sYourFirstObjective, FFontText, Self, 400);
    400: FFather.ShowDialog(sOnceThatDoneYoull, FFontText, Self, 405);
    405: FLR.ShowDialog(sGotIt, FFontText, Self, 410, 1.0);
    410: FFather.ShowDialog(sAnyQuestions, FFontText, Self, 415, 1.0);
    415: FFather.ShowDialog(sNoQuestionThen, FFontText, Self, 420);
    420: FMother.ShowDialog(sITrustYouChildren, FFontText, Self, 425);
    425: begin
      PlayerInfo.InSpace.IncCurrentStep;
      FSaveGame.Save;
      PlayerInfo.InSpace.StepPlayed := PlayerInfo.InSpace.StepPlayed + 1;
      FScene.RunScreen(ScreenHarvestingInSpace);
    end;

    // briefing 3 about the meteor storm
    500: begin
      FCamera := FScene.CreateCamera;
      FCamera.AssignToLayerRange(LAYER_ARROW, LAYER_BG3);
      FCamera.Scale.Value := PointF(1.05, 1.05);
      FStarsBG.Starnest.ScrollingAngle.Value := 0;
      FStarsBG.StarJump.Opacity.Value := 255;
      FStarsBG.StarJump.ZSpeed.Value := 0.0;
      FMainBridge.LeftSeat.FlipH := False;
      FMainBridge.RightSeat.FlipH := False;
      FFather.X.Value := ScaleW(604);
      FFather.BodyBottomY := ScaleH(640);
      FFather.IdleLeft;
      FMother.X.Value := ScaleW(354);
      FMother.BodyBottomY := ScaleH(604);
      FMother.IdleRight;
      FGranny.X.Value := ScaleW(444);
      FGranny.BodyBottomY := ScaleH(604);
      FGranny.IdleRight;
      FW7.X.Value := -FW7.BodyWidth*3;
      FW7.BodyBottomY := ScaleH(718);
      FW7.IdleRight;
      FW7.WalkHorizontallyTo(ScaleW(108), Self, 502);     //108
      FPenelope.X.Value := -FPenelope.BodyWidth*1.5;
      FPenelope.BodyBottomY := ScaleH(743);
      FPenelope.IdleRight;
      FPenelope.WalkHorizontallyTo(ScaleW(273), Self, 503);
      FPenelope.Y.ChangeTo(ScaleH(665), 1.5, idcSinusoid);
      FLR.X.Value := FScene.Width+FLR.BodyWidth*1.5;
      FLR.BodyBottomY := ScaleH(720);
      FLR.IdleLeft;
      FLR.WalkHorizontallyTo(ScaleW(758), Self, 504);
      FMarcus.X.Value := FScene.Width+FMarcus.BodyWidth*3;
      FMarcus.BodyBottomY := ScaleH(746);
      FMarcus.IdleLeft;
      FMarcus.WalkHorizontallyTo(ScaleW(827), Self, 505);
      FArrivalCount := 0;
      PostMessage(507);
    end;
    502: begin
      inc(FArrivalCount);
      FW7.IdleRight;
    end;
    503: begin
      inc(FArrivalCount);
      FPenelope.IdleRight;
    end;
    504: begin
      inc(FArrivalCount);
      FLR.IdleLeft;
    end;
    505: begin
      inc(FArrivalCount);
      FMarcus.IdleLeft;
    end;
    507: if FArrivalCount = 4 then PostMessage(510, 1.0) else PostMessage(507);
    510: begin
      FMarcus.ShowDialog(sFatherWeHaveACombatShipReady, FFontText, Self, 513);
      PostMessage(511, 0.6);
    end;
    511: FFather.IdleRight;
    513: FFather.ShowDialog(sYouveDoneWell, FFontText, Self, 515);
    515: begin
      PostMessage(516, 0.6);
      FW7.ShowDialog(sTheMeteorStormWillHit, FFontText, Self, 517);
    end;
    516: FFather.IdleLeft;
    517: FFather.ShowDialog(sVeryWellItsTimeToAct, FFontText, Self, 519);
    519: FFather.ShowDialog(sPTakeControlOfTheShip, FFontText, Self, 521);
    521: FPenelope.ShowDialog(sItsRiskyButILikeIt, FFontText, Self, 523, 0.5);
    523: begin
      FFather.IdleRight;
      PostMessage(525, 0.6);
    end;
    525: FFather.ShowDialog(Format(sPlayerYoullPilotTheCombat, [PlayerInfo.Name]), FFontText, Self, 527);
    527: FLR.ShowDialog(sIllDoMyBest, FFontText, Self, 528);
    528: FPenelope.ShowDialog(sDontForgetEachImpact, FFontText, Self, 529);
    529: FFather.ShowDialog(Format(sMWithWAssistPlayer, [PlayerInfo.Name]), FFontText, Self, 531);
    531: FMarcus.ShowDialog(sYesFather, FFontText, Self, 532, 0.5);
    532: begin
      FFather.IdleLeft;
      PostMessage(533, 0.5);
    end;
    533: FFather.ShowDialog(sLadiesWellNeedYourHelp, FFontText, Self, 535);
    535: FGranny.ShowDialog(sYesQuestion, FFontText, Self, 537);
    537: FFather.ShowDialog(sINeedYouToSweepThroughTheShip, FFontText, Self, 539);
    539: FGranny.ShowDialog(sConsiderItDone, FFontText, Self, 541);
    541: FMother.ShowDialog(sFinallySomeExercice, FFontText, Self, 543);
    543: begin
      FMainBridge.ShowAlert(texMessDanger);
      FAlarm := Audio.AddSound('alert.ogg', 0.5, True);
      FAlarm.Play;
      PostMessage(545, 1.0);
    end;
    545: FW7.ShowDialog(sIncomingMeteorActivatingShield, FFontText, Self, 547);
    547: begin // meteor comes
      FMainBridge.StartShield(FAtlas);
      FMeteor := TSprite.Create(FAtlas.RetrieveTextureByFileName('Asteroid4.svg'), False);
      FMeteorImpact := TBigFire.Create(FScene.Width*0.5, FScene.Height*0.5, LAYER_BG1, FAtlas);
      FMeteorImpact.Visible := False;
      FScene.Add(FMeteor, LAYER_BG1);
      FMeteor.CenterOnScene;
      FMeteor.Scale.Value := PointF(0.01, 0.01);
      FMeteor.Angle.AddConstant(360*2);
      FMeteor.Scale.ChangeTo(PointF(2.0, 2.0), 3.0, idcDrop);
      PostMessage(548, 1.0);
      PostMessage(549, 3.0);
    end;
    548: Audio.PlayThenKillSound('impact-incoming.ogg', 1.0);
    549: begin  // meteor explode
      FMeteor.Kill;
      FMeteorImpact.Visible := True;
      FCamera.Shaker.Start(PPIScale(10), PPIScale(10), 0.1, True);
      PostMessage(551, 2.0);
    end;
    551: begin
      FCamera.Shaker.FadeOut(1.5);
      FMeteorImpact.Opacity.ChangeTo(0, 1.5);
      PostMessage(553, 1.5);
    end;
    553: FFather.ShowDialog(sNoMoreTimeToWaste, FFontText, Self, 555);
    555: begin
      FLR.IdleRight;
      FLR.WalkHorizontallyTo(FScene.Width+FLR.BodyWidth*2, Self, 99999);
      FMarcus.IdleRight;
      FMarcus.WalkHorizontallyTo(FScene.Width+FMarcus.BodyWidth*2, Self, 99999);
      FW7.IdleRight;
      FW7.WalkHorizontallyTo(FScene.Width+FW7.BodyWidth*2, Self, 99999);
      FFather.IdleLeft;
      FFather.WalkHorizontallyTo(ScaleW(288), Self, 556);
      FGranny.IdleRight;
      FGranny.WalkHorizontallyTo(FScene.Width+FGranny.BodyWidth*2, Self, 99999);
      FGranny.Y.ChangeTo(ScaleH(745), 17.0);
      FMother.IdleRight;
      FMother.WalkHorizontallyTo(FScene.Width+FMother.BodyWidth*2, Self, 99999);
      FMother.Y.ChangeTo(ScaleH(720), 17.0);

      FPenelope.IdleLeft;
      FPenelope.WalkHorizontallyTo(ScaleW(230), Self, 557);
      FPenelope.Y.ChangeTo(ScaleH(611), 1.0);
    end;
    556: FFather.IdleLeft;
    557: begin // penelope seat
      FPenelope.IdleLeft;
      FMainBridge.LeftSeat.SetCharacter(FPenelope);
      PostMessage(559, 3.0);
    end;
    559: begin
      PlayerInfo.InSpace.IncCurrentStep;
      FSaveGame.Save;
      PlayerInfo.InSpace.StepPlayed := PlayerInfo.InSpace.StepPlayed+1;
      FScene.RunScreen(ScreenMeteorStorm);
    end;

    // briefing 4 about the mining and construction of the Gigatron and Radiation Anihilator
    700: begin
      with SpriteMessage(sTheNextMorning) do begin
        Opacity.ChangeTo(0, 4.0, idcStartSlowEndFast);
        KillDefered(4.0);
      end;
      PostMessage(703, 4.0);
    end;
    703: begin
      FBlackScreen.Kill;
      PostMessage(705, 2.0);
    end;
    705: FFather.ShowDialog(sIHopeEveryone, FFontText, Self, 710);
    710: FFather.ShowDialog(sNowThatWeveMadeIt, FFontText, Self, 715);
    715: begin
      FW7.ShowDialog(sSirMayI, FFontText, Self, 720);
      PostMessage(717, 0.7);
    end;
    717: FFather.IdleRight;
    720: FFather.ShowDialog(sOfCourseWWhatIsIt, FFontText, Self, 725);
    725: FW7.ShowDialog(sDuringYourRest, FFontText, Self, 730);
    730: FW7.ShowDialog(sItSeemsThePortal, FFontText, Self, 735);
    735: FPenelope.ShowDialog(sThenItsHopeless, FFontText, Self, 740);
    740: FW7.ShowDialog(sISaidNormally, FFontText, Self, 745);
    745: FFather.ShowDialog(sWhatDoYouMean, FFontText, Self, 750);
    750: FW7.ShowDialog(sTheMeteorsFrom, FFontText, Self, 755);
    755: begin
      FPenelope.ShowDialog(sWhatButThatsGreat, FFontText, Self, 760);
      PostMessage(757, 0.7);
    end;
    757: FFather.IdleLeft;
    760: FGranny.ShowDialog(sItsAStrangeCoincidence, FFontText, Self, 765);
    765: begin
      FW7.ShowDialog(sYesMaamItsVeryStrange, FFontText, Self, 770);
      PostMessage(767, 0.7);
    end;
    767: FFather.IdleRight;
    770: FFather.ShowDialog(sIsThereAnExplanation, FFontText, Self, 775);
    775: FW7.ShowDialog(sIveTurnedTheEvents, FFontText, Self, 780);
    780: FMarcus.ShowDialog(sWhatQuestion, FFontText, Self, 785);
    785: FW7.ShowDialog(sSentVeryLikely, FFontText, Self, 790);
    790: begin
      FMarcus.ShowDialog(sPfffSoundsLike, FFontText, Self, 795);
      PostMessage(793, 0.7);
    end;
    793: FW7.IdleRight;
    795: FW7.ShowDialog(sIRanAFullDiag, FFontText, Self, 800);
    800: begin
      FMother.ShowDialog(sW7IsRightLook, FFontText, Self, 805);
      PostMessage(803, 0.7);
      PostMessage(802, 0.5);
    end;
    802: FW7.IdleLeft;
    803: FFather.IdleLeft;
    805: FFather.ShowDialog(sItIsIndeedStrange, FFontText, Self, 810);
    810: FFather.ShowDialog(sOurFocusMustRemain, FFontText, Self, 815);
    815: FPenelope.ShowDialog(sIveGotNamesForThem, FFontText, Self, 820);
    820: FFather.ShowDialog(sApprovedEveryone, FFontText, Self, 825, 0.6);
    825: begin
      PostMessage(827, 0.5);
      FLR.IdleRight;
      FLR.WalkHorizontallyTo(FScene.Width+FLR.BodyWidth*2, Self, 99999);
    end;
    827: begin
      FMarcus.IdleRight;
      FMarcus.WalkHorizontallyTo(FScene.Width+FMarcus.BodyWidth*2, Self, 99999);
      PostMessage(830, 2.0);
    end;
    830: begin
      PlayerInfo.InSpace.IncCurrentStep;
      FSaveGame.Save;
      PlayerInfo.InSpace.StepPlayed := PlayerInfo.InSpace.StepPlayed + 1;
      FScene.RunScreen(ScreenHarvestingInSpace);
    end;

    // the big jump
    900: PostMessage(905, 2.0);
//    900:begin FsndMilitaryBriefing.stop; postmessage(1020); end;
    905: FFather.ShowDialog(sEverythingIsReadyForTheBigJump, FFontText, Self, 910);
    910: begin
      FsndMilitaryBriefing.FadeOutThenKill(12.0);
      FsndMilitaryBriefing := NIL;
      FPenelope.ShowDialog(sOkButHumanOrWolf, FFontText, Self, 915);
    end;
    915: FLR.ShowDialog(sSomethingTellsMeIts, FFontText, Self, 920);
    920: FMarcus.ShowDialog(sAndYouAChild, FFontText, Self, 925);
    925: begin
      FLR.SetFaceType(lrfWorry);
      FLR.ShowDialog(sNoThatNotWhat, FFontText, Self, 930);
    end;
    930: FMarcus.ShowDialog(sHumansAreAllTheSame, FFontText, Self, 935);
    935: begin
      FLR.ShowDialog(sAndICouldSayTheSame, FFontText, Self, 940, 2.0);
      PostMessage(937, 0.5);
    end;
    937: FMother.IdleLeft;
    940: begin
      FFather.ShowDialog(sThatsWhatIDid, FFontText, Self, 945);
      PostMessage(943, 0.7);
    end;
    943: FMother.IdleRight;
    945: FFather.ShowDialog(sThatExactlyWhatIve, FFontText, Self, 950);
    950: FFather.ShowDialog(sButNowImOld, FFontText, Self, 955);
    955: begin
      FMarcus.ShowDialog(sDad, FFontText, Self, 960);
      PostMessage(957, 0.5);
    end;
    957: begin
      FFather.IdleRight;
      FPenelope.ShowExclamationMark;
      PostMessage(958, 2.0);
    end;
    958: FPenelope.HideMark;
    960: FFather.ShowDialog(sAndIThinkThatMayBe, FFontText, Self, 965);
    965: FFather.ShowDialog(sWeDontNeedMuch, FFontText, Self, 967);
    967:begin
      FFather.IdleLeft;
      PostMessage(970, 0.5);
    end;
    970: FFather.ShowDialog(sINowKnowThat, FFontText, Self, 975);
    975: FMother.ShowDialog(sIFeelThatWayToo, FFontText, Self, 980, 1.0);
    980: FLR.ShowDialog(sThankYouForBeingSoHonest, FFontText, Self, 985);
    985: FFather.ShowDialog(sNoDontBeSorry, FFontText, Self, 990);
    990: FFather.ShowDialog(sWeDontLiveInAFairyTale, FFontText, Self, 995);
    995: FGranny.ShowDialog(sWeMustLiveAccording, FFontText, Self, 1000);
    1000: FMother.ShowDialog(sThatsRightButInTheEnd, FFontText, Self, 1005);
    1005: begin
      FPenelope.ShowDialog(sAndIfWeHaventLearned, FFontText, Self, 1010);
      PostMessage(1007, 0.6);
    end;
    1007: FFather.IdleRight;
    1010: FLR.ShowDialog(sYesThatsExactlyWhatMy, FFontText, Self, 1015);
    1015: begin
      FGranny.ShowDialog(sAtNightHeWould, FFontText, Self, 1020);
      PostMessage(1017, 0.6);
    end;
    1017: FFather.IdleLeft;
    1020: begin
      FsndMusic := Audio.AddMusic('Gigatron.ogg', True);
      FsndMusic.Volume.Value := 0.8;
      FsndMusic.Play(True);
      FGate.StartRotate;
      FGate.Scale.ChangeTo(PointF(2.5, 2.5), 95);
      PostMessage(1025, 2.0);
      FStarsBG.StarJump.ZSpeed.Changeto(0.5, 6.0, idcSinusoid);
    end;
    1025: begin
      FW7.IdleLeft;
      FW7.ShowDialog(sSirIApologizeForDisturbing, FFontText, 4.0);
      PostMessage(1030, 4.5);
      PostMessage(1027, 0.6);
    end;
    1027: FFather.IdleRight;
    1030: begin
      FPenelope.ShowDialog(sWhyAreWeMoving, FFontText, 4.0);
      PostMessage(1035, 4.5);
      PostMessage(1033, 2.0);
    end;
    1033: FW7.IdleRight;
    1035: begin
      FW7.ShowDialog(sNotTheGigatron, FFontText, 4.0);
      PostMessage(1040, 6.0);
    end;
    1040: begin
      FW7.ShowDialog(sTheGigatronIsFully, FFontText, 4.0);
      PostMessage(1045, 4.5);
    end;
    1045: begin
      FMarcus.ShowDialog(sButWhoActivatedIt, FFontText, 4.0);
      PostMessage(1050, 4.5);
    end;
    1050: begin
      FW7.ShowDialog(sIDontKnowTheProbe, FFontText, 5.0);
      PostMessage(1055, 5.5);
    end;
    1055: begin
      FFather.ShowDialog(sEveryoneToLookLike, FFontText, 6.0);
      PostMessage(1060, 6.5);
      PostMessage(1057, 0.6);
    end;
    1057: FW7.IdleLeft;
    1060: begin
      FPenelope.WalkHorizontallyTo(ScaleW(235), Self, 1065);
      FPenelope.Y.ChangeTo(ScaleH(619), 3.0, idcSinusoid);
      FMarcus.WalkHorizontallyTo(ScaleW(800), Self, 1062);
      FMarcus.Y.ChangeTo(ScaleH(619), 1.5, idcSinusoid);
      FLR.WalkHorizontallyTo(FScene.Width*0.5, Self, 1061);
    end;
    1061: FLR.IdleUp;
    1062: begin
      FMarcus.IdleLeft;
      PostMessage(1063, 0.5);
    end;
    1063: begin
      FMainBridge.RightSeat.SetCharacter(FMarcus);
      PostMessage(1064, 0.6);
    end;
    1064: FMainBridge.RightSeat.FlipH := True;
    1065: begin
      FPenelope.IdleRight;
      PostMessage(1070, 0.5);
    end;
    1070: begin
      FMainBridge.LeftSeat.SetCharacter(FPenelope);
      PostMessage(1075, 0.6);
    end;
    1075: begin
      FMainBridge.LeftSeat.FlipH := False;
      PostMessage(1080, 3.0);
    end;
    1080: begin
      FGate.OpenPhase1(10);
      PostMessage(1085, 2.0);
    end;
    1085: begin
      FMainBridge.ShowAlert(texMessRadiation);
      FW7.ShowDialog(sDetectionOfStrong, FFontText, 4.0);
      PostMessage(1090, 4.5);
    end;
    1090: begin
      FPenelope.ShowDialog(sOkImActivatingTheRadiation, FFontText, 4.0);
      PostMessage(1094, 4.5);
      PostMessage(1093, 3.0);
    end;
    1093: begin // red ambiance
      c := BGRA(185,0,0,120);
      FMainBridge.ApplyTint(c);
      FLR.ApplyTint(c);
      FGranny.ApplyTint(c);
      FW7.ApplyTint(c);
      FMarcus.ApplyTint(c);
      FPenelope.ApplyTint(c);
      FMother.ApplyTint(c);
      FFather.ApplyTint(c);
      FW7.ApplyTint(c);
    end;
    1094: begin
      FPenelope.ShowDialog(sRadiationNeutralized, FFontText, 4.0);
      FMainBridge.KillAlert;
      PostMessage(1095, 4.0);
    end;
    1095: if FGate.Done Then PostMessage(1100) else PostMessage(1095);
    1100: begin
      FGate.OpenPhase2(10);
      PostMessage(1105, 4.5);
    end;
    1105: begin
      FW7.ShowDialog(sTheGateActivity, FFontText, 4.0);
      FGate.OpenPhase3(10);
      PostMessage(1110, 10.0);
    end;
    1110: begin
      FW7.ShowDialog(sGigatronOverload, FFontText, 4.0);
      FGate.OpenPhase4(10);
      FsndMusic.FadeOut(15.0);
      Audio.PlayThenKillSound('warp-speed.ogg', 1.0);
      PostMessage(1113, 17.0); // resume music
      PostMessage(1115, 13.8);
    end;
    1113: begin
      FsndMusic.TimePosition := 103.989;
      FsndMusic.Volume.Value := 0.8;
      FsndMusic.Play(False);
    end;
    1115: begin
      FBlackScreen.Visible := True;
      FBlackScreen.Opacity.ChangeTo(0, 5.0);
      FStarsBG.Starnest.ScrollingAngle.Value := 0;
      FStarsBG.Starnest.Visible := False;
      //FStarsBG.KillStarJump;
      FStarsBG.StarJump.Visible := False;
      FStarsBG.StarJump.Freeze := True;
      FGate.Visible := False;
      FGate.Freeze := True;
      FStarsBG.InterstellarJump.Visible := True;
      FStarsBG.InterstellarJump.ZSpeed.Value := 1.0;
      FStarsBG.InterstellarJump.TrailLength.Value := 0.8;
      PostMessage(1120, 5.0);
    end;
    1120: begin
      FW7.ShowDialog(sSirIThinkWereInHyperspace, FFontText, 4.0);
      PostMessage(1123, 0.7);
      PostMessage(1122, 1.0);
      PostMessage(1125, 4.5);
    end;
    1122: FMainBridge.RightSeat.FlipH := False;
    1123: FMainBridge.LeftSeat.FlipH := True;
    1125: begin
      FPenelope.ShowDialog(sWowItWorks, FFontText, 3.0);
      PostMessage(1130, 3.5);
    end;
    1130: begin
      FFather.ShowDialog(sThatsIncredible, FFontText, 4.0);
      PostMessage(1132, 6.0);
    end;
    1132: begin
      FW7.ShowDialog(sTheRadiationsHasStopped, FFontText, 4.0);
      PostMessage(1133, 4.5);
    end;
    1133: begin  // remove tint
      c := BGRA(0,0,0,0);
      FMainBridge.ApplyTint(c);
      FLR.ApplyTint(c);
      FGranny.ApplyTint(c);
      FW7.ApplyTint(c);
      FMarcus.ApplyTint(c);
      FPenelope.ApplyTint(c);
      FMother.ApplyTint(c);
      FFather.ApplyTint(c);
      FW7.ApplyTint(c);
      PostMessage(1135,4.0);
    end;
    1135: begin
      ShowNarratorMessage(sThatNightNoOneWentToBed, 9.0);
      PostMessage(1140, 11.0);
    end;
    1140: begin
      ShowNarratorMessage(sTheyWereAwareThat, 14.0);
      PostMessage(1145, 15.0);
    end;
    1145: begin
      PlayerInfo.InSpace.IncCurrentStep;
      FSaveGame.Save;
      //FScene.RunScreen(ScreenMap);
      with SpriteMessage(sToBeContinued) do begin
        RightX := FScene.Width;
        BottomY := FScene.Height;
      end;
    end;

  end;
end;

procedure TScreenMotherShipMainBridge.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  // check if player pause the game
  if Input.PausePressed then
    FPausePanel.ShowModal;
end;

end.

