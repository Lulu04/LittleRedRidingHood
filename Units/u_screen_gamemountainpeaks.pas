unit u_screen_gamemountainpeaks;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_common_ui, u_sprite_lrcommon,
  u_ui_panels, u_audio;


const
  ZIP_LINE_VOLUME = 0.3;  // the volume of the zipline sound
  ZIP_LINE_BREAK_VOLUME = 0.5; // the volume of the break of the zipline

type

{ TScreenGameZipLine }

TScreenGameZipLine = class(TScreenTemplate)
private type TGameState=(gsUndefined=0, gsGetReady, gsRunning,
                         gsLRHurtAWall, gsWaitUntilAnimHurtAWallIsDone,
                         gsOutOfTime, gsWaitUntilAnimOutOfTimeIsDone,
                         gsCompleted, gsWaitForEndArrivalAnim,
                         gsCreatePanelAddScore, gsAddingScore);
  var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FMusic,
  FsndZipLine,
  FsndZipLineBreak: TALSSound;
  FVolcano, FLeftMountain, FRightMountain: TSprite;
  FLeftMountainCenter, FRightMountainCenter: TPointF;

  FFontDescriptor: TFontDescriptor;
  FGetReady: TSprite;

  FCameraForPerspectiveObjects: TOGLCCamera;

  FInGamePausePanel: TInGamePausePanel;
  FFontText: TTexturedFont;

  FDistanceToTravel, FDistanceAccu: single;
  procedure CreatePerspectiveLine(aIndex: integer; aPointFar, aPointNear: TPointF);
  property GameState: TGameState read FGameState write SetGameState;
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;
end;

var ScreenGameZipLine: TScreenGameZipLine;

implementation

uses u_app, u_resourcestring, u_screen_map, Forms, Math, ALSound;
type //L=left R=right Z=random side ZZ=random object/obstacle at random side
TLevelObject = (LObj, RObj, ZObj, LObs,  RObs, ZObs, ZZ);
TLevelStep = record
  O: TLevelObject; // object to create
  W: single;       // wait time before next object
end;
TArrayOfLevelStep = array of TLevelStep;
const // levels def
Lvl: array[0..9] of TArrayOfLevelStep=(
  // level 1
  ((O: LObj; W:1),(O: RObj; W:1),(O: RObs; W:0.75),(O: RObj; W:1),(O: RObj; W:1),(O: LObj; W:1),
   (O: ZZ; W:1)  ,(O: ZZ; W:1),  (O: ZZ; W:1),     (O: ZZ; W:1),  (O: ZZ; W:1),  (O: ZZ; W:1)
  ),
  // level 2
  ((O: LObj; W:0.75),(O: LObj; W:0.75),(O: RObj; W:1), (O: RObs; W:0.75),(O: LObj; W:0.75),(O: LObj; W:0.75),
   (O: RObj; W:0.75), (O: RObj; W:0.75),(O: RObs; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:0.75),
   (O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:0.75)
  ),
  // level 3
  ((O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: RObj; W:0.75),(O: RObj; W:0.5),(O: RObj; W:0.75),
   (O: LObj; W:0.5),(O: LObj; W:0.5),(O: LObj; W:1),(O: LObj; W:0.3),(O: LObs; W:0.75)
  ),
  // level 4
  ((O: LObs; W:0.75),(O: RObs; W:0.75),(O: LObs; W:0.75),(O: RObs; W:0.75),(O: LObs; W:0.75),(O: RObs; W:0.75),
   (O: LObj; W:0.5),(O: LObj; W:0.5),(O: LObj; W:0.75),(O: LObs; W:0.75),
   (O: RObj; W:0.5),(O: RObj; W:0.5),(O: RObj; W:0.75),(O: RObs; W:0.75),
   (O: LObs; W:0.75),(O: LObs; W:0.75),(O: RObs; W:0.75),(O: RObs; W:1.0)
  ),
  // level 5
  ((O: LObs; W:0.75),(O: LObs; W:0.75),(O: RObs; W:0.75),(O: RObs; W:0.75),
  (O: LObj; W:0.5),(O: LObj; W:0.5),(O: RObj; W:0.5),(O: RObj; W:0.5),(O: RObs; W:0.75),(O: LObs; W:1.0),
  (O: ZObj; W:0.5),(O: ZObj; W:0.5),(O: ZObj; W:0.5),(O: ZObj; W:0.5),(O: ZObj; W:0.5),(O: ZObj; W:0.5),
  (O: ZObj; W:0.5),(O: ZObj; W:0.5),(O: ZObj; W:0.5),(O: ZObj; W:0.5),(O: ZObj; W:1.0),
  (O: ZObs; W:0.75),(O: ZObs; W:0.75),(O: ZObs; W:0.75),(O: ZObs; W:0.75),(O: ZObs; W:0.75)
  ),
  // level 6
  ((O: LObj; W:0.75),(O: LObj; W:0.3),(O: LObj; W:0.75),(O: LObj; W:1.0),(O: LObs; W:0.75),
   (O: RObj; W:0.75),(O: RObj; W:0.3),(O: RObj; W:0.75),(O: RObj; W:1.0),(O: RObs; W:1.0),
   (O: ZObj; W:0.75),(O: ZObs; W:0.75),(O: ZObj; W:0.75),(O: ZObs; W:0.75),(O: ZObj; W:0.75),(O: ZObs; W:0.75),
   (O: ZObs; W:0.75),(O: ZObs; W:0.75),(O: ZObs; W:0.75),(O: ZObs; W:0.75),(O: ZObs; W:0.75),(O: ZObs; W:1.0),
   (O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:1.0),
   (O: LObs; W:0.75),(O: RObs; W:0.75),(O: LObs; W:0.75),(O: RObs; W:0.75),(O: LObs; W:0.75),(O: RObs; W:1.0),
   (O: LObs; W:0.75),(O: RObs; W:0.75),(O: LObs; W:0.75),(O: RObs; W:0.75)
  ),
  // level 7
  ((O: LObj; W:0.75),(O: RObj; W:0.75),(O: RObs; W:0.75),(O: RObj; W:0.75),(O: RObj; W:0.75),(O: LObj; W:0.75),
   (O: ZZ; W:1)  ,(O: ZZ; W:0.75),  (O: ZZ; W:0.75),     (O: ZZ; W:0.75),  (O: ZZ; W:0.75),  (O: ZZ; W:0.75)
  ),
  // level 8
  ((O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: LObj; W:0.75),(O: RObj; W:0.75),(O: LObj; W:0.75),
   (O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:1.0),(O: RObj; W:0.75),(O: RObj; W:0.75)
  ),
  // level 9
  ((O: RObj; W:0.5),(O: RObj; W:0.5),(O: RObj; W:0.5),(O: RObj; W:0.5),(O: RObj; W:0.5),(O: RObj; W:0.5),
   (O: LObj; W:0.5),(O: LObj; W:0.5),(O: LObj; W:0.5),(O: LObj; W:0.5),(O: LObj; W:0.5),(O: LObj; W:0.5),
   (O: LObs; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:0.75),
   (O: LObs; W:0.5),(O: ZZ; W:0.75),(O: ZZ; W:0.75),(O: ZZ; W:0.5),(O: ZZ; W:0.75),(O: ZZ; W:0.75),
   (O: RObs; W:0.75),(O: RObs; W:0.75),(O: RObs; W:0.85),(O: LObs; W:0.75),(O: LObs; W:0.75),(O: LObs; W:1.0)

  ),
  // level 10
  ((O: LObs; W:0.75),(O: LObs; W:0.75),(O: LObs; W:0.85),(O: RObs; W:0.75),(O: RObs; W:0.75),(O: RObs; W:1.0),
   (O: RObj; W:0.5),(O: RObj; W:0.75),(O: LObj; W:0.5),(O: LObj; W:0.75),(O: LObs; W:0.75),
   (O: RObs; W:0.75),(O: LObs; W:0.75),(O: RObs; W:0.75),(O: LObs; W:0.75),(O: RObs; W:0.75),(O: LObs; W:0.75),
   (O: LObj; W:0.35),(O: LObj; W:0.35),(O: LObj; W:0.35),(O: LObj; W:0.75),
   (O: RObj; W:0.35),(O: RObj; W:0.35),(O: RObj; W:0.35),(O: RObj; W:0.35),(O: RObs; W:0.75),
   (O: LObs; W:0.75),(O: RObs; W:0.75),(O: LObs; W:0.75),(O: RObs; W:0.75),(O: LObs; W:0.75),(O: RObs; W:0.75)
  )
 );

var texLRDress, texLRCloak, texLRLeftArm, texLRRightArm, texLRLeg, texLROutch,
  texMecanism, texMecanismBreak, texCableForward, texCableBackward,
  texTargetVolcano, texCloud1, texCloud2, texCloud3,
  texBGMountainLeft, texBGMountainRight,
  texScrollingPlatform1, texScrollingPlatformDown, texScrollingCloud,
  texWarningSignal, texWall, texWallBreak,
  texPlatformCoin10, texPlatformCoin100,
  texLRIcon: PTexture;


procedure PlaySoundWallHurt;
begin
  with Audio.AddSound('smashing-head-on-wall.ogg') do begin
    Volume.Value := 0.8;
    PlayThenKill(True);
  end;
end;

type

{ TLRBody }

TLRBody = class(TSpriteContainer)
  private type TBodyState = (bsNeutral, bsRotating);
private
  Dress: TLRDress;
  Cloak: TDeformationGrid;
  RightArm, LeftArm: TSprite;
  RightLeg, LeftLeg: TSprite;
  FBodyState: TBodyState;
  procedure SetDeformationOnCloak;
public
  constructor Create;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure SetWindSpeed(AValue: single);
  procedure SwingLegsToTheLeft;
  procedure SwingLegsToTheRight;
  procedure SetPositionHurtAWall;
end;

{ TZipLineMecanism }
TZipLineMecanismState = (zlmRunning,
                         zlmStartAnimHurtAWall, zlmAnimHurtAWallIsDone,
                         zlmStartAnimOutOfTime, zlmAnimOutOfTimeIsDone,
                         zlmBeforeArrival,
                         zlmStartAnimSmoothArrival, zlmStartAnimRoughArrival, zlmAnimArrivalIsDone);
// (X,Y) coordinates are the TOP of the backward cable
TZipLineMecanism = class(TSpriteContainer)
private const HALF_ROTATION_AMPLITUDE = 37;
              BREAK_ROTATION_AMPLITUDE = 25;
private
  Mecanism, FBreak, CableForward, CableBackward: TSprite;
  FBreakParticles: TParticleEmitter;
  LR: TLRBody;
  LRFrontView: TLRFrontView;
  FState: TZipLineMecanismState;
  FYMecanism: single;
  FWantedAngle: single;
  FPlayerWantRotation, FIsBreaking: boolean;
  procedure SetState(AValue: TZipLineMecanismState);
public
  constructor Create;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;

  procedure StartCableSwingAndShake;
  procedure ShiftToLeft(aDegreeAmount: single);
  procedure ShiftToRight(aDegreeAmount: single);
  function CanRotate: boolean;

  procedure UseBreak(aValue: boolean);
  property PlayerWantRotation: boolean read FPlayerWantRotation write FPlayerWantRotation;
  property CurrentAngle: single read FWantedAngle;
  property State: TZipLineMecanismState read FState write SetState;
end;


{ TPerspectiveLine }

TPerspectiveLine = class
  private const SCALE_MAXVALUE = 2.0;
                SCALE_MINVALUE = 0.2;
private
  FFar, FNear: TPointF;
  FPolar: TPolarCoor;
  FDistanceMax: single;
public
  constructor Create(aFarPoint, aNearPoint: TPointF);
  procedure GetValues(aDistanceFromOrigin: single;
                      out aPos: TPointF;
                      out aScaleValue: single;
                      out aTintValue: TBGRAPixel);
end;

{ TSpriteOnPerspectiveLine }

TSpriteOnPerspectiveLine = class(TSprite)
private const COLLISION_DISTANCE_MIN = 0.9;
              COLLISION_DISTANCE_MAX = 1.0;
              ENDLIFE_DISTANCE = 1.8;
private
  FLineToFollow: TPerspectiveLine;
  FDistanceFromOrigin: single; // 0=furthest point, 1=nearest point of the perspective line, can be >1
  FAdditionnalScale: TPointF;
  FCheckCollisionEnabled: boolean;
  procedure UpdateProperties;
public
  procedure LocateSpriteAt(aPos: TPointF); virtual; // override to customize
  function CheckCollisionWithLR: boolean; virtual; abstract; // override to customize
  procedure ProcessCollisionWithLR(var aNewDistance: single); virtual; abstract;
  constructor Create(aLineToFollow: TPerspectiveLine; aTexture: PTexture);
  procedure Update(const aElapsedTime: single); override;
  property CheckCollisionEnabled: boolean read FCheckCollisionEnabled write FCheckCollisionEnabled;
end;


{ TBasePlatform }

TBasePlatform = class(TSpriteOnPerspectiveLine)
private
  FPlatformDown: TSprite;
public
  constructor Create(aLineToFollow: TPerspectiveLine);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessCollisionWithLR(var {%H-}aNewDistance: single); override;
end;

{ TPlatform }

TPlatform = class(TBasePlatform)
private
  FObjectToCollect: TSprite;
public
  constructor Create(aLineToFollow: TPerspectiveLine);
  function CheckCollisionWithLR: boolean; override;
  procedure ProcessCollisionWithLR(var {%H-}aNewDistance: single); override;
end;

{ TBeginEndPlatform }

TBeginEndPlatform = class(TBasePlatform)
private
  FIsBeginPlatform: boolean;
  FWallBreak: TSprite;
public
  constructor Create(aLineToFollow: TPerspectiveLine; aIsBeginPlatform: boolean);
  function CheckCollisionWithLR: boolean; override;
  procedure ProcessCollisionWithLR(var aNewDistance: single); override;
  procedure ShowWallBroken;
  procedure SetRightDistanceAtEndArrival;
end;

{ TObstacle }

TObstacle = class(TBasePlatform)
private
  FPlatformUp: TSprite;
public
  procedure LocateSpriteAt(aPos: TPointF); override;
  function CheckCollisionWithLR: boolean; override;
  procedure ProcessCollisionWithLR(var aNewDistance: single); override;
  constructor Create(aLineToFollow: TPerspectiveLine);
  procedure Update(const aElapsedTime: single); override;
end;

{ TScrollingCloud }

TScrollingCloud = class(TSpriteOnPerspectiveLine)
public
  constructor Create(aLineToFollow: TPerspectiveLine);
  function CheckCollisionWithLR: boolean; override;
  procedure ProcessCollisionWithLR(var {%H-}aNewDistance: single); override;
end;

{ TUICristalCounter }

TUICristalCounter = class(TUIItemCounter)
  constructor Create;
end;


{ TInGamePanel }

TInGamePanel = class(TBaseInGamePanelWithCoinAndClock)
private
  FCristalCounter: TUICristalCounter;
public
  constructor Create;
  procedure AddToCristal(aDelta: integer);
  property CristalCounter: TUICristalCounter read FCristalCounter;
end;

{ TEndGameScorePanel }

TEndGameScorePanel = class(TBasePanelEndGameScore)
private
  FInGamePanel: TInGamePanel;
public
  constructor Create(aIngamePanel: TInGamePanel);
  procedure AddGainToInGamePanel(aValue: integer); override;
end;

{ TProgressLine }

TProgressLine = class(TShapeOutline)
private
  FDistanceToTravel: single;
  FDistanceTraveled: single;
  FLRIcon: TSprite;
  procedure SetDistanceTraveled(AValue: single);
public
  constructor Create;
  property DistanceToTravel: single read FDistanceToTravel write FDistanceToTravel;
  property DistanceTraveled: single read FDistanceTraveled write SetDistanceTraveled;
end;


var FAtlas: TOGLCTextureAtlas;
    FLR: TZipLineMecanism;
    //FLeftPerspectiveLine, FRightPerspectiveLine: TPerspectiveLine;
    FPerspectiveLines: array[0..5] of TPerspectiveLine;
    FCenterPerspectiveLine: TPerspectiveLine;

    FDifficulty: integer;
    FGameSpeed, FMaxGameSpeed, FShiftValue: single; // range [0..1]
    FLvlStep: integer;
    FTimeAccu, FCloudAccu: single;
    FArrivalIsSmooth: boolean;
    FPreviousCloudLineIndex: integer;
    FEndPlatform, FEndPlatformLeft, FEndPlatformRight: TBeginEndPlatform;
    FInGamePanel: TInGamePanel;
    FEndGameScorePanel: TEndGameScorePanel;
    FProgressPanel: TProgressLine;

{ TBasePlatform }

constructor TBasePlatform.Create(aLineToFollow: TPerspectiveLine);
begin
  inherited Create(aLineToFollow, texScrollingPlatform1);
//  FScene.Insert(0, Self, LAYER_GROUND);

  FPlatformDown := TSprite.Create(texScrollingPlatformDown, False);
  AddChild(FPlatformDown, -1);
  FPlatformDown.CenterX := Width*0.5;
  FPlatformDown.Y.Value := Height*0.7;
  FPlatformDown.Tint.Value := Tint.Value;

  ChildsUseParentOpacity := True;
end;

procedure TBasePlatform.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  FPlatformDown.Tint.Value := Tint.Value;
end;

procedure TBasePlatform.ProcessCollisionWithLR(var aNewDistance: single);
begin
 // do nothing here
end;

{ TProgressLine }

procedure TProgressLine.SetDistanceTraveled(AValue: single);
begin
  FDistanceTraveled := AValue;
  FLRIcon.CenterX := FDistanceTraveled/FDistanceToTravel * Width;
end;

constructor TProgressLine.Create;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_GAMEUI);
  SetShapeLine(PointF(FScene.Width*0.05, texLRIcon^.FrameHeight*1.1),
                PointF(FScene.Width*0.4,texLRIcon^.FrameHeight*1.1));
  LineWidth := 2;
  LineColor := BGRA(15,15,15);

  FLRIcon := TSprite.Create(texLRIcon, False);
  AddChild(FLRIcon, 0);
  //FLRIcon.Blink(-1, 0.4, 0.4);
  FLRIcon.Y.Value := -FLRIcon.Height*0.9;
  FLRIcon.CenterX := 0;
end;

{ TEndGameScorePanel }

constructor TEndGameScorePanel.Create(aIngamePanel: TInGamePanel);
var smoothArrivalBonus: integer;
    w: integer;
    t: TFreeText;
    equal: TUILabel;
begin
  inherited Create(3);

  FInGamePanel := aInGamePanel;

  // line 1  remain time
  equal := CreateLabelEqual;
  t := TFreeText.Create(FScene);
  equal.AddChild(t);
  t.Tint.Value := BGRA(220,220,220);
  t.TexturedFont := UIFontNumber;
  t.Caption := sRemainTime+' '+' x 10';
  t.SetCoordinate(-HMargin-t.Width, 0);
  w := HMargin+t.Width;
  t := TFreeText.Create(FScene);
  t.Tint.Value := BGRA(255,255,150);
  equal.AddChild(t);
  t.TexturedFont := UIFontNumber;
  t.Caption := (FInGamePanel.Second*10).ToString;
  t.RightX := HMargin*6;
  t.Y.Value := 0;
  w := w + Round(t.RightX);
  CompareLineWidth(w);

  // line 2 smooth arrival bonus
  equal := CreateLabelEqual;
  t := TFreeText.Create(FScene);
  t.Tint.Value := BGRA(220,220,220);
  equal.AddChild(t);
  t.TexturedFont := UIFontNumber;
  t.Caption := sSmoothArrivalBonus;
  t.SetCoordinate(-HMargin-t.Width, 0);
  w := HMargin+t.Width;
  t := TFreeText.Create(FScene);
  t.Tint.Value := BGRA(255,255,150);
  equal.AddChild(t);
  t.TexturedFont := UIFontNumber;
  if FArrivalIsSmooth then smoothArrivalBonus := 200 + 20*FDifficulty
    else smoothArrivalBonus := 0;
  t.Caption := smoothArrivalBonus.ToString;
  t.RightX := HMargin*6;
  t.Y.Value := 0;
  w := w + Round(t.RightX);
  CompareLineWidth(w);

  Gain := FInGamePanel.Second*10 + smoothArrivalBonus;

  // line 3 TOTAL
  CreateLineTotalGain(sTotal);

  StartCounting;
end;

procedure TEndGameScorePanel.AddGainToInGamePanel(aValue: integer);
begin
  Audio.PlayBlipIncrementScore;
  FInGamePanel.AddToCoin(aValue);
end;

{ TInGamePanel }

constructor TInGamePanel.Create;
begin
  inherited Create;
  BlinkClockWhenLessThan(10);

  FCristalCounter := TUICristalCounter.Create;
  AddItem(FCristalCounter);
  ResizeAndPlaceAtTopRight;
end;

procedure TInGamePanel.AddToCristal(aDelta: integer);
begin
  FCristalCounter.Count := FCristalCounter.Count + aDelta;
end;

{ TUICristalCounter }

constructor TUICristalCounter.Create;
begin
  inherited Create(texCristalGray, UIFontNumber, 2);
  Icon.TintMode := tmMixColor;
  Icon.Tint.Value := BGRA(255,0,255,150);
  Count := playerInfo.PurpleCristalCount;
end;

{ TBeginEndPlatform }

constructor TBeginEndPlatform.Create(aLineToFollow: TPerspectiveLine; aIsBeginPlatform: boolean);
var o: TSprite;
begin
  inherited Create(aLineToFollow);
  CheckCollisionEnabled := aLineToFollow = FCenterPerspectiveLine;
  FScene.Insert(0, Self, LAYER_GROUND);

  FAdditionnalScale := PointF(1.0, 1);
  FIsBeginPlatform := aIsBeginPlatform;

  if aIsBeginPlatform then begin
    CheckCollisionEnabled := False;
    FDistanceFromOrigin := 1.3;
    UpdateProperties;
  end else begin
      if aLineToFollow = FCenterPerspectiveLine then begin
      // wall and wall broken
      o := TSprite.Create(texWall, False);
      AddChild(o, 0);
      o.CenterX := Width*0.5;
      o.BottomY := Height*0.15;
      FWallBreak := TSprite.Create(texWallBreak, False);
      o.AddChild(FWallBreak, 0);
      FWallBreak.CenterX := o.Width*0.5;
      FWallBreak.CenterY := o.Height*0.47;
      FWallBreak.Visible := False;
    end else begin
      // warning signal
      o := TSprite.Create(texWarningSignal, False);
      AddChild(o, 0);
      o.Scale.Value := PointF(0.95,0.95);
      o.ScaledBottomY := Height*0.15;
      o.CenterX := Width*0.5;
    end;
  end;
end;

function TBeginEndPlatform.CheckCollisionWithLR: boolean;
begin
  if FLineToFollow = FPerspectiveLines[2]
    then Result := FLR.CurrentAngle > -FLR.HALF_ROTATION_AMPLITUDE*0.5
    else Result := FLR.CurrentAngle < FLR.HALF_ROTATION_AMPLITUDE*0.5;
end;

procedure TBeginEndPlatform.ProcessCollisionWithLR(var aNewDistance: single);
begin
  if FIsBeginPlatform or (ScreenGameZipLine.GameState <> gsRunning) then exit;
  aNewDistance := 1.25;
  if (ScreenGameZipLine.GameState <> ScreenGameZipLine.TGameState.gsCompleted) then
    ScreenGameZipLine.GameState := ScreenGameZipLine.TGameState.gsCompleted;
end;

procedure TBeginEndPlatform.ShowWallBroken;
begin
  FWallBreak.Visible := True;
end;

procedure TBeginEndPlatform.SetRightDistanceAtEndArrival;
begin
  FDistanceFromOrigin := 1.25;
end;

{ TObstacle }

procedure TObstacle.LocateSpriteAt(aPos: TPointF);
begin
  if FLineToFollow = FPerspectiveLines[2] then //ScaledX := aPos.x
    CenterX := aPos.x + Width*Scale.x.Value*FAdditionnalScale.x*0.5
  else //ScaledRightX := aPos.x;
    CenterX := aPos.x - Width*Scale.x.Value*FAdditionnalScale.x*0.5;
  //BottomY := aPos.y;
  CenterY := aPos.y;
end;

function TObstacle.CheckCollisionWithLR: boolean;
begin
  if FLineToFollow = FPerspectiveLines[2]
    then Result := FLR.CurrentAngle > -FLR.HALF_ROTATION_AMPLITUDE*0.5
    else Result := FLR.CurrentAngle < FLR.HALF_ROTATION_AMPLITUDE*0.5;
end;

procedure TObstacle.ProcessCollisionWithLR(var aNewDistance: single);
begin
  aNewDistance := COLLISION_DISTANCE_MIN;
  if ScreenGameZipLine.GameState <> gsRunning then exit;

  ScreenGameZipLine.GameState := ScreenGameZipLine.TGameState.gsLRHurtAWall;
end;

constructor TObstacle.Create(aLineToFollow: TPerspectiveLine);
begin
  inherited Create(aLineToFollow);
  CheckCollisionEnabled := True;
  FScene.Insert(0, Self, LAYER_GROUND);
  FAdditionnalScale := PointF(1.1, 1);
  UpdateProperties;

  FPlatformUp := TSprite.Create(texScrollingPlatform1, False);
  AddChild(FPlatformUp, 0);
  FPlatformUp.SetCoordinate(0, -Height*0.8);
  FPlatformUp.Tint.Value := Tint.Value;
end;

procedure TObstacle.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  FPlatformUp.Tint.Value := Tint.Value;
end;

{ TScrollingCloud }

constructor TScrollingCloud.Create(aLineToFollow: TPerspectiveLine);
begin
  inherited Create(aLineToFollow, texScrollingCloud);
  FScene.Insert(0, Self, LAYER_GROUND);
  CheckCollisionEnabled := False;
end;

function TScrollingCloud.CheckCollisionWithLR: boolean;
begin
  Result := False;
end;

procedure TScrollingCloud.ProcessCollisionWithLR(var aNewDistance: single);
begin
// do nothing here
end;

{ TPlatform }

constructor TPlatform.Create(aLineToFollow: TPerspectiveLine);
var v: integer;
begin
  inherited Create(aLineToFollow);
  CheckCollisionEnabled := True;
  FScene.Insert(0, Self, LAYER_GROUND);

  v := Random(1000);
  if v > 250 then begin
    if v < 500 then FObjectToCollect := TSprite.Create(texPlatformCoin10, False)
    else if v < 750 then FObjectToCollect := TSprite.Create(texPlatformCoin100, False)
    else if v < 1000 then begin
      FObjectToCollect := TSprite.Create(texCristalGray, False);
      FObjectToCollect.TintMode := tmMixColor;
      FObjectToCollect.Tint.Value := BGRA(255,0,255,150);
    end;
    AddChild(FObjectToCollect, 0);
    FObjectToCollect.CenterX := Width*0.5;
    FObjectToCollect.CenterY := Height *0.05;
  end else FObjectToCollect := NIL;
end;

function TPlatform.CheckCollisionWithLR: boolean;
begin
  if FLineToFollow = FPerspectiveLines[2]
    then Result := FLR.CurrentAngle > FLR.HALF_ROTATION_AMPLITUDE*0.5
    else Result := FLR.CurrentAngle < -FLR.HALF_ROTATION_AMPLITUDE*0.5;
end;

procedure TPlatform.ProcessCollisionWithLR(var aNewDistance: single);
begin
  if FObjectToCollect = NIL then exit;
  if ScreenGameZipLine.GameState <> gsRunning then exit;

  if FObjectToCollect.Texture = texPlatformCoin10 then begin
    Audio.PlayBlipIncrementScore;
    FInGamePanel.AddToCoin(10);
  end else if FObjectToCollect.Texture = texPlatformCoin100 then begin
    Audio.PlayBlipIncrementScore;
    FInGamePanel.AddToCoin(100);
  end else if FObjectToCollect.Texture = texCristalGray then begin
    Audio.PlayBlipIncrementScore;
    FInGamePanel.AddToCristal(1);
  end;
  FObjectToCollect.Kill;
  FObjectToCollect := NIL;
end;

{ TSpriteOnPerspectiveLine }

procedure TSpriteOnPerspectiveLine.LocateSpriteAt(aPos: TPointF);
begin
  SetCenterCoordinate(aPos);
end;

procedure TSpriteOnPerspectiveLine.UpdateProperties;
var pos: TPointF;
    scaleValue: single;
    tintValue: TBGRAPixel;
begin
  FLineToFollow.GetValues(FDistanceFromOrigin, pos, scaleValue, tintValue);
  LocateSpriteAt(pos);
  Scale.Value := PointF(scaleValue*FAdditionnalScale.x, scaleValue*FAdditionnalScale.y);
  Tint.Value := tintValue;
end;

constructor TSpriteOnPerspectiveLine.Create(aLineToFollow: TPerspectiveLine; aTexture: PTexture);
begin
  inherited Create(aTexture, False);
  FLineToFollow := aLineToFollow;
  FAdditionnalScale := PointF(1,1);
  UpdateProperties;
end;

procedure TSpriteOnPerspectiveLine.Update(const aElapsedTime: single);
var newDistance: single;
begin
  inherited Update(aElapsedTime);

  newDistance := FDistanceFromOrigin + FGameSpeed*aElapsedTime*(FDistanceFromOrigin*FDistanceFromOrigin*17+0.1);

  if FCheckCollisionEnabled then begin

    if ((FDistanceFromOrigin < COLLISION_DISTANCE_MIN) and (newDistance >= COLLISION_DISTANCE_MIN)) or
       ((FDistanceFromOrigin >= COLLISION_DISTANCE_MIN) and (newDistance <= COLLISION_DISTANCE_MAX)) then begin
      if CheckCollisionWithLR then ProcessCollisionWithLR(newDistance);
    end;
  end;

  if newDistance > ENDLIFE_DISTANCE then Kill
    else begin
      FDistanceFromOrigin := newDistance;
      UpdateProperties;
    end;
end;

{ TPerspectiveLine }

constructor TPerspectiveLine.Create(aFarPoint, aNearPoint: TPointF);
begin
  FFar := aFarPoint;
  FNear := aNearPoint;
  FDistanceMax := Distance(aFarPoint, aNearPoint);
  FPolar := CartesianToPolar(FFar, FNear);
end;

procedure TPerspectiveLine.GetValues(aDistanceFromOrigin: single; out aPos: TPointF;
  out aScaleValue: single; out aTintValue: TBGRAPixel);
begin
  FPolar.Distance := aDistanceFromOrigin*FDistanceMax;
  aPos := PolarToCartesian(FFar, FPolar);

  aDistanceFromOrigin := EnsureRange(aDistanceFromOrigin, 0, 1);
  aScaleValue := aDistanceFromOrigin*(SCALE_MAXVALUE-SCALE_MINVALUE) + SCALE_MINVALUE;

  if aDistanceFromOrigin >= 0.25 then aTintValue := BGRA(0,0,0,0)
    else aTintValue := BGRA(100,131,133, 255-Trunc(aDistanceFromOrigin*255/0.25));
end;

{ TZipLineMecanism }

procedure TZipLineMecanism.SetState(AValue: TZipLineMecanismState);
var o: TSprite;
begin
  if FState = AValue then Exit;
  FState := AValue;
  case FState of

    zlmStartAnimHurtAWall: begin
      o := TSprite.Create(texLROutch, False);
      CableBackward.AddChild(o, 3);
      o.CenterX := CableBackward.Width*0.5;
      o.CenterY := CableBackward.Height + Mecanism.Height;
      o.Opacity.ChangeTo(0, 2, idcStartSlowEndFast);
      o.KillDefered(2);
      UseBreak(False);
      PostMessage(100);
    end;

    zlmBeforeArrival: begin
      Angle.ChangeTo(0, 1, idcSinusoid);
    end;

    zlmStartAnimSmoothArrival: begin
      UseBreak(False);
      LR.Visible := False;
      LR.Freeze := True;
      LRFrontView.Visible := True;
      LRFrontView.Freeze := False;
      LRFrontView.Face.FaceType := lrfHappy;
      LRFrontView.MoveArmsAsWinner;
      LRFrontView.SetWindSpeed(0.2);
      PostMessage(200);
    end;

    zlmStartAnimRoughArrival: begin
      UseBreak(False);
      LR.SetWindSpeed(0.2);
      PostMessage(300);
    end;

    zlmStartAnimOutOfTime: begin
      UseBreak(False);
      PostMessage(400, 1);
    end;

  end;
end;

constructor TZipLineMecanism.Create;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_PLAYER);

  CableBackward := TSprite.Create(texCableBackward, False);
  AddChild(CableBackward, 0);
  CableBackward.X.Value := -CableBackward.Width*0.5;
  CableBackward.Y.Value := 0;
  CableBackward.ApplySymmetryWhenFlip := True;
  CableBackward.Pivot := PointF(0.5, 0.0);

  Mecanism := TSprite.Create(texMecanism, False);
  CableBackward.AddChild(Mecanism, 0);
  Mecanism.X.Value := (CableBackward.Width-Mecanism.Width)*0.4916;
  Mecanism.Y.Value := CableBackward.Height*0.95;
  Mecanism.ApplySymmetryWhenFlip := True;
  Mecanism.Pivot := PointF(0.4916, 0.1705);
  FYMecanism := CableBackward.Height*0.95;

  FBreak := TSprite.Create(texMecanismBreak, False);
  Mecanism.AddChild(FBreak, -1);
  FBreak.SetCoordinate(Mecanism.Width*0.2388, Mecanism.Height*0.006);
  FBreak.Pivot := PointF(0.1, 1.0);
  FBreak.Angle.ChangeTo(-BREAK_ROTATION_AMPLITUDE, 0);

  FBreakParticles := TParticleEmitter.Create(FScene);
  Mecanism.AddChild(FBreakParticles, 0);
  FBreakParticles.LoadFromFile(ParticleFolder+'ZipLineBreak.par', FAtlas);
  FBreakParticles.SetCoordinate(Mecanism.Width*0.4, Mecanism.Height*0.05);
  FBreakParticles.Freeze := False;
  FBreakParticles.Visible := False;

  CableForward := TSprite.Create(texCableForward, False);
  CableBackward.AddChild(CableForward, 1);
  CableForward.CenterX := CableBackward.Width*0.49;
  CableForward.BottomY := CableBackward.Height*1.1;
  CableForward.ApplySymmetryWhenFlip := True;
  CableForward.Pivot := PointF(0.495, 0.98);
  CableForward.Angle.Value := 20;

  LR := TLRBody.Create;
  Mecanism.AddChild(LR, 0);
  LR.CenterX := Mecanism.Width*0.53;
  LR.Y.Value := Mecanism.Height*0.9+LR.Dress.Height*1.75;

  LRFrontView := TLRFrontView.Create;
  Mecanism.AddChild(LRFrontView, 0);
  LRFrontView.CenterX := Mecanism.Width*0.53;
  LRFrontView.Y.Value := Mecanism.Height*0.9+LR.Dress.Height*1.75;
  LRFrontView.HideBasket;
  LRFrontView.Visible := False;
  LRFrontView.Freeze := True;

  FState := zlmRunning;
end;

procedure TZipLineMecanism.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if (State <> zlmRunning) and (State <> zlmBeforeArrival) then exit;

  if not FPlayerWantRotation then begin
    if FWantedAngle < 0 then begin
      FWantedAngle := FWantedAngle + 80*aElapsedTime;
      if FWantedAngle > 0 then begin
        FWantedAngle := 0;
        LR.SwingLegsToTheRight;
      end;
    end
    else if FWantedAngle > 0 then begin
      FWantedAngle := FWantedAngle - 80*aElapsedTime;
      if FWantedAngle < 0 then begin
        FWantedAngle := 0;
        LR.SwingLegsToTheLeft;
      end;
    end;
  end;
  Mecanism.Angle.Value := FWantedAngle;
  CableForward.Angle.Value := -FWantedAngle/HALF_ROTATION_AMPLITUDE*5+20;
end;

procedure TZipLineMecanism.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // SHAKING EFFECT
    0: begin
      if FGameSpeed > 0 then
        Mecanism.Y.Value := FYMecanism + random*ScaleH(6)-3;
      PostMessage(1, 0.016);
    end;
    1: begin
      Mecanism.Y.Value := FYMecanism;
      PostMessage(0, random*0.5);
    end;

    // Cable left/right swing
    10: begin
      if FState <> zlmRunning then exit;
      Angle.ChangeTo(3, 5, idcSinusoid);
      PostMessage(11, 5);
    end;
    11: begin
      if FState <> zlmRunning then exit;
      Angle.ChangeTo(-3, 5, idcSinusoid);
      PostMessage(10, 5);
    end;

    // START ANIM HURT A WALL
    100: begin
      PlaySoundWallHurt;
      LR.SetPositionHurtAWall;
      PostMessage(101, 0.75);
    end;
    101: begin
      Mecanism.Angle.ChangeTo(0, 1.5, idcSinusoid);
      PostMessage(102, 1);
    end;
    102: begin
      LR.Y.AddConstant(FScene.Height/5);
      PostMessage(103, 1.5);
    end;
    103: begin
      State := zlmAnimHurtAWallIsDone;
    end;

    // ANIM SMOOTH ARRIVAL
    200: begin
      PostMessage(201, 1);
    end;
    201: begin
      State := zlmAnimArrivalIsDone;
    end;

    // ANIM ROUGH ARRIVAL
    300: begin
      LR.LeftArm.Angle.Value := -80;
      LR.RightArm.Angle.Value := 80;
      LR.RightLeg.Angle.Value := -45;
      LR.LeftLeg.Angle.Value := 45;
      PostMessage(301, 1.5);
    end;
    301: begin
      LR.Visible := False;
      LR.Freeze := True;
      LRFrontView.Visible := True;
      LRFrontView.Freeze := False;
      LRFrontView.Face.FaceType := lrfBroken;
      PostMessage(302, 1);
    end;
    302: begin
      State := zlmAnimArrivalIsDone;
    end;

    // ANIM OUT OF TIME
    400: begin
      PostMessage(401);
      PostMessage(405, 3);
    end;
    401: begin
      LR.LeftLeg.Angle.ChangeTo(-15, 0.2, idcSinusoid);
      LR.RightLeg.Angle.ChangeTo(15, 0.2, idcSinusoid);
      PostMessage(402, 0.2);
    end;
    402: begin
      LR.LeftLeg.Angle.ChangeTo(0, 0.2, idcSinusoid);
      LR.RightLeg.Angle.ChangeTo(0, 0.2, idcSinusoid);
      PostMessage(401, 0.2);
    end;
    405: begin
      State := zlmAnimOutOfTimeIsDone;
    end;

  end;
end;

procedure TZipLineMecanism.StartCableSwingAndShake;
begin
  PostMessage(0); // shaking
  PostMessage(10); // cable swing
end;

procedure TZipLineMecanism.ShiftToLeft(aDegreeAmount: single);
begin
  if State = zlmBeforeArrival then begin
    FPlayerWantRotation := False;
    exit;
  end;

  FWantedAngle := FWantedAngle + aDegreeAmount;
  if FWantedAngle > HALF_ROTATION_AMPLITUDE then begin
    FWantedAngle := HALF_ROTATION_AMPLITUDE;
    LR.SwingLegsToTheRight;
  end;
  FPlayerWantRotation := True;
end;

procedure TZipLineMecanism.ShiftToRight(aDegreeAmount: single);
begin
  if State = zlmBeforeArrival then begin
    FPlayerWantRotation := False;
    exit;
  end;

  FWantedAngle := FWantedAngle - aDegreeAmount;
  if FWantedAngle < -HALF_ROTATION_AMPLITUDE then begin
    FWantedAngle := -HALF_ROTATION_AMPLITUDE;
    LR.SwingLegsToTheLeft;
  end;
  FPlayerWantRotation := True;
end;

function TZipLineMecanism.CanRotate: boolean;
begin
  Result := Abs(FWantedAngle) <> HALF_ROTATION_AMPLITUDE;
end;

procedure TZipLineMecanism.UseBreak(aValue: boolean);
begin
  if FIsBreaking and not aValue then begin
    FBreak.Angle.ChangeTo(-BREAK_ROTATION_AMPLITUDE, 0.25, idcSinusoid);
    FIsBreaking := False;
  end;
  if not FIsBreaking and aValue then begin
    FBreak.Angle.ChangeTo(0, 0, idcStartSlowEndFast);
    FIsBreaking := True;
  end;

  // break effect
  if FIsBreaking and (FGameSpeed > 0) then begin
    FBreakParticles.Freeze := False;
    FBreakParticles.Visible := True;
  end else begin
    FBreakParticles.Freeze := True;
    FBreakParticles.Visible := False;
  end;
end;

{ TLRBody }

procedure TLRBody.SetDeformationOnCloak;
const _cellCount = 5;
begin
  Cloak.SetGrid(_cellCount, _cellCount);
  Cloak.ApplyDeformation(dtWaveH);
  Cloak.Amplitude.Value := PointF(0.1, 0.2);
  Cloak.DeformationSpeed.Value := PointF(5,5);
  Cloak.SetDeformationAmountOnRow(0, 0.5);
  Cloak.SetDeformationAmountOnRow(1, 0.3);
  Cloak.SetDeformationAmountOnRow(2, 0.1);
  Cloak.SetDeformationAmountOnRow(3, 0);
  Cloak.SetDeformationAmountOnRow(4, 0.5);
  Cloak.SetDeformationAmountOnRow(5, 1.0);
//  Cloak.SetTimeMultiplicatorOnRow(5, 1.2);
end;

procedure TLRBody.SetWindSpeed(AValue: single);
begin
  Dress.SetWindSpeed(AValue);
  Cloak.Amplitude.Value := PointF(AValue, 0.2);
end;

procedure TLRBody.SwingLegsToTheLeft;
begin
  if FBodyState <> bsNeutral then exit;
  FBodyState := bsRotating;
  PostMessage(0);
end;

procedure TLRBody.SwingLegsToTheRight;
begin
  if FBodyState <> bsNeutral then exit;
  FBodyState := bsRotating;
  PostMessage(20);
end;

procedure TLRBody.SetPositionHurtAWall;
begin
  SetWindSpeed(0);
  LeftArm.Angle.Value := -30;
  RightArm.Angle.Value := 30;
  LeftLeg.Angle.Value := -30;
  RightLeg.Angle.Value := 30;
end;

constructor TLRBody.Create;
begin
  inherited Create(FScene);

  Dress := TLRDress.Create(texLRDress);
  AddChild(Dress, 0);
  Dress.X.Value := -Dress.Width*0.5;
  Dress.BottomY := 0;
  Dress.Pivot := PointF(0.5, 0.2);

    LeftLeg := TSprite.Create(texLRLeg, False);
    Dress.AddChild(LeftLeg, -1);
    LeftLeg.SetCoordinate(Dress.Width*0.2, Dress.Height*0.8);
    LeftLeg.Pivot := PointF(0.5, 0);
    LeftLeg.ApplySymmetryWhenFlip := True;

    RightLeg := TSprite.Create(texLRLeg, False);
    Dress.AddChild(RightLeg, -1);
    RightLeg.SetCoordinate(Dress.Width*0.6, Dress.Height*0.78);
    RightLeg.Pivot := PointF(0.5, 0);
    RightLeg.ApplySymmetryWhenFlip := True;

  Cloak := TDeformationGrid.Create(texLRCloak, False);
  AddChild(Cloak, 1);
  Cloak.CenterX := 0;
  Cloak.BottomY := Dress.Y.Value + Dress.Height*0.8;
  SetDeformationOnCloak;
  Cloak.ApplySymmetryWhenFlip := True;

    LeftArm := TSprite.Create(texLRLeftArm, False);
    Cloak.AddChild(LeftArm, -1);
    LeftArm.X.Value := -LeftArm.Width*0.4;
    LeftArm.BottomY := Cloak.Height*0.65;
    LeftArm.Pivot := PointF(0.8,0.85);
    LeftArm.ApplySymmetryWhenFlip := True;

    RightArm := TSprite.Create(texLRRightArm, False);
    Cloak.AddChild(RightArm, -1);
    RightArm.X.Value := Cloak.Width-RightArm.Width*0.8;
    RightArm.BottomY := Cloak.Height*0.65;
    RightArm.Pivot := PointF(0.2,0.85);
    RightArm.ApplySymmetryWhenFlip := True;

  SetWindSpeed(0.8);
end;

procedure TLRBody.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // leg swing to the left one time
    0: begin
      Dress.Angle.ChangeTo(-5, 0.5, idcSinusoid);
      RightLeg.Angle.ChangeTo(-5, 0.5, idcSinusoid);
      LeftLeg.Angle.ChangeTo(-5, 0.5, idcSinusoid);
      PostMessage(1, 0.5);
    end;
    1: begin
      Dress.Angle.ChangeTo(3, 0.6, idcSinusoid);
      RightLeg.Angle.ChangeTo(3, 0.6, idcSinusoid);
      LeftLeg.Angle.ChangeTo(3, 0.6, idcSinusoid);
      PostMessage(2, 0.6);
    end;
    2: begin
      Dress.Angle.ChangeTo(0, 0.6, idcSinusoid);
      RightLeg.Angle.ChangeTo(0, 0.6, idcSinusoid);
      LeftLeg.Angle.ChangeTo(0, 0.6, idcSinusoid);
      PostMessage(3, 0.6);
    end;
    3: begin
      FBodyState := bsNeutral;
    end;

    // leg swing to the right one time
    20: begin
      Dress.Angle.ChangeTo(5, 0.5, idcSinusoid);
      RightLeg.Angle.ChangeTo(5, 0.5, idcSinusoid);
      LeftLeg.Angle.ChangeTo(5, 0.5, idcSinusoid);
      PostMessage(21, 0.5);
    end;
    21: begin
      Dress.Angle.ChangeTo(-3, 0.6, idcSinusoid);
      RightLeg.Angle.ChangeTo(-3, 0.6, idcSinusoid);
      LeftLeg.Angle.ChangeTo(-3, 0.6, idcSinusoid);
      PostMessage(22, 0.6);
    end;
    22: begin
      Dress.Angle.ChangeTo(0, 0.6, idcSinusoid);
      RightLeg.Angle.ChangeTo(0, 0.6, idcSinusoid);
      LeftLeg.Angle.ChangeTo(0, 0.6, idcSinusoid);
      PostMessage(23, 0.6);
    end;
    23: begin
      FBodyState := bsNeutral;
    end;
  end;
end;


{ TScreenGameZipLine }

procedure TScreenGameZipLine.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then Exit;
  FGameState := AValue;
end;

procedure TScreenGameZipLine.CreatePerspectiveLine(aIndex: integer; aPointFar, aPointNear: TPointF);
begin
  FPerspectiveLines[aIndex] := TPerspectiveLine.Create(aPointFar, aPointNear);
{  FLines[aIndex] := TShapeOutline.Create(FScene);
  FScene.Add(FLines[aIndex], LAYER_TOP);
  FLines[aIndex].SetLine(aPointFar, aPointNear);  }
end;

procedure TScreenGameZipLine.CreateObjects;
var sky1, sky2: TMultiColorRectangle;
  o: TSprite;
  ima: TBGRABitmap;
  farPoint, nearPoint: TPointF;
  pe: TParticleEmitter;
  yy: Single;
  i: Integer;
begin
  Audio.PauseMusicTitleMap(3.0);
  FMusic := Audio.AddMusic('CatchyMusic.ogg', True);
  FMusic.FadeIn(1.0, 1.0);
  FsndZipLine := Audio.AddSound('ZipLine.ogg');
  FsndZipLine.Loop := True;
  FsndZipLine.Volume.Value := ZIP_LINE_VOLUME;

  FsndZipLineBreak := Audio.AddSound('grinder-on-metal.ogg');
  FsndZipLineBreak.Loop := True;
  FsndZipLineBreak.Volume.Value := ZIP_LINE_BREAK_VOLUME;

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 1;

  // textures for LR front view (end of the game, win or lost)
  AdditionnalScale := 1.5483;
  LoadLRFaceTextures(FAtlas);
  LoadLRFrontViewTextures(FAtlas);
  AdditionnalScale := 1.0;

  texLRCloak := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'LRCloakBack.svg', ScaleW(127), -1);
  texLRLeftArm := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'LRLeftArm.svg', ScaleW(53), -1);
  texLRRightArm := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'LRRightArm.svg', ScaleW(53), -1);
  texLRLeg := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'LRLeg.svg', ScaleW(30), -1);
  texLRDress := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'LRDress.svg', ScaleW(96), -1);
  texLROutch := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'LROutch.svg', ScaleW(218), -1);

  texMecanism := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'ZipLineMecanism.svg', ScaleW(180), -1);
  texMecanismBreak := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'MecanismBreak.svg', ScaleW(31), -1);
  FAtlas.Add(ParticleFolder+'Cross.png');
  texCableForward := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'CableForward.svg', -1, ScaleH(476));
  texCableBackward := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'CableBackward.svg', -1, ScaleH(246));

  texTargetVolcano := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'TargetVolcano.svg', ScaleW(417), -1);
  FAtlas.Add(ParticleFolder+'sphere_particle.png');
  texCloud1 := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'CloudLeftBehindVolcano.svg', ScaleW(351), -1);
  texCloud2 := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'CloudCenterBehindVolcano.svg', ScaleW(241), -1);
  texCloud3 := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'CloudRightBehindVolcano.svg', ScaleW(397), -1);
  texBGMountainLeft := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'BGMountainLeft.svg', ScaleW(350), -1);
  texBGMountainRight := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'BGMountainRight.svg', ScaleW(350), -1);

  texScrollingPlatform1 := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'ScrollingPlatform1.svg', ScaleW(142), -1);
  texScrollingPlatformDown := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'ScrollingPlatformDown.svg', ScaleW(125), -1);
  texScrollingCloud := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'ScrollingCloud.svg', ScaleW(469), -1);
  texWarningSignal := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'WarningSignal.svg', ScaleW(62), -1);
  texWall := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'Wall.svg', ScaleW(146), -1);
  texWallBreak := FAtlas.AddFromSVG(SpriteGameMountainPeaksFolder+'WallBreak.svg', ScaleW(117), -1);

  texPlatformCoin10 := FAtlas.AddFromSVG(SpriteUIFolder+'Coin10.svg', ScaleW(56), -1);
  texPlatformCoin100 := FAtlas.AddFromSVG(SpriteUIFolder+'Coin100.svg', ScaleW(56), -1);

  CreateGameFontNumber(FAtlas);
  LoadCoinTexture(FAtlas);
  LoadCristalGrayTexture(FAtlas);
  LoadWatchTexture(FAtlas);
  texLRIcon := FAtlas.AddFromSVG(SpriteBGFolder+'LR.svg', -1, ScaleH(32));

  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;
  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  // clouds behind volcano
  o := TSprite.Create(texCloud1, False);
  FScene.Add(o, LAYER_BG2);
  o.SetCenterCoordinate(ScaleW(255), ScaleH(150));
  o.Opacity.Value := 80;
  o := TSprite.Create(texCloud2, False);
  FScene.Add(o, LAYER_BG2);
  o.SetCenterCoordinate(ScaleW(639), ScaleH(112));
  o.Opacity.Value := 80;
  o := TSprite.Create(texCloud3, False);
  FScene.Add(o, LAYER_BG2);
  o.SetCenterCoordinate(ScaleW(691), ScaleH(183));
  o.Opacity.Value := 80;

  // BG mountain left and right
  FLeftMountain := TSprite.Create(texBGMountainLeft, False);
  FScene.Add(FLeftMountain, LAYER_BG2);
  FLeftMountain.SetCoordinate(0, ScaleH(67));
  FLeftMountainCenter := FLeftMountain.Center;
  FRightMountain := TSprite.Create(texBGMountainRight, False);
  FScene.Add(FRightMountain, LAYER_BG2);
  FRightMountain.RightX := FScene.Width;
  FRightMountain.Y.Value := ScaleH(42);
  FRightMountainCenter := FRightMountain.Center;

  // Target volcano
  FVolcano := TSprite.Create(texTargetVolcano, False);
  FScene.Add(FVolcano, LAYER_BG2);
  FVolcano.CenterX := FScene.Width*0.51;
  FVolcano.Y.Value := ScaleH(83);
  pe := TParticleEmitter.Create(FScene);
  FVolcano.AddChild(pe, 0);
  pe.LoadFromFile(ParticleFolder+'VolcanoMountainSmoke.par', FAtlas);
  pe.SetCoordinate(FVolcano.Width*0.35, FVolcano.Height*0.08);
  pe.SetEmitterTypeLine(PointF(FVolcano.Width*0.55, FVolcano.Height*0.08));

  // sky
  sky1 := TMultiColorRectangle.Create(FScene.Width, (FScene.Height-ScaleH(184)) div 2);
  FScene.Add(sky1, LAYER_BG1);
  sky1.SetTopColors(BGRA(255,255,255,0));
  sky1.SetBottomColors(BGRA(11,166,200));
  sky1.SetCoordinate(0, ScaleH(184));
  sky2 := TMultiColorRectangle.Create(FScene.Width, (FScene.Height-ScaleH(184)) div 2);
  FScene.Add(sky2, LAYER_BG1);
  sky2.SetTopColors(BGRA(11,166,200));
  sky2.SetBottomColors(BGRA(11,166,200));
  sky2.SetCoordinate(0, sky1.BottomY);

  // LR
  FLR := TZipLineMecanism.Create;
  FLR.SetCoordinate(FScene.Width*0.5, FVolcano.Y.Value+FVolcano.Height*0.2);

  // camera
  FCameraForPerspectiveObjects := FScene.CreateCamera;
  FCameraForPerspectiveObjects.AssignToLayer(LAYER_GROUND);

  yy := FVolcano.Y.Value+FVolcano.Height*0.5;
  // center perspective line
  farPoint := PointF(FScene.Width*0.50, yy);
  nearPoint := PointF(FScene.Width*0.5, FScene.Height);
  FCenterPerspectiveLine := TPerspectiveLine.Create(farPoint, nearPoint);

  // side perspective lines x6
  farPoint := PointF(FScene.Width*0.35, yy);
  nearPoint := PointF(farPoint.x-FScene.Width, FScene.Height);
  CreatePerspectiveLine(0, farPoint, nearPoint);

  farPoint := PointF(FScene.Width*0.40, yy);
  nearPoint := PointF(farPoint.x-FScene.Width*3/5, FScene.Height);
  CreatePerspectiveLine(1, farPoint, nearPoint);

  farPoint := PointF(FScene.Width*0.45, yy);
  nearPoint := PointF(farPoint.x-FScene.Width/5, FScene.Height);
  CreatePerspectiveLine(2, farPoint, nearPoint);

  farPoint := PointF(FScene.Width*0.55, yy);
  nearPoint := PointF(farPoint.x+FScene.Width/5, FScene.Height);
  CreatePerspectiveLine(3, farPoint, nearPoint);

  farPoint := PointF(FScene.Width*0.60, yy);
  nearPoint := PointF(farPoint.x+FScene.Width*3/5, FScene.Height);
  CreatePerspectiveLine(4, farPoint, nearPoint);

  farPoint := PointF(FScene.Width*0.65, yy);
  nearPoint := PointF(farPoint.x+FScene.Width, FScene.Height);
  CreatePerspectiveLine(5, farPoint, nearPoint);

  // Ingame pause panel
  FInGamePausePanel := TInGamePausePanel.Create(FFontText);

  // begining platform
  TBeginEndPlatform.Create(FPerspectiveLines[2], True);
  TBeginEndPlatform.Create(FCenterPerspectiveLine, True);
  TBeginEndPlatform.Create(FPerspectiveLines[3], True);

  // some clouds
  for i:=0 to 0 do begin
    with TScrollingCloud.Create(FPerspectiveLines[0]) do FDistanceFromOrigin := random(200)*0.001+0.01;
    with TScrollingCloud.Create(FPerspectiveLines[1]) do FDistanceFromOrigin := random(200)*0.001+0.01;
    with TScrollingCloud.Create(FPerspectiveLines[2]) do FDistanceFromOrigin := random(200)*0.001+0.01;
    with TScrollingCloud.Create(FPerspectiveLines[3]) do FDistanceFromOrigin := random(200)*0.001+0.01;
    with TScrollingCloud.Create(FPerspectiveLines[4]) do FDistanceFromOrigin := random(200)*0.001+0.01;
    with TScrollingCloud.Create(FPerspectiveLines[5]) do FDistanceFromOrigin := random(200)*0.001+0.01;
  end;

  // GET READY message
  FFontDescriptor.Create('Arial', Round(FScene.Height*0.1), [], BGRA(255,255,0), BGRA(0,0,0), PPIScale(3));
  GameState := gsGetReady; //gsRunning;
  PostMessage(0);

  // in game panel
  FInGamePanel := TInGamePanel.Create;


  // set game difficulty
  FDifficulty := PlayerInfo.MountainPeak.StepPlayed;
  FMaxGameSpeed := EnsureRange(0.6 + 0.5*FDifficulty/PlayerInfo.MountainPeak.StepCount, 0.5, 1); // [0.5 to 1.0]
  FDistanceToTravel := 700 + FDifficulty*200;
  i := Round(FDistanceToTravel*0.04 - FDistanceToTravel*0.005*FMaxGameSpeed);
  i := 33 + (FDifficulty-1)*4;
  FInGamePanel.Second := i;

  // progress panel
  FProgressPanel := TProgressLine.Create;
  FProgressPanel.DistanceToTravel := FDistanceToTravel;

  FDistanceAccu := 0;
  FGameSpeed := 0.0;
  FLvlStep := -1;
  FTimeAccu := 1.0;


  FScene.BackgroundColor := BGRA(80,40,80);
end;

procedure TScreenGameZipLine.FreeObjects;
var i: integer;
begin
  FMusic.FadeOutThenKill(1.0);
  FsndZipLine.FadeOutThenKill(1.0);
  FsndZipLineBreak.Kill;
  FMusic := NIL;
  Audio.ResumeMusicTitleMap(1.0);

  FScene.KillCamera(FCameraForPerspectiveObjects);

  FScene.ClearAllLayer;
  FreeAndNil(FAtlas);
  for i:=0 to High(FPerspectiveLines) do
    FreeAndNil(FPerspectiveLines[i]);
  FreeAndNil(FCenterPerspectiveLine);
end;

procedure TScreenGameZipLine.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // GET READY at beginning
    0: begin
      PostMessage(1, 0.75);
    end;
    1: begin
      FGetReady := TSprite.Create(FScene, FFontDescriptor, sGetReady);
      FScene.Add(FGetReady, LAYER_GAMEUI);
      FGetReady.CenterOnScene;
      FGetReady.KillDefered(2);
      PostMessage(2, 2.5);
    end;
    2: begin
      FGetReady := TSprite.Create(FScene, FFontDescriptor, sGo);
      FScene.Add(FGetReady, LAYER_GAMEUI);
      FGetReady.CenterOnScene;
      FGetReady.KillDefered(1);
      GameState := gsRunning;
      FLR.StartCableSwingAndShake;
      FInGamePanel.StartTime;
    end;
  end;
end;

procedure TScreenGameZipLine.Update(const aElapsedTime: single);
var i: integer;
  o: TSprite;
  v: Extended;
  procedure SavePlayerInfo;
  begin
    PlayerInfo.PurpleCristalCount := FInGamePanel.CristalCounter.Count;
    PlayerInfo.CoinCount := FInGamePanel.CoinCount;
    FSaveGame.Save;
  end;

begin
  inherited Update(aElapsedTime);

  case GameState of
    gsRunning: begin
      // acceleration and break
      if FScene.KeyState[KeyAction1] then begin
        FLR.UseBreak(True);
        FGameSpeed := FGameSpeed - 0.5*aElapsedTime; //0.01;
        if FGameSpeed < 0.0 then FGameSpeed := 0.0;
      end else begin
        FLR.UseBreak(False);
        //FGameSpeed := FGameSpeed + FMaxGameSpeed*0.2*aElapsedTime;
        // acceleration is less important when we reach the end
        if FEndPlatform = NIL then FGameSpeed := FGameSpeed + 0.3*aElapsedTime
          else FGameSpeed := FGameSpeed + 0.1*aElapsedTime;
        if FGameSpeed > FMaxGameSpeed then FGameSpeed := FMaxGameSpeed;
      end;

      // zipline sounds
      if FGameSpeed = 0 then begin
        FsndZipLine.Stop;
        FsndZipLineBreak.Stop;
      end else begin
        if FsndZipLine.State <> ALS_PLAYING then FsndZipLine.Play(True);
        if FsndZipLineBreak.State <> ALS_PLAYING then FsndZipLineBreak.Play(True);
      end;
      FsndZipLine.Pitch.Value := 1.0 - (1.0 - FGameSpeed)*0.95;

      // left
      if FScene.KeyState[KeyLeft] then begin
        FShiftValue := FShiftValue+(10+FShiftValue*0.5)*aElapsedTime;
        if FShiftValue > 2 then FShiftValue := 2;
        FLR.ShiftToLeft(FShiftValue);   // 40*aElapsedTime
      end else
      // right
      if FScene.KeyState[KeyRight] then begin
        FShiftValue := FShiftValue+(10+FShiftValue*0.5)*aElapsedTime;
        if FShiftValue > 2 then FShiftValue := 2;
        FLR.ShiftToRight(FShiftValue); // 40*aElapsedTime
      end else begin
        FLR.PlayerWantRotation := False;
        FShiftValue := 0;
      end;

      FCameraForPerspectiveObjects.MoveTo(PointF(FScene.Width*(0.5-FLR.CurrentAngle*0.001), FScene.Height*0.5), 0);

      // check if player pause the game
      if FScene.KeyState[KeyPause] then begin
        FsndZipLine.Stop;
        FsndZipLineBreak.Stop;
        FInGamePausePanel.ShowModal;
        exit;
      end;

      // clouds creation
      FCloudAccu := FCloudAccu + FGameSpeed;
      if FCloudAccu > 10 then begin
        FCloudAccu := FCloudAccu - 10;
        repeat
          i := Random(6000) div 1000;
        until i <> FPreviousCloudLineIndex;
        FPreviousCloudLineIndex := i;
        with TScrollingCloud.Create(FPerspectiveLines[i]) do
         Opacity.Value := 120;
      end;

      // end of time ?
      if FInGamePanel.Second = 0 then begin
        FGameSpeed := 0;
        FsndZipLine.Stop;
        FMusic.FadeOutThenPause(0.5);
        Audio.PlayMusicLose1;
        o := TSprite.Create(FScene, FFontDescriptor, sOutOfTime);
        FScene.Add(o, LAYER_GAMEUI);
        o.CenterOnScene;
        o.Scale.Value := PointF(0.1, 0.1);
        o.Scale.ChangeTo(PointF(1,1), 0.5, idcStartSlowEndFast);
        GameState := gsOutOfTime;
        exit;
      end;

      // end platform needed ?
      if FDistanceAccu < FDistanceToTravel then begin
        FDistanceAccu := FDistanceAccu + FGameSpeed;
        if FDistanceAccu >= FDistanceToTravel then begin
          FEndPlatform := TBeginEndPlatform.Create(FCenterPerspectiveLine, False);
          FEndPlatformLeft := TBeginEndPlatform.Create(FPerspectiveLines[2], False);
          FEndPlatformRight := TBeginEndPlatform.Create(FPerspectiveLines[3], False);
          FLR.State := zlmBeforeArrival;
        end;
      end;

      // left and right mountain moves to accentuate the perspective experience
      v :=  FDistanceAccu/FDistanceToTravel;
      FVolcano.Scale.Value := PointF(1+0.25*v, 1+0.25*v);
      FLeftMountain.Scale.Value := PointF(1+0.25*v, 1+0.25*v);
      FRightMountain.Scale.Value := PointF(1+0.25*v, 1+0.25*v);
      FLeftMountain.CenterX := FLeftMountainCenter.x - FLeftMountain.Width*0.2*v;
      FLeftMountain.CenterY := FLeftMountainCenter.y + FLeftMountain.Height*0.15*v;
      FRightMountain.CenterX := FRightMountainCenter.x + FRightMountain.Width*0.2*v;
      FRightMountain.CenterY := FRightMountainCenter.y + FRightMountain.Height*0.15*v;

      // obstacles creation
      if FDistanceAccu < FDistanceToTravel-100 then begin
        FTimeAccu := FTimeAccu - aElapsedTime*FGameSpeed;
        if FTimeAccu <= 0 then begin
          inc(FLvlStep);
          if FLvlStep = Length(Lvl[FDifficulty-1]) then FLvlStep := 0;
          case Lvl[FDifficulty-1][FLvlStep].O of
            LObj: TPlatform.Create(FPerspectiveLines[2]);
            RObj: TPlatform.Create(FPerspectiveLines[3]);
            ZObj: if Random(1000) < 500 then TPlatform.Create(FPerspectiveLines[2])
                    else TPlatform.Create(FPerspectiveLines[3]);
            LObs: TObstacle.Create(FPerspectiveLines[2]);
            RObs: TObstacle.Create(FPerspectiveLines[3]);
            ZObs: if Random(1000) < 500 then TObstacle.Create(FPerspectiveLines[2])
                    else TObstacle.Create(FPerspectiveLines[3]);
            ZZ: if Random(1000) < 500 then begin
               if Random(1000) < 500 then TPlatform.Create(FPerspectiveLines[2])
                    else TPlatform.Create(FPerspectiveLines[3]);
            end else begin
               if Random(1000) < 500 then TObstacle.Create(FPerspectiveLines[2])
                    else TObstacle.Create(FPerspectiveLines[3]);
            end;
          end;
          FTimeAccu := Lvl[FDifficulty-1][FLvlStep].W;
        end;
{        FTimeAccu := FTimeAccu + aElapsedTime*FGameSpeed;
        if FTimeAccu > 0.8 then begin
          FTimeAccu := 0.0;
          if Random > 0.5 then begin
            if FSideFlag then TObstacle.Create(FPerspectiveLines[2])
              else TObstacle.Create(FPerspectiveLines[3]);
          end else begin
            if FSideFlag then TPlatform.Create(FPerspectiveLines[2])
              else TPlatform.Create(FPerspectiveLines[3]);
          end;
          FSideFlag := not FSideFlag;
        end;   }
      end;

      // update progress panel
      FProgressPanel.DistanceTraveled := FDistanceAccu;
    end;

    gsOutOfTime: begin
      FsndZipLine.Stop;
      FsndZipLineBreak.Stop;
      FLR.State := zlmStartAnimOutOfTime;
      GameState := gsWaitUntilAnimOutOfTimeIsDone;
    end;

    gsWaitUntilAnimOutOfTimeIsDone: begin
      if FLR.State = zlmAnimOutOfTimeIsDone then begin
        SavePlayerInfo;
        FScene.RunScreen(ScreenMap);
      end;
    end;

    gsLRHurtAWall: begin
      FsndZipLine.Stop;
      FsndZipLineBreak.Stop;
      FGameSpeed := 0;
      FInGamePanel.PauseTime;
      FLR.State := zlmStartAnimHurtAWall;
      GameState := gsWaitUntilAnimHurtAWallIsDone;
    end;

    gsWaitUntilAnimHurtAWallIsDone: begin
      if FLR.State = zlmAnimHurtAWallIsDone then begin
        SavePlayerInfo;
        FScene.RunScreen(ScreenMap);
      end;
    end;

    gsCompleted: begin
      FEndPlatformLeft.SetRightDistanceAtEndArrival;
      FEndPlatformRight.SetRightDistanceAtEndArrival;
      FsndZipLine.Stop;
      FsndZipLineBreak.Stop;
      if FGameSpeed > 0.5*FMaxGameSpeed then begin
        PlaySoundWallHurt;
        FLR.State := zlmStartAnimRoughArrival;
        FEndPlatform.ShowWallBroken;
        FArrivalIsSmooth := False;
      end else begin
        Audio.PlayVoiceWhowhooo;
        FLR.State := zlmStartAnimSmoothArrival;
        FArrivalIsSmooth := True;
      end;
      PlayerInfo.MountainPeak.IncCurrentStep;
      SavePlayerInfo;
      FInGamePanel.PauseTime;
      FGameSpeed := 0;
      GameState := gsWaitForEndArrivalAnim;
    end;

    gsWaitForEndArrivalAnim: begin
      if FLR.State = zlmAnimArrivalIsDone then GameState := gsCreatePanelAddScore;
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

