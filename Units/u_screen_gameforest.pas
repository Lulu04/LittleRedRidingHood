unit u_screen_gameforest;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_sprite_wolf, u_sprite_gameforest, u_common_ui, u_gamescreentemplate,
  u_ui_panels, u_gamebackground, u_audio;

type

{ TScreenGame1 }

TScreenGame1 = class(TGameScreenTemplate)
private type TGameState=(gsUndefined=0, gsRunning, gsLRLost,
        gsWaitForEscapeDoorToOpen, gsWaitUntilPlatformIsAtTop, gsWaitLRWalksThroughTheDoor,
        gsCreatePanelAddScore, gsAddingScore,
        gsChallengeWin);
  var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FMusic: TALSSound;
  FAtlas: TOGLCTextureAtlas;
  FPlatformLR: TPlatformLR;
  FPlatformLRMinY, FPlatformLRMaxY: single;
  FLR: TLRWithBow;
  FElevatorEngine: TElevatorEngine;
  FWolfGates: array of TWolfGate;
  FBalloonCrates: array of TBalloonCrate;
  FEscapeDoor: TEscapeDoor;

  FForestBG: TForestBG;

  FHammer: THammer;
  FStormCloud: TStormCloud;

  FInGamePanel: TInGamePanel;
  FEndGameScorePanel: TEndGameScorePanel;
  FInGamePausePanel: TInGamePausePanel;
  FFontText: TTexturedFont;

  FDifficulty: integer;
  FPlatformMoveDeltaY: single;
  function CheckIfWolfLost: boolean;
  procedure ProcessEventBallonExplode;
  property GameState: TGameState read FGameState write SetGameState;
public
  procedure DefineSubTextures(aAtlas: TAtlas); override;
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property Difficulty: integer write FDifficulty;
end;

var ScreenGameForest: TScreenGame1;
implementation
uses Forms, Controls, LCLType, u_app, u_screen_map, u_utils, u_mousepointer,
  Math, u_sprite_lrcommon, u_resourcestring,
  u_screen_workshop;

{ TScreenGame1 }

procedure TScreenGame1.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then Exit;
  FGameState := AValue;
  case AValue of
    gsChallengeWin: PostMessage(200);
  end;
end;

function TScreenGame1.CheckIfWolfLost: boolean;
begin
  Result := FInGamePanel.Second = 0;
end;

procedure TScreenGame1.ProcessEventBallonExplode;
begin
  FInGamePanel.IncBalloonExploded;
end;

procedure TScreenGame1.DefineSubTextures(aAtlas: TAtlas);
var path: string;
  h: integer;
begin
  LoadLRFaceTextures(aAtlas);

  path := SpriteFolder;
  texLRDress := aAtlas.AddFromSVG(path+'LittleRedDress.svg', ScaleW(62), -1);
  texLRHood := aAtlas.AddFromSVG(path+'LittleRedHood.svg', ScaleW(86), -1);
  texLRLeftLeg := aAtlas.AddFromSVG(path+'LittleRedLeftLeg.svg', ScaleW(20), -1);
  texLRRightLeg := aAtlas.AddFromSVG(path+'LittleRedRightLeg.svg', ScaleW(19), -1);
  texLRArmForBow := aAtlas.AddFromSVG(path+'LittleRedArmForBow.svg', ScaleW(50), -1);
  texLRLeftCloak := aAtlas.AddFromSVG(path+'LittleRedLeftCloak.svg', ScaleW(68), -1);
  texLERightCloak := aAtlas.AddFromSVG(path+'LittleRedRightCloak.svg', ScaleW(59), -1);
  texLRBow := aAtlas.AddFromSVG(path+'LittleRedBow.svg', -1, ScaleH(117));

  texLRArrow := aAtlas.AddFromSVG(SpriteCommonFolder+'LRArrow.svg', ScaleW(53), -1);

  texPlatformLR := aAtlas.AddFromSVG(SpriteCommonFolder+'PlatformLR.svg', ScaleW(106), -1);
  texMotorBody := aAtlas.AddFromSVG(SpriteCommonFolder+'MotorBody.svg', ScaleW(100), -1);
  texMotorBigWheel := aAtlas.AddFromSVG(SpriteCommonFolder+'MotorBigWheel.svg', ScaleW(32), -1);
  texMotorSmallWheel := aAtlas.AddFromSVG(SpriteCommonFolder+'MotorSmallWheel.svg', ScaleW(20), -1);
  texMotorLeftPiston := aAtlas.AddFromSVG(SpriteCommonFolder+'MotorLeftPiston.svg', ScaleW(25), -1);
  AddSphereParticleToAtlas(aAtlas);
  AddCrossParticleToAtlas(aAtlas);

  texBalloonCrate := aAtlas.AddFromSVG(SpriteCommonFolder+'BalloonCrate.svg', ScaleW(70), -1);

  LoadGround1Texture(aAtlas);

  path := SpriteCommonFolder;
  texEscapeDoorAboveUp := aAtlas.AddFromSVG(path+'EscapeDoorAboveUp.svg', ScaleW(68){PPIScale(68)}, -1);
  texEscapeDoorAboveDown := aAtlas.AddFromSVG(path+'EscapeDoorAboveDown.svg', ScaleW(70){PPIScale(70)}, -1);
  texEscapeDoorBelowUp := aAtlas.AddFromSVG(path+'EscapeDoorBelowUp.svg', -1, ScaleH(175){PPIScale(175)});
  texEscapeDoorBelowDown := aAtlas.AddFromSVG(path+'EscapeDoorBelowDown.svg', -1, ScaleH(216){PPIScale(216)});
  texEscapeDoorStone := aAtlas.AddFromSVG(path+'EscapeDoorStone.svg', -1, ScaleH(194){PPIScale(194)});

  path := SpriteCommonFolder;
  texHammerBox := aAtlas.AddFromSVG(path+'HammerBox.svg', ScaleW(55), -1);
  texHammerArmPart := aAtlas.AddFromSVG(path+'HammerArmPart.svg', -1, ScaleH(25));
  texHammerHead := aAtlas.AddFromSVG(path+'HammerHead.svg', ScaleW(46), -1);
  texHammerPaf :=  aAtlas.AddFromSVG(path+'PafHammer.svg', ScaleW(55*3), -1);

  texStormCloud := aAtlas.AddFromSVG(SpriteCommonFolder+'StormCloud.svg', Round(FScene.Width/5), -1);
  AddRainDropParticleToAtlas(aAtlas);

  LoadBaseBallonTexture(aAtlas);
  LoadWolfTextures(aAtlas);
  texPine := aAtlas.AddFromSVG(SpriteBGFolder+'TreePine.svg', ScaleW(234), -1);


  CreateGameFontNumber(aAtlas);
  LoadCoinTexture(aAtlas);
  LoadWatchTexture(aAtlas);
  h := IconHeight;
  texIconBallonExploded := aAtlas.AddFromSVG(SpriteUIFolder+'IconBalloonExploded.svg', -1, h);
  texIconHammer := aAtlas.AddFromSVG(SpriteUIFolder+'IconHammer.svg', -1, h);
  texIconStormCloud := aAtlas.AddFromSVG(SpriteUIFolder+'IconStormCloud.svg', -1, h);

  // font for button in pause panel
  FFontText := CreateGameFontText(aAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(aAtlas);
  LoadMousePointerTexture(aAtlas);
end;

procedure TScreenGame1.CreateObjects;
var w: TWolf;
  g: TGround1;
  xx, yy: single;
  i, wolfCount, gameTime: integer;
begin
  FGameState := gsUndefined;
  LoadSoundForForestGame;
  sndElevator.Play(True);
  Audio.PauseMusicTitleMap;
  FMusic := Audio.AddMusic('ForestInTheNight.ogg', True);
  FMusic.FadeIn(1.0, 1.0);

  CheckAtlas(FAtlas, 'pineforest.atlas');

  // background
  FForestBG := TForestBG.Create;
  FForestBG.Free;

  // ground at the bottom of the screen
  xx := -5;
  while xx < FScene.Width do begin
    g := TGround1.Create;
    g.SetCoordinate(xx, FScene.Height-g.Height*0.75);
    xx := xx + g.Width;
  end;

  // ground at the top of the screen
  w := TWolf.Create(True);
  xx := -5;
  yy := w.BodyHeight*1.1; // PPIScale(150);
  while xx < FScene.Width do begin
    g := TGround1.Create;
    g.SetCoordinate(xx, yy);
    xx := xx + g.Width;
  end;
  w.Kill;

  // elevator engine                                      LAYER_FXANIM
  FElevatorEngine := TElevatorEngine.Create(FAtlas);
  FElevatorEngine.SetCoordinate(PPIScale(50), yy-FElevatorEngine.Body.Height*0.75);

  // player + platform
  FPlatformLR := TPlatformLR.Create;
  FPlatformLR.CenterX := FElevatorEngine.X.Value + FElevatorEngine.Body.Width*0.5;
  FPlatformLR.Y.Value := FScene.Height*0.5;
  FLR := TLRWithBow.Create;
  FPlatformLR.AddChild(FLR, 1);
  FLR.CenterX := FPlatformLR.Width*0.5;
  FLR.BottomY := FPlatformLR.Height*0.85;

  // escape door
  FEscapeDoor := TEscapeDoor.Create;
  FEscapeDoor.SetCoordinate(0, yy + g.Height*0.7);

  if ChallengeMode then FDifficulty := 10
    else FDifficulty := PlayerInfo.Forest.StepPlayed;
{PlayerInfo.Forest.ElevatorLevel:=5;
PlayerInfo.Forest.BowLevel := 5;
PlayerInfo.Forest.HammerLevel := 5;
PlayerInfo.Forest.StormCloudLevel := 3;  }


  // wolf gates
  SetLength(FWolfGates, 2);
  FWolfGates[0] := TWolfGate.Create(PointF(FScene.Width+texWolfHead^.FrameWidth, FScene.Height-g.Height*0.45), False);
  FWolfGates[0].AppearTime := 1.0;
  FWolfGates[0].YGroundAtTheTopOfTheScreen := yy+g.Height*0.25;
  FWolfGates[0].OnCheckIfLost := @CheckIfWolfLost;
  FWolfGates[0].OnBalloonExplode := @ProcessEventBallonExplode;
  FWolfGates[0].TargetElevatorEngine := FElevatorEngine;
  FWolfGates[1] := TWolfGate.Create(PointF(-texWolfHead^.FrameWidth, FScene.Height-g.Height*0.45), True);
  FWolfGates[1].AppearTime := 1.0;
  FWolfGates[1].YGroundAtTheTopOfTheScreen := yy+g.Height*0.25;
  FWolfGates[1].OnCheckIfLost := @CheckIfWolfLost;
  FWolfGates[1].OnBalloonExplode := @ProcessEventBallonExplode;
  FWolfGates[1].TargetElevatorEngine := FElevatorEngine;

  // balloon crates                           LAYER_FXANIM
  SetLength(FBalloonCrates, EnsureRange(FDifficulty, 3, 7));
  xx := FScene.Width*0.9/(Length(FBalloonCrates)+1);
  for i:=0 to High(FBalloonCrates) do begin
    FBalloonCrates[i] := TBalloonCrate.Create(FScene.Width*0.1+xx*(i+1), FScene.Height-g.Height*0.35-texBalloonCrate^.FrameHeight);
  end;

  // sets the difficulty
  gameTime := 60 + FDifficulty*3;
  FLR.ArrowRearmTimeMultiplicator := PlayerInfo.Forest.Bow.ArrowRearmTimeMultiplicator;
  FPlatformMoveDeltaY := PlayerInfo.Forest.Elevator.Speed;
  wolfCount := 3 + FDifficulty div 2;
  if FDifficulty <= 1 then begin
    // one gate
    FWolfGates[0].Count := wolfCount*2;
    FWolfGates[1].Count := 0;
  end else begin
    // two gate
    FWolfGates[0].Count := wolfCount;
    FWolfGates[1].Count := wolfCount;
  end;
  for i:=0 to High(FWolfGates) do begin
    FWolfGates[i].AppearTime := Max(0.2, 1.0 - FDifficulty*0.05);
    FWolfGates[i].TimeMultiplicator := Max(0.4, 1.2-FDifficulty*0.15);
  end;

  FPlatformLRMinY := g.BottomY+g.Height*0.25;
  FPlatformLRMaxY := FScene.Height*0.85-FPlatformLR.Height;

  // In game inventory panel
  FInGamePanel := TInGamePanel.Create;
  FInGamePanel.Second := gameTime;
  FInGamePanel.StartTime;

  // pause panel
  FInGamePausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  // hammer
  FHammer := NIL;
  if PlayerInfo.Forest.Hammer.Level <> 0 then begin
    FHammer := THammer.Create(FInGamePanel, FWolfGates[0].TimeMultiplicator);
    FHammer.SetCoordinate(FElevatorEngine.Body.Width*2, yy+g.Height*0.25-FHammer.Height);
  end;

  // storm cloud
  FStormCloud := NIL;
  if PlayerInfo.Forest.StormCloud.Level <> 0 then
    FStormCloud := TStormCloud.Create(FAtlas);


 // FScene.Mouse.SystemMouseCursorVisible := False;
  CustomizeMousePointer;

  if ChallengeMode then PostMessage(60) // show challenge mode then play
    else PostMessage(50); // (one frame deferred) show how to play and run game
end;

procedure TScreenGame1.FreeObjects;
var i: integer;
begin
  FreeMousePointer;
  FreeSoundForForestGame;
  FMusic.FadeOutThenKill(1.0);
  FMusic := NIL;

  if FScene.RequestedScreen = ScreenMap then
    Audio.ResumeMusicTitleMap;

  for i:=0 to High(FWolfGates) do FWolfGates[i].Free;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  FEndGameScorePanel := NIL;
  ResetSceneCallbacks;
  ChallengeMode := False;
end;

procedure TScreenGame1.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // sequence LOSE launch score animation after LR lost the game
    0: begin
      FMusic.FadeOutThenPause(0.5);
      sndElevator.Stop;
      Audio.PlayThenKillSound('Explode1.ogg', 0.6);
      PostMessage(1, 1.5);
    end;
    1: begin
      Audio.PlayMusicLose1;
      PostMessage(10, 2.0);
    end;
    10: begin
      if ChallengeMode then PostMessage(300)
        else GameState := gsCreatePanelAddScore;
    end;

    // game mode: show how to play
    50: begin
      GameState := gsRunning;
      ShowGameInstructions(PlayerInfo.Forest.HelpText);
    end;

    // challenge mode
    60: begin
      with SpriteMessage(sChallenge) do KillDefered(2.0);
      PostMessage(62, 2.0);
    end;
    62: GameState := gsRunning;

    // re-introduce music after jinggle success
    100: begin
      FMusic.FadeIn(1.0, 1.0);
    end;

    // CHALLENGE WINNED
    200: begin
      if sndStorm <> NIL then sndStorm.FadeOut(0.5);
      if sndPulley <> NIL then sndPulley.Stop;
      if sndElevator <> NIL then sndElevator.Stop;
      if FStormCloud <> NIL then FStormCloud.Hide;
      PostMessage(202);
    end;
    202: PlaySequenceWinTrophy('TrophyTreePine.svg', FAtlas, 205, 0);
    205: begin
      PlayerInfo.Forest.ChallengeIsTerminated := True;
      FSaveGame.Save;
      FScene.RunScreen(ScreenWorkshop);
    end;

    // CHALLENGE LOST
    300: begin
      if sndStorm <> NIL then sndStorm.FadeOut(0.5);
      if sndPulley <> NIL then sndPulley.Stop;
      if sndElevator <> NIL then sndElevator.Stop;
      if FStormCloud <> NIL then FStormCloud.Hide;
      FMusic.FadeOutThenPause(0.5);
      Audio.PlayThenKillSound('Explode1.ogg', 0.6);
      PostMessage(305, 1.5);
    end;
    305: begin
      Audio.PlayMusicLose1;
      with SpriteMessage(sFail) do CenterOnScene;
      PostMessage(310, 2.0);
    end;
    310: begin
      FScene.RunScreen(ScreenMap);
    end;
  end;
end;

procedure TScreenGame1.Update(const aElapsedTime: single);
var i: integer;
begin
  inherited Update(aElapsedTime);

  case GameState of
    gsRunning: begin
      // move player platform up/down
      if FElevatorEngine.EngineON then begin
        if Input.UpPressed and (FPlatformLR.Y.Value > FPlatformLRMinY) then begin
          FPlatformLR.Y.Value := FPlatformLR.Y.Value - FPlatformMoveDeltaY*aElapsedTime;
          FElevatorEngine.SetWheelRotation(-1);
        end else if Input.DownPressed and (FPlatformLR.Y.Value < FPlatformLRMaxY) then begin
          FPlatformLR.Y.Value := FPlatformLR.Y.Value + FPlatformMoveDeltaY*aElapsedTime;
          FElevatorEngine.SetWheelRotation(1);
        end else begin
          FElevatorEngine.SetWheelRotation(0);
        end;

        FElevatorEngine.SetRopeEndPoint(FPlatformLR.Y.Value);
      end
      else
      // check if LR lost
      if FElevatorEngine.Breaked then begin
        FLR.State := lrsLoser;
        FInGamePanel.PauseTime;
        GameState := gsLRLost;
        if ChallengeMode then PostMessage(300)
          else PostMessage(0);
        exit;
      end;

      // check if LR win
      if CheckIfWolfLost then begin
        FMusic.FadeOutThenPause(0.5);
        if ChallengeMode then begin
          GameState := gsChallengeWin;
          exit;
        end else begin
          Audio.PlayMusicSuccess1;
          PostMessage(100, 6); // fadein FMusic
          Audio.PlayVoiceWhowhooo;
          FLR.State := lrsWinner;
          FEscapeDoor.OpenTheDoor;
          GameState := gsWaitForEscapeDoorToOpen;
          FInGamePanel.PauseTime;
          if FStormCloud <> NIL then FStormCloud.Hide;
          exit;
        end;
      end;

      // shoot arrow
      if Input.Action1Pressed {and
         not FElevatorEngine.Breaked and
         not CheckIfWolfLost} then FLR.ShootArrow;

      // storm cloud ?
      if (FStormCloud <> NIL) and
         FStormCloud.CanShoot and
         Input.Action2Pressed and
         FInGamePanel.StormCloudAvailable {and
         not FElevatorEngine.Breaked  and
         not CheckIfWolfLost} then begin
           FStormCloud.Shoot;
           FInGamePanel.DecStormCloudCount;
         end;

      // wolf gates
      for i:=0 to High(FWolfGates) do
        FWolfGates[i].Update(aElapsedTime);

      // check if player pause the game
      if Input.PausePressed then begin
        FInGamePausePanel.ShowModal;
      end;
    end;

    gsWaitForEscapeDoorToOpen: begin
      if FEscapeDoor.DoorIsOpened then begin
        FPlatformLR.Y.AddConstant(-FPlatformLR.Height*0.5);
        FElevatorEngine.SetWheelRotation(-1);
        GameState := gsWaitUntilPlatformIsAtTop;
      end;
    end;

    gsWaitUntilPlatformIsAtTop: begin
      if FPlatformLR.Y.Value <= FPlatformLRMinY then begin
        sndElevator.Stop;
        FPlatformLR.Y.Value := FPlatformLRMinY;
        FElevatorEngine.SetWheelRotation(0);
        FElevatorEngine.EngineON := False;
        FLR.State := lrsWalkToTheLeft;
        GameState := gsWaitLRWalksThroughTheDoor;
      end;
      FElevatorEngine.SetRopeEndPoint(FPlatformLR.Y.Value);
    end;

    gsWaitLRWalksThroughTheDoor: begin
      if FLR.State = lrsDisappearedThroughTheDoor then begin
        PlayerInfo.Forest.IncCurrentStep;
        FSaveGame.Save;
        // lancer l'animation de score/bonus
        GameState := gsCreatePanelAddScore;
      end;
    end;

    gsCreatePanelAddScore: begin
      FEndGameScorePanel := TEndGameScorePanel.Create(FInGamePanel);
      GameState := gsAddingScore;
    end;

    gsAddingScore: begin
      if FEndGameScorePanel.Done and FScene.UserPressAKey then
        FScene.RunScreen(ScreenMap);
    end;
  end;//case

end;

end.

