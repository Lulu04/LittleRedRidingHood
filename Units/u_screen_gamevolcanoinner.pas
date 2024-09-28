unit u_screen_gamevolcanoinner;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lr4dir, u_sprite_lrcommon, u_sprite_def, u_lr4_usable_object;


// {$define LRInvincible}

type

{ TScreenGameVolcanoInner }

TScreenGameVolcanoInner = class(TGameScreenTemplate)
private type TGameState=(gsUndefined=0, gsIdle, gsRunning,
                         gsLRCaptured, gsLRWin,
                         gsDecodingDigicode,
                         gsLookInTheCrate,
                         gsStartAnimRobotConstructorMoves);
var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FCamera, FCameraBGWall: TOGLCCamera;
  FCameraFollowLR: boolean;
  FExitToTheRight: boolean;
  FViewArea: TRectF;
  FViewHeight: single;
  FsndPercuLoop, FsndBoilingLava, FsndMechanical, FsndEarthquakeLoop, FsndEarthquake: TALSSound;
  FFireOnComputer: TFireLine;
  FFunnyMessageIndex: integer;
  FFunnyMessages: TStringArray;
  FCurrentGameLevel: integer;

  FInGamePausePanel: TInGamePausePanel;
  FPanelDecodingDigicode: TPanelDecodingDigicode;

  FDifficulty: integer;
  procedure CreateCeilling;
  procedure CreateBGWall;
  procedure CreateGroundLarge(aX: single; aFloorIndex, aCount: integer);
  procedure CreateGroundLarge2(aX, aY: single; aCount: integer);
  procedure CreatePillar(const aXs: array of integer; aFloorIndex, aLayerIndex: integer; aFullOpaque: boolean);
  procedure CreateLava(aFromX, aToX, aY: single; aFadeIn: boolean=False);
  procedure CreateLevel(aLevelIndex: integer);
  procedure CreateLevel1; // discover the machine
  procedure CreateLevel2; //
  procedure CreateLevel3; // found green SD card
  procedure CreateLevel4; // found dorsal propulsor
  procedure CreateLevel5; // destroy the machine

  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
  //procedure ProcessCallbackPickUpSomethingWhenBendDown(aPickUpToTheRight: boolean);
  procedure ProcessLayerLadderBeforeUpdateEvent;
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  procedure MoveCameraTo(const p: TPointF; aDuration: single);
  procedure ZoomCameraTo(const z: TPointF; aDuration: single);
  function GetCameraCenterView: TPointF;

  procedure ProcessPlayerEnterCheatCode(const aCheatCode: string);

  procedure SetBoilingLavaVolume(AValue: single);
  property Difficulty: integer write FDifficulty;
  property ExitToTheRight: boolean read FExitToTheRight write FExitToTheRight;
  // used to compute boiling lava volume
  property ViewHeight: single read FViewHeight;
  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenGameVolcanoInner: TScreenGameVolcanoInner;
    FLRIsInvisible: boolean=False;

implementation

uses Forms, u_sprite_wolf, u_app, u_screen_map, u_resourcestring, u_utils,
  LCLType, Math, ALSound, BGRAPath;

function FloorToY(aFloorIndex0Based: integer): integer;
begin
  Result := ScaleH(245) + ScaleH(230)*aFloorIndex0Based;  // 230 = ladder height
end;
// Return the floor index where aY is. Return -1 if aY is not on a floor
function YToFloor(aY: single): integer;
var y1, y2, fl, yfl: integer;
begin
  y1 := Round(aY - PPIScale(1));
  y2 := Round(aY + PPIScale(1));
  fl := 0;
  repeat
    yfl := FloorToY(fl);
    if inRange(yfl, y1, y2) then exit(fl);
    if aY < yfl then exit(-1);
    inc(fl);
  until False;
end;

function GetNearestFloor(aY: single): integer;
var yy, fl, deltaOrigin, delta: integer;
begin
  yy := Round(aY);
  fl := 0;
  deltaOrigin := Abs(yy - FloorToY(fl));
  repeat
    inc(fl);
    delta := Abs(yy - FloorToY(fl));
    if delta < deltaOrigin then deltaOrigin := delta
      else exit(fl-1);
  until False;
end;

function DeltaFloorToCharacterFeet: integer;
begin
  Result := ScaleH(5);
end;

type
{ TLRCustom }

TLRCustom = class(TLR4Direction)
private
  function GetCurrentFloor: integer;
  procedure SetCurrentFloor(AValue: integer);
public
  // Return the floor index where LR is. Return -1 if LR feet are not on a floor
  property CurrentFloor: integer read GetCurrentFloor write SetCurrentFloor;
end;

TLavaDrop = class(TSprite)
  constructor Create;
end;

TFallingRock = class(TSprite)
  class var FRockCount: integer;
  constructor Create;
  procedure Update(const aElapsedTime: single); override;
end;

TPanelExit = class(TSprite)
private
  FExitToTheRight: boolean;
public
  constructor Create(aX: single; aFloorIndex: integer; aExitToTheRight: boolean);
  procedure Update(const aElapsedTime: single); override;
end;

TLadderBase = class(TSprite)
  AboveLadder,              // NIL no ladder above
  BelowLadder: TLadderBase; // NIL = no ladder below
  FloorIndex: integer;
  procedure Update(const aElapsedTime: single); override;
  function LRCanWalkToLeft: boolean;
  function LRCanWalkToRight: boolean;
  function LRCanClimb: boolean;
  function LRCanClimbDown: boolean;
end;

TLadderTop = class(TLadderBase)
  constructor Create(aX: single; aFloorIndex, aLadderBelowCount: integer);
end;

TLadder = class(TLadderBase)
  constructor Create(aX: single; aFloorIndex: integer);
end;

TRepulseSide = (rsToTheLeft, rsToTheRight, rsBothSide);
TIronBlock = class(TSprite)
private
  FRepulseSide: TRepulseSide;
public
  constructor Create(aX: single; aFloorIndex, aStackingCount: integer; aRepulseSide: TRepulseSide);
  constructor Create(aX, aY: single; aStackingCount: integer; aRepulseSide: TRepulseSide);
  constructor Create(aX, aY: single; aRepulseSide: TRepulseSide);
  procedure Update(const aElapsedTime: single); override;
end;

TGroundLarge = class(TTiledSprite)
  constructor Create(aX: single; aFloorIndex: integer);
  constructor Create(aX, aY: single);
end;

TCeilling = class(TTiledSprite)
  constructor Create(aX: single);
end;

TBGWall = class(TTiledSprite)
  constructor Create(aX, aY: single);
end;

TPillar = class(TSprite)
  class var FAlternateTexture: boolean;
  constructor Create(aX: single; aFloorIndex, aLayerIndex: integer);
end;

TFootSwitch = class(TSprite)
  constructor Create(aX: single; aFloorIndex: integer);
  procedure Update(const aElapsedTime: single); override;
end;

TScannerMode = (smRightSwingDown,         // start scanning to right half circle down
                smLeftSwingDown,        // start scanning to left half circle down
                smRightSwingDownWithFeet, // start scanning to right half circle down,
                                          // and scan feet on previous floor
                smLeftSwingDownWithFeet,  // start scanning to left half circle down,
                                          // and scan feet on previous floor
                smContinuousRotateCW,
                smContinuousRotateCCW);
TPillarWithScanner = class(TPillar)
private
  FScannerBody, FBeam: TSprite;
  FBeamTopRight, FBeamBottomRight, FBeamBottomLeft, FBeamTopLeft: TPointF;
  FLRIsCaught: boolean;
  FsndScanning: TALSSound;
public
  constructor Create(aX: single; aFloorIndex, aPillarLayerIndex: integer; aScannerMode: TScannerMode);
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

TWatchRoom = class(TSpriteContainer)
private type TWatchRoomState=(wrsIdle, wrsPatrolling, wrsAlert);
private
  FState: TWatchRoomState;
  FWolf: TWolf;
  FWalkingXMin, FWalkingXMax: single; // wolf walk in this range
  FCheckXMin, FCheckXMax: single; // when wolf X is in this range, we can do the test if it see LR
  FAlarmGlowLocation: TPointF;
  FFloorIndex: integer;
  procedure SetState(aValue: TWatchRoomState);
public
  constructor Create(aLeftX: single; aFloorIndex: integer);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

TLava = class(TDeformationGrid)
  class var BoilingVolume: single;
  constructor Create(aX, aY: single);
  procedure Update(const aElapsedTime: single); override;
end;

TPipeElbow = class(TSprite)
  constructor Create(aX, aY: single; aLayerIndex: integer);
end;

TVerticalPipe = class(TSprite)
  constructor Create(aX, aY: single; aLayerIndex: integer);
end;

TPipeLeft = class(TSprite)
  constructor Create(aX, aY: single; aLayerIndex: integer);
end;

TPipeVacuum = class(TSprite)
  constructor Create(aX, aY: single; aLayerIndex: integer);
end;

TLavaFallingInRobotConstructor = class(TSpriteContainer)
private
  FLayerIndex: integer;
  FTimeAccu, FEmitterWidth, FYTarget, FWidthCoeff: single;
  FTimeToNewBall, FMoveTime: TFParam;
public
  constructor Create(aCenterX, aCenterY: single; aLayerIndex: integer);
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure SetNormalFlow; virtual;
  procedure SetNormalFlowToGround;
  procedure SetMaximumFlow; virtual;

  procedure SetNormalFlowToTargetY(aY: single); // use without robot constructor
end;

TLavaForVacuum = class(TLavaFallingInRobotConstructor)
  procedure SetNormalFlow; override;
  procedure SetMaximumFlow; override;
end;

TWallWithDigicode = class(TSprite)
private
  FDigicode: TSprite;
  sceBlink: TIDScenario;
  FEnabled: boolean;
public
  constructor Create(aX, aBottomY: single; aLayerIndex: integer);
  procedure Update(const aElapsedTime: single); override;
  procedure Disable;
end;

TKeySprite = class(TSpriteThatGoInInventory)
  constructor Create;
end;

TSDCardSprite = class(TSpriteThatGoInInventory)
  constructor Create;
end;

TPropulsorSprite = class(TSpriteThatGoInInventory)
  constructor Create;
end;

{ TInventoryOnScreen }

TInventoryOnScreen = class(TInGameInventoryPanel)
private
  FKey: TUIKeyMetalCounter;
  FSDCardGreen: TUISDCardGreen;
  FDorsalThruster: TUIDorsalThruster;
public
  procedure AddKey;
  procedure RemoveKey(aCount: integer);
  procedure AddGreenSDCard;
  procedure RemoveGreenSDCard;
  procedure AddDorsalThruster;

  function KeyCount: integer;
  function HaveGreenSDCard: boolean;
  function HaveDorsalThruster: boolean;
end;


var FAtlas: TOGLCTextureAtlas;
    texPillar1, texPillar2,
    texGroundLarge, {texGroundMedium, texGroundLeft, texGroundRight,}
    texBGCeilling, texBGWall, texPanelExit, texRockMedium, texRockSmall,
    texIronBrick,
    texLadderTop, texLadder,
    texLavaLarge, texLavaBall,
    texPumpPipeElbow, texPumpVacuum, texPumpVerticalPipe,
    texScannerDevice, texScannerBeam, texFootSwitch,
    texWall, texHalfWall, texDigicode
    : PTexture;
    FFontText: TTexturedFont;
    FLR: TLRCustom;
    sndAlarm, sndEmergencyAlarm: TALSSound;
    FRobotConstructor: TLittleRobotConstructor;
    FLavaFallingInMachine: TLavaFallingInRobotConstructor;
    FLavaForVacuum: TLavaForVacuum;
    FLadderEmergency: TLadderTop;
    FComputer: TUsableComputer; //TComputer;
    FPump: TPump;
    FDigicode: TWallWithDigicode;
    FCrateHandledByLR: TUsableCrateThatContainObject;
    FInGameinventory: TInventoryOnScreen;

procedure ResetVariables;
begin
  sndAlarm := NIL; sndEmergencyAlarm := NIL;
  FRobotConstructor := NIL;
  FLavaFallingInMachine := NIL;
  FLavaForVacuum := NIL;
  FLadderEmergency := NIL;
  FComputer := NIL;
  FPump := NIL;
  FDigicode := NIL;
  FCrateHandledByLR := NIL;
  FInGameinventory := NIL;
end;

procedure PlayAlarmLRCaught;
begin
  if sndAlarm <> NIL then exit;
  sndAlarm := Audio.AddSound('alert.ogg');
  sndAlarm.Loop := True;
  sndAlarm.Volume.Value := 0.6;
  sndAlarm.Play(True);
end;

function AlarmIsAlreadyStarted: boolean;
begin
  Result := sndAlarm <> NIL;
end;

{ TInventoryOnScreen }

procedure TInventoryOnScreen.AddKey;
begin
  if FKey = NIL then begin
    FKey := TUIKeyMetalCounter.Create;
    AddItem(FKey);
    FKey.Count := 1;
  end else FKey.Count := FKey.Count + 1;
end;

procedure TInventoryOnScreen.RemoveKey(aCount: integer);
begin
  RemoveItem(FKey, aCount);
end;

procedure TInventoryOnScreen.AddGreenSDCard;
begin
  if FSDCardGreen = NIL then begin
    FSDCardGreen := TUISDCardGreen.Create;
    FInGameinventory.AddItem(FSDCardGreen);
  end;
end;

procedure TInventoryOnScreen.RemoveGreenSDCard;
begin
  RemoveItem(FSDCardGreen, 1);
end;

procedure TInventoryOnScreen.AddDorsalThruster;
begin
  if FDorsalThruster = NIL then begin
    FDorsalThruster := TUIDorsalThruster.Create;
    FInGameinventory.AddItem(FDorsalThruster);
  end;
end;

function TInventoryOnScreen.KeyCount: integer;
begin
  if FKey <> NIL then Result := FKey.Count
    else Result := 0;
end;

function TInventoryOnScreen.HaveGreenSDCard: boolean;
begin
  Result := FSDCardGreen <> NIL;
end;

function TInventoryOnScreen.HaveDorsalThruster: boolean;
begin
  Result := FDorsalThruster <> NIL;
end;

{ TPropulsorSprite }

constructor TPropulsorSprite.Create;
var p1, p2: TPointF;
begin
  p1 := FLR.GetXY+PointF(0,-FLR.DeltaYToTop) + ScreenGameVolcanoInner.FCamera.LookAt.Value;
  p2 := FInGameinventory.GetXY+PointF(FInGameinventory.Width*0.5, FInGameinventory.Height*0.5);
  p2 := ScreenGameVolcanoInner.FCamera.WorldToControlF(p2);
  inherited Create(texIconDorsalThruster, LAYER_GAMEUI, p1, p2);
end;

{ TSDCardSprite }

constructor TSDCardSprite.Create;
var p1, p2: TPointF;
begin
  p1 := FLR.GetXY+PointF(0,-FLR.DeltaYToTop) + ScreenGameVolcanoInner.FCamera.LookAt.Value;
  p2 := FInGameinventory.GetXY+PointF(FInGameinventory.Width*0.5, FInGameinventory.Height*0.5);
  p2 := ScreenGameVolcanoInner.FCamera.WorldToControlF(p2);
  inherited Create(texSDCardGreen, LAYER_GAMEUI, p1, p2);
end;

{ TKeySprite }

constructor TKeySprite.Create;
var p1, p2: TPointF;
begin
  p1 := FLR.GetXY+PointF(0,-FLR.DeltaYToTop) + ScreenGameVolcanoInner.FCamera.LookAt.Value;
  p2 := FInGameinventory.GetXY+PointF(FInGameinventory.Width*0.5, FInGameinventory.Height*0.5);
  p2 := ScreenGameVolcanoInner.FCamera.WorldToControlF(p2);
  inherited Create(texKeyMetal, LAYER_GAMEUI, p1, p2);
end;

{ TFallingRock }

constructor TFallingRock.Create;
var side: boolean;
begin
  if Random > 0.5 then inherited create(texRockMedium, False)
    else inherited create(texRockSmall, False);
  FScene.Add(Self, LAYER_FXANIM);
  inc(FRockCount);

  // we avoid LR
  side := Random > 0.5;
  repeat
    if side then X.Value := ScaleW(388)+Random(ScaleW(960)-ScaleW(388))
      else X.Value := ScaleW(1356)+Random(ScaleW(2024)-ScaleW(1356));
  until not InRange(X.Value, FLR.X.Value-FLR.BodyWidth*1.5, FLR.X.Value+FLR.BodyWidth*1.5);
  Y.Value := FLR.Y.Value-ScreenGameVolcanoInner.FCamera.GetViewRect.Height;
  Y.ChangeTo(FloorToY(9)+PPIScale(5)-Height, 4.0, idcStartSlowEndFast);
  Angle.Value := 360*3+360*Random*3;
  Angle.ChangeTo(Random*90-45, 4.0);
end;

procedure TFallingRock.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  // limit the number of rocks on the ground
  if (FRockCount > 50) and (Y.State = psNO_CHANGE) then begin
    Opacity.ChangeTo(0, 1.0);
    KillDefered(1.0);
    dec(FRockCount);
  end;
end;

{ TLavaDrop }

constructor TLavaDrop.Create;
var side: boolean;
begin
  inherited Create(texLavaBall, False);
  FScene.Add(Self, LAYER_FXANIM);
  // we avoid LR
  side := Random > 0.5;
  repeat
    if side then begin
      X.Value := ScaleW(388)+Random(ScaleW(960)-ScaleW(388));
      Y.Value := FloorToY(2);
    end else begin
      X.Value := ScaleW(1356)+Random(ScaleW(2024)-ScaleW(1356));
      Y.Value := ScaleH(762);
    end;
  until not InRange(X.Value, FLR.X.Value-FLR.BodyWidth*1.5, FLR.X.Value+FLR.BodyWidth*1.5);
  Y.ChangeTo(FloorToY(9), 3.0, idcDrop); //idcStartSlowEndFast);
  KillDefered(3.0);
  Angle.AddConstant(Random*20);
end;

{ TWallWithDigicode }

constructor TWallWithDigicode.Create(aX, aBottomY: single; aLayerIndex: integer);
begin
  inherited Create(texWall, False);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aBottomY-texWall^.FrameHeight);

  FDigicode := TSprite.Create(texDigicode, False);
  AddChild(FDigicode, 0);
  FDigicode.CenterOnParent;
  sceBlink := FDigicode.AddScenario(ScenarioYellowBlink); //ScenarioWhiteBlink);

  FEnabled := True;
end;

procedure TWallWithDigicode.Update(const aElapsedTime: single);
var d: single;
begin
  inherited Update(aElapsedTime);

  // check if LR is near the digicode
  if not FEnabled then exit;
  d := Distance(Center, FLR.GetXY);
  if (d < texDigicode^.FrameWidth*2) and (d < FLR.DistanceToObjectToHandle) then begin
    if not FDigicode.ScenarioIsPlaying(sceBlink) then
      FDigicode.PlayScenario(sceBlink, True);
    FLR.ObjectToHandle := Self;
    FLR.DistanceToObjectToHandle := d;
  end else begin
    FDigicode.StopAllScenario;
    FDigicode.Tint.Alpha.ChangeTo(0, 0.7);
  end;

end;

procedure TWallWithDigicode.Disable;
begin
  FEnabled := False;
  FDigicode.StopAllScenario;
  FDigicode.Tint.Alpha.ChangeTo(0, 0.7);
end;

{ TLavaForVacuum }

procedure TLavaForVacuum.SetNormalFlow;
begin
  FEmitterWidth := texPumpVacuum^.FrameWidth*0.8;
  FTimeToNewBall.Value := 1/40;
  FYTarget := ScaleH(679);
  FWidthCoeff := 0.3;
  FMoveTime.Value := 0.5;
end;

procedure TLavaForVacuum.SetMaximumFlow;
begin
  FEmitterWidth := texPumpVacuum^.FrameWidth;
  FTimeToNewBall.Value := 1/100;
  FYTarget := ScaleH(679);
  FWidthCoeff := 0.3;
  FMoveTime.Value := 0.25;
end;

{ TLavaFallingInRobotConstructor }

constructor TLavaFallingInRobotConstructor.Create(aCenterX, aCenterY: single; aLayerIndex: integer);
begin
  inherited Create(FScene);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aCenterX, aCenterY);
  FLayerIndex := aLayerIndex;

  FTimeAccu := 0;
  FTimeToNewBall := TFParam.Create;
  FMoveTime := TFParam.Create;
  SetNormalFlow;
end;

destructor TLavaFallingInRobotConstructor.Destroy;
begin
  FTimeToNewBall.Free;
  FMoveTime.Free;
  inherited Destroy;
end;

procedure TLavaFallingInRobotConstructor.Update(const aElapsedTime: single);
var o: TSprite;
begin
  inherited Update(aElapsedTime);

  FTimeToNewBall.OnElapse(aElapsedTime);
  FMoveTime.OnElapse(aElapsedTime);

  // lava balls creation
  FTimeAccu := FTimeAccu + aElapsedTime;
  if FTimeAccu >= FTimeToNewBall.Value then begin
    repeat
      FTimeAccu := FTimeAccu - FTimeToNewBall.Value;
      o := TSprite.Create(texLavaBall, False);
      FScene.Insert(0, o, FLayerIndex);
      //FScene.Add(o, FLayerIndex);
      o.CenterX := X.Value-FEmitterWidth*0.5+FEmitterWidth*random;
      o.CenterY := Y.Value;
      o.MoveTo(X.Value-FEmitterWidth*FWidthCoeff*0.5+FEmitterWidth*FWidthCoeff*random, FYTarget, FMoveTime.Value);
      o.KillDefered(FMoveTime.Value);
    until FTimeAccu < FTimeToNewBall.Value;
  end;
end;

procedure TLavaFallingInRobotConstructor.SetNormalFlow;
begin
  FEmitterWidth := texPumpVerticalPipe^.FrameWidth*0.6;
  FTimeToNewBall.Value := 1/40;
  FYTarget := ScaleH(435);
  FWidthCoeff := 0.0;
  FMoveTime.Value := 0.5;
end;

procedure TLavaFallingInRobotConstructor.SetNormalFlowToGround;
begin
  FEmitterWidth := texPumpVerticalPipe^.FrameWidth*0.6;
  FTimeToNewBall.Value := 1/40;
  FYTarget := FloorToY(2);
  FWidthCoeff := 1.0;
  FMoveTime.Value := 1.0;
end;

procedure TLavaFallingInRobotConstructor.SetMaximumFlow;
begin
  FEmitterWidth := texPumpVerticalPipe^.FrameWidth*0.6;
  FTimeToNewBall.ChangeTo(1/300, 5.0);
  FYTarget := FloorToY(2);
  FWidthCoeff := 10.0;
  FMoveTime.ChangeTo(0.75, 5.0);
end;

procedure TLavaFallingInRobotConstructor.SetNormalFlowToTargetY(aY: single);
begin
  FEmitterWidth := texIronBrick^.FrameWidth;
  FTimeToNewBall.Value := 1/60;
  FYTarget := aY;
  FWidthCoeff := 1.0;
  FMoveTime.Value := 0.5;
end;

{ TPipeLeft }

constructor TPipeLeft.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(texPumpVerticalPipe, False);
  FScene.Add(Self, aLayerIndex);
  Angle.Value := -90;
  SetCoordinate(aX+texPumpVerticalPipe^.FrameHeight*0.5-texPumpVerticalPipe^.FrameWidth*0.5,
                aY+texPumpVerticalPipe^.FrameWidth*0.5-texPumpVerticalPipe^.FrameHeight*0.5);
end;

{ TPipeVacuum }

constructor TPipeVacuum.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(texPumpVacuum, False);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
end;

{ TVerticalPipe }

constructor TVerticalPipe.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(texPumpVerticalPipe, False);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
end;

{ TPipeElbow }

constructor TPipeElbow.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(texPumpPipeElbow, False);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
end;

{ TPanelExit }

constructor TPanelExit.Create(aX: single; aFloorIndex: integer; aExitToTheRight: boolean);
begin
  inherited Create(texPanelExit, False);
  FScene.Add(Self, LAYER_GROUND);
  X.Value := aX;
  BottomY := FloorToY(aFloorIndex);
  FlipH := not aExitToTheRight;
  FExitToTheRight := aExitToTheRight;
end;

procedure TPanelExit.Update(const aElapsedTime: single);
var r: TRectF;
begin
  inherited Update(aElapsedTime);
  // check if LR collide the panel -> game win
  r := GetRectAreaInParentSpace;
  if FLR.CheckCollisionWith(r) then begin
    ScreenGameVolcanoInner.ExitToTheRight := FExitToTheRight;
    ScreenGameVolcanoInner.GameState := gsLRWin;
  end;
end;

{ TBGWall }

constructor TBGWall.Create(aX, aY: single);
begin
  inherited Create(texBGWall, False);
  FScene.Add(Self, LAYER_BG3);
  SetCoordinate(aX, aY);
  Opacity.Value := 130;
end;

{ TIronBlock }

constructor TIronBlock.Create(aX: single; aFloorIndex, aStackingCount: integer; aRepulseSide: TRepulseSide);
var i: Integer;
  yy: single;
begin
  inherited Create(texIronBrick, False);
  FScene.Add(Self, LAYER_GROUND);
  X.Value := aX;
  BottomY := FloorToY(aFloorIndex) + texGroundLarge^.FrameHeight*0.3;
  FRepulseSide := aRepulseSide;

  yy := Y.Value-Height;
  for i:=1 to aStackingCount-1 do begin
    TIronBlock.Create(aX, yy, 1, aRepulseSide);
    yy := yy - Height;
  end;
end;

constructor TIronBlock.Create(aX, aY: single; aStackingCount: integer; aRepulseSide: TRepulseSide);
var i: integer;
  yy: single;
begin
  inherited Create(texIronBrick, False);
  FScene.Add(Self, LAYER_GROUND);
  SetCoordinate(aX, aY);
  FRepulseSide := aRepulseSide;

  yy := aY - Height;
  for i:=1 to aStackingCount-1 do begin
    TIronBlock.Create(aX, yy, aRepulseSide);
    yy := yy - Height;
  end;
end;

constructor TIronBlock.Create(aX, aY: single; aRepulseSide: TRepulseSide);
begin
  inherited Create(texIronBrick, False);
  FScene.Add(Self, LAYER_GROUND);
  SetCoordinate(aX, aY);
  FRepulseSide := aRepulseSide;
end;

procedure TIronBlock.Update(const aElapsedTime: single);
var rLR: TRectF;
  x1, x2, w: single;
begin
  inherited Update(aElapsedTime);

  // stops LR if she hurt this brick
  rLR := FLR.GetBodyRect;
  if not InRange(rLR.Top, Y.Value, BottomY) and
     not InRange(rLR.Bottom, Y.Value, BottomY) then exit;

  w := Width*0.5;
  if FRepulseSide = rsBothSide then begin
    x1 := X.Value-w;
    x2 := RightX+w;
    if InRange(rLR.Left, x1, x2) or InRange(rLR.Right, x1, x2) then
      if rLR.Left+(rLR.Right-rLR.Left)*0.5 < X.Value+w then begin
        if FLR.RightX > x1 then FLR.RightX := x1;
        if FLR.Speed.x.Value > 0 then FLR.Speed.x.Value := 0;
      end else begin
        if FLR.X.Value < x2 then FLR.X.Value := x2;
        if FLR.Speed.x.Value < 0 then FLR.Speed.x.Value := 0;
      end;
    exit;
  end;

  if FRepulseSide = rsToTheLeft then begin
    x1 := X.Value-w;
    x2 := RightX;
  end else begin
    x1 := X.Value;
    x2 := RightX+w;
  end;

  if InRange(rLR.Left, x1, x2) or
     InRange(rLR.Right, x1, x2) then
      if FRepulseSide = rsToTheLeft then begin
        if FLR.RightX > x1 then FLR.RightX := x1;
        if FLR.Speed.x.Value > 0 then FLR.Speed.x.Value := 0;
       end else begin
         if FLR.X.Value < x2 then FLR.X.Value := x2;
         if FLR.Speed.x.Value < 0 then FLR.Speed.x.Value := 0;
       end;
end;

{ TLadderBase }

procedure TLadderBase.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if FLR.LadderInUse <> NIL then exit; // a ladder is already in use

  // check if LR can use this ladder
  if ((FLR.X.Value - FLR.BodyWidth*0.5 > X.Value+Width*0.0) and
     (FLR.X.Value + FLR.BodyWidth*0.5 < RightX-Width*0.0) and
     InRange(FLR.GetYBottom, Y.Value, BottomY)) then
      FLR.LadderInUse := Self;
end;

function TLadderBase.LRCanWalkToLeft: boolean;
begin
  Result := FLR.CurrentFloor = FloorIndex;
end;

function TLadderBase.LRCanWalkToRight: boolean;
begin
  Result := FLR.CurrentFloor = FloorIndex;
end;

function TLadderBase.LRCanClimb: boolean;
begin
  if Self is TLadderTop then exit(False);

  if FLR.CurrentFloor = FloorIndex then exit(AboveLadder <> NIL);
  Result := InRange(FLR.GetYBottom, Y.Value, BottomY);
end;

function TLadderBase.LRCanClimbDown: boolean;
begin
  if FLR.CurrentFloor = FloorIndex then exit(BelowLadder <> NIL);
  Result := InRange(FLR.GetYBottom, Y.Value, BottomY);
end;

{ TPillarWithScanner }

constructor TPillarWithScanner.Create(aX: single; aFloorIndex, aPillarLayerIndex: integer;
  aScannerMode: TScannerMode);
begin
  inherited Create(aX, aFloorIndex, aPillarLayerIndex);

  FScannerBody := TSprite.Create(texScannerDevice, False);
  FScene.Add(FScannerBody, LAYER_ARROW);
  FScannerBody.SetCenterCoordinate(CenterX, Y.Value+Height*0.28);

  FBeam := TSprite.Create(texScannerBeam, False);
  FScannerBody.AddChild(FBeam, -1);
  FBeam.CenterX := FScannerBody.Width * 0.5;
  FBeam.Y.Value := FScannerBody.Height * 0.9;
  FBeam.Pivot := PointF(0.5, 0);

  // sets the points for collision lines
  FBeamTopLeft := PointF((FBeam.Width-FBeam.Width*0.094)*0.5, 0);
  FBeamTopRight := PointF(FBeamTopLeft.x-FBeam.Width*0.094, 0);
  FBeamBottomRight := PointF(FBeam.Width, FBeam.Height);
  FBeamBottomLeft := PointF(0, FBeam.Height);

  FsndScanning := Audio.AddSound('scanner-samsung-c460-ms.ogg');
  FsndScanning.Loop := True;
  FsndScanning.PositionRelativeToListener := False;
  FsndScanning.DistanceModel := AL_EXPONENT_DISTANCE; // AL_INVERSE_DISTANCE_CLAMPED
  FsndScanning.Attenuation3D(FBeam.Height*0.6, FBeam.Height*3, 2.0, 1.0);
  FsndScanning.Position3D(Center.x, Center.y, -1.0);

  case aScannerMode of
    smRightSwingDownWithFeet: PostMessage(0);
    smLeftSwingDownWithFeet: PostMessage(10);
    smContinuousRotateCW: PostMessage(20);
    smContinuousRotateCCW: PostMessage(30);
    smRightSwingDown: PostMessage(40);
    smLeftSwingDown: PostMessage(50);
  end;
end;

destructor TPillarWithScanner.Destroy;
begin
  FsndScanning.FadeOutThenKill(1.0);
  inherited Destroy;
end;

procedure TPillarWithScanner.Update(const aElapsedTime: single);
var m: TOGLCMatrix;
    collide: boolean;
    procedure CheckLineCollisionWithLR(aPt1, aPt2: TPointF);
    begin
      aPt1 := m.Transform(aPt1);
      aPt2 := m.Transform(aPt2);
      collide := FLR.CheckCollisionWithLine(aPt1, aPt2);
    end;
begin
  inherited Update(aElapsedTime);

  if FLRIsCaught then exit;
  if FLRIsInvisible then exit;

  if FBeam.Visible then begin
    // check if the beam touch LR
    m := FBeam.GetMatrixSurfaceSpaceToScene;

    collide := False;
    CheckLineCollisionWithLR(FBeamTopRight, FBeamBottomRight);
    if not collide then CheckLineCollisionWithLR(FBeamBottomLeft, FBeamBottomRight);
    if not collide then CheckLineCollisionWithLR(FBeamTopLeft, FBeamBottomLeft);
    if collide then begin
      if ScreenGameVolcanoInner.GameState <> gsLRCaptured then begin
        ClearMessageList; // stop anim scanner
        FBeam.Visible := True;
        FScannerBody.Angle.Value := FScannerBody.Angle.Value; // stops any rotation
        FBeam.Tint.Value := BGRA(255,255,0);
        ScreenGameVolcanoInner.GameState := gsLRCaptured;
        FLRIsCaught := True;
      end;
    end else FBeam.Tint.Alpha.Value := 0;
  end;
end;

procedure TPillarWithScanner.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // scanner beam: rotate to right, stop, rotate to left, stop, loop. Scan feet on previous floor!
    0: begin  // moves to right
      FsndScanning.Play(True);
      FScannerBody.Angle.ChangeTo(-100, 3.0, idcSinusoid);
      PostMessage(1, 3.0);
    end;
    1: begin  // stop
      FsndScanning.Stop;
      FBeam.Visible := False;
      PostMessage(2, 2.5);
    end;
    2: begin  // re-appears
      FBeam.Visible := True;
      PostMessage(3, 1.0);
    end;
    3: begin  // move to left
      FsndScanning.Play(True);
      FScannerBody.Angle.ChangeTo(100, 3.0, idcSinusoid);
      PostMessage(4, 3.0);
    end;
    4: begin  // stop
      FsndScanning.Stop;
      FBeam.Visible := False;
      PostMessage(5, 2.5);
    end;
    5: begin  // re-appears
      FBeam.Visible := True;
      PostMessage(0, 1.0);
    end;

    // scanner beam: rotate to left, stop, rotate to right, stop, loop. Scan feet on previous floor!
    10: begin  // moves to right
      FsndScanning.Play(True);
      FScannerBody.Angle.ChangeTo(100, 3.0, idcSinusoid);
      PostMessage(11, 3.0);
    end;
    11: begin  // stop
      FsndScanning.Stop;
      FBeam.Visible := False;
      PostMessage(12, 2.5);
    end;
    12: begin  // re-appears
      FBeam.Visible := True;
      PostMessage(13, 1.0);
    end;
    13: begin  // move to left
      FsndScanning.Play(True);
      FScannerBody.Angle.ChangeTo(-100, 3.0, idcSinusoid);
      PostMessage(14, 3.0);
    end;
    14: begin  // stop
      FsndScanning.Stop;
      FBeam.Visible := False;
      PostMessage(15, 2.5);
    end;
    15: begin  // re-appears
      FBeam.Visible := True;
      PostMessage(10, 1.0);
    end;

    // smContinuousRotateCW
    20: begin
      FsndScanning.Play(True);
      FScannerBody.Angle.AddConstant(360/6);
    end;

    // smContinuousRotateCCW
    30: begin
      FsndScanning.Play(True);
      FScannerBody.Angle.AddConstant(-360/6);
    end;

    // smRightSwingDown without feet on previous floor
    40: begin  // moves to right
      FsndScanning.Play(True);
      FScannerBody.Angle.ChangeTo(-80, 3.0, idcSinusoid);
      PostMessage(41, 3.0);
    end;
    41: begin  // stop
      FsndScanning.Stop;
      FBeam.Visible := False;
      PostMessage(42, 3.5);
    end;
    42: begin  // re-appears
      FBeam.Visible := True;
      PostMessage(43, 1.0);
    end;
    43: begin  // move to left
      FsndScanning.Play(True);
      FScannerBody.Angle.ChangeTo(80, 3.0, idcSinusoid);
      PostMessage(44, 3.0);
    end;
    44: begin  // stop
      FsndScanning.Stop;
      FBeam.Visible := False;
      PostMessage(45, 3.5);
    end;
    45: begin  // re-appears
      FBeam.Visible := True;
      PostMessage(40, 1.0);
    end;

    // smLeftSwingDown without feet on previous floor
    50: begin  // moves to right
      FsndScanning.Play(True);
      FScannerBody.Angle.ChangeTo(80, 3.0, idcSinusoid);
      PostMessage(51, 3.0);
    end;
    51: begin  // stop
      FsndScanning.Stop;
      FBeam.Visible := False;
      PostMessage(52, 3.5);
    end;
    52: begin  // re-appears
      FBeam.Visible := True;
      PostMessage(53, 1.0);
    end;
    53: begin  // move to left
      FsndScanning.Play(True);
      FScannerBody.Angle.ChangeTo(-80, 3.0, idcSinusoid);
      PostMessage(54, 3.0);
    end;
    54: begin  // stop
      FsndScanning.Stop;
      FBeam.Visible := False;
      PostMessage(55, 3.5);
    end;
    55: begin  // re-appears
      FBeam.Visible := True;
      PostMessage(50, 1.0);
    end;

  end;
end;

{ TLadder }

constructor TLadder.Create(aX: single; aFloorIndex: integer);
begin
  inherited Create(texLadder, False);
  FScene.Add(Self, LAYER_GROUND);
  X.Value := aX;
  //Y.Value := aY;
  BottomY := FloorToY(aFloorIndex)+texGroundLarge^.FrameHeight*0.3;
  FloorIndex := aFloorIndex;
end;

{ TLadderTop }

constructor TLadderTop.Create(aX: single; aFloorIndex, aLadderBelowCount: integer);
var o, above: TLadderBase;
  i: Integer;
begin
  inherited Create(texLadderTop, False);
  FScene.Add(Self, LAYER_GROUND);
  X.Value := aX;
  BottomY := FloorToY(aFloorIndex) + texGroundLarge^.FrameHeight*0.3;
  FloorIndex := aFloorIndex;

  AboveLadder := NIL;
  above := Self;
  for i:=1 to aLadderBelowCount do begin
    o := TLadder.Create(aX, aFloorIndex+i);
    o.AboveLadder := above;
    above.BelowLadder := o;
    above := o;
  end;
end;

{ TLRCustom }

function TLRCustom.GetCurrentFloor: integer;
var yy: single;
begin
  yy := GetYBottom - DeltaFloorToCharacterFeet;
  Result := YToFloor(yy);
end;

procedure TLRCustom.SetCurrentFloor(AValue: integer);
begin
  Y.Value := FloorToY(AValue)-FLR.DeltaYToBottom+DeltaFloorToCharacterFeet;
end;

{ TGroundLarge }

constructor TGroundLarge.Create(aX: single; aFloorIndex: integer);
begin
  inherited Create(texGroundLarge, False);
  FScene.Add(Self, LAYER_BG1);
  SetCoordinate(aX, FloorToY(aFloorIndex));
end;

constructor TGroundLarge.Create(aX, aY: single);
begin
  inherited Create(texGroundLarge, False);
  FScene.Add(Self, LAYER_BG1);
  SetCoordinate(aX, aY);
end;

{ TCeilling }

constructor TCeilling.Create(aX: single);
begin
  inherited Create(texBGCeilling, False);
  FScene.Add(Self, LAYER_BG1);
  SetCoordinate(aX, 0);
end;

{ TWatchRoom }

procedure TWatchRoom.SetState(aValue: TWatchRoomState);
begin
  if FState = aValue then exit;
  FState := aValue;

  case aValue of
    wrsAlert: begin
      FWolf.State := wsIdle;
      FWolf.FlipH := FLR.X.Value > FWolf.X.Value+X.Value;
      PostMessage(100);
    end;
  end;
end;

constructor TWatchRoom.Create(aLeftX: single; aFloorIndex: integer);
var o1, o2, p, wallBottomLeft, wallBottomRight: TSprite;
begin
  inherited create(FScene);
  FScene.Add(Self, LAYER_BG2);
  SetCoordinate(aLeftX, FloorToY(aFloorIndex)+ScaleH(6)-texPillar1^.FrameHeight);
  FFloorIndex := aFloorIndex;

  // pillar left
  TPillar.FAlternateTexture := not TPillar.FAlternateTexture;
  if TPillar.FAlternateTexture then p := TSprite.Create(texPillar1, False)
    else p := TSprite.Create(texPillar2, False);
  AddChild(p, -1);
  p.SetCoordinate(0, 0);

  // wall bottom left
  wallBottomLeft := TSprite.Create(texWall, False);
  AddChild(wallBottomLeft, 0);
  wallBottomLeft.X.Value := p.Width * 0.5;
  wallBottomLeft.BottomY := p.Height*0.985;
  // wall top left
  o1 := TSprite.Create(texWall, False);
  AddChild(o1, 0);
  o1.X.Value := wallBottomLeft.X.Value;
  o1.BottomY := wallBottomLeft.Y.Value;
  // half wall top
  o2 := TSprite.Create(texHalfWall, False);
  AddChild(o2, 0);
  o2.X.Value := o1.RightX;
  o2.Y.Value := o1.Y.Value;
  // half wall bottom
  o2 := TSprite.Create(texHalfWall, False);
  AddChild(o2, 0);
  o2.X.Value := o1.RightX;
  o2.BottomY := wallBottomLeft.BottomY;
  // wall bottom right
  wallBottomRight := TSprite.Create(texWall, False);
  AddChild(wallBottomRight, 0);
  wallBottomRight.X.Value := o2.RightX;
  wallBottomRight.BottomY := o2.BottomY;
  // wall top right
  o1 := TSprite.Create(texWall, False);
  AddChild(o1, 0);
  o1.X.Value := o2.RightX;
  o1.BottomY := wallBottomRight.Y.Value;
  FAlarmGlowLocation := PointF(o1.X.Value + o1.Width*0.75, o1.Y.Value + o1.Height*0.25);
  // pillar right
  TPillar.FAlternateTexture := not TPillar.FAlternateTexture;
  if TPillar.FAlternateTexture then p := TSprite.Create(texPillar1, False)
    else p := TSprite.Create(texPillar2, False);
  AddChild(p, -1);
  p.CenterX := o1.RightX;
  p.Y.Value := 0;
  // wolf gardian
  FWolf := TWolf.Create(False, -1);
  AddChild(FWolf, -2);
  FWolf.Y.Value := o2.Y.Value+o2.Height*0.6 - FWolf.DeltaYToBottom;
  FWolf.CenterX := o2.CenterX;

  FWalkingXMin := wallBottomLeft.X.Value + FWolf.BodyWidth*0.5;
  FWalkingXMax := wallBottomRight.RightX - FWolf.BodyWidth*0.5;

  FCheckXMin := wallBottomLeft.RightX - FWolf.BodyWidth*0.5;
  FCheckXMax := wallBottomRight.X.Value + FWolf.BodyWidth*0.5;

  PostMessage(0); // wolf start walk
  FState := wrsPatrolling;
end;

procedure TWatchRoom.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if FLRIsInvisible then exit;

  if (FState = wrsPatrolling) and (FWolf.X.Value > FCheckXMin) and (FWolf.X.Value < FCheckXMax) then begin
    // check if the wolf see LR
    if InRange(FLR.X.Value, FCheckXMin+X.Value, FCheckXMax+X.Value) and
       (FLR.CurrentFloor = FFloorIndex) then
      SetState(wrsAlert);
  end;
end;

procedure TWatchRoom.ProcessMessage(UserValue: TUserMessageValue);
var glow: TOGLCGlow;
begin
  case UserValue of
    // wolf patrols
    0: begin
      if FState <> wrsPatrolling then exit;
      FWolf.WalkHorizontallyTo(FWalkingXMin, Self, 1, 0);
    end;
    1: begin
      if FState <> wrsPatrolling then exit;
      FWolf.State := wsIdle;
      PostMessage(2, 4.0);
    end;
    2: begin
      if FState <> wrsPatrolling then exit;
      FWolf.WalkHorizontallyTo(FWalkingXMax, Self, 3, 0);
    end;
    3: begin
      if FState <> wrsPatrolling then exit;
      FWolf.State := wsIdle;
      PostMessage(0, 4.0);
    end;

    // alert !
    100: begin     // wolf surprise
      FLR.SetFaceType(lrfNotHappy);
      FWolf.Head.SetMouthSurprise;
      FWolf.RightArm.Angle.Value := 0;
      FWolf.LeftArm.Angle.Value := 0;
      PostMessage(101, 0.75);
    end;
    101: begin    // wolf run to the right
      FWolf.TimeMultiplicator := 0.5;
      FWolf.WalkHorizontallyTo(FWalkingXMax, Self, 102, 0);
    end;
    102: begin    // red glow + alarm sounds
      ScreenGameVolcanoInner.FsndPercuLoop.FadeOutThenKill(1.0);
      ScreenGameVolcanoInner.FsndPercuLoop := NIL;
      glow := TOGLCGlow.Create(FScene, texWall^.FrameWidth*0.25, BGRA(255,0,0), FX_BLEND_NORMAL);
      AddChild(glow, 1);
      glow.SetCenterCoordinate(FAlarmGlowLocation);
      glow.AddAndPlayScenario('Visible TRUE'#10+
                              'Wait 1.0'#10+
                              'Visible FALSE'#10+
                              'Wait 1.0'#10+
                              'Loop');
      PlayAlarmLRCaught;
      FWolf.TimeMultiplicator := 1.0;
      FWolf.State := wsIdle;
      FWolf.WalkHorizontallyTo(FCheckXMin+(FCheckXMax-FCheckXMin)*0.5, Self, 103, 0);
    end;
    103: begin  // wolf come back happy
      FWolf.State := wsWinner;
      FWolf.FlipH := FLR.X.Value > FWolf.X.Value+X.Value;
      PostMessage(104, 2.0);
    end;
    104: begin // back to the map
      FScene.RunScreen(ScreenMap);
    end;
  end;
end;

{ TFootSwitch }

constructor TFootSwitch.Create(aX: single; aFloorIndex: integer);
begin
  inherited Create(texFootSwitch, False);
  FScene.Add(Self, LAYER_FXANIM);
  SetCoordinate(aX, FloorToY(aFloorIndex)+ScaleH(3));
end;

procedure TFootSwitch.Update(const aElapsedTime: single);
var r: TRectF;
begin
  inherited Update(aElapsedTime);

  if FLRIsInvisible then exit;

  // check if LR feet are on the switch
  r.Left := X.Value;
  r.Top := Y.Value + Height*0.25;
  r.Width := Width;
  r.Height := Height*0.5;
  if FLR.BottomFeetCollideWith(r) then begin
    Tint.Value := BGRA(255,255,0);
    if ScreenGameVolcanoInner.GameState <> gsLRCaptured then Audio.PlayUIClick;
    ScreenGameVolcanoInner.GameState := gsLRCaptured;
  end else Tint.Alpha.Value := 0;
end;

{ TPillar }

constructor TPillar.Create(aX: single; aFloorIndex, aLayerIndex: integer);
var tex: PTexture;
begin
  FAlternateTexture := not FAlternateTexture;
  if FAlternateTexture then tex := texPillar1
    else tex := texPillar2;
  inherited Create(tex, False);
  FScene.Add(Self, aLayerIndex);
  X.Value := aX;
  BottomY := FloorToY(aFloorIndex)+ScaleH(6);
end;

{ TLava }

constructor TLava.Create(aX, aY: single);
var pe: TParticleEmitter;
begin
  inherited Create(texLavaLarge, False);
  FScene.Add(Self, LAYER_BG1);
  SetCoordinate(aX, aY);
  SetGrid(2, 8);
  Amplitude.Value := PointF(0.4, 0.25);
  DeformationSpeed.Value := PointF(1.2, 1.0);
  ApplyDeformation(dtTumultuousWater);
  SetDeformationAmountOnRow(2, 0.0);
  SetTimeMultiplicatorOnRow(0, 1+(random*0.5)-0.25);
  SetTimeMultiplicatorOnRow(1, 1+(random*0.5)-0.25);

  pe := TParticleEmitter.Create(FScene);
  pe.LoadFromFile(ParticleFolder+'LavaSmoke.par', FAtlas);
  AddChild(pe, 0);
  pe.SetCoordinate(0, Height*0.75);
  pe.SetEmitterTypeLine(PointF(Width, Height*0.75));
  pe.Update(1.0);  // make some smoke before player see the scene
  pe.Update(1.0);
  pe.Update(1.0);
end;

procedure TLava.Update(const aElapsedTime: single);
var d, vol: single;
begin
  inherited Update(aElapsedTime);
  // compute the distance LR/Self
  d := Distance(PointF(0,FLR.CenterY), PointF(0,CenterY));
  vol := 1-EnsureRange(d/ScreenGameVolcanoInner.ViewHeight, 0, 1);
  if BoilingVolume < vol then BoilingVolume := vol;
end;

{ TScreenGameVolcanoInner }

procedure TScreenGameVolcanoInner.CreateCeilling;
var xx: single;
begin
  xx := 0;
  repeat
    TCeilling.Create(xx);
    xx := xx + texBGCeilling^.FrameWidth;
  until xx >= FViewArea.Right;
end;

procedure TScreenGameVolcanoInner.CreateBGWall;
var xx, yy: single;
begin
  yy := -texBGWall^.FrameHeight*0.5;
  repeat
    xx := -texBGWall^.FrameWidth*0.5;
    repeat
      TBGWall.Create(Trunc(xx), Trunc(yy));
      xx := xx + texBGWall^.FrameWidth-1;
    until xx > FViewArea.Right + texBGWall^.FrameWidth*0.5;
    yy := yy + texBGWall^.FrameHeight-1;
  until yy > FViewArea.Bottom + texBGWall^.FrameHeight;
end;

procedure TScreenGameVolcanoInner.CreateGroundLarge(aX: single; aFloorIndex, aCount: integer);
begin
  if aCount = 0 then exit;
  repeat
    TGroundLarge.Create(Trunc(aX), aFloorIndex);
    aX := aX + texGroundLarge^.FrameWidth-0.5;
    dec(aCount);
  until aCount = 0;
end;

procedure TScreenGameVolcanoInner.CreateGroundLarge2(aX, aY: single; aCount: integer);
begin
  if aCount = 0 then exit;
  repeat
    TGroundLarge.Create(Trunc(aX), aY);
    aX := aX + texGroundLarge^.FrameWidth-0.5;
    dec(aCount);
  until aCount = 0;
end;

procedure TScreenGameVolcanoInner.CreatePillar(const aXs: array of integer;
  aFloorIndex, aLayerIndex: integer; aFullOpaque: boolean);
var i: integer;
begin
  if Length(aXs) = 0 then exit;
  for i:=0 to High(aXs) do begin
    with TPillar.Create(ScaleW(aXs[i]) ,aFloorIndex, aLayerIndex) do
      if not aFullOpaque then Tint.Value := BGRA(0,0,0,100); //Opacity.Value := 65;
  end;
end;

procedure TScreenGameVolcanoInner.CreateLava(aFromX, aToX, aY: single; aFadeIn: boolean);
begin
  repeat
    with TLava.Create(aFromX, aY) do
      if aFadeIn then begin
        Opacity.Value := 0;
        Opacity.ChangeTo(255, 2.0);
      end;
    aFromX := aFromX + texLavaLarge^.FrameWidth*0.75;
  until aFromX > aToX - texLavaLarge^.FrameWidth;
  // force creation of the last to the right
  with TLava.Create(aToX-texLavaLarge^.FrameWidth, aY) do
    if aFadeIn then begin
      Opacity.Value := 0;
      Opacity.ChangeTo(255, 2.0);
    end;
end;

procedure TScreenGameVolcanoInner.CreateLevel(aLevelIndex: integer);
begin
  FCurrentGameLevel := aLevelIndex;
  FViewArea.Left := FScene.Width*0.5;
  FViewArea.Top := FScene.Height*0.5;

  case FCurrentGameLevel of
    1: CreateLevel1;   // discover the machine
    2: CreateLevel2;   //
    3: CreateLevel3;   // found SD card
    4: CreateLevel4;   // found propulsor
    5: CreateLevel5;   // destroy the machine anim
  end;//case

  if PlayerInfo.Volcano.HaveGreenSDCard then FInGameinventory.AddGreenSDCard;
  if PlayerInfo.Volcano.DorsalThruster.Owned then FInGameinventory.AddDorsalThruster;

  FViewHeight := FViewArea.Bottom; // used to compute boiling lava volume
  FViewArea.Right := FViewArea.Right - FScene.Width*0.5;
  FViewArea.Bottom := FViewArea.Bottom - FScene.Height*0.5;
end;

procedure TScreenGameVolcanoInner.CreateLevel1;
var xx, yy: single;
  i: integer;
begin
  FViewArea.Right := ScaleW(2501);
  FViewArea.Bottom := ScaleH(2335);

  CreateCeilling;
  CreateBGWall;
  CreateGroundLarge(0, 0, 15);
  CreateGroundLarge(ScaleW(1000), 1, 9);
  CreateGroundLarge(ScaleW(1003), 2, 2);
  for i:=3 to 7 do
    CreateGroundLarge(ScaleW(367), i, 6);
  CreateGroundLarge(ScaleW(336), 8, 14);
  CreateGroundLarge(ScaleW(336), 9, 14);

  CreateGroundLarge(0, 2, 6);

  // smRightSwingDown, smLeftSwingDown,
  // smRightSwingDownWithFeet, smLeftSwingDownWithFeet,
  // smContinuousRotateCW, smContinuousRotateCCW

  CreatePillar([226,748,1059,1772,2054,2398], 0, LAYER_BG2, True);
  CreatePillar([608], 0, LAYER_BG2, False);

  CreatePillar([1241, 1973], 1, LAYER_BG2, False);
  CreatePillar([1711,2226], 1, LAYER_BG2, True);

  FPump := TPump.Create(ScaleW(1463), FloorToY(1)-TPump.texPumpBody^.FrameHeight, LAYER_FXANIM);
  xx := ScaleW(1463)-texPumpPipeElbow^.FrameWidth;
  TPipeElbow.Create(xx, ScaleH(414), LAYER_BG2);
  TVerticalPipe.Create(xx, ScaleH(480), LAYER_BG2);
  TVerticalPipe.Create(xx, ScaleH(580), LAYER_BG2);
  TPipeVacuum.Create(ScaleW(1373), ScaleH(679), LAYER_BG2);
  FLavaForVacuum := TLavaForVacuum.Create(ScaleW(1373)+texPumpVacuum^.FrameWidth*0.5, ScaleH(748), LAYER_BG2);

  yy := ScaleH(290);
  TVerticalPipe.Create(ScaleW(1608), yy, LAYER_BG2); // top
  yy := yy - texPumpVerticalPipe^.FrameHeight;
  TVerticalPipe.Create(ScaleW(1608), yy, LAYER_BG2);
  yy := yy - texPumpVerticalPipe^.FrameHeight;
  TVerticalPipe.Create(ScaleW(1608), yy, LAYER_BG2);
  yy := yy - texPumpPipeElbow^.FrameHeight;
  xx := ScaleW(1582);
  with TPipeElbow.Create(xx, yy, LAYER_BG2) do FlipH := True;
  for i:=1 to 10 do begin
    xx := xx - texPumpVerticalPipe^.FrameHeight;
    TPipeLeft.Create(xx, yy, LAYER_BG2);
  end;
  xx := xx - texPumpPipeElbow^.FrameWidth;
  TPipeElbow.Create(xx, yy, LAYER_BG2);
  yy := yy + texPumpPipeElbow^.FrameHeight;
  with TVerticalPipe.Create(xx, yy, LAYER_BG2) do FlipV := True;
  FLavaFallingInMachine := TLavaFallingInRobotConstructor.Create(xx+texPumpVerticalPipe^.FrameWidth*0.5, ScaleH(286), LAYER_BG2);
  yy := yy + texPumpVerticalPipe^.FrameHeight;
  with TVerticalPipe.Create(xx, yy, LAYER_BG2) do FlipV := True;


  FRobotConstructor := TLittleRobotConstructor.Create(ScaleW(540), FloorToY(2), LAYER_BG2);
  FRobotConstructor.StartConstructing;

  FDigicode := TWallWithDigicode.Create(ScaleW(1003), FloorToY(1), LAYER_FXANIM);

  FComputer := TUsableComputer.Create(ScaleW(765), FloorToY(2)+texGroundLarge^.FrameHeight*0.3, LAYER_BG2, FFontText, NIL);
  if FCurrentGameLevel = 1 then FComputer.StartCountingRobot(9000, FRobotConstructor)
    else FComputer.StartCountingRobot(15000, FRobotConstructor);

  TLadderTop.Create(ScaleW(1136), 1, 7);

  xx := texIronBrick^.FrameWidth*0.5;
  TIronBlock.Create(-xx, Single(ScaleH(543)), 7, rsToTheRight);
  TIronBlock.Create(ScaleW(957), Single(ScaleH(693)), 6, rsBothSide);
  TIronBlock.Create(ScaleW(1299), Single(ScaleH(2041)), 21, rsToTheLeft);
  TIronBlock.Create(FViewArea.Right+xx, 2, 2, rsToTheLeft);

  CreateGroundLarge2(ScaleW(1345), ScaleH(755), 7);
  CreateLava(ScaleW(1324), FViewArea.Right+xx, ScaleH(721));
  //CreateLava(ScaleW(1324), FViewArea.Right+xx, ScaleH(721));

  TPanelExit.Create(ScaleW(2381), 0, True);
  TPanelExit.Create(ScaleW(2381), 9, True);

  // retrieve the ladder top
  for i:=0 to FScene.Layer[LAYER_GROUND].SurfaceCount-1 do
    if FScene.Layer[LAYER_GROUND].Surface[i] is TLadderTop then begin
      FLadderEmergency := TLadderTop(FScene.Layer[LAYER_GROUND].Surface[i]);
      break;
    end;
  // and make it inaccessible
  FLadderEmergency.Y.Value := FLadderEmergency.Y.Value+FLadderEmergency.Height*2;

  // bottom ladder
  TLadderTop.Create(ScaleW(500), 3, 6);
  TLadderTop.Create(ScaleW(834), 3, 5);
  // bottom iron block
  TIronBlock.Create(ScaleW(333), Single(ScaleH(2273)), 21, rsToTheRight);
  TIronBlock.Create(ScaleW(691), Single(ScaleH(2037)), 15, rsBothSide);
  TIronBlock.Create(ScaleW(1003), Single(ScaleH(1829)), 16, rsBothSide);


  FLR.X.Value := FLR.BodyWidth*2;
  FLR.CurrentFloor := 0;
end;

procedure TScreenGameVolcanoInner.CreateLevel2;
var xx: single;
begin
  FViewArea.Right := ScaleW(3000);
  FViewArea.Bottom := ScaleH(824);

  TWatchRoom.Create(ScaleW(2241), 0);
  TWatchRoom.Create(ScaleW(1058), 1);

  CreateCeilling;
  CreateBGWall;
  CreateGroundLarge(0, 0, 18);
  CreateGroundLarge(0, 1, 18);
  CreateGroundLarge(0, 2, 18);

  // smRightSwingDown, smLeftSwingDown,
  // smRightSwingDownWithFeet, smLeftSwingDownWithFeet,
  // smContinuousRotateCW, smContinuousRotateCCW

  CreatePillar([328,1060], 0, LAYER_BG2, True);
  CreatePillar([531,912,1556,2036], 0, LAYER_BG2, False);
  TPillarWithScanner.Create(ScaleW(748), 0, LAYER_BG2, smRightSwingDownWithFeet);
  TPillarWithScanner.Create(ScaleW(1359), 0, LAYER_BG2, smLeftSwingDownWithFeet);
  TPillarWithScanner.Create(ScaleW(1844), 0, LAYER_BG2, smRightSwingDownWithFeet);

  CreatePillar([889,1597,2309,2690], 1, LAYER_BG2, True);
  CreatePillar([192,704,1774,2130,2506], 1, LAYER_BG2, False);
  TPillarWithScanner.Create(ScaleW(457), 1, LAYER_BG2, smLeftSwingDown);
  TPillarWithScanner.Create(ScaleW(1938), 1, LAYER_BG2, smRightSwingDown);

  CreatePillar([268,2612], 2, LAYER_BG2, True);
  CreatePillar([494,1091,2027,2439], 2, LAYER_BG2, False);
  TPillarWithScanner.Create(ScaleW(782), 2, LAYER_BG2, smRightSwingDown);
  TPillarWithScanner.Create(ScaleW(1348), 2, LAYER_BG2, smLeftSwingDown);
  TPillarWithScanner.Create(ScaleW(1840), 2, LAYER_BG2, smRightSwingDown);
  TPillarWithScanner.Create(ScaleW(2382), 2, LAYER_BG2, smLeftSwingDown);

  TLadderTop.Create(ScaleW(2798), 0, 1);
  TLadderTop.Create(ScaleW(64), 1, 1);

  xx := texIronBrick^.FrameWidth*0.5;
  TIronBlock.Create(-xx, Single(ScaleH(847)), 11, rsToTheRight);
  //TIronBlock.Create(FViewArea.Right-xx, Single(ScaleH(847)), 11, rsToTheLeft);
  TIronBlock.Create(FViewArea.Right-xx, 1, 6, rsToTheLeft);

  CreateLava(-xx, FViewArea.Right+xx, FViewArea.Bottom-texLavaLarge^.FrameHeight);

  TPanelExit.Create(ScaleW(2899), 2, True);

  FLR.X.Value := FLR.BodyWidth*2;
  FLR.CurrentFloor := 0;
end;

procedure TScreenGameVolcanoInner.CreateLevel3;
var xx: single;
begin
  FViewArea.Right := ScaleW(2000);
  FViewArea.Bottom := ScaleH(1054);

  CreateCeilling;
  CreateBGWall;
  CreateGroundLarge(0, 0, 18);
  CreateGroundLarge(0, 1, 18);
  CreateGroundLarge(0, 2, 18);
  CreateGroundLarge(0, 3, 18);

  CreatePillar([208,748,1059], 0, LAYER_BG2, True);
  CreatePillar([495,912,1556], 0, LAYER_BG2, False);
  TPillarWithScanner.Create(ScaleW(1345), 0, LAYER_BG2, smRightSwingDown);
  TPillarWithScanner.Create(ScaleW(1697), 0, LAYER_BG2, smLeftSwingDown);
  TFootSwitch.Create(ScaleW(469), 0);
  TFootSwitch.Create(ScaleW(674), 0);
  TFootSwitch.Create(ScaleW(872), 0);
  TFootSwitch.Create(ScaleW(415), 3);
  TFootSwitch.Create(ScaleW(462), 3);
  TFootSwitch.Create(ScaleW(650), 3);
  TFootSwitch.Create(ScaleW(900), 3);
  TFootSwitch.Create(ScaleW(1149), 3);

  CreatePillar([889,1597], 1, LAYER_BG2, True);
  CreatePillar([192,704,1466], 1, LAYER_BG2, False);
  TPillarWithScanner.Create(ScaleW(457), 1, LAYER_BG2, smRightSwingDown);

  CreatePillar([494,1091], 2, LAYER_BG2, False);
  TPillarWithScanner.Create(ScaleW(347), 2, LAYER_BG2, smRightSwingDownWithFeet);
  TPillarWithScanner.Create(ScaleW(810), 2, LAYER_BG2, smRightSwingDownWithFeet);
  TPillarWithScanner.Create(ScaleW(1348), 2, LAYER_BG2, smLeftSwingDownWithFeet);
  TPillarWithScanner.Create(ScaleW(1666), 2, LAYER_BG2, smContinuousRotateCCW);

  TLadderTop.Create(ScaleW(85), 0, 1);
  TLadderTop.Create(ScaleW(976), 0, 1);
  TLadderTop.Create(ScaleW(1838), 0, 1);
  TLadderTop.Create(ScaleW(1245), 1, 2);

  xx := texIronBrick^.FrameWidth*0.5;
  TIronBlock.Create(-xx, Single(ScaleH(637)), 10, rsToTheRight);
  TIronBlock.Create(ScaleW(290), 0, 2, rsBothSide);
  TIronBlock.Create(ScaleW(1147), 1, 2, rsBothSide);
  TIronBlock.Create(ScaleW(1417), 3, 5, rsToTheLeft);
  TIronBlock.Create(ScaleW(1463), 2, 1, rsBothSide);
  TIronBlock.Create(ScaleW(1509), 2, 1, rsBothSide);
  TIronBlock.Create(ScaleW(1555), 3, 5, rsToTheRight);
  TIronBlock.Create(FViewArea.Right-xx, Single(ScaleH(1954)), 12, rsToTheLeft);

  CreateLava(-xx, FViewArea.Right, ScaleH(1007), False);
  with TLavaFallingInRobotConstructor.Create(ScaleW(1509), ScaleH(723), LAYER_GROUND) do
    SetNormalFlowToTargetY(ScaleH(1027));

  TPanelExit.Create(ScaleW(51), 3, False);

  with TUsableCrateThatContainObject.Create(ScaleW(51), FloorToY(2)+DeltaFloorToCharacterFeet, LAYER_GROUND, not PlayerInfo.Volcano.HaveGreenSDCard, FLR) do begin
    if PlayerInfo.Volcano.HaveGreenSDCard then begin
      ContentID := oicIDNone;
      Enabled := False;
    end else ContentID := oicIDSDCard;
  end;
  with TUsableCrateThatContainObject.Create(ScaleW(350), FloorToY(0)+DeltaFloorToCharacterFeet, LAYER_GROUND, False, FLR) do
    if PlayerInfo.Volcano.HaveGreenSDCard then begin
      ContentID := oicIDNone;
      Enabled := False;
    end else ContentID := oicIDKey;

  FLR.X.Value := FLR.BodyWidth*2;
  FLR.CurrentFloor := 0;
end;

procedure TScreenGameVolcanoInner.CreateLevel4;
var xx: single;
begin
  FViewArea.Right := ScaleW(2330);
  FViewArea.Bottom := ScaleH(1050);

  TWatchRoom.Create(ScaleW(611), 1);

  CreateCeilling;
  CreateBGWall;
  CreateGroundLarge(0, 0, 14);
  CreateGroundLarge(0, 1, 14);
  CreateGroundLarge(0, 2, 14);
  CreateGroundLarge(0, 3, 14);

  CreatePillar([328,1059], 0, LAYER_BG2, True);
  CreatePillar([531,912,1556,2036], 0, LAYER_BG2, False);
  TPillarWithScanner.Create(ScaleW(748), 0, LAYER_BG2, smRightSwingDown);
  TPillarWithScanner.Create(ScaleW(1359), 0, LAYER_BG2, smLeftSwingDown);
  TPillarWithScanner.Create(ScaleW(1844), 0, LAYER_BG2, smRightSwingDown);
  TFootSwitch.Create(ScaleW(252), 0);
  TFootSwitch.Create(ScaleW(1070), 0);
  TFootSwitch.Create(ScaleW(2056), 0);

  CreatePillar([1229, 1597], 1, LAYER_BG2, True);
  CreatePillar([192,1456,1774,2130], 1, LAYER_BG2, False);
  TPillarWithScanner.Create(ScaleW(1938), 1, LAYER_BG2, smRightSwingDown);
  TFootSwitch.Create(ScaleW(1161), 1);
  TFootSwitch.Create(ScaleW(1362), 1);
  TFootSwitch.Create(ScaleW(1557), 1);
  TFootSwitch.Create(ScaleW(1736), 1);

  CreatePillar([268,782], 2, LAYER_BG2, True);
  CreatePillar([1091,1657], 2, LAYER_BG2, False);
  TPillarWithScanner.Create(ScaleW(1348), 2, LAYER_BG2, smLeftSwingDown);
  TPillarWithScanner.Create(ScaleW(1840), 2, LAYER_BG2, smRightSwingDown);
  TFootSwitch.Create(ScaleW(1356), 2);
  TFootSwitch.Create(ScaleW(1852), 2);

  CreatePillar([206,981,2019], 3, LAYER_BG2, True);
  CreatePillar([582,1312,1812], 3, LAYER_BG2, False);
  TPillarWithScanner.Create(ScaleW(1613), 3, LAYER_BG2, smLeftSwingDown);
  TFootSwitch.Create(ScaleW(585), 3);
  TFootSwitch.Create(ScaleW(788), 3);
  TFootSwitch.Create(ScaleW(833), 3);
  TFootSwitch.Create(ScaleW(1044), 3);
  TFootSwitch.Create(ScaleW(1301), 3);
  TFootSwitch.Create(ScaleW(1905), 3);

  TLadderTop.Create(ScaleW(2193), 0, 1);
  TLadderTop.Create(ScaleW(700), 1, 1);
  TLadderTop.Create(ScaleW(2193), 2, 1);

  xx := texIronBrick^.FrameWidth*0.5;
  TIronBlock.Create(-xx, Single(ScaleH(409)), 7, rsToTheRight);
  TIronBlock.Create(ScaleW(440), 1, 2, rsBothSide);
  TIronBlock.Create(ScaleW(486), Single(ScaleH(334)), 1, rsBothSide);
  TIronBlock.Create(ScaleW(532), Single(ScaleH(334)), 1, rsBothSide);
  TIronBlock.Create(ScaleW(578), 1, 2, rsBothSide);
  TIronBlock.Create(ScaleW(634), 2, 2, rsBothSide);
  TIronBlock.Create(FViewArea.Right-xx, Single(ScaleH(983)), 14, rsToTheLeft);

  CreateLava(-xx, FViewArea.Right, ScaleH(1004), False);
  with TLavaFallingInRobotConstructor.Create(ScaleW(534), ScaleH(400), LAYER_GROUND) do
    SetNormalFlowToTargetY(ScaleH(663));

  TPanelExit.Create(ScaleW(51), 3, False);

  with TUsableCrateThatContainObject.Create(ScaleW(862), FloorToY(2)+DeltaFloorToCharacterFeet, LAYER_GROUND, not PlayerInfo.Volcano.DorsalThruster.Owned, FLR) do begin
    if PlayerInfo.Volcano.DorsalThruster.Owned then begin
      ContentID := oicIDNone;
      Enabled := False;
    end else ContentID := oicIDPropulsor;
  end;
  with TUsableCrateThatContainObject.Create(ScaleW(415), FloorToY(3)+DeltaFloorToCharacterFeet, LAYER_GROUND, False, FLR) do
    if PlayerInfo.Volcano.DorsalThruster.Owned then begin
      ContentID := oicIDNone;
      Enabled := False;
    end else ContentID := oicIDKey;

  TPropulsorConstructor.Create(ScaleW(382), ScaleH(618), LAYER_GROUND);

  FLR.X.Value := FLR.BodyWidth*2;
  FLR.CurrentFloor := 0;
end;

procedure TScreenGameVolcanoInner.CreateLevel5;
var xx: single;
begin
  CreateLevel1;

  xx := texIronBrick^.FrameWidth*0.5;
  TIronBlock.Create(FViewArea.Right-xx, Single(ScaleH(410)), 2, rsToTheLeft);

  FLR.X.Value := FViewArea.Right-FLR.BodyWidth*2;
  FLR.CurrentFloor := 1;
  FLR.IdleLeft;
end;

procedure TScreenGameVolcanoInner.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin

end;

procedure TScreenGameVolcanoInner.ProcessLayerLadderBeforeUpdateEvent;
begin
  // when LAYER_GROUND is updated, this property will be updated by ladder object.
  // we need to set it to NIL before.
  FLR.LadderInUse := NIL;
  FLR.ObjectToHandle := NIL;
  FLR.DistanceToObjectToHandle := MaxSingle;
end;

procedure TScreenGameVolcanoInner.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then Exit;
  FGameState := AValue;
  case AValue of
    gsLRCaptured: PostMessage(0);

    gsLRWin: PostMessage(100);
  end;
end;

procedure TScreenGameVolcanoInner.CreateObjects;
var path: string;
  ima: TBGRABitmap;
  p: TPointF;
begin
  FGameState := gsUndefined;
  ResetVariables;
  FsndMechanical := NIL;
  FsndEarthquakeLoop := NIL;
  FsndEarthquake := NIL;
  FComputer := NIL;
  sndAlarm := NIL;
  sndEmergencyAlarm := NIL;

  Audio.PauseMusicTitleMap(3.0);
  FsndPercuLoop := Audio.AddMusic('PercuLoop1.ogg', True);
  FsndPercuLoop.FadeIn(1.0, 1.0);

  FsndBoilingLava := Audio.AddSound('Boiling.ogg');
  FsndBoilingLava.Loop := True;
  FsndBoilingLava.FadeIn(0.5, 1.0);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 1;

  AdditionnalScale := 0.8;
  LoadLR4DirTextures(FAtlas, False);
  LoadWolfTextures(FAtlas);

  AdditionnalScale := 1.0;

  path := SpriteGameVolcanoInnerFolder;
  texPillar1 := FAtlas.AddFromSVG(path+'Pillar1.svg', -1, ScaleH(225)); //ScaleH(714));
  texPillar2 := FAtlas.AddFromSVG(path+'Pillar2.svg', -1, ScaleH(225)); //ScaleH(714));
  texBGCeilling := FAtlas.AddFromSVG(path+'BGCeilling.svg', ScaleW(167), -1);
  texBGWall := FAtlas.AddFromSVG(path+'BGWall.svg', ScaleW(140), -1);
  texGroundLarge := FAtlas.AddFromSVG(path+'GroundLarge.svg', ScaleW(167), -1);
  texIronBrick := FAtlas.AddFromSVG(path+'IronBrick.svg', -1, ScaleH(75));
  texLadderTop := FAtlas.AddFromSVG(path+'LadderTop.svg', -1, ScaleH(132));
  texLadder := FAtlas.AddFromSVG(path+'Ladder.svg', -1, ScaleH(230));
  texLavaLarge := FAtlas.AddFromSVG(path+'LavaLarge.svg', ScaleW(310), -1);
  texRockMedium := FAtlas.AddFromSVG(path+'RockMedium.svg', ScaleW(82), -1);
  texRockSmall := FAtlas.AddFromSVG(path+'RockSmall.svg', ScaleW(56), -1);
  texLavaBall := FAtlas.AddFromSVG(path+'LavaBall.svg', ScaleW(20), -1);

  AddFlameParticleToAtlas(FAtlas);
  AddSphereParticleToAtlas(FAtlas);
  AddCloud128x128ParticleToAtlas(FAtlas);
  AddCrossParticleToAtlas(FAtlas);

  texPanelExit := FAtlas.AddFromSVG(path+'PanelExit.svg', ScaleW(52), -1);

  texPumpPipeElbow := FAtlas.AddFromSVG(path+'PumpPipeElbow.svg', ScaleW(66), -1);
  texPumpVacuum := FAtlas.AddFromSVG(path+'PumpVacuum.svg', ScaleW(90), -1);
  texPumpVerticalPipe := FAtlas.AddFromSVG(path+'PumpVerticalPipe.svg', -1, ScaleH(100));

  TLittleRobotConstructor.LoadTexture(FAtlas);
  TLittleRobot.LoadTexture(FAtlas);
  TPropulsorConstructor.LoadTexture(FAtlas);
  TPanelDecodingDigicode.LoadTextures(FAtlas);
  TUsableComputer.LoadTexture(FAtlas);
  TPump.LoadTexture(FAtlas);
  TImpact1.LoadTexture(FAtlas);
  TUsableCrateThatContainObject.LoadTexture(FAtlas);

  texScannerDevice := FAtlas.AddFromSVG(path+'ScannerDevice.svg', ScaleW(12), -1);
  texScannerBeam := FAtlas.AddFromSVG(path+'ScannerBeam.svg', ScaleW(98), -1);
  texFootSwitch := FAtlas.AddFromSVG(path+'FootSwitch.svg', ScaleW(43), -1);
  texWall := TPanelDecodingDigicode.texWallBG; // FAtlas.AddFromSVG(SpriteGameVolcanoEntranceFolder+'PanelDecodeWallBG.svg', ScaleW(114), -1);
  texHalfWall := FAtlas.AddFromSVG(path+'HalfWall.svg', ScaleW(114), -1);
  texDigicode := FAtlas.AddFromSVG(SpriteGameVolcanoEntranceFolder+'Digicode.svg', ScaleW(36), -1);

  CreateGameFontNumber(FAtlas);
  LoadKeyMetalTexture(FAtlas);
  LoadSDCardTexture(FAtlas);
  LoadDorsalThrusterTexture(FAtlas);
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
  FLR := TLRCustom.Create;
  FLR.TimeMultiplicator := 0.7; // accelerate a little bit LR moves.
  FLR.X.Value := FLR.BodyWidth;
  FLR.CurrentFloor := 0;
  FLR.SetWindSpeed(0.5);
  FLR.SetFaceType(lrfSmile);
  FLR.IdleRight;

  FInGameinventory := TInventoryOnScreen.Create;
  CreateLevel(PlayerInfo.Volcano.StepPlayed);

  // camera
  FCamera := FScene.CreateCamera;
  FCamera.AssignToLayer([LAYER_DIALOG, LAYER_WEATHER, LAYER_ARROW, LAYER_PLAYER,
   LAYER_WOLF, LAYER_FXANIM, LAYER_GROUND, LAYER_BG1, LAYER_BG2]);

  FCameraBGWall := FScene.CreateCamera;
  FCameraBGWall.AssignToLayer(LAYER_BG3);
  FCameraFollowLR := True;

  // background color
  FScene.BackgroundColor := BGRA(68,49,63);

  // callback for layer where are the ladders
  FScene.Layer[LAYER_GROUND].OnBeforeUpdate := @ProcessLayerLadderBeforeUpdateEvent;

  // pause panel
  FInGamePausePanel := TInGamePausePanel.Create(FFontText, FAtlas);
  FInGamePausePanel.SetCheatCodeList([VolcanoInnerCheatCode]);
  FInGamePausePanel.OnPlayerEnterCheatCode := @ProcessPlayerEnterCheatCode;

  // decode digicode panel
  FPanelDecodingDigicode := TPanelDecodingDigicode.Create;

  // prepare the array with funny message, displayed at the end of this game
  FFunnyMessages := NIL;
  SetLength(FFunnyMessages, 4);
  FFunnyMessages[0] := sFunnyRunAway;
  FFunnyMessages[1] := sFunnyAtTheCanteen;
  FFunnyMessages[2] := sSpinachIsGoodForYourHealth;
  FFunnyMessages[3] := sToMuchLavaIsBadForYourHealth;

  if FCurrentGameLevel = 1 then begin
    // level 1 start with cinematic and some message from LR
    FCameraFollowLR := False;
    FCamera.MoveTo(PointF(FRobotConstructor.X.Value, FRobotConstructor.Y.Value-FRobotConstructor.texWheel^.FrameHeight*0.5));
    FCamera.Scale.Value := PointF(3.0, 3.0);
    PostMessage(110)
  end else if FCurrentGameLevel = 5 then begin
    // level 5 start with LR to the right
    p.x := EnsureRange(FLR.X.Value, FViewArea.Left, FViewArea.Right);
    p.y := EnsureRange(FLR.Y.Value, FViewArea.Top, FViewArea.Bottom);
    MoveCameraTo(p, 0.0);
    FGameState := gsRunning;
  end else FGameState := gsRunning;

  // show how to play
  ShowGameInstructions(PlayerInfo.Volcano.HelpText);
end;

procedure TScreenGameVolcanoInner.FreeObjects;
begin
  Audio.ResumeMusicTitleMap;
  if FsndPercuLoop <> NIL then FsndPercuLoop.FadeOutThenKill(3.0);
  FsndPercuLoop := NIL;
  FsndBoilingLava.FadeOutThenKill(3.0);
  FsndBoilingLava := NIL;
  if sndAlarm <> NIL then sndAlarm.FadeOutThenKill(3.0);
  sndAlarm := NIL;
  if sndEmergencyAlarm <> NIL then sndEmergencyAlarm.FadeOutThenKill(3.0);
  sndEmergencyAlarm := NIL;
  if FsndEarthquakeLoop <> NIL then FsndEarthquakeLoop.FadeOutThenKill(3.0);
  FsndEarthquakeLoop := NIL;
  if FsndEarthquake <> NIL then FsndEarthquake.FadeOutThenKill(3.0);
  FsndEarthquake := NIL;

  FScene.KillCamera(FCamera);
  FScene.KillCamera(FCameraBGWall);
  FScene.ClearAllLayer;
  FAtlas.Free;
  ResetSceneCallbacks;
end;

procedure TScreenGameVolcanoInner.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // LR captured
    0: begin
      if AlarmIsAlreadyStarted then exit;
      FsndPercuLoop.FadeOutThenKill(1.0);
      FsndPercuLoop := NIL;
      FLR.SetFaceType(lrfNotHappy);
      FLR.SetIdlePosition;
      PlayAlarmLRCaught;
      PostMessage(1, 3.0);
    end;
    1: begin
      FScene.RunScreen(ScreenMap);
    end;

    // LR WIN
    100: begin  // check if all crates of this level are opened by player
      if ((FCurrentGameLevel = 3) and not FInGameinventory.HaveGreenSDCard) or
         ((FCurrentGameLevel = 4) and not FInGameinventory.HaveDorsalThruster) then begin
        FLR.SetIdlePosition;
        FLR.ShowDialog(sBeforeILeaveIHaveToSearchAllCratesInTheArea, FFontText, Self, 103, 0, FCamera);
      end else PostMessage(101);
    end;
    101: begin
      if FsndPercuLoop <> NIL then FsndPercuLoop.FadeOutThenKill(1.0);
      FsndPercuLoop := NIL;
      d := 0.0;
      if FCurrentGameLevel <> 1 then begin
        Audio.PlayVoiceWhowhooo;
        Audio.PlayMusicSuccess1;
        FLR.SetFaceType(lrfHappy);
        d := 3.0;
      end;
      FLR.SetIdlePosition;
      if FExitToTheRight then
        FLR.WalkHorizontallyTo(FCamera.GetViewRect.Right+FScene.Width*0.5+FLR.BodyWidth, Self, 102, d)
      else
        FLR.WalkHorizontallyTo(-FLR.BodyWidth, Self, 102, d);
    end;
    102: begin
      PlayerInfo.Volcano.IncCurrentStep;
      FSaveGame.Save;
      FScene.RunScreen(ScreenMap);
    end;
    103: begin // LR can not leave this level, she walk back some steps
      if FExitToTheRight then FLR.WalkHorizontallyTo(FLR.X.Value-FLR.BodyWidth, Self, 104)
        else FLR.WalkHorizontallyTo(FLR.X.Value+FLR.BodyWidth, Self, 104);
    end;
    104: FGameState := gsRunning;


    // ANIM discover of the machine
    110: begin // zoom on the machine
      FCameraFollowLR := False;
      FCamera.MoveTo(PointF(FRobotConstructor.X.Value, FRobotConstructor.Y.Value-FRobotConstructor.texWheel^.FrameHeight*0.5));
      FCamera.Scale.Value := PointF(3.0, 3.0);
      PostMessage(111, 10.0);
    end;
    111: begin // zoom out
      FCamera.Reset(11.0, idcSinusoid);
      PostMessage(121, 11);
    end;
    // message from LR when she look at the machine
    121: begin
      FLR.WalkHorizontallyTo(ScaleW(300), Self, 122);
    end;
    122: begin
      FCameraFollowLR := True;
      FLR.IdleRight;
      FLR.ShowExclamationMark;
      FLR.SetFaceType(lrfWorry);
      PostMessage(126, 2.0);
    end;
    126: begin
      FLR.HideMark;
      FLR.ShowDialog(sWowAMachineThatBuildsRobots, FFontText, Self, 127, 0, FCamera);
    end;
    127: FLR.ShowDialog(sAndTheyUseVolcanoLavaAsRawMaterial, FFontText, Self, 128, 0, FCamera);
    128: FLR.ShowDialog(sWolvesAreDefinitelyResourceFul, FFontText, Self, 129, 0, FCamera);
    129: FLR.ShowDialog(sIWonderWhatAllTheseRobotsAreFor, FFontText, Self, 130, 0, FCamera);
    130: begin
      FLR.SetFaceType(lrfSmile);
      FLR.ShowDialog(sIHaveGotToFindAWayToStopThisMachine, FFontText, Self, 131, 0, FCamera);
    end;
    131: FGameState := gsRunning;

    // final animation
    // show some dialogs about the digicode then decode it
    150: FLR.ShowDialog(sIWonderWhatTheDigicodeIsFor, FFontText, Self, 151, 0, FCamera);
    151: FLR.ShowDialog(sLetTryHackingItAndSeeWhatHappens, FFontText, Self, 152, 0, FCamera);
    152: begin
      FPanelDecodingDigicode.Show;
      PostMessage(153);
    end;
    153: begin
      if FPanelDecodingDigicode.ScanIsDone then begin
        FPanelDecodingDigicode.Hide(True);
        FGameState := gsStartAnimRobotConstructorMoves;
        PostMessage(160);
      end else PostMessage(153)
    end;

    // show some warning dialogs from the computer
    160: begin
      sndEmergencyAlarm := Audio.AddSound('EmergencyAlarm.mp3');   // alarm
      sndEmergencyAlarm.Loop := True;
      sndEmergencyAlarm.Volume.Value := 0.4;
      sndEmergencyAlarm.Play(True);
      FComputer.StartScreenFlashRed;
      FComputer.SetText(sAICorrupted);
      FLR.ShowQuestionMark;
      with TInfoPanel.Create(sAIvoice, sSystemIntrusionAlert, FFontText, Self, 161) do
          SetCenterCoordinate(PointF(FComputer.Center.x, GetCameraCenterView.y));
    end;
    161: with TInfoPanel.Create(sAIvoice, CorruptString(sSystemMalfunctionDueToHacking), FFontText, Self, 200) do
          SetCenterCoordinate(PointF(FComputer.Center.x, GetCameraCenterView.y));

    // gsStartAnimRobotConstructorMoves
    200: begin  // camera zoom out
      FCameraFollowLR := False;
      ZoomCameraTo(PointF(0.8,0.8), 4.0);
      MoveCameraTo(PointF(ScaleW(730), ScaleH(514)), 4.0);
      FLR.HideMark;
      PostMessage(201, 4.0);
    end;
    201: begin
      FRobotConstructor.StopConstructing;
      PostMessage(202, 3.0);
    end;
    202: begin  // wait the end of the previous construction
      if not FRobotConstructor.ConstructionFinished then PostMessage(202)
        else PostMessage(203);
    end;
    203: begin  // machine shift to left
      FRobotConstructor.X.ChangeTo(ScaleW(238), 4.0, idcSinusoid);
      FRobotConstructor.SetWheelsAngleTo(-360*2, 4.0, idcSinusoid);
      FRobotConstructor.PlaySoundMoveMotor;
      FLavaFallingInMachine.SetNormalFlowToGround;
      PostMessage(204, 4.0);
    end;
    204: begin  // machine stop
      FRobotConstructor.StopSoundMoveMotor;
      PostMessage(205, 1.0);
    end;
    205: begin // message computer try to position the machine
      with TInfoPanel.Create(sAIvoice, CorruptString(sMachineIsNotInRightAxis), FFontText, Self, 206) do
          SetCenterCoordinate(PointF(FComputer.Center.x, GetCameraCenterView.y));
    end;
    206: with TInfoPanel.Create(sAIvoice, CorruptString(sRapidReturnToTheAxis), FFontText, Self, 207) do
          SetCenterCoordinate(PointF(FComputer.Center.x, GetCameraCenterView.y));
    207: begin  // machine run to the right and hurt computer
      FRobotConstructor.X.ChangeTo(FComputer.X.Value-FRobotConstructor.BodyWidth*0.5, 1.0, idcStartSlowEndFast);
      FRobotConstructor.SetWheelsAngleTo(360, 1.0, idcStartSlowEndFast);
      FRobotConstructor.PlaySoundMoveMotorAtMaxSpeed;
      PostMessage(208, 1.0);
    end;
    208: begin // earthquake + machine rotation
      FRobotConstructor.StopSoundMoveMotor;
      FCamera.Shaker.Start(PPIScale(20), PPIScale(20), 0.03);
      FRobotConstructor.Pivot := PointF(FRobotConstructor.BodyWidth*0.5, 0);
      FRobotConstructor.Angle.ChangeTo(45, 0.2, idcStartFastEndSlow);
      Audio.PlayThenKillSound('CollisionLong1.ogg', 1.0, 0.0, 1.0, Audio.FXReverbLong, 0.5);
      FLR.ShowExclamationMark;
      FLR.SetFaceType(lrfWorry);
      PostMessage(209, 0.5);
    end;
    209: begin  // stop earthquake + machine return to no rotation + fire on computer
      FCamera.Shaker.Stop;
      FRobotConstructor.Angle.ChangeTo(0, 1.0, idcStartSlowEndFast);
      FFireOnComputer := TFireLine.Create(FComputer.X.Value, FComputer.Y.Value + FComputer.Height*0.3, LAYER_FXANIM, FAtlas);
      PostMessage(210, 1.0);
    end;
    210: begin
      Audio.PlayThenKillSound('CollisionPunchShort.ogg', 1.0, 0.0, 1.0, Audio.FXReverbLong, 0.5);
      PostMessage(211, 1.0);
    end;
    211: begin // machine shift to left
      FRobotConstructor.X.ChangeTo(ScaleW(238), 4.0, idcSinusoid);
      FRobotConstructor.SetWheelsAngleTo(-360*2, 4.0, idcSinusoid);
      FRobotConstructor.PlaySoundMoveMotor;
      PostMessage(212, 4.0);
    end;
    212: begin
      FRobotConstructor.StopSoundMoveMotor;
      with TInfoPanel.Create(sAIvoice, CorruptString(sNewAttempt), FFontText, Self, 213) do
            SetCenterCoordinate(PointF(FComputer.Center.x, GetCameraCenterView.y));
    end;

    213: begin // machine run to the right and hurt computer
      FRobotConstructor.PlaySoundMoveMotorAtMaxSpeed;
      FRobotConstructor.X.ChangeTo(FComputer.X.Value-FRobotConstructor.BodyWidth*0.5, 1.0, idcStartSlowEndFast);
      FRobotConstructor.SetWheelsAngleTo(360, 1.0, idcStartSlowEndFast);
      PostMessage(214, 1.0);
    end;
    214: begin // earthquake + machine rotation + impacts on machine
      FCamera.Shaker.Start(PPIScale(20), PPIScale(20), 0.03);
      FRobotConstructor.StopGearsRotation;
      FRobotConstructor.Pivot := PointF(FRobotConstructor.BodyWidth*0.5, 0);
      FRobotConstructor.Angle.ChangeTo(45, 0.2, idcStartFastEndSlow);
      Audio.PlayThenKillSound('CollisionLong1.ogg', 1.0, 0.0, 1.0, Audio.FXReverbLong, 0.5);
      FRobotConstructor.CreateImpacts;
      FRobotConstructor.StopSoundMoveMotor;
      PostMessage(215, 0.5);
    end;
    215: begin // stop earthquake
      FCamera.Shaker.Stop;
      PostMessage(216, 1.0);
    end;
    216: with TInfoPanel.Create(sAIvoice, CorruptString(sProblemSolved), FFontText, Self, 220) do
          SetCenterCoordinate(PointF(FComputer.Center.x, GetCameraCenterView.y));

         // some message from the computer
    220: begin
      FLR.HideMark;
      with TInfoPanel.Create(sAIvoice, CorruptString(sSlowerRobotProduction), FFontText, Self, 221) do
          SetCenterCoordinate(PointF(FComputer.Center.x, GetCameraCenterView.y));
    end;
    221: with TInfoPanel.Create(sAIvoice, CorruptString(sPossibleCauseLackOfLava), FFontText, Self, 222) do
          SetCenterCoordinate(PointF(FComputer.Center.x, GetCameraCenterView.y));
    222: with TInfoPanel.Create(sAIvoice, CorruptString(RemedyPumpAtMaxi), FFontText, Self, 223) do
          SetCenterCoordinate(PointF(FComputer.Center.x, GetCameraCenterView.y));
    223: begin // center camera on the pump
      MoveCameraTo(FPump.Center-PointF(ScaleW(20),0), 4.0);
      PostMessage(224, 4.0);
    end;
    224: begin // pump at max + LR turn to right
      FLR.IdleRight;
      FPump.SetMaximumSpeed;
      FLavaForVacuum.SetMaximumFlow;
      PostMessage(225, 4.0);
    end;
    225: begin // smoke appears on pump
      FPump.CreateSmoke;
      PostMessage(230, 4.0);
    end;
    230: begin  // camera to the machine
      FLR.HideMark;
      MoveCameraTo(PointF(ScaleW(730), ScaleH(514)), 4.0);
      PostMessage(231, 3.0);
    end;
    231: begin  // lava maximum flow + LR turn Left
      FLR.IdleLeft;
      FLavaFallingInMachine.SetMaximumFlow;
      PostMessage(232, 2.0);
    end;
    232: begin
      FsndEarthquakeLoop := Audio.AddSound('Earthquake1_2654Loop.ogg', 0.8, True);
      FsndEarthquakeLoop.FadeIn(0.6, 4.0);
      PostMessage(240, 2.0);
    end;
    240: begin // lava appears + fire on computer disapear + sound earthquake loop
      CreateLava(-ScaleW(18), ScaleW(984), FloorToY(2)-texLavaLarge^.FrameHeight*1.5, True);
      CreateLava(-ScaleW(18), ScaleW(984), FloorToY(2)-texLavaLarge^.FrameHeight, True);
      FFireOnComputer.Opacity.ChangeTo(0, 2.0);
      FFireOnComputer.KillDefered(2.0);
      PostMessage(250, 3.0);
    end;
    250: with TInfoPanel.Create(sAIvoice, CorruptString(sProblemSolvedButEvacuate), FFontText, Self, 251) do
          SetCenterCoordinate(PointF(FComputer.Center.x, GetCameraCenterView.y));
    251: begin // camera on LR
      MoveCameraTo(FLR.GetXY, 4.0);
      PostMessage(252, 4.0);
    end;
    252: begin
      FCameraFollowLR := True;
      PostMessage(255);
    end;
    255: with TInfoPanel.Create(sAIvoice, CorruptString(sDeploymentOfEmergencyExit), FFontText, Self, 260) do
          SetCenterCoordinate(PointF(FComputer.Center.x, GetCameraCenterView.y));
    260: begin // ladder become accessible
      FLR.IdleRight;
      FLadderEmergency.Y.ChangeTo(FloorToY(1) + texGroundLarge^.FrameHeight*0.3 - texLadderTop^.FrameHeight, 2.0, idcSinusoid);

      FsndMechanical := Audio.AddSound('Mechanical1.ogg', 0.6, True);
      FsndMechanical.Play(True);
      PostMessage(261, 2.0);
    end;
    261: begin
      FsndMechanical.Kill;
      FsndMechanical := NIL;
      PostMessage(262, 1.0);
    end;
    262: begin // pump breaks a little + LR exclamation
      FPump.Pivot := PointF(0,0.5);
      FPump.Angle.Value := 7;
      FPump.Y.Value := FPump.Y.Value+PPIScale(10);
      Audio.PlayThenKillSound('CollisionLong1.ogg', 1.0, 0.5, 1.0, Audio.FXReverbLong, 0.5);
      FLR.ShowExclamationMark;
      PostMessage(263, 1.0);
    end;
    263: begin
      FLR.HideMark;
      PostMessage(264, 0.5);
    end;
    264: begin
      FLR.ShowDialog(sIBetterLeaveThisPlaceQuickly, FFontText, Self, 270, 0, FCamera);
    end;
    270: begin // end, player take the control + periodical earthquake + funny message from computer
      //ZoomCameraTo(PointF(1.0, 1.0), 10.0);
      GameState := gsRunning;
      PostMessage(300, 1); // generate periodical earthquake
      FFunnyMessageIndex := -1;
      PostMessage(350, 5.0); // generate periodical funny message from the computer
      PostMessage(360); // generate lava drop falling
      PostMessage(370); // generate falling rocks
      PostMessage(400); // check to make debris falling on bottom of 1rst escape ladder
      PostMessage(380); // check to make the machine fall
      PostMessage(390); // check to make the pump fall
    end;

    // generate periodical earthquake
    300: begin
      if FsndEarthquake = NIL then FsndEarthquake := Audio.AddSound('earthquake3.ogg', 0.6, False);
      FsndEarthquake.Volume.Value := 0.8;
      FsndEarthquake.Play(True);
      FCamera.Shaker.Start(PPIScale(20), PPIScale(20), 0.03);
      PostMessage(301, 4.0+Random*4);
    end;
    301: begin
      FCamera.Shaker.Stop;
      FsndEarthquake.FadeOut(2.0);
      PostMessage(300, 4.0+random*2);
    end;

    // generate periodical funny message from the computer
    350: begin
      inc(FFunnyMessageIndex);
      if FFunnyMessageIndex > High(FFunnyMessages) then FFunnyMessageIndex := 0;
      with TInfoPanel.Create(sAIvoice, CorruptString(FFunnyMessages[FFunnyMessageIndex]), FFontText, 4.0, LAYER_GAMEUI) do
                SetCoordinate(FScene.Width div 4, FScene.Height div 4);
      PostMessage(350, 10.0);
    end;

    // generate periodical lava drop
    360: begin
      TLavaDrop.Create;
      PostMessage(360, 0.12+Random);
    end;

    // generate periodical falling rock
    370: begin
      if (FsndEarthquake = NIL) or (FsndEarthquake.State <> ALS_PLAYING) then PostMessage(370)
      else begin
         TFallingRock.Create;
         PostMessage(370, 0.25+Random*0.5);
      end;
    end;

    // check if the machine can fall
    380: begin
      if (FLR.CurrentFloor = 9) and (FLR.X.Value > ScaleW(1044)) then begin
        FRobotConstructor.Pivot := PointF(0,0);
        FRobotConstructor.Angle.Value := 110;
        FRobotConstructor.Y.ChangeTo(FloorToY(9)-FRobotConstructor.BodyHeight*0.5, 1.0, idcSingleRebound); //idcStartSlowEndFast);
        PostMessage(381, 0.5);
        PostMessage(385); // avoid LR comme back
      end else PostMessage(380);
    end;
    381: begin // sound explosion + earthquake + big fire
        Audio.PlayThenKillSound('CollisionLong1.ogg', 1.0, -0.5, 1.0, Audio.FXReverbLong, 0.5);
        FCamera.Shaker.Start(PPIScale(20), PPIScale(20), 0.03);
        TBigFire.Create(FRobotConstructor.X.Value+FRobotConstructor.BodyHeight*0.5, FloorToY(9), LAYER_FXANIM, FAtlas);
        PostMessage(382, 2.0);
    end;
    382: begin // stop earthquake
        FCamera.Shaker.Stop;
    end;
    385: begin // avoid LR comme back where is the machine
      if FLR.X.Value < ScaleW(1044) then begin
        if FLR.Speed.x.Value < 0 then FLR.Speed.x.Value := 0;
        FLR.X.Value := ScaleW(1044);
      end;
      PostMessage(385);
    end;

    // check to make the pump fall
    390: begin
      if (FLR.CurrentFloor = 9) and (FLR.X.Value > ScaleW(1742)) then begin
        FPump.Y.ChangeTo(FloorToY(9)-FPump.Height, 1.0, idcStartSlowEndFast);
        PostMessage(391, 1.0);
        PostMessage(395); // avoid LR comme back
      end else PostMessage(390);
    end;
    391: begin // sound explosion + earthquake + smoke
        Audio.PlayThenKillSound('CollisionLong1.ogg', 1.0, -0.5, 1.0, Audio.FXReverbLong, 0.5);
        FCamera.Shaker.Start(PPIScale(20), PPIScale(20), 0.03);
        TBigFire.Create(FPump.CenterX, FPump.CenterY, LAYER_FXANIM, FAtlas);
        TSmokePoint.Create(FPump.X.Value, FloorToY(9), LAYER_FXANIM, FAtlas);
        TSmokePoint.Create(FPump.X.Value+FPump.Width*0.7, FloorToY(9), LAYER_FXANIM, FAtlas);
        PostMessage(392, 2.0);
    end;
    392: begin // stop earthquake
        FCamera.Shaker.Stop;
    end;
    395: begin // avoid LR come back where is the machine
      if FLR.X.Value < ScaleW(1742) then begin
        if FLR.Speed.x.Value < 0 then FLR.Speed.x.Value := 0;
        FLR.X.Value := ScaleW(1742);
      end;
      PostMessage(395);
    end;

    // check to make debris falling on bottom of 1rst escape ladder
    400: begin
      if (FLR.CurrentFloor = 8) and (FLR.X.Value < ScaleW(1010)) then begin
        with TCeilling.Create(ScaleW(1045)) do begin
          Angle.Value := -900; Angle.ChangeTo(167, 2.0, idcSingleRebound);
          Y.ChangeTo(ScaleH(2063), 2.0, idcSingleRebound);
        end;
        with TCeilling.Create(ScaleW(1112)) do begin
          Angle.Value := 600; Angle.ChangeTo(-151, 2.5, idcSingleRebound);
          Y.ChangeTo(ScaleH(2024), 2.5, idcBouncy);
        end;
        with TLadder.Create(ScaleW(1145),2) do begin
          Angle.Value := -50; Angle.ChangeTo(48, 2.2);
          Y.ChangeTo(ScaleH(1863), 2.2);
        end;
        PostMessage(401, 1.0);
        PostMessage(405);
      end else PostMessage(400);
    end;
    401: begin // explosion + big fire
      Audio.PlayThenKillSound('CollisionLong1.ogg', 1.0, 0.5, 1.0, Audio.FXReverbLong, 0.5);
      Audio.PlayThenKillSound('CollisionGlassBreakLong.ogg', 1.0, 0.5, 1.0, Audio.FXReverbLong, 0.5);
      TBigFire.Create(ScaleW(1166), ScaleH(2030), LAYER_FXANIM, FAtlas);
    end;
    405: begin // avoid LR to come back where is the fire
      if (FLR.CurrentFloor = 8) and (FLR.X.Value > ScaleW(1010)) then begin
        if FLR.Speed.x.Value > 0 then FLR.Speed.x.Value := 0;
        FLR.X.Value := ScaleW(1010);
      end;
      PostMessage(405);
    end;

    // LR looks in a crate
    500: begin
      FLR.State := lr4sBendDown;
      PostMessage(501, 1.0);
    end;
    501: begin // check if the crate is locked -> open it only if LR have 1 key or +
      if not FCrateHandledByLR.IsLocked then PostMessage(505)
      else begin
        if FInGameinventory.KeyCount = 0 then FLR.ShowDialog(sThisCrateIsLockedINeedAKeyToOpenIt, FFontText, Self, 520, 0, FCamera)
        else begin
          FInGameinventory.RemoveKey(1);  // use 1 key from inventory
          FCrateHandledByLR.RemoveLock;
          Audio.PlayThenKillSound('unlock-lock-unlock-door-inside.ogg', 1.0, 0.0, 1.0, Audio.FXReverbShort, 0.5);
          PostMessage(505, 1.0);
        end;
      end;
    end;
    505: begin // add the content of the crate to inventory panel
      FCrateHandledByLR.Enabled := False; // stop react when LR is near
      FLR.State := lr4sBendUp;
      case FCrateHandledByLR.ContentID of
        oicIDKey: PostMessage(510);
        oicIDSDCard: PostMessage(512);
        oicIDPropulsor: PostMessage(515);
      end;//case
    end;

    510: begin // add a key to inventory
      FInGameinventory.AddKey;
      Audio.PlayMusicSuccessShort1;
      FCrateHandledByLR.ContentID := oicIDNone;
      TKeySprite.Create;
      PostMessage(520, 1.0);
    end;

    512: FLR.ShowDialog(sAnSDCardIWillTakeIt, FFontText,Self, 513, 0, ScreenGameVolcanoInner.FCamera);
    513: begin // add SD card to inventory
      PlayerInfo.Volcano.HaveGreenSDCard := True;
      FSaveGame.Save;
      FInGameinventory.AddGreenSDCard;
      Audio.PlayMusicSuccessShort1;
      FCrateHandledByLR.ContentID := oicIDNone;
      TSDCardSprite.Create;
      PostMessage(520, 1.0);
    end;

    515: FLR.ShowDialog(sADorsalPropulsorINeedIt, FFontText,Self, 516, 0, ScreenGameVolcanoInner.FCamera);
    516: begin // add the dorsal propulsor to inventory
      PlayerInfo.Volcano.DorsalThruster.Level := 1;
      FSaveGame.Save;
      FInGameinventory.AddDorsalThruster;
      Audio.PlayMusicSuccessShort1;
      TPropulsorSprite.Create;
      FCrateHandledByLR.ContentID := oicIDNone;
      PostMessage(520, 1.0);
    end;

    520: begin
      FLR.State := lr4sBendUp;
      FGameState := gsRunning;
    end;

  end;
end;

procedure TScreenGameVolcanoInner.Update(const aElapsedTime: single);
var flagPlayerIdle: boolean;
  p: TPointF;
//  r: TRectF;
begin
  inherited Update(aElapsedTime);

  case FGameState of
    gsRunning: begin
      flagPlayerIdle := True;

      if Input.Action1Pressed and not FLR.IsOnLadder then begin
        FLR.State := lr4sJumping;
        flagPlayerIdle := False;
      end;

      if Input.LeftPressed and flagPlayerIdle then begin
        if FLR.IsOnLadder then begin
          if (FLR.LadderInUse <> NIL) and TLadderBase(FLR.LadderInUse).LRCanWalkToLeft then
            if FLR.State = lr4sOnLadderIdle then begin
              FLR.State := lr4sLeftWalking;
              flagPlayerIdle := False;
            end;
        end else begin
          FLR.State := lr4sLeftWalking;
          flagPlayerIdle := False;
        end;
      end;

      if Input.RightPressed and flagPlayerIdle then begin
        if FLR.IsOnLadder then begin
          if (FLR.LadderInUse <> NIL) and TLadderBase(FLR.LadderInUse).LRCanWalkToRight then
            if FLR.State = lr4sOnLadderIdle then begin
              FLR.State := lr4sRightWalking;
              flagPlayerIdle := False;
            end;
        end else begin
          FLR.State := lr4sRightWalking;
          flagPlayerIdle := False;
        end;
      end;

      if Input.UpPressed and flagPlayerIdle then begin
        if (FLR.LadderInUse <> NIL) and not (FLR.LadderInUse is TLadderTop) then
          if TLadderBase(FLR.LadderInUse).LRCanClimb then begin
            FLR.State := lr4sOnLadderUp;
            flagPlayerIdle := False;
          end;
      end;

      if Input.DownPressed and flagPlayerIdle then begin
         if FLR.LadderInUse <> NIL then
          if TLadderBase(FLR.LadderInUse).LRCanClimbDown then begin
            FLR.State := lr4sOnLadderDown;
            flagPlayerIdle := False;
          end;
      end;

      if Input.Action2Pressed and flagPlayerIdle
         and (FLR.ObjectToHandle <> NIL)
         and not FLR.IsOnLadder and not FLR.IsJumping then begin
        // here LR can interact with an object
        if FLR.ObjectToHandle is TWallWithDigicode then begin
          // digicode
          FDigicode.Disable;
          FGameState := gsDecodingDigicode;
          FsndPercuLoop.FadeOutThenKill(7.0);  // stop music
          FsndPercuLoop := NIL;
          PostMessage(150); // show some dialogs then decode
        end else
        if FLR.ObjectToHandle is TUsableCrateThatContainObject then begin
          // crate
          FCrateHandledByLR := TUsableCrateThatContainObject(FLR.ObjectToHandle); // save crate instance coz it'll be niled on next frame
          FGameState := gsLookInTheCrate;
          PostMessage(500); // anim LR looks in the crate
        end;
      end;

      if flagPlayerIdle then FLR.SetIdlePosition;

      // bug: if LR is on ladder and LR.LadderInUse = NIL
      if FLR.IsOnLadder and (FLR.LadderInUse = NIL) and flagPlayerIdle then begin
        // move LR on the nearest floor
        FLR.CurrentFloor := GetNearestFloor(FLR.GetYBottom);
        FLR.IdleRight;
      end;

    end;// gsRunning
  end;//case

  // check if player pause the game
  if Input.PausePressed then
    FInGamePausePanel.ShowModal;

  // camera follow LR in the bounds of FViewArea
  if FCameraFollowLR then begin
    p.x := EnsureRange(FLR.X.Value, FViewArea.Left, FViewArea.Right);
    p.y := EnsureRange(FLR.Y.Value, FViewArea.Top, FViewArea.Bottom);
    MoveCameraTo(p, 0.0);
    // audio listener position follow LR position
    Audio.SetListenerPosition(FLR.X.Value, FLR.Y.Value)
  end else begin
    // audio listener position follow camera view center
    p := GetCameraCenterView;
    Audio.SetListenerPosition(p.x, p.y);
  end;

  // sound boiling lava
  ScreenGameVolcanoInner.SetBoilingLavaVolume(TLava.BoilingVolume);
  TLava.BoilingVolume := 0.0;
end;

procedure TScreenGameVolcanoInner.MoveCameraTo(const p: TPointF; aDuration: single);
begin
  FCamera.MoveTo(PointF(p.Truncate), aDuration, idcSinusoid);
  // camera BG
  FCameraBGWall.MoveTo(p*0.96, aDuration, idcSinusoid);
end;

procedure TScreenGameVolcanoInner.ZoomCameraTo(const z: TPointF; aDuration: single);
begin
  FCamera.Scale.ChangeTo(z, aDuration, idcSinusoid);
  FCameraBGWall.Scale.ChangeTo(z, aDuration, idcSinusoid);
end;

function TScreenGameVolcanoInner.GetCameraCenterView: TPointF;
begin
  Result := FCamera.LookAt.Value*(-1);
  Result := Result + FScene.Center;
end;

procedure TScreenGameVolcanoInner.ProcessPlayerEnterCheatCode(const aCheatCode: string);
begin
  if aCheatCode = VolcanoInnerCheatCode then
    FLRIsInvisible := True;
end;

procedure TScreenGameVolcanoInner.SetBoilingLavaVolume(AValue: single);
begin
  FsndBoilingLava.Volume.Value := AValue;
end;

end.

