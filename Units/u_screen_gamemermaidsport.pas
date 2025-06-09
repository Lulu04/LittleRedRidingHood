unit u_screen_gamemermaidsport;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon, u_sprite_def, u_sprite_def2;

type

{ TScreenMermaidsPort }

TScreenMermaidsPort = class(TGameScreenTemplate)
private type TGameState=(gsUndefined,
                         gsRunning,
                         gsLRFalling,   // when LR fall from platform or container
                         gsLRWin,
                         gsLookInTheCrate,
                         gsLRCollideRoad,
                         gsLROpenGate, gsShowMessLRNeedKeyToOpenGate,
                         gsLRUseControlPanel
                         );
var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FInGamePausePanel: TInGamePausePanel;
  FRain: TParticleEmitter;
  FsndRain: TALSSound;
  FLRYBeforeFalling: single;
  procedure ResetVariables;
  procedure StartRain(aDuration: single);
  procedure StopRain;
  procedure ProcessLAYERGROUNDBeforeUpdate;
  procedure CreateClouds; // LAYER_BG3
  procedure CreateGround; // LAYER_BG3
  procedure CreateFactory3; // LAYER_BG2
  procedure CreateFactory2; // LAYER_BG1
  procedure CreateFactory1(var aX: single; aCount: integer); // LAYER_GROUND
  procedure CreateBGFence(aXBegin, aXEnd: single);
  procedure CreateLevel(aLevelIndex: integer);
  procedure CreateLevel1;
  procedure CreateLevel2;
  procedure CreateLevel3;
  procedure FadeOutAndKillMusicAndSounds;
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenMermaidsPort: TScreenMermaidsPort;

implementation

uses Forms, u_screen_map, u_app, u_utils, Math, u_sprite_lr4dir, u_sprite_wolf,
  u_gamebackground, u_mousepointer, u_lr4_usable_object, u_resourcestring, Graphics;

const FACTORY1_SCALE = 2.0;
      FACTORY2_SCALE = 1.5;
      FACTORY3_SCALE = 2.0;
var FWorldArea,  // the size of the word
    FViewArea: TRectF; // the constrained size for the camera

function FloorHeight: integer; inline;
begin
  Result := ScaleH(229);
end;

function GetYGround: single;
begin
  Result := FWorldArea.Bottom - ScaleH(100);
end;

function GetYFloor(aFloorIndex: integer): single;
begin
  Result := GetYGround - FloorHeight * aFloorIndex;   //242     229
end;

type

{ TCustomPanelUsingControlPanel0 }

TCustomPanelUsingControlPanel0 = class(TPanelUsingControlPanel0)
  constructor Create;
end;

TMetalKeyThatGoInInventory = class(TSpriteThatGoInInventory)
  constructor Create(aUserValue: TUserMessageValue);
end;

TGameInventory = class(TInGameInventoryPanel)
private
  FKey: TUIKeyMetalCounter;
public
  procedure AddKey;
end;

TRemoteThatGoInInventory = class(TSpriteThatGoInInventory)
  constructor Create;
end;


TCraneRemote = class(TSprite)
private class var texBody, texLedBG, texPadLeft, texConnected: PTexture;
private
  FConnected, FActivated: boolean;
  FLed, FPadLeft, FPadRight, FPadUp, FPadDown, FTextConnected: TSprite;
  FPadActivated: TSprite;
  procedure SetActivated(AValue: boolean);
  procedure SetConnected(AValue: boolean);
public
  class procedure LoadTexture(aAtlas: TAtlas);
  constructor Create;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure DeactivateAllDirection;
  procedure ActivateLeftDirection;
  procedure ActivateRightDirection;
  procedure ActivateUpDirection;
  procedure ActivateDownDirection;

  procedure EnableLeftDirection(aValue: boolean);
  procedure EnableRightDirection(aValue: boolean);
  procedure EnableUpDirection(aValue: boolean);
  procedure EnableDownDirection(aValue: boolean);

  // set to true when player have pressed ACTION2 to use the remote
  property Activated: boolean read FActivated write SetActivated;
  // set to true when LR walk on a container
  property Connected: boolean read FConnected write SetConnected;
end;

TSky = class(TGradientRectangle) // LAYER_BG3
private
  FStormIsActive: boolean;
  FStormIndex: integer;
public
  constructor Create;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure StartStorm;
  procedure StopStorm;
end;

TRoad = class(TQuad4Color)  // LAYER_GROUND
  FTruckZOrder: integer;
  constructor Create(aX: single);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  class procedure CheckIfLRCollideARoadAfterABigFall;
end;

{ TTruck }

TTruck = class(TSprite)
private
  FSndEngine: TALSSound;
  FFlagUpdate: boolean; // to update sound only 1 frame on 2
  procedure ComputeVolumeAndPan(out vol, pan: single);
public
  constructor Create(aTexture: PTexture; aParentRoad: TRoad; aZOrder: integer);
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

TSewerPlate = class(TSprite)  // LAYER_GROUND
  constructor Create(aX: single);
end;

TFenceGate = class(TSprite) // LAYER_ARROW
private
  FGates: array[0..5] of TSprite;
  FOpened: boolean;
public
 constructor Create(aX, aY: single);
 procedure Update(const aElapsedTime: single); override;
 procedure Open;
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
  constructor Create(aX: single; aFloorIndex: integer);
  procedure Update(const aElapsedTime: single); override;
end;


// when LR is on the container, she becomes a child of the container
// when she jump, from the container, she remove this child dependency

{ TSuspendedContainer }

TSuspendedContainer = class(TSprite) // LAYER_FXANIM
private type TLastMove = (lsmIdle, lsmleft, lsmRight, lsmUp, lsmDown);
  var FLastMove: TLastMove;
private // automatic
  FCraneHook: TSprite;
  FAutomaticPath: TArrayOfInteger;
  FPathIndex: integer; // by pair: first is x,  second is FloorIndex
  FPauseBetweenStep: single;
  FAutomaticMode: boolean;
  function ComputeMovingTime(aNewCoor: TPointF): single;
private // manual
  FManualConstraints: TArrayOfInteger; // by 3: first is FloorIndex,  second is xMin,  third is xMax
                                       // several ranges per floor are possible
  FFloorMin, FFloorMax: integer;
  FChangingFloor: boolean;
  FXMin, FXMax: single;
  procedure GetXMinMax(aFloorIndex: integer; out aXMin, aXMax: integer);
public
  FloorIndex: integer;
  constructor Create;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  class procedure CheckLRFeetOnContainer;
  class function LRFallOnContainer: boolean;
  // by pair: first is x,  second is FloorIndex
  procedure SetAutomaticPath(A: TArrayOfInteger; aAddReverseData: boolean);
  procedure RunAutomaticSequence;
  procedure StopAutomaticSequence;

  // by 3: first is FloorIndex,  second is xMin,  third is xMax
  // several ranges per floor are possible
  procedure SetManualPathConstraints(A: TArrayOfInteger);
  procedure MoveToLeft;
  procedure MoveToRight;
  procedure MoveToUp;
  procedure MoveToDown;
  procedure Idle;
  procedure ResetFlagLastMove;
  function CanMoveLeft: boolean;
  function CanMoveRight: boolean;
  function CanMoveUp: boolean;
  function CanMoveDown: boolean;
  // true when the container change floor. used to avoid LR jump/move when changing floor
  property ChangingFloor: boolean read FChangingFloor;
public
  class procedure PlayAudioRelay;
end;

TCustomUsableControlPanel = class(TUsableControlPanel)
  TargetContainer: TSuspendedContainer;
  constructor Create(aX, aBottomY: single; aLayerIndex: integer; aLR4DirInstance: TLR4Direction;
                       aTargetContainer: TSuspendedContainer);
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

TPlatform4Legs = class(TSprite) // LAYER_ARROW + LAYER_GROUND
private
  FGrounds: array of TSprite;
  FFloorIndex: integer;
public
  constructor Create(aX: single; aFloorIndex, aSecondaryPlatformCount: integer; aUsePlatformForLadder: boolean=False);
  class procedure CheckLRFeetOnPlatform;
  class function LRFallOnPlatform: boolean;
  property FloorIndex: integer read FFloorIndex write FFloorIndex;
end;

TPlatformWithLadder = class(TPlatform4Legs)
  Ladder: TSprite;
  constructor Create(aX: single; aFloorIndex, aSecondaryPlatformCount: integer);
  procedure Update(const aElapsedTime: single); override;
  function LRCanGoUp: boolean;
  function LRCanGoDown: boolean;
end;

TCustomLR4Direction = class(TLR4Direction)
private
  FCanClimbOnLadder, FIsAboveLadder: boolean;
  FFloorIndex: integer;
  function GetFloorIndex: integer;
  procedure SetFloorIndex(AValue: integer);
protected
  procedure ProcessCallbackDoOnJumpMove(aMoveDuration: single; aJumpStep: integer); override;
public
  HaveFeetOnPlatform: boolean; // set to true by a TPlatform instance
  HaveFeetOnContainer: boolean; // set to true by a TSuspendedContainer instance
  ContainerToControl: TSuspendedContainer;
  property CanClimbOnLadder: boolean read FCanClimbOnLadder write FCanClimbOnLadder;
  property IsAboveLadder: boolean read FIsAboveLadder write FIsAboveLadder;
  property FloorIndex: integer read GetFloorIndex write SetFloorIndex;
end;


var
  FAtlas: TAtlas;
  FFontText: TTexturedFont;
  texTruckYellow, texTruckBlue, texTruckGreen,
  texFactory1, texFactory2, texFactory3,
  texCraneHook, texCraneHookBG, texContainer, texPanelExit,
  texControlPanel, texPlatformLeg, texPlatformGround, texPlatformGroundForLadder, texPlatformLadder,
  texSewerPlate, texBarrel, texGroundStain, texBGFenceVertical, texBGFenceHorizontal,
  texFence: PTexture;

  FSky: TSky;
  FLR: TCustomLR4Direction;
  FCamera, FCameraFactory2, FCameraFactory3: TOGLCCamera;
  FPanelUsingControlPanel0: TPanelUsingControlPanel0;
  FControlPanelInUse: TCustomUsableControlPanel;
  FCraneRemote: TCraneRemote;
  FCrateHandledByLR: TUsableCrateThatContainObject;
  FsndBuzzer: TALSSound;
  FGameinventory: TGameInventory;
  FWorkingGate: TFenceGate;
  FFenceGateSubSequence: boolean;

{ TCustomPanelUsingControlPanel0 }

constructor TCustomPanelUsingControlPanel0.Create;
var lab: TUILabel;
  o: TSprite;
begin
  inherited Create(sStartSequence, FFontText, FAtlas);
  BStart.AnchorPosToParent(haCenter, haCenter, 0, vaBottom, vaBottom, -Round(BStart.Height*1.5));

  // label marcus transport
  lab := TUILabel.Create(FScene, sMarcusTransport, FFontText);
  AddChild(lab, 0);
  lab.AnchorHPosToParent(haCenter, haCenter, 0);
  lab.Y.Value := lab.Height*2;

  // container icon
  o := TSprite.Create(texContainer, False);
  AddChild(o, 0);
  o.SetSize(ScaleW(88), ScaleH(49));
  o.CenterX := Width*0.5;
  o.Y.Value := lab.BottomY;
end;

{ TFenceGate }

constructor TFenceGate.Create(aX, aY: single);
begin
  inherited Create(texFence, False);
  FScene.Add(Self, LAYER_ARROW);
  SetCoordinate(aX, aY+ScaleH(216));
  FGates[0] := Self;

  FGates[1] := TSprite.Create(texFence, False);
  FScene.Add(FGates[1], LAYER_ARROW);
  FGates[1].SetCoordinate(aX+ScaleW(38), aY+ScaleH(173));

  FGates[2] := TSprite.Create(texFence, False);
  FScene.Add(FGates[2], LAYER_ARROW);
  FGates[2].SetCoordinate(aX+ScaleW(77), aY+ScaleH(130));

  FGates[3] := TSprite.Create(texFence, False);
  FScene.Add(FGates[3], LAYER_ARROW);
  FGates[3].SetCoordinate(aX+ScaleW(115), aY+ScaleH(86));

  FGates[4] := TSprite.Create(texFence, False);
  FScene.Add(FGates[4], LAYER_ARROW);
  FGates[4].SetCoordinate(aX+ScaleW(154), aY+ScaleH(43));

  FGates[5] := TSprite.Create(texFence, False);
  FScene.Add(FGates[5], LAYER_ARROW);
  FGates[5].SetCoordinate(aX+ScaleW(192), aY+ScaleH(0));
end;

procedure TFenceGate.Update(const aElapsedTime: single);
var xx: single;
begin
  inherited Update(aElapsedTime);

  if FLR.ParentSurface <> NIL then exit;
  if FOpened then exit;

  // check if LR bump into the gate
  xx := FGates[0].X.Value + texFence^.FrameWidth * 1.5;
  if FLR.X.Value > xx then begin
    FLR.X.Value := xx - PPIScale(2);
    if not FFenceGateSubSequence and (ScreenMermaidsPort.GameState = gsRunning) then begin
      FWorkingGate := Self;
      if (FGameInventory.FKey <> NIL) and (FGameInventory.FKey.Count > 0)
        then ScreenMermaidsPort.GameState := gsLROpenGate
        else ScreenMermaidsPort.GameState := gsShowMessLRNeedKeyToOpenGate;
    end;
  end;
end;

procedure TFenceGate.Open;
begin
  if FOpened then exit;
  FGates[2].MoveTo(FGates[1].GetXY, 1.0);
  FGates[2].KillDefered(1.0);

  FGates[3].MoveTo(FGates[4].GetXY, 1.0);
  FGates[3].KillDefered(1.0);

  FGates[4].MoveToLayer(LAYER_FXANIM);
  FGates[5].MoveToLayer(LAYER_FXANIM);

  FOpened := True;
end;

{ TMetalKeyThatGoInInventory }

constructor TMetalKeyThatGoInInventory.Create(aUserValue: TUserMessageValue);
begin
  inherited Create(texKeyMetal, LAYER_GAMEUI, FLR, FGameinventory, ScreenMermaidsPort, aUserValue);
end;

{ TGameInventory }

procedure TGameInventory.AddKey;
begin
  if FKey = NIL then begin
    FKey := TUIKeyMetalCounter.Create;
    AddItem(FKey);
    FKey.Count := 1;
  end else FKey.Count := FKey.Count + 1;
end;

{ TUsableControlPanel }

constructor TCustomUsableControlPanel.Create(aX, aBottomY: single;
  aLayerIndex: integer; aLR4DirInstance: TLR4Direction; aTargetContainer: TSuspendedContainer);
begin
  inherited Create(aX, aBottomY, aLayerIndex, aLR4DirInstance);
  TargetContainer := aTargetContainer;
end;

{ TRemoteThatGoInInventory }

constructor TRemoteThatGoInInventory.Create;
begin
  inherited Create(texIconCraneRemote, LAYER_GAMEUI, FLR.SurfaceToScene(PointF(0, -FLR.DeltaYToTop)),
  PointF(0, 0), ScreenMermaidsPort, 316);
end;

{ TCraneRemote }

procedure TCraneRemote.SetConnected(AValue: boolean);
begin
  if FConnected = AValue then exit;
  FConnected := AValue;
  if AValue then PostMessage(0);
  if AValue then begin
    Scale.ChangeTo(PointF(1, 1), 0.25, idcSinusoid);
    Audio.PlayThenKillSound('phone-connecting-with-charger.ogg', 1.0, -0.8)
  end else begin
    Scale.ChangeTo(PointF(0.5, 0.5), 0.25, idcSinusoid);
    Audio.PlayThenKillSound('phone-connecting-with-chargerReversed.ogg', 1.0, -0.8);
  end;
end;

procedure TCraneRemote.SetActivated(AValue: boolean);
begin
  if FActivated = AValue then exit;
  FActivated := AValue;
  if AValue then FLed.Tint.Value := BGRA(98,255,98)
    else FLed.Tint.Alpha.Value := 0;
end;

class procedure TCraneRemote.LoadTexture(aAtlas: TAtlas);
var path: string;
  fd: TFontDescriptor;
begin
  path := FolderSpriteGameMermaidsPort;
  texBody := aAtlas.AddFromSVG(path+'RemoteBody.svg', -1, ScaleH(136));
  texLedBG := aAtlas.AddFromSVG(path+'RemoteLedBG.svg', ScaleW(52), -1);
  texPadLeft := aAtlas.AddFromSVG(path+'RemoteLeft.svg', ScaleW(13), -1);

  fd.Create('Arial', 10, [fsBold], BGRA(98,200,98));
  fd.ComputeMaxHeightFor(sConnected, Rect(0, 0, ScaleW(58), ScaleH(13)));
  texConnected := aAtlas.AddString(sConnected, fd, NIL);
end;

constructor TCraneRemote.Create;
begin
  inherited Create(texBody, False);
  FScene.Add(Self, LAYER_GAMEUI);

  FLed := CreateSpriteChild(texLedBG, False, -1);
  FLed.SetCoordinate(ScaleW(12), ScaleH(34));

  FPadLeft := CreateSpriteChild(texPadLeft, False, 0);
  FPadLeft.SetCoordinate(ScaleW(12), ScaleH(92));

  FPadRight := CreateSpriteChild(texPadLeft, False, 0);
  FPadRight.FlipH := True;
  FPadRight.SetCoordinate(ScaleW(50), ScaleH(92));

  FPadUp := CreateSpriteChild(texPadLeft, False, 0);
  FPadUp.Angle.Value := 90;
  FPadUp.SetCenterCoordinate(ScaleW(37), ScaleH(84));

  FPadDown := CreateSpriteChild(texPadLeft, False, 0);
  FPadDown.Angle.Value := -90;
  FPadDown.SetCenterCoordinate(ScaleW(37), ScaleH(121));

  FTextConnected := CreateSpriteChild(texConnected, False, 1);
  FTextConnected.SetCenterCoordinate(ScaleW(38), ScaleH(59));
  FTextConnected.Visible := False;

  Scale.Value := PointF(0.5,0.5);

  PostMessage(50); // PAD BLINK
end;

procedure TCraneRemote.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // ANIM led blink
    0: begin
      if not FConnected then begin
        FTextConnected.Visible := False;
        exit;
      end;
      FTextConnected.Visible := True;
      PostMessage(2, 0.25);
    end;
    2: begin
      FTextConnected.Visible := False;
      if FConnected then PostMessage(0, 0.25);
    end;

    // ANIM PAD BLINK
    50: begin
      if FPadActivated <> NIL then
        FPadActivated.Tint.Value := BGRA(255,255,255);
      PostMessage(52, 0.25);
    end;
    52: begin
      if FPadActivated <> NIL then
        FPadActivated.Tint.Alpha.Value := 0;
      PostMessage(50, 0.25);
    end;
  end;
end;

procedure TCraneRemote.DeactivateAllDirection;
begin
  FPadActivated := NIL;
  FPadLeft.Tint.Alpha.Value := 0;
  FPadRight.Tint.Alpha.Value := 0;
  FPadUp.Tint.Alpha.Value := 0;
  FPadDown.Tint.Alpha.Value := 0;
end;

procedure TCraneRemote.ActivateLeftDirection;
begin
  FPadActivated := FPadLeft;
end;

procedure TCraneRemote.ActivateRightDirection;
begin
  FPadActivated := FPadRight;
end;

procedure TCraneRemote.ActivateUpDirection;
begin
  FPadActivated := FPadUp;
end;

procedure TCraneRemote.ActivateDownDirection;
begin
  FPadActivated := FPadDown;
end;

procedure TCraneRemote.EnableLeftDirection(aValue: boolean);
begin
  if not aValue then FPadLeft.Tint.Value := BGRA(255,0,0)
    else if FPadLeft.Tint.Value = BGRA(255,0,0) then FPadLeft.Tint.Alpha.Value := 0;
end;

procedure TCraneRemote.EnableRightDirection(aValue: boolean);
begin
  if not aValue then FPadRight.Tint.Value := BGRA(255,0,0)
    else if FPadRight.Tint.Value = BGRA(255,0,0) then FPadRight.Tint.Alpha.Value := 0;
end;

procedure TCraneRemote.EnableUpDirection(aValue: boolean);
begin
  if not aValue then FPadUp.Tint.Value := BGRA(255,0,0)
    else if FPadUp.Tint.Value = BGRA(255,0,0) then FPadUp.Tint.Alpha.Value := 0;
end;

procedure TCraneRemote.EnableDownDirection(aValue: boolean);
begin
  if not aValue then FPadDown.Tint.Value := BGRA(255,0,0)
    else if FPadDown.Tint.Value = BGRA(255,0,0) then FPadDown.Tint.Alpha.Value := 0;
end;

{ TPanelExit }

constructor TPanelExit.Create(aX: single; aFloorIndex: integer);
begin
  inherited Create(texPanelExit, False);
  FScene.Add(Self, LAYER_GROUND);
  X.Value := aX;
  BottomY := GetYFloor(aFloorIndex);
end;

procedure TPanelExit.Update(const aElapsedTime: single);
var r: TRectF;
begin
  inherited Update(aElapsedTime);
  // check if LR collide the panel -> game win
  r := GetMatrixSurfaceToWorld.Transform(GetRectAreaInLocalSpace);
  if FLR.CheckCollisionWith(r) then begin
    ScreenMermaidsPort.GameState := gsLRWin;
  end;
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

{ TBarrel }

constructor TBarrel.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(texBarrel, False);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
end;

{ TCustomLR4Direction }

function TCustomLR4Direction.GetFloorIndex: integer;
begin
 { if IsOnLadder then Result := -1
    else} Result := FFloorIndex;
end;

procedure TCustomLR4Direction.SetFloorIndex(AValue: integer);
begin
  FFloorIndex := AValue;
 { Y.Value := GetYFloor(AValue);  }
end;

procedure TCustomLR4Direction.ProcessCallbackDoOnJumpMove(aMoveDuration: single; aJumpStep: integer);
begin
  inherited ProcessCallbackDoOnJumpMove(aMoveDuration, aJumpStep);
  if aJumpStep = 2 then begin
    ScreenMermaidsPort.GameState := gsLRFalling;
  end;
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

// compare function to sort sprite by BottomY values, like in rpg.
{function LayerSortCompare(Item1, Item2: Pointer): Integer;
var yBottom1, yBottom2: single;
begin
  if Item1 = Pointer(FLR) then yBottom1 := FLR.BodyBottomY else yBottom1 := TSimpleSurfaceWithEffect(Item1).ScaledBottomY;
  if Item2 = Pointer(FLR) then yBottom2 := FLR.BodyBottomY else yBottom2 := TSimpleSurfaceWithEffect(Item2).ScaledBottomY;
  Result := Trunc(yBottom1 - yBottom2);
end;  }

{ TPlatformWithLadder }

constructor TPlatformWithLadder.Create(aX: single; aFloorIndex, aSecondaryPlatformCount: integer);
begin
  inherited Create(aX, aFloorIndex, aSecondaryPlatformCount, True);
  Ladder := TSprite.Create(texPlatformLadder, False);
  FGrounds[0].AddChild(Ladder, 2);
  Ladder.SetCoordinate(ScaleW(50), ScaleH(18));
end;

procedure TPlatformWithLadder.Update(const aElapsedTime: single);
var xx1, xx2, yy1, yy2: single;
begin
  inherited Update(aElapsedTime);

  xx1 := X.Value + Ladder.X.Value + Ladder.Width*0.3;
  xx2 := X.Value + Ladder.X.Value + Ladder.Width*0.7;

  if not InRange(FLR.X.Value, xx1, xx2) then exit;

  yy1 := Y.Value + Ladder.Y.Value;
  yy2 := yy1 + Ladder.Height;

  // check if LR can climb on ladder
  if (FLR.FloorIndex = FloorIndex) and InRange(FLR.BodyBottomY, yy1, yy2) and
     (FLR.ParentSurface = NIL) then begin
    FLR.CanClimbOnLadder := True;
    FLR.LadderInUse := Self;
  end
  else
  // check if LR is above the ladder
  if (FLR.FloorIndex = FloorIndex+1) {and (FLR.BodyBottomY <= yy1-FLR.YDeltaToMoveOnLadder)} and
     (FLR.ParentSurface = NIL) then begin
    FLR.IsAboveLadder := True;
    FLR.LadderInUse := Self;
  end;
end;

function TPlatformWithLadder.LRCanGoUp: boolean;
begin
  Result := FLR.BodyBottomY > (Y.Value + FLR.YDeltaToMoveOnLadder*4);  //3
end;

function TPlatformWithLadder.LRCanGoDown: boolean;
begin
  Result := FLR.BodyBottomY < (Y.Value + FLR.YDeltaToMoveOnLadder*9);
end;

{ TPlatform4Legs }

constructor TPlatform4Legs.Create(aX: single; aFloorIndex,
  aSecondaryPlatformCount: integer; aUsePlatformForLadder: boolean);
var o, o1: TSprite;
  xx: single;
  groundZOrder, i: integer;
begin
  inherited Create(texPlatformLeg, False);
  FScene.Add(Self, LAYER_ARROW);
  X.Value := aX;
  BottomY := GetYFloor(aFloorIndex)+ScaleH(4);

  o := TSprite.Create(texPlatformLeg, False);
  AddChild(o, 0);
  o.SetCoordinate(ScaleW(170), 0);
  ////
  o := TSprite.Create(texPlatformLeg, False);
  FScene.Add(o, LAYER_GROUND);
  o.X.Value := aX+ScaleW(22);
  o.BottomY := GetYFloor(aFloorIndex)-ScaleH(18);
  o.Tint.Value := BGRA(0,0,0,80);

  o1 := TSprite.Create(texPlatformLeg, False);
  o.AddChild(o1, -2);
  o1.SetCoordinate(ScaleW(170), 0);
  o1.Tint.Value := BGRA(0,0,0,80);

  groundZOrder := 1;
  FGrounds := NIL;
  SetLength(FGrounds, aSecondaryPlatformCount+1);
  if not aUsePlatformForLadder
    then FGrounds[0] := TSprite.Create(texPlatformGround, False)
    else FGrounds[0] := TSprite.Create(texPlatformGroundForLadder, False);
  o.AddChild(FGrounds[0], groundZOrder);
  FGrounds[0].SetCoordinate(ScaleW(-23), ScaleH(-4));

  xx := ScaleW(158);
  i := 1;
  while aSecondaryPlatformCount > 0 do begin
    inc(groundZOrder);
    FGrounds[i] := TSprite.Create(texPlatformGround, False);
    o.AddChild(FGrounds[i], groundZOrder);
    FGrounds[i].SetCoordinate(xx, ScaleH(-4));

    o1 := TSprite.Create(texPlatformLeg, False);
    FScene.Add(o1, LAYER_ARROW);
    o1.X.Value := aX+xx+ScaleW(191);
    o1.BottomY := GetYFloor(aFloorIndex)+ScaleH(4);

    o1 := TSprite.Create(texPlatformLeg, False);
    o.AddChild(o1, 0);
    o1.SetCoordinate(xx+ScaleW(189), 0);
    o1.Tint.Value := BGRA(0,0,0,80);

    dec(aSecondaryPlatformCount);
    xx := xx + ScaleW(158);
    inc(i);
  end;

  FloorIndex := aFloorIndex;

{  inherited Create(texPlatformLeg, False);
  FScene.Add(Self, LAYER_GROUND);
  X.Value := aX;
  BottomY := GetYFloor(aFloorIndex);

  o := TSprite.Create(texPlatformLeg, False);
  AddChild(o, 0);
  o.SetCoordinate(ScaleW(170), 0);

  o := TSprite.Create(texPlatformLeg, False);
  AddChild(o, -2);
  o.SetCoordinate(ScaleW(22), ScaleH(-18));
  o.Tint.Value := BGRA(0,0,0,80);

  o := TSprite.Create(texPlatformLeg, False);
  AddChild(o, -2);
  o.SetCoordinate(ScaleW(192), ScaleH(-18));
  o.Tint.Value := BGRA(0,0,0,80);

  FGrounds := NIL;
  SetLength(FGrounds, aSecondaryPlatformCount+1);
  FGrounds[0] := TSprite.Create(texPlatformGround, False);
  AddChild(FGrounds[0], 1);
  FGrounds[0].SetCoordinate(ScaleW(0), ScaleH(-22));

  xx := ScaleW(180);
  groundZOrder := 2;
  i := 1;
  while aSecondaryPlatformCount > 0 do begin
    FGrounds[i] := TSprite.Create(texPlatformGround, False);
    AddChild(FGrounds[i], groundZOrder);
    FGrounds[i].SetCoordinate(xx, ScaleH(-22));

    o := TSprite.Create(texPlatformLeg, False);
    AddChild(o, 0);
    o.SetCoordinate(xx+ScaleW(171), 0);

    o := TSprite.Create(texPlatformLeg, False);
    AddChild(o, 0);
    o.SetCoordinate(xx+ScaleW(193), ScaleH(-18));
    o.Tint.Value := BGRA(0,0,0,80);

    dec(aSecondaryPlatformCount);
    xx := xx + ScaleW(180);
    inc(groundZOrder);
    inc(i);
  end;

  FloorIndex := aFloorIndex;  }
end;

class procedure TPlatform4Legs.CheckLRFeetOnPlatform;
var x1, x2: single;
  i, j: integer;
  p: TPointF;
  o: TPlatform4Legs;
begin
  if FLR.ParentSurface <> NIL then exit;

  for i:=0 to FScene.Layer[LAYER_ARROW].SurfaceCount-1 do
    if FScene.Layer[LAYER_ARROW].Surface[i] is TPlatform4Legs then begin
      o := TPlatform4Legs(FScene.Layer[LAYER_ARROW].Surface[i]);
      // check if LR have feet on one of the platforms
      if //not FLR.HaveFeetOnPlatform and
         (FLR.FloorIndex = o.FloorIndex+1) then begin
        for j:=0 to High(o.FGrounds) do begin
          p := o.FGrounds[j].SurfaceToSceneWithoutLayerTransform(PointF(0, 0));
          x1 := p.x + texPlatformGround^.FrameWidth*0.05;
          x2 := p.x + texPlatformGround^.FrameWidth*0.95;
          if InRange(FLR.X.Value, x1, x2) then begin
            FLR.HaveFeetOnPlatform := True;
            exit;
          end;
        end;
      end;
  end;
end;

class function TPlatform4Legs.LRFallOnPlatform: boolean;
var x1, x2: single;
  i, j: integer;
  p: TPointF;
  o: TPlatform4Legs;
begin
  Result := False;
  for i:=0 to FScene.Layer[LAYER_ARROW].SurfaceCount-1 do
    if FScene.Layer[LAYER_ARROW].Surface[i] is TPlatform4Legs then begin
      o := TPlatform4Legs(FScene.Layer[LAYER_ARROW].Surface[i]);

      for j:=0 to High(o.FGrounds) do begin
        p := o.FGrounds[j].SurfaceToSceneWithoutLayerTransform(PointF(0, 0));
        x1 := p.x + texPlatformGround^.FrameWidth*0.05;
        x2 := p.x + texPlatformGround^.FrameWidth*0.95;
        if InRange(FLR.X.Value, x1, x2) and
           InRange(FLR.BodyBottomY, p.y, p.y+texPlatformGround^.FrameHeight) then begin
          FLR.Speed.Value := PointF(0, 0);
          FLR.SetIdlePosition;
          FLR.BodyBottomY := o.FGrounds[j].ParentSurface.Y.Value+ScaleH(11);
          FLR.FloorIndex := o.FloorIndex+1;
          Result := True;
          exit;
        end;
      end;
  end;
end;

{ TFactory3 }

constructor TFactory3.Create(aX: single);
begin
  inherited Create(texFactory3, False);
  FScene.Add(Self, LAYER_BG2);
  Scale.Value := PointF(FACTORY3_SCALE, FACTORY3_SCALE);
  ScaledX := aX;
  ScaledBottomY := FScene.Height-ScaleH(297);
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

{ TFactory2 }

constructor TFactory2.Create(aX: single);
begin
  inherited Create(texFactory2, False);
  FScene.Add(Self, LAYER_BG1);
  Scale.Value := PointF(FACTORY2_SCALE, FACTORY2_SCALE);
  ScaledX := aX;
  ScaledBottomY := FScene.Height-ScaleH(296);
end;

{ TSuspendedContainer }

function TSuspendedContainer.ComputeMovingTime(aNewCoor: TPointF): single;
var delta: single;
begin
  if aNewCoor.x = X.Value then delta := Abs(Y.Value-aNewCoor.y) else delta := Abs(X.Value-aNewCoor.x);
  Result := delta/(FScene.Width*0.125);
end;

function TSuspendedContainer.CanMoveLeft: boolean;
var i: integer;
begin
  i := 0;
  while i < High(FManualConstraints) do begin
    if (FManualConstraints[i] = FloorIndex) and
       (X.Value > FManualConstraints[i+1]) and
       (X.Value <= FManualConstraints[i+2]) then begin
      FXMin := FManualConstraints[i+1];
      FXMax := FManualConstraints[i+2];
      exit(True);
    end;
    inc(i, 3);
  end;
  Result := False;
end;

function TSuspendedContainer.CanMoveRight: boolean;
var i: integer;
begin
  i := 0;
  while i < High(FManualConstraints) do begin
    if (FManualConstraints[i] = FloorIndex) and
       (X.Value >= FManualConstraints[i+1]) and
       (X.Value < FManualConstraints[i+2]) then begin
      FXMin := FManualConstraints[i+1];
      FXMax := FManualConstraints[i+2];
      exit(True);
    end;
    inc(i, 3);
  end;
  Result := False;
end;

function TSuspendedContainer.CanMoveUp: boolean;
var i: integer;
begin
  if FloorIndex = FFloorMax then exit(False);
  i := 0;
  while i < High(FManualConstraints) do begin
    if (FManualConstraints[i] = FloorIndex+1) and
       InRange(X.Value, FManualConstraints[i+1], FManualConstraints[i+2]) then exit(True);
    inc(i, 3);
  end;
  Result := False;
end;

function TSuspendedContainer.CanMoveDown: boolean;
var i: integer;
begin
  if FloorIndex = FFloorMin then exit(False);
  i := 0;
  while i < High(FManualConstraints) do begin
    if (FManualConstraints[i] = FloorIndex-1) and
       InRange(X.Value, FManualConstraints[i+1], FManualConstraints[i+2]) then exit(True);
    inc(i, 3);
  end;
  Result := False;
end;

class procedure TSuspendedContainer.PlayAudioRelay;
begin
  Audio.PlayThenKillSound('buzzing-relay.ogg', 2.0, 0.0, 1.0, Audio.FXReverbShort, 0.5);
end;

procedure TSuspendedContainer.GetXMinMax(aFloorIndex: integer; out aXMin, aXMax: integer);
var i: integer;
begin
  i := 0;
  while i < High(FManualConstraints) do begin
    if FManualConstraints[i] = aFloorIndex then begin
      aXMin := FManualConstraints[i+1];
      aXMax := FManualConstraints[i+2];
      exit;
    end;
    inc(i, 3);
  end;
  raise exception.create('bug');
end;

constructor TSuspendedContainer.Create;
var o: TSprite;
  c: TShapeOutline;
begin
  inherited Create(texContainer, False);
  FScene.Add(Self, LAYER_FXANIM);
  Pivot := PointF(0.52, -3.0);

  FCraneHook := CreateSpriteChild(texCraneHook, False, 0);
  FCraneHook.SetCoordinate(ScaleW(152), ScaleH(-106));

  o := TSprite.Create(texCraneHookBG, False);
  FCraneHook.AddChild(o, -2);
  o.SetCoordinate(ScaleW(49), ScaleH(-3));

  c := TShapeOutline.Create(FScene);
  FCraneHook.AddChild(c, -1);
  c.SetParam(PPIScale(6), BGRA(39,39,39), lpMiddle, False);
  c.SetShapeLine(PointF(ScaleW(45), ScaleH(9)), PointF(ScaleW(45), -FScene.Height*3));

  c := TShapeOutline.Create(FScene);
  FCraneHook.AddChild(c, -1);
  c.SetParam(PPIScale(6), BGRA(39,39,39), lpMiddle, False);
  c.SetShapeLine(PointF(ScaleW(55), ScaleH(9)), PointF(ScaleW(55), -FScene.Height*3));

  PostMessage(0); // swing
end;

procedure TSuspendedContainer.Update(const aElapsedTime: single);
var xx, yy: integer;
  d: single;
begin
  inherited Update(aElapsedTime);

  // follow the path
  if FAutomaticMode then begin
    if  (Length(FAutomaticPath) > 0) then begin
      if (X.State = psNO_CHANGE) and (Y.State = psNO_CHANGE) then begin
        if FPauseBetweenStep > 0 then
          FPauseBetweenStep := FPauseBetweenStep-aElapsedTime;

        if FPauseBetweenStep <= 0 then begin
          if not((FLR.ParentSurface = Self) and FLR.IsJumping) then begin
            // take new coord
            xx := FAutomaticPath[FPathIndex];
            yy := Round(GetYFloor(FAutomaticPath[FPathIndex+1]))-ScaleH(62); //48
            // compute the duration of the move to have same speed for different distance
            d := ComputeMovingTime(PointF(xx, yy));
            MoveTo(FAutomaticPath[FPathIndex], yy, d);
            // are we changing floor ?
            if FAutomaticPath[FPathIndex+1] <> FloorIndex then begin
              FloorIndex := FAutomaticPath[FPathIndex+1];
              FChangingFloor := True;
              PostMessage(100, d);
            end;
          end;

          FPauseBetweenStep := 0.5;

          inc(FPathIndex, 2);
          if FPathIndex = Length(FAutomaticPath) then FPathIndex := 0;
        end;
      end;
    end;
  end else begin
    // keep the container in the right range
    if (Speed.X.Value < 0.0) and (X.Value <= FXMin) then begin
      Speed.X.Value := 0.0;
      X.Value := FXMin;
    end;

    if (Speed.X.Value > 0.0) and (X.Value >= FXMax) then begin
      Speed.X.Value := 0.0;
      X.Value := FXMax;
    end;
  end;
end;

procedure TSuspendedContainer.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // ANIM CONTAINER SWING
    0: begin
      Angle.ChangeTo(-1, 3.0, idcSinusoid);
      //FCraneHook.Angle.ChangeTo(1, 3.0, idcSinusoid);
      PostMessage(2, 3.0);
    end;
    2: begin
      Angle.ChangeTo(1, 3.0, idcSinusoid);
      //FCraneHook.Angle.ChangeTo(-1, 3.0, idcSinusoid);
      PostMessage(0, 3.0);
    end;

    // reset FChangingFloor
    100: FChangingFloor := False;
  end;
end;

class procedure TSuspendedContainer.CheckLRFeetOnContainer;
var p: TPointF;
  x1, x2: single;
  o: TSuspendedContainer;
  i: Integer;
begin
  for i:=0 to FScene.Layer[LAYER_FXANIM].SurfaceCount-1 do
    if FScene.Layer[LAYER_FXANIM].Surface[i] is TSuspendedContainer then begin
      o := TSuspendedContainer(FScene.Layer[LAYER_FXANIM].Surface[i]);
      if FLR.ParentSurface = NIL then begin
        // check if LR becomes a child of the container
        p := o.SurfaceToSceneWithoutLayerTransform(PointF(0, 0));
        x1 := p.x + o.Width*0.05;
        x2 := p.x + o.Width*0.90;
        if (o.FloorIndex = FLR.FloorIndex) and
           not FLR.IsJumping and
           InRange(FLR.X.Value, x1, x2) then begin
          FLR.SetChildOf(o, 2);
          FLR.HaveFeetOnContainer := True;
          if PlayerInfo.MermaidsPort.CraneRemoteControl.Owned then begin
            FLR.ContainerToControl := o;
            o.StopAutomaticSequence;
          end;
          exit;
        end;
      end
      else
      if FLR.ParentSurface = o then begin
        // check if LR is still on the container
        x1 := o.Width*0.05;
        x2 := o.Width*0.90;
        if not FLR.IsJumping and InRange(FLR.X.Value, x1, x2) then begin
          FLR.HaveFeetOnContainer := True;
          FLR.ContainerToControl := o;
          FLR.FloorIndex := o.FloorIndex;
          exit;
        end;
      end;
    end;
end;

class function TSuspendedContainer.LRFallOnContainer: boolean;
var p: TPointF;
  x1, x2, y1, y2: single;
  o: TSuspendedContainer;
  i: Integer;
begin
  Result := False;
  for i:=0 to FScene.Layer[LAYER_FXANIM].SurfaceCount-1 do
    if FScene.Layer[LAYER_FXANIM].Surface[i] is TSuspendedContainer then begin
      o := TSuspendedContainer(FScene.Layer[LAYER_FXANIM].Surface[i]);

      // check if LR becomes a child of the container
      p := o.SurfaceToSceneWithoutLayerTransform(PointF(0, 0));
      x1 := p.x + o.Width*0.05;
      x2 := p.x + o.Width*0.90;
      y1 := p.y;
      y2 := p.y + o.Height*0.7;
      if InRange(FLR.X.Value, x1, x2) and
         InRange(FLR.BodyBottomY, y1, y2) then begin
        FLR.Speed.Value := PointF(0, 0);
        FLR.SetIdlePosition;
        FLR.SetChildOf(o, 2);
        FLR.BodyBottomY := ScaleH(48);
        FLR.HaveFeetOnContainer := True;
        if PlayerInfo.MermaidsPort.CraneRemoteControl.Owned then begin
          FLR.ContainerToControl := o;
          o.StopAutomaticSequence;
        end;
        FLR.FloorIndex := o.FloorIndex;
        Result := True;
        exit;
      end;

    end;
end;

procedure TSuspendedContainer.SetAutomaticPath(A: TArrayOfInteger;
  aAddReverseData: boolean);
var idest, isrc: integer;
begin
  if Length(A) mod 2 <> 0 then raise exception.create('error in array');

  if not aAddReverseData then
    FAutomaticPath := Copy(A, 0, Length(A))
  else begin
    FAutomaticPath := NIL;
    SetLength(FAutomaticPath, Length(A)*2);
    // copy normal data
    for idest:=0 to High(A) do FAutomaticPath[idest] := A[idest];
    // add reverse data
    idest := Length(A);
    isrc := High(A)-1;
    while idest < Length(FAutomaticPath) do begin
      FAutomaticPath[idest] := A[isrc];
      FAutomaticPath[idest+1] := A[isrc+1];
      inc(idest, 2);
      dec(isrc, 2);
    end;
  end;
  // the first step is the start coordinates
  FloorIndex := FAutomaticPath[1];
  SetCoordinate(FAutomaticPath[0], GetYFloor(FloorIndex)-ScaleH(48));
end;

procedure TSuspendedContainer.RunAutomaticSequence;
begin
  FAutomaticMode := True;
end;

procedure TSuspendedContainer.StopAutomaticSequence;
begin
  FAutomaticMode := False;
end;

procedure TSuspendedContainer.SetManualPathConstraints(A: TArrayOfInteger);
var i: integer;
begin
  if Length(A) mod 3 <> 0 then raise exception.create('error in array');
  FManualConstraints := Copy(A, 0, Length(A));
  // retrieve the min and max floor authorized to go on
  FFloorMin := MaxInt;
  FFloorMax := -1;
  i := 0;
  while i < High(A) do begin
    if FFloorMin > A[i] then FFloorMin := A[i];
    if FFloorMax < A[i] then FFloorMax := A[i];
    inc(i, 3);
  end;
end;

procedure TSuspendedContainer.MoveToLeft;
begin
  if FChangingFloor then exit;
  if not CanMoveLeft then begin
    if FsndBuzzer.State = ALS_STOPPED then FsndBuzzer.Play;
    Idle;
  end else begin
    Speed.Value := PointF(-FScene.Width*0.125, 0);
    if FLastMove <> lsmLeft then PlayAudioRelay;
    FLastMove := lsmLeft;
  end;
end;

procedure TSuspendedContainer.MoveToRight;
begin
  if FChangingFloor then exit;
  if not CanMoveRight then begin
    if FsndBuzzer.State = ALS_STOPPED then FsndBuzzer.Play;
    Idle;
  end else begin
    Speed.Value := PointF(FScene.Width*0.125, 0);
    if FLastMove <> lsmRight then PlayAudioRelay;
    FLastMove := lsmRight;
  end;
end;

procedure TSuspendedContainer.MoveToUp;
var newPos: TPointF;
  d: single;
begin
  if FChangingFloor then exit;
  if not CanMoveUp then begin
    if FsndBuzzer.State = ALS_STOPPED then FsndBuzzer.Play;
    Idle;
  end else begin
    Speed.Value := PointF(0, 0);
    inc(FloorIndex);
    newPos := PointF(X.Value, GetYFloor(FloorIndex)-ScaleH(62)); //48
    d := ComputeMovingTime(newPos);
    MoveTo(newPos, d);
    FChangingFloor := True;
    PostMessage(100, d);
    FLR.FloorIndex := FloorIndex;
    if FLastMove <> lsmUp then PlayAudioRelay;
    FLastMove := lsmUp;
  end;
end;

procedure TSuspendedContainer.MoveToDown;
var newPos: TPointF;
  d: single;
begin
  if FChangingFloor then exit;
  if not CanMoveDown then begin
    if FsndBuzzer.State = ALS_STOPPED then FsndBuzzer.Play;
    Idle;
  end else begin
    Speed.Value := PointF(0, 0);
    dec(FloorIndex);
    newPos := PointF(X.Value, GetYFloor(FloorIndex)-ScaleH(62)); //48
    d := ComputeMovingTime(newPos);
    MoveTo(newPos, d);
    FChangingFloor := True;
    PostMessage(100, d);
    FLR.FloorIndex := FloorIndex;
    if FLastMove <> lsmDown then PlayAudioRelay;
    FLastMove := lsmDown;
  end;
end;

procedure TSuspendedContainer.Idle;
begin
  Speed.Value := PointF(0, 0);
end;

procedure TSuspendedContainer.ResetFlagLastMove;
begin
  FLastMove := lsmIdle;
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
  Gradient.CreateVertical([BGRA(27,6,58), BGRA(87,19,194)], [0, 1]);
  SetSize(FScene.Width, ScaleH(472));
end;

procedure TSky.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // storm
    0: begin
      if not FStormIsActive then exit;
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

procedure TSky.StartStorm;
begin
  if FStormIsActive then exit;
  FStormIsActive := True;
  PostMessage(0, 10);
end;

procedure TSky.StopStorm;
begin
  FStormIsActive := False;
end;

{ TTruck }

procedure TTruck.ComputeVolumeAndPan(out vol, pan: single);
var p: TPointF;
  distMax, v: single;
begin
  p := FLR.SurfaceToSceneWithoutLayerTransform(PointF(0, 0));
  v := Distance(p, ParentSurface.Center);
  distMax := FScene.Width*1.5;
  if v > distMax then v := distMax;
  v := distMax - v;
  v := v / distMax;
  vol := v * 0.8;
  v := 1.0 - v;
  if p.x < ParentSurface.Center.x then pan := v
    else pan := -v;
end;

constructor TTruck.Create(aTexture: PTexture; aParentRoad: TRoad; aZOrder: integer);
var sc: TPointF;
  v, p: single;
begin
  inherited Create(aTexture, False);
  aParentRoad.AddChild(Self, aZOrder);
  CenterX := ScaleW(170);
  Scale.Value := ScaleValueToFitWidth(aTexture, ScaleW(9));
  ScaledBottomY := 0;

  sc := ScaleValueToFitWidth(aTexture, ScaleW(300));
  Scale.ChangeTo(sc, 3.0, idcStartSlowEndFast);
  Y.ChangeTo(aParentRoad.Height{+Height*sc.y}, 3.0, idcStartSlowEndFast);

  FSndEngine := Audio.AddSound('engine-47745.ogg', 0.0, True);
  ComputeVolumeAndPan(v, p);
  FSndEngine.FadeIn(v, 3.0);
  FSndEngine.Pan.Value := p;
  FSndEngine.Pitch.Value := 1.0 + Random + 0.25;
  PostMessage(0, 3.0); // kill sprite and sound
end;

destructor TTruck.Destroy;
begin
  if FSndEngine <> NIL then FSndEngine.FadeOutThenKill(1.0);
  FSndEngine := NIL;
  inherited Destroy;
end;

procedure TTruck.Update(const aElapsedTime: single);
var v, p: single;
begin
  inherited Update(aElapsedTime);

  // update the volume of the truck engine according to LR distance
  FFlagUpdate := not FFlagUpdate;
  if FFlagUpdate and (FSndEngine <> NIL) then begin
    ComputeVolumeAndPan(v, p);
    FSndEngine.GlobalVolume := FSaveGame.SoundVolume * v;
    FSndEngine.Pan.Value := p;
  end;
end;

procedure TTruck.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin
      Visible := False;
      FSndEngine.Pitch.ChangeTo(FSndEngine.Pitch.Value-0.5, 2.0, ALS_StartFastEndSlow);
      FSndEngine.FadeOutThenKill(2.0);
      FSndEngine := NIL;
      PostMessage(1, 2.0);
    end;
    2: begin
      Kill;
    end;
  end;
end;

{ TRoad }

constructor TRoad.Create(aX: single);
var quad: TQuadCoor;
begin
  inherited Create(FScene);
  quad := QuadCoor(PointF(ScaleW(165), 0), PointF(ScaleW(176), 0),
              PointF(ScaleW(338), ScaleH(296)), PointF(0, ScaleH(296)));
  SetSize(quad);
  SetAllColorsTo(BGRA(24,31,28));
  SetCoordinate(aX, FWorldArea.Bottom-Height);
  FScene.Add(Self, LAYER_GROUND);

  FTruckZOrder := MaxInt;
  PostMessage(100); // Truck creation
end;

procedure TRoad.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if ScreenMermaidsPort.GameState = gsLRFalling then exit;

  // check if LR collide the road
  if (FLR.FloorIndex = 0) and InRange(FLR.X.Value, X.Value, RightX) then begin
    if FLR.X.Value-FLR.BodyWidth*2 < X.Value then begin
      FLR.X.Value := X.Value-PPIScale(5);
      ScreenMermaidsPort.GameState := gsLRCollideRoad;
    end else
    if FLR.X.Value+FLR.BodyWidth*2 > RightX then
      FLR.X.Value := RightX+PPIScale(5);
  end;
end;

class procedure TRoad.CheckIfLRCollideARoadAfterABigFall;
var i: Integer;
  o: TRoad;
begin
  for i:=0 to FScene.Layer[LAYER_GROUND].SurfaceCount-1 do
    if FScene.Layer[LAYER_GROUND].Surface[i] is TRoad then begin
      o := TRoad(FScene.Layer[LAYER_GROUND].Surface[i]);
      if InRange(FLR.X.Value, o.X.Value, o.RightX) then begin
        // LR becomes child of the road (under the cars)
        FLR.SetChildOf(o, 0);
      end;
    end;
end;

procedure TRoad.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // Truck creation
    100: begin
      case random(3000) of
        0..1000: TTruck.Create(texTruckYellow, Self, FTruckZOrder);
        1001..2000: TTruck.Create(texTruckBlue, Self, FTruckZOrder);
        2001..3000: TTruck.Create(texTruckGreen, Self, FTruckZOrder);
      end;
      dec(FTruckZOrder);
      if FTruckZOrder < 0 then FTruckZOrder := MaxInt;
      PostMessage(100, Random+1);
    end;
  end;
end;

{ TScreenMermaidsPort }

procedure TScreenMermaidsPort.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;
  case AValue of
    gsLRUseControlPanel: PostMessage(50); // show some dialogs then activate container
    gsLRWin: PostMessage(200);
    gsLRCollideRoad: PostMessage(400);
    gsLRFalling: PostMessage(500);
    gsShowMessLRNeedKeyToOpenGate: PostMessage(600);
    gsLROpenGate: PostMessage(700);
  end;
end;

procedure TScreenMermaidsPort.ResetVariables;
begin
  FFenceGateSubSequence := False;
end;

procedure TScreenMermaidsPort.StartRain(aDuration: single);
begin
  FsndRain := Audio.AddSound('rain.ogg', 0.0, True);
  FsndRain.FadeIn(0.4, 4.0);
  FRain.ParticlesToEmit.ChangeTo(1024, aDuration, idcStartSlowEndFast);
  FSky.StartStorm;
end;

procedure TScreenMermaidsPort.StopRain;
begin
  FSky.StopStorm;
  FsndRain.FadeOutThenKill(3.0);
  FRain.ParticlesToEmit.ChangeTo(0, 3.0);
  FsndRain := NIL;
end;

procedure TScreenMermaidsPort.ProcessLAYERGROUNDBeforeUpdate;
begin
  FLR.CanClimbOnLadder := False;
  FLR.IsAboveLadder := False;
  FLR.LadderInUse := NIL;
  FLR.ObjectToHandle := NIL;
  FLR.DistanceToObjectToHandle := MaxSingle;
  FLR.HaveFeetOnPlatform := False;
  FLR.HaveFeetOnContainer := False;
  FLR.ContainerToControl := NIL;
end;

procedure TScreenMermaidsPort.CreateClouds;
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

procedure TScreenMermaidsPort.CreateGround;
var ground: TGradientRectangle;
begin
  ground := TGradientRectangle.Create(FScene);
  FScene.Add(ground, LAYER_BG3);
  ground.Gradient.CreateVertical([BGRA(25,40,31), BGRA(55,48,39)], [0, 1]);
  ground.SetSize(FScene.Width, ScaleH(296));
  ground.Y.Value := FSky.Height;
end;

procedure TScreenMermaidsPort.CreateFactory3;
var xx, w: single;
begin
  xx := 0;
  w := texFactory3^.FrameWidth * FACTORY3_SCALE;
  while xx < FWorldArea.Right do begin
    TFactory3.Create(xx);
    xx := xx + w + Random*w;
  end;
end;

procedure TScreenMermaidsPort.CreateFactory1(var aX: single; aCount: integer);
begin
  while aCount > 0 do begin
    TFactory1.Create(aX);
    aX := aX + texFactory1^.FrameWidth*FACTORY1_SCALE;
    dec(aCount);
  end;
end;

procedure TScreenMermaidsPort.CreateBGFence(aXBegin, aXEnd: single);
var w: single;
begin
  w := texBGFenceVertical^.FrameWidth + texBGFenceHorizontal^.FrameWidth;
  while aXBegin < aXEnd do
    TBGFence.Create(aXBegin, aXBegin+w < aXEnd);
end;

procedure TScreenMermaidsPort.CreateFactory2;
var xx: single;
begin
  xx := -texFactory2^.FrameWidth*0.3;
  while xx < FWorldArea.Right do begin
    TFactory2.Create(xx);
    xx := xx + texFactory2^.FrameWidth * FACTORY2_SCALE;
  end;
end;

procedure TScreenMermaidsPort.CreateLevel(aLevelIndex: integer);
begin
  FWorldArea.Left := 0;
  FWorldArea.Top := 0;

  case aLevelIndex of
    1: CreateLevel1;   //
    2: CreateLevel2;   //
    3: CreateLevel3;   //
  end;//case

  // constrained size for the camera
  FViewArea.Left := FWorldArea.Left + FScene.Width*0.5;
  FViewArea.Top := FWorldArea.Top + FScene.Height*0.5;
  FViewArea.Right := FWorldArea.Right - FScene.Width*0.5;
  FViewArea.Bottom := FWorldArea.Bottom - FScene.Height*0.5;
end;

procedure TScreenMermaidsPort.CreateLevel1;
var xx, xx1: single;
  o: TSuspendedContainer;
begin
  FWorldArea := RectF(0, 0, ScaleW(5120), ScaleH(768*1));

  FSky := TSky.Create;
  CreateClouds;
  CreateGround;
  TGroundStain.Create(ScaleW(143), ScaleH(569));
  TGroundStain.Create(ScaleW(513), ScaleH(627));
  TGroundStain.Create(ScaleW(933), ScaleH(567));
  TGroundStain.Create(ScaleW(1696), ScaleH(573));
  TGroundStain.Create(ScaleW(2152), ScaleH(630));
  TGroundStain.Create(ScaleW(2708), ScaleH(553));
  CreateFactory3;
  CreateFactory2;

  xx := 0;
  CreateFactory1(xx, 5);
  CreateBGFence(0, xx);
  xx := xx - ScaleW(70);
  TRoad.Create(xx);
  xx := xx + ScaleW(339-70);
  xx1 := xx;
  CreateFactory1(xx, 2);
  CreateBGFence(xx1, FWorldArea.Right+ScaleW(50));

  TSewerPlate.Create(ScaleW(279));
  TSewerPlate.Create(ScaleW(1206));
  TSewerPlate.Create(ScaleW(1866));
  TSewerPlate.Create(ScaleW(2762));

  TBarrel.Create(ScaleW(416), ScaleH(622), LAYER_ARROW);
  TBarrel.Create(ScaleW(474), ScaleH(638), LAYER_ARROW);
  TBarrel.Create(ScaleW(1054), ScaleH(638), LAYER_ARROW);
  TBarrel.Create(ScaleW(1504), ScaleH(539), LAYER_GROUND);
  TBarrel.Create(ScaleW(1661), ScaleH(622), LAYER_ARROW);
  TBarrel.Create(ScaleW(1719), ScaleH(638), LAYER_ARROW);

  o := TSuspendedContainer.Create;
  o.SetAutomaticPath([ScaleW(1224), 2, ScaleW(1812), 2, ScaleW(1812), 1, ScaleW(2064), 1], True);

  o.SetManualPathConstraints([1, ScaleW(1812), ScaleW(2064),  // floor1
                              2, ScaleW(1224), ScaleW(3885)]); // floor2

  TPlatform4Legs.Create(ScaleW(813), 0, 1);// left
  TPlatform4Legs.Create(ScaleW(813), 1, 1);
  with TUsableCrateThatContainObject.Create(ScaleW(880), GetYFloor(2)-ScaleH(15), LAYER_GROUND, False, FLR) do begin
    Enabled := not PlayerInfo.MermaidsPort.CraneRemoteControl.Owned;
    if Enabled
      then ContentID := oicIDCraneRemoteControl
      else ContentID := oicIDNone;
  end;

  TPlatformWithLadder.Create(ScaleW(2520), 0, 1);// middle
  TCustomUsableControlPanel.Create(ScaleW(2775), ScaleH(419), LAYER_GROUND, FLR, o);

  TPlatform4Legs.Create(ScaleW(4321), 0, 1);// right
  TPlatform4Legs.Create(ScaleW(4321), 1, 0);

  TPanelExit.Create(ScaleW(4929), 0);
  StartRain(0);

  FLR.X.Value := FLR.BodyWidth*2;
  FLR.BodyBottomY := GetYFloor(0);
  FLR.FloorIndex := 0;
end;

procedure TScreenMermaidsPort.CreateLevel2;
var xx, xx1: single;
  o: TSuspendedContainer;
begin
  FWorldArea := RectF(0, 0, ScaleW(5130), ScaleH(768*2));

  FSky := TSky.Create;
  CreateClouds;
  CreateGround;
  TGroundStain.Create(ScaleW(384), ScaleH(1403));
  TGroundStain.Create(ScaleW(754), ScaleH(1461));
  TGroundStain.Create(ScaleW(1174), ScaleH(1401));
  TGroundStain.Create(ScaleW(1936), ScaleH(1408));
  TGroundStain.Create(ScaleW(2745), ScaleH(1447));
  TGroundStain.Create(ScaleW(3135), ScaleH(1408));
  TGroundStain.Create(ScaleW(3567), ScaleH(1436));
  TGroundStain.Create(ScaleW(3811), ScaleH(1380));
  TGroundStain.Create(ScaleW(4139), ScaleH(1444));
  TGroundStain.Create(ScaleW(4563), ScaleH(1404));
  TGroundStain.Create(ScaleW(4971), ScaleH(1452));
  CreateFactory3;
  CreateFactory2;

  xx := 0;
  CreateFactory1(xx, 3);
  CreateBGFence(0, xx);
  xx := xx - ScaleW(80);
  TRoad.Create(xx);
  xx := xx + ScaleW(339-70);
  xx1 := xx;
  CreateFactory1(xx, 3);

  CreateBGFence(xx1, ScaleW(4772));

  TSewerPlate.Create(ScaleW(345));
  TSewerPlate.Create(ScaleW(1272));
  TSewerPlate.Create(ScaleW(1932));
  TSewerPlate.Create(ScaleW(2571));
  TSewerPlate.Create(ScaleW(3179));
  TSewerPlate.Create(ScaleW(3887));
  TSewerPlate.Create(ScaleW(4551));

  TBarrel.Create(ScaleW(373), ScaleH(1314), LAYER_GROUND);
  TBarrel.Create(ScaleW(529), ScaleH(1416), LAYER_ARROW);
  TBarrel.Create(ScaleW(1410), ScaleH(1314), LAYER_GROUND);
  TBarrel.Create(ScaleW(1496), ScaleH(1316), LAYER_GROUND);
  TBarrel.Create(ScaleW(1527), ScaleH(1405), LAYER_ARROW);
  TBarrel.Create(ScaleW(3099), ScaleH(1433), LAYER_ARROW);
  TBarrel.Create(ScaleW(3263), ScaleH(1423), LAYER_ARROW);
  TBarrel.Create(ScaleW(3543), ScaleH(1413), LAYER_ARROW);
  TBarrel.Create(ScaleW(3503), ScaleH(1427), LAYER_ARROW);
  TBarrel.Create(ScaleW(3781), ScaleH(1437), LAYER_ARROW);
  TBarrel.Create(ScaleW(4423), ScaleH(1413), LAYER_ARROW);
  TBarrel.Create(ScaleW(4383), ScaleH(1427), LAYER_ARROW);

  TPlatformWithLadder.Create(ScaleW(800), 0, 0); // left
  TPlatform4Legs.Create(ScaleW(2626), 0, 1); // middle
  TPlatform4Legs.Create(ScaleW(2626), 1, 1);
  TPlatform4Legs.Create(ScaleW(2626), 2, 1);
  TPlatform4Legs.Create(ScaleW(2626), 3, 1);
  TPlatformWithLadder.Create(ScaleW(4006), 0, 0); // right

  // container 1
  o := TSuspendedContainer.Create;
  o.SetAutomaticPath([ScaleW(1054), 1], False);
  o.SetManualPathConstraints([1, ScaleW(1054), ScaleW(1054),
                              2, ScaleW(1054), ScaleW(1054),
                              3, ScaleW(1054), ScaleW(2191),
                              4, ScaleW(2191), ScaleW(2191)]);

  // container 2
  o := TSuspendedContainer.Create;
  o.SetAutomaticPath([ScaleW(3300), 4, ScaleW(3038), 4], True);
  o.SetManualPathConstraints([1, ScaleW(3035), ScaleW(3590),
                              2, ScaleW(3035), ScaleW(3590),
                              3, ScaleW(3035), ScaleW(3590),
                              4, ScaleW(3035), ScaleW(3590)]);
  TCustomUsableControlPanel.Create(ScaleW(2876), ScaleH(506), LAYER_GROUND, FLR, o);

  // container 3
  o := TSuspendedContainer.Create;
  o.SetAutomaticPath([ScaleW(4004), 4], False);
  o.SetManualPathConstraints([4, ScaleW(4004), ScaleW(4004)]);

  with TUsableCrateThatContainObject.Create(o.Width*0.5, o.Height*0.25, -1, False, FLR) do begin
    SetChildOf(o, 0);
    ContentID := oicIDKey;
  end;

  TFenceGate.Create(ScaleW(4612), ScaleH(1162));
  TPanelExit.Create(ScaleW(4900), 0);

  StartRain(0);

  FLR.X.Value := FLR.BodyWidth*2;
  FLR.BodyBottomY := GetYFloor(0);
  FLR.FloorIndex := 0;
end;

procedure TScreenMermaidsPort.CreateLevel3;
begin

end;

procedure TScreenMermaidsPort.FadeOutAndKillMusicAndSounds;
begin
  if FsndRain <> NIL then FsndRain.FadeOutThenKill(2.0);
  FsndRain := NIL;
  if FsndBuzzer <> NIL then FsndBuzzer.Kill;
  FsndBuzzer := NIL;
end;

procedure TScreenMermaidsPort.CreateObjects;
var path: string;
  ima: TBGRABitmap;
begin

  FGameState := gsUndefined;
  ResetVariables;
  Audio.PauseMusicTitleMap(3.0);
  FsndBuzzer := Audio.AddSound('BuzzerError.ogg', 0.4, False);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  AdditionnalScale := 0.8;
  LoadLR4DirTextures(FAtlas, False);
  LoadWolfTextures(FAtlas);
  AdditionnalScale := 1.0;

  path := FolderSpriteGameMermaidsPort;
  texTruckYellow := FAtlas.AddFromSVG(path+'TruckYellow.svg', ScaleW(140), -1);
  texTruckBlue := FAtlas.AddFromSVG(path+'TruckBlue.svg', ScaleW(140), -1);
  texTruckGreen := FAtlas.AddFromSVG(path+'TruckGreen.svg', ScaleW(140), -1);
  texCraneHook := FAtlas.AddFromSVG(path+'CraneHook.svg', -1, ScaleH(137));
  texCraneHookBG := FAtlas.AddFromSVG(path+'CraneHookBG.svg', ScaleW(55), -1);
  texContainer := FAtlas.AddFromSVG(path+'Container.svg', ScaleW(408), -1);
  TUsableControlPanel.LoadTexture(FAtlas);
  TUsableCrateThatContainObject.LoadTexture(FAtlas, 1);
  TCraneRemote.LoadTexture(FAtlas);
  texPanelExit := FAtlas.AddFromSVG(SpriteGameVolcanoInnerFolder+'PanelExit.svg', ScaleW(52), -1);
  texFence := FAtlas.AddFromSVG(path+'Fence.svg', -1, ScaleH(186));

  texControlPanel := FAtlas.AddFromSVG(path+'ControlPanel.svg', ScaleW(73), -1);
  texPlatformLeg := FAtlas.AddFromSVG(path+'PlatformLeg.svg', -1, ScaleH(229));
  texPlatformGround := FAtlas.AddFromSVG(path+'PlatformGround.svg', ScaleW(205), -1);
  texPlatformGroundForLadder := FAtlas.AddFromSVG(path+'PlatformGroundForLadder.svg', ScaleW(205), -1);
  texPlatformLadder := FAtlas.AddFromSVG(path+'PlatformLadder.svg', -1, ScaleH(230));
  texSewerPlate := FAtlas.AddFromSVG(path+'SewerPlate.svg', ScaleW(66), -1);
  texBarrel := FAtlas.AddFromSVG(path+'Barrel.svg', ScaleW(72), -1);
  texGroundStain := FAtlas.AddFromSVG(path+'GroundStain.svg', ScaleW(120), -1);
  texBGFenceVertical := FAtlas.AddFromSVG(path+'BGFenceVertical.svg', -1, ScaleH(55));
  texBGFenceHorizontal := FAtlas.AddFromSVG(path+'BGFenceHorizontal.svg', ScaleW(25), -1);

  path := GetFolderSpritePlainOfSleepingMoon;
  texFactory1 := FAtlas.AddFromSVG(path+'Factory1.svg', ScaleW(710 div 2), -1);
  texFactory2 := FAtlas.AddFromSVG(path+'Factory2.svg', ScaleW(634 div 2), -1);
  texFactory3 := FAtlas.AddFromSVG(path+'Factory3.svg', ScaleW(354 div 2), -1);

  LoadCloudsTexture(FAtlas);
  AddRainDropParticleToAtlas(FAtlas);
  // ui
  CreateGameFontNumber(FAtlas); // < must be first !
  LoadIconCraneRemoteTexture(FAtlas);
  LoadKeyMetalTexture(FAtlas);
  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);
  LoadGameDialogTextures(FAtlas);
  TCustomPanelUsingControlPanel0.LoadTextures(FAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(FAtlas);
  LoadMousePointerTexture(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;

  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  // LAYER_GROUND callback
  FScene.Layer[LAYER_GROUND].OnBeforeUpdate := @ProcessLAYERGROUNDBeforeUpdate;

  // rain
  FRain := TParticleEmitter.Create(FScene);
  FScene.Add(FRain, LAYER_WEATHER);
  FRain.LoadFromFile(ParticleFolder+'RainMermaidsPort.par', FAtlas);
  FRain.SetEmitterTypeRectangle(FScene.Width, FScene.Height);
  FRain.Opacity.Value := 180;
  FRain.ParticlesToEmit.Value := 0;


  // LR
  FLR := TCustomLR4Direction.Create(LAYER_PLAYER); //LAYER_GROUND);
  FLR.X.Value := ScaleW(220);
  FLR.BodyBottomY := ScaleH(600);
  FLR.TimeMultiplicator := 0.4;
  FLR.JumpDeltaX := FScene.Width*0.115;
  FLR.SetWindSpeed(2.0);
  FLR.IdleRight;
  FLR.ApplyTint(BGRA(29,0,50,80));

  // level
  CreateLevel(PlayerInfo.MermaidsPort.StepPlayed);

//  // install a compare function to sort the sprite in the layer LAYER_GROUND
//  FScene.Layer[LAYER_GROUND].OnSortCompare := @LayerSortCompare;

  // camera
  FCamera := FScene.CreateCamera;
  FCamera.AssignToLayerRange(LAYER_ARROW, LAYER_GROUND);
  FCamera.AutoFollow.Bounds := FViewArea;
  FCamera.AutoFollow.SetTargetSurface(FLR, True);
  FCamera.AutoFollow.Speed := 0.01;
  //FCamera.Scale.Value := PointF(2,2);

  FCameraFactory2 := FScene.CreateCamera;
  FCameraFactory2.AssignToLayer(LAYER_BG1);

  FCameraFactory3 := FScene.CreateCamera;
  FCameraFactory3.AssignToLayer(LAYER_BG2);

  // remote
  FCraneRemote := TCraneRemote.Create;
  FCraneRemote.Visible := PlayerInfo.MermaidsPort.CraneRemoteControl.Owned;

  // panel for control panel
  FPanelUsingControlPanel0 := TCustomPanelUsingControlPanel0.Create;

  // inventory
  FGameinventory := TGameInventory.Create;

  // pause panel
  FInGamePausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  GameState := gsRunning;

  CustomizeMousePointer;

  // show how to play
  PostMessage(30);
  if PlayerInfo.MermaidsPort.CraneRemoteControl.Owned then
    PlayerInfo.MermaidsPort.RemoteExplanationDone := True;
end;

procedure TScreenMermaidsPort.FreeObjects;
begin
  if FsndRain <> NIL then begin
    FsndRain.FadeOutThenKill(3.0);
    FsndRain := NIL;
  end;

  if FScene.RequestedScreen = ScreenMap then begin
    FadeOutAndKillMusicAndSounds;
    Audio.ResumeMusicTitleMap;
  end;

  FScene.KillCamera(FCamera);
  FScene.KillCamera(FCameraFactory2);
  FScene.KillCamera(FCameraFactory3);
  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
end;

procedure TScreenMermaidsPort.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // show instructions
    30: ShowGameInstructions(PlayerInfo.MermaidsPort.HelpText);

    // ANIM USE CONTROL PANEL 0
    50: begin
      FLR.IdleUp;
      FPanelUsingControlPanel0.Show;
      PostMessage(52);
    end;
    52: begin
      if FPanelUsingControlPanel0.IsCancelled then PostMessage(55)
      else if FPanelUsingControlPanel0.SequenceStarted then PostMessage(60)
      else PostMessage(52);
    end;
    55: begin // cancelled
      FPanelUsingControlPanel0.Hide(False);
      FControlPanelInUse.Enabled := True;
      GameState := gsRunning;
    end;
    60: begin // start container sequence
      TSuspendedContainer.PlayAudioRelay;
      FPanelUsingControlPanel0.Hide(False);
      FControlPanelInUse.Enabled := True;
      GameState := gsRunning;
      FControlPanelInUse.TargetContainer.RunAutomaticSequence;
    end;

    // LR WIN THE GAME
    200: begin
      Audio.PlayVoiceWhowhooo;
      FLR.SetFaceType(lrfHappy);
      FLR.WalkHorizontallyTo(FWorldArea.Right+FLR.BodyWidth*2, Self, 202, 1);
    end;
    202: begin
      PlayerInfo.MermaidsPort.IncCurrentStep;
      FSaveGame.Save;
      FScene.RunScreen(ScreenMap);
    end;

    // LR LOOK IN THE CRATE
    300: begin
      FLR.State := lr4sBendDown;
      PostMessage(303, 1.0);
    end;
    303: if FCrateHandledByLR.ContentID = oicIDCraneRemoteControl
           then FLR.ShowDialog(sSoundsLikeARemote, FFontText, Self, 310)
           else PostMessage(310);
    310: begin // add the content of the crate to inventory panel
      FCrateHandledByLR.Enabled := False; // stop react when LR is near
      Audio.PlayMusicSuccessShort1;
      FLR.State := lr4sBendUp;
      case FCrateHandledByLR.ContentID of
        oicIDCraneRemoteControl: PostMessage(315);
        oicIDKey: PostMessage(320);
      end;//case
    end;
    315: begin // CRANE REMOTE
      TRemoteThatGoInInventory.Create;
      PlayerInfo.MermaidsPort.CraneRemoteControl.IncLevel;
      FSaveGame.Save;
      PostMessage(350);
    end;
    316: FCraneRemote.Visible := True;

    320: begin // METAL KEY
      TMetalKeyThatGoInInventory.Create(321);
      PostMessage(350);
    end;
    321: FGameInventory.AddKey;

    350: begin
      FLR.State := lr4sBendUp;
      FGameState := gsRunning;
    end;

    // LR COLLIDE ROAD: show message
    400: begin
      FLR.SetIdlePosition;
      FLR.SetFaceType(lrfWorry);
      FLR.ShowDialog(sItsTooDangerousIHaveToFind, FFontText, Self, 402);
    end;
    402: begin
      FLR.SetFaceType(lrfSmile);
      GameState := gsRunning;
    end;

    // LR FALLING
    500: begin
      FLRYBeforeFalling := FLR.Y.Value;
      FLR.Speed.y.ChangeTo(FScene.Height*2, 0.3);
      PostMessage(502);
    end;
    502: begin
      // check if LR feet touch a platform
      if TPlatform4Legs.LRFallOnPlatform then GameState := gsRunning
      else
      if TSuspendedContainer.LRFallOnContainer then begin
        // show remote explanation
        if not PlayerInfo.MermaidsPort.RemoteExplanationDone and
           PlayerInfo.MermaidsPort.CraneRemoteControl.Owned then begin
          ShowGameInstructions(sMermaidsPortHelpText2);
          PlayerInfo.MermaidsPort.RemoteExplanationDone := True;
          SetGameInstructions(sMermaidsPortHelpText+LineEnding+sMermaidsPortHelpText2);
        end;
        GameState := gsRunning;
      end else if FLR.BodyBottomY >= GetYFloor(0) then begin
        FLR.Speed.y.Value := 0;
        FLR.BodyBottomY := GetYFloor(0);
        FLR.FloorIndex := 0;
        if FLR.Y.Value-FLRYBeforeFalling > FloorHeight*1.5 then PostMessage(510)
          else PostMessage(505);
      end
      else PostMessage(502);
    end;
    505: begin  // the fall was only 1 floor
      GameState := gsRunning;
    end;
    510: begin // the fall was > 1 floor
      FLR.Speed.Value := PointF(0, 0);
      FLR.Scale.Value := PointF(0.5,1.0);
      if FLR.IsOrientedLeft then FLR.Angle.Value := -90
        else FLR.Angle.Value := 90;
      FLR.IdleUp;
      FLR.SetWindSpeed(0);
      FLR.ShowDialog('OUTCH!!', FFontText, Self, 512);
      // if LR is on the road, she becomes child of this road (the car overlappes her)
      TRoad.CheckIfLRCollideARoadAfterABigFall;
    end;
    512: DialogQuestion(sWouldYouLikeToTryAgain, sYes, sNo, FFontText, Self, 514, 520, FAtlas);
    514: FScene.RunScreen(Self);
    520: FScene.RunScreen(ScreenMap);

    // Show message LR need a key to open this gate
    600: begin
      if FFenceGateSubSequence then exit;  // to avoid double call
      FFenceGateSubSequence := True;
      FLR.IdleRight;
      FLR.ShowDialog(sINeedAKeyToOpenThisGate, FFontText, Self, 601);
    end;
    601: begin
      GameState := gsRunning;
      FFenceGateSubSequence := False;
    end;

    // LR open the gate
    700: begin
      if FFenceGateSubSequence then exit; // to avoid double call
      FFenceGateSubSequence := True;
      FLR.IdleRight;
      Audio.PlayThenKillSound('unlock-lock-unlock-door-inside.ogg', 0.8);
      FGameInventory.FKey.Count := FGameInventory.FKey.Count-1;
      PostMessage(702, 0.3);
    end;
    702: begin
      FWorkingGate.Open;
      Audio.PlayThenKillSound('metal-chain.ogg', 1.0);
      PostMessage(704, 1.0);
    end;
    704: begin
      FFenceGateSubSequence := False;
      GameState := gsRunning;
    end;
  end;
end;

procedure TScreenMermaidsPort.Update(const aElapsedTime: single);
var flagPlayerIdle: Boolean;
  p: TPointF;
  ladder: TPlatformWithLadder;
  deltaY: single;
begin
  inherited Update(aElapsedTime);

  case FGameState of
    gsRunning: begin
      flagPlayerIdle := True;

      TSuspendedContainer.CheckLRFeetOnContainer;
      TPlatform4Legs.CheckLRFeetOnPlatform;

      FCraneRemote.Connected := FCraneRemote.Visible and FLR.HaveFeetOnContainer;

      // check if LR fall from platform or container
      if (FLR.FloorIndex > 0) and
         not FLR.IsJumping and
         not (FLR.HaveFeetOnPlatform or FLR.HaveFeetOnContainer) then begin
        // remove the child dependency of a container
        if FLR.ParentSurface <> NIL then FLR.MoveToLayer(LAYER_PLAYER);
        GameState := gsLRFalling;
        flagPlayerIdle := False;
      end;

      if not FLR.IsOnLadder then begin

        if Input.Action1Pressed and flagPlayerIdle then begin
          // remove the child dependency of a container
          if FLR.ParentSurface <> NIL then FLR.MoveToLayer(LAYER_PLAYER);
          FLR.State := lr4sJumping;
          flagPlayerIdle := False;
        end;

        if Input.Action2Pressed and flagPlayerIdle and not FLR.IsJumping then begin
          if FLR.ObjectToHandle <> NIL then begin
            if FLR.ObjectToHandle is TCustomUsableControlPanel then begin
              FControlPanelInUse := TCustomUsableControlPanel(FLR.ObjectToHandle);
              FControlPanelInUse.Enabled := False;
              GameState := gsLRUseControlPanel; // show some dialogs then activate container
              flagPlayerIdle := False;
            end else
            if FLR.ObjectToHandle is TUsableCrateThatContainObject then begin
              // crate
              FCrateHandledByLR := TUsableCrateThatContainObject(FLR.ObjectToHandle); // save crate instance coz it'll be niled on next frame
              FGameState := gsLookInTheCrate;
              PostMessage(300); // anim LR looks in a crate
              flagPlayerIdle := False;
            end;
          end else
          if FCraneRemote.Connected then
            FCraneRemote.Activated := True;
        end;
        if not Input.Action2Pressed then begin
          if FCraneRemote.Activated and (FLR.ContainerToControl <> NIL)
            then FLR.ContainerToControl.Idle;
          FCraneRemote.Activated := False;
        end;

        if Input.LeftPressed and flagPlayerIdle then begin
          if FCraneRemote.Activated then begin
            if FLR.ContainerToControl <> NIL then FLR.ContainerToControl.MoveToLeft;
            FCraneRemote.ActivateLeftDirection;
          end else FLR.State := lr4sLeftWalking;
          flagPlayerIdle := False;
        end;

        if Input.RightPressed and flagPlayerIdle then begin
          if FCraneRemote.Activated then begin
            if FLR.ContainerToControl <> NIL then FLR.ContainerToControl.MoveToRight;
            FCraneRemote.ActivateRightDirection;
          end else FLR.State := lr4sRightWalking;
          flagPlayerIdle := False;
        end;

        if Input.UpPressed and flagPlayerIdle then begin
          if FCraneRemote.Activated then begin
            FLR.ContainerToControl.MoveToUp;
            FCraneRemote.ActivateUpDirection;
          end else begin
              if FLR.CanClimbOnLadder then
                FLR.State := lr4sOnLadderUp;
            end;
          flagPlayerIdle := False;
        end;

        if Input.DownPressed and flagPlayerIdle then begin
          if FCraneRemote.Activated then begin
            FLR.ContainerToControl.MoveToDown;
            FCraneRemote.ActivateDownDirection;
           end else begin
              if FLR.IsAboveLadder then begin
                FLR.Y.Value := FLR.Y.Value + ScaleH(60); // 40 LR 'jump' on the ladder
                FLR.State := lr4sOnLadderDown;
              end;
            end;
          flagPlayerIdle := False;
        end;

      end else begin//if not FLR.IsOnLadder
        // here LR is on ladder
        ladder := TPlatformWithLadder(FLR.LadderInUse);

        if Input.DownPressed and flagPlayerIdle and FLR.LRBack.CanMoveOnLadder then begin
          if (ladder <> NIL) and ladder.LRCanGoDown then begin
            FLR.State := lr4sOnLadderDown;
            flagPlayerIdle := False;
          end;
        end;

        if Input.UpPressed and flagPlayerIdle and FLR.LRBack.CanMoveOnLadder then begin
          if ladder <> NIL then begin
            if ladder.LRCanGoUp then begin
              FLR.State := lr4sOnLadderUp;
              flagPlayerIdle := False;
            end else begin
                FLR.FloorIndex := ladder.FloorIndex+1;
                FLR.BodyBottomY := GetYFloor(FLR.FloorIndex) - ScaleH(10); //10
                FLR.IdleRight;
                flagPlayerIdle := False;
            end;
          end;
        end;

        if Input.RightPressed and flagPlayerIdle and
           (ladder <> NIL) and not ladder.LRCanGoDown then begin
          FLR.FloorIndex := ladder.FloorIndex;
          FLR.Y.Value := GetYFloor(FLR.FloorIndex) - FLR.DeltaYToBottom;
          FLR.State := lr4sRightWalking;
          flagPlayerIdle := False;
        end;

        if Input.LeftPressed and flagPlayerIdle and
           (ladder <> NIL) and not ladder.LRCanGoDown then begin
          FLR.FloorIndex := ladder.FloorIndex;
          FLR.Y.Value := GetYFloor(FLR.FloorIndex) - FLR.DeltaYToBottom;
          FLR.State := lr4sLeftWalking;
          flagPlayerIdle := False;
        end;
      end;

      if flagPlayerIdle then begin
        FLR.SetIdlePosition;
        if FLR.ContainerToControl <> NIL then FLR.ContainerToControl.ResetFlagLastMove;
        if FCraneRemote.Activated then begin
          FLR.ContainerToControl.Idle;
          FCraneRemote.DeactivateAllDirection;
        end;
      end;

      // update crane remote direction color
      if FCraneRemote.Connected and (FLR.ContainerToControl <> NIL) then begin
        FCraneRemote.EnableLeftDirection(FLR.ContainerToControl.CanMoveLeft);
        FCraneRemote.EnableRightDirection(FLR.ContainerToControl.CanMoveRight);
        FCraneRemote.EnableUpDirection(FLR.ContainerToControl.CanMoveUp);
        FCraneRemote.EnableDownDirection(FLR.ContainerToControl.CanMoveDown);
      end else begin
        FCraneRemote.EnableLeftDirection(True);
        FCraneRemote.EnableRightDirection(True);
        FCraneRemote.EnableUpDirection(True);
        FCraneRemote.EnableDownDirection(True);
      end;

    end;// gsRunning
  end;//case

  // force LR in the wolrd area
  if (ScreenMermaidsPort.GameState <> gsLRWin) and (FLR.ParentSurface = NIL) then begin
    if FLR.X.Value < FWorldArea.Left+FLR.BodyWidth then
      FLR.X.Value := FWorldArea.Left+FLR.BodyWidth;
    if FLR.X.Value > FWorldArea.Right-FLR.BodyWidth then
      FLR.X.Value := FWorldArea.Right-FLR.BodyWidth;
  end;

  // update LR camera
  p := FLR.SurfaceToSceneWithoutLayerTransform(PointF(0, 0));
  if FLR.IsJumping then p.y := FLR.YBeforeJump;
  FCamera.AutoFollow.SetTargetPoint(p);

  // update FCameraFactory3
 { p := FCamera.LookAt.Value ;//+ FScene.Center;
  FCameraFactory3.LookAt.x.Value := p.x * 0.25;
  p := (FScene.Center - FCamera.LookAt.Value) * 0.25;
  FCameraFactory3.LookAt.y.Value := FScene.Center.y-(p.y);   }

  //LookAt.Value := FParentScene.Center-aPt; => aPt = FParentScene.Center-LookAt.Value
  p := FCamera.LookAt.Value;
  FCameraFactory3.LookAt.x.Value := p.x * 0.25;
  FCameraFactory2.LookAt.x.Value := p.x * 0.5;



  deltaY := FScene.Height*0.5 - p.y;
  deltaY := FScene.Height - FWorldArea.Bottom - deltaY;
  deltaY := FScene.Height*0.5 + deltaY;
  FCameraFactory3.LookAt.y.Value := deltaY;


 { p := FScene.Center - p;
  deltaY := p.y - FWorldArea.Bottom;
  deltaY := FScene.Height*0.5 - deltaY;
  FCameraFactory3.LookAt.y.Value := -deltaY;  }

  //FCameraFactory3.LookAt.y.Value := FScene.Height*0.5 - (FWorldArea.Bottom - deltaY);



  //update FCameraFactory2
 { p := FCamera.LookAt.Value; // + FScene.Center;
  FCameraFactory2.LookAt.x.Value := p.x * 0.5;
  p := (FScene.Center - FCamera.LookAt.Value) * 0.5;
  FCameraFactory2.LookAt.y.Value := FScene.Center.y-(p.y);  }
//  FCameraFactory2.LookAt.Value := FCamera.LookAt.Value * 0.5;

  // check if player pause the game
  if Input.PausePressed then
    FInGamePausePanel.ShowModal;
end;

end.

