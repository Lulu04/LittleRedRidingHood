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
        gsCreatePanelAddScore, gsAddingScore);
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
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property Difficulty: integer write FDifficulty;
end;

var ScreenGameForest: TScreenGame1;
implementation
uses Forms, Controls, LCLType, u_app, u_screen_map, u_utils,
  Math;

{ TScreenGame1 }

procedure TScreenGame1.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then Exit;
  FGameState := AValue;
end;

function TScreenGame1.CheckIfWolfLost: boolean;
begin
  Result := FInGamePanel.Second = 0;
end;

procedure TScreenGame1.ProcessEventBallonExplode;
begin
  FInGamePanel.IncBalloonExploded;
end;

procedure TScreenGame1.CreateObjects;
var ima: TBGRABitmap;
  w: TWolf;
  g: TGround1;
  xx, yy: single;
  i, wolfCount, gameTime, h: integer;
begin
  FGameState := gsUndefined;
  LoadSoundForForestGame;
  sndElevator.Play(True);
  Audio.PauseMusicTitleMap;
  FMusic := Audio.AddMusic('ForestInTheNight.ogg', True);
  FMusic.FadeIn(1.0, 1.0);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 1;

  LoadTexturesForForestGame(FAtlas);
  LoadBaseBallonTexture(FAtlas);
  LoadWolfTextures(FAtlas);
  LoadForestBGTexture(FAtlas);

  CreateGameFontNumber(FAtlas);
  LoadCoinTexture(FAtlas);
  LoadWatchTexture(FAtlas);
  h := IconHeight;
  texIconBallonExploded := FAtlas.AddFromSVG(SpriteUIFolder+'IconBalloonExploded.svg', -1, h);
  texIconHammer := FAtlas.AddFromSVG(SpriteCommonFolder+'HammerHead.svg', -1, h);
  texIconStormCloud := FAtlas.AddFromSVG(SpriteCommonFolder+'StormCloud.svg', -1, h);

  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;
  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

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

  FDifficulty := PlayerInfo.Forest.StepPlayed;
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

  // In game panel
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

  PostMessage(50); // (one frame deferred) show how to play and run game
end;

procedure TScreenGame1.FreeObjects;
var i: integer;
begin
FScene.LogDebug('TScreenGame1.FreeObjects BEGIN');
  FreeSoundForForestGame;
  FMusic.FadeOutThenKill(1.0);
  FMusic := NIL;
  Audio.ResumeMusicTitleMap;

  for i:=0 to High(FWolfGates) do FWolfGates[i].Free;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  FEndGameScorePanel := NIL;
  ResetSceneCallbacks;
FScene.LogDebug('TScreenGame1.FreeObjects END');
end;

procedure TScreenGame1.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // sequence LOSE launch score animation after LR lost the game
    0: begin
      FMusic.FadeOutThenPause(0.5);
      sndElevator.Stop;
      with Audio.AddSound('Explode1.ogg') do begin
        Volume.Value := 0.5;
        PlayThenKill(True);
      end;
      PostMessage(1, 1.5);
    end;
    1: begin
      Audio.PlayMusicLose1;
      PostMessage(10, 2.0);
    end;
    10: begin
      GameState := gsCreatePanelAddScore;
    end;

    // show how to play
    50: begin
      GameState := gsRunning;
      ShowGameInstructions(PlayerInfo.Forest.HelpText);
    end;

    // re-introduce music after jinggle success
    100: begin
      FMusic.FadeIn(1.0, 1.0);
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
        PostMessage(0);
        exit;
      end;

      // check if LR win
      if CheckIfWolfLost then begin
        FMusic.FadeOutThenPause(0.5);
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
      if FEndGameScorePanel.Done and FScene.UserPressAKey then FScene.RunScreen(ScreenMap);
    end;
  end;//case

end;

end.

