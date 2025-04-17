unit screen_gameplainmoon;

{$mode ObjFPC}{$H+}
{$modeswitch AdvancedRecords}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lr4dir, u_sprite_lrcommon, u_sprite_def,
  u_procedural_starnest, u_ProceduralPlanet, u_proceduralcloud;

{
 Here, the world size is 4x Scene size

    ----- ----- ----- -----
    |   | |   | |   | |   |
    ----- ----- ----- -----      full view is achieved with camera scale of (0.25, 0.25)
    |   | |   | |   | |   |
    ----- ----- ----- -----
    |   | |   | |   | |   |
    ----- --*******-- -----      * is the view with camera scale of (1, 1)
    |   | | * | | * | |   |
    ----- --*******-- -----
 A camera locked to the bottom of the world, show a partial or full view.
 To lock the camera to the bottom of the word: FCamera.Pivot := PointF(0.5, 1.0);
 To center the camera on the world: FCamera.MoveTo(PointF(FScene.Width*2.5, FScene.Height*0.5));

 }

const  PLAIN_MOON_GAME_TIME = 300;   // medium 280   hard 260
       PLAIN_MOON_WAGON_COUNT = 4;
type

{ TScreenPlainOfSleepingMoon }

TScreenPlainOfSleepingMoon = class(TGameScreenTemplate)
public type TGameState=(gsUndefined=0,
                         gsLRPlayOutside,
                         gsLREnterWagon,
                         gsLRLeaveWagon,
                         gsAllWagonAreDone,
                         gsLRFallBetweenWagon, gsLRIsEjectedByRobot, gsTimeElapsed);
private
  FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private type TGameSequence = (gsNone, gsWaitPlayerIsOnWagonCenter, gsDestroyRobotOnTheRoof,
                              gsWaitPlayerEnterWagon, gsWaitPlayerJumpOnPreviousWagon);
var FGameSequence: TGameSequence;
  FPreviousWagonIndex: integer;
  procedure SetGameSequence(AValue: TGameSequence);
private
  FInGamePausePanel: TInGamePausePanel;
  FWagonsIndex: integer;
  FAction2Released,
  FEndOfShootingStars: boolean;
  procedure ResetVariables;
  procedure UpdateParallaxScrollingSpeed;
private
  FRobotCount, FRobotCreated, FRobotDestroyed: integer;
  FDelayBeforeNextRobotAppears: single;
  procedure PlayLaserShootSound;
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  procedure FadeOutAndKillMusicAndSounds;

  property GameState: TGameState read FGameState write SetGameState;
  property GameSequence: TGameSequence read FGameSequence write SetGameSequence;
  property RobotDestroyed: integer read FRobotDestroyed write FRobotDestroyed;
end;

var ScreenPlainOfSleepingMoon: TScreenPlainOfSleepingMoon;
    sndMusic, sndTrainWheel: TALSSound;

implementation
uses Forms, u_app, u_sprite_wolf, u_utils, u_resourcestring, u_screen_map,
  screen_gameplainmooninside, u_mousepointer, Math;


function YFeetOnTrain: single; inline;
begin
  Result := ScaleH(10);
end;
function YFeetOnPlatform: single; inline;
begin
  Result := ScaleH(224);
end;

procedure ApplyNightEffectOn(aSurface: TSimpleSurfaceWithEffect);
begin
  aSurface.Tint.Value := BGRA(29,0,50,80);
end;

type

//////////////
// GAME
//////////////

{ TShootingStar }

TShootingStar = class(TSprite)
  constructor Create;
  procedure Update(const aElapsedTime: single); override;
end;

TLaserGunThatGoInInventory = class(TSpriteThatGoInInventory)
  constructor Create(aUserValue: TUserMessageValue);
end;

TLaserShoot = class(TSprite)  // is child of current wagon
  constructor Create;
  procedure Update(const aElapsedTime: single); override;
end;

{ TGameInventory }

TGameInventory = class(TInGameInventoryPanel)
private
  FClock: TUIClock;
  FLaserGun: TUILaserGun;
public
  procedure AddClock;
  procedure AddLaserGun;
  property Clock: TUIClock read FClock;
end;

const TRAIN_WHEEL_MAX_SPEED_ROTATION = 360*4;
      TRAIN_PART_OVERLAPPING = 2;  // in pixel. To avoid artifact when zoom out
type
TTrainPart = class(TSpriteContainer)
  FullWidth: integer;
end;

{ TWagonHead }

TWagonHead = class(TTiledSprite)   // construct wagon head with ladder+door+railing
  Ladder, Railing, Axle, Wheel1, Wheel2, DoorBG, Number: TSprite;
  RoofAddon: TTiledSprite;
  Door: TAutomaticDoor;
  DoorLight: TOGLCGlow;
  constructor Create(aNumber: integer); // the number added to the wagon, near the door
  procedure SetWheelAngle(a: single);
  procedure SetDoorLightRed;
  procedure SetDoorLightGreen;
end;

TWagonTail = class(TWagonHead)    // construct wagon tail with ladder+door+railing
  constructor Create(aNumber: integer); reintroduce;
end;

{ TLocomotive }

TLocomotive = class(TTrainPart)
  Axle, Wheel1, Wheel2: TSprite;
  FTail: TWagonTail;
  Light1, Light2: TOGLCSpotLight;
  constructor Create(aXLeft, aYTop: single; aLayerIndex: integer=-1);
  procedure SetWheelAngle(a: single);
end;

TWagon = class(TTrainPart)
  FHead: TWagonHead;
  FTail: TWagonTail;
  Glows: array[0..2] of TOGLCGlow;
  constructor Create(aYTop: single; aNumberLabel: integer; aLayerIndex: integer=-1);
  procedure SetWheelAngle(a: single);
end;
TArrayOfWagon = array of TWagon;

{ TRobotOnWagon }

TRobotOnWagon = class(TLittleRobot)
  FParentWagon: TWagon;
  constructor Create(aWagonIndex: integer);
  procedure Update(const aElapsedTime: single); override;
  procedure Explode;
end;

{ TBigRobot }

TBigRobot = class(TLittleRobot)
  constructor Create(aWagonIndex: integer);
end;

{ TTrain }

TTrain = record        // layer: LAYER_FXANIM
private
  FCharacterToFollow: TWalkingCharacter;
  MovingTime: single;
  function CheckIfCharacterToFollowCanOpenTheDoor(out aWagonPart: TWagonHead): boolean;
public
  var Loco: TLocomotive;
  Wagons: TArrayOfWagon;
  FDirectionnalArrow: TDirectionnalArrow;
  sndEngine: TALSSound;
  procedure InitDefault;
  procedure Create(aY: single; aLayerIndex: integer);
  procedure DeleteSound;
  procedure SetWheelSpeed(aLinearSpeed: single);
  function LastWagon: TWagon;
  procedure SetSmoothMoves;
  procedure SetQuickMoves;
  procedure UpdatePosition;
  procedure UpdateDoorLight;
  // Center the train on the character.
  procedure CenterOnCharacter(aCharacter: TWalkingCharacter; aTime: single=3.0);
  // Uses to allow the train to follow FLR or Penelope when their moves.
  // NIL to cancel the following.
  procedure SetCharacterToFollow(aCharacter: TWalkingCharacter);
  // return True if the character to follow is no more on the carriages and fall on the rails.
  function CheckIfCharacterToFollowCanFall: boolean;
  function CharacterToFollowIsAboveLadder: boolean;
  // Return True if the character is on the down platform and at middle of the ladder
  function CharacterToFollowCanClimbUpLadder: boolean;
  function CharacterToFollowIsOnRoof: boolean;
  // True if the character is on the down platform
  function CharacterToFollowIsOnPlatform: boolean;
  function CharacterToFollowIsOnHeadPlatform: boolean;
  function CharacterToFollowIsOnTailPlatform: boolean;
  function CharacterToFollowCanOpenTheDoor: boolean;
  procedure PlaceLRToGetsOutOfTheWagon(aWagonIndex: integer; out aWagonPart: TWagonHead);
  procedure CharacterToFollowUpdateCarriageParent;
  function CharacterToFollowIsOnWagonCenter: boolean;
  procedure AvoidCharacterToFollowToJumpOnAnotherWagon;
  procedure AvoidCharacterToFollowToJumpOnNextWagon;
  procedure KillRobots; // kill all robots on all wagons
public
  procedure ShowDirectionnalArrowOnWagonCenter(aWagonIndex: integer);
  procedure ShowDirectionnalArrowOnLeftLadder(aWagonIndex: integer);
  procedure ShowDirectionnalArrowOnWagonRight(aWagonIndex: integer);
  procedure HideDirectionnalArrow;
end;

TSky = record         // layer: LAYER_BG3
  FStarNestRenderer: TStarNestRenderer;
  FStarNest: TStarNest;
  FPlanetRenderer: TOGLCPlanetRenderer;
  FMoon: TOGLCSpritePlanet;
  procedure Create;
  procedure FreeRenderer;
end;

TMountainParallax = record  // layer: LAYER_BG2
  private const useLayer = LAYER_BG2;
  var FMountain2Speed, FMountain1Speed, FCloudSpeed: single;
  FCloudsRenderer: TOGLCCloudsRenderer;
  FClouds, FClouds2: TOGLCSpriteClouds;
  type
    TMountain2 = class(TTiledSprite)
      FYMountain2Base: single;
      procedure SetYCoordinate;
      procedure Update(const aElapsedTime: single); override;
    end;
    TMountain1 = class(TTiledSprite)
      Count: integer;
      procedure Update(const aElapsedTime: single); override;
    end;
  procedure SetCloudSpeed(AValue: single);
  procedure SetMountain2Speed(AValue: single);
  procedure SetMountain1Speed(AValue: single);
public
  procedure Create(aYMountain1, aYMountain2: single);
  procedure FreeRenderer;
  property Mountain1Speed: single read FMountain1Speed write SetMountain1Speed;
  property Mountain2Speed: single read FMountain2Speed write SetMountain2Speed;
  property CloudSpeed: single read FCloudSpeed write SetCloudSpeed;
end;

TGround = record      // layer: LAYER_BG1
private const useLayer = LAYER_BG1;
  var FSpeed: single;
  type
    TRail = class(TTiledSprite)
      RailCount: integer;
      procedure Update(const aElapsedTime: single); override;
    end;
  procedure SetSpeed(AValue: single);
public
  procedure Create(aTopY: single);
  property Speed: single read FSpeed write SetSpeed;
end;

TOakForest = record     // layer: LAYER_FXANIM
  private const useLayer = LAYER_FXANIM;
    var FSpeed: single;
    type
      TRock1 = class(TSprite)
        procedure Update(const aElapsedTime: single); override;
      end;
      TOakTrees = Class(TTiledSprite)
        FBottomY: single;
        procedure SetScale;
        procedure Update(const aElapsedTime: single); override;
      end;
    procedure SetSpeed(AValue: single);
  public
    procedure Create(aBottomY: single);
    property Speed: single read FSpeed write SetSpeed;
end;

TFactoryParallax = record
private const useLayer = LAYER_BG2;
              scalecoeff = 3.5;
var FFactory1Speed, FFactory2Speed, FFactory3Speed, FYBottom: single;
type
  TCustomFactory = class(TTiledSprite)
    MakeFactoryAppears: boolean
  end;
  TFactory3 = class(TCustomFactory)
    procedure Update(const aElapsedTime: single); override;
  end;
  TFactory2 = class(TCustomFactory)
    procedure Update(const aElapsedTime: single); override;
  end;
  TFactory1 = class(TCustomFactory)
    FCanCreateAnother: boolean;
    constructor Create(aX, aYBottom, aSpeed: single);
    procedure Update(const aElapsedTime: single); override;
  end;
  procedure SetFactory3Speed(AValue: single);
  procedure SetFactory2Speed(AValue: single);
  procedure SetFactory1Speed(AValue: single);
public
  procedure Create(aYBottom: single);
  procedure MakeFactoryAppears;
  property Factory1Speed: single read FFactory1Speed write SetFactory1Speed;
  property Factory2Speed: single read FFactory2Speed write SetFactory2Speed;
  property Factory3Speed: single read FFactory3Speed write SetFactory3Speed;
end;

{ TPlainGame }

TPlainGame = record
  Activated: boolean;
  procedure Create;
  procedure FreeRenderer;
end;

///////////////
// INTRO
///////////////

{ TPlainIntroductionCinematic }

TPlainIntroductionCinematic = record    // layer: LAYER_GROUND LAYER_FXANIM LAYER_WOLF
private type
  TCustomWagon = class(TWagon)
    FNextWagon: TCustomWagon;
    Loop: boolean;
    procedure Update(const aElapsedTime: single); override;
  end;
  var FWagon1, FWagon2: TCustomWagon;
  FCloudsRenderer: TOGLCCloudsRenderer;
  Loop: boolean;
  procedure CreateVerticalRock(ax, aY: single; aLayerIndex: integer);
  procedure CreateGroundDeep(aX, aY: single; aLayerIndex: integer);
  procedure CallbackLRDoOnJumpMove(aDuration: single; aJumpStep: integer);
public
  Activated: boolean;
  procedure Create;
  procedure FreeRenderer;
  procedure ProcessMessage(UserValue: TUserMessageValue);
  procedure UpdateWagonsPosition;
end;

var
  FAtlas: TOGLCTextureAtlas;
  // texture for intro
  texGroundSlope, texGroundFlat, texGroundDeep, texGround1, texGround1Right, texGroundCorner,
  // texture for game
  texMountain1, texMountain2, texOakForest, texRail, texDoorBG, texRock1,
  texWagonRailing, texWagonLadder, texWagonHead, texWagonRoofAddon, texWagonMiddle, texWagonHook,
  texLocoHead, texLocoMiddle, texWheel, texAxle,
  texFactory1, texFactory2, texFactory3,
  texLaserGun, texLaserShoot, texArrowYellow,
  texOne, texTwo, texThree, texFour, texShootingStar,
  texRobotMace: PTexture;
  FFontText: TTexturedFont;
  FGameinventory: TGameInventory;
  FYRail: single;   // the y coordinate for the rails
  FTrain: TTrain;
  FCamera: TOGLCCamera;
  FSky: TSky;
  FGround: TGround;
  FMountainParallax: TMountainParallax;
  FOakForest: TOakForest;
  FFactoryParallax: TFactoryParallax;
  FScrollingSpeed: TFParam;
  FForceSpeedUpdate: boolean;
  FLR: TLR4Direction;
  FLaserGun: TSprite;
  FPenelope: TWolfPenelope;
  FPlainGame: TPlainGame;
  FPlainIntroductionCinematic: TPlainIntroductionCinematic;
  FWagonPartEntered, FWagonPartLeft: TWagonHead;
  FUpdateTrainEngineVolume: boolean;
  sndTrainIdle: TALSSound;
  FSpriteMessageTimeOver: TSprite;

{ TBigRobot }

constructor TBigRobot.Create(aWagonIndex: integer);
var wag: TWagon;
  o: TSprite;
begin
  wag := FTrain.Wagons[aWagonIndex];
  inherited Create(wag.FullWidth*0.15, YFeetOnTrain, -1);
  Scale.Value := PointF(1.5,1.5);
  ScaledBottomY := YFeetOnTrain;
  FlipH := True;
  FArm.Angle.AddConstant(360*2);
  wag.AddChild(Self, 1);

  o := FArm.CreateSpriteChild(texRobotMace, False, 1);
  o.CenterX := FArm.Width*0.5;
  o.CenterY := FArm.Height*1.1;
end;

{ TShootingStar }

constructor TShootingStar.Create;
var a: single;
begin
  inherited Create(texShootingStar, False);
  FScene.Add(Self, LAYER_FXANIM);
  SetCoordinate(Random*FScene.Width*2+FScene.Width*1.5, -FScene.Height*1.5+Random*FScene.Height*0.6);
  a := -Random*15-20;
  Angle.Value := a;
  Speed.Value := PointF(-Random*FScene.Width*0.5-FScene.Width*1.0,
                        -sin(a*Deg2Rad)*FScene.Height*1.2);
   Opacity.Value := 200;
end;

procedure TShootingStar.Update(const aElapsedTime: single);
var v: single;
begin
  inherited Update(aElapsedTime);

  v := (Abs(Y.Value) - FScene.Height*0.5) / (FScene.Height*0.5) * 200;
  Opacity.Value := EnsureRange(v, 0, 200);
  if Y.Value > 0 then Kill;
end;

{ TRobotOnWagon }

constructor TRobotOnWagon.Create(aWagonIndex: integer);
var xx, yy, sp: single;
  wag: TWagon;
begin
  wag := FTrain.Wagons[aWagonIndex];
  sp := FScene.Width*0.3+FScene.Width*Random*0.3;
  if Random*1000 > 500 then begin
    xx := wag.FullWidth*0.15;
  end else begin
    xx := wag.FullWidth*0.85;
    sp := -sp;
  end;
  yy := YFeetOnTrain;
  inherited Create(xx, yy, -1);
  Speed.x.Value := sp;
  if sp > 0 then FlipH := True;
  wag.AddChild(Self, 1);
  FParentWagon := wag;
end;

procedure TRobotOnWagon.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  // bounds
  if (X.Value < FParentWagon.FullWidth*0.05) or
     (X.Value > FParentWagon.FullWidth*0.95) then begin
    Speed.x.Value := -Speed.x.Value;
    FlipH := not FlipH;
  end;

  // check LR collision
  if (ScreenPlainOfSleepingMoon.GameState = gsLRPlayOutside) and
     (FLR.BodyBottomY = YFeetOnTrain) then
    if FScene.Collision.RectFRectF(FLR.GetBodyRect, GetBodyRect) then begin
      ScreenPlainOfSleepingMoon.GameState := gsLRIsEjectedByRobot;
    end;
end;

procedure TRobotOnWagon.Explode;
var pc: TPointF;
  v: single;
begin
  Kill;
  pc := SurfaceToScene(PointF(TLittleRobot.texBody^.FrameWidth*0.0, TLittleRobot.texBody^.FrameHeight*0.0));
  ExplodeTexture(FScene, LAYER_WOLF, TLittleRobot.texBody, 3, 3, pc,
                 TLittleRobot.texBody^.FrameWidth*0.25, // center variation
                 PointF(1.0,1.0), // scale value
                 -360*2,360*2, // angle min max
                 FScene.Width*0.4, // distance
                 FScene.Width* 0.4,// distance variation
                 1.5,// duration
                 idcStartFastEndSlow);

  v := Distance(FScene.Center, pc);
  v := EnsureRange(v/FScene.Width*0.4, 0.0, 1.0);
  v := v*(ALS_PAN_RIGHT - ALS_PAN_LEFT) + ALS_PAN_LEFT;
  Audio.PlayThenKillSound('big-boom.ogg', 0.7, v, 1.0+Random*0.25-0.125);
end;

{ TLaserShoot }

constructor TLaserShoot.Create;
var xx, sp: single;
  indexWagon: integer;
begin
  inherited Create(texLaserShoot, False);
  indexWagon := FLR.ParentSurface.Tag1;
  if indexWagon = 0 then FTrain.Loco.AddChild(Self, 10)
    else FTrain.Wagons[indexWagon-1].AddChild(Self, 10);
  sp := FScene.Width*1.5;
  if FLR.IsOrientedLeft then begin
    xx := -FLR.BodyWidth*1.5;
    Speed.x.Value := -sp;
  end else begin
    xx := FLR.BodyWidth*1.0;
    Speed.x.Value := sp;
  end;
  SetCoordinate(FLR.X.Value+xx, FLR.Y.Value-FLR.BodyHeight*0.4);
  KillDefered(1.5);
end;

procedure TLaserShoot.Update(const aElapsedTime: single);
var wag: TWagon;
  r: TRectF;
  i: integer;
begin
  inherited Update(aElapsedTime);

  // check collision with robot
  if not (FLR.ParentSurface is TWagon) then exit;
  wag := TWagon(FLR.ParentSurface);

  r.Left := X.Value;
  r.Top := Y.Value;
  r.Width := Width;
  r.Height := Height;

  for i:=0 to wag.ChildCount-1 do
    if wag.Childs[i] is TRobotOnWagon then
      if Collision.RectFRectF(r, TRobotOnWagon(wag.Childs[i]).GetBodyRect) then begin
        Kill;
        TRobotOnWagon(wag.Childs[i]).Explode;
        ScreenPlainOfSleepingMoon.RobotDestroyed := ScreenPlainOfSleepingMoon.RobotDestroyed+1;
      end;
end;

{ TLaserGunThatGoInInventory }

constructor TLaserGunThatGoInInventory.Create(aUserValue: TUserMessageValue);
var p1, p2: TPointF;
begin
  p1 := FLR.SurfaceToScene(PointF(0, FLR.BodyTopY));
  p1 := FCamera.WorldToControlF(p1);
  p2 := FGameinventory.Center; //GetXY+PointF(FGameinventory.Width*0.5, FGameinventory.Height*0.5);
  p2.x := p2.x + FScene.Width;
  inherited Create(texIconLaserGun, LAYER_GAMEUI, p1, p2, ScreenPlainOfSleepingMoon, aUserValue);
end;

{ TPlainGame }

procedure TPlainGame.Create;
begin
  Activated := True;

  FUpdateTrainEngineVolume := True;

  if sndMusic = NIL then begin
    Audio.PauseMusicTitleMap(1.0);
    sndMusic := Audio.AddMusic('Boss_Time.ogg', False);
    sndMusic.SetLoopBounds(14.767, sndMusic.TotalDuration);
  end;
  if sndTrainWheel = NIL then begin
    sndTrainWheel := Audio.AddSound('train.ogg', 0.0, True);
    sndTrainWheel.FadeIn(0.6, 2.0);
  end;

  // game inventory
  FGameinventory := TGameInventory.Create;

  // scrolling speed
  FScrollingSpeed := TFParam.Create;
  FScrollingSpeed.Value := 1.0;

  // sky
  FSky.Create;

  // mountain parallax
  FMountainParallax.Create(ScaleH(70), ScaleH(0));

  // factory parallax
  FFactoryParallax.Create(ScaleH(736));

  // rails
  FYRail := FScene.Height - texRail^.FrameHeight;
  FGround.Create(FYRail);

  // train
  FTrain.Create(FYRail-ScaleH(318), LAYER_FXANIM);

  // Penelope
  FPenelope := TWolfPenelope.Create(False, -1);
  FTrain.Loco.AddChild(FPenelope, 10);
  FPenelope.X.Value := FTrain.Loco.FullWidth*0.6;
  FPenelope.BodyBottomY := YFeetOnTrain;
  FPenelope.SetRunMode;
  FPenelope.JumpDeltaX := FScene.Width*0.1;
  FPenelope.IdleRight;
  FPenelope.ApplyTint(BGRA(29,0,50,80));

  // LR
  FLR := TLR4Direction.Create(-1);
  FTrain.LastWagon.AddChild(FLR, 10);
  FLR.X.Value := FTrain.LastWagon.FullWidth*0.1;
  FLR.BodyBottomY := YFeetOnTrain;
  FLR.TimeMultiplicator := 0.4;
  FLR.JumpDeltaX := FScene.Width*0.115;
  FLR.SetWindSpeed(3.0);
  FLR.IdleRight;
  FLR.ApplyTint(BGRA(29,0,50,80));
  FLR.LRRight.ApplyTint(BGRA(29,0,50,80));
  FLR.LRBack.ApplyTint(BGRA(29,0,50,80));
  FLR.LRFront.ApplyTint(BGRA(29,0,50,80));
  // laser gun for LR
  FLaserGun := TSprite.Create(texLaserGun, False);
  FLaserGun.ApplySymmetryWhenFlip := True;
  FLR.LRRight.AddObjectInRightHand(FLaserGun,
            PointF(-texLaserGun^.FrameWidth*0.05, -texLaserGun^.FrameHeight*0.6), -1);

  // Oak forest
  FOakForest.Create(FYRail + texRail^.FrameHeight*0.5);

  // camera
  FCamera := FScene.CreateCamera;
  FCamera.AssignToLayerRange(LAYER_DIALOG, LAYER_BG3);
  FCamera.Pivot := PointF(0.5, 1.0);  // keeps the camera aligned to the bottom of the screen
  FCamera.MoveTo(PointF(FScene.Width*2, FScene.Height*0.5));
end;

procedure TPlainGame.FreeRenderer;
begin
  FSky.FreeRenderer;
  FMountainParallax.FreeRenderer;
end;

{ TPlainIntroductionCinematic.TCustomWagon }

procedure TPlainIntroductionCinematic.TCustomWagon.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  exit;
  if not Loop then exit;

  if X.Value > FScene.Width then
    X.Value := FNextWagon.X.Value - texWagonHook^.FrameWidth - FullWidth;
end;

{ TPlainIntroductionCinematic }

procedure TPlainIntroductionCinematic.CreateVerticalRock(ax, aY: single; aLayerIndex: integer);
var w, h: integer;
  o: TSprite;
begin
  w := texGroundFlat^.FrameWidth;
  h := texGroundFlat^.FrameHeight;
  o := FScene.AddSprite(texGroundFlat, False, aLayerIndex);
  o.Angle.Value := 90;
  o.SetCoordinate(aX-(w-h)*0.5, aY+(w-h)*0.5);
  ApplyNightEffectOn(o);
end;

procedure TPlainIntroductionCinematic.CreateGroundDeep(aX, aY: single; aLayerIndex: integer);
var o: TSprite;
begin
  o := FScene.AddSprite(texGroundDeep, False, aLayerIndex);
  o.SetCoordinate(aX, aY);
  ApplyNightEffectOn(o);
end;

procedure TPlainIntroductionCinematic.CallbackLRDoOnJumpMove(aDuration: single; aJumpStep: integer);
var v, deltaX: single;
begin
  if FLR.LRRight.IsFlippedH then v := -1 else v := 1;
  deltaX := FScene.Width*0.08;
  case aJumpStep of
    0: begin  // up
      FLR.Y.ChangeTo(FLR.Y.Value - FScene.Height*0.1, aDuration, idcStartFastEndSlow);
      FLR.X.ChangeTo(FLR.X.Value + deltaX*v, aDuration, idcLinear);
    end;
    1: begin  // down
      FLR.Y.ChangeTo(ScaleH(420)-FLR.DeltaYToBottom, aDuration, idcStartSlowEndFast);
      FLR.X.ChangeTo(FLR.X.Value + deltaX*v, aDuration, idcLinear);
    end;
    2: begin
      FLR.IdleRight;
      //FLR.State := lr4sStartAnimWinner;
      FLR.Speed.x.Value := FWagon1.Speed.x.Value;
    end;
  end;
end;


procedure TPlainIntroductionCinematic.Create;
var i: integer;
  xx, yy, a: single;
  sky: TGradientRectangle;
  clouds: TOGLCSpriteClouds;
  o: TSprite;
begin
  Activated := True;

  FUpdateTrainEngineVolume := False;

  Audio.PauseMusicTitleMap(3.0);
  sndTrainWheel := Audio.AddSound('train.ogg', 0.0, True);
  sndTrainWheel.FadeIn(0.6, 2.0);

  // sky gradient
  sky := TGradientRectangle.Create;
  sky.Gradient.CreateVertical([BGRA(60,0,184), BGRA(212,68,119), BGRA(57,4,37), BGRA(57,4,37)],
                              [0.0, 0.35, 0.6, 1.0]);
  sky.SetSize(FScene.Width, FScene.Height);
  sky.SetCoordinate(0, 0);
  FScene.Add(sky, LAYER_GROUND);

  // mountain 2
  with FScene.AddSprite(texMountain2, False, LAYER_GROUND) do
    SetCoordinate(ScaleW(130), ScaleH(124));
  // cloud 2
  FCloudsRenderer := TOGLCCloudsRenderer.Create(FScene, True);
  clouds := TOGLCSpriteClouds.Create(FScene, FCloudsRenderer);
  FScene.Add(clouds, LAYER_GROUND);
  clouds.SetSize(FScene.Width, Round(FScene.Height*0.3));
  clouds.SetCoordinate(0, -FScene.Height*0.0);
  clouds.LoadParamsFromString(CLOUDS_CLOUDS);
  clouds.Opacity.Value := 150;
  clouds.BlendMode := FX_BLEND_ADD;

  // mountain 1
  with FScene.AddSprite(texMountain1, False, LAYER_GROUND) do begin
    SetCoordinate(ScaleW(0), ScaleH(206));
    FlipH := True;
  end;
  // cloud 1
  clouds := TOGLCSpriteClouds.Create(FScene, FCloudsRenderer);
  FScene.Add(clouds, LAYER_GROUND);
  clouds.SetSize(FScene.Width, Round(FScene.Height*0.4));
  clouds.SetCoordinate(0, FScene.Height*0.2);
  clouds.LoadParamsFromString(CLOUDS_CLOUDS);
  clouds.Opacity.Value := 50;
  //clouds.BlendMode := FX_BLEND_ADD;

  // backward wall
  CreateVerticalRock(ScaleW(128), ScaleH(640), LAYER_GROUND);
  CreateVerticalRock(ScaleW(128), ScaleH(512), LAYER_GROUND);
  CreateVerticalRock(ScaleW(128), ScaleH(384), LAYER_GROUND);
  yy := ScaleH(704);
  for i:=0 to 5 do begin
    CreateGroundDeep(0, yy, LAYER_GROUND);
    yy := yy - texGroundDeep^.FrameHeight;
  end;
  o := FScene.AddSprite(texGroundCorner, False, LAYER_GROUND);
  o.SetCoordinate(ScaleW(128), ScaleH(320));
  ApplyNightEffectOn(o);
  o := FScene.AddSprite(texGroundSlope, False, LAYER_GROUND);
  o.SetCoordinate(ScaleW(0), ScaleH(256));
  o.FlipH := True;
  ApplyNightEffectOn(o);
  o := FScene.AddSprite(texGround1, False, LAYER_GROUND);
  o.SetCoordinate(0, ScaleH(346));
  ApplyNightEffectOn(o);
  o := FScene.AddSprite(texGround1Right, False, LAYER_GROUND);
  o.SetCoordinate(ScaleW(178), ScaleH(346));
  ApplyNightEffectOn(o);

  // rails
  xx := 0;
  for i:=0 to 7 do begin
    o := FScene.AddSprite(texRail, False, LAYER_GROUND);
    o.SetCoordinate(xx, FScene.Height-texRail^.FrameHeight);
    ApplyNightEffectOn(o);
    xx := xx + texRail^.FrameWidth;
  end;

  // forward wall
  CreateVerticalRock(ScaleW(46), ScaleH(640), LAYER_WOLF);
  CreateVerticalRock(ScaleW(46), ScaleH(512), LAYER_WOLF);
  CreateVerticalRock(ScaleW(46), ScaleH(384), LAYER_WOLF);
  yy := ScaleH(704);
  for i:=0 to 5 do begin
    CreateGroundDeep(ScaleW(-82), yy, LAYER_WOLF);
    yy := yy - texGroundDeep^.FrameHeight;
  end;
  o := FScene.AddSprite(texGroundCorner, False, LAYER_WOLF);
  o.SetCoordinate(ScaleW(46), ScaleH(320));
  ApplyNightEffectOn(o);
  o := FScene.AddSprite(texGroundSlope, False, LAYER_WOLF);
  o.SetCoordinate(ScaleW(-82), ScaleH(256));
  o.FlipH := True;
  ApplyNightEffectOn(o);

  // rock1
  o := FScene.AddSprite(texRock1, False, LAYER_WOLF);
  o.SetCoordinate(FScene.Width-texRock1^.FrameWidth*1.1, FScene.Height-texRock1^.FrameHeight);
  ApplyNightEffectOn(o);

  // wagons x2
  yy := FScene.Height - texRail^.FrameHeight - ScaleH(318);
  FWagon1 := TCustomWagon.Create(yy, -1, LAYER_FXANIM);
  FWagon1.X.Value := 0;
  FWagon1.Speed.x.Value := FScene.Width * 0.5;
  a := LinearSpeedToAngleRotation(FWagon1.Speed.x.Value, texWheel^.FrameWidth*0.5);
  FWagon1.SetWheelAngle(a);
  FWagon1.Loop := True;

  FWagon2 := TCustomWagon.Create(yy, -1, LAYER_FXANIM);
  FWagon2.X.Value := -FWagon2.FullWidth - texWagonHook^.FrameWidth;
  FWagon2.Speed.x.Value := FWagon1.Speed.x.Value;
  FWagon2.SetWheelAngle(a);
  FWagon2.Loop := True;

  FWagon1.FNextWagon := FWagon2;
  FWagon2.FNextWagon := FWagon1;
  Loop := True;

  // LR
  FLR := TLR4Direction.Create;
  FScene.MoveSurfaceToLayer(FLR, LAYER_FXANIM);
  FLR.X.Value := -FLR.BodyWidth*2;
  FLR.LRRight.CallbackDoOnJumpMove := @CallbackLRDoOnJumpMove;
  FLR.ApplyTint(BGRA(29,0,50,80));

  ScreenPlainOfSleepingMoon.PostMessage(0, 5); // LR appear after 5s
end;

procedure TPlainIntroductionCinematic.FreeRenderer;
begin
  FCloudsRenderer.Free;
  FCloudsRenderer := NIL;
end;

procedure TPlainIntroductionCinematic.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin
      FLR.Y.Value := ScaleH(360)-FLR.DeltaYToBottom;
      FLR.IdleRight;
      FLR.WalkHorizontallyTo(ScaleW(160), ScreenPlainOfSleepingMoon, 1);
    end;
    1: begin
      FLR.IdleRight;
      FLR.SetFaceType(lrfWorry);
      FLR.ShowDialog(sATrain, FFontText, ScreenPlainOfSleepingMoon, 2);
    end;
    2: FLR.ShowDialog(sIDontKnowWhereItsGoing, FFontText, ScreenPlainOfSleepingMoon, 3);
    3: begin // before jumping, we wait there is a wagon below
      if Inrange(FWagon1.X.Value, -FWagon1.Speed.x.Value*0.5, -FWagon1.Speed.x.Value*0.25) then begin
        FWagon2.Visible := False;
        FWagon1.Loop := False;
        FWagon2.Loop := False;
        Loop := False;
        ScreenPlainOfSleepingMoon.PostMessage(10);
      end
      else
      if Inrange(FWagon2.X.Value, -FWagon2.Speed.x.Value*0.5, -FWagon2.Speed.x.Value*0.25) then begin
        FWagon1.Visible := False;
        FWagon1.Loop := False;
        FWagon2.Loop := False;
        Loop := False;
        ScreenPlainOfSleepingMoon.PostMessage(10);
      end
      else ScreenPlainOfSleepingMoon.PostMessage(3);
    end;
    10: begin
      FLR.TimeMultiplicator := 0.6;
      FLR.State := lr4sJumping;
      ScreenPlainOfSleepingMoon.PostMessage(100);
    end;
    100: begin // jump is done: we wait until LR is out of the scene
      if FLR.X.Value > FScene.Width+FLR.BodyWidth*10 then
        ScreenPlainOfSleepingMoon.PostMessage(101)
      else
        ScreenPlainOfSleepingMoon.PostMessage(100);
    end;
    101: begin // LR is no more visible: we start the anim with Penelope
      FScene.ColorFadeIn(BGRABlack, 0.5);
      ScreenPlainOfSleepingMoon.PostMessage(102, 0.5);
    end;
    102: begin
      FScene.ClearAllLayer;
      FPlainIntroductionCinematic.Activated := False;
      FPlainIntroductionCinematic.FreeRenderer;
      FPlainGame.Create;
      FScene.ColorFadeOut(0.5);
      ScreenPlainOfSleepingMoon.PostMessage(0, 0.5);
      PlayerInfo.PlainMoon.IntroAlreadySeen := True;
      FSaveGame.Save;
    end;
  end;//case
end;

procedure TPlainIntroductionCinematic.UpdateWagonsPosition;
begin
  if not Loop then exit;

  if FWagon1.X.Value > FScene.Width then begin
    FScene.RemoveSurfaceFromItsLayer(FWagon1);
    FScene.Insert(0, FWagon1, LAYER_FXANIM);
    FWagon1.X.Value := FWagon2.X.Value - texWagonHook^.FrameWidth - FWagon1.FullWidth;
  end;

  if FWagon2.X.Value > FScene.Width then begin
    FScene.RemoveSurfaceFromItsLayer(FWagon2);
    FScene.Insert(0, FWagon2, LAYER_FXANIM);
    FWagon2.X.Value := FWagon1.X.Value - texWagonHook^.FrameWidth - FWagon2.FullWidth;
  end;
end;

{ TOakForest.TRock1 }

procedure TOakForest.TRock1.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if X.Value < -texRock1^.FrameWidth then X.Value := texRock1^.FrameWidth + FScene.Width*4;
end;

{ TFactoryParallax.TFactory3 }

procedure TFactoryParallax.TFactory3.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if ScaledX < -ScaledWidth then begin
    ScaledX := ScaledX + FScene.Width*4 + texFactory3^.FrameWidth * scalecoeff;
    Visible := MakeFactoryAppears;
  end;
end;

procedure TFactoryParallax.TFactory2.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if ScaledX < -ScaledWidth then begin
    ScaledX := ScaledX + FScene.Width*4 + texFactory2^.FrameWidth * scalecoeff; // ScaledX + ScaledWidth*FCount;
    Visible := MakeFactoryAppears;
  end;
end;

{ TFactoryParallax.TFactory1 }

constructor TFactoryParallax.TFactory1.Create(aX, aYBottom, aSpeed: single);
begin
  inherited Create(texFactory1, False);
  FScene.Add(Self, useLayer);
  Scale.Value := PointF(scalecoeff, scalecoeff);
  ScaledX := aX;
  ScaledBottomY := aYBottom;
  Speed.X.Value := aSpeed;
  FCanCreateAnother := True;
end;

procedure TFactoryParallax.TFactory1.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if FCanCreateAnother and (X.Value < FScene.Width*4) then begin
    FCanCreateAnother := False;
    // create the next factory 1 to the right
    TFactory1.Create(ScaledRightX, ScaledBottomY, Speed.X.Value);
  end;

  if ScaledRightX < 0 then Kill;
end;

{ TFactoryParallax }

procedure TFactoryParallax.SetFactory3Speed(AValue: single);
var i :integer;
begin
  if (FFactory3Speed=AValue) and not FForceSpeedUpdate then exit;
  FFactory3Speed := AValue;
  for i:=0 to FScene.Layer[useLayer].SurfaceCount-1 do
    if FScene.Layer[useLayer].Surface[i] is TFactory3 then
      FScene.Layer[useLayer].Surface[i].Speed.x.Value := AValue;
end;

procedure TFactoryParallax.SetFactory2Speed(AValue: single);
var i :integer;
begin
  if (FFactory2Speed=AValue) and not FForceSpeedUpdate then exit;
  FFactory2Speed := AValue;
  for i:=0 to FScene.Layer[useLayer].SurfaceCount-1 do
    if FScene.Layer[useLayer].Surface[i] is TFactory2 then
      FScene.Layer[useLayer].Surface[i].Speed.x.Value := AValue;
end;

procedure TFactoryParallax.SetFactory1Speed(AValue: single);
var i :integer;
begin
  if (FFactory1Speed=AValue) and not FForceSpeedUpdate then exit;
  FFactory1Speed := AValue;
  for i:=0 to FScene.Layer[useLayer].SurfaceCount-1 do
    if FScene.Layer[useLayer].Surface[i] is TFactory1 then
      FScene.Layer[useLayer].Surface[i].Speed.x.Value := AValue;
end;

procedure TFactoryParallax.Create(aYBottom: single);
var xx, yy: single;
  flip: Boolean;
  f3: TFactory3;
  f2: TFactory2;
begin
  FYBottom := aYBottom;

  // factory 3
  yy := aYBottom - texFactory3^.FrameHeight*0.2;
  xx := -texFactory3^.FrameWidth * scalecoeff;
  flip := False;
  while xx <= FScene.Width*4 - texFactory3^.FrameWidth * scalecoeff do begin
    f3 := TFactory3.Create(texFactory3, False);
    FScene.Add(f3, useLayer);
    f3.Scale.Value := PointF(scalecoeff, scalecoeff);
    f3.ScaledX := xx;
    f3.ScaledBottomY := yy;
    f3.FlipH := flip;
    flip := not flip;
    f3.Visible := False;
    xx := xx + f3.ScaledWidth * (1.1 + Random);
  end;

  // factory 2
  yy := aYBottom - texFactory2^.FrameHeight*0.25;
  xx := -texFactory2^.FrameWidth * scalecoeff;
  while xx <= FScene.Width*4 - texFactory2^.FrameWidth * scalecoeff do begin
    f2 := TFactory2.Create(texFactory2, False);
    FScene.Add(f2, useLayer);
    f2.Scale.Value := PointF(scalecoeff, scalecoeff);
    f2.ScaledX := xx;
    f2.ScaledBottomY := yy;
    f2.Visible := False;
    xx := xx + f2.ScaledWidth * (1.2 + Random);
  end;
end;

procedure TFactoryParallax.MakeFactoryAppears;
var i: Integer;
  o: TSimpleSurfaceWithEffect;
begin
  for i:=0 to FScene.Layer[LAYER_BG2].SurfaceCount-1 do begin
    o := FScene.Layer[LAYER_BG2].Surface[i];
    if (o is TCustomFactory) then TCustomFactory(o).MakeFactoryAppears := True;
  end;

  // create the first factory 1 to the right
  //TFactory2.Create(FScene.Width*4.1, FYBottom - texFactory2^.FrameHeight*0.25, FFactory2Speed);
  TFactory1.Create(FScene.Width*4, FYBottom, FFactory1Speed);
end;

{ TOakForest }

procedure TOakForest.SetSpeed(AValue: single);
var i: integer;
  o: TSimpleSurfaceWithEffect;
begin
  if (FSpeed=AValue) and not FForceSpeedUpdate then Exit;
  FSpeed := AValue;
  for i:=0 to FScene.Layer[useLayer].SurfaceCount-1 do begin
    o := FScene.Layer[useLayer].Surface[i];
    if (o is TOakTrees) or (o is TRock1) then
      FScene.Layer[useLayer].Surface[i].Speed.x.Value := AValue;
  end;
end;

procedure TOakForest.Create(aBottomY: single);
var tree: TOakTrees;
  xx: single;
  flip: boolean;
  ro: TRock1;
begin
  // oaks
  xx := 0;
  flip := False;
  while xx < FScene.Width*4 do begin
    tree := TOakTrees.Create(texOakForest, False);
    tree.FBottomY := aBottomY;
    FScene.Add(tree, useLayer);
    tree.SetScale;
    tree.ScaledX := xx;
    tree.FlipH := flip;
    tree.Tint.Value := BGRA(29,0,50,180);
    flip := not flip;
    xx := xx + tree.ScaledWidth * (2 + Random*2);
  end;

  // rock1
  xx := 0;
  while xx < FScene.Width*4 do begin
    ro := TRock1.Create(texRock1, False);
    FScene.Add(ro, useLayer);
    ro.Tint.Value := BGRA(29,0,50,180);
    ro.SetCoordinate(xx, ScaleH(640));
    xx := xx + texRock1^.FrameWidth*(6+Random*5);
  end;
end;

{ TOakForest.TOakTrees }

procedure TOakForest.TOakTrees.SetScale;
var sc: single;
begin
  sc := 1.6+Random*0.4;
  Scale.Value := PointF(sc,sc);
  ScaledBottomY := FBottomY;
end;

procedure TOakForest.TOakTrees.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if ScaledX < -ScaledWidth then begin
    SetScale;
    FlipH := not FlipH;
    ScaledX := ScaledWidth + FScene.Width*5+FScene.Width*Random*10.0;
  end;
end;

{ TMountainParallax.TMountain1 }

procedure TMountainParallax.TMountain1.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if X.Value <= -Width then X.Value := X.Value + Count*texMountain1^.FrameWidth;
end;

{ TMountainParallax.TMountain2 }

procedure TMountainParallax.TMountain2.SetYCoordinate;
begin
  Y.Value := FYMountain2Base+(texMountain2^.FrameHeight*random*0.5-texMountain2^.FrameHeight*0.25);
end;

procedure TMountainParallax.TMountain2.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if X.Value < -texMountain2^.FrameWidth then begin
    X.Value := X.Value + FScene.Width*4 + texMountain2^.FrameWidth;
    SetYCoordinate;
  end;
end;

{ TMountainParallax }

procedure TMountainParallax.SetCloudSpeed(AValue: single);
begin
  FClouds.TranslationSpeed := 0.0; // -0.0050 - AValue*0.0001;
  FClouds2.TranslationSpeed := Min(-0.015, AValue*0.01);
  FCloudSpeed := AValue;
end;

procedure TMountainParallax.SetMountain2Speed(AValue: single);
var i: integer;
  o: TSimpleSurfaceWithEffect;
begin
  if (FMountain2Speed=AValue) and not FForceSpeedUpdate then Exit;
  FMountain2Speed := AValue;
  for i:=0 to FScene.Layer[useLayer].SurfaceCount-1 do begin
    o := FScene.Layer[useLayer].Surface[i];
    if o is TMountain2 then
      o.Speed.x.Value := AValue;
  end;
end;

procedure TMountainParallax.SetMountain1Speed(AValue: single);
var i: integer;
  o: TSimpleSurfaceWithEffect;
begin
  if (FMountain1Speed=AValue) and not FForceSpeedUpdate then Exit;
  FMountain1Speed := AValue;
  for i:=0 to FScene.Layer[useLayer].SurfaceCount-1 do begin
    o := FScene.Layer[useLayer].Surface[i];
    if o is TMountain1 then
      o.Speed.x.Value := AValue;
  end;
end;

procedure TMountainParallax.Create(aYMountain1, aYMountain2: single);
var xx: single;
  m2: TMountain2;
  m1: TMountain1;
  c, i: integer;
  flip: boolean;
begin
  // mountain 2
  xx := -texMountain2^.FrameWidth;
  flip := False;
  while xx < FScene.Width*4 + texMountain2^.FrameWidth do begin
    m2 := TMountain2.Create(texMountain2, False);
    FScene.Add(m2, useLayer);
    m2.X.Value := xx;
    m2.FYMountain2Base := aYMountain2;
    m2.SetYCoordinate;
    m2.FlipH := flip;
    flip := not flip;
    xx := xx + texMountain2^.FrameWidth * (1 + Random*2);
  end;

  // cloud 1
  FCloudsRenderer := TOGLCCloudsRenderer.Create(FScene, True);
  FClouds := TOGLCSpriteClouds.Create(FScene, FCloudsRenderer);
  FScene.Add(FClouds, useLayer);
  FClouds.SetSize(Round(FScene.Width*4.5), Round(FScene.Height*0.5));
  FClouds.SetCoordinate(-FScene.Width*0.25, -FScene.Height*0.2);
  FClouds.LoadParamsFromString(CLOUDS_CLOUDS);
  FClouds.Opacity.Value := 150;
  FClouds.BlendMode := FX_BLEND_ADD;

  // mountain 1
  xx := -texMountain1^.FrameWidth;
  c := 0;
  flip := False;
  while xx < FScene.Width*4 + texMountain1^.FrameWidth do begin
    m1 := TMountain1.Create(texMountain1, False);
    FScene.Add(m1, useLayer);
    m1.SetCoordinate(xx, aYMountain1);
    m1.FlipH := flip;
    flip := not flip;
    xx := xx + texMountain1^.FrameWidth;
    inc(c);
  end;
  for i:=0 to FScene.Layer[useLayer].SurfaceCount-1 do
    if FScene.Layer[useLayer].Surface[i] is TMountain1 then
      TMountain1(FScene.Layer[useLayer].Surface[i]).Count := c;

  // cloud 2
  FClouds2 := TOGLCSpriteClouds.Create(FScene, FCloudsRenderer);
  FScene.Add(FClouds2, useLayer);
  FClouds2.SetSize(Round(FScene.Width*4.5), Round(FScene.Height*0.4));
  FClouds2.SetCoordinate(-FScene.Width*0.25, FScene.Height*0.1);
  FClouds2.LoadParamsFromString(CLOUDS_CLOUDS);
  FClouds2.Opacity.Value := 50;
  //FClouds2.BlendMode := FX_BLEND_ADD;
end;

procedure TMountainParallax.FreeRenderer;
begin
  FCloudsRenderer.Free;
  FCloudsRenderer := NIL;
end;

{ TSky }

procedure TSky.Create;
var sky: TGradientRectangle;
begin
  // high sky gradient
  sky := TGradientRectangle.Create;
  sky.Gradient.CreateVertical([BGRA(60,0,184), BGRA(60,0,184), BGRA(60,0,184)],
                              [0.0, 0.55, 1.0]);
//  sky.SetSize(Round(FScene.Width*4.5), FScene.Height*2);
//  sky.SetCoordinate(-FScene.Width*0.25, -FScene.Height*3);
  sky.SetSize(Round(FScene.Width*4), FScene.Height*2);
  sky.SetCoordinate(0, -FScene.Height*3);
  FScene.Add(sky, LAYER_BG3);


  // low sky gradient
  sky := TGradientRectangle.Create;
//  sky.Gradient.CreateVertical([BGRA(180,87,237), BGRA(212,68,119), BGRA(57,4,37), BGRA(57,4,37)],
//                              [0.0, 0.35, 0.6, 1.0]);
  sky.Gradient.CreateVertical([BGRA(60,0,184), BGRA(212,68,119), BGRA(57,4,37), BGRA(57,4,37)],
                              [0.0, 0.35, 0.6, 1.0]);
//  sky.SetSize(Round(FScene.Width*4.5), FScene.Height*2);
//  sky.SetCoordinate(-FScene.Width*0.25, -FScene.Height);
  sky.SetSize(Round(FScene.Width*4), FScene.Height*2);
  sky.SetCoordinate(0, -FScene.Height);
  FScene.Add(sky, LAYER_BG3);

  // star nest
  FStarNestRenderer := TStarNestRenderer.Create(FScene, True);
  FStarNest := TStarNest.Create(FScene, FStarNestRenderer);
//  FStarNest.SetSize(Round(FScene.Width*4.5), Round(FScene.Height*2.75));
//  FStarNest.SetCoordinate(-FScene.Width*0.25, -FScene.Height*3);
  FStarNest.SetSize(Round(FScene.Width*4), Round(FScene.Height*2.75));
  FStarNest.SetCoordinate(05, -FScene.Height*3);
  FStarNest.FlipV := True;
  FScene.Add(FStarNest, LAYER_BG3);

  // moon
  FPlanetRenderer := TOGLCPlanetRenderer.Create(FScene, True);
  FMoon := TOGLCSpritePlanet.Create(FScene, FPlanetRenderer);
  FMoon.LoadParamsFromString(PLANET_PINKY_MOON);
  FMoon.SetSize(Round(FScene.Width*0.6), Round(FScene.Width*0.6));
  FMoon.SetCoordinate(FScene.Width*2.5, -FScene.Height*0.6);
  FScene.Add(FMoon, LAYER_BG3);

end;

procedure TSky.FreeRenderer;
begin
  FStarNestRenderer.Free;
  FStarNestRenderer := NIL;
  FPlanetRenderer.Free;
  FPlanetRenderer := NIL;
end;

{ TGround.TRail }

procedure TGround.TRail.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if X.Value <= -Width*5 then X.Value := X.Value + RailCount*Width;
end;

{ TGround }

procedure TGround.SetSpeed(AValue: single);
var i: integer;
begin
  if (FSpeed=AValue) and not FForceSpeedUpdate then Exit;
  FSpeed := AValue;
  for i:=0 to FScene.Layer[useLayer].SurfaceCount-1 do
    FScene.Layer[useLayer].Surface[i].Speed.x.Value := AValue;
end;

procedure TGround.Create(aTopY: single);
var xx: single;
  r: TRail;
  c, i: integer;
begin
  xx := -texRail^.FrameWidth*5;
  c := 0;
  while xx < FScene.Width*4 + texRail^.FrameWidth*5 do begin
    r := TRail.Create(texRail, False);
    FScene.Add(r, useLayer);
    r.Tint.Value := BGRA(29,0,50,150);
    r.SetCoordinate(xx, aTopY);
    xx := xx + texRail^.FrameWidth;
    inc(c);
  end;
  for i:=0 to FScene.Layer[useLayer].SurfaceCount-1 do
    TRail(FScene.Layer[useLayer].Surface[i]).RailCount := c;
end;

{ TTrain }

procedure TTrain.InitDefault;
begin
  FCharacterToFollow := NIL;
end;

procedure TTrain.Create(aY: single; aLayerIndex: integer);
var i: integer;
begin
  Loco := TLocomotive.Create(0, aY, aLayerIndex);

  Wagons := NIL;
  SetLength(Wagons, PLAIN_MOON_WAGON_COUNT);
  for i:=0 to PLAIN_MOON_WAGON_COUNT-1 do begin
    Wagons[i] := TWagon.Create(aY, i+1 ,aLayerIndex);
    Wagons[i].Tag1 := i+1; // first wagon have tag1=1, second tag1=2, ...
//    if i = 0 then Wagons[i].BindToSprite(Loco, -Wagons[i].FullWidth-texWagonHook^.FrameWidth, 0)
//      else Wagons[i].BindToSprite(Wagons[i-1], -Wagons[i].FullWidth-texWagonHook^.FrameWidth, 0);
    // railing becomes child of its wagon
    Wagons[i].FTail.Railing.SetChildOf(Wagons[i], 20);
    Wagons[i].FHead.Railing.SetChildOf(Wagons[i], 20);
  end;

  FDirectionnalArrow := TDirectionnalArrow.Create(d4Down, texArrowYellow, -1);
  Wagons[0].AddChild(FDirectionnalArrow, 0);
  HideDirectionnalArrow;

  FCharacterToFollow := NIL;
  SetQuickMoves;

  sndEngine := Audio.AddSound('engine-47745.ogg', 0.4, True);
  sndEngine.Attenuation3D(FScene.Width*1.0, FScene.Width*7, 1.0, 1.0);
  sndEngine.Position3D(Loco.X.Value, 0, 0);
  sndEngine.PositionRelativeToListener := False;
  sndEngine.DistanceModel := AL_LINEAR_DISTANCE_CLAMPED; // AL_INVERSE_DISTANCE_CLAMPED
  sndEngine.Play(True);
end;

procedure TTrain.DeleteSound;
begin
  if sndEngine <> NIL then sndEngine.FadeOutThenKill(1.0);
  sndEngine := NIL;
end;

procedure TTrain.SetWheelSpeed(aLinearSpeed: single);
var w: TWagon;
  a: single;
begin
  a := LinearSpeedToAngleRotation(aLinearSpeed, texWheel^.FrameWidth*0.5); //(65));
  Loco.SetWheelAngle(a);
  for w in Wagons do
    w.SetWheelAngle(a);
end;

function TTrain.LastWagon: TWagon;
begin
  Result := Wagons[PLAIN_MOON_WAGON_COUNT-1];
end;

procedure TTrain.SetSmoothMoves;
begin
  MovingTime := 0.18;
end;

procedure TTrain.SetQuickMoves;
begin
  MovingTime := 0.08;
end;

procedure TTrain.UpdatePosition;
var delta: single;
  i: integer;
begin
  // we moves the wagon to keep them linked
  // because Surface.Bind have a delay
  for i:=0 To PLAIN_MOON_WAGON_COUNT-1 do
    Wagons[i].X.Value := Loco.X.Value - (texWagonHook^.FrameWidth + Wagons[0].FullWidth)*(i+1);

  if FCharacterToFollow = NIL then exit;

  i := FCharacterToFollow.ParentSurface.Tag1; // tag1 is an index: loco:0  1st wagon:1, etc...
  if i = 0 then delta := 0
    else delta := i * (texWagonHook^.FrameWidth + Wagons[0].FullWidth);
  Loco.X.ChangeTo(FScene.Width*2 - FCharacterToFollow.X.Value + delta, MovingTime, idcSinusoid);

end;

procedure TTrain.UpdateDoorLight;
var wagonPart: TWagonHead;
begin
   if CheckIfCharacterToFollowCanOpenTheDoor(wagonPart) then begin
     if wagonPart <> NIL then wagonPart.SetDoorLightGreen;
   end else if wagonPart <> NIL then wagonPart.SetDoorLightRed;
end;

procedure TTrain.SetCharacterToFollow(aCharacter: TWalkingCharacter);
begin
  FCharacterToFollow := aCharacter;
end;

function TTrain.CheckIfCharacterToFollowCanFall: boolean;
var indexWagon: integer;
begin
  if FCharacterToFollow = NIL then Result := False
  else begin
    indexWagon := FCharacterToFollow.ParentSurface.Tag1;
    if indexWagon = 0
       then Result := not InRange(FCharacterToFollow.X.Value, Loco.FullWidth*0.015, Loco.FullWidth*0.65)
       else Result := not InRange(FCharacterToFollow.X.Value,
                                  Wagons[indexWagon-1].FullWidth*0.01,  //0.015
                                  Wagons[indexWagon-1].FullWidth*0.99); //0.985
  end;
end;

function TTrain.CharacterToFollowIsAboveLadder: boolean;
var indexWagon: integer;
begin
  if FCharacterToFollow = NIL then Result := False
  else begin
    indexWagon := FCharacterToFollow.ParentSurface.Tag1;
    if indexWagon = 0
      then Result := False
      else Result := (FCharacterToFollow.BodyBottomY = YFeetOnTrain) and
                   // right ladder
                  (InRange(FCharacterToFollow.X.Value,
                           Wagons[indexWagon-1].FullWidth-ScaleW(288-15),
                           Wagons[indexWagon-1].FullWidth-ScaleW(224+15)) or
                   // left ladder
                   InRange(FCharacterToFollow.X.Value, ScaleW(224+15), ScaleW(288-15)));
  end;
end;

function TTrain.CharacterToFollowCanClimbUpLadder: boolean;
var indexWagon: integer;
begin
  if FCharacterToFollow = NIL then Result := False
  else begin
    indexWagon := FCharacterToFollow.ParentSurface.Tag1;
    if indexWagon = 0
      then Result := False
      else Result := (FCharacterToFollow.BodyBottomY = YFeetOnPlatform) and
                   // right ladder
                  (InRange(FCharacterToFollow.X.Value,
                           Wagons[indexWagon-1].FullWidth-ScaleW(288-15),
                           Wagons[indexWagon-1].FullWidth-ScaleW(224+15)) or
                   // left ladder
                   InRange(FCharacterToFollow.X.Value, ScaleW(224+15), ScaleW(288-15)));
  end;
end;

function TTrain.CharacterToFollowIsOnRoof: boolean;
begin
  if FCharacterToFollow = NIL then Result := False
    else Result := FCharacterToFollow.BodyBottomY = YFeetOnTrain;
end;

function TTrain.CharacterToFollowIsOnPlatform: boolean;
begin
  if FCharacterToFollow = NIL then Result := False
    else Result := FCharacterToFollow.BodyBottomY = YFeetOnPlatform;
end;

function TTrain.CharacterToFollowIsOnHeadPlatform: boolean;
var indexWagon: integer;
begin
  if (FCharacterToFollow = NIL) or not CharacterToFollowIsOnPlatform then Result := False
    else begin
      indexWagon := FCharacterToFollow.ParentSurface.Tag1;
      if indexWagon = 0
        then Result := False
        else Result := FCharacterToFollow.X.Value > Wagons[indexWagon-1].FullWidth*0.5;
    end;
end;

function TTrain.CharacterToFollowIsOnTailPlatform: boolean;
var indexWagon: integer;
begin
  if (FCharacterToFollow = NIL) or not CharacterToFollowIsOnPlatform then Result := False
    else begin
      indexWagon := FCharacterToFollow.ParentSurface.Tag1;
      if indexWagon = 0
        then Result := False
        else Result := FCharacterToFollow.X.Value < Wagons[indexWagon-1].FullWidth*0.5;
    end;
end;

function TTrain.CharacterToFollowCanOpenTheDoor: boolean;
var wagonPart: TWagonHead;
begin
  Result := CheckIfCharacterToFollowCanOpenTheDoor(wagonPart);
end;

procedure TTrain.PlaceLRToGetsOutOfTheWagon(aWagonIndex: integer; out aWagonPart: TWagonHead);
var wag: TWagon;
  door: TAutomaticDoor;
begin
  wag := Wagons[aWagonIndex];
  door := wag.FHead.Door;
  aWagonPart := wag.FHead;
  FLR.SetChildOf(door, 20); // -2
  FLR.X.Value := door.Width*0.5;
  FLR.BodyBottomY := door.Height;
  FLR.IdleDown;
  FLR.SetChildOf(wag, -10);
end;

procedure TTrain.CharacterToFollowUpdateCarriageParent;
var i, indexWagon: integer;
  p, p1: TPointF;
begin
  if (FCharacterToFollow = NIL) or not CharacterToFollowIsOnRoof then exit;
  if not CheckIfCharacterToFollowCanFall then exit;

  indexWagon := FCharacterToFollow.ParentSurface.Tag1;

  p := FCharacterToFollow.SurfaceToScene(PointF(0,0));
  if indexWagon = 0 then begin
    // loco to first wagon
    p1 := Wagons[0].SceneToSurface(p);
    if InRange(p1.x, Wagons[0].FullWidth*0.015, Wagons[0].FullWidth*0.985) then
      FCharacterToFollow.SetChildOf(Wagons[0], 10);
  end else begin
    for i:=0 to PLAIN_MOON_WAGON_COUNT-1 do begin
      // first wagon to loco
      p1 := Loco.SceneToSurface(p);
      if (i = 0) and InRange(p1.x, Loco.FullWidth*0.015, Loco.FullWidth*0.65) then begin
        FCharacterToFollow.SetChildOf(Loco, 10);
        exit;
      end;
      // wagon to previous wagon
      if i > 0 then begin
        p1 := Wagons[i-1].SceneToSurface(p);
        if InRange(p1.x, Wagons[i-1].FullWidth*0.015, Wagons[i-1].FullWidth*0.985) then begin
          FCharacterToFollow.SetChildOf(Wagons[i-1], 10);
          exit;
        end;
      end;
      // wagon to next wagon
      if i < PLAIN_MOON_WAGON_COUNT-1 then begin
        p1 := Wagons[i+1].SceneToSurface(p);
        if InRange(p1.x, Wagons[i+1].FullWidth*0.015, Wagons[i+1].FullWidth*0.985) then begin
          FCharacterToFollow.SetChildOf(Wagons[i+1], 10);
          exit;
        end;
      end;
    end;
  end;
end;

function TTrain.CharacterToFollowIsOnWagonCenter: boolean;
var indexWagon: integer;
begin
  if (FCharacterToFollow = NIL) or not CharacterToFollowIsOnRoof then exit(False);

  indexWagon := FCharacterToFollow.ParentSurface.Tag1;
  if indexWagon = 0 then exit(False);
  Result := InRange(FCharacterToFollow.X.Value,
                    Wagons[indexWagon-1].FullWidth*0.45,
                    Wagons[indexWagon-1].FullWidth*0.55);
end;

procedure TTrain.AvoidCharacterToFollowToJumpOnAnotherWagon;
var indexWagon: integer;
begin
  if FCharacterToFollow = NIL then exit;

  indexWagon := FCharacterToFollow.ParentSurface.Tag1;
  if indexWagon = 0 then exit;
 { FCharacterToFollow.X.Value := EnsureRange(FCharacterToFollow.X.Value,
                                            Wagons[indexWagon-1].FullWidth*0.05,
                                            Wagons[indexWagon-1].FullWidth*0.95); }
  if FCharacterToFollow.X.Value < Wagons[indexWagon-1].FullWidth*0.05 then
    FCharacterToFollow.X.Value := Wagons[indexWagon-1].FullWidth*0.05;
  if FCharacterToFollow.X.Value > Wagons[indexWagon-1].FullWidth*0.95 then
    FCharacterToFollow.X.Value := Wagons[indexWagon-1].FullWidth*0.95
end;

procedure TTrain.AvoidCharacterToFollowToJumpOnNextWagon;
var indexWagon: integer;
begin
  if FCharacterToFollow = NIL then exit;

  indexWagon := FCharacterToFollow.ParentSurface.Tag1;
  if indexWagon = 0 then exit;
  if FCharacterToFollow.X.Value < Wagons[indexWagon-1].FullWidth*0.05 then
    FCharacterToFollow.X.Value := Wagons[indexWagon-1].FullWidth*0.05;
end;

procedure TTrain.KillRobots;
var i, j: integer;
begin
  for i:=0 to PLAIN_MOON_WAGON_COUNT-1 do
    for j:=0 to Wagons[i].ChildCount-1 do begin
      if Wagons[i].Childs[j] is TRobotOnWagon or
         Wagons[i].Childs[j] is TBigRobot then
        Wagons[i].Childs[j].Kill;
    end;
end;

procedure TTrain.ShowDirectionnalArrowOnWagonCenter(aWagonIndex: integer);
begin
  FDirectionnalArrow.Direction := d4Down;
  FDirectionnalArrow.SetChildOf(Wagons[aWagonIndex], -5);
  FDirectionnalArrow.CenterX := Wagons[aWagonIndex].FullWidth*0.5;
  FDirectionnalArrow.CenterY := -ScaleH(77);
  FDirectionnalArrow.Show;
  FDirectionnalArrow.Freeze := False;
end;

procedure TTrain.ShowDirectionnalArrowOnLeftLadder(aWagonIndex: integer);
begin
  FDirectionnalArrow.Direction := d4Down;
  FDirectionnalArrow.SetChildOf(Wagons[aWagonIndex], -5);
  FDirectionnalArrow.CenterX := Wagons[aWagonIndex].FullWidth*0.133;
  FDirectionnalArrow.CenterY := -ScaleH(77);
  FDirectionnalArrow.Show;
  FDirectionnalArrow.Freeze := False;
end;

procedure TTrain.ShowDirectionnalArrowOnWagonRight(aWagonIndex: integer);
begin
  FDirectionnalArrow.Direction := d4Right;
  FDirectionnalArrow.SetChildOf(Wagons[aWagonIndex], -5);
  FDirectionnalArrow.CenterX := Wagons[aWagonIndex].FullWidth*0.9;
  FDirectionnalArrow.CenterY := -ScaleH(77);
  FDirectionnalArrow.Show;
  FDirectionnalArrow.Freeze := False;
end;

procedure TTrain.HideDirectionnalArrow;
begin
  FDirectionnalArrow.Hide;
  FDirectionnalArrow.Freeze := True;
end;

function TTrain.CheckIfCharacterToFollowCanOpenTheDoor(out aWagonPart: TWagonHead): boolean;
var indexWagon: integer;
  wag: TWagon;
  door: TAutomaticDoor;
begin
  Result := False;
  aWagonPart := NIL;
  if FCharacterToFollow = NIL then exit;

  indexWagon := FCharacterToFollow.ParentSurface.Tag1;
  if indexWagon = 0 then exit;
  wag := Wagons[indexWagon-1];
  door := NIL;
  aWagonPart := NIL;
  if CharacterToFollowIsOnTailPlatform then begin
    door := wag.FTail.Door;
    aWagonPart := wag.FTail;
    Result := InRange(FCharacterToFollow.X.Value, door.X.Value+door.Width*0.3, door.X.Value+door.Width*0.7);
  end; { else
  if CharacterToFollowIsOnHeadPlatform then begin
    door := wag.FHead.Door;
    aWagonPart := wag.FHead;
    Result := InRange(FCharacterToFollow.X.Value,
                      aWagonPart.X.Value+door.X.Value+door.Width*0.3,
                      aWagonPart.X.Value+door.X.Value+door.Width*0.7);
  end;}
end;

procedure TTrain.CenterOnCharacter(aCharacter: TWalkingCharacter; aTime: single);
var delta: single;
  i: integer;
begin
  FCharacterToFollow := NIL;

  i := aCharacter.ParentSurface.Tag1;
  if i = 0 then delta := 0
    else delta := i * (texWagonHook^.FrameWidth + Wagons[0].FullWidth);
  Loco.X.ChangeTo(FScene.Width*2 - aCharacter.X.Value + delta, aTime, idcSinusoid);
end;

{ TWagonTail }

constructor TWagonTail.Create(aNumber: integer);
begin
  inherited Create(aNumber);
  FlipH := True;

  Door.X.Value := ScaleW(87);
  DoorLight.CenterX := Door.CenterX;
  if Number <> NIL then Number.SetCenterCoordinate(ScaleW(41), ScaleH(76));
  Railing.SetCoordinate(ScaleW(74), ScaleH(166));
  Ladder.SetCoordinate(ScaleW(224), ScaleH(4));
  RoofAddon.SetCoordinate(Width-RoofAddon.Width-ScaleW(49), -RoofAddon.Height);
  Axle.SetCoordinate(ScaleW(43), ScaleH(238));
  Axle.FlipH := True;
  Wheel1.SetCoordinate(ScaleW(253), ScaleH(9));
  Wheel2.SetCoordinate(ScaleW(36), ScaleH(9));
end;

{ TWagonHead }

constructor TWagonHead.Create(aNumber: integer);
begin
  inherited Create(texWagonHead, False);
  ApplyNightEffectOn(Self);

  Door := TAutomaticDoor.Create(ScaleW(186), ScaleH(77), -1);
  AddChild(Door, 0);
  ApplyNightEffectOn(Door);

  DoorBG := TSprite.Create(texDoorBG, False);
  Door.AddChild(DoorBG, -5);
  DoorBG.CenterX := Door.Width*0.5;
  DoorBG.BottomY := Door.Height;

  DoorLight := TOGLCGlow.Create(FScene);
  AddChild(DoorLight, 1);
  DoorLight.SetRadius(ScaleW(25), ScaleW(10));
  SetDoorLightRed;
  DoorLight.CenterX := Door.CenterX;
  DoorLight.Y.Value := ScaleH(60);


  case aNumber of
    1: Number := TSprite.Create(texOne, False);
    2: Number := TSprite.Create(texTwo, False);
    3: Number := TSprite.Create(texThree, False);
    4: Number := TSprite.Create(texFour, False);
    else Number := NIL;
  end;
  if Number <> NIL then begin
    AddChild(Number, 1);
    Number.SetCenterCoordinate(ScaleW(353), ScaleH(76));
    Number.Opacity.Value := 160;
  end;

  Railing := TSprite.Create(texWagonRailing, False);
  AddChild(Railing, 0);
  Railing.SetCoordinate(ScaleW(89), ScaleH(166));
  ApplyNightEffectOn(Railing);

  Ladder := TSprite.Create(texWagonLadder, False);
  AddChild(Ladder, 0);
  Ladder.SetCoordinate(ScaleW(106), ScaleH(4));
  ApplyNightEffectOn(Ladder);

  RoofAddon := TTiledSprite.Create(texWagonRoofAddon, False);
  AddChild(RoofAddon, 0);
  RoofAddon.SetCoordinate(ScaleW(49), -RoofAddon.Height);
  ApplyNightEffectOn(RoofAddon);

  Axle := TSprite.Create(texAxle, False);
  AddChild(Axle, 0);
  Axle.SetCoordinate(ScaleW(22), ScaleH(238));
  ApplyNightEffectOn(Axle);

  Wheel1 := TSprite.Create(texWheel, False);
  Axle.AddChild(Wheel1, -1);
  Wheel1.SetCoordinate(ScaleW(220), ScaleH(9));
  Wheel1.Angle.Value := Random*360;
  ApplyNightEffectOn(Wheel1);

  Wheel2 := TSprite.Create(texWheel, False);
  Axle.AddChild(Wheel2, -1);
  Wheel2.SetCoordinate(ScaleW(4), ScaleH(9));
  Wheel2.Angle.Value := Random*360;
  ApplyNightEffectOn(Wheel2);
end;

procedure TWagonHead.SetWheelAngle(a: single);
begin
  Wheel1.Angle.AddConstant(a);
  Wheel2.Angle.AddConstant(a);
end;

procedure TWagonHead.SetDoorLightRed;
begin
  DoorLight.SetAllColorsTo(BGRA(255,50,50));
end;

procedure TWagonHead.SetDoorLightGreen;
begin
  DoorLight.SetAllColorsTo(BGRA(50,255,50));
end;

{ TWagon }

constructor TWagon.Create(aYTop: single; aNumberLabel: integer;
  aLayerIndex: integer);
var o: TTiledSprite;
  xx: single;
  i, glowIndex: Integer;
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  Y.Value := aYTop;

  FTail := TWagonTail.Create(aNumberLabel);
  AddChild(FTail);
  xx := FTail.Width - TRAIN_PART_OVERLAPPING;

  glowIndex := 0;
  for i:=0 to 4 do begin
    o := TTiledSprite.Create(texWagonMiddle, False);
    o.SetCoordinate(xx, 0);
    AddChild(o);
    ApplyNightEffectOn(o);
    if i in [0, 2, 4] then begin
      Glows[glowIndex] := TOGLCGlow.Create(FScene);
      Glows[glowIndex].SetAllColorsTo(BGRA(0,255,255));
      Glows[glowIndex].SetSize(Round(o.Width*0.3), Round(o.Width*0.2));
      Glows[glowIndex].SetCenterCoordinate(o.Width*0.5, o.Height*0.8);
      Glows[glowIndex].Power.Value := 0.930;
      o.AddChild(Glows[glowIndex]);
      Glows[glowIndex].SetChildOf(Self, 1);
      inc(glowIndex);
    end;
    xx := xx + o.Width - TRAIN_PART_OVERLAPPING;
  end;

  FHead := TWagonHead.Create(aNumberLabel);
  AddChild(FHead);
  FHead.SetCoordinate(xx, 0);

  FullWidth := Round(FHead.RightX);

  // head hook
  o := TTiledSprite.Create(texWagonHook, False);
  o.SetCoordinate(FullWidth, ScaleH(176));
  AddChild(o, -1);
  ApplyNightEffectOn(o);
end;

procedure TWagon.SetWheelAngle(a: single);
begin
  FHead.SetWheelAngle(a);
  FTail.SetWheelAngle(a);
end;

{ TLocomotive }

constructor TLocomotive.Create(aXLeft, aYTop: single; aLayerIndex: integer);
var o: TTiledSprite;
  xx: single;
  i: Integer;
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  SetCoordinate(aXLeft, aYTop);

  FTail := TWagonTail.Create(-1);
  AddChild(FTail);
  xx := FTail.Width - TRAIN_PART_OVERLAPPING;

  for i:=0 to 4 do begin
    o := TTiledSprite.Create(texLocoMiddle, False);
    o.SetCoordinate(xx, 0);
    AddChild(o);
    ApplyNightEffectOn(o);
    xx := xx + o.Width - TRAIN_PART_OVERLAPPING;
  end;

  o := TTiledSprite.Create(texLocoHead, False);
  AddChild(o);
  o.SetCoordinate(xx, 0);
  ApplyNightEffectOn(o);

  Light1 := TOGLCSpotLight.Create(FScene);
  Light1.SetSize(Round(FScene.Width*1.5), ScaleH(50));
  Light1.SetAllColorsTo(BGRA(255,255,50));
  o.AddChild(Light1, 1);
  Light1.X.Value := ScaleW(553);
  Light1.CenterY := ScaleH(223);
  Light1.Opacity.Value := 150;

  Light2 := TOGLCSpotLight.Create(FScene);
  Light2.SetSize(FScene.Width, ScaleH(40));
  Light2.SetAllColorsTo(BGRA(255,255,50));
  o.AddChild(Light2, 1);
  Light2.X.Value := ScaleW(195);
  Light2.CenterY := ScaleH(18);
  Light2.Opacity.Value := 150;

  FullWidth := Round(o.RightX);

  Axle := TSprite.Create(texAxle, False);
  o.AddChild(Axle, 0);
  Axle.SetCoordinate(ScaleW(5), ScaleH(238));
  ApplyNightEffectOn(Axle);

  Wheel1 := TSprite.Create(texWheel, False);
  Axle.AddChild(Wheel1, -1);
  Wheel1.SetCoordinate(ScaleW(220), ScaleH(9));
  Wheel1.Angle.Value := Random*360;
  ApplyNightEffectOn(Wheel1);

  Wheel2 := TSprite.Create(texWheel, False);
  Axle.AddChild(Wheel2, -1);
  Wheel2.SetCoordinate(ScaleW(4), ScaleH(9));
  Wheel2.Angle.Value := Random*360;
  ApplyNightEffectOn(Wheel2);
end;

procedure TLocomotive.SetWheelAngle(a: single);
begin
  Wheel1.Angle.AddConstant(a);
  Wheel2.Angle.AddConstant(a);
  FTail.SetWheelAngle(a);
end;

{ TGameInventory }

procedure TGameInventory.AddClock;
begin
  if FClock = NIL then begin
    FClock := TUIClock.Create;
    AddItem(FClock);
  end;
end;

procedure TGameInventory.AddLaserGun;
begin
  if FLaserGun = NIL then begin
    FLaserGun := TUILaserGun.Create;
    AddItem(FLaserGun);
  end;
end;

{ TScreenPlainOfSleepingMoon }

procedure TScreenPlainOfSleepingMoon.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;

  case FGameState of
    gsLRFallBetweenWagon: PostMessage(200);
    gsLRIsEjectedByRobot: PostMessage(250);
    gsTimeElapsed: PostMessage(260);
    gsAllWagonAreDone: PostMessage(500);
  end;
end;

procedure TScreenPlainOfSleepingMoon.ResetVariables;
begin
  FPlainGame.Activated := False;
  FPlainIntroductionCinematic.Activated := False;
  FTrain.InitDefault;
  FForceSpeedUpdate := True;
  FAction2Released := True;
  FEndOfShootingStars := False;
  FSpriteMessageTimeOver := NIL;
end;

procedure TScreenPlainOfSleepingMoon.SetGameSequence(AValue: TGameSequence);
begin
  if FGameSequence = AValue then Exit;
  FGameSequence := AValue;
  // update the directionnal arrow
  case FGameSequence of
    gsWaitPlayerIsOnWagonCenter: begin
      FTrain.ShowDirectionnalArrowOnWagonCenter(FLR.ParentSurface.Tag1-1);
    end;
    gsDestroyRobotOnTheRoof: begin
      FTrain.HideDirectionnalArrow;
    end;
    gsWaitPlayerEnterWagon: begin
      FTrain.ShowDirectionnalArrowOnLeftLadder(FLR.ParentSurface.Tag1-1);
    end;
    gsWaitPlayerJumpOnPreviousWagon: begin
      FTrain.ShowDirectionnalArrowOnWagonRight(FLR.ParentSurface.Tag1-1);
      FPreviousWagonIndex := FLR.ParentSurface.Tag1-1;
    end;
  end;
end;

procedure TScreenPlainOfSleepingMoon.UpdateParallaxScrollingSpeed;
var scrollingSpeed, v: Single;
begin
  scrollingSpeed := FScrollingSpeed.Value;
  v := -FScene.Width*4.0 * scrollingSpeed;
  FGround.Speed := v;
  FTrain.SetWheelSpeed(Min(TRAIN_WHEEL_MAX_SPEED_ROTATION, -v));
  FOakForest.Speed := v;
  FFactoryParallax.Factory1Speed := -FScene.Width*1.3 * scrollingSpeed;
  FFactoryParallax.Factory2Speed := -FScene.Width*1.0 * scrollingSpeed;    //1.2
  FFactoryParallax.Factory3Speed := -FScene.Width*0.7 * scrollingSpeed;    //1.0

  FMountainParallax.Mountain1Speed := -FScene.Width*0.3 * scrollingSpeed;
  FMountainParallax.Mountain2Speed := -FScene.Width*0.08 * scrollingSpeed;
  FMountainParallax.CloudSpeed := -FScene.Width*0.03 * scrollingSpeed;
end;

procedure TScreenPlainOfSleepingMoon.PlayLaserShootSound;
begin
  Audio.PlayThenKillSound('laser-gunshot.ogg', 0.8, 0.0, 1.0+Random*0.1-0.05, Audio.FXReverbShort, 0.5);
end;

procedure TScreenPlainOfSleepingMoon.CreateObjects;
var path: string;
  ima: TBGRABitmap;
begin
  FGameState := gsUndefined;
  ResetVariables;

  //Audio.PauseMusicTitleMap(3.0);
  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  AdditionnalScale := 0.8;
  LoadLR4DirTextures(FAtlas, False);
  texLaserGun := FAtlas.AddFromSVG(SpriteLR4DirRightFolder+'rLaserGun.svg', ScaleW(40), -1);
  texLaserShoot := FAtlas.AddFromSVG(SpriteLR4DirRightFolder+'rLaserShoot.svg', ScaleW(20), -1);
  LoadWolfTextures(FAtlas);
  LoadPenelopeTextures(FAtlas);
  AdditionnalScale := 1.0;

  AdditionnalScale := 1.1;
  TLittleRobot.LoadTexture(FAtlas);
  texRobotMace := FAtlas.AddFromSVG(GetFolderSpritePlainOfSleepingMoon+'RobotMace.svg', ScaleW(47), -1);
  AdditionnalScale := 1.0;

  path := SpriteGameVolcanoDinoFolder;
  texGroundDeep := FAtlas.AddFromSVG(path+'GroundDeep.svg', ScaleW(128), -1);
  texGroundSlope := FAtlas.AddFromSVG(path+'GroundSlope.svg', ScaleW(128), -1);
  texGroundFlat := FAtlas.AddFromSVG(path+'GroundFlat.svg', ScaleW(128), -1);
  texGroundCorner := FAtlas.AddFromSVG(path+'GroundCorner.svg', ScaleW(64), -1);

  path := SpriteCommonFolder;
  texGround1 := FAtlas.AddFromSVG(path+'Ground1.svg', ScaleW(178), -1);
  texGround1Right := FAtlas.AddFromSVG(path+'Ground1Right.svg', -1, ScaleH(48));

  path := GetFolderSpritePlainOfSleepingMoon;
  texMountain1 := FAtlas.AddFromSVG(path+'Mountain1.svg', ScaleW(1192), -1);
  texMountain2 := FAtlas.AddFromSVG(path+'Mountain2.svg', ScaleW(728), -1);
  texOakForest := FAtlas.AddFromSVG(path+'OakForest.svg', ScaleW(270), -1);
  texRock1 := FAtlas.AddFromSVG(path+'Rock1.svg', ScaleW(194), -1);
  //texCloud  := FAtlas.AddFromSVG(path+'Cloud.svg', ScaleW(199), -1);
  texRail := FAtlas.AddFromSVG(path+'Rail.svg', ScaleW(133), -1);
  texFactory1 := FAtlas.AddFromSVG(path+'Factory1.svg', ScaleW(555), -1);
  texFactory2 := FAtlas.AddFromSVG(path+'Factory2.svg', ScaleW(408), -1);
  texFactory3 := FAtlas.AddFromSVG(path+'Factory3.svg', ScaleW(270), -1);

  texShootingStar := FAtlas.AddFromSVG(path+'ShootingStar.svg', ScaleW(135), -1);

  texWagonRailing := FAtlas.AddFromSVG(path+'WagonRailing.svg', ScaleW(232), -1);
  texWagonLadder := FAtlas.AddFromSVG(path+'WagonLadder.svg', -1, ScaleH(217));
  texWagonHead := FAtlas.AddFromSVG(path+'WagonHead.svg', ScaleW(394), -1);
  texWagonRoofAddon := FAtlas.AddFromSVG(path+'WagonRoofAddon.svg', ScaleW(103), -1);
  texWagonHook := FAtlas.AddFromSVG(path+'WagonHook.svg', ScaleW(75), -1);
  TAutomaticDoor.LoadTexture(FAtlas, ScaleW(120), ScaleH(145));
  texDoorBG := FAtlas.AddFromSVG(path+'DoorBG.svg', ScaleW(111), -1);
  texWagonMiddle := FAtlas.AddFromSVG(path+'WagonMiddle.svg', ScaleW(227), -1);
  texLocoHead := FAtlas.AddFromSVG(path+'LocoHead.svg', ScaleW(562), -1);
  texLocoMiddle := FAtlas.AddFromSVG(path+'LocoMiddle.svg', ScaleW(90), -1);
  texWheel := FAtlas.AddFromSVG(path+'Wheel.svg', ScaleW(71), -1);
  texAxle := FAtlas.AddFromSVG(path+'Axle.svg', ScaleW(328), -1);
  texOne := FAtlas.AddFromSVG(path+'One.svg', ScaleW(29), -1);
  texTwo := FAtlas.AddFromSVG(path+'Two.svg', ScaleW(47), -1);
  texThree := FAtlas.AddFromSVG(path+'Three.svg', ScaleW(43), -1);
  texFour := FAtlas.AddFromSVG(path+'Four.svg', ScaleW(46), -1);

  // ui
  CreateGameFontNumber(FAtlas); // < must be first !
  LoadWatchTexture(FAtlas);
  LoadLaserGunTexture(FAtlas);
  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);
  LoadGameDialogTextures(FAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(FAtlas);
  texArrowYellow := FAtlas.AddFromSVG(SpriteUIFolder+'ArrowYellow.svg', ScaleW(40), -1);
  LoadMousePointerTexture(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;

  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  // pause panel
  FInGamePausePanel := TInGamePausePanel.Create(FFontText, FAtlas);
  //FInGamePausePanel.SetCheatCodeList([VolcanoInnerCheatCode]);
  //FInGamePausePanel.OnPlayerEnterCheatCode := @ProcessPlayerEnterCheatCode;

  // select which part to play
  if not PlayerInfo.PlainMoon.IntroAlreadySeen then
    FPlainIntroductionCinematic.Create
  else begin
    FPlainGame.Create;
    FLaserGun.Visible := PlayerInfo.PlainMoon.LaserGun.Owned;
    if PlayerInfo.PlainMoon.CurrentWagonJustDone then begin
      PlayerInfo.PlainMoon.CurrentWagonJustDone := False;
      PostMessage(400);
    end else PostMessage(0);
  end;

  CustomizeMousePointer;
end;

procedure TScreenPlainOfSleepingMoon.FreeObjects;
begin
  FreeMousePointer;
  if FInGamePausePanel.PlayerHaveClickedBackToMapButton or
     (FScene.RequestedScreen = ScreenMap) then begin
    FadeOutAndKillMusicAndSounds;
    Audio.ResumeMusicTitleMap;
  end;
  FTrain.DeleteSound;

  FPlainGame.FreeRenderer;
  FPlainIntroductionCinematic.FreeRenderer;

  FScrollingSpeed.Free;
  FScrollingSpeed := NIL;

  if FCamera <> NIL then begin
    FCamera.Unassign;
    FScene.KillCamera(FCamera);
    FCamera := NIL;
  end;

  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
end;

procedure TScreenPlainOfSleepingMoon.ProcessMessage(UserValue: TUserMessageValue);
var xx: Single;
  r: TRectF;
begin
  if FPlainIntroductionCinematic.Activated then begin
    FPlainIntroductionCinematic.ProcessMessage(UserValue);
    exit;
  end;

  case UserValue of
    0: begin  // choose which part to start with
      case PlayerInfo.PlainMoon.StepPlayed of
        1: PostMessage(2);   // Penelope encounter
        2: PostMessage(100)  // start the game directly
        else raise exception.create('??? value is '+PlayerInfo.PlainMoon.CurrentStep.ToString);
      end;
    end;
    // ANIMATION PENELOPE RUN ALONG THE TRAIN TO ENCOUNTER LR
    2: begin // sets the camera to center and train appears from the left
      FCamera.Scale.Value := PointF(1.0, 1.0);
      FCamera.MoveTo(PointF(FScene.Width*2, FScene.Height*0.5));
      FLR.SetFaceType(lrfWorry);
      FLaserGun.Visible := False;
      FTrain.Loco.X.Value := -FTrain.Loco.FullWidth*0.5;
      FTrain.Loco.X.ChangeTo(FScene.Width*2-FPenelope.X.Value, 10, idcSinusoid);
      PostMessage(3, 3);
    end;
    3: begin   //train horn
      with Audio.AddSound('train-horn.ogg') do begin
        Volume.Value := 0.4;
        Volume.ChangeTo(0.8, 2.0);
        Pan.Value := -0.7;
        Pan.ChangeTo(0.0, 2.0);
        PlayThenKill(True);
      end;
      //Audio.PlayThenKillSound('train-horn.ogg', 0.8, -0.5, 1.0, Audio.FXReverbLong, 0.6);
      PostMessage(4, 8);
    end;
    4: begin
      Audio.PlayThenKillSound('radio-static.ogg', 0.8);
      r := GetViewRect(FCamera);
      with TInfoPanel.Create(sDriverVoice, sWeHaveReachedFullSpeed, FFontText, Self, 5) do
        SetCoordinate(r.Right-Width, r.Height*0.45);
    end;
    5: begin
      FPenelope.LeftArm.Angle.ChangeTo(262, 0.5, idcSinusoid);
      PostMessage(6, 0.85);
    end;
    6: begin
      Audio.PlayThenKillSound('radio-static.ogg', 0.8);
      FPenelope.ShowDialog(sAllRightWeWillBeOnTime, FFontText, Self, 7, 0.0, FCamera);
    end;
    7: begin
      FPenelope.LeftArm.Angle.ChangeTo(46, 0.6, idcSinusoid);
      PostMessage(11, 3.0);
    end;
    11: begin   // penelope look at left
      FPenelope.IdleLeft;
      FPenelope.SetWalkMode;
      PostMessage(12, 0.5);
    end;
    12: begin
      FTrain.SetCharacterToFollow(FPenelope);
      FPenelope.ShowQuestionMark;
      PostMessage(13, 0.75);
    end;
    13: begin
      FPenelope.HideMark;
      FPenelope.ShowDialog(sThereSomeoneOnMyTrain, FFontText, Self, 14, 0, FCamera);
      FWagonsIndex := 0;
    end;
    14: begin // train moves to keep Penelope visible, camera zoom out, penelope run
      FTrain.SetQuickMoves;
      FTrain.SetCharacterToFollow(FPenelope);
      FCamera.Scale.ChangeTo(PointF(0.5,0.5), 1.5, idcSinusoid);
      FPenelope.SetRunMode;
      FPenelope.WalkHorizontallyTo(FTrain.Loco.FullWidth*0.03, Self, 15);
    end;
    15: begin
      FPenelope.Jump;
      PostMessage(17);
      if FWagonsIndex = 1 then PostMessage(16, 0.05);
    end;
    16: begin  // Penelope make a salto
      FPenelope.Angle.Value := 0;
      FPenelope.Angle.ChangeTo(-360, 0.3);
    end;
    17: if FPenelope.IsJumping then PostMessage(17) else PostMessage(18); // wait the end of penelope jump
    18: begin
      xx := FPenelope.X.Value;
      FPenelope.SetChildOf(FTrain.Wagons[FWagonsIndex], 10);
      FPenelope.X.Value :=  FTrain.Wagons[FWagonsIndex].FullWidth+texWagonHook^.FrameWidth+xx;
      FPenelope.WalkHorizontallyTo(FTrain.Wagons[FWagonsIndex].FullWidth*0.03, Self, 19);
    end;
    19: begin
      inc(FWagonsIndex);
      if FWagonsIndex = PLAIN_MOON_WAGON_COUNT-1 then PostMessage(20)
        else PostMessage(15);   // 9
    end;
    20: begin
       FPenelope.Jump;
       PostMessage(21);
       PostMessage(16, 0.05);  // salto
    end;
    21: if FPenelope.IsJumping then PostMessage(21) else PostMessage(22); // wait the end of penelope jump
    22: begin
      xx := FPenelope.X.Value;
      FPenelope.SetChildOf(FTrain.Wagons[FWagonsIndex], 10);
      FPenelope.X.Value :=  FTrain.Wagons[FWagonsIndex].FullWidth+texWagonHook^.FrameWidth+xx;
      FPenelope.WalkHorizontallyTo(FTrain.Wagons[FWagonsIndex].FullWidth*0.2, Self, 23);
    end;
    23: begin
      FPenelope.IdleLeft;
      FPenelope.Head.HideAllMouth;
      FCamera.Scale.ChangeTo(PointF(1.0,1.0), 2.0, idcSinusoid);
      PostMessage(25, 2.0);
    end;
    25: begin
      FPenelope.LeftArm.Angle.Value := 161;
      FPenelope.ShowDialog(sYouWhatAreYouDoingOnMyTrain, FFontText, Self, 26, 0, FCamera);
    end;
    26: FLR.ShowDialog(sIveComeForMyGrandMother, FFontText, Self, 27, 0, FCamera);
    27: begin
      FPenelope.Idle;
      FPenelope.ShowDialog(sRelaxIDontEvenKnown, FFontText, Self, 28, 0, FCamera);
    end;
    28: FLR.ShowDialog(sYouLying, FFontText, Self, 29, 0, FCamera);
    29: FPenelope.ShowDialog(sOkOkYouLookSmart, FFontText, Self, 30, 0, FCamera);
    30: FPenelope.ShowDialog(sTakeThis, FFontText, Self, 31, 0, FCamera);
    31: begin
      FPenelope.SetWalkMode;
      FPenelope.WalkHorizontallyTo(FLR.X.Value+FLR.BodyWidth*2, Self, 32);
    end;
    32: begin
      FPenelope.IdleLeft;
      PostMessage(33, 0.3);
    end;
    33: begin
      FPenelope.Abdomen.Angle.ChangeTo(-15, 0.75, idcSinusoid);
      FPenelope.RightArm.Angle.ChangeTo(0, 0.75, idcSinusoid);
      FPenelope.LeftArm.Angle.ChangeTo(137, 0.75, idcSinusoid);
      PostMessage(34, 0.5);
    end;
    34: begin
      FLR.State := lr4sReceiveObjectFromNPC;
      PostMessage(35, 0.75);
    end;
    35: begin
      TLaserGunThatGoInInventory.Create(36);
      Audio.PlayMusicSuccessShort1;
      PlayerInfo.PlainMoon.LaserGun.IncLevel;
      FSaveGame.Save;
      PostMessage(37, 1.5);
    end;
    36: FGameInventory.AddLaserGun; // called when the laser gun is over the inventory panel
    37: begin
      FLR.IdleRight;
      FPenelope.Idle;
      PostMessage(38, 0.75);
    end;
    38: FPenelope.WalkHorizontallyTo(FTrain.Wagons[FWagonsIndex].FullWidth*0.2, Self, 42);
    42: begin
      FPenelope.IdleLeft;
      PostMessage(43, 0.5);
    end;

    43: FPenelope.ShowDialog(sItsALaserGun, FFontText, Self, 44, 0, FCamera);
    44: FLR.ShowDialog(sWhy, FFontText, Self, 45, 0, FCamera);
    45: FPenelope.ShowDialog(sShhIfYouManage, FFontText, Self, 46, 0, FCamera);
    46: FPenelope.ShowDialog(sYouWontBeAbleChangeCarriages, FFontText, Self, 47, 0, FCamera);
    47: FLR.ShowDialog(sButWhatAboutYourRobots, FFontText, Self, 48, 0, FCamera);
    48: FPenelope.ShowDialog(sOhDontWorryICanHave, FFontText, Self, 49, 0, FCamera);
    49: FPenelope.ShowDialog(sSoAreYouIn, FFontText, Self, 50, 0, FCamera);
    50: FLR.ShowDialog(sIHaveNoChoice, FFontText, Self, 51, 0, FCamera);
    51: FPenelope.ShowDialog(sIAlwaysKeepMyWord, FFontText, Self, 52, 0, FCamera);
    52: FPenelope.ShowDialog(sComeOnItsTime, FFontText, Self, 53, 0, FCamera);
    53: FPenelope.ShowDialog(Format(sYouveGotExactly, [PLAIN_MOON_GAME_TIME, PLAIN_MOON_WAGON_COUNT]),
                             FFontText, Self, 55, 0, FCamera);
    55: begin
      FTrain.CenterOnCharacter(FLR);
      FCamera.Scale.Value := PointF(0.5,0.5);
      PostMessage(56, 0.5);
    end;
    56: begin
      FPenelope.IdleRight;
      FPenelope.SetRunMode;
      FPenelope.WalkHorizontallyTo(FTrain.LastWagon.FullWidth*0.95, Self, 57);
    end;
    57: begin  // replace Penelope on the locomotive, and set the train to follow LR smoothly
      FPenelope.SetChildOf(FTrain.Loco, 10);
      FPenelope.X.Value := FTrain.Loco.FullWidth*0.6;
      FPenelope.IdleRight;
      FTrain.SetSmoothMoves;
      FTrain.SetCharacterToFollow(FLR);
      PostMessage(59, 1.0);
      // Penelope encounter is done
      if PlayerInfo.PlainMoon.CurrentStep = 1 then begin
        PlayerInfo.PlainMoon.IncCurrentStep;
        PlayerInfo.PlainMoon.StepPlayed := PlayerInfo.PlainMoon.CurrentStep;
        FSaveGame.Save;
      end;
    end;
    59: begin  // add the clock to the inventory panel and show the game instructions
      FGameinventory.AddClock;
      FGameinventory.Clock.Second := PLAIN_MOON_GAME_TIME;
      FLaserGun.Visible := True;
      sndMusic.Play(True);
      PostMessage(61);
      ShowGameInstructions(SPlainMoonHelpText);
    end;
    61: begin // start clock and game
      FGameinventory.Clock.StartTime;
      GameState := gsLRPlayOutside;
      GameSequence := gsWaitPlayerIsOnWagonCenter;
      FWagonsIndex := PLAIN_MOON_WAGON_COUNT-1;
    end;

    // START THE GAME DIRECTLY
    100: begin
      sndMusic.Play(True);
      FScene.Layer[LAYER_WOLF].Clear; // remove all remains of robot
      FTrain.KillRobots;

      FCamera.Scale.Value := PointF(0.5,0.5);
      FGameinventory.AddLaserGun;
      FGameinventory.AddClock;
      FGameinventory.Clock.Second := PLAIN_MOON_GAME_TIME;
      FWagonsIndex := PLAIN_MOON_WAGON_COUNT-1;
      //FTrain.LastWagon.AddChild(FLR, 10);
      FLR.SetChildOf(FTrain.LastWagon, 10);
      FLR.Angle.Value := 0;
      FLR.Speed.Value := PointF(0, 0);
      FLR.X.Value := FTrain.LastWagon.FullWidth*0.1;
      FLR.BodyBottomY := YFeetOnTrain;
      FLR.IdleRight;
      FLR.Visible := True;
      FLR.Scale.Value := PointF(1,1);
      FTrain.CenterOnCharacter(FLR, 0.0);
      FTrain.SetSmoothMoves;
      FTrain.SetCharacterToFollow(FLR);
      FScrollingSpeed.Value := 1.0;
      FForceSpeedUpdate := True;
      PostMessage(101, 0.1);
    end;
    101: begin
      ShowGameInstructions(SPlainMoonHelpText);
      PostMessage(61);
    end;

    // LR FALL BETWEEN TWO WAGON
    200: begin
      FTrain.SetCharacterToFollow(NIL);
      FLR.Y.ChangeTo(texWagonHead^.FrameHeight-FLR.DeltaYToBottom, 0.5, idcDrop);
      if FLR.IsOrientedRight
        then FLR.X.ChangeTo(FLR.X.Value+texWagonHook^.FrameWidth*0.5, 0.5)
        else FLR.X.ChangeTo(FLR.X.Value-texWagonHook^.FrameWidth*0.5, 0.5);
      PostMessage(205, 0.5);
    end;
    205: begin
      FLR.SetZOrder(-100);   // LR is behind the train wheel
      FLR.Angle.Value := 90;
      FLR.Speed.x.Value := FGround.Speed;
      PostMessage(210, 1.5);
    end;
    210: begin  // show message 'Je crois que je me suis cassé un ongle...'
      with TInfoPanel.Create(FLR.DialogAuthorName, sIThinkIveBrokenANail, FFontText, Self, 215, 0, LAYER_GAMEUI) do begin
        X.Value := 0;
        BottomY := FScene.Height - PPIScale(10);
      end;
    end;
    215: DialogQuestion(sWouldYouLikeToTryAgain, sYes, sNo, FFontText, Self, 100, 216, FAtlas);
    216: FScene.RunScreen(ScreenMap);

    // ANIM LR IS EJECTED FROM THE TRAIN ROOF BY A ROBOT
    250: begin
      FTrain.SetCharacterToFollow(NIL);
      FLR.Y.ChangeTo(texWagonHead^.FrameHeight-FLR.DeltaYToBottom, 0.5, idcDrop);
      FLR.X.ChangeTo(FLR.X.Value-FScene.Width*0.1, 0.5);
      FLR.Angle.ChangeTo(65, 0.5);
      PostMessage(205, 0.5);
    end;

    // ANIM NO TIME REMAINS
    260: begin
      FLR.Speed.Value := PointF(0,0);
      FLR.IdleLeft;
      FLR.ShowExclamationMark;
      FLR.SetFaceType(lrfWorry);
      // create a big robot that comes from the left
      with TBigRobot.Create(FLR.ParentSurface.Tag1-1) do begin
        WalkSpeed := FScene.Width*0.8;
        WalkHorizontallyTo(FLR.X.Value-FLR.BodyWidth*2, Self, 270);
      end;
    end;
    270: begin
      FTrain.SetCharacterToFollow(NIL);
      FLR.HideMark;
      FLR.IdleDown;
      FLR.LRFront.SetWinPosture;
      FLR.SetFaceType(lrfBroken);
      FLR.Speed.Value := PointF(0,0);
      FLR.Angle.ChangeTo(-55, 1.0);
      FLR.Scale.ChangeTo(PointF(10,10), 1.0, idcSinusoid);
      //FLR.X.ChangeTo(FLR.X.Value-FScene.Width*0.1, 1.0);
      Audio.PlayThenKillSound('punch.ogg', 1.0, 0.0, 1.0, Audio.FXReverbShort, 0.7);
      FSpriteMessageTimeOver.KillDefered(2.5);
      FSpriteMessageTimeOver := NIL;
      PostMessage(272, 1.0);
    end;
    272: begin
      FLR.Visible := False;
      FLR.SetFaceType(lrfSmile);
      PostMessage(215, 1.5);
    end;

    // LR enter a wagon
    300: begin
      PlayerInfo.PlainMoon.CurrentWagonIndex := FLR.ParentSurface.Tag1-1;
      PlayerInfo.PlainMoon.CurrentWagonJustDone := False;
      FWagonPartEntered.Door.Open;
      PostMessage(302, 0.75);
    end;
    302: begin
      FTrain.SetCharacterToFollow(NIL);
      FLR.TimeMultiplicator := 1.0;
      FLR.WalkSpeed := FLR.WalkSpeed*0.5;
      FLR.WalkVerticallyTo(FLR.BottomY-2, Self, 305);
    end;
    305: begin
      FLR.Y.ChangeTo(FLR.Y.Value - PPIScale(10), 1.2);
      FLR.Scale.ChangeTo(PointF(0.7,0.7), 1.2);
      FLR.SetChildOf(FWagonPartEntered.Door, -2);
      PostMessage(307, 0.5);
    end;
    307: begin
      FLR.IdleRight;
      FLR.Scale.Value := FLR.Scale.Value;
      FLR.SetFaceType(lrfWorry);
      PostMessage(309,0.5);
    end;
    309: begin
      PlayerInfo.PlainMoon.RemainingSeconds := FGameInventory.Clock.Second;
      FWagonPartEntered.Door.Close;
      FWagonPartEntered.SetDoorLightRed;
      FScene.RunScreen(ScreenPlainMoonInside);
    end;

    // LR gets out of the wagon. we stops the music if this is the last wagon
    400: begin
      if PlayerInfo.PlainMoon.CurrentWagonIndex = 0 then begin
        if sndMusic <> NIL then sndMusic.FadeOutThenKill(2.0);
        sndMusic := NIL;
      end;
      FGameinventory.AddClock;
      FGameinventory.Clock.Second := PlayerInfo.PlainMoon.RemainingSeconds;
      FGameinventory.Clock.StartTime;
      FTrain.PlaceLRToGetsOutOfTheWagon(PlayerInfo.PlainMoon.CurrentWagonIndex, FWagonPartLeft);
      FTrain.CenterOnCharacter(FLR, 0);
      FCamera.Scale.Value := PointF(1,1);
      UpdateParallaxScrollingSpeed;
      PostMessage(405, 2.0);
    end;
    405: begin
      FLR.SetChildOf(FWagonPartLeft.Door, -2);
      FWagonPartLeft.SetDoorLightGreen;
      FLR.Scale.Value := PointF(0.78, 0.78);
      FLR.Y.Value := FLR.Y.Value - PPIScale(10);
      PostMessage(406, 1.0);
    end;
    406: begin
      FWagonPartLeft.Door.Open;
      PostMessage(408, 1.0);
    end;
    408: begin
      FLR.Scale.ChangeTo(PointF(1,1), 1.2);
      FLR.TimeMultiplicator := 1.0;
      FLR.Y.ChangeTo(FLR.Y.Value + PPIScale(10), 1.2);
      FLR.WalkVerticallyTo(FLR.BodyBottomY+2, Self, 410);
    end;
    410: begin   // lr becomes child of the wagon
      FLR.SetChildOf(FWagonPartLeft.ParentSurface, 10);
      FLR.Y.ChangeTo(YFeetOnPlatform-FLR.DeltaYToBottom, 0.75);
      PostMessage(412, 0.5);
    end;
    412: begin
      FWagonPartLeft.Door.Close;
      FWagonPartLeft.SetDoorLightRed;
      PostMessage(414, 0.5);
    end;
    414: begin
      FLR.IdleLeft;
      FLR.TimeMultiplicator := 0.4;
      FTrain.SetCharacterToFollow(FLR);
      GameState := gsLRPlayOutside;
      GameSequence := gsWaitPlayerJumpOnPreviousWagon;
    end;

    // ANIM END OF THE GAME
    500: begin
      FGameinventory.Clock.PauseTime;
      sndMusic := Audio.AddMusic('StarrySky.ogg', False);
      sndMusic.Volume.Value := 0.8;
      sndMusic.Play(True);
      FTrain.HideDirectionnalArrow;
      FLR.State := lr4sStartAnimWinner;
      FLR.Speed.x.Value := 0;
      FLR.TimeMultiplicator := 0.6;
      FLR.LRRight.RemoveObjectInRightHand(True); // remove the laser gun from LR hand
      FLR.WalkHorizontallyTo(FPenelope.X.Value-FPenelope.BodyWidth*2, Self, 502);
      FCamera.Scale.ChangeTo(PointF(1.0, 1.0), 3.0, idcSinusoid);
    end;
    502: begin
      FLR.IdleRight;
      PostMessage(503, 0.5);
    end;
    503: begin
      FLR.ShowDialog(sHeyIDidIt, FFontText, Self, 504, 0, FCamera);
    end;
    504: begin
      FPenelope.IdleLeft;
      FPenelope.ShowDialog(sIKnewYouCouldDoIt, FFontText, Self, 505, 0, FCamera);
    end;
    505: FPenelope.ShowDialog(sLetsLookAtTheLandscape, FFontText, Self, 507, 0, FCamera);
    507: begin
      FUpdateTrainEngineVolume := False;
      FTrain.sndEngine.Volume.ChangeTo(0, 7.0);
      sndTrainWheel.Volume.ChangeTo(0, 7.0);
      FGameinventory.Visible := False;
      FPenelope.IdleRight;
      sndMusic.Volume.ChangeTo(1.0, 2.0);
      FCamera.Scale.ChangeTo(PointF(0.5, 0.5), 6.0, idcSinusoid);
      PostMessage(510, 2.0);
    end;
    510: begin // wait the music point
      if sndMusic.TimePosition < 35.6 then PostMessage(510)
        else PostMessage(515);
    end;
    515: begin  // full zoom on starry sky
      FCamera.Scale.ChangeTo(PointF(0.25, 0.25), 3.0, idcSinusoid);
      PostMessage(517);
      PostMessage(590, 5.0);
    end;
    517: begin  // wait the end of music
      if sndMusic.TimePosition < 105 then PostMessage(517)
        else PostMessage(519);
    end;
    519: begin
      FEndOfShootingStars := True;
      FTrain.sndEngine.Volume.ChangeTo(0.4, 3.0);
      sndTrainWheel.Volume.ChangeTo(0.6, 2.0);
      FCamera.Scale.ChangeTo(PointF(1.0, 1.0), 6.0, idcSinusoid);
      PostMessage(525, 6.0);
    end;
    525: FLR.ShowDialog(sAreYouGoingToHelpMeNow, FFontText, Self,  526, 0, FCamera);
    526: begin
      FPenelope.IdleLeft;
      PostMessage(527, 0.5);
    end;
    527: FPenelope.ShowDialog(sYesAsIToldYouIAlways, FFontText, Self,  529, 0, FCamera);
    529: FPenelope.ShowDialog(sYourGrandmotherWasInvited, FFontText, Self,  531, 0, FCamera);
    531: begin
      FLR.SetFaceType(lrfWorry);
      FLR.ShowDialog(sInvitedYouTiedHer, FFontText, Self,  532, 0, FCamera);
    end;
    532: FPenelope.ShowDialog(sMyFatherWasInHurry, FFontText, Self,  534, 0, FCamera);
    534: FLR.ShowDialog(sWeirdWayOfInvitingPeople, FFontText, Self,  536, 0, FCamera);
    536: FPenelope.ShowDialog(sIDontKnowAboutThatIDont, FFontText, Self,  538, 0, FCamera);
    538: FPenelope.ShowDialog(sIfYouWantToJoinYour, FFontText, Self,  540, 0, FCamera);
    540: FPenelope.ShowDialog(sButHurryItsReallyUrgent, FFontText, Self,  542, 0, FCamera);
    542: FLR.ShowDialog(sWillTheyLeaveTheCastle, FFontText, Self,  544, 0, FCamera);
    544: FPenelope.ShowDialog(sYesThatsWhatIVaguelyHeard, FFontText, Self,  550, 0, FCamera);
    550: begin
      FLR.SetFaceType(lrfSmile);
      FLR.ShowDialog(sOkDoYouKnownWhereICanFindABoat, FFontText, Self,  552, 0, FCamera);
    end;
    552: FPenelope.ShowDialog(sNoIdeaYouAreSmart, FFontText, Self,  554, 0, FCamera);
    554: begin
      Audio.PlayThenKillSound('train-horn.ogg', 0.8);
      PostMessage(555, 0.5);
    end;
    555: FPenelope.ShowDialog(sWeArriveAtMermaidsPort, FFontText, Self,  556, 0, FCamera);
    556: FLR.ShowDialog(sThankYouForYourHelp, FFontText, Self,  559, 0, FCamera);
    559: begin
      FPenelope.IdleRight;
      FCamera.Scale.ChangeTo(PointF(0.4, 0.4), 3.0, idcSinusoid);
      PostMessage(560, 1.75);
    end;
    560: begin // clouds2 disapears and factories appears
      FMountainParallax.FClouds2.Opacity.ChangeTo(0, 2.0);
      FFactoryParallax.MakeFactoryAppears;
      PostMessage(564, 5.0);
    end;
    564: begin  // train brakes
      sndTrainWheel.Volume.ChangeTo(0, 8.0);
      FTrain.sndEngine.Volume.ChangeTo(0, 8.0);
      Audio.PlayThenKillSound('train-braking.ogg', 0.8, 0.0, 1.0, Audio.FXReverbShort, 0.8);
      FScrollingSpeed.ChangeTo(0, 8.6);
      PostMessage(570, 8.0);
    end;
    570: begin
      sndTrainIdle := Audio.AddSound('depressurization-of-the-brakes-of-a-train.ogg', 0.8, True);
      sndTrainIdle.Play(True);
      PostMessage(573, 0.5);
    end;
    573: begin  // LR jump
      FLR.IdleUp;
      PostMessage(575, 0.5);
    end;
    575: begin
      FLR.Y.ChangeTo(FLR.Y.Value - PPIScale(20), 0.4, idcStartFastEndSlow);
      PostMessage(576, 0.4);
    end;
    576: begin
      FTrain.SetCharacterToFollow(NIL);
      FLR.MoveFromChildToScene(LAYER_BG2);
      FLR.Y.ChangeTo(ScaleH(611)+FLR.DeltaYToTop, 0.5, idcDrop);
      PostMessage(578, 0.8);
    end;
    578: begin
      FLR.IdleRight;
      PostMessage(580, 0.5);
    end;
    580: begin
      FLR.TimeMultiplicator := 0.4;
      FLR.WalkHorizontallyTo(FLR.X.Value + FScene.Width*2, Self, 99999);
      PostMessage(582, 3.0);
    end;
    582: begin  // mini game is terminated: return to map
      FadeOutAndKillMusicAndSounds;
      PlayerInfo.PlainMoon.IncCurrentStep;
      FSaveGame.Save;
      FScene.RunScreen(ScreenMap);
    end;
    590: begin // create Shooting stars
      if FEndOfShootingStars then exit;
      TShootingStar.Create;
      PostMessage(590, Random*5+3.0);
    end;
  end;
end;

procedure TScreenPlainOfSleepingMoon.Update(const aElapsedTime: single);
var flagPlayerIdle: boolean;
  wagonPart: TWagonHead;
  p: TPointF;
begin
  inherited Update(aElapsedTime);

  if FPlainGame.Activated then begin
    case FGameState of
      gsLRPlayOutside: begin
        flagPlayerIdle := True;

        if not FLR.IsOnLadder then begin

          // shoot
          if Input.Action2Pressed then begin
            if FAction2Released then begin
              PlayLaserShootSound;
              FLR.LRRight.ShootWithRightHandObject;
              TLaserShoot.Create;
              FAction2Released := False;
            end;
          end else FAction2Released := True;

          if Input.Action1Pressed and not FTrain.CharacterToFollowIsOnPlatform then begin
            FLR.State := lr4sJumping;
            flagPlayerIdle := False;
          end;

          if Input.LeftPressed and flagPlayerIdle then begin
            if FTrain.CharacterToFollowIsOnHeadPlatform then begin
              if FLR.X.Value > FTrain.Wagons[0].FullWidth-ScaleW(300) then FLR.State := lr4sLeftWalking
                else begin
                  FLR.X.Value := FTrain.Wagons[0].FullWidth-ScaleW(300);
                  FLR.State := lr4sLeftIdle;
                end;
            end
            else
            if FTrain.CharacterToFollowIsOnTailPlatform then begin
              if FLR.X.Value > ScaleW(105) then FLR.State := lr4sLeftWalking
                else begin
                  FLR.X.Value := ScaleW(105);
                  FLR.State := lr4sLeftIdle;
                end;
            end
            else FLR.State := lr4sLeftWalking;
            flagPlayerIdle := False;
          end; //Input.LeftPressed

          if Input.RightPressed and flagPlayerIdle then begin
            if FTrain.CharacterToFollowIsOnHeadPlatform then begin
              if FLR.X.Value < FTrain.Wagons[0].FullWidth-ScaleW(130) then FLR.State := lr4sRightWalking
                else begin
                  FLR.X.Value := FTrain.Wagons[0].FullWidth-ScaleW(130);
                  FLR.State := lr4sRightIdle;
               end;
            end
            else
            if FTrain.CharacterToFollowIsOnTailPlatform then begin
              if FLR.X.Value < ScaleW(280) then FLR.State := lr4sRightWalking
                else begin
                  FLR.X.Value := ScaleW(280);
                  FLR.State := lr4sRightIdle;
               end;
            end
            else FLR.State := lr4sRightWalking;
            flagPlayerIdle := False;
          end; //Input.RightPressed

          if Input.DownPressed and flagPlayerIdle then begin
            if FTrain.CharacterToFollowIsAboveLadder then begin
              FLR.Y.Value := FLR.Y.Value + ScaleH(40); // LR 'jump' on the ladder
              FLR.State := lr4sOnLadderDown;
              if FCamera.Scale.State = psNO_CHANGE then
                FCamera.Scale.ChangeTo(PointF(1.0,1.0), 3.0, idcSinusoid);
              flagPlayerIdle := False;
            end;
          end;

          if Input.UpPressed and flagPlayerIdle then begin
            if FTrain.CharacterToFollowCanClimbUpLadder then begin
              FLR.State := lr4sOnLadderUp;
              flagPlayerIdle := False;
            end
            else   // LR open door
            if (FGameSequence = gsWaitPlayerEnterWagon) and
               FTrain.CheckIfCharacterToFollowCanOpenTheDoor(wagonPart) then begin
              FWagonPartEntered := wagonPart;
              GameState := gsLREnterWagon;
              PostMessage(300);
              flagPlayerIdle := False;
            end;
          end;
        end  //if not FLR.IsOnLadder
        else begin
          // HERE LR IS ON LADDER
          if Input.DownPressed and flagPlayerIdle then begin
            if FLR.BodyBottomY < YFeetOnPlatform
              then FLR.State := lr4sOnLadderDown
              else begin
                FLR.State := lr4sOnLadderIdle;
                FLR.BodyBottomY := YFeetOnPlatform;
              end;
            flagPlayerIdle := False;
          end;

          if Input.UpPressed and flagPlayerIdle then begin
            if FLR.BodyBottomY > YFeetOnTrain
              then FLR.State := lr4sOnLadderUp
              else begin
                FLR.State := lr4sOnLadderIdle;
                FLR.BodyBottomY := YFeetOnTrain;
                if FCamera.Scale.State = psNO_CHANGE then
                  FCamera.Scale.ChangeTo(PointF(0.5,0.5), 3.0, idcSinusoid);
              end;
            flagPlayerIdle := False;
          end;

          if Input.LeftPressed and flagPlayerIdle and
             ((FLR.BodyBottomY = YFeetOnTrain) or (FLR.BodyBottomY = YFeetOnPlatform)) then begin
            FLR.State := lr4sLeftWalking;
            flagPlayerIdle := False;
          end;

          if Input.RightPressed and flagPlayerIdle and
             ((FLR.BodyBottomY = YFeetOnTrain) or (FLR.BodyBottomY = YFeetOnPlatform)) then begin
            FLR.State := lr4sRightWalking;
            flagPlayerIdle := False;
          end;

          // LR 'jump' from ladder to train roof
          if FLR.BodyBottomY < YFeetOnTrain+ScaleH(40) then begin
            FLR.BodyBottomY := YFeetOnTrain;
            FLR.State := lr4sRightIdle;
          end;
        end;

        // no moves -> idle state
        if flagPlayerIdle then FLR.SetIdlePosition;

        // update the LR parent
        FTrain.CharacterToFollowUpdateCarriageParent;

        // check if LR fall. (She can fall only when she jump on another wagon)
        if not FLR.IsJumping and FTrain.CheckIfCharacterToFollowCanFall then
          GameState := gsLRFallBetweenWagon;

        // check time
        if FGameInventory.Clock.Second = 0 then begin
          FGameInventory.Clock.PauseTime;
          if FSpriteMessageTimeOver = NIL then begin
            FSpriteMessageTimeOver := SpriteMessage(sOutOfTime);
            FSpriteMessageTimeOver.BottomY := FScene.Height*0.3;
          end;
          // we wait LR is on the roof
          if FLR.BodyBottomY = YFeetOnTrain then GameState := gsTimeElapsed;
          exit;
        end;

        // update the door light on the wagon where the player is
        //FTrain.UpdateDoorLight;

        // update the directionnal arrow position and game current sequence
        case FGameSequence of
          gsWaitPlayerIsOnWagonCenter: begin
            // avoid LR to jump on another wagon
            FTrain.AvoidCharacterToFollowToJumpOnAnotherWagon;
            if FTrain.CharacterToFollowIsOnWagonCenter then begin
              GameSequence := gsDestroyRobotOnTheRoof;
              FRobotCount := 20 + (PLAIN_MOON_WAGON_COUNT-FLR.ParentSurface.Tag1)*20;
              FRobotDestroyed := 0;
              FRobotCreated := 0;
              FDelayBeforeNextRobotAppears := 1.0;
            end;
          end;
          gsDestroyRobotOnTheRoof: begin
            // avoid LR to jump on another wagon
            FTrain.AvoidCharacterToFollowToJumpOnAnotherWagon;
             if FRobotDestroyed >= FRobotCount then GameSequence := gsWaitPlayerEnterWagon;
             if FRobotCreated < FRobotCount then begin
               FDelayBeforeNextRobotAppears := FDelayBeforeNextRobotAppears - aElapsedTime;
               if FDelayBeforeNextRobotAppears <= 0.0 then begin
                 inc(FRobotCreated);
                 TRobotOnWagon.Create(FLR.ParentSurface.Tag1-1);
                 case FLR.ParentSurface.Tag1-1 of
                   3: FDelayBeforeNextRobotAppears := 0.2 + Random*0.3;
                   2: FDelayBeforeNextRobotAppears := 0.1 + Random*0.2;
                   1: FDelayBeforeNextRobotAppears := 0.1 + Random*0.1;
                   0: FDelayBeforeNextRobotAppears := 0.1 + Random*0.1;
                 end;
               end;
             end;
          end;
          gsWaitPlayerEnterWagon: begin
            // avoid LR to jump on another wagon
            FTrain.AvoidCharacterToFollowToJumpOnAnotherWagon;
            // update the door light on the wagon where the player is
            FTrain.UpdateDoorLight;
         end;
          gsWaitPlayerJumpOnPreviousWagon: begin
            // avoid LR to jump on the next (left) wagon
            FTrain.AvoidCharacterToFollowToJumpOnNextWagon;
            if FLR.ParentSurface.Tag1-1 <> FPreviousWagonIndex then
              if FLR.ParentSurface.Tag1 = 0
                then GameState := gsAllWagonAreDone
                else GameSequence := gsWaitPlayerIsOnWagonCenter;
          end;
        end;
      end; //gsLRPlayOutside
    end;// case FGameState

    // update the position of the train on the scene to follow a character
    FTrain.UpdatePosition;

    // adjust the parallax scrolling speed and train wheel rotation speed
    FScrollingSpeed.OnElapse(aElapsedTime);
    UpdateParallaxScrollingSpeed;
    FForceSpeedUpdate := False;
  end; //if FPlainGame.Activated

  if FPlainIntroductionCinematic.Activated then begin
    FPlainIntroductionCinematic.UpdateWagonsPosition;
  end;

  // update the position of the train sound engine
  if FUpdateTrainEngineVolume then begin
    p := FTrain.Loco.SurfaceToScene(PointF(FTrain.Loco.FullWidth*0.5, 0));
    FTrain.sndEngine.Position3D(p.x, p.y, 0);
    // audio listener position follow camera view center
    p := GetCenterView(FCamera);
    Audio.SetListenerPosition(p.x, p.y);
  end;

  // check if player pause the game
  if Input.PausePressed then
    FInGamePausePanel.ShowModal;
end;

procedure TScreenPlainOfSleepingMoon.FadeOutAndKillMusicAndSounds;
begin
  if sndTrainWheel <> NIL then sndTrainWheel.FadeOutThenKill(2.0);
  sndTrainWheel := NIL;

  if sndMusic <> NIL then sndMusic.FadeOutThenKill(1.0);
  sndMusic := NIL;

  FTrain.DeleteSound;
  if sndTrainIdle <> NIL then sndTrainIdle.FadeOutThenKill(2.0);
  sndTrainIdle := NIL;
end;


end.

