unit u_screen_gamevolcanodino;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lr4dir, u_sprite_lrcommon, u_sprite_def, u_lr4_usable_object;

type

TGameState=(gsUndefined=0, gsIdle, gsRunningOnGround, gsRacing,
            gsComputerAnim, gsOpenDoorAnim,
            gsLRLost, gsOutOfGas, gsLRWin);

{ TScreenGameVolcanoDino }

TScreenGameVolcanoDino = class(TGameScreenTemplate)
var FGameState: TGameState;
private
  FViewArea: TRectF;
  FCamera: TOGLCCamera;
  FCameraFollowLR, FCameraStayVerticallyCenteredOnScene: boolean;
  FLRWaitInTheAir: boolean;

  FsndDoorBeep, FsndEarthQuakeLoop, FsndEmotionMusic: TALSSound;

  FPanelComputer: TPanelUsingComputer;
  FInGamePausePanel: TInGamePausePanel;

  FDifficulty: integer;
  procedure CreateGround;
  procedure CreateLevel;
  procedure ProcessLayerComputerBeforeUpdateEvent;
  procedure SetGameState(AValue: TGameState);
  procedure CreateEndRaceMessage(const aMess: string; aAppearTime, aStayTime: single);
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  procedure MoveCameraTo(const p: TPointF; aDuration: single);
  procedure ZoomCameraTo(const z: TPointF; aDuration: single);
  function GetCameraCenterView: TPointF;

  procedure LRLostTheRace;

  property Difficulty: integer write FDifficulty;
  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenGameVolcanoDino: TScreenGameVolcanoDino;

implementation

uses Forms, u_sprite_wolf, u_app, u_resourcestring, u_utils, u_screen_map,
  LCLType, Math, BGRAPath, ALSound;

{
  -  flat
  /  upward slope
  \  downward slope
  o  gas cans
  R  pile of rock
  X  end of race
  E  end of view
}
const LevelData=
  '--------//----\\--------\\----//-----------o-----R--------//////-----R----o-----R----//////o'+
  '----------//////o\\\\\\\\\\\\\\\\\\----R----\\\\\\\\\\\\\\o\\--------////--\\\\-------R------o'+
  '\\\\\\\\\\\\\\\\o////////////////--------------------///o///--------\\\\\\----R----///////o'+
  '\\\\\\\//////\\\\\\\//////---o---\\\\\\\///////\\\\\\\///o////\\\\\\\///////\\\\\\\///////\\\///----o'+
  '//////////o//////////\\\\\\\\\\\\\\\\\\\\o--//--\\--//--\\--//--\\//\\\\////\\\\////----------------'+
  '------------X--------E-';
  TRAIL_DECORS_COUNT = 9;
type

{ TGroundBase }

TGroundBase = class(TTiledSprite)
  procedure CreateGroundDeep(aX, aY: single; aLayerIndex: integer; aCreateCeilling: boolean);
  constructor Create(aTexture: PTexture; aX, aY: single; aLayerIndex: integer);
end;

TGroundFlat = class(TGroundBase)
  constructor Create(aX, aY: single; aLayerIndex: integer);
  procedure Update(const aElapsedTime: single); override;
end;

TGroundSlope = class(TGroundBase)
  constructor Create(aX, aY: single; aLayerIndex: integer);
  procedure Update(const aElapsedTime: single); override;
end;

TGroundDeep = class(TGroundBase)
  constructor Create(aX, aY: single; aLayerIndex: integer);
  procedure Update(const aElapsedTime: single); override;
end;

TPanelExit = class(TSprite)
  constructor Create;
  procedure Update(const aElapsedTime: single); override;
end;

TFloorFlat = class(TGroundFlat)
  constructor Create(aLayerIndex: integer; aCreateCeilling: boolean=True);
end;

TFloorFlatWithCeilSlopeUp = class(TGroundFlat)
  constructor Create(aLayerIndex: integer; aCeilShift: single);
end;

TFloorFlatWithCeilSlopeDown = class(TGroundFlat)
  constructor Create(aLayerIndex: integer; aCeilShift: single);
end;

TFloorSlopeUp = class(TGroundSlope)
  constructor Create(aLayerIndex: integer);
end;

TFloorSlopeDown = class(TGroundSlope)
  constructor Create(aLayerIndex: integer);
end;

TGazCan = class(TSprite)
  constructor Create(aLayerindex: integer);
  procedure Update(const aElapsedTime: single); override;
end;

TGasJauge = class(TUIPanel)
  class var texExclamation, texNozzle: PTexture;
private
  FNozzle,
  FExclamation : TSprite;
  FProgress: TMultiColorRectangle;
  FExclamationCanBlink: boolean;
  FPercent: single;
  function GetTankPath: TOGLCPath;
  procedure UpdateFillColor;
public
  class procedure LoadTexture (aAtlas: TOGLCTextureAtlas);
  constructor Create;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  // aAmount range is [0..1]
  procedure Refill(aAmount: single);
  // aAmount range is [0..1]
  procedure Consume(aAmount: single);
  // the percentage of the jauge [0..1]
  property Percent: single read FPercent;
end;

TProgress = class(TProgressLine)
private
  FDinoIcon, FFlagFinish: TSprite;
  FDistanceTraveledByDino: single;
  procedure SetDistanceTraveledByDino(AValue: single);
public
  constructor Create;
  property DistanceTraveledByDino: single read FDistanceTraveledByDino write SetDistanceTraveledByDino;
end;

TPileOfRocks = class(TSpriteContainer)
private
  FRocks: array of TPolarSprite;
  FXCollisionWithDino: single;
  FP1LineForLRCollision, FP2LineForLRCollision, FP3LineForLRCollision: TPointF;
  procedure CreateRocks(aX, aY: single; aCount: integer; var aK: integer);
public
  constructor Create(aX, aBottomY: single);
  procedure Update(const aElapsedTime: single); override;
end;


TStaticCeiling = class(TSprite)
  constructor Create(aX: single);
end;

TStaticPillar = class(TSprite)
  constructor Create(aX: single);
end;

TArmoredDoor = class(Tsprite)
  constructor Create(aX, aY: single; aLayerindex: integer);
end;

TDustForArmoredDoor = class(TParticleEmitter)
  constructor Create;
end;

TComputer = class(TUsableComputer)
  function GetLavaDropTargetPosition: TPointF;
end;

TFallingLavaDropOnComputer = class(TSprite)
private FDone: boolean;
public
  constructor Create(aCenterX: single; aLayerindex: integer);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  property FallIsDone: boolean read FDone;
end;

TLavaOnComputer = class(TSprite)
  constructor Create(FAtlas: TOGLCTextureAtlas);
end;

{ TCage }

TCage = class(TSprite) // the cage ground is the parent
private class var texBarBack, texBarMiddle, texBarForward, Texground, texCeiling, texChain: PTexture;
                  FAtlas: TOGLCTextureAtlas;
private
  FCeiling, FBGBar1, FBGBar2, FBGBar3, FBGBar4, FMidBarL, FMidBarR, FBar1, FBar2, FBar3, FBar4, FBar5: TSprite;
  FMessValueToSendWhenCageIsOpened: TUserMessageValue;
  FsndPneumatic: TALSSound;
  FCanSwing: boolean;
  function CreateBar(aTexture: PTexture; aX: single; aZOrder: integer): TSprite;
  function CreateBarChildOfFloor(aTexture: PTexture; aX: single; aZOrder: integer): TSprite;
  procedure CreateParticleEmitterOnBar(aBar: TSprite);
public
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas);
  constructor Create(aX: single; aLayerindex: integer);
  destructor Destroy; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure SetBottomY(aBottomY: single);
  procedure SetDinoInTheCage;
  procedure MoveCageToBottom(aDuration: single; aCurve: integer);
  procedure OpenCage(aMessageValue: TUserMessageValue);
  procedure KillBarsAndCeil;
end;


var FAtlas: TOGLCTextureAtlas;
    texGroundFlat, texGroundDeep, texGroundSlope,
    texGasCan, texRockMedium, texPanelExit,
    texDinoIcon, texFlagFinish,
    texLadder, texPillar1, texCeiling,
    texArmoredDoor,
    texLavaBall, texLavaOnComputer: PTexture;
    FFontText: TTexturedFont;
    FLR: TLR4Direction;
    FUsableComputer: TComputer;
    FArmoredDoor: TArmoredDoor;
    FDustForArmoredDoor: TDustForArmoredDoor;
    FDino: TDino;
    FCage: TCage;
    FsndDoorMotor,
    FsndFunnyMusic,
    FsndRaceMusic,
    FSndRockPileExplode: TALSSound;
    FSpriteFloorCanCheckCollisionWithLR: boolean;
    FNextXDecors, FNextYDecors, FXDecorsToSubstract: single;
    FGazCanCoordinates: TPointF;
    FIndexLevelData: integer;
    FDinoMaxSpeed, FLRMaxSpeed: single;
    FGasJauge: TGasJauge;
    FProgressLine: TProgress;

function YStepOnFloor: single;
begin
  Result := FScene.Height - texGroundFlat^.FrameHeight*1.8;
end;

function DeltaYFloorCeil: integer;
begin
  Result := FScene.Height - texGroundFlat^.FrameHeight*3;
end;

procedure RegisterGasCanCoordinate(aSpriteWidth: integer);
var v: single;
begin
  v := DeltaYFloorCeil;
  FGazCanCoordinates := PointF(FNextXDecors+aSpriteWidth*0.5, FNextYDecors-v*0.5+(v*Random*0.6-v*0.3));
end;

{ TPanelExit }

constructor TPanelExit.Create;
begin
  inherited Create(texPanelExit, False);
  FScene.Add(Self, LAYER_FXANIM);
  SetCoordinate(FNextXDecors, FNextYDecors-Height*0.7);
end;

procedure TPanelExit.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if ScreenGameVolcanoDino.GameState <> gsRacing then exit;

  // check if one character finished the race
  if (FLR.X.Value+FLR.BodyWidth*0.5 < X.Value) and
     (FDino.X.Value+FDino.BodyWidth*0.5 < X.Value) then exit;

  // check who win
  if FLR.X.Value+FLR.BodyWidth*0.5 > FDino.X.Value+FDino.BodyWidth*0.5 then
    ScreenGameVolcanoDino.GameState := gsLRWin
  else
    ScreenGameVolcanoDino.GameState := gsLRLost;
end;

{ TPileOfRocks }

procedure TPileOfRocks.CreateRocks(aX, aY: single; aCount: integer; var aK: integer);
var i: integer;
begin
  for i:=1 to aCount do begin
    FRocks[aK] := TPolarSprite.Create(texRockMedium, False);
    FScene.Add(FRocks[aK], LAYER_FXANIM);
    FRocks[aK].Polar.Center.Value := PointF(aX+Random*PPIScale(6)-PPIScale(3), aY+Random*PPIScale(6)-PPIScale(3));
    FRocks[aK].Polar.Angle.Value := 90+(Random*270-135);//180-(Random*120-60);
    FRocks[aK].Angle.Value := Random*45-22;
    inc(aK);
    aX := aX + texRockMedium^.FrameWidth*0.8;
  end;
end;

constructor TPileOfRocks.Create(aX, aBottomY: single);
var k: integer;
    xx, yy: single;
begin
  inherited create(FScene);
  FScene.Add(Self, LAYER_FXANIM);

  SetLength(FRocks, 30);
  k := 0;

  FXCollisionWithDino := aX;

  xx := aX+texRockMedium^.FrameWidth*0.5;
  yy := aBottomY-texRockMedium^.FrameHeight*0.5;
  FP1LineForLRCollision := PointF(xx, yy);
  CreateRocks(xx, yy, 6, k);
  xx := aX+texRockMedium^.FrameWidth*0.5;
  yy := yy-texRockMedium^.FrameHeight*0.9;
  CreateRocks(xx, yy, 6, k);

  xx := aX+texRockMedium^.FrameWidth*1.0;
  yy := yy-texRockMedium^.FrameHeight*0.9;
  CreateRocks(xx, yy, 5, k);
  xx := aX+texRockMedium^.FrameWidth*1.0;
  yy := yy-texRockMedium^.FrameHeight*0.9;
  CreateRocks(xx, yy, 5, k);

  xx := aX+texRockMedium^.FrameWidth*1.5;
  yy := yy-texRockMedium^.FrameHeight*0.9;
  CreateRocks(xx, yy, 4, k);
  xx := aX+texRockMedium^.FrameWidth*1.5;
  yy := yy-texRockMedium^.FrameHeight*0.9;
  CreateRocks(xx, yy, 4, k);
  FP2LineForLRCollision := PointF(xx, yy);
  FP3LineForLRCollision := PointF(xx+4*texRockMedium^.FrameWidth*0.8, yy);

{  xx := aX+texRockMedium^.FrameWidth*2.0;
  yy := yy-texRockMedium^.FrameHeight*0.9;
  CreateRocks(xx, yy, 3, k);
  xx := aX+texRockMedium^.FrameWidth*2.0;
  yy := yy-texRockMedium^.FrameHeight*0.9;
  CreateRocks(xx, yy, 3, k); }
end;

procedure TPileOfRocks.Update(const aElapsedTime: single);
var i: integer;
begin
  inherited Update(aElapsedTime);

  // check collision with Dino
  if FDino.X.Value > FXCollisionWithDino then begin
    FXCollisionWithDino := maxSingle;  // to avoid another
    FSndRockPileExplode.Position3D(FDino.X.Value+FDino.BodyWidth, FDino.Y.Value+FDino.BodyHeight*0.5, -1.0);
    FSndRockPileExplode.Play(True);
    for i:=0 to High(FRocks) do begin
      FRocks[i].Polar.Distance.ChangeTo(FScene.Width*1.5, 0.75);
      FRocks[i].Angle.AddConstant(270+Random*180);
      FRocks[i].KillDefered(0.75);
      FRocks[i].Opacity.ChangeTo(0, 0.75, idcStartSlowEndFast);
    end;
    FDino.Speed.x.Value := FDino.Speed.x.Value*0.25;
    Kill;
  end else // check collision with LR
  if FLR.CheckCollisionWithLine(FP1LineForLRCollision, FP2LineForLRCollision) then begin
    // LR collide with face of rock pile
    FLR.Speed.x.Value := Max(0, FLR.Speed.x.Value - FScene.Width*0.25);
    FLR.X.Value := FLR.X.Value - FLR.BodyWidth;
    if FLR.Speed.Y.Value > 0 then FLR.Speed.Y.Value := 0;
  end else
  if FLR.CheckCollisionWithLine(FP2LineForLRCollision, FP3LineForLRCollision) then begin
    // LR collide with top of rock pile
    FLR.Speed.x.Value := Max(0, FLR.Speed.x.Value - FScene.Width*0.25);
    if FLR.Speed.Y.Value > 0 then FLR.Speed.Y.Value := 0;
    FLR.Y.Value := FLR.Y.Value - FLR.BodyHeight;
  end;

end;

{ TProgress }

procedure TProgress.SetDistanceTraveledByDino(AValue: single);
begin
  FDistanceTraveledByDino := AValue;
  FDinoIcon.CenterX := FDistanceTraveledByDino/DistanceToTravel * Width;
end;

constructor TProgress.Create;
begin
  inherited Create;
  SetShapeLine(PointF(FScene.Width*0.05, FScene.Height*0.05),
                PointF(FScene.Width*0.8, FScene.Height*0.05));

  FDinoIcon := TSprite.Create(texDinoIcon, False);
  AddChild(FDinoIcon, 0);
  FDinoIcon.Y.Value := -FDinoIcon.Height*0.9;
  FDinoIcon.CenterX := 0;

  FFlagFinish := TSprite.Create(texFlagFinish, False);
  AddChild(FFlagFinish, 0);
  FFlagFinish.CenterY := 0;
  FFlagFinish.X.Value := Width-FFlagFinish.Width;
end;

{ TGasJauge }

function TGasJauge.GetTankPath: TOGLCPath;
var w, h: single;
begin
  w := 54;
  h := 122;
  Result := NIL;
  Result.ConcatPoints(ComputeOpenedSpline([PointF(0, h*0.25), PointF(w*0.5, 0), PointF(w, h*0.25)], ssInsideWithEnds));
  Result.ConcatPoints([PointF(w, h), PointF(0, h), PointF(0, h*0.25)]);
  Result.RemoveIdenticalConsecutivePoint;
  Result.ClosePath;
end;

procedure TGasJauge.UpdateFillColor;
begin
  FExclamationCanBlink := FPercent < 0.5;
  if FPercent > 0.5 then FProgress.SetAllColorsTo(BGRA(12,244,5))
    else FProgress.SetAllColorsTo(BGRA(173,19,6));
  FProgress.SetSize(Width, Round(Height*FPercent));
  FProgress.Y.Value := Height - FProgress.Height;
end;

class procedure TGasJauge.LoadTexture(aAtlas: TOGLCTextureAtlas);
begin
  texExclamation := aAtlas.AddFromSVG(SpriteGameVolcanoDinoFolder+'GasJaugeExclamation.svg', -1, ScaleH(73));
  texNozzle := aAtlas.AddFromSVG(SpriteGameVolcanoDinoFolder+'GasJaugeNozzle.svg', ScaleW(49), -1);
end;

constructor TGasJauge.Create;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_GAMEUI);
  BodyShape.SetCustomShape(GetTankPath, PPIScale(4));
  BodyShape.Border.Color := BGRA(251,191,50);
  MouseInteractionEnabled := False;
  SetCoordinate(FScene.Width-Width*1.1, Height*0.1);

  FProgress := TMultiColorRectangle.Create(Width, Height);
  AddChild(FProgress, 0);

  FNozzle := TSprite.Create(texNozzle, False);
  FScene.Insert(0, FNozzle, LAYER_GAMEUI);
  FNozzle.CenterX := CenterX;
  FNozzle.Y.Value := BottomY;

  FExclamation := TSprite.Create(texExclamation, False);
  FScene.Add(FExclamation, LAYER_GAMEUI);
  FExclamation.SetCenterCoordinate(Center);
  FExclamation.Visible := False;

  Refill(1.0);
  PostMessage(0); // anim blink exclamation
end;

procedure TGasJauge.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // exclamation blink
    0: begin
      FExclamation.Visible := FExclamationCanBlink;
      PostMessage(1, 0.25);
    end;
    1: begin
      FExclamation.Visible := False;
      PostMessage(0, 0.25);
    end;
  end;
end;

procedure TGasJauge.Refill(aAmount: single);
begin
  FPercent := FPercent + aAmount;
  if FPercent > 1.0 then FPercent := 1.0;
  UpdateFillColor
end;

procedure TGasJauge.Consume(aAmount: single);
begin
  FPercent := FPercent - aAmount;
  if FPercent < 0 then FPercent := 0;
  UpdateFillColor
end;

{ TGazCan }

constructor TGazCan.Create(aLayerindex: integer);
begin
  inherited Create(texGasCan, False);
  if aLayerindex <> -1 then FScene.Add(Self, aLayerindex);
  SetCoordinate(FGazCanCoordinates);
end;

procedure TGazCan.Update(const aElapsedTime: single);
var r: TRectF;
begin
  inherited Update(aElapsedTime);

  // if the sprite is too far from LR, we kill it
  if Min(FLR.X.Value, FDino.X.Value)-X.Value > FScene.Width*2 then Kill
  else begin
    // check collision with LR
    r := RectF(X.Value, Y.Value, RightX, BottomY);
    if FLR.CheckCollisionWith(r) then begin
      MoveTo(FGasJauge.Center, 0.25);
      Scale.ChangeTo(PointF(0.3,0.3), 0.25);
      Opacity.ChangeTo(0, 0.25);
      KillDefered(0.25);
      FGasJauge.Refill(0.5);
    end;
  end;

end;

{ TFloorFlatWithCeilSlopeDown }

constructor TFloorFlatWithCeilSlopeDown.Create(aLayerIndex: integer; aCeilShift: single);
begin
  inherited Create(FNextXDecors, FNextYDecors, aLayerindex);
  // create flipped sprite to construct the ceiling part
  with TGroundSlope.Create(FNextXDecors, FNextYDecors-DeltaYFloorCeil-texGroundSlope^.FrameHeight*aCeilShift, aLayerIndex) do
    FlipV := True;

  RegisterGasCanCoordinate(Width);

  CreateGroundDeep(FNextXDecors, FNextYDecors, aLayerIndex, False);
  FNextXDecors := FNextXDecors + Width;
end;

{ TFloorFlatWithCeilSlopeUp }

constructor TFloorFlatWithCeilSlopeUp.Create(aLayerIndex: integer; aCeilShift: single);
begin
  inherited Create(FNextXDecors, FNextYDecors, aLayerindex);
  // create flipped sprite to construct the ceiling part
  with TGroundSlope.Create(FNextXDecors, FNextYDecors-DeltaYFloorCeil-texGroundSlope^.FrameHeight*aCeilShift, aLayerIndex) do begin
    FlipV := True;
    FlipH := True;
  end;

  RegisterGasCanCoordinate(Width);

  CreateGroundDeep(FNextXDecors, FNextYDecors, aLayerIndex, False);
  FNextXDecors := FNextXDecors + Width;
end;

{ TFloorSlopeDown }

constructor TFloorSlopeDown.Create(aLayerIndex: integer);
begin
  inherited create(FNextXDecors, FNextYDecors, aLayerindex);
  FlipH := True;
  // create flipped sprite to construct the ceiling part
  with TGroundSlope.Create(FNextXDecors, FNextYDecors-DeltaYFloorCeil{-Height}, aLayerIndex) do begin
    FlipV := True;
    //FlipH := True;
  end;
  CreateGroundDeep(FNextXDecors, FNextYDecors, aLayerIndex, True);

  RegisterGasCanCoordinate(Width);

  FNextYDecors := FNextYDecors + texGroundDeep^.FrameHeight;
  FNextXDecors := FNextXDecors + Width;
end;

{ TFloorSlopeUp }

constructor TFloorSlopeUp.Create(aLayerIndex: integer);
begin
  RegisterGasCanCoordinate(Width);

  FNextYDecors := FNextYDecors - texGroundDeep^.FrameHeight;
  inherited create(FNextXDecors, FNextYDecors, aLayerindex);
  // create flipped sprite to construct the ceiling part
  with TGroundSlope.Create(FNextXDecors, FNextYDecors-DeltaYFloorCeil, aLayerIndex) do begin
    FlipV := True;
    FlipH := True;
  end;
  CreateGroundDeep(FNextXDecors, FNextYDecors, aLayerIndex, True);
  FNextXDecors := FNextXDecors + Width;
end;

{ TFloorFlat }

constructor TFloorFlat.Create(aLayerIndex: integer; aCreateCeilling: boolean);
begin
  inherited Create(FNextXDecors, FNextYDecors, aLayerindex);
  // create flipped sprite to construct the ceiling part
  if aCreateCeilling then
    with TGroundFlat.Create(FNextXDecors, FNextYDecors-DeltaYFloorCeil, aLayerIndex) do FlipV := True;

  RegisterGasCanCoordinate(Width);

  CreateGroundDeep(FNextXDecors, FNextYDecors, aLayerIndex, aCreateCeilling);
  FNextXDecors := FNextXDecors + Width;
end;

{ TGroundSlope }

constructor TGroundSlope.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(texGroundSlope, aX, aY, aLayerIndex);
end;

procedure TGroundSlope.Update(const aElapsedTime: single);
var p1, p2: TPointF;
    delta, percent: single;
begin
  inherited Update(aElapsedTime);

  if not FSpriteFloorCanCheckCollisionWithLR then exit;

  // maintain Dino above the floor with right angle
  if not FlipV and InRange(FDino.X.Value, X.Value, RightX) then begin
    percent := (FDino.X.Value-X.Value)/Width;
    if not FlipH then begin
      FDino.Angle.Value := -35;
      FDino.Y.Value := Y.Value - (Height*percent + FDino.DeltaYToBottom)*0.5;
    end else begin
      FDino.Angle.Value := 35;
      FDino.Y.Value := Y.Value + (Height*percent - FDino.DeltaYToBottom)*0.5;
    end;
  end;

  // if the sprite is too far from LR, we kill it
  if Min(FLR.X.Value, FDino.X.Value)-X.Value > FScene.Width*2 then Kill
  else begin
    // check collision with LR
    if FlipV and FlipH then begin  // ceil up
      p1 := PointF(X.Value, BottomY);
      p2 := PointF(RightX, Y.Value+Height*0.5);
      delta := Height*0.25;
    end else if FlipV then begin  // ceil down
      p1 := PointF(X.Value, Y.Value+Height*0.5);
      p2 := PointF(RightX, BottomY);
      delta := Height*0.25;
    end else if FlipH then begin // floor down
      p1 := GetXY;
      p2 := PointF(RightX, Y.Value+Height*0.5);
      delta := -Height*0.25;
    end else begin
      p1 := PointF(X.Value, Y.Value+Height*0.5);
      p2 := PointF(RightX, Y.Value);
      delta := -Height*0.25;
    end;
    if FLR.CheckCollisionWithLine(p1, p2) then begin
      FLR.Y.Value := FLR.Y.Value + delta;
      delta := FLR.Speed.x.Value;
      delta := delta - FScene.Width*0.25; //ScaleW(50);
      if delta < 0 then delta := 0;
      FLR.Speed.x.Value := delta;
      FLR.Speed.Y.Value := 0.0;
    end;
  end;
end;

{ TGroundDeep1 }

constructor TGroundDeep.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(texGroundDeep, aX, aY, aLayerIndex);
end;

procedure TGroundDeep.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  // if the sprite is too far from LR, we kill it
  if FSpriteFloorCanCheckCollisionWithLR and (Min(FLR.X.Value, FDino.X.Value)-X.Value > FScene.Width*2) then Kill;
end;

{ TGroundBase }

procedure TGroundBase.CreateGroundDeep(aX, aY: single; aLayerIndex: integer; aCreateCeilling: boolean);
var i: integer;
    yy: single;
begin
  for i:=0 to 8 do begin
    yy := aY + Height + texGroundDeep^.FrameHeight*i;
    TGroundDeep.Create(aX, yy, aLayerIndex);
    // flipped V for ceilling
    if aCreateCeilling then begin
      yy := aY - texGroundDeep^.FrameHeight*(i+1) - DeltaYFloorCeil;
      with TGroundDeep.Create(aX, yy, aLayerIndex) do FlipV := True;
    end;
  end;
end;

constructor TGroundBase.Create(aTexture: PTexture; aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(aTexture, False);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
end;

{ TGroundFlat }

constructor TGroundFlat.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(texGroundFlat, aX, aY, aLayerIndex);
end;

procedure TGroundFlat.Update(const aElapsedTime: single);
var p1, p2: TPointF;
    delta: single;
begin
  inherited Update(aElapsedTime);

  if not FSpriteFloorCanCheckCollisionWithLR then exit;

  // maintain Dino above the floor with right angle
  if InRange(FDino.X.Value, X.Value, RightX) then begin
    if FDino.Angle.Value <> 0 then FDino.Angle.Value := FDino.Angle.Value*0.5;
    FDino.Y.Value := Y.Value {- Height*0.8} - FDino.DeltaYToBottom;
  end;

  // if the sprite is too far from LR backward, we kill it
  if Min(FLR.X.Value, FDino.X.Value)-X.Value > FScene.Width*2 then Kill
  else begin
    // check collision with LR
    if FlipV then begin
      p1 := PointF(X.Value, BottomY);
      p2 := PointF(RightX, BottomY);
      delta := Height*0.5;
    end else begin
      p1 := GetXY;
      p2 := PointF(RightX, Y.Value);
      delta := -Height*0.5;
    end;
    if FLR.CheckCollisionWithLine(p1, p2) then begin
      FLR.Y.Value := FLR.Y.Value + delta; // shift LR position
      delta := FLR.Speed.x.Value;
      delta := delta - FScene.Width*0.25; //ScaleW(50);
      if delta < 0 then delta := 0;
      FLR.Speed.x.Value := delta;
      FLR.Speed.Y.Value := 0.0;
    end;
  end;
end;

{ TCage }

function TCage.CreateBar(aTexture: PTexture; aX: single; aZOrder: integer): TSprite;
begin
  Result := TSprite.Create(aTexture, False);
  FCeiling.AddChild(Result, aZOrder);
  Result.X.Value := aX;
  Result.Y.Value := FCeiling.Height-PPIScale(1);
end;

function TCage.CreateBarChildOfFloor(aTexture: PTexture; aX: single; aZOrder: integer): TSprite;
begin
  Result := TSprite.Create(aTexture, False);
  AddChild(Result, aZOrder);
  Result.X.Value := aX;
  Result.Y.Value := FCeiling.BottomY - PPIScale(1);
end;

procedure TCage.CreateParticleEmitterOnBar(aBar: TSprite);
var o: TParticleEmitter;
begin
  o := TParticleEmitter.Create(FScene);
  AddChild(o, aBar.ZOrderAsChild);
  o.LoadFromFile(ParticleFolder+'DinoCageUnlockBar.par', Self.FAtlas);
  o.X.Value := aBar.CenterX;
  o.Y.Value := aBar.BottomY;
  o.Shoot;
  o.KillDefered(3.0);
end;

class procedure TCage.LoadTexture(aAtlas: TOGLCTextureAtlas);
var path: string;
begin
  Self.FAtlas := aAtlas;
  path := SpriteGameVolcanoDinoFolder;
  texBarBack := aAtlas.AddFromSVG(path+'CageBackwardBar.svg', -1, ScaleH(457));
  texBarMiddle := aAtlas.AddFromSVG(path+'CageMiddleBar.svg', -1, ScaleH(473));
  texBarForward := aAtlas.AddFromSVG(path+'CageForwardBar.svg', -1, ScaleH(488));
  texground := aAtlas.AddFromSVG(path+'CageGround.svg', ScaleW(593), -1);
  texCeiling := aAtlas.AddFromSVG(path+'CageCeiling.svg', ScaleW(593), -1);
  texChain := aAtlas.AddFromSVG(path+'CageChain.svg', -1, ScaleH(159));
end;

constructor TCage.Create(aX: single; aLayerindex: integer);
var o, o1: TSprite;
    yPivot: single;
begin
  inherited Create(texground, False);
  FScene.Add(Self, aLayerindex);
  X.Value := aX;
  yPivot := (texBarBack^.FrameHeight + texCeiling^.FrameHeight + texChain^.FrameHeight*2)/texGround^.FrameHeight;
  Pivot := PointF(0.5, -yPivot);

  FsndPneumatic := Audio.AddSound('pneumatic-grease-bomb.ogg', 0.75, False);
  FsndPneumatic.Pan.Value := -0.4;

  FCeiling := TSprite.Create(texCeiling, False);
  AddChild(FCeiling, 4);
  FCeiling.SetCoordinate(0, -texBarForward^.FrameHeight*0.92-FCeiling.Height);

  o := TSprite.Create(texChain, False);
  FCeiling.AddChild(o, 0);
  o.CenterX := FCeiling.Width*0.5;
  o.BottomY := FCeiling.Height*0.15;
  o1 := TSprite.Create(texChain, False);
  o.AddChild(o1, 0);
  o1.CenterX := o.Width*0.5;
  o1.BottomY := FCeiling.Height*0.15;

  FBGBar1 := CreateBarChildOfFloor(texBarBack, Width*0.14, 0); //bg left
  FBGBar2 := CreateBarChildOfFloor(texBarBack, Width*0.315, 0);
  FBGBar3 := CreateBarChildOfFloor(texBarBack, Width*0.595, 0);
  FBGBar4 := CreateBarChildOfFloor(texBarBack, Width*0.83, 0);

  FMidBarL := CreateBarChildOfFloor(texBarMiddle, Width*0.09, 2); // middle left
  FMidBarR := CreateBarChildOfFloor(texBarMiddle, Width*0.88, 2);

  FBar1 := CreateBarChildOfFloor(texBarForward, Width*0.05, 3); // forward left
  FBar2 := CreateBarChildOfFloor(texBarForward, Width*0.26, 3);
  FBar3 := CreateBarChildOfFloor(texBarForward, Width*0.483, 3);
  FBar4 := CreateBarChildOfFloor(texBarForward, Width*0.66, 3);
  FBar5 := CreateBarChildOfFloor(texBarForward, Width*0.93, 3);

  FCanSwing := True;
  PostMessage(0);
end;

destructor TCage.Destroy;
begin
  if FsndPneumatic <> NIL then FsndPneumatic.Kill;
  FsndPneumatic := NIL;
  inherited Destroy;
end;

procedure TCage.ProcessMessage(UserValue: TUserMessageValue);
const deltaYBar = 20; durationMoveBar = 0.4; d=0.4;
var dur, dd: single;
begin
  case UserValue of
    // Anim cage balancing
    0: begin
      if not FCanSwing then exit;
      Angle.ChangeTo(1, 2.0, idcSinusoid);
      PostMessage(1, 2.0);
    end;
    1: begin
      if not FCanSwing then exit;
      Angle.ChangeTo(-1, 2.0, idcSinusoid);
      PostMessage(0, 2.0);
    end;

    // Anim Open cage
    100: begin
      CreateParticleEmitterOnBar(FBGBar2);
      FsndPneumatic.Play(True);
      PostMessage(101, d);
    end;
    101: begin
      FBGBar2.MoveYRelative(-ScaleH(deltaYBar), durationMoveBar);
      PostMessage(102, d);
    end;
    102: begin
      CreateParticleEmitterOnBar(FBGBar1);
      FsndPneumatic.Play(True);
      PostMessage(103, d);
    end;
    103: begin
      FBGBar1.MoveYRelative(-ScaleH(deltaYBar), durationMoveBar);
      PostMessage(106, d);
    end;
    106: begin
      CreateParticleEmitterOnBar(FMidBarL);
      FsndPneumatic.Play(True);
      PostMessage(107, d);
    end;
    107: begin
      FMidBarL.MoveYRelative(-ScaleH(deltaYBar), durationMoveBar);
      PostMessage(108, d);
    end;
    108: begin
      CreateParticleEmitterOnBar(FBar1);
      FsndPneumatic.Play(True);
      PostMessage(109, d);
    end;
    109: begin
      FBar1.MoveYRelative(-ScaleH(deltaYBar), durationMoveBar);
      PostMessage(110, d);
    end;
    110: begin
      CreateParticleEmitterOnBar(FBar2);
      FsndPneumatic.Play(True);
      PostMessage(111, d);
    end;
    111: begin
      FBar2.MoveYRelative(-ScaleH(deltaYBar), durationMoveBar);
      PostMessage(112, d);
    end;
    112: begin
      CreateParticleEmitterOnBar(FBar3);
      FsndPneumatic.Play(True);
      PostMessage(113, d);
    end;
    113: begin
      FBar3.MoveYRelative(-ScaleH(deltaYBar), durationMoveBar);
      PostMessage(114, d);
    end;
    114: begin
      CreateParticleEmitterOnBar(FBar4);
      FsndPneumatic.Play(True);
      PostMessage(115, d);
    end;
    115: begin
      FBar4.MoveYRelative(-ScaleH(deltaYBar), durationMoveBar);
      PostMessage(116, d);
    end;
    116: begin
      CreateParticleEmitterOnBar(FBar5);
      FsndPneumatic.Play(True);
      PostMessage(117, d);
    end;
    117: begin
      FBar5.MoveYRelative(-ScaleH(deltaYBar), durationMoveBar);
      PostMessage(118, d);
    end;
    118: begin
      CreateParticleEmitterOnBar(FMidBarR);
      FsndPneumatic.Play(True);
      PostMessage(119, d);
    end;
    119: begin
      FMidBarR.MoveYRelative(-ScaleH(deltaYBar), durationMoveBar);
      PostMessage(120, d);
    end;
    120: begin
      CreateParticleEmitterOnBar(FBGBar4);
      FsndPneumatic.Play(True);
      PostMessage(121, d);
    end;
    121: begin
      FBGBar4.MoveYRelative(-ScaleH(deltaYBar), durationMoveBar);
      PostMessage(122, d);
    end;
    122: begin
      CreateParticleEmitterOnBar(FBGBar3);
      FsndPneumatic.Play(True);
      PostMessage(123, d);
    end;
    123: begin
      FBGBar3.MoveYRelative(-ScaleH(deltaYBar), durationMoveBar);
      PostMessage(124, d);
    end;
    124: begin   // cage go up
      FsndDoorMotor.Pitch.Value := 0.5;
      FsndDoorMotor.Pitch.ChangeTo(1.0, 0.2);
      FsndDoorMotor.Play;
      dur := 4.0;
      dd := -FBar1.Height*1.5;
      FCeiling.MoveYRelative(dd, dur, idcSinusoid);
      FBGBar1.MoveYRelative(dd, dur, idcSinusoid);
      FBGBar2.MoveYRelative(dd, dur, idcSinusoid);
      FBGBar3.MoveYRelative(dd, dur, idcSinusoid);
      FBGBar4.MoveYRelative(dd, dur, idcSinusoid);
      FMidBarL.MoveYRelative(dd, dur, idcSinusoid);
      FMidBarR.MoveYRelative(dd, dur, idcSinusoid);
      FBar1.MoveYRelative(dd, dur, idcSinusoid);
      FBar2.MoveYRelative(dd, dur, idcSinusoid);
      FBar3.MoveYRelative(dd, dur, idcSinusoid);
      FBar4.MoveYRelative(dd, dur, idcSinusoid);
      FBar5.MoveYRelative(dd, dur, idcSinusoid);

      FCeiling.KillDefered(dur);
      FBGBar1.KillDefered(dur);
      FBGBar2.KillDefered(dur);
      FBGBar3.KillDefered(dur);
      FBGBar4.KillDefered(dur);
      FMidBarL.KillDefered(dur);
      FMidBarR.KillDefered(dur);
      FBar1.KillDefered(dur);
      FBar2.KillDefered(dur);
      FBar3.KillDefered(dur);
      FBar4.KillDefered(dur);
      FBar5.KillDefered(dur);
      PostMessage(126, dur);
    end;
    126: begin   // end of anim open cage
      FsndDoorMotor.Stop;
      ScreenGameVolcanoDino.PostMessage(FMessValueToSendWhenCageIsOpened);
    end;
  end;
  end;

procedure TCage.SetDinoInTheCage;
begin
  FDino.MoveFromSceneToChildOf(Self, 1);
  FDino.Y.Value := BottomY-Height*0.3-FDino.DeltaYToBottom;
  FDino.X.Value := Width*0.5;
end;

procedure TCage.SetBottomY(aBottomY: single);
begin
  Y.Value := aBottomY - Height;
end;

procedure TCage.MoveCageToBottom(aDuration: single; aCurve: integer);
begin
  FCanSwing := False;
  Y.ChangeTo(YStepOnFloor-Height*0.5, aDuration, aCurve);
  Angle.ChangeTo(0, aDuration, idcSinusoid);
end;

procedure TCage.OpenCage(aMessageValue: TUserMessageValue);
begin
  FMessValueToSendWhenCageIsOpened := aMessageValue;
  PostMessage(100);
end;

procedure TCage.KillBarsAndCeil;
begin
  DeleteAllChilds;
end;

{ TComputer }

function TComputer.GetLavaDropTargetPosition: TPointF;
begin
  Result.x := X.Value + Width*0.55;
  Result.y := Y.Value + Height*0.05;
end;

{ TDustForArmoredDoor }

constructor TDustForArmoredDoor.Create;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_FXANIM);
  SetCoordinate(ScaleW(2832), ScaleH(642));
end;

{ TLavaOnComputer }

constructor TLavaOnComputer.Create(FAtlas: TOGLCTextureAtlas);
var pe: TSmokePoint;
begin
  inherited Create(texLavaOnComputer, False);
  FScene.Add(Self, LAYER_FXANIM);
  CenterX := FUsableComputer.GetLavaDropTargetPosition.x;
  Y.Value := FUsableComputer.GetLavaDropTargetPosition.y;

  pe := TSmokePoint.Create(Width*0.5, Height*0.4, -1, FAtlas);
  AddChild(pe, 0);
  pe.Opacity.Value := 100;
end;

{ TFallingLavaDropOnComputer }

constructor TFallingLavaDropOnComputer.Create(aCenterX: single; aLayerindex: integer);
begin
  inherited Create(texLavaBall, False);
  FScene.Add(Self, aLayerindex);
  CenterX := aCenterX;
  Y.Value := -texLavaBall^.FrameHeight;
  PostMessage(0);
end;

procedure TFallingLavaDropOnComputer.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // drop start to appear slowly
    0: begin
      Y.ChangeTo(FUsableComputer.GetLavaDropTargetPosition.y, 2.0);
      PostMessage(4, 2.0);
    end;
    4: begin
      ScreenGameVolcanoDino.PostMessage(200);
      Opacity.ChangeTo(0, 1.0, idcSinusoid);
      KillDefered(1.0);
    end;
  end;
end;

{ TArmoredDoor }

constructor TArmoredDoor.Create(aX, aY: single; aLayerindex: integer);
begin
  inherited Create(texArmoredDoor, False);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
  Pivot := PointF(0.3, 0.86);
end;

{ TStaticPillar }

constructor TStaticPillar.Create(aX: single);
begin
  inherited Create(texPillar1, False);
  FScene.Add(Self, LAYER_BG2);
  SetCoordinate(aX, texCeiling^.FrameHeight*0.8);
end;

{ TStaticCeiling }

constructor TStaticCeiling.Create(aX: single);
begin
  inherited Create(texCeiling, False);
  FScene.Add(Self, LAYER_BG1);
  X.Value := aX;
  Y.Value := 0;
end;

{ TScreenGameVolcanoDino }

procedure TScreenGameVolcanoDino.CreateGround;
var i: integer;
begin
  for i:=1 to 13 do
    TFloorFlat.Create(LAYER_GROUND, True);

  TStaticPillar.Create(FNextXDecors-texPillar1^.FrameWidth);

  TFloorFlatWithCeilSlopeUp.Create(LAYER_GROUND, 0.5);
  TFloorFlatWithCeilSlopeUp.Create(LAYER_GROUND, 1.0);

  for i:=1 to 4 do
    TFloorFlat.Create(LAYER_GROUND, False);

  TFloorFlatWithCeilSlopeDown.Create(LAYER_GROUND, 1.0);
  TFloorFlatWithCeilSlopeDown.Create(LAYER_GROUND, 0.5);

  TStaticPillar.Create(FNextXDecors);
  for i:=1 to 11 do
    TFloorFlat.Create(LAYER_GROUND, True);

  FXDecorsToSubstract := FNextXDecors;
end;

procedure TScreenGameVolcanoDino.CreateLevel;
var o: TSprite;
begin
  FNextXDecors := 0;
  FNextYDecors := FScene.Height - texGroundFlat^.FrameHeight*2;

  //CreateBGWall;
  CreateGround;

//  TStaticPillar.Create(ScaleW(1450));


  // debris and fire
  o := TStaticCeiling.Create(-ScaleW(22));
  //FScene.Add(o, LAYER_GROUND);
  o.FlipV := True;
  o.CenterX := ScaleW(82);
  o.CenterY := ScaleH(582);
  o.Angle.Value := 15;

  o := TSprite.Create(texLadder, False);
  FScene.Add(o, LAYER_GROUND);
  //o.Pivot := PointF(0, 1);
  o.Angle.Value := 75;
  o.FlipV := True;
  o.CenterX := ScaleW(89);
  o.CenterY := ScaleH(606);

  o := TSprite.Create(texLadder, False);
  FScene.Add(o, LAYER_GROUND);
  o.Angle.Value := -65;
  o.CenterX := ScaleW(171);
  o.CenterY := ScaleH(569);

  with TBigFire.Create(ScaleW(117), ScaleH(595), LAYER_FXANIM, FAtlas) do
   Update(0.5);

  FUsableComputer := TComputer.Create(ScaleW(2634), YStepOnFloor+FLR.DeltaYToBottom*0.7, LAYER_GROUND, FFontText, FLR);

  FArmoredDoor := TArmoredDoor.Create(ScaleW(2828), ScaleH(48), LAYER_GROUND);
  FDustForArmoredDoor := TDustForArmoredDoor.Create;

  FViewArea.Left := FScene.Width*0.5;
  FViewArea.Top := FScene.Height*0.5;
  FViewArea.Right := MaxInt;
  FViewArea.Bottom := ScaleH(768) - FScene.Height*0.5;
end;

procedure TScreenGameVolcanoDino.ProcessLayerComputerBeforeUpdateEvent;
begin
  FLR.LadderInUse := NIL;
  FLR.ObjectToHandle := NIL;
  FLR.DistanceToObjectToHandle := MaxSingle;
end;

procedure TScreenGameVolcanoDino.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then Exit;
  FGameState := AValue;
  case AValue of
    gsLRWin: PostMessage(500);
    gsLRLost: PostMessage(550);
    gsOutOfGas: PostMessage(530);
  end;
end;

procedure TScreenGameVolcanoDino.CreateEndRaceMessage(const aMess: string;
  aAppearTime, aStayTime: single);
var fd: TFontDescriptor;
    o: TSprite;
begin
  fd.Create('Arial', Round(FScene.Height*0.2), [], BGRA(255,255,180), BGRA(30,30,30), PPIScale(5));
  o := TSprite.Create(FScene, fd, aMess);
  FScene.Add(o, LAYER_DIALOG);
  with o do begin
    Scale.Value := PointF(0.1, 0.1);
    Scale.ChangeTo(PointF(1.0, 1.0), aAppearTime, idcStartSlowEndFast);
    Opacity.Value :=0;
    Opacity.ChangeTo(255, aAppearTime);
    SetCenterCoordinate(GetCameraCenterView);
    KillDefered(aStayTime);
  end;
end;

procedure TScreenGameVolcanoDino.CreateObjects;
var path: string;
  ima: TBGRABitmap;
begin
  FGameState := gsUndefined;
  Audio.PauseMusicTitleMap(3.0);
  FsndFunnyMusic := Audio.AddMusic('Malloga_Ballinga_Mastered.ogg', True);
  FsndFunnyMusic.Play(True);
  FsndRaceMusic := Audio.AddMusic('PromenonsNousDansLesBois.ogg', True);
FsndRaceMusic.Volume.Value := 0.8;
  FsndEarthQuakeLoop := Audio.AddSound('Earthquake1_2654Loop.ogg', 1.0, True);
  FsndEarthQuakeLoop.AppLyEffect(Audio.FXReverbShort);
  FsndEarthQuakeLoop.SetEffectDryWetVolume(Audio.FXReverbShort, 0.5);

  FSndRockPileExplode := Audio.AddSound('dropping-rocks.ogg', 0.7, False);
  FSndRockPileExplode.PositionRelativeToListener := False;
  FSndRockPileExplode.DistanceModel := AL_INVERSE_DISTANCE_CLAMPED;
  FSndRockPileExplode.Attenuation3D(FScene.Width*0.8, FScene.Width*2, 3.0, 1.0);

  FsndEmotionMusic := NIL;

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 1;

  AdditionnalScale := 0.8;

  LoadLR4DirTextures(FAtlas, True);
  LoadWolfTextures(FAtlas);
  //FAtlas.Add(ParticleFolder+'sphere_particle.png');

  AdditionnalScale := 1.0;
  path := SpriteGameVolcanoDinoFolder;
  texLadder := FAtlas.AddFromSVG(SpriteGameVolcanoInnerFolder+'Ladder.svg', -1, ScaleH(230));
  texPillar1 := FAtlas.AddFromSVG(path+'Pillar1.svg', -1, ScaleH(615));

  texCeiling := FAtlas.AddFromSVG(path+'Ceiling.svg', ScaleH(310), -1);

  texGroundFlat := FAtlas.AddFromSVG(path+'GroundFlat.svg', ScaleW(128), -1);
  texGroundDeep := FAtlas.AddFromSVG(path+'GroundDeep.svg', ScaleW(128), -1);
  texGroundSlope := FAtlas.AddFromSVG(path+'GroundSlope.svg', ScaleW(128), -1);
  texRockMedium := FAtlas.AddFromSVG(SpriteGameVolcanoInnerFolder+'RockMedium.svg', ScaleW(82), -1);
  texGasCan := FAtlas.AddFromSVG(path+'GasCan.svg', ScaleW(58), -1);
  TGasJauge.LoadTexture(FAtlas);
  TProgressLine.LoadTexture(FAtlas);
  texDinoIcon := FAtlas.AddFromSVG(path+'DinoIcon.svg', -1, ScaleH(32));
  texFlagFinish := FAtlas.AddFromSVG(SpriteUIFolder+'FlagFinish.svg', -1, ScaleH(32));
  texPanelExit := FAtlas.AddFromSVG(SpriteGameVolcanoInnerFolder+'PanelExit.svg', -1, ScaleH(76));

  AddCloud128x128ParticleToAtlas(FAtlas);
  AddSphereParticleToAtlas(FAtlas);
  AddDustParticleToAtlas(FAtlas);

  TPanelUsingComputer.LoadTextures(FAtlas);
  TUsableComputer.LoadTexture(FAtlas);

  AdditionnalScale := 1.5;
  TDino.LoadTexture(FAtlas);
  AdditionnalScale := 1.0;
  TCage.LoadTexture(FAtlas);

  texArmoredDoor := FAtlas.AddFromSVG(path+'ArmoredDoor.svg', -1, ScaleH(714));
  texLavaBall := FAtlas.AddFromSVG(SpriteGameVolcanoInnerFolder+'LavaBall.svg', ScaleW(20), -1);
  texLavaOnComputer := FAtlas.AddFromSVG(path+'LavaOnComputer.svg', ScaleW(23), -1);

  CreateGameFontNumber(FAtlas);
  LoadCoinTexture(FAtlas);
  LoadWatchTexture(FAtlas);
  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);
  LoadGameDialogTextures(FAtlas);

  // load arrow for button panels
  AddBlueArrowToAtlas(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;
  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  // LR 4 direction
  FLR := TLR4Direction.Create;
  FLR.SetCoordinate(ScaleW(394), YStepOnFloor);
  FLR.SetWindSpeed(0.5);
  FLR.SetFaceType(lrfSmile);
  FLR.IdleRight;
  FLR.TimeMultiplicator := 0.7;

  // cameras
  FCamera := FScene.CreateCamera;
  FCamera.AssignToLayer([LAYER_DIALOG, LAYER_WEATHER, LAYER_ARROW, LAYER_PLAYER,
   LAYER_WOLF, LAYER_FXANIM, LAYER_GROUND, LAYER_BG1, LAYER_BG2]);
  FCameraFollowLR := True;

  CreateLevel;

  FDino := TDino.Create(ScaleW(700), ScaleH(337), LAYER_GROUND);
  FDino.FlipH := True;
  FDino.Y.Value := YStepOnFloor-FDino.DeltaYToBottom;
  FDino.State := dsIdle;

  FCage := TCage.Create(ScaleW(1892), LAYER_GROUND);
  FCage.SetDinoInTheCage;
  FCage.SetBottomY(ScaleH(95));

  FGasJauge := NIL;

  // using computer panel
  FPanelComputer := TPanelUsingComputer.Create(FFontText);

  // callback for layer where is the computer
  FScene.Layer[LAYER_GROUND].OnBeforeUpdate := @ProcessLayerComputerBeforeUpdateEvent;

  // pause panel
  FInGamePausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  FCameraStayVerticallyCenteredOnScene := True;
  FSpriteFloorCanCheckCollisionWithLR := False;
  FIndexLevelData := 0;
  FDinoMaxSpeed := FScene.Width*0.8;
  FLRMaxSpeed := FDinoMaxSpeed*1.1;

  // background color
  FScene.BackgroundColor := BGRA(68,49,63);

  // don't play anim open cage and door
  if PlayerInfo.Volcano.AnimDinoOpenCageAndDoorAlreadySeen then
    PostMessage(300)  // ask if player want see that anim again
  else begin
    ShowGameInstructions(PlayerInfo.Volcano.HelpText); // show how to play
    FGameState := gsRunningOnGround;
  end;
end;

procedure TScreenGameVolcanoDino.FreeObjects;
begin
  Audio.ResumeMusicTitleMap;
  if FsndDoorMotor <> NIL then FsndDoorMotor.FadeOutThenKill(1.0);
  FsndDoorMotor := NIL;
  if FsndDoorBeep <> NIL then FsndDoorBeep.FadeoutThenKill(1.0);
  FsndDoorBeep := NIL;
  if FsndEarthQuakeLoop <> NIL then FsndEarthQuakeLoop.FadeOutThenKill(1.0);
  FsndEarthQuakeLoop := NIL;
  if FsndFunnyMusic <> NIL then FsndFunnyMusic.FadeOutThenKill(1.0);
  FsndFunnyMusic := NIL;
  if FsndRaceMusic <> NIL then FsndRaceMusic.FadeOutThenKill(1.0);
  FsndRaceMusic := NIL;
  if FSndRockPileExplode <> NIL then FSndRockPileExplode.Kill;
  FSndRockPileExplode := NIL;
  if FsndEmotionMusic <> NIL then FsndEmotionMusic.FadeOutThenKill(1.0);
  FsndEmotionMusic := NIL;

  FScene.KillCamera(FCamera);
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
end;

procedure TScreenGameVolcanoDino.ProcessMessage(UserValue: TUserMessageValue);
var
  r: TRectF;
begin
  case UserValue of
    // before LR use the computer
    90: FLR.ShowDialog(sThisComputerHaveSDCardReader, FFontText, Self, 91, 0, FCamera);
    91: begin
      FLR.IdleUp;
      PostMessage(92, 0.5);
    end;
    92: FPanelComputer.StartAnimSDCardVolcano;

    // ANIM open door
    100: begin  // LR goes to the left of the computer
       FUsableComputer.SetText(sOpenArmouredDoor);
       FLR.WalkHorizontallyTo(FUsableComputer.X.Value, Self, 101);
    end;
    101: begin // LR idle to the right
       FsndFunnyMusic.Volume.ChangeTo(0.6, 2.0);
       FLR.IdleRight;
       PostMessage(102, 0.5);
    end;
    102: begin // start beep +
       FsndDoorBeep := Audio.AddSound('train-door-beep-a.ogg', 0.8, True);
       FsndDoorBeep.ApplyEffect(Audio.FXReverbShort);
       FsndDoorBeep.SetEffectDryWetVolume(Audio.FXReverbShort, 0.65);
       FsndDoorBeep.Play(True);
       PostMessage(103, 3.0);
    end;
    103: begin // door starts to move slowly
       FArmoredDoor.MoveYRelative(-ScaleH(120), 10.0, idcLinear);
       FsndDoorMotor := Audio.AddSound('ElectricalMotorLoop.ogg', 0.8, True);
       FsndDoorMotor.Pitch.Value := 0.25;
       FsndDoorMotor.Play(True);
       PostMessage(120, 2.0);
    end;
    120: begin  // drop of lava fall
       TFallingLavaDropOnComputer.Create(FUsableComputer.GetLavaDropTargetPosition.x, LAYER_FXANIM);
    end;

    // called when the lava drop touch the computer
    200: begin
      FsndDoorMotor.Stop;
      FsndDoorBeep.Stop;
      FUsableComputer.StartScreenFlashRed;
      FUsableComputer.SetText(sFail);
      Audio.PlayThenKillSound('fire3alternate.ogg', 0.6);
      FArmoredDoor.Y.Value := FArmoredDoor.Y.Value;
      TLavaOnComputer.Create(FAtlas);
      FLR.SetFaceType(lrfWorry);
      PostMessage(205, 2.5);
    end;
    205: begin // door fall
      FArmoredDoor.Y.ChangeTo(ScaleH(48), 0.25, idcStartSlowEndFast);
      PostMessage(206, 0.25);
    end;
    206: begin // camera shake + sound
      FCamera.Shaker.Start(PPIScale(10), PPIScale(10), 0.03);
      Audio.PlayThenKillSound('CollisionPunchShort.ogg', 1.0, 0.0, 0.5, Audio.FXReverbShort, 0.5);
      FDustForArmoredDoor.Shoot;
      PostMessage(208, 1.0);
    end;
    208: begin // stop earthquake for falling door
      FCamera.Shaker.Stop;
      PostMessage(210, 0.75);
    end;
    210: with TInfoPanel.Create(sAIvoice, sFailToOpenDoorTryToOpenCage, FFontText, Self, 218) do
            SetCenterCoordinate(PointF(FUsableComputer.Center.x, GetCameraCenterView.y));

    218: begin  // camera shift to the left to see cage and LR
      FCameraFollowLR := False;
      FCamera.MoveTo(PointF(FLR.X.Value-FScene.Width*0.25, FScene.Height*0.5), 4.0, idcSinusoid);
      PostMessage(220, 3.0);
      PostMessage(219, 1.0);
    end;
    219: FLR.IdleLeft;
    220: begin // cage go down
      FUsableComputer.SetText(sOpenCage);
      FCage.MoveCageToBottom(6.0, idcLinear);
      FsndDoorMotor.Pitch.Value := 1.0;
      FsndDoorMotor.Play(True);
      PostMessage(222, 6.0);
    end;
    222: begin // earthquake
      FsndDoorMotor.Stop;
      FCamera.Shaker.Start(PPIScale(5), PPIScale(5), 0.03);
      FsndEarthQuakeLoop.FadeIn(1.0, 0.2);
      PostMessage(224, 1.0);
    end;
    224: begin // stop earthquake
      FsndEarthQuakeLoop.FadeOut(1.0);
      FCamera.Shaker.Stop;
      PostMessage(226, 1.0)
    end;
    226: FCage.OpenCage(228);  // open cage
    228: begin // dino is no more child of cage and turn to LR side
      FDino.MoveFromChildToScene(LAYER_WOLF);
      FDino.FlipH := False;
      PostMessage(230, 0.75);
    end;
    230: begin
      FDino.FHead.Angle.ChangeTo(28, 0.5, idcSinusoid);
      PostMessage(232, 0.75);
    end;
    232: begin
      FDino.FJaw.Angle.ChangeTo(17, 0.5, idcSinusoid);
      PostMessage(234, 0.75);
    end;
    234: begin
      Audio.PlayThenKillSound('DinoSurprise.ogg', 1.0, -0.3, 0.8, Audio.FXReverbShort, 0.5);
      FDino.FRightArm.Angle.ChangeTo(-59, 0.2, idcSinusoid);
      FDino.ShowDialog(SDinoWantHug, FFontText, Self, 236, 0, FCamera);
    end;
    236: FLR.ShowDialog(sJumpInMyArmGiveMeHug, FFontText, Self, 237, 0, FCamera);
    237: FDino.ShowDialog(sYesItsEasyIJumpInYourArms, FFontText, Self, 238, 0, FCamera);
    238: FLR.ShowDialog(sItsHugIsTooHeavyForMe, FFontText, Self, 240, 0, FCamera);
    240: begin  // LR put thruster
      FLR.UseDorsalThruster;
      PostMessage(242, 0.75);
    end;
    242: begin  // LR takes off
      FLR.TakeOffWithDorsalThruster(ScaleH(161), 2.0);
      PostMessage(244, 0.25);
    end;
    244: begin  // dino rush to the right
      FDino.State := dsRush;
      PostMessage(246);
    end;
    246: if FDino.CanMoveInRushPosition then PostMessage(248) else PostMessage(246);
    248: begin // dino go backward
      FDino.MoveXRelative(-FScene.Width*0.2, 1.0, idcSinusoid);
      PostMessage(250, 1.0);
    end;
    250: begin // dino rush to the door + camera shift to the left
      FLR.FlipH := False;
      FDino.X.ChangeTo(ScaleW(2846), 0.4, idcStartSlowEndFast);
      MoveCameraTo(PointF(FArmoredDoor.X.Value+FArmoredDoor.Height*0.15, FScene.Height*0.5), 0.4);
      PostMessage(251, 0.4);
    end;
    251: begin // dino stop rush + earthquake
      Audio.PlayThenKillSound('CollisionPunchShort.ogg', 1.0, 0.0, 1.0, Audio.FXReverbShort, 0.6);
      FsndEarthQuakeLoop.FadeIn(1.0, 0.0);
      FCamera.Shaker.Start(PPIScale(20), PPIScale(20), 0.03);
      PostMessage(252); // 1.5s
    end;
    252: begin // dino rebound
      FDino.X.ChangeTo(ScaleW(2642), 1.0, idcStartFastEndSlow);
      FDino.MoveYRelative(-FScene.Height*0.1, 0.5, idcStartFastEndSlow);
      PostMessage(253, 0.5);
    end;
    253: begin
      //FDino.Y.ChangeTo(ScaleH(707) - FDino.DeltaYToBottom, 0.5, idcStartSlowEndFast);
      FDino.MoveYRelative(FScene.Height*0.1, 0.5, idcStartSlowEndFast);
      PostMessage(254, 0.5);
    end;
    254: begin // dino idle + stop earthquake + door balancing
      FDino.State := dsIdle;
      FDino.ShowQuestionMark;
      Audio.PlayThenKillSound('DinoSurprise.ogg', 1.0);
      FsndEarthQuakeLoop.FadeOut(1.0);
      FCamera.Shaker.Stop;
      FArmoredDoor.Angle.ChangeTo(2, 0.5, idcSinusoid);
      PostMessage(256, 0.5);
    end;
    256: begin
      FArmoredDoor.Angle.ChangeTo(-3.5, 1.5, idcSinusoid);
      PostMessage(258, 1.5);
    end;
    258: begin // door fall
      FArmoredDoor.Angle.ChangeTo(90, 1.5, idcStartSlowEndFast);
      FDino.FHead.Angle.ChangeTo(30, 1.5, idcSinusoid);
      PostMessage(260, 1.5);
    end;
    260: begin // earthquake
      Audio.PlayThenKillSound('custom_short_explosion.ogg', 1.0, 0.3, 1.0, Audio.FXReverbShort, 0.5);
      FCamera.Shaker.Start(PPIScale(10), PPIScale(10), 0.03);
      PostMessage(262, 2.0);
    end;
    262: begin // stop earthquake
      FCamera.Shaker.Stop;
      FLR.MoveTo(FArmoredDoor.X.Value + FArmoredDoor.Height*0.6, FScene.Height*0.5, 1.0, idcSinusoid);
      FLRWaitInTheAir := False;
      PostMessage(263, 0.5);
    end;
    263: begin
      FLR.SetFaceType(lrfSmile);
      FLR.ShowDialog(sGreatNowICanPass, FFontText, Self, 264, 0, FCamera);
    end;
    264: begin
      FDino.HideMark;
      FDino.State := dsIdle;
      FDino.FHead.Angle.ChangeTo(-10, 1.0, idcSinusoid);
      FLR.FlipH := True;
      PostMessage(266, 0.5);
    end;
    266: begin
      with Audio.AddSound('DinoSurprise.ogg') do begin
        Pitch.Value := 1.4;
        PlayThenKill(True);
        Pitch.ChangeTo(1.2, 0.2);
      end;
      FDino.ShowDialog(sWantToRaceWithMe, FFontText, Self, 267, 0, FCamera);
    end;
    267: begin
      if not PlayerInfo.Volcano.AnimDinoOpenCageAndDoorAlreadySeen then begin
        // save player have seen the animation
        PlayerInfo.Volcano.AnimDinoOpenCageAndDoorAlreadySeen := True;
        FSaveGame.Save;
      end;
      if FsndFunnyMusic <> NIL then FsndFunnyMusic.FadeOutThenKill(1.0);
      FsndFunnyMusic := NIL;
      PostMessage(268);
      FGasJauge := TGasJauge.Create;
      FProgressLine := TProgress.Create;
      FProgressLine.DistanceToTravel := Length(LevelData)-TRAIL_DECORS_COUNT;
      ShowGameInstructions(sDinoRaceInstructions);
    end;
    268: begin // camera centered on LR
      FLR.FlipH := False;
      MoveCameraTo(FLR.GetXY, 2.0);
      ZoomCameraTo(PointF(0.8,0.8), 4.0);
      PostMessage(269, 2.0);
    end;
    269: begin
      ShowGetReadyGo(280, 0); // get ready
    end;
    280: begin
      FCameraFollowLR := True;
      FsndRaceMusic.Play(True);
      FDino.State := dsRush;
      FSpriteFloorCanCheckCollisionWithLR := True;
      FCameraStayVerticallyCenteredOnScene := False;
      FGameState := gsRacing;
      PostMessage(400);  // when dino is forward LR, it turn backward its head periodically
    end;

    // zapp the animation cage/door opened and prepare sprites to the race
    300: DialogQuestion(sWouldYouLikeToSeeDinoReleaseSceneAgain, sYes, sNo, FFontText,
                        Self, 301, 305, FAtlas);
    301: begin // yes
      ShowGameInstructions(PlayerInfo.Volcano.HelpText); // show how to play
      FGameState := gsRunningOnGround;
    end;
    305: begin  // no
      FGameState := gsIdle;
      FArmoredDoor.Angle.Value := 90;
      FDino.MoveFromChildToScene(LAYER_WOLF);
      FDino.SetCoordinate(FArmoredDoor.X.Value {- FDino.BodyWidth}, YStepOnFloor-FDino.DeltaYToBottom);
      FDino.State := dsIdle;
      FDino.FlipH := False;
      FLR.UseDorsalThruster;
      FLR.TakeOffWithDorsalThruster(FScene.Height*0.5, 0.0);
      FLR.X.Value := FArmoredDoor.X.Value + FArmoredDoor.Height*0.6;
      FLR.SetFaceType(lrfSmile);
      MoveCameraTo(PointF(FArmoredDoor.X.Value, FScene.Height*0.5), 0);
      FUsableComputer.StartScreenFlashRed;
      FUsableComputer.SetText(sOpenCage);
      FCage.MoveCageToBottom(0, idcLinear);
      FCage.KillBarsAndCeil;
      PostMessage(267);
    end;

    // when dino is forward LR, it turn backward its head periodically
    400: begin
      if FGameState <> gsRacing then exit;
      if FDino.X.Value-FDino.BodyWidth*0.3 > FLR.X.Value then begin
        FDino.TurnHeadBackward(1.0);
        if FDino.Tag1 = -1 then FDino.PlaySoundDinoOvertakeLR;
        FDino.Tag1 := 1;
      end else if FDino.X.Value+FDino.BodyWidth*0.3 < FLR.X.Value then begin
        if FDino.Tag1 = 1 then FDino.PlaySoundDinoOvertakenByLR;
        FDino.Tag1 := -1;
      end;
      PostMessage(400, 3.0+Random);
    end;

    // LR WIN the race
    500: begin
      FsndEmotionMusic := Audio.AddMusic('Emotion1Loop.ogg', True);
      FsndRaceMusic.FadeOutThenKill(1.0);
      FsndRaceMusic := NIL;
      Audio.PlayMusicSuccess1;
      CreateEndRaceMessage(sYouWin, 0.25, 6.0);
      FLR.Speed.Value := PointF(0, 0);
      FLR.StandByInTheAirWithDorsalThruster;
      r := FCamera.GetViewRect;
      if FScene.Collision.RectFRectF(FDino.GetBodyRect, r) then begin
        // dino is visible
        PostMessage(502);
        PostMessage(504, 6.0);
      end else begin
        // dino is not yet visible
        postMessage(501);
        PostMessage(504, 6.0);
      end;
    end;
    501: begin // dino is not visible -> we place it on the left of the screen
      FLR.FlipH := True;
      r := FCamera.GetViewRect;
      FDino.X.Value := r.Left-FDino.BodyWidth*1.5;
      PostMessage(502);
      //PostMessage(504, 2.0);
    end;
    502: begin // wait dino is near LR + stop dino
      if FDino.X.Value+FDino.BodyWidth < FLR.X.Value then PostMessage(502)
      else begin
        FDino.Speed.X.Value := 0;
        FDino.X.Value := FLR.X.Value-FDino.BodyWidth;
        FDino.State := dsIdle;
        FSpriteFloorCanCheckCollisionWithLR := False;
        FDino.Y.ChangeTo(FNextYDecors - FDino.DeltaYToBottom*0.8, 1.0, idcSinusoid);
        //PostMessage(504);
      end;
    end;
    504: begin  // LR land + camera zoom in
      FSpriteFloorCanCheckCollisionWithLR := False;
      FLR.FlipH := True;
      FLR.LandWithDorsalThruster(FNextYDecors+FLR.DeltaYToBottom, 3.0);
      ZoomCameraTo(PointF(1.0, 1.0), 6.0);
      MoveCameraTo(PointF(FLR.X.Value-FDino.BodyWidth*0.5, FNextYDecors-texGroundFlat^.FrameHeight*4), 6.0);  //3.5
      FCameraFollowLR := False;
      FDino.FHead.Angle.ChangeTo(45, 3.0, idcSinusoid);
      PostMessage(507, 3.0);
    end;
    507: begin
      with Audio.AddSound('DinoSurprise.ogg') do PlayThenKill(True);
      FsndEmotionMusic.FadeIn(0.8, 3.0);
      FDino.ShowDialog(sMyFriendYouWinTheRace, FFontText, Self, 509, 0, FCamera);
    end;
    509: begin // dino blend down
      FDino.BendDown(2.0);
      PostMessage(511, 2.0);
    end;
    511: begin // LR walk near dino head
      FLR.TimeMultiplicator := 1.0;
      FLR.WalkHorizontallyTo(FDino.X.Value+FDino.BodyWidth*0.8, Self, 512);
    end;
    512: begin  // LR start the hug
      FLR.SetIdlePosition;
      FLR.State := lr4sHugToDino;
      PostMessage(514, 1.0);
    end;
    514: begin // play sound happy
      Audio.PlayThenKillSound('DinoSurprise.ogg', 0.8);
      PostMessage(515, 3.0);
    end;
    515: begin // LR idle
      FLR.SetIdlePosition;
      PostMessage(516, 0.5);
    end;
    516: begin // Dino idle
      FDino.State := dsIdle;
      FDino.FHead.Angle.ChangeTo(35, 1.0, idcSinusoid);
      FLR.LRRight.Face.Angle.ChangeTo(-30, 1.0, idcSinusoid);
      PostMessage(518, 2.0);
    end;
    518: FDino.ShowDialog('Maintenant, on est copain pour la vie!', FFontText, Self, 520, 0, FCamera);
    520: FLR.ShowDialog('Merci Dino. Je suis contente de te connaître. J''espère qu''on se reverra.', FFontText, Self, 522, 0, FCamera);
    521: FDino.ShowDialog('Moi aussi! Tu peux venir me voir quand tu voudras.', FFontText, Self, 522, 0, FCamera);
    522: begin
      FLR.LRRight.Face.Angle.ChangeTo(0, 1.5, idcSinusoid);
      PostMessage(523, 0.5);
    end;
    523: begin
      FLR.IdleRight;
      FLR.WalkHorizontallyTo(FViewArea.Right, Self, 525, 2.0);
      FDino.FHead.Angle.ChangeTo(10, 3.0, idcSinusoid);
      FDino.State := dsArmGoodbye;
    end;
    525: begin
      PlayerInfo.Volcano.IncCurrentStep;
      PlayerInfo.Volcano.VolcanoDinoIsDone := True;
      PlayerInfo.Volcano.HaveGreenSDCard := False;
      FSaveGame.Save;
      FScene.RunScreen(ScreenMap);
    end;

    // OUT OF GAS
    530: begin
      FsndRaceMusic.FadeOutThenKill(1.0);
      FsndRaceMusic := NIL;
      Audio.PlayMusicLose1;
      CreateEndRaceMessage(sOutOfGas, 0.25, 2.5);
      FLR.Speed.Value := PointF(0, 0);
      FLR.DorsalThruster.StopThruster;
      FLR.SetFaceType(lrfNotHappy);
      FDino.State := dsIdle;
      FDino.Speed.X.Value := 0;
      postMessage(578, 3.25);
    end;

    // LR LOST the race
    550: begin
      FsndRaceMusic.FadeOutThenKill(1.0);
      FsndRaceMusic := NIL;
      Audio.PlayMusicLose1;
      CreateEndRaceMessage(sYouLose, 0.25, 2.5);
      FLR.Speed.Value := PointF(0, 0);
      FLR.StandByInTheAirWithDorsalThruster;
      FDino.State := dsIdle;
      FDino.Speed.X.Value := 0;
      FDino.FlipH := not FDino.FlipH;
      r := FCamera.GetViewRect;
      if FScene.Collision.RectFRectF(FDino.GetBodyRect, r) then begin
        // dino is visible
        PostMessage(566, 2.5);
        FSpriteFloorCanCheckCollisionWithLR := False;
        FDino.Y.ChangeTo(FNextYDecors - FDino.DeltaYToBottom*0.8, 1.0, idcSinusoid);
      end else begin
        // dino is not yet visible
        postMessage(551, 2.5);
      end;
    end;
    551: begin // lr is far from dino: scene becomes black
        FScene.ColorFadeIn(BGRABlack, 0.5);
        PostMessage(552, 0.5);
    end;
    552: begin // scene visible + put LR on the left of dino
      FScene.ColorFadeOut(0.5);
      FLR.X.Value := FDino.X.Value-FScene.Width;
      FLR.X.ChangeTo(FDino.X.Value-FDino.BodyWidth, 2.0, idcStartFastEndSlow);
      FLR.Y.Value := FDino.Y.Value - FDino.BodyHeight*0.6;
      FDino.Y.Value := FNextYDecors - FDino.DeltaYToBottom*0.8;
      FSpriteFloorCanCheckCollisionWithLR := False;
      {r := FCamera.GetViewRect;
      FDino.X.Value := r.Right+FDino.BodyWidth*1.5;
      FDino.Y.ChangeTo(FNextYDecors - FDino.DeltaYToBottom*0.8, 1.0, idcSinusoid); }
      PostMessage(566, 2.0);
    end;
    553: begin // LR fly near dino
      PostMessage(566, 2.0);
    end;
    566: begin // LR land near Dino + camera zoom in
      FSpriteFloorCanCheckCollisionWithLR := False;
      FLR.X.ChangeTo(FDino.X.Value-FDino.BodyWidth, 3.0, idcSinusoid);
      FLR.LandWithDorsalThruster(FNextYDecors+FLR.DeltaYToBottom, 3.0);
      ZoomCameraTo(PointF(1.0, 1.0), 6.0);
      MoveCameraTo(PointF(FDino.X.Value-FDino.BodyWidth*0.5, FNextYDecors-texGroundFlat^.FrameHeight*4), 6.0);
      FCameraFollowLR := False;
      FDino.FHead.Angle.ChangeTo(45, 3.0, idcSinusoid);
      PostMessage(568, 3.5);
    end;
    568: FDino.ShowDialog(sMyFriendIWinTheRace, FFontText, Self, 570, 0, FCamera);
    570: begin // dino jump above LR
      FLR.ShowQuestionMark;
      FDino.X.ChangeTo(FLR.X.Value-FLR.BodyHeight*0.5, 0.5);
      FDino.MoveYRelative(-FDino.BodyHeight*0.8, 0.5, idcStartFastEndSlow);
      PostMessage(571, 0.85);
    end;
    571: begin // Dino fall on LR
      FDino.Y.ChangeTo(FNextYDecors - FDino.DeltaYToBottom*0.0, 0.2, idcDrop);
      PostMessage(572, 0.1);
    end;
    572: begin // LR rotate
      FLR.Angle.Value := -90;
      FLR.SetFaceType(lrfNotHappy);
      FLR.HideMark;
      FScene.MoveSurfaceToLayer(FLR, LAYER_FXANIM);
      FDino.SetHugPosition(0.1);
      PostMessage(573, 0.1);
    end;
    573: begin // earthquake
      FCamera.Shaker.Start(PPIScale(10), PPIScale(10), 0.03, True);
      FCamera.Shaker.FadeOut(3.0);
      FsndEarthQuakeLoop.Volume.Value := 1.0;
      FsndEarthQuakeLoop.Play(True);
      PostMessage(575, 2.0);
    end;
    575: begin
      FsndEarthQuakeLoop.FadeOut(2.0);
      FDino.ShowDialog(sHug, FFontText, Self, 577, 0, FCamera);
    end;
    577: with TInfoPanel.Create(PlayerInfo.Name, sNoComment, FFontText, Self, 578, 0) do
            SetCoordinate(FLR.X.Value+FLR.BodyHeight*0.5, FLR.Y.Value-FLR.BodyWidth);
    578: DialogQuestion(sWouldYouLikeToTryAgain, sYes, sNo, FFontText, Self, 579, 580, FAtlas);
    579: FScene.RunScreen(ScreenGameVolcanoDino);
    580: FScene.RunScreen(ScreenMap);
  end;
end;

procedure TScreenGameVolcanoDino.Update(const aElapsedTime: single);
var flagPlayerIdle: boolean;
  p: TPointF;
  v, threshold, delta: single;
begin
  inherited Update(aElapsedTime);

  case FGameState of
    gsRunningOnGround: begin
      flagPlayerIdle := True;

      if Input.Action1Pressed and not FLR.IsOnLadder then begin
        FLR.State := lr4sJumping;
        flagPlayerIdle := False;
      end;

      if Input.LeftPressed and flagPlayerIdle then begin
        FLR.State := lr4sLeftWalking;
        flagPlayerIdle := False;
      end;

      if Input.RightPressed and flagPlayerIdle then begin
        FLR.State := lr4sRightWalking;
        flagPlayerIdle := False;
      end;

      if Input.UpPressed and flagPlayerIdle then begin
        flagPlayerIdle := False;
      end;

      if Input.DownPressed and flagPlayerIdle then begin
        flagPlayerIdle := False;
      end;

      if Input.Action2Pressed and flagPlayerIdle
         and (FLR.ObjectToHandle <> NIL)
         and not FLR.IsJumping then begin
        // here LR can interact with an object
        if FLR.ObjectToHandle is TUsableComputer then begin
          FGameState := gsComputerAnim;
          FUsableComputer.Enabled := False;
          PostMessage(90);
        end;
      end;

      if flagPlayerIdle then FLR.SetIdlePosition;

      // avoid LR to go to the left
      if FLR.X.Value < ScaleW(394) then FLR.X.Value := ScaleW(394);
      // avoid LR go through the armored door
      if FLR.X.Value > FArmoredDoor.X.Value then FLR.X.Value := FArmoredDoor.X.Value;
    end;// gsRunningOnGround

    gsComputerAnim: begin
      if FPanelComputer.AnimIsDone then begin
        FPanelComputer.Kill;
        FPanelComputer := NIL;
        FGameState := gsOpenDoorAnim;
        PostMessage(100);
      end;
    end;

    gsRacing: begin
      // increase Dino speed
      if FDino.CanMoveInRushPosition then begin
        v := FDino.Speed.x.Value;
        if v < FScene.Width*0.8 then begin
          v := v + FScene.Width*0.07;    // 0.1
          FDino.Speed.x.Value := Min(v + FScene.Width*0.1, FDinoMaxSpeed);
        end;
      end;

      // create decors
      if FNextXDecors <= {FLR.X.Value}Max(FLR.X.Value, FDino.X.Value) + FCamera.GetViewRect.Width then begin
        inc(FIndexLevelData);
        case LevelData[FIndexLevelData] of
          '-': TFloorFlat.Create(LAYER_GROUND);
          '/': TFloorSlopeUp.Create(LAYER_GROUND);
          '\': TFloorSlopeDown.Create(LAYER_GROUND);
          'o': TGazCan.Create(LAYER_FXANIM);
          'R': TPileOfRocks.Create(FNextXDecors, FNextYDecors+FLR.DeltaYToBottom);
          'X': TPanelExit.Create; // end of race
          'E': FViewArea.Right := FNextXDecors-FScene.Width*0.5; // end of view
        end;//case
        if FIndexLevelData = Length(LevelData) then
          FIndexLevelData := 0;
        //update icons on progress line
        FProgressLine.DistanceTraveledByLR := (FLR.X.Value-FXDecorsToSubstract)/texGroundFlat^.FrameWidth;
        FProgressLine.DistanceTraveledByDino := (FDino.X.Value-FXDecorsToSubstract)/texGroundFlat^.FrameWidth;
      end;

      flagPlayerIdle := True;
      delta := FScene.Width*0.5*aElapsedTime;
      if Input.Action1Pressed or Input.RightPressed then begin
        FLR.Speed.X.Value := EnsureRange(FLR.Speed.X.Value + delta, 0, FLRMaxSpeed);
        FGasJauge.Consume(0.1 * aElapsedTime);
        if FGasJauge.Percent > 0 then  FLR.SetPositionWhenSpeedUpWithDorsalThruster
          else GameState := gsOutOfGas;
        flagPlayerIdle := False;
      end;

      // decrease player horizontal speed
      if flagPlayerIdle then begin
        v := FLR.Speed.X.Value;
        if v > 0 then FLR.Speed.X.Value := Max(0, v - delta*0.25)
          else FLR.Speed.X.Value := Min(0, v + delta*0.25);
        FLR.SetPositionInertiaWithDorsalThruster;
      end;

      flagPlayerIdle := True;
      threshold := FScene.Height*0.5;
      delta := FScene.Height*2.0*aElapsedTime;
      if Input.UpPressed then begin
        v := FLR.Speed.Y.Value - delta;
        if v < -threshold then v := -threshold;
        FLR.Speed.Y.Value := v;
        flagPlayerIdle := False;
      end;

      if Input.DownPressed then begin
        v := FLR.Speed.Y.Value + delta;
        if v > threshold then v := threshold;
        FLR.Speed.Y.Value := v;
        flagPlayerIdle := False;
      end;

      // decrease player vertical speed
      if flagPlayerIdle then begin
        v := FLR.Speed.Y.Value;
        if v > 0 then FLR.Speed.y.Value := Max(0, v - delta*0.25)
          else FLR.Speed.y.Value := Min(0, v + delta*0.25)
      end;
    end;// gsRacing

  end;//case


  // check if player pause the game
  if Input.PausePressed then begin
    FInGamePausePanel.ShowModal;
  end;

  // camera follow LR in the bounds of FViewArea
  if FCameraFollowLR then begin
    p.x := EnsureRange(FLR.X.Value, FViewArea.Left, FViewArea.Right);
    if FCameraStayVerticallyCenteredOnScene then
      p.y := EnsureRange(FLR.Y.Value, FViewArea.Top, FViewArea.Bottom)
    else
      p.y := FLR.Y.Value;
    MoveCameraTo(p, 0.0);
    // audio listener position follow LR position
    Audio.SetListenerPosition(FLR.X.Value, FLR.Y.Value)
  end;

end;

procedure TScreenGameVolcanoDino.MoveCameraTo(const p: TPointF; aDuration: single);
var p1: TPointF;
begin
  p1 := PointF(p.Truncate);
  FCamera.MoveTo(p1, aDuration, idcSinusoid);
end;

procedure TScreenGameVolcanoDino.ZoomCameraTo(const z: TPointF; aDuration: single);
begin
  FCamera.Scale.ChangeTo(z, aDuration, idcSinusoid);
end;

function TScreenGameVolcanoDino.GetCameraCenterView: TPointF;
begin
  Result := FCamera.LookAt.Value*(-1);
  Result := Result + FScene.Center;
end;

procedure TScreenGameVolcanoDino.LRLostTheRace;
begin
  if FGameState = gsLRLost then exit;
  FGameState := gsLRLost;
  PostMessage(550);
  FDino.Speed.x.Value := 0.0;
  FDino.State := dsIdle;
end;

end.

