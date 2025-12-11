unit u_wolfmothership;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes,
  u_sprite_wolf, u_procedural_interstellarjump, u_procedural_starjump,
  u_procedural_starnest, u_audio, u_common, gvector, u_common_ui;

type

{ TScrollingStars2D }

TScrollingStars2D = class(TSpriteContainer)
private type
  TSingleStar2D = class(TSprite)
    SpeedCoeff: single;
  end;
private
  FSizeStar1, FSizeStar2, FSizeStar3: Integer;
  FArea: TRect;
public
  ScrollingSpeed: TPointFParam;
  constructor Create(aLayerIndex: integer; aPlane1Count: integer=30; aPlane2Count: integer=60; aPlane3Count: integer=200);
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
end;

{ TStarsBG }

TStarsBG = class(TSpriteContainer)
private
  FStarnestRenderer: TStarNestRenderer;
  FStarnest: TStarNest;
  function GetStarnest: TStarNest;
private
  FScrollingStars2D: TScrollingStars2D;
  function GetScrollingStars2D: TScrollingStars2D;
private
  FStarJumpRenderer: TStarJumpRenderer;
  FStarJump: TStarJump;
  function GetStarJump: TStarJump;
private
  FInterstellarJumpRenderer: TInterStellarJumpRenderer;
  FInterstellarJump: TInterstellarJump;
  function GetInterstellarJump: TInterstellarJump;
private
  FJumping: boolean;
public
  constructor Create(aLayerIndex: integer);
  destructor Destroy; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;

  procedure EnterInterstellarJump;
  procedure ExitInterstellarJump;

  property Starnest: TStarNest read GetStarnest;
  property ScrollingStars2D: TScrollingStars2D read GetScrollingStars2D;
  property InterstellarJump: TInterstellarJump read GetInterstellarJump;
  property StarJump: TStarJump read GetStarJump;
end;

{ TAsteroidBeltViewFromShip }

TAsteroidBeltViewFromShip = class(TSpriteContainer)
  constructor Create(aLayerIndex: integer);
end;


TBaseLittleShip = class;
{ THyperSpaceGate }

THyperSpaceGate = class(TSprite)
private
  FRing2: TSprite;
  FGlow: TOGLCGlow;
  FParticles: TParticleEmitter;
  FSize, FAV: TFParam;
  FDone: boolean;
public
  constructor Create(aCenterX, aCenterY: single; aLayerIndex: integer; aAtlas: TAtlas);
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure StartRotate;
  procedure OpenPhase1(aDuration: single); // particle starts to flow
  procedure OpenPhase2(aDuration: single);
  procedure OpenPhase3(aDuration: single); // big white cloud
  procedure OpenPhase4(aDuration: single); // hole appears

  property Done: boolean read FDone;
end;

{ TMotherShipDockingBay }

TMotherShipDockingBay = class(TSprite)
private
  class var texMotherShipDockBody, texMotherShipDockBG, texMotherShipDockFlare: PTexture;
private
  BG: TSprite;
  FlareLeft: TSprite;
  FlareRight: TSprite;
public
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas);
  constructor Create(aLayerIndex: integer=-1);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

{ TBaseLittleShip }

TBaseLittleShip = class(TSprite)
private
  FAnimDone,
  FFollowingPath, FManualDrive: boolean;
  FPathFilename: string;
  FPath: TPathToFollow;
  FPE: TParticleEmitter;
  FsndPropulsor: TALSSound;
  FVelocity: TFParam;
  FVelocityMax, FTurnAngle, FAccelerateAmount, FDecelerateAmount: single;
  function GetVelocity: single;
  procedure SetVelocity(AValue: single);
public
  ParentDockingBay: TMotherShipDockingBay;
  constructor Create(ATexture: PTexture; Owner: boolean; aAtlas: TAtlas; aUseSound: boolean);
  procedure SetVelocityConstant(aVelocityMax, aTurnAngleAmount, aAccelerateAmount, aDecelerateAmount: single);
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
public  // utils
  function GetCenterInWorldCoor: TPointF;
public  // anim
  procedure StartPropulsor;
  procedure StopPropulsor;
  // assume the ship is docked in the docking bay (child of docking bay)
  procedure ExitFromDockingBay;
  // assume the ship is docked in the docking bay (child of docking bay)
  procedure ExitFromDockingBay_RunPath(const aPathFilename: string);
  // assume the ship is docked in the docking bay (child of docking bay)
  procedure ExitFromDockingBay_RunPath_EnterDockingBay(const aPathFilename: string);
  procedure EnterDockingBay;
  property AnimDone: boolean read FAnimDone;
public // manual drive
  procedure SetManualDrive;
  procedure TurnLeft(const aElapsedTime: single);
  procedure TurnRight(const aElapsedTime: single);
  procedure Accelerate(const aElapsedTime: single);
  procedure Decelerate(const aElapsedTime: single);
  function ParamsAreOkToDock: boolean;
  // goes back a little (when the ship hurt something)
  procedure Bump;
  property Velocity: single read GetVelocity write SetVelocity;
  property VelocityMax: single read FVelocityMax;
public  // manual drive for shoot'em up
  procedure MoveLeft(const aElapsedTime: single);
  procedure MoveRight(const aElapsedTime: single);
  procedure MoveUp(const aElapsedTime: single);
  procedure MoveDown(const aElapsedTime: single);
end;

{ TMiningShip }

TMiningShip = class(TBaseLittleShip)
  FPEHarvesting: TParticleEmitter;
  FsndHarvesting: TALSSound;
  constructor Create(aAtlas: TAtlas; aUseSound: boolean);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  // check property AnimDone to known when the harvesting is completed
  procedure StartHarvesting;
end;

{ TCombatShip }
TOnBulletCheckCollision = procedure(aBullet: TSimpleSurfaceWithEffect) of object;
TCombatShip = class(TBaseLittleShip)
private const LASER_MAXINDEX = 4;
private type
  TBulletInfo = record
    pos: TPointF;
    angle: single;
  end;
  TArrayOfBulletInfo = array of TBulletInfo;

  TShoot = class(TSprite)  // LAYER_ARROW
    FOnBulletCheckCollision: TOnBulletCheckCollision;
    FDelayCheckCollision: integer;
    constructor Create(aCenter: TPointF; aAngle: single; aOnBulletCheckCollision: TOnBulletCheckCollision);
    procedure Update(const aElapsedTime: single); override;
  end;
private
  FBulletInfo: array[0..4] of TArrayOfBulletInfo;
  FOnBulletCheckCollision: TOnBulletCheckCollision;
  FShootLevelIndex: integer;
  FShootDelayRemain: single;
  procedure ComputeBulletInfos;
public
  Invincible: boolean;
  constructor Create(aAtlas: TAtlas; aUseSound: boolean);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Shoot;
  procedure UpgradeWeapon;
  procedure Hit;
  property OnBulletCheckCollision: TOnBulletCheckCollision read FOnBulletCheckCollision write FOnBulletCheckCollision;
  property ShootLevelIndex: integer read FShootLevelIndex;
end;

{ TRadioMessage }

TRadioMessage = class(TSpriteContainer)
private type
    TMess = class(TQuad4Color)
      FTextArea: TUITextArea;
      FIcon: TSprite;
      constructor Create(aTex: PTexture; const aText: string; aFont: TTexturedFont; const aBGColor: TBGRAPixel);
      procedure ProcessMessage(UserValue: TUserMessageValue); override;
    end;
private
  FFont: TTexturedFont;
  FBGColor: TBGRAPixel;
  procedure InsertMessage(aMess: TMess);
public
  constructor Create(aFont: TTexturedFont; aLayerIndex: integer=LAYER_DIALOG);
  procedure SetBGColor(const aColor: TBGRAPixel);
  procedure AddMessageFromPenelope(const aText: string);
  procedure AddMessageFromMarcus(const aText: string);
  procedure AddMessageFromFather(const aText: string);
  procedure AddMessageFromW7(const aText: string);
  procedure AddMessageFromLR(const aText: string);
end;

{ TRadar }

TRadar = class(TSprite)
private type
  TRadarItem = record
    Icon: TSprite;
    Instance: TSimpleSurfaceWithEffect;
    CopyInstanceAngle: boolean;
  end;
  PRadarItem = ^TRadarItem;
  TRadarItemList = class(specialize TVector<TRadarItem>);
  var
  FItems: TRadarItemList;
  procedure AddItemToList(aIcon: TSprite; aInstance: TSimpleSurfaceWithEffect; aCopyInstanceAngle: boolean);
  procedure RemoveItemFromList(aInstance: TSimpleSurfaceWithEffect);
  procedure UpdateItemOnTheRadar(aIndex: SizeUInt);
private
  FIconArrow: TSprite;
  FOwnerShip: TSimpleSurfaceWithEffect;
public
  constructor Create(aLayerIndex: integer=LAYER_GAMEUI);
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure SetBGColor(aColor: TBGRAPixel);
public
  procedure RegisterOwnerShip(aSurface: TSimpleSurfaceWithEffect);
  procedure RegisterMotherShip(aSurface: TSimpleSurfaceWithEffect);
  procedure RegisterGate(aSurface: TSimpleSurfaceWithEffect);
  procedure RegisterObject(aIconTex: PTexture; aResize: boolean;
    aInstance: TSimpleSurfaceWithEffect; aCopyInstanceAngle: boolean);
  procedure RemoveObject(aInstance: TSimpleSurfaceWithEffect);
  procedure PlayBeep;
end;

{ TItemAsked }

TItemAsked = class(TBaseInGamePanel)
  IsEmpty: boolean;
  procedure SetBGColor(const aColor: TBGRAPixel);
  procedure Add(aItemIndex, aCount: integer);
  procedure Substract(aItemIndex, aCount: integer);
end;

{ THUD }

THUD = class
private
  FRadar: TRadar;
  FRadio: TRadioMessage;
  FItemAsked: TItemAsked;
public
  constructor Create(aFont: TTexturedFont);
  procedure SetBGColor(const aColor: TBGRAPixel);
  property Radar: TRadar read FRadar;
  property Radio: TRadioMessage read FRadio;
  property ItemAsked: TItemAsked read FItemAsked;
end;

{ TMotherShipTopView }
// the whole ship top view
TMotherShipTopView = class(TSprite)
private
  class var FAdditionalScale: single;
  class var texMotherShipBody, texMotherShipWingLeft, texMotherShipRadar, texTransporterWK510,
            texMotherShipGigatron, texMotherShipAnnihilator: PTexture;
private
  WingLeft: TSprite;
  MotherShipRadar: TSprite;
  WingRight: TSprite;
  FPropulsorLeft, FPropulsorRight: TParticleEmitter;
  FTransporterWK510: TSprite;
  FDockingBay: TMotherShipDockingBay;
  FShield, FShield2: TParticleEmitter;
  FGigatron1, FGigatron2, FAnnihilator1, FAnnihilator2: TSprite;
  FBlinkCounter: integer;
  FShaker: TShakerDescriptor;
  FOriginForShaker: TPointF;
public
  // aAdditionalScale is used to scale the collision bodies
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single=1.0);
  constructor Create(aLayerIndex: integer; aAtlas: TAtlas; aAddTransporterWK510: boolean);
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;

  function GetLocalTransporterBayCenter: TPointF;
public // anim
  procedure StartPropulsors;
  procedure StopPropulsor;
  procedure StartShield;
  procedure StopShield;
  procedure Shake;

  procedure ShowDockingBay;
  procedure ShowGigatron;
  procedure ShowAnnihilator;

  // hide the ship in the docking bay. The ship becomes a child of the docking bay.
  procedure DockShip(aShip: TBaseLittleShip);
public // upgrade anim
  procedure MakeDockingBayAppears;
  procedure MakeShieldAppears;
  procedure MakeGigatronAppears;
  procedure MakeAnnihilatorAppears;
end;

{ TScreenAnim }

TScreenAnimType = (satNone, satRotate, satFlipH, satFlipV);
TScreenAnim = class(TSprite)
private
  FInverse: TSprite;
  procedure CreateFlippedH(aTex: PTexture);
  procedure CreateFlippedV(aTex: PTexture);
public
  constructor Create(aTex: PTexture; aX, aY: single; aWidth, aHeight: integer; aAnimType: TScreenAnimType;
    aLayerIndex: integer);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

{ TScreenAnimScrollingText }

TScreenAnimScrollingText = class(TTileEngine)
  constructor Create(aTex: PTexture; aX, aY: single; aWidth, aHeight, aLayerIndex: integer);
end;

{ TSeatWithCharacter }

TSeatWithCharacter = class(TSprite)
private class var texSeat, texSeatArmrest: PTexture;
private
  FArmrest: TSprite;
  FSeatedCharacter: TWolf;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  class procedure LoadTexture(aAtlas: TAtlas);
  constructor Create(aLayerIndex: integer);
  procedure SetCharacter(aWolfCharacter: TWolf);
  procedure RaiseCharacter(aLayerIndex: integer);
  procedure ApplyTint(AValue: TBGRAPixel);
end;

{ TMainBridgeBG }

TMainBridgeBG = class(TSprite)
private
  FDeskCenter: TSprite;
  FShield: TParticleEmitter;
  FDangerBG: TQuad4Color;
  FDangerLabel: TSprite;
  procedure CreateAlertPanel(aTex: PTexture);
public
  // FlipH=false  mean to the left
  LeftSeat, RightSeat: TSeatWithCharacter;
  constructor Create(aLayerIndex: integer);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure CreateDeskCenter(aLayerIndex: integer);
  procedure CreateSeats(aLayerIndex: integer);
  class function GetMessFontDescriptor(const aMess: string): TFontDescriptor;

  procedure StartShield(aAtlas: TAtlas);
  procedure StopShield;

  procedure ShowAlert(aTex: PTexture);
  procedure KillAlert;

  procedure ApplyTint(AValue: TBGRAPixel);
end;

{ TConstructionUnit }
TConstructionState = (cusIdle, cusConstructing, cusConstructionDone, cusConstructionFailed);
TConstructionUnit = class(TSprite)
private type
  TFallingItem = class(TSprite)
    constructor Create(aParent: TConstructionUnit; aIndex: integer);
    procedure Update(const aElapsedTime: single); override;
  end;
  TCrate = class(TSprite)
    constructor Create(aParent: TConstructionUnit; const aCrateLabel: string; aFontText: TTexturedFont);
  end;
private
  FFontText: TTexturedFont;
  FConveyor: TScrollableSprite;
  FMachine, FMarcusDialog, FCrate, FGaugeArrow: TSprite;
  FSmoke: TParticleEmitter;
  FButtons: array[0..34] of TUIButton;
  FState: TConstructionState;
  FConstructionItemIndexes: TArrayOfInteger;
  FConstructionItemIndex: integer;
  FGaugeTime: single;
  FCrateLabel: string;
  function GetGaugePercent: Single;
  procedure SetGaugePercent(AValue: Single);
  procedure ProcessButtonMouseEnter(Sender: TSimpleSurfaceWithEffect);
  procedure ProcessButtonMouseLeave(Sender: TSimpleSurfaceWithEffect);
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
  procedure CheckItemFalled(aIndex: integer);
  procedure ShowMarcusDialog(aIndex: integer);
  procedure HideMarcusDialog;
  procedure SetState(AValue: TConstructionState);
public
  constructor Create(aAtlas: TAtlas; aFontText: TTexturedFont; aLayerIndex: integer);
  procedure Update(const aElapsedTime: single); override;
  procedure EnableButtons(AValue: boolean);
  procedure StartConstruction(const aItemIndexes: TArrayOfInteger; aCrateLabel: string);
  // 0..1
  property GaugePercent: Single read GetGaugePercent write SetGaugePercent;
  // default is 3s
  property GaugeTime: single read FGaugeTime write FGaugeTime;
  property State: TConstructionState read FState write SetState;
end;

{TResearchCenter = class(TSprite)
  Seat: TSeatWithCharacter;
  constructor Create(aLayerIndex: integer);
  destructor Destroy; override;
end; }

procedure LoadScrollingStar2DTextures(aAtlas: TAtlas);
procedure LoadMainBridgeTextures(aAtlas: TAtlas);
procedure LoadConstructionUnitTextures(aAtlas: TAtlas);
//procedure LoadResearchCenterTextures(aAtlas: TAtlas);
procedure LoadMiningShipTextures(aAtlas: TAtlas);
procedure LoadRedCombatShipTextures(aAtlas: TAtlas);
procedure LoadHyperSpaceGateTextures(aAtlas: TAtlas);
procedure LoadRadioMessageTextures(aAtlas: TAtlas);
procedure LoadRadarTextures(aAtlas: TAtlas);

function GetOreTexture(aIndex: integer): PTexture;
function GetOreColor(aIndex: integer): TBGRAPixel;

implementation

uses u_app, u_resourcestring, Math, ALSound;

var
  // 2D scrolling stars
  texScrollingStar2D,
  // main bridge
  texMainBridge, texDeskCenter,
  // construction unit
  texConsBG, texConsConveyor, texConsMachine, texConsGaugeArrow, texConsPipe, texConsPipeBG,
  texConsMarcusDialog, texConsCrate: PTexture;
  texConsItems: array[0..34] of PTexture;
  // research center
  //texResearchCenter,
  // radio message
  texIconPenelopeHead, texIconMarcusHead, texIconFatherHead, texIconW7Head, texIconLRHead,
  // radar
  texRadarBody, texRadarIconArrow, texRadarIconMotherShip, texRadarIconGate,
  // common
  texScreen1, texScreen2, texScreen3, texScreen4,
  texAsteroid1, texAsteroid2, texAsteroid3, texAsteroid4,
  texMiningShip, texRedCombatShip, texRedCombatShipShoot,
  texHyperSpaceGate: PTexture;

{procedure LoadResearchCenterTextures(aAtlas: TAtlas);
var path: String;
begin
  path := FolderSpriteInSpace;
  TSeatWithCharacter.LoadTexture(aAtlas);
  texResearchCenter := aAtlas.AddFromSVG(path+'InnerResearchCenter.svg', ScaleW(768), -1);
  texScreen1 := aAtlas.AddFromSVG(path+'Screen1.svg', ScaleW(40), -1);
end;  }

procedure LoadConstructionUnitTextures(aAtlas: TAtlas);
var path: string;
  i: integer;
begin
  path := FolderConstructionUnit;
  texConsBG := aAtlas.AddFromSVG(path+'ConstructionRoomBG.svg', ScaleW(768), -1);
  //texConsConveyor := aAtlas.AddFromSVG(path+'Conveyor.svg', ScaleW(317), -1);
  texConsConveyor := FScene.TexMan.AddFromSVG(path+'Conveyor.svg', ScaleW(317), -1);
  texConsMachine := aAtlas.AddFromSVG(path+'Machine.svg', ScaleW(466), -1);
  texConsGaugeArrow := aAtlas.AddFromSVG(path+'GaugeArrow.svg', -1, ScaleH(48));
  texConsPipe := aAtlas.AddFromSVG(path+'Pipe.svg', ScaleW(124), -1);
  texConsPipeBG := aAtlas.AddFromSVG(path+'PipeBG.svg', ScaleW(124), -1);
  texConsMarcusDialog := aAtlas.AddFromSVG(path+'MarcusDialog.svg', -1, ScaleH(117));
  texConsCrate := aAtlas.AddFromSVG(path+'Crate.svg', ScaleW(134), -1);
  for i:=0 to 34 do
    case i of
      0, 3, 7,  14..20, 28..34:
        texConsItems[i] := aAtlas.AddFromSVG(path+'ConsItem'+i.ToString+'.svg', -1, ScaleH(49));
      1, 2, 4..6, 8, 9..13, 21..27:
        texConsItems[i] := aAtlas.AddFromSVG(path+'ConsItem'+i.ToString+'.svg', ScaleW(49), -1);
    end;
  texScreen4 := aAtlas.AddFromSVG(FolderSpriteInSpace+'Screen4.svg', ScaleW(44), -1);
end;

procedure LoadMiningShipTextures(aAtlas: TAtlas);
begin
  texMiningShip := aAtlas.AddFromSVG(FolderSpriteWolfCastle+'MiningShip.svg', ScaleW(41), -1);
end;

procedure LoadRedCombatShipTextures(aAtlas: TAtlas);
begin
  texRedCombatShip := aAtlas.AddFromSVG(FolderSpriteInSpace+'CombatShipRed.svg', ScaleW(32), -1);
  texRedCombatShipShoot := aAtlas.AddFromSVG(FolderSpriteInSpace+'CombatShipRedShoot.svg', -1, ScaleH(23));
end;

procedure LoadHyperSpaceGateTextures(aAtlas: TAtlas);
begin
  texHyperSpaceGate := aAtlas.AddFromSVG(FolderSpriteInSpace+'HyperSpaceGate.svg', ScaleW(360), -1);
end;

procedure LoadRadioMessageTextures(aAtlas: TAtlas);
begin
  texIconPenelopeHead := aAtlas.AddFromSVG(SpriteUIFolder+'IconPenelopeHead.svg', ScaleW(45), -1);
  texIconMarcusHead := aAtlas.AddFromSVG(SpriteUIFolder+'IconMarcusHead.svg', ScaleW(45), -1);
  texIconFatherHead := aAtlas.AddFromSVG(SpriteUIFolder+'IconFatherHead.svg', ScaleW(45), -1);
  texIconW7Head := aAtlas.AddFromSVG(SpriteUIFolder+'IconW7Head.svg', ScaleW(45), -1);
  texIconLRHead := aAtlas.AddFromSVG(SpriteUIFolder+'IconLRHead.svg', ScaleW(45), -1);
end;

procedure LoadRadarTextures(aAtlas: TAtlas);
var path: String;
begin
  path := FolderSpriteInSpace;
  texRadarBody := aAtlas.AddFromSVG(path+'RadarBody.svg', ScaleW(173), -1);
  texRadarIconArrow := aAtlas.AddFromSVG(path+'RadarIconArrow.svg', ScaleW(14), -1);
  texRadarIconMotherShip := aAtlas.AddFromSVG(path+'RadarIconMotherShip.svg', -1, ScaleH(18));
  texRadarIconGate := aAtlas.AddFromSVG(path+'RadarIconGate.svg', ScaleW(21), -1);
end;

function GetOreTexture(aIndex: integer): PTexture;
begin
  Result := texConsItems[EnsureRange(aIndex, 0, 6)+21];
end;

function GetOreColor(aIndex: integer): TBGRAPixel;
begin
  case EnsureRange(aIndex, 0, 6) of
    0: Result := BGRA(246,246,37);    // gold - yellow
    1: Result := BGRA(241,77,3);    // copperdynium - cooper
    2: Result := BGRA(244,244,244);   // gadolinium - white
    3: Result := BGRA(0,0,0);         // praseodymium - black
    4: Result := BGRA(129,61,145);    // neodymium - purple
    5: Result := BGRA(40,240,25);     // argythium - green
    6: Result := BGRA(255,22,14);     // triferium - red
  end;
end;

procedure LoadScrollingStar2DTextures(aAtlas: TAtlas);
begin
  texScrollingStar2D := aAtlas.AddFromSVG(FolderSpriteInSpace+'ScrollingStar2D.svg', ScaleW(6), -1);
end;

procedure LoadMainBridgeTextures(aAtlas: TAtlas);
var path: String;
begin
  path := FolderSpriteInSpace;
  TSeatWithCharacter.LoadTexture(aAtlas);
  texMainBridge := aAtlas.AddFromSVG(path+'InnerMainBridge.svg', ScaleW(768), -1);
  texDeskCenter := aAtlas.AddFromSVG(path+'DeskCenter.svg', ScaleW(222), -1);
  texScreen1 := aAtlas.AddFromSVG(path+'Screen1.svg', ScaleW(40), -1);
  texScreen2 := aAtlas.AddFromSVG(path+'Screen2.svg', ScaleW(25), -1);
  texScreen3 := aAtlas.AddFromSVG(path+'Screen3.svg', ScaleW(23), -1);
  texScreen4 := aAtlas.AddFromSVG(path+'Screen4.svg', ScaleW(44), -1);
  texAsteroid1 := aAtlas.AddFromSVG(path+'Asteroid1.svg', ScaleW(82), -1);
  texAsteroid2 := aAtlas.AddFromSVG(path+'Asteroid2.svg', ScaleW(102), -1);
  texAsteroid3 := aAtlas.AddFromSVG(path+'Asteroid3.svg', ScaleW(45), -1);
  texAsteroid4 := aAtlas.AddFromSVG(path+'Asteroid4.svg', ScaleW(74), -1);
end;

{ TScreenAnimScrollingText }

constructor TScreenAnimScrollingText.Create(aTex: PTexture; aX, aY: single; aWidth,
  aHeight, aLayerIndex: integer);
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  LoadMapFile(FolderSpriteInSpace+'Screen4Main_Map.map', [aTex]);
  SetCoordinate(aX, aY);
  SetViewSize(aWidth, aHeight);
end;

{ TScreenAnim }

procedure TScreenAnim.CreateFlippedH(aTex: PTexture);
begin
  FInverse := TSprite.Create(aTex, False);
  AddChild(FInverse, -1);
  FInverse.FlipH := True;
  FInverse.X.Value := Width*0.5;
  FInverse.Y.Value := 0;
end;

procedure TScreenAnim.CreateFlippedV(aTex: PTexture);
begin
  FInverse := TSprite.Create(aTex, False);
  AddChild(FInverse, -1);
  FInverse.FlipV := True;
  FInverse.Y.Value := Height*0.5;
  FInverse.X.Value := 0;
end;

constructor TScreenAnim.Create(aTex: PTexture; aX, aY: single; aWidth,
  aHeight: integer; aAnimType: TScreenAnimType; aLayerIndex: integer);
begin
  inherited Create(aTex, False);
  SetCoordinate(aX, aY);
  SetSize(aWidth, aHeight);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  case aAnimType of
    satRotate: Angle.AddConstant(180);
    satFlipH: begin
      CreateFlippedH(aTex);
      PostMessage(0);
    end;
    satFlipV: begin
      CreateFlippedV(aTex);
      PostMessage(50);
    end;
  end;
end;

procedure TScreenAnim.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // anim flipped H
    0: begin
      MoveXRelative(Width*0.5, 1.5, idcSinusoid);
      FInverse.MoveXRelative(-Width, 1.5, idcSinusoid);
      PostMessage(5, 1.5);
    end;
    5: begin
      MoveXRelative(-Width*0.5, 1.5, idcSinusoid);
      FInverse.MoveXRelative(Width, 1.5, idcSinusoid);
      PostMessage(0, 1.5);
    end;

    // anim flipped V
    50: begin
      MoveYRelative(Height*0.5, 1.5, idcSinusoid);
      FInverse.MoveYRelative(-Height, 1.5, idcSinusoid);
      PostMessage(55, 1.5);
    end;
    55: begin
      MoveYRelative(-Height*0.5, 1.5, idcSinusoid);
      FInverse.MoveYRelative(Height, 1.5, idcSinusoid);
      PostMessage(50, 1.5);
    end;
  end;
end;

{ TSeatWithCharacter }

procedure TSeatWithCharacter.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FArmrest.FlipH := AValue;
  if FSeatedCharacter <> NIL then
    FSeatedCharacter.FlipH := AValue;
end;

procedure TSeatWithCharacter.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FArmrest.FlipV := AValue;
  if FSeatedCharacter <> NIL then
    FSeatedCharacter.FlipV := AValue;
end;

class procedure TSeatWithCharacter.LoadTexture(aAtlas: TAtlas);
begin
  texSeat := aAtlas.AddFromSVG(FolderSpriteInSpace+'Seat.svg', ScaleW(120), -1);
  texSeatArmrest := aAtlas.AddFromSVG(FolderSpriteInSpace+'SeatArmrest.svg', ScaleW(69), -1);
end;

constructor TSeatWithCharacter.Create(aLayerIndex: integer);
begin
  inherited Create(texSeat, False);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);

  FArmrest := CreateSpriteChild(texSeatArmrest, False, 1);
  FArmrest.SetCoordinate(0.378*Width, 0.389*Height);
  FArmrest.ApplySymmetryWhenFlip := True;
end;

procedure TSeatWithCharacter.SetCharacter(aWolfCharacter: TWolf);
begin
  FSeatedCharacter := aWolfCharacter;
  FSeatedCharacter.SetChildOf(Self, 0);
  FSeatedCharacter.X.Value := Width*0.40;
  FSeatedCharacter.Y.Value := Height*0.60;
  FSeatedCharacter.State := wsSeatOnChair;
end;

procedure TSeatWithCharacter.RaiseCharacter(aLayerIndex: integer);
begin
  if FSeatedCharacter = NIL then exit;
  FSeatedCharacter.Y.Value := FSeatedCharacter.Y.Value + Height*0.20;
  if aLayerIndex <> -1 then FSeatedCharacter.MoveToLayer(aLayerIndex);
  FSeatedCharacter.Idle(True);
  FSeatedCharacter := NIL;
end;

procedure TSeatWithCharacter.ApplyTint(AValue: TBGRAPixel);
begin
  Tint.Value := AVAlue;
  FArmrest.Tint.Value := AVAlue;
end;

{ TMainBridgeBG }

procedure TMainBridgeBG.CreateAlertPanel(aTex: PTexture);
begin
  FDangerBG := TQuad4Color.Create(FScene);
  FDangerBG.SetChildOf(Self, 0);
  FDangerBG.SetSize(ScaleW(132), ScaleH(17));
  FDangerBG.SetCoordinate(ScaleW(445), ScaleH(133));
  FDangerBG.SetAllColorsTo(BGRA(239,48,54));

  FDangerLabel := TSprite.Create(aTex, False);
  FDangerLabel.SetChildOf(FDangerBG, 0);
  FDangerLabel.CenterOnParent;
  FDangerLabel.Blink(-1, 0.5, 0.5);
end;

constructor TMainBridgeBG.Create(aLayerIndex: integer);
begin
  inherited Create(texMainBridge, False);

  if aLayerIndex <> -1 then begin
    FScene.Add(Self, aLayerIndex);
    SetSize(FScene.Width+2, FScene.Height+2);
    CenterOnScene;
  end
  else SetSize(FScene.Width, FScene.Height);
  // screen 1
  TScreenAnim.Create(texScreen3, ScaleW(25), ScaleH(505), ScaleW(23), ScaleH(23), satRotate, aLayerIndex);
  // screen 3
  with TScreenAnim.Create(texScreen2, ScaleW(323), ScaleH(454), ScaleW(25), ScaleH(21), satFlipH, aLayerIndex) do
    Angle.Value := -2.7;
  // screen 5
  TScreenAnim.Create(texScreen1, ScaleW(588), ScaleH(448), ScaleW(40), ScaleH(15), satFlipV, aLayerIndex);
  // screen 6
  with TScreenAnim.Create(texScreen2, ScaleW(667), ScaleH(454), ScaleW(25), ScaleH(21), satFlipH, aLayerIndex) do
    Angle.Value := 2.7;
  // screen 7
  with TScreenAnim.Create(texScreen1, ScaleW(874), ScaleH(476), ScaleW(26), ScaleH(15), satFlipV, aLayerIndex) do
    Angle.Value := 17;
  // screen 2
  with TScreenAnimScrollingText.Create(texScreen4, ScaleW(153), ScaleH(470), ScaleW(35), ScaleH(29), aLayerIndex) do begin
    ScrollSpeed.Y.Value := FScene.Height*0.01;
    Angle.Value := -18;
    Tint.Value := BGRA(255,0,255,80);
  end;
  // screen 4
  with TScreenAnimScrollingText.Create(texScreen4, ScaleW(393), ScaleH(447), ScaleW(48), ScaleH(28), aLayerIndex) do
    ScrollSpeed.Y.Value := -FScene.Height*0.01;
end;

procedure TMainBridgeBG.ProcessMessage(UserValue: TUserMessageValue);
begin
{  case UserValue of
    // start interstellar jump
    0: begin
      if not FTravelling then exit;
      InterStellarJump.Visible := True;
      InterStellarJump.Opacity.Value := 0;
      InterStellarJump.Opacity.ChangeTo(255, 3.0);
      InterStellarJump.TrailLength.Value := 0.0;
      InterStellarJump.TrailLength.ChangeTo(1.0, 3.0, idcStartFastEndSlow);

      PostMessage(5, 3.0);
    end;
    5: begin
      if not FTravelling then exit;
      InterStellarJump.TrailLength.ChangeTo(0.8, 0.5);
      InterStellarJump.TimeAccu.AddConstant(1.2);
    end;

    // stop travelling
    50: begin
      //TrailLength.ChangeTo(0.0, 0.5);
      InterStellarJump.TimeAccu.AddConstant(-0.001);
      //InterStellarJump.TrailLength.Value := 0.0;
      InterStellarJump.TrailLength.ChangeTo(0.0, 0.75, idcStartSlowEndFast); // idcSinusoid);
      PostMessage(52, 0.75);
    end;
    52: begin
      InterStellarJump.Opacity.ChangeTo(0, 0.5);
      PostMessage(55, 0.5);
    end;
    55: begin
      InterStellarJump.Visible := False;
      InterStellarJump.Opacity.Value := 255;
      InterStellarJump.TrailLength.Value := 0.8;
      InterStellarJump.TimeAccu.Value := 0;
      FTravelling := False;
    end;
  end;  }
end;

procedure TMainBridgeBG.CreateDeskCenter(aLayerIndex: integer);
begin
  FDeskCenter := FScene.AddSprite(texDeskCenter, False, aLayerIndex);
  FDeskCenter.SetCoordinate(ScaleW(394), ScaleH(619));
end;

procedure TMainBridgeBG.CreateSeats(aLayerIndex: integer);
begin
  LeftSeat := TSeatWithCharacter.Create(aLayerIndex);
  LeftSeat.SetCoordinate(ScaleW(172), ScaleH(487));

  RightSeat := TSeatWithCharacter.Create(aLayerIndex);
  RightSeat.SetCoordinate(ScaleW(748), ScaleH(493));
  RightSeat.FlipH := True;
end;

class function TMainBridgeBG.GetMessFontDescriptor(const aMess: string
  ): TFontDescriptor;
begin
  Result.Create('Arial', 10, [], BGRA(0,0,0));
  Result.ComputeMaxHeightFor(aMess, Rect(0, 0, ScaleW(132), ScaleH(17)));
end;

procedure TMainBridgeBG.StartShield(aAtlas: TAtlas);
begin
  if FShield = NIL then begin
    FShield := TParticleEmitter.Create(FScene);
    FShield.SetChildOf(Self, -1);
    FShield.LoadFromFile(ParticleFolder+'WolfMotherShipShield.par', aAtlas);
    FShield.SetEmitterTypeRectangle(FScene.Width, ScaleH(365));
    FShield.SetCoordinate(0, ScaleH(103));
  end;
  FShield.ParticlesToEmit.Value := 1024;
end;

procedure TMainBridgeBG.StopShield;
begin
  if FShield <> NIL then
    FShield.ParticlesToEmit.Value := 0;
end;

procedure TMainBridgeBG.ShowAlert(aTex: PTexture);
begin
  KillAlert;
  CreateAlertPanel(aTex);
end;

procedure TMainBridgeBG.KillAlert;
begin
  if FDangerBG = NIL then exit;
  FDangerBG.Kill;
  FDangerBG := NIL;
end;

procedure TMainBridgeBG.ApplyTint(AValue: TBGRAPixel);
begin
  Tint.Value := AValue;
  if LeftSeat <> NIL then LeftSeat.ApplyTint(AValue);
  if RightSeat <> NIL then RightSeat.ApplyTint(AValue);
  if FDeskCenter <> NIL then FDeskCenter.Tint.Value := AValue;
end;

{ TConstructionUnit }

function TConstructionUnit.GetGaugePercent: Single;
begin
  Result := (FGaugeArrow.Angle.Value+128) / 256;
end;

procedure TConstructionUnit.SetGaugePercent(AValue: Single);
begin
  AValue := EnsureRange(AValue, 0, 1);
  FGaugeArrow.Angle.Value := AValue*256 - 128;
end;

procedure TConstructionUnit.ProcessButtonMouseEnter(Sender: TSimpleSurfaceWithEffect);
begin
  TUIButton(Sender).BodyShape.Border.Color := BGRA(255,255,0);
end;

procedure TConstructionUnit.ProcessButtonMouseLeave(Sender: TSimpleSurfaceWithEffect);
begin
  TUIButton(Sender).BodyShape.Border.Color := BGRA(0,0,0);
end;

procedure TConstructionUnit.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  TFallingItem.Create(Self, Sender.Tag1);
  HideMarcusDialog;
end;

procedure TConstructionUnit.CheckItemFalled(aIndex: integer);
begin
  if State <> cusConstructing then exit;

  if FConstructionItemIndexes[FConstructionItemIndex] = aIndex then begin
    Audio.PlayThenKillSound('ice-machine.ogg', 1.0);
    GaugePercent := 1.0;
    inc(FConstructionItemIndex);
    if FConstructionItemIndex = Length(FConstructionItemIndexes) then State := cusConstructionDone
      else ShowMarcusDialog(FConstructionItemIndexes[FConstructionItemIndex]);
  end else begin
    State := cusConstructionFailed;
  end;

end;

procedure TConstructionUnit.ShowMarcusDialog(aIndex: integer);
begin
  FMarcusDialog.Visible := True;
  FMarcusDialog.DeleteAllChilds;
  with TSprite.Create(texConsItems[aIndex], False) do begin
    SetChildOf(FMarcusDialog, 0);
    CenterX := FMarcusDialog.Width*0.5;
    CenterY := FMarcusDialog.Width*0.5;
  end;
end;

procedure TConstructionUnit.HideMarcusDialog;
begin
  FMarcusDialog.Visible := False;
  FMarcusDialog.DeleteAllChilds;
end;

procedure TConstructionUnit.SetState(AValue: TConstructionState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  case FState of
    cusConstructionDone: begin
      HideMarcusDialog;
      TCrate.Create(Self, FCrateLabel, FFontText);
      EnableButtons(False);
    end;
    cusConstructionFailed: begin
      Audio.PlayThenKillSound('water-steaming-on-hot-surface-1.ogg', 0.6);
      HideMarcusDialog;
      EnableButtons(False);
      FSmoke.ParticlesToEmit.Value := 558;
      FSmoke.ParticlesToEmit.ChangeTo(0, 3.5);
      FSmoke.LoopMode := True;
      GaugePercent := 0.0;
      //FSmoke.Shoot;
      FConveyor.Offset.x.AddConstant(0);
    end;
  end;
end;

procedure TConstructionUnit.EnableButtons(AValue: boolean);
var button: TUIButton;
begin
  for button in FButtons do
    button.MouseInteractionEnabled := AValue and button.Visible;
end;

procedure TConstructionUnit.StartConstruction(const aItemIndexes: TArrayOfInteger; aCrateLabel: string);
var i: integer;
begin
  if State = cusConstructing then exit;

  // check if there is no error in item listing
  for i:=0 to High(aItemIndexes) do
    if not FButtons[aItemIndexes[i]].Visible then
      raise exception.Create('item index '+aItemIndexes[i].ToString+' not available!');

  State := cusConstructing;
  FConstructionItemIndexes := aItemIndexes;
  FConstructionItemIndex := 0;
  EnableButtons(True);
  FConveyor.Offset.x.AddConstant(-100);
  GaugePercent := 1.0;
  ShowMarcusDialog(FConstructionItemIndexes[FConstructionItemIndex]);
  FCrateLabel := aCrateLabel;
end;

constructor TConstructionUnit.Create(aAtlas: TAtlas; aFontText: TTexturedFont;
  aLayerIndex: integer);
var o: TSprite;
  yy: single;
  i: integer;
begin
  inherited Create(texConsBG, False);
  if aLayerIndex <> -1 then begin
    FScene.Add(Self, aLayerIndex);
    SetSize(FScene.Width+2, FScene.Height+2);
    CenterOnScene;
  end
  else SetSize(FScene.Width, FScene.Height);

  FFontText := aFontText;

  FConveyor := TScrollableSprite.Create(texConsConveyor, True);   // False
  FConveyor.SetChildOf(Self, 0);
  FConveyor.SetCoordinate(ScaleW(709), ScaleH(698));
  FConveyor.Offset.x.AddConstant(-60);

  FMachine := TSprite.Create(texConsMachine, False);
  FMachine.SetChildOf(Self, 2);
  FMachine.SetCoordinate(ScaleW(267), ScaleH(386));

  FGaugeArrow := TSprite.Create(texConsGaugeArrow, False);
  FGaugeArrow.SetChildOf(FMachine, 0);
  FGaugeArrow.SetCoordinate(ScaleW(58), ScaleH(20));
  FGaugeArrow.Pivot := PointF(0.5, 1.0);

  FGaugeTime := 3.0;


  // smoke effect
  FSmoke := TParticleEmitter.Create(FScene);
  FSmoke.SetChildOf(Self, 1);
  FSmoke.LoadFromFile(ParticleFolder+'ConstructionUnitFailed.par', aAtlas);
  FSmoke.SetCoordinate(ScaleW(446), ScaleH(568));
  FSmoke.SetEmitterTypeLine(PointF(ScaleW(506), ScaleH(568)));


  // pipe
  o := TSprite.Create(texConsPipe, False);
  o.SetChildOf(Self, 2);
  o.SetCoordinate(ScaleW(415), ScaleH(0));
  // pipe BG
  o := TSprite.Create(texConsPipeBG, False);
  o.SetChildOf(Self, 0);
  o.SetCoordinate(ScaleW(415), ScaleH(108));

  FMarcusDialog := TSprite.Create(texConsMarcusDialog, False);
  FMarcusDialog.SetChildOf(Self, 0);
  FMarcusDialog.SetCoordinate(ScaleW(117), ScaleH(490));
  HideMarcusDialog;

  FCrate := TSprite.Create(texConsCrate, False);
  FCrate.SetChildOf(Self, 1);
  FCrate.SetCoordinate(ScaleW(566), ScaleH(603));

  yy := ScaleH(156-56);
  for i:=0 to 34 do begin
    if i mod 7 = 0 then yy := yy + ScaleH(59);
    FButtons[i] := TUIButton.Create(FScene, '', NIL, NIL);//texConsItems[i]);
    FButtons[i].AutoSize := False;
    FButtons[i].BodyShape.SetShapeRectangle(ScaleW(49), ScaleW(49), PPIScale(2));
    FButtons[i].SetChildOf(Self, 0);
    FButtons[i].ChildClippingEnabled := False;
    FButtons[i].BodyShape.Border.Color := BGRA(0,0,0);
    //FButtons[i].BodyShape.Fill.Color := BGRA(220,220,220);
    FButtons[i].BackGradient.CreateHorizontal([BGRA(100,50,255,100), BGRA(255,0,255,110), BGRA(50,0,255,100)],
                                              [0.0, 0.5, 1.0]);
    FButtons[i].BackGradient.Visible := True;
    FButtons[i].SetCoordinate(ScaleW(568)+(i mod 7)*ScaleW(59), yy);
    FButtons[i].Tag1 := i;
    FButtons[i].OnAnimMouseEnter := @ProcessButtonMouseEnter;
    FButtons[i].OnAnimMouseLeave := @ProcessButtonMouseLeave;
    FButtons[i].OnClick := @ProcessButtonClick;
    case PlayerInfo.InSpace.StepPlayed of
      2: FButtons[i].Visible := i < 14;
      5, 7: FButtons[i].Visible := (i < 14) or (i in [14, 17, 18, 21, 24, 25, 28, 31, 32]);

    end;
    o := TSprite.Create(texConsItems[i], False);
    o.SetChildOf(FButtons[i], 0);
    if o.Width > o.Height then o.SetSize(FButtons[i].Width-2, -1)
      else o.SetSize(-1, FButtons[i].Height-2);
    o.CenterOnParent;
  end;
  EnableButtons(False);

  // screen 4
  with TScreenAnimScrollingText.Create(texScreen4, ScaleW(108), ScaleH(612), ScaleW(128), ScaleH(58), aLayerIndex) do begin
    ScrollSpeed.Y.Value := -FScene.Height*0.01;
    Angle.Value := 2;
  end;
end;

procedure TConstructionUnit.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if State = cusConstructing then begin
    GaugePercent := GaugePercent - aElapsedTime/FGaugeTime;
    if GaugePercent = 0 then State := cusConstructionFailed;
  end;
end;

{ TConstructionUnit.TFallingItem }

constructor TConstructionUnit.TFallingItem.Create(aParent: TConstructionUnit;
  aIndex: integer);
begin
  inherited Create(texConsItems[aIndex], False);
  SetChildOf(aParent, 1);
  CenterX := ScaleW(474);
  BottomY := ScaleH(100);
  Speed.Y.ChangeTo(FScene.Height, 0.5, idcDrop);
  Tag1 := aIndex;
end;

procedure TConstructionUnit.TFallingItem.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  // check end of fall
  if Y.Value > ScaleH(567) then begin
    TConstructionUnit(ParentSurface).CheckItemFalled(Tag1);
    Kill;
  end;
end;

{ TConstructionUnit.TCrate }

constructor TConstructionUnit.TCrate.Create(aParent: TConstructionUnit;
  const aCrateLabel: string; aFontText: TTexturedFont);
begin
  inherited Create(texConsCrate, False);
  SetChildOf(aParent, 1);
  SetCoordinate(ScaleW(578), ScaleH(603));
  Speed.x.Value := 100;
  KillDefered((FScene.Width-X.Value)/100); // 100pixel/s is the speed of the conveyor

  with TFreeText.Create(FScene) do begin
    SetChildOf(Self, 0);
    TexturedFont := aFontText;
    Caption := aCrateLabel;
    CenterX := Self.Width*0.60;
    CenterY := Self.Height*0.55;
    Tint.Value := BGRA(0,0,0);
    Scale.Value := PointF(1.5, 1.5);
  end;
  Audio.PlayThenKillSound('digital-machine-grunt-1_4.ogg', 1.0);
end;

{ TScrollingStars2D }

constructor TScrollingStars2D.Create(aLayerIndex: integer;
  aPlane1Count: integer; aPlane2Count: integer; aPlane3Count: integer);
var i: integer;
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);

  FArea := Rect(-texScrollingStar2D^.FrameWidth, -texScrollingStar2D^.FrameWidth,
                FScene.Width+texScrollingStar2D^.FrameWidth,
                FScene.Height+texScrollingStar2D^.FrameWidth);

  FSizeStar1 := texScrollingStar2D^.FrameWidth;
  FSizeStar2 := Round(FSizeStar1*0.625);
  FSizeStar3 := Round(FSizeStar1*0.33);

  for i:=0 to aPlane1Count-1 do
    with TSingleStar2D.Create(texScrollingStar2D, False) do begin
      SetChildOf(Self, 0);
      SetCoordinate(Random*FArea.Width+FArea.Left, Random*FArea.Height+FArea.Top);
      SpeedCoeff := 1.0+Random*0.4-0.2;
    end;

  for i:=0 to aPlane2Count-1 do
    with TSingleStar2D.Create(texScrollingStar2D, False) do begin
      SetChildOf(Self, -1);
      SetSize(FSizeStar2, FSizeStar2);
      SetCoordinate(Random*FArea.Width+FArea.Left, Random*FArea.Height+FArea.Top);
      SpeedCoeff := 0.625+Random*0.2-0.1;
    end;

  for i:=0 to aPlane3Count-1 do
    with TSingleStar2D.Create(texScrollingStar2D, False) do begin
      SetChildOf(Self, -2);
      SetSize(FSizeStar3, FSizeStar3);
      SetCoordinate(Random*FArea.Width+FArea.Left, Random*FArea.Height+FArea.Top);
      SpeedCoeff := 0.25+Random*0.06-0.03;
    end;

  ScrollingSpeed := TPointFParam.Create;
end;

destructor TScrollingStars2D.Destroy;
begin
  FreeAndNil(ScrollingSpeed);
  inherited Destroy;
end;

procedure TScrollingStars2D.Update(const aElapsedTime: single);
var i: integer;
  o: TSingleStar2D;
  p: TPointF;
begin
  inherited Update(aElapsedTime);

  ScrollingSpeed.OnElapse(aElapsedTime);
  if ScrollingSpeed.Value.IsZero then exit;

  for i:=0 to ChildCount-1 do begin
    o := Childs[i] as TSingleStar2D;
    p := o.GetXY + ScrollingSpeed.Value * aElapsedTime * o.SpeedCoeff;
    if p.x > FArea.Right-o.Width then p.x := FArea.Left
    else
    if p.x < FArea.Left then p.x := FArea.Right-o.Width;

    if p.y > FArea.Bottom-o.Height then p.y := FArea.Top
    else
    if p.y < FArea.Top then p.y := FArea.Bottom-o.Height;

    o.SetCoordinate(p);
  end;
end;

{ TStarsBG }

function TStarsBG.GetStarnest: TStarNest;
begin
  if FStarnest = NIL then begin
    FStarnestRenderer := TStarNestRenderer.Create(FScene, True);
    FStarnest := TStarNest.Create(FScene, FStarnestRenderer);
    FStarnest.SetChildOf(Self, 0);
    FStarnest.SetSize(FScene.Width, FScene.Height);
    FStarnest.SetCoordinate(0, 0);
    FStarnest.LoadParamsFromString(STARNEST_SIMPLEHOT);
    FStarnest.OpacityThreshold := 1.0;
  end;
  Result := FStarnest;
end;

function TStarsBG.GetScrollingStars2D: TScrollingStars2D;
begin
  if FScrollingStars2D = NIL then begin
    FScrollingStars2D := TScrollingStars2D.Create(-1);
    FScrollingStars2D.SetChildOf(Self, 1);
  end;
  Result := FScrollingStars2D;
end;

function TStarsBG.GetStarJump: TStarJump;
begin
  if FStarJump = NIL then begin
  FStarJumpRenderer := TStarJumpRenderer.Create(FScene, True);
  FStarJump := TStarJump.Create(FScene, FStarJumpRenderer);
  FStarJump.SetChildOf(Self, 2);
  FStarJump.SetSize(FScene.Width, FScene.Height);
  FStarJump.SetCoordinate(0, 0);
  end;
  Result := FStarJump;
end;

function TStarsBG.GetInterstellarJump: TInterstellarJump;
begin
  if FInterstellarJump = NIL then begin
    FInterstellarJumpRenderer := TInterStellarJumpRenderer.Create(FScene, True);
    FInterstellarJump := TInterstellarJump.Create(FScene, FInterstellarJumpRenderer);
    FInterstellarJump.SetChildOf(Self, 2);
    FInterstellarJump.SetSize(FScene.Width, FScene.Height);
    FInterstellarJump.SetCoordinate(0, 0);
  end;
  Result := FInterstellarJump;
end;

constructor TStarsBG.Create(aLayerIndex: integer);
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
end;

destructor TStarsBG.Destroy;
begin
  FreeAndNil(FStarnestRenderer);
  FreeAndNil(FInterstellarJumpRenderer);
  FreeAndNil(FStarJumpRenderer);
  inherited Destroy;
end;

procedure TStarsBG.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // start interstellar jump
    0: begin
      if not FJumping then exit;
      InterStellarJump.Visible := True;
      InterStellarJump.Opacity.Value := 0;
      InterStellarJump.Opacity.ChangeTo(255, 3.0);
      InterStellarJump.TrailLength.Value := 0.0;
      InterStellarJump.TrailLength.ChangeTo(1.0, 3.0, idcStartFastEndSlow);

      PostMessage(5, 3.0);
    end;
    5: begin
      if not FJumping then exit;
      InterStellarJump.TrailLength.ChangeTo(0.8, 0.5);
      InterStellarJump.ZSpeed.Value := 1.2;
    end;

    // stop interstellar jump
    50: begin
      if FJumping then exit;
      //TrailLength.ChangeTo(0.0, 0.5);
      InterStellarJump.ZSpeed.ChangeTo(0, 0.75, idcSinusoid);
      //InterStellarJump.TrailLength.Value := 0.0;
     // InterStellarJump.TrailLength.ChangeTo(0.0, 0.75, idcStartSlowEndFast); // idcSinusoid);
      PostMessage(53, 0.75);
    end;
    52: begin
      InterStellarJump.TrailLength.ChangeTo(0.0, 0.75, idcStartSlowEndFast);
      InterStellarJump.ZSpeed.ChangeTo(-1, 0.75, idcStartSlowEndFast);
      PostMessage(53, 0.75);
    end;
    53: begin
      if FJumping then exit;
      InterStellarJump.ZSpeed.Value := 0;
      InterStellarJump.Opacity.ChangeTo(0, 0.25);
      PostMessage(55, 0.25);
    end;
    55: begin
      if FJumping then exit;
      InterStellarJump.Visible := False;
      InterStellarJump.Opacity.Value := 255;
      InterStellarJump.TrailLength.Value := 0.8;
      InterStellarJump.ZSpeed.Value := 0;
    end;
  end;
end;

procedure TStarsBG.EnterInterstellarJump;
begin
  if FJumping then exit;
  FJumping := True;
  PostMessage(0);
end;

procedure TStarsBG.ExitInterstellarJump;
begin
  if not FJumping then exit;
  FJumping := False;
  PostMessage(50);
end;

{ TAsteroidBeltViewFromShip }

constructor TAsteroidBeltViewFromShip.Create(aLayerIndex: integer);
var o: TSprite;
  i, k: Integer;
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  SetCoordinate(-FScene.Width*1.5, -FScene.Height);
  ChildsUseParentOpacity := True;

  k := 0;
  for i:=0 to 1000 do begin
    case k of
      0: o := TSprite.Create(texAsteroid1, False);
      1: o := TSprite.Create(texAsteroid2, False);
      2: o := TSprite.Create(texAsteroid3, False);
      3: o := TSprite.Create(texAsteroid4, False);
    end;
    o.SetChildOf(Self, Random(21)-10);
    o.SetCenterCoordinate(Random*FScene.Width*4, Random*FScene.Height*2);
    o.Angle.Value := Random*360;
    o.Angle.AddConstant(Random*25-12.5);
    o.Scale.Value := PointF(1+Random*0.5-0.25, 1+Random*0.5-0.25);
    if k < 3 then inc(k) else k := 0;
  end;

  k := 0;
  for i:=0 to 400 do begin
    case k of
      0: o := TSprite.Create(texAsteroid1, False);
      1: o := TSprite.Create(texAsteroid2, False);
      2: o := TSprite.Create(texAsteroid3, False);
      3: o := TSprite.Create(texAsteroid4, False);
    end;
    o.SetChildOf(Self, -Random(10)-11);
    o.SetCenterCoordinate(Random*FScene.Width+FScene.Width*1.5, Random*FScene.Height+FScene.Height*0.75);
    o.Angle.Value := Random*360;
    o.Angle.AddConstant(Random*20-10);
    o.Scale.Value := PointF(0.2+Random*0.2, 0.2+Random*0.2);
    if k < 3 then inc(k) else k := 0;
    //o.Tint.Value := BGRA(255,0,255);
  end;
end;



{ THyperSpaceGate }

constructor THyperSpaceGate.Create(aCenterX, aCenterY: single; aLayerIndex: integer; aAtlas: TAtlas);
begin
  inherited Create(texHyperSpaceGate, False);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  SetCenterCoordinate(aCenterX, aCenterY);
  Scale.Value := PointF(1.5, 1.5);

  FRing2 := TSprite.Create(texHyperSpaceGate, False);
  FRing2.SetChildOf(Self, 0);
  FRing2.CenterOnParent;
  FRing2.Scale.Value := PointF(1.25, 1.25);
  FRing2.Angle.Value := 20;
{  FRing2 := TSprite.Create(texHyperSpaceGate, False);
  FScene.Add(FRing2, aLayerIndex);
  FRing2.SetCenterCoordinate(aCenterX, aCenterY);
  FRing2.Scale.Value := PointF(1.25, 1.25);   }


  FGlow := TOGLCGlow.Create(FScene);
  FGlow.SetChildOf(Self, 0);
  FGlow.SetRadius(ScaledWidth*0.5, ScaledHeight*0.5);
  FGlow.CenterOnParent;
  FGlow.SetAllColorsTo(BGRA(40,107,17));
  FGlow.Power.Value := 0.940;
{  FGlow := TOGLCGlow.Create(FScene);
  FScene.Add(FGlow, aLayerIndex);
  FGlow.SetRadius(ScaledWidth*0.5, ScaledHeight*0.5);
  FGlow.SetCenterCoordinate(aCenterX, aCenterY);
  FGlow.SetAllColorsTo(BGRA(40,107,17));
  FGlow.Power.Value := 0.940;  }

  FParticles := TParticleEmitter.Create(FScene);
  FParticles.SetChildOf(Self, 0);
  FParticles.LoadFromFile(ParticleFolder+'HyperSpaceGate.par', aAtlas);
  FParticles.SetEmitterTypeInnerCircle(Width*0.5);
  FParticles.SetCoordinate(Width*0.5, Height*0.5);
  FParticles.LoopMode := False;
  FParticles.ParticlesToEmit.Value := Width/200*300;
  FParticles.FParticleParam.Life := (Width*0.5)/200*2;

  FAV := TFParam.Create;
  FSize := TFParam.Create;
end;

destructor THyperSpaceGate.Destroy;
begin
  FreeAndNil(FAV);
  FreeAndNil(FSize);
  inherited Destroy;
end;

procedure THyperSpaceGate.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  FAV.OnElapse(aElapsedTime);
  FSize.OnElapse(aElapsedTime);
end;

procedure THyperSpaceGate.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue Of
    0: FDone := True;

    200: begin
      FParticles.FParticleParam.AVelocity := FAV.Value;
      FParticles.FParticleParam.Size := FSize.Value;
      PostMessage(200);
    end;
  end;
end;

procedure THyperSpaceGate.StartRotate;
begin
  Angle.AddConstant(5);
  FRing2.Angle.AddConstant(-10);
end;

procedure THyperSpaceGate.OpenPhase1(aDuration: single);
begin
  PostMessage(200); // updates particle params
  FParticles.LoopMode := True;
  FParticles.FParticleParam.Velocity := Width*0.5;
  FSize.Value := 0;
  FAV.Value := 0;
  FSize.ChangeTo(0.26, aDuration);
  FDone := False;
  PostMessage(0, aDuration);
end;

procedure THyperSpaceGate.OpenPhase2(aDuration: single);
begin
  FSize.ChangeTo(0.95, aDuration);
  FDone := False;
  PostMessage(0, aDuration);
end;

procedure THyperSpaceGate.OpenPhase3(aDuration: single);
begin
  FSize.ChangeTo(4.0, aDuration);
  FDone := False;
  PostMessage(0, aDuration);
end;

procedure THyperSpaceGate.OpenPhase4(aDuration: single);
begin
  FAV.ChangeTo(160, aDuration);
  FDone := False;
  PostMessage(0, aDuration);
end;

{ TMotherShipDockingBay }

class procedure TMotherShipDockingBay.LoadTexture(aAtlas: TOGLCTextureAtlas);
var path: String;
begin
  path := FolderSpriteWolfCastle;
  texMotherShipDockBody := aAtlas.AddFromSVG(path+'MotherShipDockBody.svg', -1, ScaleH(77));
  texMotherShipDockBG := aAtlas.AddFromSVG(path+'MotherShipDockBG.svg', ScaleW(48), -1);
  texMotherShipDockFlare := aAtlas.AddFromSVG(path+'MotherShipDockFlare.svg', ScaleW(5), -1);
end;

constructor TMotherShipDockingBay.Create(aLayerIndex: integer);
begin
  inherited Create(texMotherShipDockBody, False);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);

  BG := TSprite.Create(texMotherShipDockBG, False);
  with BG do begin
    SetChildOf(Self, -3);
    SetCoordinate(0, 0.926*Self.Height);
  end;

  FlareLeft := TSprite.Create(texMotherShipDockFlare, False);
  with FlareLeft do begin
    SetChildOf(Self, -2);
    SetCoordinate(0.279*Self.Width, 0.971*Self.Height);
    Visible := False;
  end;

  FlareRight := TSprite.Create(texMotherShipDockFlare, False);
  with FlareRight do begin
    SetChildOf(Self, -2);
    SetCoordinate(0.617*Self.Width, 0.971*Self.Height);
  end;

  PostMessage(0); // flare blink anim
end;

procedure TMotherShipDockingBay.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // flare blink anim
    0: begin
      FlareLeft.Visible := False;
      FlareRight.Visible := True;
      PostMessage(5, 1.0);
    end;
    5: begin
      FlareLeft.Visible := True;
      FlareRight.Visible := False;
      PostMessage(0, 1.0);
    end;
  end;//case
end;

{ TBaseLittleShip }

procedure TBaseLittleShip.SetVelocity(AValue: single);
begin
  AValue := EnsureRange(AValue, 0, FVelocityMax);
  if FVelocity.Value = AValue then Exit;
  FVelocity.Value := AValue;
end;

function TBaseLittleShip.GetVelocity: single;
begin
  Result := FVelocity.Value;
end;

constructor TBaseLittleShip.Create(ATexture: PTexture; Owner: boolean;
  aAtlas: TAtlas; aUseSound: boolean);
begin
  inherited Create(ATexture, Owner);

  FPE := TParticleEmitter.Create(FScene);
  FPE.SetChildOf(Self, -1);
  FPE.LoadFromFile(ParticleFolder+'LittleShipFlame.par', aAtlas);
  FPE.SetCoordinate(0, Height*0.5);
  FPE.ParticlesToEmit.Value := 0;

  if aUseSound then begin
    FsndPropulsor := Audio.AddSound('BlowtorchLoop.ogg', 0.6, True);
  end else FsndPropulsor := NIL;

  FVelocity := TFParam.Create;
end;

procedure TBaseLittleShip.SetVelocityConstant(aVelocityMax, aTurnAngleAmount,
  aAccelerateAmount, aDecelerateAmount: single);
begin
  FVelocityMax := aVelocityMax;
  FTurnAngle := aTurnAngleAmount;
  FAccelerateAmount := aAccelerateAmount;
  FDecelerateAmount := aDecelerateAmount;
end;

destructor TBaseLittleShip.Destroy;
begin
  FPath.Free;
  FVelocity.Free;
  if FsndPropulsor <> NIL then FsndPropulsor.Kill;
  FsndPropulsor := NIL;
  inherited Destroy;
end;

procedure TBaseLittleShip.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  FVelocity.OnElapse(aElapsedTime);
  if FFollowingPath then
    FPath.Update(aElapsedTime)
  else
  if FManualDrive and (FVelocity.Value <> 0.0) then begin
    X.Value := X.Value + cos(Deg2Rad*Angle.Value)*FVelocity.Value;
    Y.Value := Y.Value + sin(Deg2Rad*Angle.Value)*FVelocity.Value;
  end;
end;

procedure TBaseLittleShip.ProcessMessage(UserValue: TUserMessageValue);
var path: TOGLCPath;
  procedure ApplyAngleAndPos;
  var pos: TPointF;
    a: single;
  begin
    FPath.GetPosAndAngle(pos, a);
    Angle.Value := a;
    SetCenterCoordinate(pos);
  end;
begin
  case UserValue of
    // anim exit docking bay
    0: begin
      Angle.Value := 90;
      MoveYRelative(Height*1.5,  3.5, idcSinusoid);
      PostMessage(5, 3.5);
    end;
    5: begin
      SetZOrder(1);
      FAnimDone := True;
    end;

    // Exit From Docking Bay, Run Path
    50: begin
      Angle.Value := 90;
      Y.ChangeTo(Y.Value + Height*1.5,  2.5);
      //MoveYRelative(Height*1.5,  3.5);
      PostMessage(55, 2.5);
    end;
    55: begin // load and translate the path
      SetZOrder(1);
      path := NIL;
      path.LoadFromNormalizedFileAndExpand(FPathFilename, FScene.Width, FScene.Height);
      path.Translate(PointF(-path[0].x, -path[0].y) + Center);
      path.ConvertToSpline(ssCrossingWithEnds);
      FPath.InitFrom(path, False);

      FFollowingPath := True;
      FPath.Speed.Value := PPIScale(400)/5;
      FPath.Speed.ChangeTo(PPIScale(400), 3.0, idcDrop);
      StartPropulsor;
      PostMessage(60);
    end;
    60: begin   // run the path and decelerate near the end
      ApplyAngleAndPos;
      if FPath.DistanceTravelled > FPath.PathLength*0.8 then begin
        FPath.Speed.ChangeTo(FPath.Speed.Value/7, 1.0); // descelerate
        StopPropulsor;
        PostMessage(63);
      end else PostMessage(60);
    end;
    63: begin // wait the ship reach the end of the path
      ApplyAngleAndPos;
      if FPath.DistanceTravelled = FPath.PathLength then begin
        FFollowingPath := False;
        PostMessage(65);
      end else PostMessage(63);
    end;
    65: begin
      FFollowingPath := False;
      ApplyAngleAndPos;
      SetZOrder(1);
      FAnimDone := True;
    end;


    // Exit From Docking Bay, Run Path, Enter Docking Bay
    100: begin   // exit docking bay
      Angle.Value := 90;
      Y.ChangeTo(Y.Value + Height*1.5,  2.5);
      //MoveYRelative(Height*1.5,  3.5);
      PostMessage(105, 2.5);
    end;
    105: begin  // load and translate the path
      SetZOrder(1);
      path := NIL;
      path.LoadFromNormalizedFileAndExpand(FPathFilename, FScene.Width, FScene.Height);
      path.Translate(PointF(-path[0].x, -path[0].y) + Center);
      path.ConvertToSpline(ssCrossingWithEnds);
      FPath.InitFrom(path, False);

      FFollowingPath := True;
      FPath.Speed.Value := PPIScale(400)/5;
      FPath.Speed.ChangeTo(PPIScale(400), 3.0, idcDrop);
      StartPropulsor;
      PostMessage(110);
    end;
    110: begin
      ApplyAngleAndPos;
      if FPath.DistanceTravelled > FPath.PathLength*0.8 then begin
        FPath.Speed.ChangeTo(FPath.Speed.Value/7, 4.0); // descelerate
        PostMessage(113);
      end else PostMessage(110);
    end;
    113: begin  // wait the ship reach the end of the path
      ApplyAngleAndPos;
      if FPath.DistanceTravelled = FPath.PathLength then begin
        FFollowingPath := False;
        StopPropulsor;
        PostMessage(115);
      end else PostMessage(113);
    end;
    115: begin  // ship enter docking bay + anim done
      SetZOrder(-1);
      FFollowingPath := False;
      ApplyAngleAndPos;
      Y.ChangeTo(Y.Value - Height*1.5,  2.5);
      PostMessage(120, 2.5);
    end;
    120: FAnimDone := True;

    // ship enter the docking bay (after a manual fly)
    200: begin
      SetZOrder(-1);
      MoveXCenterTo(ParentDockingBay.Width*0.5, 1.0, idcSinusoid);
      Angle.Value := KeepAngleInRange360(Angle.Value);
      Angle.ChangeTo(270, 1.0, idcSinusoid);
      Y.ChangeTo(ParentDockingBay.Height*0.4, 2.5, idcSinusoid);
      PostMessage(205, 2.5);
    end;
    205: begin
      Angle.Value := 90;
      FAnimDone := True;
    end;
  end;
end;

function TBaseLittleShip.GetCenterInWorldCoor: TPointF;
begin
  Result := SurfaceToWorld(PointF(Width*0.5, Height*0.5));
end;

procedure TBaseLittleShip.StartPropulsor;
begin
  if (FsndPropulsor <> NIL) and (FsndPropulsor.State <> ALS_PLAYING) then FsndPropulsor.Play(True);
  FPE.ParticlesToEmit.Value := 50;
end;

procedure TBaseLittleShip.StopPropulsor;
begin
  if FsndPropulsor <> NIL then FsndPropulsor.Stop;
  FPE.ParticlesToEmit.Value := 0;
end;

procedure TBaseLittleShip.ExitFromDockingBay;
begin
  FAnimDone := False;
  FManualDrive := False;
  PostMessage(0);
end;

procedure TBaseLittleShip.ExitFromDockingBay_RunPath(const aPathFilename: string);
begin
  FAnimDone := False;
  FManualDrive := False;
  FPathFilename := aPathFilename;
  PostMessage(50);
end;

procedure TBaseLittleShip.ExitFromDockingBay_RunPath_EnterDockingBay(const aPathFilename: string);
begin
  FAnimDone := False;
  FManualDrive := False;
  FPathFilename := aPathFilename;
  PostMessage(100);
end;

procedure TBaseLittleShip.EnterDockingBay;
begin
  FAnimDone := False;
  FManualDrive := False;
  PostMessage(200);
end;

procedure TBaseLittleShip.SetManualDrive;
begin
  FManualDrive := True;
  FFollowingPath := False;
end;

procedure TBaseLittleShip.TurnLeft(const aElapsedTime: single);
begin
  Angle.Value := Angle.Value - FTurnAngle*aElapsedTime;
end;

procedure TBaseLittleShip.TurnRight(const aElapsedTime: single);
begin
  Angle.Value := Angle.Value + FTurnAngle*aElapsedTime;
end;

procedure TBaseLittleShip.Accelerate(const aElapsedTime: single);
begin
  if FVelocity.State <> psNO_CHANGE then exit;
  Velocity := Velocity + FAccelerateAmount*aElapsedTime;
end;

procedure TBaseLittleShip.Decelerate(const aElapsedTime: single);
begin
  if FVelocity.State <> psNO_CHANGE then exit;
  Velocity := Velocity - FDecelerateAmount*aElapsedTime;
end;

function TBaseLittleShip.ParamsAreOkToDock: boolean;
begin
  Result := InRange(KeepAngleInRange360(Angle.Value), 260, 280) and
            (FVelocity.Value < FVelocityMax*0.3) and
            InRange(CenterX, ParentDockingBay.Width*0.35, ParentDockingBay.Width*0.65) and
            InRange(Y.Value, ParentDockingBay.Height*1.1, ParentDockingBay.Height*1.5);
end;

procedure TBaseLittleShip.Bump;
begin
  if FVelocity.Value <> 0 then FVelocity.Value := Min(-FVelocity.Value, -FVelocityMax*0.5)
    else FVelocity.Value := -FVelocityMax*0.5;
  FVelocity.ChangeTo(0, 1.0, idcStartFastEndSlow);
end;

procedure TBaseLittleShip.MoveLeft(const aElapsedTime: single);
begin
  X.Value := X.Value - FVelocityMax*50*aElapsedTime;
end;

procedure TBaseLittleShip.MoveRight(const aElapsedTime: single);
begin
  X.Value := X.Value + FVelocityMax*50*aElapsedTime;
end;

procedure TBaseLittleShip.MoveUp(const aElapsedTime: single);
begin
  Y.Value := Y.Value - FVelocityMax*50*aElapsedTime;
end;

procedure TBaseLittleShip.MoveDown(const aElapsedTime: single);
begin
 Y.Value := Y.Value + FVelocityMax*50*aElapsedTime;
end;

{ TMiningShip }

constructor TMiningShip.Create(aAtlas: TAtlas; aUseSound: boolean);
begin
  inherited Create(texMiningShip, False, aAtlas, True);
  SetVelocityConstant(PPIScale(5), 90, PPIScale(1)*0.75, PPIScale(3));
  // Collision body
  CollisionBody.AddPolygon([PointF(0.917*Width, 0.633*Height), PointF(0.946*Width, 0.497*Height),
      PointF(0.922*Width, 0.370*Height), PointF(0.746*Width, 0.292*Height),
      PointF(0.661*Width, 0.061*Height), PointF(0.298*Width, 0.020*Height),
      PointF(0.002*Width, 0.491*Height), PointF(0.298*Width, 0.983*Height),
      PointF(0.666*Width, 0.942*Height), PointF(0.746*Width, 0.702*Height),
      PointF(0.917*Width, 0.633*Height)]);

  // harvesting effect
  FPEHarvesting := TParticleEmitter.Create(FScene);
  FPEHarvesting.SetChildOf(Self, -1);
  FPEHarvesting.LoadFromFile(ParticleFolder+'MiningShipHarvesting.par', aAtlas);
  FPEHarvesting.SetCoordinate(Width, Height*0.5);
  FPEHarvesting.LoopMode := False;
end;

procedure TMiningShip.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // end of harvesting anim
    1000: begin
      FsndHarvesting.FadeOutThenKill(3.0);
      FsndHarvesting := NIL;
      FPEHarvesting.LoopMode := False;
      FAnimDone := True;
    end;
  end;
end;

procedure TMiningShip.StartHarvesting;
begin
  if FsndHarvesting = NIL then begin
    FsndHarvesting := Audio.AddSound('laser-weapon-sounds.ogg', 0.75, True);
    FsndHarvesting.SetLoopBounds(2.241, FsndHarvesting.TotalDuration);
  end;
  FsndHarvesting.Play(True);
  FAnimDone := False;
  FPEHarvesting.LoopMode := True;
  PostMessage(1000, 6.0);
end;

{ TCombatShip }

procedure TCombatShip.ComputeBulletInfos;
const _ANGLE:array[0..4] of single=(33, 45, 64, 67, 75);
var j: integer;
  procedure DoCompute(aInfoIndex: integer; aSpreadAngle: single);
  var polar: TPolarCoor;
    i, shootCount: integer;
    deltaAngle: single;
    p: TPointF;
  begin
    polar.Distance := Height*0.77;
    shootCount := Length(FBulletInfo[aInfoIndex]);

    polar.Angle := 270 - aSpreadAngle*0.5;
    deltaAngle := aSpreadAngle/(shootCount-1);
    p := PointF(0, 0);
    i := 0;
    while shootCount > 0 do begin
      FBulletInfo[aInfoIndex][i].pos := PolarToCartesian(p, polar);
      FBulletInfo[aInfoIndex][i].angle := polar.Angle;
      polar.Angle := polar.Angle + deltaAngle;
      dec(shootCount);
      inc(i);
    end;
  end;
begin
  for j:=0 to 4 do begin
    SetLength(FBulletInfo[j], j+2);
    DoCompute(j, _ANGLE[j]);
  end;

  FBulletInfo[0,0].angle := 270;
  FBulletInfo[0,1].angle := 270;
end;

constructor TCombatShip.Create(aAtlas: TAtlas; aUseSound: boolean);
begin
  inherited Create(texRedCombatShip, False, aAtlas, aUseSound);
  SetVelocityConstant(PPIScale(5), 120, PPIScale(1)*0.85, PPIScale(3));

  FShootLevelIndex := 0;

  ComputeBulletInfos;

  // Collision body
  CollisionBody.AddPolygon([PointF(0.298*Width, 0.001*Height), PointF(0.180*Width, 0.136*Height),
    PointF(0.205*Width, 0.266*Height), PointF(-0.008*Width, 0.501*Height),
    PointF(0.223*Width, 0.741*Height), PointF(0.155*Width, 0.871*Height),
    PointF(0.298*Width, 1.006*Height), PointF(0.455*Width, 0.886*Height),
    PointF(0.580*Width, 0.661*Height), PointF(0.998*Width, 0.536*Height),
    PointF(0.992*Width, 0.466*Height), PointF(0.567*Width, 0.331*Height),
    PointF(0.467*Width, 0.121*Height), PointF(0.298*Width, 0.001*Height)]);
end;

procedure TCombatShip.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  FShootDelayRemain := FShootDelayRemain - aElapsedTime;
  if FShootDelayRemain < 0 then FShootDelayRemain := 0;
end;

procedure TCombatShip.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // hit animation
    1000: begin
      PostMessage(1010);
      PostMessage(1005, 6.0);
    end;
    1005: begin
      Invincible := False;
      Tint.Alpha.Value := 0;
    end;
    1010: begin
      if not Invincible then exit;
      Tint.Value := BGRA(255,255,0);
      PostMessage(1015, 0.25)
    end;
    1015: begin
      if not Invincible then exit;
      Tint.Alpha.Value := 0;
      PostMessage(1010, 0.25)
    end;
  end;
end;

procedure TCombatShip.Shoot;
var i: integer;
  p: TPointF;
begin
  if FShootDelayRemain > 0 then exit;
{  case FShootLevelIndex of
    0: FShootDelayRemain := 0.2;
    1: FShootDelayRemain := 0.2;
    2: FShootDelayRemain := 0.21;
    3: FShootDelayRemain := 0.22;
    4: FShootDelayRemain := 0.25;
  end;  }
  FShootDelayRemain :=0.15;
  Audio.PlayThenKillSound('pulse-laser.ogg', 1.2);

  p := Center;
  for i:=0 to High(FBulletInfo[FShootLevelIndex]) do
    TShoot.Create(p + FBulletInfo[FShootLevelIndex][i].pos, FBulletInfo[FShootLevelIndex][i].angle, FOnBulletCheckCollision);
end;

procedure TCombatShip.UpgradeWeapon;
begin
  if FShootLevelIndex < LASER_MAXINDEX then inc(FShootLevelIndex)
  else begin
    // add a bomb
  end;
end;

procedure TCombatShip.Hit;
begin
  //if FShootLevelIndex > 0 then dec(FShootLevelIndex);
  Invincible := True;
  PostMessage(1000)
end;

{ TCombatShip.TShoot }

constructor TCombatShip.TShoot.Create(aCenter: TPointF; aAngle: single;
  aOnBulletCheckCollision: TOnBulletCheckCollision);
var s, c: single;
begin
  inherited Create(texRedCombatShipShoot, False);
  FScene.Add(Self, LAYER_ARROW);

  //aAngle := aAngle + 90;
  Angle.Value := aAngle + 90;
  SetCenterCoordinate(aCenter);

  FOnBulletCheckCollision := aOnBulletCheckCollision;
  SinCos(Deg2Rad*aAngle, s, c);
  Speed.x.Value := c*FScene.Height;
  Speed.y.Value := s*FScene.Height;

  FDelayCheckCollision := 5;

 { CollisionBody.AddPoint(PointF(0, 0));
  CollisionBody.AddPoint(PointF(Width, 0));
  CollisionBody.AddPoint(PointF(Width*0.5, Height)); }
end;

procedure TCombatShip.TShoot.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  // kill the sprite when it exit the scene
  if (BottomY < 0) or (X.Value > FScene.Width) or (RightX < 0) then begin
    Kill;
    exit;
  end;

  // check collision with other objects
  dec(FDelayCheckCollision);
  if FDelayCheckCollision > 0 then exit;
  FDelayCheckCollision := 5;
  FOnBulletCheckCollision(Self);
end;

{ TRadioMessage }

procedure TRadioMessage.InsertMessage(aMess: TMess);
var i: integer;
begin
  Audio.PlayThenKillSound('button-beep_Short.ogg', 0.8);
  for i:=0 to ChildCount-1 do
    if Childs[i] is TMess then
      Childs[i].Y.Value := Childs[i].Y.Value - aMess.Height - PPIScale(10);
  aMess.SetChildOf(Self, 0);
  aMess.Y.Value := -aMess.Height;
end;

constructor TRadioMessage.Create(aFont: TTexturedFont; aLayerIndex: integer);
begin
  inherited Create(FScene);
  FScene.Add(Self, aLayerIndex);
  FFont := aFont;
  SetCoordinate(0, FScene.Height);
end;

procedure TRadioMessage.SetBGColor(const aColor: TBGRAPixel);
begin
  FBGColor := aColor;
end;

procedure TRadioMessage.AddMessageFromPenelope(const aText: string);
begin
  InsertMessage(TMess.Create(texIconPenelopeHead, aText, FFont, FBGColor));
end;

procedure TRadioMessage.AddMessageFromMarcus(const aText: string);
begin
  InsertMessage(TMess.Create(texIconMarcusHead, aText, FFont, FBGColor));
end;

procedure TRadioMessage.AddMessageFromFather(const aText: string);
begin
  InsertMessage(TMess.Create(texIconFatherHead, aText, FFont, FBGColor));
end;

procedure TRadioMessage.AddMessageFromW7(const aText: string);
begin
  InsertMessage(TMess.Create(texIconW7Head, aText, FFont, FBGColor));
end;

procedure TRadioMessage.AddMessageFromLR(const aText: string);
begin
  InsertMessage(TMess.Create(texIconLRHead, aText, FFont, FBGColor));
end;

{ TRadioMessage.TMess }

constructor TRadioMessage.TMess.Create(aTex: PTexture; const aText: string;
  aFont: TTexturedFont; const aBGColor: TBGRAPixel);
begin
  inherited Create(FScene);
  SetSize(ScaleW(230), ScaleH(20));
  SetAllColorsTo(aBGColor);

  FIcon := TSprite.Create(aTex, False);
  FIcon.SetChildOf(Self, 0);
  FIcon.SetCoordinate(PPIScale(2), PPIScale(2));

  FTextArea := TUITextArea.Create(FScene);
  with FTextArea do begin
    SetChildOf(Self, 0);
    VScrollBarMode := sbmNeverShow;
    HScrollBarMode := sbmNeverShow;
    BodyShape.SetShapeRectangle(ScaleW(164), ScaleH(56), 0);
    BodyShape.Fill.Visible := False;
    Text.Align := taTopLeft;
    Text.TexturedFont := aFont;
    Text.Caption := aText;
    Text.Tint.Value := BGRAWhite;
    BodyShape.ResizeCurrentShape(Text.DrawingSize.cx+PPIScale(5)*2, Text.DrawingSize.cy+PPIScale(5)*2, True);
    SetCoordinate(ScaleW(59), PPIScale(10));
  end;

  SetSize(ScaleW(59) + FTextArea.Width + PPIScale(10), Max(FTextArea.Text.DrawingSize.cy + ScaleH(20), FIcon.Height));
  PostMessage(0, 12);
end;

procedure TRadioMessage.TMess.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin
      ChildsUseParentOpacity := True;
      Opacity.ChangeTo(0, 5.0);
      PostMessage(5, 5.0);
    end;
    5: Kill;
  end;
end;

{ TRadar }

procedure TRadar.AddItemToList(aIcon: TSprite;
  aInstance: TSimpleSurfaceWithEffect; aCopyInstanceAngle: boolean);
var o: TRadarItem;
begin
  o.Icon := aIcon;
  o.Instance := aInstance;
  o.CopyInstanceAngle := aCopyInstanceAngle;
  FItems.PushBack(o);
  UpdateItemOnTheRadar(FItems.Size-1);
end;

procedure TRadar.RemoveItemFromList(aInstance: TSimpleSurfaceWithEffect);
var i: SizeUInt;
begin
  if FItems.Size = 0 then exit;

  for i :=0 to FItems.Size-1 do
    if FItems.Mutable[i]^.Instance = aInstance then begin
      FItems.Mutable[i]^.Icon.Kill;
      FItems.Erase(i);
      exit;
    end;
end;

procedure TRadar.UpdateItemOnTheRadar(aIndex: SizeUInt);
var o: PRadarItem;
  polar: TPolarCoor;
  pOwner, pItem: TPointF;
begin
  if FOwnerShip = NIL then exit;
  pOwner := FOwnerShip.SurfaceToWorld(PointF(FOwnerShip.Width*0.5, FOwnerShip.Height*0.5));

  o := FItems.Mutable[aIndex];
  pItem := o^.Instance.SurfaceToWorld(PointF(o^.Instance.Width*0.5, o^.Instance.Height*0.5));

  polar := CartesianToPolar(pOwner, pItem);
  polar.Distance := EnsureRange(polar.Distance, 0, FScene.Height*4);
  polar.Distance := (polar.Distance / (FScene.Height*4)) * Width*0.5;
  o^.Icon.SetCenterCoordinate(PolarToCartesian(PointF(Width*0.5, Height*0.5), polar));

  if o^.CopyInstanceAngle then
    o^.Icon.Angle.Value := o^.Instance.Angle.Value;
end;

constructor TRadar.Create(aLayerIndex: integer);
begin
  inherited Create(texRadarBody, False);
  if aLayerIndex <> -1 then begin
    FScene.Add(Self, aLayerIndex);
    SetCoordinate(PPIScale(20), FScene.Height-Height-PPIScale(20));
  end;

  ChildsUseParentOpacity := False;
  Opacity.Value := 160;

  FIconArrow := CreateSpriteChild(texRadarIconArrow, False, 1);
  FIconArrow.CenterOnParent;

  FItems := TRadarItemList.Create;
end;

destructor TRadar.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TRadar.Update(const aElapsedTime: single);
var i: SizeUInt;
begin
  inherited Update(aElapsedTime);

  // update the pos and angle of items
  if FItems.Size > 0 then
    for i:=0 to FItems.Size-1 do
      UpdateItemOnTheRadar(i);

  // update owner icon angle
  if FOwnerShip <> NIL then
    FIconArrow.Angle.Value := FOwnerShip.Angle.Value;
end;

procedure TRadar.SetBGColor(aColor: TBGRAPixel);
begin
  aColor.alpha := 160;
  Tint.Value := aColor;
end;

procedure TRadar.RegisterOwnerShip(aSurface: TSimpleSurfaceWithEffect);
begin
  FOwnerShip := aSurface;
end;

procedure TRadar.RegisterMotherShip(aSurface: TSimpleSurfaceWithEffect);
begin
  RegisterObject(texRadarIconMotherShip, False, aSurface, False);
end;

procedure TRadar.RegisterGate(aSurface: TSimpleSurfaceWithEffect);
begin
  RegisterObject(texRadarIconGate, False, aSurface, False);
end;

procedure TRadar.RegisterObject(aIconTex: PTexture; aResize: boolean;
  aInstance: TSimpleSurfaceWithEffect; aCopyInstanceAngle: boolean);
var o: TSprite;
begin
  o := TSprite.Create(aIconTex, False);
  o.SetChildOf(Self, 0);
  if aResize then o.SetSize(ScaleW(20), -1);
  AddItemToList(o, aInstance, aCopyInstanceAngle);
end;

procedure TRadar.RemoveObject(aInstance: TSimpleSurfaceWithEffect);
begin
  RemoveItemFromList(aInstance);
end;

procedure TRadar.PlayBeep;
begin
  Audio.PlayThenKillSound('button-beep_Short.ogg', 1.0);
end;

{ TItemAsked }

procedure TItemAsked.SetBGColor(const aColor: TBGRAPixel);
begin
  BodyShape.Fill.Color := aColor;
end;

procedure TItemAsked.Add(aItemIndex, aCount: integer);
begin
  AddItem(TUIItemSpaceHarvesting.Create(aItemIndex, aCount));
  IsEmpty := False;
  Visible := True;
end;

procedure TItemAsked.Substract(aItemIndex, aCount: integer);
var i: integer;
  o: TUIItemSpaceHarvesting;
begin
  for i:=0 to ChildCount-1 do
    if Childs[i] is TUIItemSpaceHarvesting then begin
      o := TUIItemSpaceHarvesting(Childs[i]);
      if o.ItemIndex = aItemIndex then begin
        RemoveItem(o, aCount);
        if ItemCount = 0 then begin
          IsEmpty := True;
          Visible := False;
        end;
        exit;
      end;
    end;
end;

{ THUD }

constructor THUD.Create(aFont: TTexturedFont);
begin
  FRadar := TRadar.Create(LAYER_GAMEUI);
  FRadio := TRadioMessage.Create(aFont ,LAYER_GAMEUI);
  FRadio.BottomY := FRadar.Y.Value - PPIScale(20);
  FItemAsked := TItemAsked.Create(4);
end;

procedure THUD.SetBGColor(const aColor: TBGRAPixel);
begin
  FRadar.SetBGColor(aColor);
  FRadio.SetBGColor(aColor);
  FItemAsked.SetBGColor(aColor);
end;

{ TMotherShipTopView }

class procedure TMotherShipTopView.LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single);
var path: string;
begin
  FAdditionalScale := aAdditionalScale;
  path := FolderSpriteWolfCastle;
  texMotherShipBody := aAtlas.AddFromSVG(path+'MotherShipBody.svg', -1, ScaleH(417));
  texMotherShipWingLeft := aAtlas.AddFromSVG(path+'MotherShipWingLeft.svg', -1, ScaleH(303));
  texMotherShipRadar := aAtlas.AddFromSVG(path+'MotherShipRadar.svg', ScaleW(21), -1);
  texTransporterWK510 := aAtlas.AddFromSVG(path+'TransporterWhole.svg', ScaleW(153), -1);
  texMotherShipAnnihilator := aAtlas.AddFromSVG(path+'MotherShipWingAnnihilator.svg', ScaleW(30), -1);
  texMotherShipGigatron := aAtlas.AddFromSVG(path+'MotherShipWingGigatron.svg', ScaleW(39), -1);
  TMotherShipDockingBay.LoadTexture(aAtlas);
end;

constructor TMotherShipTopView.Create(aLayerIndex: integer; aAtlas: TAtlas;
  aAddTransporterWK510: boolean);
begin
  inherited Create(texMotherShipBody, False);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);

  FTransporterWK510 := TSprite.Create(texTransporterWK510, False);
  with FTransporterWK510 do begin
    SetChildOf(Self, 0);
    SetCoordinate(0.021*Self.Width, 0.638*Self.Height);
    Angle.Value := -90.00;
    Visible := aAddTransporterWK510;
    Freeze := not aAddTransporterWK510;
  end;

  WingLeft := TSprite.Create(texMotherShipWingLeft, False);
  with WingLeft do begin
    SetChildOf(Self, -1);
    SetCoordinate(-0.5*Self.Width, 0.427*Self.Height);   //0.528
  end;
  FGigatron1 := TSprite.Create(texMotherShipGigatron, False);
  FGigatron1.SetChildOf(WingLeft, 0);
  FGigatron1.SetCoordinate(WingLeft.Width*0.272, WingLeft.Height*0.77);
  FGigatron1.Visible := False;
  FAnnihilator1 := TSprite.Create(texMotherShipAnnihilator, False);
  FAnnihilator1.SetChildOf(WingLeft, 0);
  FAnnihilator1.SetCoordinate(WingLeft.Width*0.142, 0);
  FAnnihilator1.Visible := False;

  MotherShipRadar := TSprite.Create(texMotherShipRadar, False);
  with MotherShipRadar do begin
    SetChildOf(WingLeft, 0);
    SetCoordinate(0.627*WingLeft.Width, 0.161*WingLeft.Height);
    Angle.AddConstant(180);
  end;

  WingRight := TSprite.Create(texMotherShipWingLeft, False);
  with WingRight do begin
    SetChildOf(Self, -2);
    SetCoordinate(0.653*Self.Width, 0.427*Self.Height);    // 0.634
    FlipH := True;
  end;
  FGigatron2 := TSprite.Create(texMotherShipGigatron, False);
  FGigatron2.SetChildOf(WingRight, 0);
  FGigatron2.SetCoordinate(WingRight.Width*0.451, WingRight.Height*0.77);
  FGigatron2.FlipH := True;
  FGigatron2.Visible := False;
  FAnnihilator2 := TSprite.Create(texMotherShipAnnihilator, False);
  FAnnihilator2.SetChildOf(WingRight, 0);
  FAnnihilator2.SetCoordinate(WingRight.Width*0.644, 0);
  FAnnihilator2.Visible := False;

  FPropulsorLeft := TParticleEmitter.Create(FScene);
  with FPropulsorLeft do begin
    SetChildOf(WingLeft, -1);
    LoadFromFile(ParticleFolder+'WolfMotherShipFlame.par', aAtlas);
    SetCoordinate(WingLeft.Width*0.415, WingLeft.Height*0.969);
    ParticlesToEmit.Value := 0;
  end;

  FPropulsorRight := TParticleEmitter.Create(FScene);
  with FPropulsorRight do begin
    SetChildOf(WingRight, -1);
    LoadFromFile(ParticleFolder+'WolfMotherShipFlame.par', aAtlas);
    SetCoordinate(WingRight.Width*0.58, WingRight.Height*0.969);
    ParticlesToEmit.Value := 0;
  end;

  FDockingBay := TMotherShipDockingBay.Create(-1);
  with FDockingBay do begin
    SetChildOf(Self, 1);
    SetCoordinate(0, Self.Height*0.8);     //0.75
    Visible := False;
  end;

  FShield := TParticleEmitter.Create(FScene);
  with FShield do begin
    SetChildOf(Self, 2);
    LoadFromFile(ParticleFolder+'WolfMotherShipShield.par', aAtlas);
    SetCoordinate(Self.Width*0.5, Self.Height*0.6);
    SetEmitterTypeRing(Self.Height*1.335*0.5, Self.Height*1.40*0.5);
    //SetEmitterTypeCircle(Self.Height*1.40*0.5);
    ParticlesToEmit.Value := 0;
  end;
  FShield2 := TParticleEmitter.Create(FScene);
  with FShield2 do begin
    SetChildOf(Self, 2);
    LoadFromFile(ParticleFolder+'WolfMotherShipShield.par', aAtlas);
    SetCoordinate(Self.Width*0.5, Self.Height*0.6);
    //SetEmitterTypeRing(Self.Height*1.335*0.5, Self.Height*1.40*0.5);
    SetEmitterTypeCircle(Self.Height*1.40*0.5);
    ParticlesToEmit.Value := 0;
  end;

  FShaker.Create;
end;

destructor TMotherShipTopView.Destroy;
begin
  FShaker.Free;
  inherited Destroy;
end;

procedure TMotherShipTopView.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  FShaker.Update(aElapsedTime);
  // apply shaker only on x
  if FShaker.ComputedOffsetX <> 0 then
    X.Value := FOriginForShaker.x + FShaker.ComputedOffsetX;
end;

procedure TMotherShipTopView.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // docking bay appears
    0: begin
      dec(FBlinkCounter);
      if FBlinkCounter = 0 then exit;
      FDockingBay.Tint.Value := BGRA(255,255,0);
      PostMessage(5, 0.4);
    end;
    5: begin
      FDockingBay.Tint.Alpha.Value := 0;
      PostMessage(0, 0.4);
    end;

    // annihilator appears
    10: begin
      dec(FBlinkCounter);
      if FBlinkCounter = 0 then exit;
      FAnnihilator1.Tint.Value := BGRA(255,255,0);
      FAnnihilator2.Tint.Value := BGRA(255,255,0);
      PostMessage(15, 0.4);
    end;
    15: begin
      FAnnihilator1.Tint.Alpha.Value := 0;
      FAnnihilator2.Tint.Alpha.Value := 0;
      PostMessage(10, 0.4);
    end;

    // gigatron appears
    20: begin
      dec(FBlinkCounter);
      if FBlinkCounter = 0 then exit;
      FGigatron1.Tint.Value := BGRA(255,255,0);
      FGigatron2.Tint.Value := BGRA(255,255,0);
      PostMessage(25, 0.4);
    end;
    25: begin
      FGigatron1.Tint.Alpha.Value := 0;
      FGigatron2.Tint.Alpha.Value := 0;
      PostMessage(20, 0.4);
    end;
  end;
end;

function TMotherShipTopView.GetLocalTransporterBayCenter: TPointF;
begin
  Result.x := Width*0.50;
  Result.y := Height*0.67;
end;

procedure TMotherShipTopView.StartPropulsors;
begin
  FPropulsorLeft.ParticlesToEmit.ChangeTo(203, 1.0);
  FPropulsorRight.ParticlesToEmit.ChangeTo(203, 1.0);
end;

procedure TMotherShipTopView.StopPropulsor;
begin
  FPropulsorLeft.ParticlesToEmit.ChangeTo(0, 4.0);
  FPropulsorRight.ParticlesToEmit.ChangeTo(0, 4.0);
end;

procedure TMotherShipTopView.StartShield;
begin
  FShield.ParticlesToEmit.Value := 1024;
  FShield2.ParticlesToEmit.Value := 512;
end;

procedure TMotherShipTopView.StopShield;
begin
  FShield.ParticlesToEmit.Value := 0;
  FShield2.ParticlesToEmit.Value := 0;
end;

procedure TMotherShipTopView.Shake;
begin
  if FShaker.Amount.State = psNO_CHANGE then
    FOriginForShaker := GetXY;
  FShaker.Start(PPIScale(8), 0, 0.1);
  FShaker.FadeOut(2.0);
end;

procedure TMotherShipTopView.ShowDockingBay;
begin
  FDockingBay.Visible := True;
end;

procedure TMotherShipTopView.ShowGigatron;
begin
  FGigatron1.Visible := True;
  FGigatron2.Visible := True;
end;

procedure TMotherShipTopView.ShowAnnihilator;
begin
  FAnnihilator1.Visible := True;
  FAnnihilator2.Visible := True;
end;

procedure TMotherShipTopView.DockShip(aShip: TBaseLittleShip);
begin
  aShip.SetChildOf(FDockingBay, -1);
  aShip.SetCoordinate((FDockingBay.Width-aShip.Width)*0.5, FDockingBay.Height*0.4);
  aShip.ParentDockingBay := FDockingBay;
end;

procedure TMotherShipTopView.MakeDockingBayAppears;
begin
  FBlinkCounter := 5;
  FDockingBay.Visible := True;
  PostMessage(0);
  Audio.PlayMusicSuccessShort1;
end;

procedure TMotherShipTopView.MakeShieldAppears;
begin
  StartShield;
end;

procedure TMotherShipTopView.MakeGigatronAppears;
begin
  FBlinkCounter := 5;
  FGigatron1.Visible := True;
  FGigatron2.Visible := True;
  PostMessage(20);
  Audio.PlayMusicSuccessShort1;
end;

procedure TMotherShipTopView.MakeAnnihilatorAppears;
begin
  FBlinkCounter := 5;
  FAnnihilator1.Visible := True;
  FAnnihilator2.Visible := True;
  PostMessage(10);
  Audio.PlayMusicSuccessShort1;
end;

end.
