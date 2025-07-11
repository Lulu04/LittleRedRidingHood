unit u_screen_gamesnakefissureintro;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon;

type


{ TScreenSnakeFissureIntro }

TScreenSnakeFissureIntro = class(TGameScreenTemplate)
private type TGameState=(gsUndefined, gsRunning);
var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FPausePanel: TInGamePausePanel;
  FsndSeaWave, FsndEngine, FsndBubble: TALSSound;
  FBlueBG: TGradientRectangle;
  FBubbles: TParticleEmitter;
  procedure ResetVariables;
  procedure CreateLevel;
  procedure CreateBubbleEffect;
public
  procedure DefineSubTextures(aAtlas: TAtlas); override;
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenSnakeFissureIntro: TScreenSnakeFissureIntro;


implementation

uses Forms, u_app, u_sprite_lr4dir, u_mousepointer, u_screen_map, u_utils,
  u_resourcestring, u_sprite_def2, u_submarine;

type

TCloud = class(TSprite)
  constructor Create(aX, aY: single);
  procedure Update(const aElapsedTime: single); override;
end;

TPontoon = class(TSprite)
  constructor Create(aX, aY: single; aLayerIndex: integer);
end;

{ TSeagull }

TSeagull = class(TSeagullFlyInRectangle)
  function ComputeHSpeed: single; override;
  function ComputeVSpeed: single; override;
  procedure ComputeTimeToChangeY; override;
  procedure ComputeLeftThresholdX; override;
  procedure ComputeRightThresholdX; override;
  procedure ComputeUpThresholdY; override;
  procedure ComputeDownThresholdY; override;
end;

var
  texTunnel, texPontoon, texPontoonPillar, texWave1: PTexture;
  FAtlas: TAtlas;
  FFontText: TTexturedFont;
  FSubmarine: TSubmarine;
  FLR: TLR4Direction;

function TSeagull.ComputeHSpeed: single;
begin
  Result := FScene.Width*0.05+Random*FScene.Width*0.01;
end;

function TSeagull.ComputeVSpeed: single;
begin
  Result := 0; //Random * PPIScale(30) - PPIScale(15);
end;

procedure TSeagull.ComputeTimeToChangeY;
begin
  FTimeAccu := 3 + Random*3;
end;

procedure TSeagull.ComputeLeftThresholdX;
begin
  FThresholdX := -FScene.Width*0.1;
end;

procedure TSeagull.ComputeRightThresholdX;
begin
  FThresholdX := FScene.Width*1.1;
end;

procedure TSeagull.ComputeUpThresholdY;
begin
  FThresholdY := FScene.Height*0.1;
end;

procedure TSeagull.ComputeDownThresholdY;
begin
  FThresholdY := FScene.Height*0.65;
end;

{ TPontoon }

constructor TPontoon.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(texPontoon, False);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);

  with CreateSpriteChild(texPontoon, False, 0) do
    SetCoordinate(ScaleW(150), ScaleH(0));
  with CreateSpriteChild(texPontoon, False, 0) do
    SetCoordinate(ScaleW(298), ScaleH(0));
  with CreateSpriteChild(texPontoon, False, 0) do
    SetCoordinate(ScaleW(447), ScaleH(0));

  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(126), ScaleH(71));
  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(159), ScaleH(16));
  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(407), ScaleH(71));
  with CreateSpriteChild(texPontoonPillar, False, -1) do
    SetCoordinate(ScaleW(441), ScaleH(16));
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

  if RightX <= 0 then X.Value := FScene.Width;
end;

{ TScreenSnakeFissureIntro }

procedure TScreenSnakeFissureIntro.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;
end;

procedure TScreenSnakeFissureIntro.ResetVariables;
begin

end;

procedure TScreenSnakeFissureIntro.CreateLevel;
var grad: TGradientRectangle;
  o: TSprite;
  xx, yy, deltay: single;
  wave: TWave1;
  i: integer;
begin
  // sky
  grad := TGradientRectangle.Create(FScene);
  FScene.Add(grad, LAYER_BG3);
  grad.Gradient.CreateVertical([BGRA(157,226,252), BGRA(64,121,212)], [0.0, 1.0]);
  grad.SetSize(FScene.Width, ScaleH(472));
  // water
  grad := TGradientRectangle.Create(FScene);
  FScene.Add(grad, LAYER_BG3);
  grad.Gradient.CreateVertical([BGRA(25,83,169), BGRA(37,154,233)], [0.0, 1.0]);
  grad.SetSize(FScene.Width, FScene.Height - ScaleH(472));
  grad.Y.Value := ScaleH(472);
  // waves
  yy := ScaleH(474);
  deltay := ScaleH(5);
  repeat
    xx := Random*FScene.Width*0.1;
    repeat
      wave := TWave1.Create(texWave1, xx, yy, LAYER_BG3);
      xx := xx + ScaleW(80)+Random*wave.ScaledWidth;
    until xx > FScene.Width;
    yy := yy + deltay;
    deltay := deltay*1.1;
  until yy > FScene.Height;
  // clouds
  TCloud.Create(ScaleW(14), ScaleH(52));
  TCloud.Create(ScaleW(246), ScaleH(1));
  TCloud.Create(ScaleW(413), ScaleH(83));
  TCloud.Create(ScaleW(498), ScaleH(1));
  TCloud.Create(ScaleW(750), ScaleH(56));
  TCloud.Create(ScaleW(1042), ScaleH(52));
  TCloud.Create(ScaleW(1274), ScaleH(2));
  // pontoon
  TPontoon.Create(ScaleW(0), ScaleH(661), LAYER_WOLF);
  // tunnel
  o := TSprite.Create(texTunnel, False);
  FScene.Add(o, LAYER_WOLF);
  o.SetCoordinate(ScaleW(-64), ScaleH(537));
  // seagulls
  for i:=0 to 15 do
    TSeagull.Create(LAYER_BG1);
end;

procedure TScreenSnakeFissureIntro.CreateBubbleEffect;
var y: single;
begin
  FBubbles := TParticleEmitter.Create(FScene);
  FBubbles.LoadFromFile(ParticleFolder+'SubmarineDive.par', FAtlas);
  FScene.Add(FBubbles, LAYER_GROUND);
  y := FSubMarine.BottomY-ScaleH(50);
  FBubbles.SetCoordinate(FSubMarine.X.Value, y);
  //FBubbles.SetEmitterTypeLine(PointF(FSubMarine.RightX, y));
  FBubbles.SetEmitterTypeRectangle(FSubMarine.Width, ScaleH(30));
end;

procedure TScreenSnakeFissureIntro.DefineSubTextures(aAtlas: TAtlas);
var path: string;
begin
  AdditionnalScale := 0.8;
  LoadLR4DirTextures(aAtlas, False);
  AdditionnalScale := 1.9;
  TSubmarine.LoadTexture(aAtlas, AdditionnalScale);
  AdditionnalScale := 0.3;
  TSeagull.LoadTexture(aAtlas);
  AdditionnalScale := 1.0;

  path := FolderSpriteGameMermaidsPort;
  texTunnel := aAtlas.AddFromSVG(path+'Tunnel.svg', ScaleW(165), -1);
  texPontoon := aAtlas.AddFromSVG(path+'WoodenPontoon.svg', ScaleW(200), -1);
  texPontoonPillar := aAtlas.AddFromSVG(path+'WoodenPillar.svg', ScaleW(46), -1);
  texWave1 := aAtlas.AddFromSVG(path+'SeaWave1.svg', ScaleW(81), -1);

  AddCloud128x128ParticleToAtlas(aAtlas);
  AddBubbleParticleToAtlas(aAtlas);

  // ui
  CreateGameFontNumber(aAtlas); // < must be first !
  // font for button in pause panel
  FFontText := CreateGameFontText(aAtlas);
  LoadGameDialogTextures(aAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(aAtlas);
  LoadMousePointerTexture(aAtlas);
end;

procedure TScreenSnakeFissureIntro.CreateObjects;
var h: integer;
begin
  FGameState := gsUndefined;
  ResetVariables;
  Audio.PauseMusicTitleMap(3.0);

  FsndSeaWave := Audio.AddSound('sea-and-seagull.ogg');
  FsndSeaWave.Loop := True;
  FsndSeaWave.FadeIn(0.8, 3.0);

  CheckAtlas(FAtlas, 'snakefissureintro.atlas');

  CreateLevel;

  //submarine
  FSubmarine := TSubmarine.Create(LAYER_GROUND);
  FSubmarine.SetCoordinate(ScaleW(254), ScaleH(496));
  FSubmarine.Posture_Idle(0);
  FSubmarine.StartFloating;

  // blue quad to hide the submarine when it dives
  FBlueBG := TGradientRectangle.Create(FScene);
  FScene.Add(FBlueBG, LAYER_FXANIM);
  FBlueBG.Gradient.CreateSingleColor(BGRA(37,154,233));
  h := Round(FScene.Height-(FSubmarine.BottomY-ScaleH(20)));
  FBlueBG.SetSize(FSubmarine.Width, h);
  FBlueBG.SetCoordinate(FSubmarine.X.Value, FScene.Height - h);

  FLR := TLR4Direction.Create;
  FLR.X.Value := ScaleW(98);
  FLR.BodyBottomY := ScaleH(715);
  FLR.IdleRight;

  // pause panel
  FPausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  CustomizeMousePointer;
  PostMessage(50);
end;

procedure TScreenSnakeFissureIntro.FreeObjects;
begin
  if FsndSeaWave <> NIL then FsndSeaWave.FadeOutThenKill(1.0);
  FsndSeaWave := NIL;
  if FsndEngine <> NIL then FsndEngine.FadeOutThenKill(1.0);
  FsndEngine := NIL;
  if FsndBubble <> NIL then FsndBubble.FadeOutThenKill(1.0);
  FsndBubble := NIL;
  if FScene.RequestedScreen = ScreenMap then
    Audio.ResumeMusicTitleMap;

  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
  ChallengeMode := False;
end;

procedure TScreenSnakeFissureIntro.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // Dialogs
    50: begin
      FLR.ShowExclamationMark;
      PostMessage(55, 2.5);
    end;
    55: begin
      FLR.HideMark;
      FLR.WalkHorizontallyTo(ScaleW(220), Self, 60);
    end;
    60: begin
      FLR.IdleRight;
      FLR.ShowDialog(sASubmarineIWasnt, FFontText, Self, 65);
    end;
    65: begin  // open door
      Audio.PlayThenKillSound('spaceship-compartment-doorOPEN.ogg', 0.6);
      FSubMarine.Posture_OpenDoor(1.0);
      PostMessage(70, 1.5);
    end;
    70: FLR.ShowDialog(sOkLetsGo, FFontText, Self, 75);
    75: FLR.WalkHorizontallyTo(FSubMarine.CenterX, Self, 80);
    80: begin
      FLR.IdleUp;
      PostMessage(85, 0.5);
    end;
    85: begin
      FLR.WalkVerticallyTo(ScaleH(629), Self, 87);
      FLR.Scale.ChangeTo(PointF(0.9, 0.9), 2.0);
    end;
    87: begin    // LR enter into the cockpit
      FLR.IdleRight;
      FLR.SetChildOf(FSubMarine, -1);
      FLR.WalkHorizontallyTo(FLR.X.Value + ScaleW(105), Self, 90);
    end;
    90: begin  // close the door
      FLR.IdleRight;
      Audio.PlayThenKillSound('spaceship-compartment-doorCLOSE.ogg', 0.6);
      FSubMarine.Posture_Idle(1.0);
      PostMessage(92, 2.0);
    end;
    92: FLR.ShowDialog(sHereTheresANoteOnThe, FFontText, Self, 95);
    95: FLR.ShowDialog(sWellHowToStartIt, FFontText, Self, 100, 1.0);
    100: FLR.ShowDialog(sHereThereIsAButton, FFontText, Self, 105, 1.0);
    105: begin
      FsndEngine := Audio.AddSound('synth-robot-sound.ogg', 0.4, True);
      FsndEngine.Pitch.Value := 1.0 - 1/12*4;
      FsndEngine.Play(True);
      FsndEngine.Pitch.ChangeTo(1.0, 4.0);
      PostMessage(110, 4.0);
    end;
    110: FLR.ShowDialog(sCool, FFontText, Self, 115);
    115: FLR.ShowDialog(sLetsTryDivingNow, FFontText, Self, 117);
    117: begin
      Audio.PlayThenKillSound('elevator-button-beep.ogg', 1.0);
      PostMessage(120, 0.2);
    end;
    120: begin
      FSubmarine.Posture_ArmDeployed(0.5);
      PostMessage(125, 1.0);
    end;
    125: FLR.ShowDialog(sOups, FFontText, Self, 127);
    127: begin
      Audio.PlayThenKillSound('elevator-button-beep.ogg', 1.0);
      PostMessage(130, 0.2);
    end;
    130: begin
      FSubmarine.Posture_OpenDoor(0.5);
      PostMessage(135, 1.0);
    end;
    135: FLR.ShowDialog(sNoTreePoint, FFontText, Self, 137);
    137: begin
      Audio.PlayThenKillSound('elevator-button-beep.ogg', 1.0);
      PostMessage(140, 0.2);
    end;
    140: begin
      FSubmarine.Posture_ArmAboveTank(0.5);
      FSubmarine.OpenTrapDoor(0.5);
      PostMessage(145, 0.5);
    end;
    145: begin
      Audio.PlayThenKillSound('elevator-button-beep.ogg', 1.0);
      FSubmarine.Posture_Idle(0.5);
      FSubmarine.CloseTrapDoor(0.5);
      PostMessage(150, 0.5);
    end;
    150: begin
      Audio.PlayThenKillSound('elevator-button-beep.ogg', 1.0);
      PostMessage(155, 0.5);
    end;
    155: begin  // bubbles
      FsndBubble := Audio.AddSound('heavy-bubbles-35889.ogg', 1.0, True);
      FsndBubble.FadeIn(1.0, 1.0);
      PostMessage(160, 1.0);
    end;
    160: begin
      FSubMarine.StopFloating;
      CreateBubbleEffect;
      PostMessage(165, 2.0);
    end;
    165: begin // the submarine dives
      FSubMarine.Y.ChangeTo(FBlueBG.Y.Value+TSubMarine.texLeftTrapdoor^.FrameHeight,  4.0, idcDrop);
      PostMessage(170, 3.0);
    end;
    170: begin
      FBubbles.ParticlesToEmit.ChangeTo(0, 1.5);
      FsndEngine.FadeOut(2.0);
      FsndBubble.FadeOut(2.0);
      PostMessage(175, 3.0);
    end;
    175: begin
      PlayerInfo.SnakeFissure.IncCurrentStep;
      FSaveGame.Save;
      FScene.RunScreen(ScreenMap);
    end;

  end;
end;

procedure TScreenSnakeFissureIntro.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  // check if player pause the game
  if Input.PausePressed then
    FPausePanel.ShowModal;
end;

end.

