unit u_screen_msconstruction;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes, BGRAPath,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon, u_wolfmothership;

type


{ TScreenMotherShipConstruction }

TScreenMotherShipConstruction = class(TGameScreenTemplate)
  private type TGameState=(gsUndefined, gsRunning);
  var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FPausePanel: TInGamePausePanel;
  FStars: TStarsBG;
  FBuildStepIndex: Integer;
  FBuildMarcusMessage: String;
  FBuildData: array of TArrayOfInteger;
  FUserValueWhenCompleted: TUserMessageValue;
  FBlackScreen: TQuad4Color;

  FsndSpaceShipAmbiance: TALSSound;

  procedure SetTopViewInSpace;
  procedure SetViewInConstructionUnit;
  procedure ResetVariables;
public
  procedure DefineSubTextures(aAtlas: TAtlas); override;
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenMotherShipConstruction: TScreenMotherShipConstruction;

implementation
uses Forms, u_app, u_mousepointer, u_screen_map, u_sprite_wolf, u_utils,
  u_procedural_starnest, u_resourcestring, u_screen_msmainbridge,
  u_screen_msharvesting;

var
  FAtlas: TOGLCTextureAtlas;
  FFontText: TTexturedFont;
  FConstructionUnit: TConstructionUnit;
  FMarcus: TWolfMarcus;
  FMotherShip: TMotherShipTopView;
  FMiningShip: TMiningShip;
  FCombatShip: TCombatShip;

{ TScreenMotherShipConstruction }

procedure TScreenMotherShipConstruction.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;
end;

procedure TScreenMotherShipConstruction.SetTopViewInSpace;
begin
  PostMessage(1000);
end;

procedure TScreenMotherShipConstruction.SetViewInConstructionUnit;
begin
  PostMessage(1100);
end;

procedure TScreenMotherShipConstruction.ResetVariables;
begin

end;

procedure TScreenMotherShipConstruction.DefineSubTextures(aAtlas: TAtlas);
begin
  AdditionnalScale := 1.0;
  LoadWolfTextures(aAtlas);
  LoadMarcusTextures(aAtlas);
  AdditionnalScale := 1.0;
  LoadConstructionUnitTextures(aAtlas);
  LoadMiningShipTextures(aAtlas);
  LoadRedCombatShipTextures(aAtlas);
  TMotherShipTopView.LoadTexture(aAtlas);
  AdditionnalScale := 1.0;

  AddSphereParticleToAtlas(aAtlas);
  AddCrossParticleToAtlas(aAtlas);

  // ui
  CreateGameFontNumber(aAtlas); // < must be first !
  // font for button in pause panel
  FFontText := CreateGameFontText(aAtlas);
  LoadGameDialogTextures(aAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(aAtlas);
  LoadMousePointerTexture(aAtlas);
end;

procedure TScreenMotherShipConstruction.CreateObjects;
begin
  Audio.PauseMusicTitleMap(3.0);
  FsndSpaceShipAmbiance := Audio.AddSound('spaceship-ambi-roomtone.ogg', 0.0, True);
  FsndSpaceShipAmbiance.FadeIn(0.8, 3.0);

  CheckAtlas(FAtlas, 'spaceconstruction.atlas');

  // stars   LAYER_BG3
  FStars := TStarsBG.Create(LAYER_BG3);
  FStars.Starnest.LoadParamsFromString(STARNEST_SIMPLEHOT);
  FStars.Starnest.ScrollingAngle.Value := 0;
  FStars.Starnest.ScrollingSpeed.Value := FScene.Width*0.000001;

  // room bg   LAYER_GROUND
  FConstructionUnit := TConstructionUnit.Create(FAtlas, FFontText, LAYER_GROUND);

  // marcus
  FMarcus := TWolfMarcus.Create(False, LAYER_GROUND);
  FMarcus.X.Value := ScaleW(100);
  FMarcus.BodyBottomY := ScaleH(739);
  FMarcus.IdleRight;

  // space top view   LAYER_ARROW
  FMotherShip := TMotherShipTopView.Create(LAYER_ARROW, FAtlas, True);
  FMotherShip.StartPropulsors;
  FScene.Layer[LAYER_ARROW].Visible := False;
  if PlayerInfo.InSpace.StepPlayed > 2 then FMotherShip.ShowDockingBay;
  FMotherShip.CenterOnScene;

  FMiningShip := TMiningShip.Create(FAtlas, True);
  FMotherShip.DockShip(FMiningShip);

  FCombatShip := TCombatShip.Create(FAtlas, True);
  FMotherShip.DockShip(FCombatShip);

  // black rectangle for screen transition
  FBlackScreen := TQuad4Color.Create(FScene);
  FScene.Add(FBlackScreen, LAYER_TOP);
  FBlackScreen.SetSize(FScene.Width, FScene.Height);
  FBlackScreen.SetAllColorsTo(BGRA(0,0,0));
  FBlackScreen.Opacity.Value := 0;

  // pause panel
  FPausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  CustomizeMousePointer(True);
  SetGameInstructions(PlayerInfo.InSpace.HelpText);
  PostMessage(0);  // show instructions
end;

procedure TScreenMotherShipConstruction.FreeObjects;
begin
  FScene.Layer[LAYER_ARROW].Visible := True;
  FScene.Layer[LAYER_GROUND].Visible := True;

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

procedure TScreenMotherShipConstruction.ProcessMessage(UserValue: TUserMessageValue);
  procedure StartConstruction(const aMarcusMessage: string; aUserValueWhenCompleted: TUserMessageValue);
  begin
    FBuildStepIndex := 0;
    FBuildMarcusMessage := aMarcusMessage;
    FUserValueWhenCompleted := aUserValueWhenCompleted;
    PostMessage(30);
  end;

begin
  case UserValue of
    // show instructions
    0: begin
      PostMessage(5);
      if PlayerInfo.InSpace.StepPlayed = 2 then ShowGameInstructions(PlayerInfo.InSpace.HelpText)
        else SetGameInstructions(PlayerInfo.InSpace.HelpText);
    end;
    5: begin  // select the sequence to play
      case PlayerInfo.InSpace.StepPlayed of
        2: PostMessage(100, 1.0);  // construct docking bay and mining ship
        5: PostMessage(300, 1.0);  // construct the shield
        7: PostMessage(400, 1.0);  // construct the fighter
        12: PostMessage(500, 1.0); // construct the Gigatron and the radiation annihilator

        else raise exception.Create('bug! stepPlayed='+PlayerInfo.InSpace.StepPlayed.ToString);
      end;//case
    end;
    // loop build steps
    30: FMarcus.ShowDialog(Format(FBuildMarcusMessage, [FBuildStepIndex+1, Length(FBuildData)]), FFontText, Self, 35);
    35: begin
      FConstructionUnit.StartConstruction(FBuildData[FBuildStepIndex], (FBuildStepIndex+1).ToString+'/'+integer(Length(FBuildData)).ToString);
      PostMessage(40);
    end;
    40: begin  // check if construction is done or fail
      if FConstructionUnit.State = cusConstructionDone then PostMessage(45)
      else
      if FConstructionUnit.State = cusConstructionFailed then PostMessage(50, 3.0)
      else PostMessage(40);
    end;
    45: begin  // step done
      inc(FBuildStepIndex);
      if FBuildStepIndex = Length(FBuildData) then PostMessage(FUserValueWhenCompleted) // construction completed ?
        else PostMessage(30, 4.0);
    end;
    50: FMarcus.ShowDialog(sOkLetsFocusAndGetBack, FFontText, Self, 30); // step failed

    // construction of the docking bay
    100: begin
      FBuildData := NIL;
      SetLength(FBuildData, 5);
      FBuildData[0] := [0,3,7,1,5,2];
      FBuildData[1] := [0,3,0,7,3,0,0];
      FBuildData[2] := [0,3,7,0,5,13,10,9];
      FBuildData[3] := [9,12,5,8,10,6,0,11,11,9];
      FBuildData[4] := [13,3,7,11,4,11,4,10,6,9,5,8,1];
      StartConstruction(sConsDockBay, 105);
    end;
    105: FMarcus.ShowDialog(sGreatLetsAssembleBay, FFontText, Self, 110);
    110: begin  // view in space
      SetTopViewInSpace;
      PostMessage(115, 3.0);
    end;
    115: begin
      FMotherShip.MakeDockingBayAppears;
      PostMessage(120, 7.0);
    end;
    120: begin
      SetViewInConstructionUnit;
      PostMessage(200, 2.0);
    end;

    // construction of the mining ship
    200: FMarcus.ShowDialog(sNowLetsMoveOnToThe, FFontText, Self, 205);
    205: begin
      FBuildData := NIL;
      SetLength(FBuildData, 3);
      FBuildData[0] := [0,6,2,7,13,0];
      FBuildData[1] := [2,4,8,13,10,12,3,11];
      FBuildData[2] := [13,0,5,7,8,2,12,9,4];
      StartConstruction(sConsMiningShip, 208);
    end;
    208: FMarcus.ShowDialog(sThereWeGoWeHaveAll, FFontText, Self, 211);
    211: begin  // space view
      FScene.Mouse.MouseSprite.Visible := False;
      SetTopViewInSpace;
      PostMessage(214, 3.0);
    end;
    214: begin  // mining ship fly in space
      //FMiningShip.MoveToLayer(LAYER_ARROW);
      FMiningShip.ExitFromDockingBay_RunPath_EnterDockingBay(FolderConstructionUnit+'PathForMiningShipFirstFly.txt');
      PostMessage(217);
      PostMessage(215, 2.0);
    end;
    215: Audio.PlayMusicSuccessShort1;
    217: if not FMiningShip.AnimDone then PostMessage(217)
           else begin
             PlayerInfo.InSpace.IncCurrentStep;
             FSaveGame.Save;
             PlayerInfo.InSpace.StepPlayed := PlayerInfo.InSpace.StepPlayed + 1;
             FScene.RunScreen(ScreenMotherShipMainBridge);
           end;


    // construction of the shield
    300: FMarcus.ShowDialog(sThisFirstMissionIntoSpace, FFontText, Self, 303, 0.5);
    303: FMarcus.ShowDialog(sPHasDrawnUpThePlans, FFontText, Self, 305);
    305: begin
      FBuildData := NIL;
      SetLength(FBuildData, 3);
      FBuildData[0] := [14,25,31,0,3,32,2,5,32,17,17];
      FBuildData[1] := [9,13,8,4,4,28,4,4,28];
      FBuildData[2] := [24,31,10,21,31,10,25,31,10,9,8,4];
      StartConstruction(sConsShield, 310);
    end;
    310: FMarcus.ShowDialog(sWeGotAllTheComponentForTheShield, FFontText, Self, 315);
    315: begin // space view
      FScene.Mouse.MouseSprite.Visible := False;
      SetTopViewInSpace;
      PostMessage(320, 3.0);
    end;
    320: begin
      FMotherShip.MakeShieldAppears;
      PostMessage(325, 6.0);
    end;
    325: begin
      SetViewInConstructionUnit;
      PostMessage(330, 3.0);
    end;
    330: FMarcus.ShowDialog(sPStillNeedsOre, FFontText, Self, 335);
    335: begin
      PlayerInfo.InSpace.IncCurrentStep;
      PlayerInfo.InSpace.StepPlayed := PlayerInfo.InSpace.StepPlayed + 1;
      FSaveGame.Save;
      FScene.RunScreen(ScreenHarvestingInSpace);
    end;


    // construction of the fighters
    400: FMarcus.ShowDialog(sLetsGetStartedOnBuilding, FFontText, Self, 405, 0.5);
    405: begin
      FBuildData := NIL;
      SetLength(FBuildData, 4);
      FBuildData[0] := [17,28,24,28,18,28,25,28,0,0,0];
      FBuildData[1] := [5,3,12,6,7];
      FBuildData[2] := [13,7,11,3,11,3,1];
      FBuildData[3] := [4,9,10,8];
      StartConstruction(sConsCombatShip, 410);
    end;
    410: FMarcus.ShowDialog(sWeHaveAllPartsOfCombatShip, FFontText, Self, 415, 0.5);
    415: begin
      FScene.Mouse.MouseSprite.Visible := False;
      SetTopViewInSpace;
      PostMessage(420, 3.0);
    end;
    420: begin  // combat ship fly in space
      FCombatShip.ExitFromDockingBay_RunPath_EnterDockingBay(FolderConstructionUnit+'PathForCombatShipFirstFly.txt');
      PostMessage(425);
      PostMessage(423, 2.0);
    end;
    423: Audio.PlayMusicSuccessShort1;
    425: if not FCombatShip.AnimDone then PostMessage(425)
           else begin
             PlayerInfo.InSpace.IncCurrentStep;
             FSaveGame.Save;
             PlayerInfo.InSpace.StepPlayed := PlayerInfo.InSpace.StepPlayed + 1;
             FScene.RunScreen(ScreenMotherShipMainBridge);
           end;

    // construction of the gigatron propulsor and the radiation annihilator
    500: FMarcus.ShowDialog(sWeHaveNewOres, FFontText, Self, 505, 0.5);
    505: FMarcus.ShowDialog(sAsYouCanSeeTheyAre, FFontText, Self, 510, 0.5);
    510: FMarcus.ShowDialog(sEverythingIsReadyLetsGet, FFontText, Self, 515, 0.5);
    515: begin
      FMotherShip.StopPropulsor;
      FStars.Starnest.ScrollingSpeed.Value := 0;
      FBuildData := NIL;
      SetLength(FBuildData, 2);
      FBuildData[0] := [34,24,15,0,20,31,22,0,30,26,18,0,9,8,10];
      FBuildData[1] := [34,24,15,0,20,31,22,0,30,26,18,0,9,8,10];
      StartConstruction(sConsGigatron, 520);
    end;
    520: FMarcus.ShowDialog(sWeHaveAllPartForGigatron, FFontText, Self, 525);
    525: begin // view in space
      FScene.Mouse.MouseSprite.Visible := False;
      SetTopViewInSpace;
      PostMessage(530, 3.0);
    end;
    530: begin
      FMotherShip.MakeGigatronAppears;
      PostMessage(535, 6.0);
    end;
    535: begin
      SetViewInConstructionUnit;
      FScene.Mouse.MouseSprite.Visible := True;
      PostMessage(540, 3.0);
    end;
    540: FMarcus.ShowDialog(sLetContinueWithAnnihilator, FFontText, Self, 545);
    545: begin
      FBuildData := NIL;
      SetLength(FBuildData, 2);
      FBuildData[0] := [15,26,21,29,19,34,3,13,0,10,9,8];
      FBuildData[1] := [15,26,21,29,19,34,3,13,0,10,9,8];
      StartConstruction(sConsAnnihilator, 550);
    end;
    550: FMarcus.ShowDialog(sWereDoneLetsInstall, FFontText, Self, 555);
    555: begin // view in space
      FScene.Mouse.MouseSprite.Visible := False;
      SetTopViewInSpace;
      PostMessage(560, 3.0);
    end;
    560: begin
      FMotherShip.MakeAnnihilatorAppears;
      PostMessage(565, 6.0);
    end;
    565: begin
      PlayerInfo.InSpace.IncCurrentStep;
      FSaveGame.Save;
      PlayerInfo.InSpace.StepPlayed := PlayerInfo.InSpace.StepPlayed + 1;
      FScene.RunScreen(ScreenMotherShipMainBridge);
    end;


    // view in space
    1000: begin
      FBlackScreen.Opacity.ChangeTo(255, 0.5);
      PostMessage(1005, 0.5);
    end;
    1005: begin
      FScene.Layer[LAYER_ARROW].Visible := True;
      FScene.Layer[LAYER_GROUND].Visible := False;
      FStars.Starnest.ScrollingAngle.Value := 90;
      FBlackScreen.Opacity.ChangeTo(0, 0.5);
    end;

    // view in construction unit
    1100: begin
      FBlackScreen.Opacity.ChangeTo(255, 0.5);
      PostMessage(1105, 0.5);
    end;
    1105: begin
      FScene.Layer[LAYER_ARROW].Visible := False;
      FScene.Layer[LAYER_GROUND].Visible := True;
      FStars.Starnest.ScrollingAngle.Value := 0;
      FBlackScreen.Opacity.ChangeTo(0, 0.5);
    end;
  end;
end;

procedure TScreenMotherShipConstruction.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  // check if player pause the game
  if Input.PausePressed then
    FPausePanel.ShowModal;
end;

end.

