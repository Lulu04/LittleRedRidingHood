unit u_screen_gamemermaidboss;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon;

type

{ TScreenMermaidsBoss }

  TScreenMermaidsBoss = class(TGameScreenTemplate)
private type TGameState=(gsUndefined, gsRunning,
                         gsLRWin, gsLRLose);
var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FRain: TParticleEmitter;
  FsndRain, FsndHelico: TALSSound;
  FPausePanel: TInGamePausePanel;
  procedure ResetVariables;
  procedure StartRain(aDuration: single);
  procedure CreateClouds; // LAYER_BG3
  procedure CreateGround; // LAYER_BG2
  procedure CreateFactory3(aFromX: single); // LAYER_BG2
  procedure CreateFactory2(aFromX: single); // LAYER_BG1
  procedure CreateFactory1(aX: single; aCount: integer); // LAYER_GROUND
  procedure CreateBGFence(aXBegin, aXEnd: single);
  procedure CreateLevel;
  procedure CreateProgressBar;
public
  procedure DefineSubTextures(aAtlas: TAtlas); override;
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenMermaidsBoss: TScreenMermaidsBoss;

implementation

uses Forms, u_screen_map, u_app, u_utils, Math, u_sprite_lr4dir, u_sprite_wolf,
  u_gamebackground, u_mousepointer, u_resourcestring, u_sprite_def,
  u_sprite_def2, Graphics;

const FACTORY1_SCALE = 2.0;
      FACTORY2_SCALE = 1.5;
      FACTORY3_SCALE = 2.0;
      DEFENSE_TIME_WHEN_DETECT_BULLET = 0.5;  // for Marcus

var FWorldArea,  // the size of the word
    FViewArea: TRectF; // the constrained size for the camera

function GetYGround: single;
begin
  Result := ScaleH(680);
end;

type

TSky = class(TGradientRectangle) // LAYER_BG3
private
  FStormIndex: integer;
public
  constructor Create;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

TSewerPlate = class(TSprite)  // LAYER_GROUND
  constructor Create(aX: single);
end;

TBarrel = class(TSprite)  // LAYER_GROUND
  constructor Create(aX, aY: single; aLayerIndex: integer);
end;

TGroundStain = class(TSprite) // LAYER_GROUND
  constructor Create(aX, aY: single);
end;

TBGFence = class(TSprite) // LAYER_GROUND
  constructor Create(var aX: single; aUseHorizontalBar: boolean);
end;

TPanelExit = class(TSprite)
  constructor Create(aX, aBottomY: single);
end;

TFactory1 = class(TTiledSprite) // LAYER_GROUND
  constructor Create(aX: single);
end;

TFactory2 = class(TTiledSprite) // LAYER_BG1
  constructor Create(aX: single);
end;

TFactory3 = class(TTiledSprite) // LAYER_BG2
  constructor Create(aX: single);
end;

TCustomLR4Direction = class(TLR4Direction);

TControlPanel = class(TSprite)
  constructor Create(aX, aBottomY: single);
  procedure HitByBullet;
end;

{ TContainer }

TContainer = class(TSprite)  // LAYER_ARROW  (LAYER_FXANIM)
private type TMode = (contmGoToTheRight, contmFalling,
                      contmHitMarcus, contmHitLR);
private
  FMode: TMode;
  FCraneHitCount: integer;
public
  FCraneHook: TSprite;
  constructor Create;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Fall;
  procedure HitCraneHook;
  property Mode: TMode read FMode;
end;

TEggShoot = class(TSprite)
  OwnerIsLR, FInBounceMode: boolean;
  constructor Create(aTex: PTexture);
  procedure Update(const aElapsedTime: single); override;
end;

TEggState = (eggsUndefined, eggsIdleFly, eggsExecuteBossSequence,
             eggsFreezed, eggsStunned, eggsBroken);

{ TCommonEggs }

TCommonEggs = class(TSprite)   // LAYER_ARROW
  class var texEggRed, texBGRed, texEggBlack, texBGBlack, texRedShoot, texBlackShoot: PTexture;
private
  FBG, FImpact1, FImpact2, FImpact3: TSprite;
  FState: TEggState;
  FOwnerIsLR, FShootSide, FApplyBounds: boolean;
  FTimeBeforeNextShoot: single;
  FAcceleration, FFriction: single;
  FBounds: TRect;
  FDriver: TCharacterWithDialogPanel;
  FElectricalBeam: TOGLCElectricalBeam;
  procedure SetState(AValue: TEggState);
  procedure DoShoot(aTex: PTexture);
  procedure CreateBrokenState;
  procedure RemoveBrokenState;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  class procedure LoadTexture(aAtlas: TAtlas);
  constructor Create(aTexEgg, aTexBG: Ptexture);
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
public
  FsndRedEgg: TALSSound;
  procedure PlaySoundWhenArrive;
  procedure PrepareSoundToFight;
  procedure PlaySoundWhenLeave;
  procedure PitchSoundForMove;
public
  procedure SetDriverAsChild(aCharacter: TCharacterWithDialogPanel);
  procedure RemoveDriver(aLayerIndex: integer);
  procedure ComputeMoveBounds;
  procedure Defend(AValue: boolean);
  procedure MoveRight;
  procedure MoveLeft;
  procedure MoveUp;
  procedure MoveDown;

  property State: TEggState read FState write SetState;
  property ApplyBounds: boolean read FApplyBounds write FApplyBounds;
end;

TRedEgg = class(TCommonEggs)
public
  constructor Create;
  procedure Shoot;
end;

TBlackEgg = class(TCommonEggs)
private
  FFlagContinueShoot: boolean;
  FTimeToStayInDefensiveMode: single;
  function GetBossYSpeed: single; // less life, more speed
  function ComputeMovingTime(aNewYCoor: single): single;
public
  DetectBulletArea: TOGLCBodyItem;
  constructor Create;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Shoot;
  procedure SetDefendMode(aDuration: single);
  procedure StartBossSequence;
  procedure ResumeBossSequence;
end;


var
  FAtlas: TAtlas;
  FFontText: TTexturedFont;
  texCraneHook, texCraneHookBG, texContainer, texPanelExit,
  texSewerPlate, texBarrel, texGroundStain, texControlPanel,
  texBGFenceVertical, texBGFenceHorizontal,
  texFactory1, texFactory2, texFactory3,
  texTunnel: PTexture;
  FLR: TCustomLR4Direction;
  FMarcus: TWolfMarcus;
  FCamera, FCameraFactory2, FCameraFactory3: TOGLCCamera;
  FControlPanel: TControlPanel;
  FRedEgg: TRedEgg;
  FBlackEgg: TBlackEgg;
  FLRLifeProgressBar, FMarcusProgressBar: TUIProgressBar;
  FWorkingContainer: TContainer;
  FHelico: TMarcusHelicopter;
  FCameraViewRect: TRectF;


{ TBlackEgg }

function TBlackEgg.ComputeMovingTime(aNewYCoor: single): single;
begin
  Result := Abs(Y.Value - aNewYCoor) / GetBossYSpeed;
end;

function TBlackEgg.GetBossYSpeed: single;
var deltaSpeed: single;
begin
  deltaSpeed := FScene.Height*2 - FScene.Height*0.3;
  Result := FScene.Height*0.3 + deltaSpeed*(1.0-FMarcusProgressBar.Percent);
end;

constructor TBlackEgg.Create;
begin
  inherited Create(texEggBlack, texBGBlack);

  // the rectangle to detect LR bullet
  DetectBulletArea := Default(TOGLCBodyItem);
  DetectBulletArea.BodyType := _btRect;
  DetectBulletArea.rect := RectF(ScaleW(-153), ScaleH(-60), ScaleW(-8), ScaleH(198));
end;

procedure TBlackEgg.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if ScreenMermaidsBoss.GameState <> gsRunning then exit;

  // defensive mode
  if State in [eggsFreezed, eggsStunned] then FlipH := True
  else begin
    if FTimeToStayInDefensiveMode > 0 then begin
      FTimeToStayInDefensiveMode := FTimeToStayInDefensiveMode - aElapsedTime;
      FlipH := not (FTimeToStayInDefensiveMode > 0);
    end else FlipH := True;
  end;
end;

procedure TBlackEgg.ProcessMessage(UserValue: TUserMessageValue);
var newY, d: single;
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // BOSS SEQUENCE
    100: begin  // go down then shoot
      if State <> eggsExecuteBossSequence then exit;
      PitchSoundForMove;
      newY := ScaleH(550);
      d := ComputeMovingTime(newY);
      MoveTo(FBounds.Left+FBounds.Width*Random, newY, d, idcSinusoid);
      PostMessage(105, d);
      FFlagContinueShoot := True;
      PostMessage(110, d+ 0.5);  // shooting time = 0.5
    end;
    105: begin // shoot continuously until FFlagContinueShoot is False
      if State <> eggsExecuteBossSequence then exit;
      Shoot;
      if FFlagContinueShoot then PostMessage(105);
    end;
    110: begin // stop shooting
      FFlagContinueShoot := False;
      if State <> eggsExecuteBossSequence then exit;
      PostMessage(115);
    end;
    115: begin  // go up then shoot
      if State <> eggsExecuteBossSequence then exit;
      PitchSoundForMove;
      newY := ScaleH(50);
      d := ComputeMovingTime(newY);
      MoveTo(FBounds.Left+FBounds.Width*Random, newY, d, idcSinusoid);
      PostMessage(105, d);
      FFlagContinueShoot := True;
      PostMessage(120, d+ 0.5);  // shooting time = 0.5
    end;
    120: begin // stop shooting
      FFlagContinueShoot := False;
      if State <> eggsExecuteBossSequence then exit;
      PostMessage(125);
    end;
    125: begin // go middle then shoot
      if State <> eggsExecuteBossSequence then exit;
      PitchSoundForMove;
      newY := ScaleH(322);
      d := ComputeMovingTime(newY);
      MoveTo(FBounds.Left+FBounds.Width*Random, newY, d, idcSinusoid);
      PostMessage(105, d);
      FFlagContinueShoot := True;
      PostMessage(130, d+ 0.5);   // shooting time = 0.5
    end;
    130: begin // stop shooting
      FFlagContinueShoot := False;
      if State <> eggsExecuteBossSequence then exit;
      PostMessage(135);
    end;
    135: begin
      PostMessage(100);
    end;

  end;
end;

procedure TBlackEgg.Shoot;
begin
  DoShoot(texBlackShoot);
end;

procedure TBlackEgg.SetDefendMode(aDuration: single);
begin
  FlipH := False;
  FTimeToStayInDefensiveMode := FTimeToStayInDefensiveMode + aDuration;
  if FTimeToStayInDefensiveMode > DEFENSE_TIME_WHEN_DETECT_BULLET then
    FTimeToStayInDefensiveMode := DEFENSE_TIME_WHEN_DETECT_BULLET;
end;

procedure TBlackEgg.StartBossSequence;
begin
  FFlagContinueShoot := False;
  State := eggsExecuteBossSequence;
end;

procedure TBlackEgg.ResumeBossSequence;
begin
  StartBossSequence;
end;

{ TRedEgg }

constructor TRedEgg.Create;
begin
  inherited Create(texEggRed, texBGRed);
end;

procedure TRedEgg.Shoot;
begin
  DoShoot(texRedShoot);
end;

{ TCommonEggs }

procedure TCommonEggs.SetState(AValue: TEggState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  FElectricalBeam.Visible := False;
  FElectricalBeam.Freeze := True;
  case AValue of
    eggsIdleFly: begin
      Angle.ChangeTo(0, 0.5, idcSinusoid);
      PostMessage(0);
    end;
    eggsFreezed: begin
      Angle.Value := 0;
      Speed.Value := PointF(0, 0);
    end;
    eggsStunned: begin
      PostMessage(50);
      PostMessage(60);
      if (FOwnerIsLR and (FLRLifeProgressBar.Percent > 0.1)) or
         (not FOwnerIsLR and (FMarcusProgressBar.Percent > 0.1)) then
        PostMessage(70);
      FElectricalBeam.Visible := True;
      FElectricalBeam.Freeze := False;
    end;
    eggsBroken: CreateBrokenState;
    eggsExecuteBossSequence: begin
      PostMessage(100);
      Angle.ChangeTo(0, 0.5, idcSinusoid);
    end;
  end;
end;

procedure TCommonEggs.DoShoot(aTex: PTexture);
var o: TEggShoot;
  panValue: single;
begin
  if State = eggsFreezed then exit;
  if FTimeBeforeNextShoot > 0 then exit;
  FTimeBeforeNextShoot := 1/8;

  o := TEggShoot.Create(aTex);
  FScene.Add(o, LAYER_ARROW);

  o.OwnerIsLR := FOwnerIsLR;
  if FOwnerIsLR then begin
    panValue := -0.5;
    o.OwnerIsLR := True;
  end else begin
    panValue := 0.5;
    o.OwnerIsLR := False;
  end;
  Audio.PlayThenKillSound('shotgun-shoot-only.ogg', 0.8, panValue);

  FShootSide := not FShootSide;
  o.Speed.x.Value := FScene.Width*2;
  if not FlipH then begin
    if not FShootSide then o.X.Value := X.Value + ScaleW(133)
      else o.X.Value := X.Value + ScaleW(67);
  end else begin
    if not FShootSide then o.X.Value := X.Value - ScaleW(10)
      else o.X.Value := X.Value + ScaleW(56);
    o.Speed.x.Value := -o.Speed.x.Value;
  end;
  o.Y.Value := Y.Value + ScaleH(80);
end;

procedure TCommonEggs.CreateBrokenState;
begin
  FImpact1 := TImpact1.Create(ScaleW(6), ScaleH(78), -1);
  AddChild(FImpact1, 1);
  FImpact2 := TImpact1.Create(ScaleW(65), ScaleH(112), -1);
  AddChild(FImpact2, 1);
  FImpact3 := TImpact1.Create(ScaleW(99), ScaleH(35), -1);
  AddChild(FImpact3, 1);
end;

procedure TCommonEggs.RemoveBrokenState;
begin
  FImpact1.Kill;
  FImpact2.Kill;
  FImpact3.Kill;
end;

procedure TCommonEggs.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FBG.FlipH := AValue;
  if FDriver <> NIL then
    if FOwnerIsLR then FDriver.FlipH := AValue
      else FDriver.FlipH := not AValue;
end;

procedure TCommonEggs.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FBG.FlipV := AValue;
  if FDriver <> NIL then FDriver.FlipV := AValue;
end;

class procedure TCommonEggs.LoadTexture(aAtlas: TAtlas);
var path: string;
begin
  path := FolderSpriteGameMermaidsPort;
  texEggRed := aAtlas.AddFromSVG(path+'EggRed.svg', ScaleW(151), -1);
  texBGRed := aAtlas.AddFromSVG(path+'EggRedBG.svg', ScaleW(47), -1);
  texEggBlack := aAtlas.AddFromSVG(path+'EggBlack.svg', ScaleW(151), -1);
  texBGBlack := aAtlas.AddFromSVG(path+'EggBlackBG.svg', ScaleW(47), -1);
  texRedShoot := aAtlas.AddFromSVG(path+'EggRedShoot.svg', ScaleW(28), -1);
  texBlackShoot := aAtlas.AddFromSVG(path+'EggBlackShoot.svg', ScaleW(28), -1);
end;

constructor TCommonEggs.Create(aTexEgg, aTexBG: Ptexture);
begin
  inherited Create(aTexEgg, False);
  FScene.Add(Self, LAYER_ARROW);

  FOwnerIsLR := aTexEgg = texEggRed;

  FBG := CreateSpriteChild(aTexBG, False, -2);
  FBG.ApplySymmetryWhenFlip := True;
  FBG.SetCoordinate(ScaleW(68), ScaleH(17));

  FElectricalBeam := TOGLCElectricalBeam.Create(FScene);
  FScene.Add(FElectricalBeam, LAYER_ARROW);
  with FElectricalBeam do begin
    Freeze := True;
    Visible := False;
    BeamColor.Value := BGRA(255,50,0);
    BeamWidth := PPIScale(2);
    HaloColor.Value := BGRA(200,10,255);
    HaloWidth := 0; //PPIScale(20);
    Aperture := PPIScale(45);
    BlendMode := FX_BLEND_ADD;
  end;

  FAcceleration := PPIScale(48*2);
  FFriction := PPIScale(48);

  // Collision body
  CollisionBody.AddPolygon([PointF(ScaleW(54), ScaleH(0)),
      PointF(ScaleW(39), ScaleH(4)), PointF(ScaleW(24), ScaleH(18)),
      PointF(ScaleW(10), ScaleH(46)), PointF(ScaleW(1), ScaleH(81)),
      PointF(ScaleW(0), ScaleH(115)), PointF(ScaleW(3), ScaleH(126)),
      PointF(ScaleW(21), ScaleH(142)), PointF(ScaleW(43), ScaleH(151)),
      PointF(ScaleW(64), ScaleH(154)), PointF(ScaleW(87), ScaleH(153)),
      PointF(ScaleW(109), ScaleH(143)), PointF(ScaleW(125), ScaleH(124)),
      PointF(ScaleW(129), ScaleH(110)), PointF(ScaleW(128), ScaleH(87)),
      PointF(ScaleW(124), ScaleH(57)), PointF(ScaleW(118), ScaleH(41)),
      PointF(ScaleW(108), ScaleH(22)), PointF(ScaleW(94), ScaleH(8)),
      PointF(ScaleW(77), ScaleH(0))]);

  FsndRedEgg := Audio.AddSound('EggSoundLoop.ogg', 1.0, True);
end;

destructor TCommonEggs.Destroy;
begin
  if FsndRedEgg <> NIL then FsndRedEgg.FadeOutThenKill(1.0);
  FsndRedEgg := NIL;
  inherited Destroy;
end;

procedure TCommonEggs.Update(const aElapsedTime: single);
var v: single;
begin
  inherited Update(aElapsedTime);

  if FTimeBeforeNextShoot > 0 then
    FTimeBeforeNextShoot := FTimeBeforeNextShoot - aElapsedTime;

  // apply friction
  v := Speed.X.Value;
  if v > 0 then v := Max(v - FFriction, 0)
    else if v < 0 then v := Min(v + FFriction, 0);
  Speed.X.Value := v;
  v := Speed.Y.Value;
  if v > 0 then v := Max(v - FFriction, 0)
    else if v < 0 then v := Min(v + FFriction, 0);
  Speed.Y.Value := v;

  // apply bounds
  if FApplyBounds then begin
    if X.Value < FBounds.Left then X.Value := FBounds.Left
      else if X.Value > FBounds.Right then X.Value := FBounds.Right;
    if Y.Value < FBounds.Top then Y.Value := FBounds.Top
      else if Y.Value > FBounds.Bottom then Y.Value := FBounds.Bottom;
  end;
end;

procedure TCommonEggs.ProcessMessage(UserValue: TUserMessageValue);
var p: TPointF;
begin
  case UserValue of
    // FLY IDLE
    0: begin
      if State <> eggsIdleFly then exit;
      if Speed.Y.Value = 0 then
        Y.ChangeTo(Y.Value+ScaleH(10), 1.0, idcSinusoid);
      PostMessage(5, 1.0);
    end;
    5: begin
      if State <> eggsIdleFly then exit;
      if Speed.Y.Value = 0 then
        Y.ChangeTo(Y.Value-ScaleH(10), 1.0, idcSinusoid);
      PostMessage(0, 1.0);
    end;

    // ANIM STUNNED
    50: begin
      if State <> eggsStunned then exit;
      Angle.ChangeTo(-5, 0.04, idcSinusoid);
      PostMessage(55, 0.04);
    end;
    55: begin
      if State <> eggsStunned then exit;
      Angle.ChangeTo(5, 0.04, idcSinusoid);
      PostMessage(50, 0.04);
    end;
    60: begin
      if State <> eggsStunned then begin
        FElectricalBeam.Freeze := True;
        FElectricalBeam.Visible := False;
        exit;
      end;
      p := PointF(Random*Width, Random*Height*0.25);
      p := SurfaceToWorld(p);
      FElectricalBeam.SetCoordinate(p);
      p := PointF(Random*Width, Height*0.75+Random*Height*0.25);
      p := SurfaceToScene(p);
      FElectricalBeam.SetTargetPoint(p);
      FElectricalBeam.ComputeBeam;
      PostMessage(60, 0.05);
    end;
    70: begin
      PostMessage(72, 0.5);
      PostMessage(72, 1.0);
      PostMessage(72, 1.35);
      PostMessage(72, 1.8);
      PostMessage(72, 2.3);
      PostMessage(72, 2.5);
      PostMessage(72, 3.0);
    end;
    72: begin
      Audio.PlayThenKillSound('electric-zap.ogg', 1.0, 0.5);
    end;
  end;
end;

procedure TCommonEggs.PlaySoundWhenArrive;
begin
  FsndRedEgg.Pan.Value := 1.0;
  if FOwnerIsLR then FsndRedEgg.Pan.ChangeTo(-0.5, 3.5)
    else FsndRedEgg.Pan.ChangeTo(0.5, 3.5);
  FsndRedEgg.FadeIn(1.0, 1.0);
end;

procedure TCommonEggs.PrepareSoundToFight;
begin
  if FOwnerIsLR then FsndRedEgg.Pan.Value := -0.5
    else FsndRedEgg.Pan.Value := 0.5;
  FsndRedEgg.FadeIn(0.8);
end;

procedure TCommonEggs.PlaySoundWhenLeave;
begin
  FsndRedEgg.Pan.ChangeTo(1.0, 3.0);
  FsndRedEgg.FadeOutThenKill(3.0);
  FsndRedEgg := NIL;
end;

procedure TCommonEggs.PitchSoundForMove;
begin
  if FOwnerIsLR then FsndRedEgg.Pitch.Value := 1.2
    else FsndRedEgg.Pitch.Value := 1.4;
  FsndRedEgg.Pitch.ChangeTo(1.0, 1.0);
end;

procedure TCommonEggs.SetDriverAsChild(aCharacter: TCharacterWithDialogPanel);
begin
  if FDriver = aCharacter then exit;
  FDriver := aCharacter;
  FDriver.SetChildOf(Self, -1);
  FDriver.ApplySymmetryWhenFlip := True;
end;

procedure TCommonEggs.RemoveDriver(aLayerIndex: integer);
begin
  if FDriver <> NIL then FDriver.MoveToLayer(aLayerIndex);
  FDriver := NIL;
end;

procedure TCommonEggs.ComputeMoveBounds;
var r: TRectF;
begin
  r := FCamera.GetViewRect;
  if FOwnerIsLR then
    FBounds := Rect(Round(r.Left), 0, Round(r.Left+r.Width*0.4), FScene.Height-Height)
    //FBounds := Rect(Round(r.Left), 0, Round(r.Left+r.Width*0.4), Round(r.Bottom)-Height)
  else
    FBounds := Rect(Round(r.Left+r.Width*0.6), 0, Round(r.Right)-Width, FScene.Height-Height);
    //FBounds := Rect(Round(r.Left+r.Width*0.6), 0, Round(r.Right)-Width, Round(r.Bottom)-Height);
end;

procedure TCommonEggs.Defend(AValue: boolean);
begin
  if FOwnerIsLR then FlipH := AValue
    else FlipH := not AValue;
end;

procedure TCommonEggs.MoveRight;
begin
  if (State <> eggsFreezed) and
     (X.Value < FBounds.Right) then begin
    Speed.X.Value := Speed.X.Value + FAcceleration;
    PitchSoundForMove;
  end;
end;

procedure TCommonEggs.MoveLeft;
begin
  if (State <> eggsFreezed) and
    (X.Value > FBounds.Left) then begin
    Speed.X.Value := Speed.X.Value - FAcceleration;
    PitchSoundForMove;
  end;
end;

procedure TCommonEggs.MoveUp;
begin
  if (State <> eggsFreezed) and
    (Y.Value > FBounds.Top) then begin
    Y.Value := Y.Value;
    Speed.Y.Value := Speed.Y.Value - FAcceleration;
    PitchSoundForMove;
  end;
end;

procedure TCommonEggs.MoveDown;
begin
  if (State <> eggsFreezed) and
    (Y.Value < FBounds.Bottom) then begin
    Y.Value := Y.Value;
    Speed.Y.Value := Speed.Y.Value + FAcceleration;
    PitchSoundForMove;
  end;
end;

{ TEggShoot }

constructor TEggShoot.Create(aTex: PTexture);
begin
  inherited Create(aTex, False);
  if not FlipH then Angle.AddConstant(360*2)
    else Angle.AddConstant(-360*2);
  CollisionBody.AddCircle(PointF(Width*0.5, Height*0.5), Width*0.5);
  FInBounceMode := False;
end;

procedure TEggShoot.Update(const aElapsedTime: single);
var r: TRectF;
  m: TOGLCMatrix;
begin
  inherited Update(aElapsedTime);

  // kill the bullet if LR win or lose
  if ScreenMermaidsBoss.GameState <> gsRunning then begin
    Kill;
    exit;
  end;

  CollisionBody.SetTransformMatrix(GetMatrixSurfaceToScene);
  if FInBounceMode then begin
    // when the bullet bounce, we check the collision with the crane hook
    if (FWorkingContainer <> NIL) and (FWorkingContainer.Mode = contmGoToTheRight) then begin
      FWorkingContainer.FCraneHook.CollisionBody.SetTransformMatrix(FWorkingContainer.FCraneHook.GetMatrixSurfaceToScene);
      if CollisionBody.CheckCollisionWith(FWorkingContainer.FCraneHook) then begin
        Audio.PlayThenKillSound('metal-hit.ogg', 0.6, 0.0, 0.8);
        FWorkingContainer.HitCraneHook;
        Kill;
        exit;
      end;
    end;
    // check if bullet is out of view
    //if not FCameraViewRect.Contains(Center) then
    if (Y.Value < -FScene.Height) or (Y.Value > FScene.Height*2) then
      Kill;
    exit;
  end;

  if OwnerIsLR then begin
    m := FBlackEgg.GetMatrixSurfaceToScene;

    // check collision with Marcus detection area
    if FBlackEgg.State <> eggsFreezed then begin
      r := FBlackEgg.DetectBulletArea.rect;
      r.Left := r.Left + FBlackEgg.X.Value;
      r.Top := r.Top + FBlackEgg.Y.Value;
      r.Right := r.Right + FBlackEgg.X.Value;
      r.Bottom := r.Bottom + FBlackEgg.Y.Value;
      if Collision.CircleRectF(Center, Width*0.5, r) then
        FBlackEgg.SetDefendMode(DEFENSE_TIME_WHEN_DETECT_BULLET);
    end;

    // check collision with Marcus egg
    FBlackEgg.CollisionBody.SetTransformMatrix(m);
    if CollisionBody.CheckCollisionWith(FBlackEgg) then begin
      if not FBlackEgg.FlipH then begin
        // Marcus is in defense mode -> bullet bounce
        Audio.PlayThenKillSound('metal-hit.ogg', 0.6, 0.5, 1.0);
        Speed.X.Value := -Speed.X.Value;
        if CenterY > FBlackEgg.CenterY then Speed.Y.Value := -Speed.X.Value
          else Speed.Y.Value := Speed.X.Value;
        FInBounceMode := True;
      end else begin
        // inflicts damage to Marcus
        Audio.PlayThenKillSound('CollisionPunchShort.ogg', 0.6, 0.5);
        Kill;
        FMarcusProgressBar.Percent := FMarcusProgressBar.Percent - 0.01;
      end;
    end else begin
      // check collision with the control panel
      FControlPanel.CollisionBody.SetTransformMatrix(FControlPanel.GetMatrixSurfaceToScene);
      if CollisionBody.CheckCollisionWith(FControlPanel) then begin
        Audio.PlayThenKillSound('metal-hit.ogg', 0.6, 0.0, 1.2);
        Kill;
        FControlPanel.HitByBullet;
      end else if X.Value > FCameraViewRect.Right then Kill;
      {else begin
        // check collision with crane hook
        if (FWorkingContainer <> NIL) and (FWorkingContainer.Mode = contmGoToTheRight) and
          (BottomY < FWorkingContainer.Y.Value) and (RightX >= FWorkingContainer.Width*0.45) then begin
          Audio.PlayThenKillSound('metal-hit.ogg', 0.8, 0.0, 0.8);
          FWorkingContainer.HitCraneHook;
          Kill;
        end else if X.Value > FScene.Width then Kill;
      end; }
    end;
  end else begin
    // check collision with LR egg
    FRedEgg.CollisionBody.SetTransformMatrix(FRedEgg.GetMatrixSurfaceToScene);
    if CollisionBody.CheckCollisionWith(FRedEgg) then begin
      if FRedEgg.FlipH then begin
        // LR is in defense mode -> bullet bounce
        Audio.PlayThenKillSound('metal-hit.ogg', 0.6, -0.5, 1.0);
        Speed.X.Value := -Speed.X.Value;
        if CenterY > FRedEgg.CenterY then Speed.Y.Value := Speed.X.Value
          else Speed.Y.Value := -Speed.X.Value;
        FInBounceMode := True;
      end else begin
        // inflicts damage to LR
        Audio.PlayThenKillSound('CollisionPunchShort.ogg', 0.6, -0.5);
        Kill;
        FLRLifeProgressBar.Percent := FLRLifeProgressBar.Percent - 0.02;
      end;
    end else if X.Value < FCameraViewRect.Left then Kill;
  end;
end;

{ TContainer }

constructor TContainer.Create;
var o: TSprite;
  FCable1, FCable2: TShapeOutline;
begin
  inherited Create(texContainer, False);
  FScene.Add(Self, LAYER_ARROW);
  Pivot := PointF(0.52, -3.0);

  FCraneHook := CreateSpriteChild(texCraneHook, False, 0);
  FCraneHook.SetCoordinate(ScaleW(152), ScaleH(-106));
  FCraneHook.CollisionBody.AddPolygon([PointF(ScaleW(46), ScaleH(0)), PointF(ScaleW(0), ScaleH(43)),
                                       PointF(ScaleW(0), ScaleH(52)), PointF(ScaleW(38), ScaleH(52)),
                                       PointF(ScaleW(37), ScaleH(87)), PointF(ScaleW(45), ScaleH(91)),
                                       PointF(ScaleW(45), ScaleH(136)), PointF(ScaleW(49), ScaleH(136)),
                                       PointF(ScaleW(49), ScaleH(90)), PointF(ScaleW(58), ScaleH(87)),
                                       PointF(ScaleW(59), ScaleH(52)), PointF(ScaleW(101), ScaleH(51)),
                                       PointF(ScaleW(102), ScaleH(40)), PointF(ScaleW(58), ScaleH(-3)),
                                       PointF(ScaleW(52), ScaleH(-3))]);

  o := TSprite.Create(texCraneHookBG, False);
  FCraneHook.AddChild(o, -2);
  o.SetCoordinate(ScaleW(49), ScaleH(-3));

  FCable1 := TShapeOutline.Create(FScene);
  FCraneHook.AddChild(FCable1, -1);
  FCable1.SetParam(PPIScale(6), BGRA(39,39,39), lpMiddle, False);
  FCable1.SetShapeLine(PointF(ScaleW(45), ScaleH(9)), PointF(ScaleW(45), -FScene.Height*3));

  FCable2 := TShapeOutline.Create(FScene);
  FCraneHook.AddChild(FCable2, -1);
  FCable2.SetParam(PPIScale(6), BGRA(39,39,39), lpMiddle, False);
  FCable2.SetShapeLine(PointF(ScaleW(55), ScaleH(9)), PointF(ScaleW(55), -FScene.Height*3));

  CollisionBody.AddPolygon([PointF(ScaleW(68), ScaleH(0)), PointF(ScaleW(0), ScaleH(68)),
                                 PointF(ScaleW(0), ScaleH(225)), PointF(ScaleW(334), ScaleH(225)),
                                 PointF(ScaleW(407), ScaleH(147)), PointF(ScaleW(407), ScaleH(0))]);
  X.Value := -Width;
  Y.Value := ScaleH(-200); //0; //ScaleH(74);
  Speed.X.Value := FScene.Width*0.125;
  FMode := contmGoToTheRight;
end;

procedure TContainer.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  case FMode of
    contmGoToTheRight: begin
      // check if container is out of the scene area
      if X.Value > FCamera.GetViewRect.Right then begin // FScene.Width then begin
        Kill;
        FWorkingContainer := NIL;
        exit;
      end;
    end;
    contmFalling: begin
      // check if container collide Marcus egg
      CollisionBody.SetTransformMatrix(GetMatrixSurfaceToScene);
      FBlackEgg.CollisionBody.SetTransformMatrix(FBlackEgg.GetMatrixSurfaceToScene);
      if CollisionBody.CheckCollisionWith(FBlackEgg) then begin
        ScreenMermaidsBoss.PostMessage(300);
        FMode := contmHitMarcus;
      end else begin
        // check if the container collide LR egg
        FRedEgg.CollisionBody.SetTransformMatrix(FRedEgg.GetMatrixSurfaceToScene);
        if CollisionBody.CheckCollisionWith(FRedEgg) then begin
          ScreenMermaidsBoss.PostMessage(400);
          FMode := contmHitLR;
        end else begin
          // check if the falling container exit the view
          if Y.Value >= FCamera.GetViewRect.Bottom then begin //; FScene.Height then begin
            Kill;
            FWorkingContainer := NIL;
          end;
        end;
      end;
    end;

  end;
end;

procedure TContainer.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // ANIM container explode
    0: begin
      Audio.PlayThenKillSound('fall-5-on-floor-cushion.ogg', 1.0, 0.0);
      ExplodeTexture(FScene, LAYER_FXANIM, texContainer, 2, 3, Center,
                  0.5, PointF(1,1), -60, 60, FScene.Width*0.5, 0, 2.0); // idcLinear, True, True);
      Kill;
      FWorkingContainer := NIL;
    end;
  end;
end;

procedure TContainer.Fall;
begin
  if FMode = contmGoToTheRight then begin
    Audio.PlayThenKillSound('Falling.ogg', 0.6);
    FMode := contmFalling;
    Y.ChangeTo(FCamera.GetViewRect.Bottom-Height, 1.0, idcDrop);
    PostMessage(0, 1.0); // anim container explode
  end;
end;

procedure TContainer.HitCraneHook;
begin
  FCraneHook.Tint.Value := BGRAWhite;
  FCraneHook.Tint.Alpha.ChangeTo(0, 0.5);
  inc(FCraneHitCount);
  if FCraneHitCount = 1 then begin
    FCraneHitCount := 0;
    Fall;
  end;
end;

{ TControlPanel }

constructor TControlPanel.Create(aX, aBottomY: single);
begin
  inherited Create(texControlPanel, False);
  FScene.Add(Self, LAYER_GROUND);
  X.Value := aX;
  BottomY := aBottomY;

  CollisionBody.AddPolygon([PointF(ScaleW(22), ScaleH(0)), PointF(ScaleW(0), ScaleH(20)),
                            PointF(ScaleW(32), ScaleH(20)), PointF(ScaleW(32), ScaleH(70)),
                            PointF(ScaleW(41), ScaleH(70)), PointF(ScaleW(41), ScaleH(20)),
                            PointF(ScaleW(51), ScaleH(20)), PointF(ScaleW(73), ScaleH(0))]);
end;

procedure TControlPanel.HitByBullet;
begin
  if FWorkingContainer = NIL then
    FWorkingContainer := TContainer.Create;
end;

{ TFactory3 }

constructor TFactory3.Create(aX: single);
begin
  inherited Create(texFactory3, False);
  FScene.Add(Self, LAYER_BG2);
  Scale.Value := PointF(FACTORY3_SCALE, FACTORY3_SCALE);
  ScaledX := aX;
  ScaledBottomY := FWorldArea.Bottom-ScaleH(297);
end;

{ TFactory2 }

constructor TFactory2.Create(aX: single);
begin
  inherited Create(texFactory2, False);
  FScene.Add(Self, LAYER_BG1);
  Scale.Value := PointF(FACTORY2_SCALE, FACTORY2_SCALE);
  ScaledX := aX;
  ScaledBottomY := FWorldArea.Bottom-ScaleH(296);
end;

{ TFactory1 }

constructor TFactory1.Create(aX: single);
begin
  inherited Create(texFactory1, False);
  FScene.Add(Self, LAYER_GROUND);
  Scale.Value := PointF(FACTORY1_SCALE, FACTORY1_SCALE);
  ScaledX := aX;
  ScaledBottomY := FWorldArea.Bottom-ScaleH(180); //ScaleH(206);
end;

{ TPanelExit }

constructor TPanelExit.Create(aX, aBottomY: single);
begin
  inherited Create(texPanelExit, False);
  FScene.Add(Self, LAYER_GROUND);
  X.Value := aX;
  BottomY := aBottomY;
end;

{ TBGFence }

constructor TBGFence.Create(var aX: single; aUseHorizontalBar: boolean);
begin
  inherited Create(texBGFenceVertical, False);
  FScene.Add(Self, LAYER_GROUND);
  X.Value := aX;
  Y.Value := FWorldArea.Bottom-ScaleH(200);      //235

  if aUseHorizontalBar then
    with TSprite.Create(texBGFenceHorizontal, False) do begin
      SetChildOf(Self, 0);
      SetCoordinate(Self.Width, 0);
    end;
  aX := aX + Self.Width + texBGFenceHorizontal^.FrameWidth;
end;

{ TGroundStain }

constructor TGroundStain.Create(aX, aY: single);
begin
  inherited Create(texGroundStain, False);
  FScene.Add(Self, LAYER_GROUND);
  Scale.Value := PointF(2, 2);
  ScaledX := aX;
  ScaledY := aY; // FWorldArea.Bottom-(ScaleH(768)-aY);
  FlipH :=  Random > 0.5;
  FlipV :=  Random > 0.5;
  Tint.Value := BGRA(255,255,255, Random(50));
end;

{ TBarrel }

constructor TBarrel.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(texBarrel, False);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
end;

{ TSewerPlate }

constructor TSewerPlate.Create(aX: single);
begin
  inherited Create(texSewerPlate, False);
  FScene.Add(Self, LAYER_GROUND);
  SetCoordinate(aX, FWorldArea.Bottom-ScaleH(89));
end;

{ TSky }

constructor TSky.Create;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_BG3);
  Gradient.CreateVertical([BGRA(27,6,58), BGRA(87,19,194), BGRA(87,19,194)], [0, 0.5, 1.0]);
  SetSize(Round(FWorldArea.Width)+FScene.Width, Round(FWorldArea.Height));
  X.Value := -FScene.Width;
  PostMessage(0, 10); // start storm
end;

procedure TSky.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // storm
    0: begin
      inc(FStormIndex);
      if FStormIndex = 2 then FStormIndex := 0;
      case FStormIndex of
        0: Audio.PlayThenKillSound('lighning1.ogg', 0.6, Random*2-1, 1.0+Random*0.5-0.25);
        1: Audio.PlayThenKillSound('lighning2.ogg', 0.7, Random*2-1, 1.0+Random*0.5-0.25);
      end;
      Tint.Value := BGRA(200,200,200);
      PostMessage(2, 0.1);
    end;
    2: begin
      Tint.Value := BGRA(0,0,0,0);
      PostMessage(0, 6+Random*10);
    end;
  end;
end;

{ TScreenMermaidsBoss }

procedure TScreenMermaidsBoss.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;
  case AValue of
    gsRunning: begin
      FRedEgg.ApplyBounds := True;
      FBlackEgg.ApplyBounds := True;
    end;
    gsLRWin: PostMessage(500);
    gsLRLose: PostMessage(600);
  end;
end;

procedure TScreenMermaidsBoss.ResetVariables;
begin
  FWorkingContainer := NIL;
end;

procedure TScreenMermaidsBoss.StartRain(aDuration: single);
begin
  FsndRain := Audio.AddSound('rain.ogg', 0.0, True);
  FsndRain.FadeIn(0.4, 4.0);
  FRain.ParticlesToEmit.ChangeTo(1024, aDuration, idcStartSlowEndFast);
end;

procedure TScreenMermaidsBoss.CreateClouds;
var i: integer;
begin
  for i:=0 to 15 do TCloud.Create(Random*FScene.Width, Random*FScene.Height*0.2, 0.6, -1, LAYER_BG3);
  for i:=0 to 15 do TCloud.Create(Random*FScene.Width, Random*FScene.Height*0.2, 0.5, -1, LAYER_BG3);
  for i:=0 to 15 do TCloud.Create(Random*FScene.Width, Random*FScene.Height*0.2, 0.4, -1, LAYER_BG3);
  TCloud.Create(0, 0, 0.2, -1, LAYER_BG3);
  TCloud.Create(FScene.Width*0.3, FScene.Height*0.15, 0.2, -1, LAYER_BG3);
  TCloud.Create(FScene.Width*0.75, FScene.Height*0.2, 0.25, -1, LAYER_BG3);
  TCloud.Create(FScene.Width*0.5, FScene.Height*0.05, 0.3, -1, LAYER_BG3);
  TCloud.Create(FScene.Width*1, FScene.Height*0.1, 0.25, -1, LAYER_BG3);
end;

procedure TScreenMermaidsBoss.CreateGround;
var ground: TGradientRectangle;
begin
  ground := TGradientRectangle.Create(FScene);
  FScene.Add(ground, LAYER_BG2);
  ground.Gradient.CreateVertical([BGRA(25,40,31), BGRA(55,48,39)], [0, 1]);
  ground.SetSize(Round(FWorldArea.Width)+FScene.Width, ScaleH(296));
  ground.X.Value := -FScene.Width;
  ground.Y.Value := FWorldArea.Bottom - ScaleH(296);
end;

procedure TScreenMermaidsBoss.CreateFactory3(aFromX: single);
var w: single;
begin
  w := texFactory3^.FrameWidth * FACTORY3_SCALE;
  while aFromX < FWorldArea.Right do begin
    TFactory3.Create(aFromX);
    aFromX := aFromX + w + Random*w;
  end;
end;

procedure TScreenMermaidsBoss.CreateFactory2(aFromX: single);
begin
  while aFromX < FWorldArea.Right do begin
    TFactory2.Create(aFromX);
    aFromX := aFromX + texFactory2^.FrameWidth * FACTORY2_SCALE;
  end;
end;

procedure TScreenMermaidsBoss.CreateFactory1(aX: single; aCount: integer);
begin
  while aCount > 0 do begin
    TFactory1.Create(aX);
    aX := aX + texFactory1^.FrameWidth*FACTORY1_SCALE;
    dec(aCount);
  end;
end;

procedure TScreenMermaidsBoss.CreateBGFence(aXBegin, aXEnd: single);
var w: single;
begin
  w := texBGFenceVertical^.FrameWidth + texBGFenceHorizontal^.FrameWidth;
  while aXBegin < aXEnd do
    TBGFence.Create(aXBegin, aXBegin+w < aXEnd);
end;

procedure TScreenMermaidsBoss.CreateLevel;
begin
  FWorldArea := RectF(0, 0, ScaleW(2048), ScaleH(768));
  TSky.Create;
  CreateClouds;
  CreateGround;
  TGroundStain.Create(ScaleW(-184), ScaleH(623));
  TGroundStain.Create(ScaleW(143), ScaleH(569));
  TGroundStain.Create(ScaleW(513), ScaleH(627));
  TGroundStain.Create(ScaleW(933), ScaleH(567));
  TGroundStain.Create(ScaleW(1379), ScaleH(609));
  TGroundStain.Create(ScaleW(1696), ScaleH(573));
  CreateFactory3(ScaleW(-697));
  CreateFactory2(ScaleW(-697));
  CreateFactory1(ScaleW(-697), 4);
  CreateBGFence(0, FWorldArea.Right);

  TSewerPlate.Create(ScaleW(-345));
  TSewerPlate.Create(ScaleW(279));
  TSewerPlate.Create(ScaleW(1206));
  TSewerPlate.Create(ScaleW(1866));

  TBarrel.Create(ScaleW(1221), ScaleH(534), LAYER_GROUND);
  TBarrel.Create(ScaleW(1306), ScaleH(536), LAYER_GROUND);

  FControlPanel := TControlPanel.Create(ScaleW(909), FScene.Height);

  TPanelExit.Create(ScaleW(1784), ScaleH(668));
  with FScene.AddSprite(texTunnel, False, LAYER_ARROW) do
    SetCoordinate(ScaleW(1936), ScaleH(505));
  StartRain(0);

  FLR.X.Value := FLR.BodyWidth*2;
  FLR.BodyBottomY := GetYGround;

  // constrained size for the camera
  FViewArea.Left := FWorldArea.Left + FScene.Width*0.5;
  FViewArea.Top := FWorldArea.Top + FScene.Height*0.5;
  FViewArea.Right := FWorldArea.Right - FScene.Width*0.5;
  FViewArea.Bottom := FWorldArea.Bottom - FScene.Height*0.5;
end;

procedure TScreenMermaidsBoss.CreateProgressBar;
  function MakePB: TUIProgressBar;
  begin
    Result := TUIProgressBar.Create(FScene, uioVertical);
    FScene.Add(Result, LAYER_GAMEUI);
    Result.BodyShape.ResizeCurrentShape(FScene.Width div 40, FScene.Height div 2, True);
    Result.Percent := 1.0;
    Result.CenterY := FScene.Height*0.5;
    Result.Visible := False;
    Result.Reversed := True;
    Result.MouseInteractionEnabled := False;
  end;
begin
  FLRLifeProgressBar := MakePB;
  FLRLifeProgressBar.X.Value := PPIScale(10);

  FMarcusProgressBar := MakePB;
  FMarcusProgressBar.RightX := FScene.Width-PPIScale(10);
end;

procedure TScreenMermaidsBoss.DefineSubTextures(aAtlas: TAtlas);
var path: string;
begin
  AdditionnalScale := 0.8;
  LoadLR4DirTextures(aAtlas, False);
  LoadWolfTextures(aAtlas);
  LoadMarcusTextures(aAtlas);
  AdditionnalScale := 1.0;

  path := FolderSpriteGameMermaidsPort;
  texCraneHook := aAtlas.AddFromSVG(path+'CraneHook.svg', -1, ScaleH(137));
  texCraneHookBG := aAtlas.AddFromSVG(path+'CraneHookBG.svg', ScaleW(55), -1);
  texContainer := aAtlas.AddFromSVG(path+'Container.svg', ScaleW(408), -1);
  texPanelExit := aAtlas.AddFromSVG(SpriteGameVolcanoInnerFolder+'PanelExit.svg', ScaleW(52), -1);
  texSewerPlate := aAtlas.AddFromSVG(path+'SewerPlate.svg', ScaleW(66), -1);
  texBarrel := aAtlas.AddFromSVG(path+'Barrel.svg', ScaleW(72), -1);
  texGroundStain := aAtlas.AddFromSVG(path+'GroundStain.svg', ScaleW(120), -1);
  texBGFenceVertical := aAtlas.AddFromSVG(path+'BGFenceVertical.svg', -1, ScaleH(55));
  texBGFenceHorizontal := aAtlas.AddFromSVG(path+'BGFenceHorizontal.svg', ScaleW(25), -1);
  texControlPanel := aAtlas.AddFromSVG(path+'ControlPanel.svg', ScaleW(73), -1);
  texTunnel := aAtlas.AddFromSVG(path+'Tunnel.svg', ScaleW(165), -1);

  path := GetFolderSpritePlainOfSleepingMoon;
  texFactory1 := aAtlas.AddFromSVG(path+'Factory1.svg', ScaleW(710 div 2), -1);
  texFactory2 := aAtlas.AddFromSVG(path+'Factory2.svg', ScaleW(634 div 2), -1);
  texFactory3 := aAtlas.AddFromSVG(path+'Factory3.svg', ScaleW(354 div 2), -1);

  TCommonEggs.LoadTexture(aAtlas);
  AddSphereParticleToAtlas(aAtlas);
  TImpact1.LoadTexture(aAtlas);
  TMarcusHelicopter.LoadTexture(aAtlas);

  LoadCloudsTexture(aAtlas);
  AddRainDropParticleToAtlas(aAtlas);
  // ui
  CreateGameFontNumber(aAtlas); // < must be first !
  // font for button in pause panel
  FFontText := CreateGameFontText(aAtlas);
  LoadGameDialogTextures(aAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(aAtlas);
  LoadMousePointerTexture(aAtlas);
end;

procedure TScreenMermaidsBoss.CreateObjects;
begin
  FGameState := gsUndefined;
  ResetVariables;
  Audio.PauseMusicTitleMap(3.0);

  CheckAtlas(FAtlas, 'mermaidsboss.atlas');

  // rain
  FRain := TParticleEmitter.Create(FScene);
  FScene.Add(FRain, LAYER_WEATHER);
  FRain.LoadFromFile(ParticleFolder+'RainMermaidsPort.par', FAtlas);
  FRain.SetEmitterTypeRectangle(FScene.Width, FScene.Height);
  FRain.Opacity.Value := 180;
  FRain.ParticlesToEmit.Value := 0;

  // LR
  FLR := TCustomLR4Direction.Create(LAYER_PLAYER);
  FLR.X.Value := -FLR.BodyWidth*1.5;
  FLR.BodyBottomY := ScaleH(600);
  FLR.TimeMultiplicator := 0.6;
  FLR.JumpDeltaX := FScene.Width*0.115;
  FLR.SetWindSpeed(2.0);
  FLR.IdleRight;
  FLR.ApplyTint(BGRA(29,0,50,80));
  FLR.Visible := False;

  // Marcus
  FMarcus := TWolfMarcus.Create(False);
  FMarcus.X.Value := FScene.Width + FMarcus.BodyWidth*2;
  FMarcus.BodyBottomY := GetYGround;
  FMarcus.SetWalkMode;

  // life progress bar
  CreateProgressBar;

  // eggs
  FRedEgg := TRedEgg.Create;
  FRedEgg.SetCoordinate(ScaleW(1100), ScaleH(203));
  FRedEgg.ApplyBounds := False;
  FBlackEgg := TBlackEgg.Create;
  FBlackEgg.SetCoordinate(ScaleW(1100), ScaleH(187));
  FBlackEgg.ApplyBounds := False;

  // level
  CreateLevel;

  // camera
  FCamera := FScene.CreateCamera;
  FCamera.AssignToLayerRange(LAYER_ARROW, LAYER_GROUND);
  FCamera.AutoFollow.Bounds := FViewArea;
  FCamera.AutoFollow.SetTargetSurface(FLR, True);
  FCamera.AutoFollow.Speed := 0.01;

  FCameraFactory2 := FScene.CreateCamera;
  FCameraFactory2.AssignToLayer(LAYER_BG1);

  FCameraFactory3 := FScene.CreateCamera;
  FCameraFactory3.AssignToLayer(LAYER_BG2);

  // pause panel
  FPausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  CustomizeMousePointer;

  if PlayerInfo.MermaidsPort.MarcusEncounterDone then
    PostMessage(50)  // ask to review marcus encounter or not
  else
    PostMessage(100); // anim Marcus encounter
end;

procedure TScreenMermaidsBoss.FreeObjects;
begin
  if FsndRain <> NIL then begin
    FsndRain.FadeOutThenKill(3.0);
    FsndRain := NIL;
  end;

  if FScene.RequestedScreen = ScreenMap then
    Audio.ResumeMusicTitleMap;

  FScene.KillCamera(FCamera);
  FScene.KillCamera(FCameraFactory2);
  FScene.KillCamera(FCameraFactory3);
  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
  ChallengeMode := False;
end;

procedure TScreenMermaidsBoss.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // ask to see again Marcus meeting
    50: with TDialogQuestion.Create(sWouldYouLikeToSeeMarcus, sYes, sNo, FFontText, Self, 100, 250, FAtlas) do
          ShowModal;

    // MARCUS ENCOUNTER
    100: Begin
      FLR.Visible := True;
      FLR.X.Value := -FLR.BodyWidth*1.5;
      PostMessage(102, 2.0);
    end;
    102: FLR.WalkHorizontallyTo(ScaleW(234), Self, 105);
    105: begin
      FLR.IdleRight;
      FLR.SetFaceType(lrfWorry);
      PostMessage(110);
    end;
    110: FMarcus.WalkHorizontallyTo(ScaleW(722), Self, 115); // marcus comes
    115: begin
      FMarcus.IdleLeft;
      FMarcus.ShowDialog(sMySisterWasRight, FFontText, Self, 120);
    end;
    120: begin
      FLR.ShowQuestionMark;
      PostMessage(125, 1.0);
    end;
    125: FMarcus.ShowDialog(sImMarcus, FFontText, Self, 130);
    130: begin
      FLR.HideMark;
      FLR.ShowDialog(sIHaveToGetToTheIsland, FFontText, Self, 135);
    end;
    135: FMarcus.ShowDialog(sOfCourseThereIsBut, FFontText, Self, 140);
    140: FLR.ShowDialog(sAreYouInTheHabit, FFontText, Self, 145);
    145: FMarcus.ShowDialog(sItsMoreFunThisWay, FFontText, Self, 150);
    150: FMarcus.ShowDialog(sIKnowAGame, FFontText, Self, 155);
    155: FLR.ShowDialog(sPfffThatsNotFairplay, FFontText, Self, 160);
    160: FMarcus.ShowDialog(sComeOnImSureWith, FFontText, Self, 165);
    165: begin
      FRedEgg.FlipH := True;
      FRedEgg.MoveTo(FLR.X.Value-FRedEgg.Width*0.5, ScaleH(203), 3.5, idcSinusoid);
      FRedEgg.PlaySoundWhenArrive;
      FBlackEgg.FlipH := True;
      FBlackEgg.MoveTo(FMarcus.X.Value-FBlackEgg.Width*0.5, ScaleH(203), 3.5, idcSinusoid);
      FBlackEgg.PlaySoundWhenArrive;
      PostMessage(167, 3.5);
    end;
    167: begin
      FRedEgg.FlipH := False;
      PostMessage(170, 0.5);
    end;
    170: FMarcus.ShowDialog(sSeeTheseEggShaped, FFontText, Self, 175);
    175: FMarcus.ShowDialog(sRedIsForYou, FFontText, Self, 180);
    180: FLR.ShowDialog(sErIDontWantToEndMyLife, FFontText, Self, 185);
    185: FMarcus.ShowDialog(sDontBeAfraidYoureSafe, FFontText, Self, 190);
    190: begin // character 'enter' into the eggs
      FRedEgg.MoveTo(FLR.X.Value-FRedEgg.Width*0.6, FLR.BodyBottomY-FRedEgg.Height*0.9, 2.0);
      FBlackEgg.MoveTo(FMarcus.X.Value-FBlackEgg.Width*0.45, FMarcus.BodyBottomY-FBlackEgg.Height*0.9, 2.0);
      PostMessage(195, 2.5);
    end;
    195: begin
      FRedEgg.SetDriverAsChild(FLR);
      FBlackEgg.SetDriverAsChild(FMarcus);
      Audio.PlayThenKillSound('pneumatic-grease-bomb.ogg', 1.0);
      PostMessage(200, 0.5);
    end;
    200: begin // eggs fly
      FRedEgg.Y.ChangeTo(ScaleH(310), 2.0, idcSinusoid);
      FBlackEgg.Y.ChangeTo(ScaleH(310), 2.0, idcSinusoid);
      FRedEgg.PitchSoundForMove;
      FBlackEgg.PitchSoundForMove;
      PostMessage(205, 2.0);
      PlayerInfo.MermaidsPort.MarcusEncounterDone := True;
      FSaveGame.Save;
    end;
    205: begin
      FRedEgg.State := eggsIdleFly;
      FBlackEgg.State := eggsIdleFly;
      FCamera.Pivot := PointF(0.5, 1.0);
      FCameraFactory2.Pivot := PointF(0.5, 1.0);
      FCameraFactory3.Pivot := PointF(0.5, 1.0);
      FCamera.Scale.ChangeTo(PointF(0.7, 0.7), 1.0, idcSinusoid);
      FCameraFactory2.Scale.ChangeTo(PointF(0.8, 0.8), 1.0, idcSinusoid);
      FCameraFactory3.Scale.ChangeTo(PointF(0.9, 0.9), 1.0, idcSinusoid);
      FCameraViewRect := FCamera.GetViewRect;
      PostMessage(210, 1.0);
    end;
    210: begin
      GameState := gsRunning;
      FLR.SetFaceType(lrfSmile);
      FRedEgg.ComputeMoveBounds;
      FBlackEgg.ComputeMoveBounds;
      FLRLifeProgressBar.Visible := True;
      FLRLifeProgressBar.Percent := 1.0;
      FMarcusProgressBar.Visible := True;
      FMarcusProgressBar.Percent := 1.0;
      FBlackEgg.StartBossSequence;
      ShowGameInstructions(sMermaidBossInstructions);
    end;

    // START THE GAME DIRECTLY (without Marcus meeting)
    250: begin
      FLR.Visible := True;
      FLR.X.Value := ScaleW(234);
      FLR.BodyBottomY := GetYGround;
      FMarcus.X.Value := ScaleW(722);
      FMarcus.BodyBottomY := GetYGround;
      FRedEgg.SetCoordinate(FLR.X.Value-FRedEgg.Width*0.6, FLR.BodyBottomY-FRedEgg.Height*0.9);
      FBlackEgg.SetCoordinate(FMarcus.X.Value-FBlackEgg.Width*0.45, FMarcus.BodyBottomY-FBlackEgg.Height*0.9);
      FBlackEgg.FlipH := True;
      FRedEgg.SetDriverAsChild(FLR);
      FBlackEgg.SetDriverAsChild(FMarcus);
      FRedEgg.Y.Value := ScaleH(310);
      FBlackEgg.Y.Value := ScaleH(310);
      FRedEgg.State := eggsIdleFly;
      FBlackEgg.State := eggsIdleFly;
      FCamera.Scale.Value := PointF(0.7, 0.7);
      FCamera.Pivot := PointF(0.5, 1.0);
      FCameraFactory2.Pivot := PointF(0.5, 1.0);
      FCameraFactory3.Pivot := PointF(0.5, 1.0);
      FCameraFactory2.Scale.Value := PointF(0.8, 0.8);
      FCameraFactory3.Scale.Value := PointF(0.9, 0.9);
      FCameraViewRect := FCamera.GetViewRect;
      FRedEgg.PrepareSoundToFight;
      FBlackEgg.PrepareSoundToFight;
      PostMessage(210);
    end;

    // CONTAINER FALLING ON MARCUS
    300: begin
      // immobiliser Marcus et enlever son mode defense
      FBlackEgg.State := eggsFreezed;
      PostMessage(305)
      // attendre que le container soit totalement tombé
      // exploser le container
      // enlever un peu de vie à Marcus
      // Marcus reste immobile pendant 3s
      // après les 3s, Marcus se met en mode défense puis reprend son cycle du début
    end;
    305: begin  // wait the container is destroyed, then put the eggs in stuned state
      if FWorkingContainer <> NIL then begin
        FBlackEgg.BottomY := FWorkingContainer.BottomY;
        PostMessage(305);
      end else begin
        FMarcusProgressBar.Percent := FMarcusProgressBar.Percent - 0.2;
        FBlackEgg.State := eggsStunned;
        PostMessage(310, 3.0); // time Marcus stay freezed
      end;
    end;
    310: if FMarcusProgressBar.Percent > 0.1 then FBlackEgg.ResumeBossSequence;

    // CONTAINER FALLING ON LR
    400: begin
      // immobiliser l'oeuf de LR
      FRedEgg.State := eggsFreezed;
      PostMessage(405);
      // attendre que le container soit totalement tombé
      // exploser le container
      // enlever un peu de vie à LR
    end;
    405: begin // wait the container is fully fallen
      if FWorkingContainer <> NIL then begin
        FRedEgg.BottomY := FWorkingContainer.BottomY;
        PostMessage(405);
      end else begin
          FLRLifeProgressBar.Percent := FLRLifeProgressBar.Percent - 0.4;
          FRedEgg.State := eggsStunned;
          PostMessage(410, 3.0); // time LR stay freezed
        end;
    end;
    410: if FLRLifeProgressBar.Percent > 0.1 then FRedEgg.State := eggsIdleFly;

    // LR WIN
    500: begin
      Audio.PlayMusicSuccessShort1;
      FLR.SetFaceType(lrfHappy);
      FBlackEgg.State := eggsBroken;
      FRedEgg.State := eggsUndefined;
      FRedEgg.Defend(False);
      PostMessage(505, 3.0);
    end;
    505: begin // moves eggs to the y ground
      FBlackEgg.Angle.ChangeTo(0, 0.5, idcSinusoid);
      FBlackEgg.MoveTo(ScaleW(722)-FBlackEgg.Width*0.45, GetYGround-FBlackEgg.Height*0.9, 2.0, idcSinusoid);
      FRedEgg.Angle.ChangeTo(0, 0.5, idcSinusoid);
      FRedEgg.MoveTo(ScaleW(234)-FRedEgg.Width*0.6, GetYGround-FRedEgg.Height*0.9, 2.0, idcSinusoid);
      PostMessage(510, 2.0);
    end;
    510: begin // removes child dependencies
      FRedEgg.RemoveDriver(LAYER_PLAYER);
      FBlackEgg.RemoveDriver(LAYER_WOLF);
      FMarcus.ApplySymmetryWhenFlip := False;
      FLR.ApplySymmetryWhenFlip := False;
      FLR.IdleRight;
      FMarcus.IdleLeft;
      PostMessage(515, 0.5);
    end;
    515: begin  // eggs go up
      FLR.SetFaceType(lrfSmile);
      FBlackEgg.ApplyBounds := False;
      FRedEgg.ApplyBounds := False;
      FBlackEgg.Y.ChangeTo(ScaleH(190), 1.0, idcDrop);
      FRedEgg.Y.ChangeTo(ScaleH(190), 1.0, idcDrop);
      FRedEgg.PitchSoundForMove;
      FBlackEgg.PitchSoundForMove;
      PostMessage(520, 1.0);
    end;
    520: begin // eggs exit to the right
      FBlackEgg.Defend(True);
      FBlackEgg.X.ChangeTo(FScene.Width*2, 3.0, idcSinusoid);
      FRedEgg.X.ChangeTo(FScene.Width*2, 3.0, idcSinusoid);
      FBlackEgg.KillDefered(3.0);
      FRedEgg.KillDefered(3.0);
      FBlackEgg.PlaySoundWhenLeave;
      FRedEgg.PlaySoundWhenLeave;
      PostMessage(525, 1.0);
    end;
    525: begin
      FCamera.Scale.ChangeTo(PointF(1.0, 1.0), 2.0, idcSinusoid);
      FCameraFactory2.Scale.ChangeTo(PointF(1.0, 1.0), 2.0, idcSinusoid);
      FCameraFactory3.Scale.ChangeTo(PointF(1.0, 1.0), 2.0, idcSinusoid);
      FLRLifeProgressBar.Opacity.ChangeTo(0, 2.0);
      FLRLifeProgressBar.KillDefered(2.0);
      FMarcusProgressBar.Opacity.ChangeTo(0, 2.0);
      FMarcusProgressBar.KillDefered(2.0);
      PostMessage(530, 2.0);
    end;
    530: FMarcus.ShowDialog(sCongratOnceAgain, FFontText, Self, 535);
    535: FLR.ShowDialog(sItWasFunny, FFontText, Self, 540);
    540: FMarcus.ShowDialog(sIllHelpYouToo, FFontText, Self, 545);
    545: begin
      FCamera.AutoFollow.SetTargetSurface(FLR, False);
      FMarcus.TimeMultiplicator := 0.5;
      FMarcus.WalkSpeed := FLR.WalkSpeed*0.80;
      FMarcus.WalkHorizontallyTo(ScaleW(1667), Self, 547);
      FLR.WalkHorizontallyTo(ScaleW(1481), Self, 550);
    end;
    547: FMarcus.IdleLeft;
    550: begin
      FLR.IdleRight;
      PostMessage(555, 1.0);
    end;
    555: FMarcus.ShowDialog(sTakeThisTunnel, FFontText, Self, 560);
    560: FLR.ShowDialog(sFinally, FFontText, Self, 565);
    565: FMarcus.ShowDialog(sGoodLuckSeeYouSoon, FFontText, Self, 570);
    570: begin
      FLR.WalkHorizontallyTo(ScaleW(1811), Self, 572);
      FMarcus.WalkHorizontallyTo(ScaleW(1667), Self, 575);
      FsndHelico := Audio.AddSound('HelicopterLoop.ogg', 0.0, True);
      FsndHelico.Fadein(0.9, 3.0);
      FsndHelico.Pan.Value := 1.0;
      FsndHelico.Pan.ChangeTo(-0.2, 3.0);
    end;
    572: begin
      FLR.IdleLeft;
      FLR.SetFaceType(lrfWorry);
    end;
    575: begin
      FHelico := TMarcusHelicopter.Create(LAYER_ARROW);
      FHelico.SetCoordinate(ScaleW(1577), ScaleH(-375));
      FHelico.MoveTo(ScaleW(1117), ScaleH(500), 3.0, idcSinusoid);
      FHelico.Angle.Value := 20;
      FHelico.Angle.ChangeTo(0, 2.8, idcStartSlowEndFast);
      PostMessage(573, 3.0);
    end;
    573: FMarcus.WalkHorizontallyTo(ScaleW(1234), Self, 576);
    576: begin
      FMarcus.IdleLeft;
      FMarcus.Visible := False;
      FHelico.MoveTo(ScaleW(427), ScaleH(-404), 2.0, idcDrop);
      FHelico.Angle.ChangeTo(-30, 1.5, idcStartSlowEndFast);
      FsndHelico.Pan.ChangeTo(-1.0, 3.0);
      FsndHelico.FadeOutThenKill(4.0);
      FsndHelico := NIL;
      PostMessage(579, 2.0);
    end;
    579: begin
      FLR.ShowExclamationMark;
      PostMessage(581, 2.0);
    end;
    581: begin
      FLR.HideMark;
      FLR.ShowDialog(sPfffHeCouldHave, FFontText, Self, 584);
    end;
    584: FLR.WalkHorizontallyTo(FWorldArea.Right+FLR.BodyWidth, Self, 587);
    587: begin
      PlayerInfo.MermaidsPort.IncCurrentStep;
      FSaveGame.Save;
      FScene.RunScreen(ScreenMap); //ScreenMermaidsSeaSide);
    end;

    // LR LOSE
    600: begin
      FRedEgg.State := eggsBroken;
      FLR.SetFaceType(lrfNotHappy);
      FBlackEgg.State := eggsUndefined;
      FBlackEgg.Defend(False);
      PostMessage(605, 3.0);
    end;
    605: with TDialogQuestion.Create(sWouldYouLikeToTryAgain, sYes, sNo, FFontText, Self, 615, 610, FAtlas) do
           ShowModal;
    610: FScene.RunScreen(ScreenMap);
    615: begin // remove smoke/fire from LR egg
      FRedEgg.RemoveBrokenState;
      FRedEgg.SetCoordinate(ScaleW(234)-FRedEgg.Width*0.6, ScaleH(310));
      FBlackEgg.SetCoordinate(ScaleW(722)-FBlackEgg.Width*0.45, ScaleH(310));
      FRedEgg.State := eggsIdleFly;
      FBlackEgg.State := eggsIdleFly;
      PostMessage(210);
    end;

  end;
end;

procedure TScreenMermaidsBoss.Update(const aElapsedTime: single);
var p: TPointF;
begin
  inherited Update(aElapsedTime);

  case GameState of
    gsRunning: begin
      // shoot
      if Input.Action1Pressed then
        FRedEgg.Shoot;

      // defend
      if Input.Action2Pressed and (FRedEgg.State <> eggsStunned) then begin
        FRedEgg.Defend(True);
      end else FRedEgg.Defend(False);

      if Input.UpPressed and (FRedEgg.State <> eggsStunned) then
        FRedEgg.MoveUp;

      if Input.DownPressed and (FRedEgg.State <> eggsStunned) then
        FRedEgg.MoveDown;

      if Input.LeftPressed and (FRedEgg.State <> eggsStunned) then
        FRedEgg.MoveLeft;

      if Input.RightPressed and (FRedEgg.State <> eggsStunned) then
        FRedEgg.MoveRight;

      if FMarcusProgressBar.Percent < 0.01 then begin
        GameState := gsLRWin;
        exit;
      end;

      if FLRLifeProgressBar.Percent < 0.01 then begin
        GameState := gsLRLose;
        exit;
      end;
    end;// gsRunning

    gsLRWin: begin
      // parallax horizontal
      p := FCamera.LookAt.Value;
      FCameraFactory2.LookAt.x.Value := p.x * 0.5;
      FCameraFactory3.LookAt.x.Value := p.x * 0.25;
    end;
  end;// case

  // check if player pause the game
  if Input.PausePressed then
    FPausePanel.ShowModal;
end;

end.

