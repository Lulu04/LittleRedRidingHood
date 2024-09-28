unit u_sprite_gameforest;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes,
  u_common_ui, u_sprite_lrcommon,
  u_audio;

type

{ TUIBalloonExplodedCounter }

TUIBalloonExplodedCounter = class(TUIItemCounter)
  constructor Create;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
end;

{ TUIStormCloudCounter }

TUIStormCloudCounter = class(TUIItemCounter)
  constructor Create;
end;

{ TUIHammerCounter }

TUIHammerCounter = class(TUIItemCounter)
  constructor Create;
end;

{ TInGamePanel }

TInGamePanel = class(TBaseInGamePanelWithCoinAndClock)
private
  FBalloonExplodedCounter: TUIBalloonExplodedCounter;
  FHammerCounter: TUIHammerCounter;
  FStormCloudCounter: TUIStormCloudCounter;
//  FCoinCounter: TUICoinCounter;
//  FClock: TUIClock;
  function GetRemainHammer: integer;
//  function GetRemainSecond: integer;
//  procedure SetRemainSecond(AValue: integer);
public
  constructor Create;

  procedure IncBalloonExploded;
  procedure DecHammerCount;
  function StormCloudAvailable: boolean;
  procedure DecStormCloudCount;

  property RemainHammer: integer read GetRemainHammer;
  property BalloonExplodedCounter: TUIBalloonExplodedCounter read FBalloonExplodedCounter;
end;


{ TEndGameScorePanel }

TEndGameScorePanel = class(TBasePanelEndGameScore)
private
  FBalloonCounter: TUIBalloonExplodedCounter;
  FInGamePanel: TInGamePanel;
public
  constructor Create(aIngamePanel: TInGamePanel);
  procedure AddGainToInGamePanel(aValue: integer); override;
end;

{ TPlatformLR }

TPlatformLR = class(TSprite)
  constructor Create;
end;

{ TBalloonCrate }

TBalloonCrate = class(TSprite)
private
  FBusy: boolean;
public
  constructor Create(aX, aY: single);
  // true if a wolf is taking something from this crate
  property Busy: boolean read FBusy write FBusy;
end;

{ TGround1Left }

TGround1Left = class(TSprite)
  constructor Create;
end;

{ TGround1Right }

TGround1Right = class(TSprite)
  constructor Create;
end;
TGround1 = class(TSprite)
  constructor Create;
end;


{ TElevatorEngine }

TElevatorEngine = class(TSpriteContainer)
private
  FLeftPistonPosUp, FLeftPistonPosDown,
  FRightPistonPosUp, FRightPistonPosDown: TPointF;
  FEngineON, FBreaked: boolean;
  FHitCount: integer;
  FSmoke: TParticleEmitter;
  FAtlas: TOGLCTextureAtlas;
  FRopeBeginPoint: TPointF;
  procedure SetEngineON(AValue: boolean);
  procedure SetHitCount(AValue: integer);
public
  Body, SmallWheel, BigWheel, LeftPiston, RightPiston: TSprite;
  Rope: TShapeOutline;
  CollisionRect: TRect;
  constructor Create(aAtlas: TOGLCTextureAtlas);
 // procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;

  // -1=rotation CCW  0=no rotation  1=rotation CW
  procedure SetWheelRotation(aValue: integer);
  procedure SetRopeEndPoint(aSceneY: single);
  procedure Explode;

  property EngineON: boolean read FEngineON write SetEngineON;
  property Breaked: boolean read FBreaked;
  property HitCount: integer read FHitCount write SetHitCount;
end;


{ TEscapeDoorAbove }

TEscapeDoorAbove = class(TSprite)
  // self is AboveUp
  DoorPart2: TSprite;
  constructor Create;
end;

{ TEscapeDoorBelow }

TEscapeDoorBelow = class(TSprite)
private
  FsndStoneRip: TALSSound;
  FDoorIsOpened: boolean;
  FBlinkCount: integer;
  WoodenPillar{, Stone}: TSprite;
  Stone: TDeformationGrid;
public
  constructor Create;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure OpenTheDoor;
  property DoorIsOpened: boolean read FDoorIsOpened;
end;

TEscapeDoor = class(TEscapeDoorAbove)
private
  BelowPart: TEscapeDoorBelow;
  function GetDoorIsOpened: boolean;
public
  constructor Create;
  procedure OpenTheDoor;
  property DoorIsOpened: boolean read GetDoorIsOpened;
end;

{ THammer }

THammer = class(TSprite)
private type TState = (hsUndefined=0, hsReadyToHit, hsHitting);
private
  FState: TState;
  FTimeMultiplicator: single;
  Part: array[0..5] of TSprite;
  Paf: TSprite;
  FInGamePanel: TInGamePanel;
public
  constructor Create(aInGamePanel: TInGamePanel; aTimeMultiplicator: single);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;

  procedure Hit;
  property TimeMultiplicator: single read FTimeMultiplicator write FTimeMultiplicator;
end;


{ TCloudForStorm }

TCloudForStorm = class(TSprite)
private
  FPulse: TPointF;
  FPulseFactor: single;
  FMovingRectangle: TPointF;
  FAccumulator: TPointF;
  FCenterPosOrigin: TPointF;
public
  constructor Create(aMovingRectangle: TPointF; aTimeMultiplicator: single);
  procedure Update(const aElapsedTime: single); override;
  property CenterPosOrigin: TPointF read FCenterPosOrigin write FCenterPosOrigin;
end;

{ TStormCloud }
// main sprite is darkness
TStormCloud = class(TMultiColorRectangle)
private
  FClouds: TSpriteContainer;
  FRain: TPArticleEmitter;
  FYHide: single;
  FTargetWolf: TSpriteContainer;
  FTargetDone: integer;
  FIsReadyToShoot: boolean;
public
  constructor Create(aAtlas: TOGLCTextureAtlas);
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure Shoot;
  procedure Hide;
  property CanShoot: boolean read FIsReadyToShoot;
end;

{ TLRArrow }

TLRArrow = class(TSprite)
  constructor Create;
  procedure Shoot;
end;

TLRForestState = (wsUndefined=0,
            ssReadyToPullBowString, ssPullingBowString, ssBowReadyToShoot, ssBowRestAfterShoot,
            lrsWalking,
            lrsWinner, lrsLoser,
            lrsWalkToTheLeft,
            lrsDisappearedThroughTheDoor);
{ TLRWithBow }

TLRWithBow = class(TSpriteContainer)
private
  FArrow: TLRArrow;  FsndArrowWoosh: TALSSound;
  FArrowRearmTimeMultiplicator: single;
  FDeltaYFromGround, FWinJumpCount: integer;
  FState: TLRForestState;
  //procedure SetPositionWithBow;
  procedure CreateArrow;
  procedure HideBowAndKillArrow;
  procedure SetState(AValue: TLRForestState);
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  Dress: TLRDress;
  Face: TLRFace;
  Hood, RightCloak, LeftCloak: TDeformationGrid;
  RightArm, LeftArm: TSprite;
  RightLeg, LeftLeg: TSprite;
  Bow: TSprite;
  BowString: TOGLCPathToFollow;
  FFaceCenterCoor: TPointF;
  FRightArmMinX, FRightArmMaxX: single;
  procedure SetDeformationOnRightCloak;
  procedure SetDeformationOnLeftCloak;
  procedure SetDeformationOnHood;
  procedure ComputeBowStringPositionAndPath;

  constructor Create;
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;

  procedure LookAtLeft(aValue: boolean);
  procedure ShootArrow;
  property State: TLRForestState read FState write SetState;
  property DeltaYFromGround: integer read FDeltaYFromGround;
  // 0.3 to 1.0
  property ArrowRearmTimeMultiplicator: single read FArrowRearmTimeMultiplicator write FArrowRearmTimeMultiplicator;
end;

var
texLRDress, texLRHood, texLRLeftLeg, texLRRightLeg, texLRArmForBow, texLRLeftCloak, texLERightCloak,
texLRBow, texLRArrow: PTexture;

texIconBallonExploded, texIconStormCloud, texIconHammer: PTexture;
texPlatformLR,
texBalloonCrate,
texGround1Left, texGround1, texGround1Right,
texMotorBody, texMotorBigWheel, texMotorSmallWheel, texMotorLeftPiston,
texEscapeDoorAboveUp, texEscapeDoorAboveDown, texEscapeDoorBelowUp, texEscapeDoorBelowDown, texEscapeDoorStone,
texHammerBox, texHammerArmPart, texHammerHead, texHammerPaf,
texStormCloud: PTexture;

sndStorm,
sndPulley,
sndElevator,
sndHammer: TALSSound;

procedure LoadTexturesForForestGame(aAtlas: TOGLCTextureAtlas);
procedure LoadGround1Texture(aAtlas: TOGLCTextureAtlas);
procedure LoadSoundForForestGame;
procedure FreeSoundForForestGame;

implementation
uses u_app, u_common, u_sprite_wolf, u_resourcestring, Math;

procedure LoadPlatformLRTexture(aAtlas: TOGLCTextureAtlas);
begin
  texPlatformLR := aAtlas.AddFromSVG(SpriteCommonFolder+'PlatformLR.svg', ScaleW(106) {PPIScale(106)}, -1);
  texMotorBody := aAtlas.AddFromSVG(SpriteCommonFolder+'MotorBody.svg', ScaleW(100) {PPIScale(100)}, -1);
  texMotorBigWheel := aAtlas.AddFromSVG(SpriteCommonFolder+'MotorBigWheel.svg', ScaleW(32){PPIScale(32)}, -1);
  texMotorSmallWheel := aAtlas.AddFromSVG(SpriteCommonFolder+'MotorSmallWheel.svg', ScaleW(20){PPIScale(20)}, -1);
  texMotorLeftPiston := aAtlas.AddFromSVG(SpriteCommonFolder+'MotorLeftPiston.svg', ScaleW(25){PPIScale(25)}, -1);
  aAtlas.Add(ParticleFolder+'sphere_particle.png');
end;

procedure LoadBalloonCrateTexture(aAtlas: TOGLCTextureAtlas);
begin
  texBalloonCrate := aAtlas.AddFromSVG(SpriteCommonFolder+'BalloonCrate.svg', ScaleW(70){PPIScale(75)}, -1);
end;

procedure LoadGround1Texture(aAtlas: TOGLCTextureAtlas);
var path: String;
begin
  path := SpriteCommonFolder;
  texGround1Left := aAtlas.AddFromSVG(path+'Ground1Left.svg', -1, ScaleH(48));
  texGround1 := aAtlas.AddFromSVG(path+'Ground1.svg', ScaleW(167), -1);
  texGround1Right := aAtlas.AddFromSVG(path+'Ground1Right.svg', -1, ScaleH(48));
end;

procedure LoadSoundForForestGame;
begin
  sndStorm := Audio.AddSound('StormCloud.ogg');
  sndStorm.Loop := True;

  sndPulley := Audio.AddSound('polea.ogg');
  sndPulley.Loop := True;
  sndPulley.Tone.Value := 0.15;
  sndPulley.Pitch.Value := 0.8;
  sndPulley.Pan.Value := -0.5;

  sndElevator := Audio.AddSound('EngineLoop.ogg');
  sndElevator.Loop := True;

  sndHammer := Audio.AddSound('wall-bump-1.ogg');
end;

procedure FreeSoundForForestGame;
begin
  if sndStorm <> NIL then sndStorm.Kill;
  sndStorm := NIL;

  if sndPulley <> NIL then sndPulley.Kill;
  sndPulley := NIL;

  if sndElevator <> NIL then sndElevator.Kill;
  sndElevator := NIL;

  if sndHammer <> NIL then sndHammer.Kill;
  sndHammer := NIL;
end;

procedure LoadEscapeDoorTexture(aAtlas: TOGLCTextureAtlas);
var path: String;
begin
  path := SpriteCommonFolder;
  texEscapeDoorAboveUp := aAtlas.AddFromSVG(path+'EscapeDoorAboveUp.svg', ScaleW(68){PPIScale(68)}, -1);
  texEscapeDoorAboveDown := aAtlas.AddFromSVG(path+'EscapeDoorAboveDown.svg', ScaleW(70){PPIScale(70)}, -1);
  texEscapeDoorBelowUp := aAtlas.AddFromSVG(path+'EscapeDoorBelowUp.svg', -1, ScaleH(175){PPIScale(175)});
  texEscapeDoorBelowDown := aAtlas.AddFromSVG(path+'EscapeDoorBelowDown.svg', -1, ScaleH(216){PPIScale(216)});
  texEscapeDoorStone := aAtlas.AddFromSVG(path+'EscapeDoorStone.svg', -1, ScaleH(194){PPIScale(194)});
end;

procedure LoadHammerBoxTexture(aAtlas: TOGLCTextureAtlas);
var path: String;
begin
  path := SpriteCommonFolder;
  texHammerBox := aAtlas.AddFromSVG(path+'HammerBox.svg', ScaleW(55), -1);
  texHammerArmPart := aAtlas.AddFromSVG(path+'HammerArmPart.svg', -1, ScaleH(25));
  texHammerHead := aAtlas.AddFromSVG(path+'HammerHead.svg', ScaleW(46), -1);
  texHammerPaf :=  aAtlas.AddFromSVG(path+'PafHammer.svg', ScaleW(55*3), -1);
end;

procedure LoadStormCloudTexture(aAtlas: TOGLCTextureAtlas);
begin
  texStormCloud := aAtlas.AddFromSVG(SpriteCommonFolder+'StormCloud.svg', Round(FScene.Width/5), -1);
  aAtlas.Add(ParticleFolder+'RainDrop.png');
end;

procedure LoadTexturesForForestGame(aAtlas: TOGLCTextureAtlas);
begin
  LoadLRFaceTextures(aAtlas);

  texLRDress := aAtlas.AddFromSVG(SpriteFolder+'LittleRedDress.svg', ScaleW(62), -1);
  texLRHood := aAtlas.AddFromSVG(SpriteFolder+'LittleRedHood.svg', ScaleW(86), -1);
  texLRLeftLeg := aAtlas.AddFromSVG(SpriteFolder+'LittleRedLeftLeg.svg', ScaleW(20), -1);
  texLRRightLeg := aAtlas.AddFromSVG(SpriteFolder+'LittleRedRightLeg.svg', ScaleW(19), -1);
  texLRArmForBow := aAtlas.AddFromSVG(SpriteFolder+'LittleRedArmForBow.svg', ScaleW(50), -1);
  texLRLeftCloak := aAtlas.AddFromSVG(SpriteFolder+'LittleRedLeftCloak.svg', ScaleW(68), -1);
  texLERightCloak := aAtlas.AddFromSVG(SpriteFolder+'LittleRedRightCloak.svg', ScaleW(59), -1);
  texLRBow := aAtlas.AddFromSVG(SpriteFolder+'LittleRedBow.svg', -1, ScaleH(117));
  texLRArrow := aAtlas.AddFromSVG(SpriteCommonFolder+'LRArrow.svg', ScaleW(53), -1);
  LoadPlatformLRTexture(aAtlas);
  LoadBalloonCrateTexture(aAtlas);
  LoadGround1Texture(aAtlas);
  LoadEscapeDoorTexture(aAtlas);
  LoadHammerBoxTexture(aAtlas);
  LoadStormCloudTexture(aAtlas);
end;


{ TLRArrow }

constructor TLRArrow.Create;
begin
  inherited Create(texLRArrow, False);
  //FScene.Add(Self, LAYER_ARROW);
end;

procedure TLRArrow.Shoot;
begin
  Speed.X.Value := PlayerInfo.Forest.Bow.ArrowSpeed;
  KillDefered(5);
end;


{ TLRWithBow }

{procedure TLRWithBow.SetPositionWithBow;
begin
  RightArm.Angle.ChangeTo(0, 1*FArrowRearmTimeMultiplicator, idcSinusoid);
  RightArm.X.ChangeTo(FRightArmMaxX, 1*FArrowRearmTimeMultiplicator, idcSinusoid);
  LeftArm.Angle.ChangeTo(0, 1*FArrowRearmTimeMultiplicator, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, 1*FArrowRearmTimeMultiplicator, idcSinusoid);
  //LeftLeg.FlipH := true;
  RightLeg.Angle.ChangeTo(0, 1*FArrowRearmTimeMultiplicator, idcSinusoid);
end; }

procedure TLRWithBow.CreateArrow;
begin
  FArrow := TLRArrow.Create;
  FArrow.Pivot := PointF(0,0.5);
  Bow.AddChild(FArrow, 2);
  FArrow.SetCoordinate(0, Bow.Height*0.5);
  //FArrow.SetCoordinate(Bow.SurfaceToScene(PointF(0, Bow.Height*0.5)));
end;

procedure TLRWithBow.HideBowAndKillArrow;
begin
  Bow.Visible := False;
  BowString.Visible := False;
  if FArrow <> NIL then FArrow.Kill;
  FArrow := NIL;
end;

procedure TLRWithBow.SetState(AValue: TLRForestState);
begin
  if FState = AValue then Exit;
  FState := AValue;

  case FState of
    ssReadyToPullBowString: begin
      PostMessage(500);
    end;

    lrsLoser: begin
      Face.FaceType := lrfNotHappy;
      //LeftLeg.FlipH := False;
      RightArm.X.ChangeTo(FRightArmMinX, 1.0, idcSinusoid);
      RightArm.Angle.ChangeTo(60, 1.0, idcSinusoid);
      LeftArm.Angle.ChangeTo(55, 1.0, idcSinusoid);
      Face.Angle.ChangeTo(20, 1.0, idcSinusoid);
      HideBowAndKillArrow;
    end;

    lrsWinner: begin
      //ClearMessageList;
      //PostMessage(0); // eyes anim
      Face.FaceType := lrfHappy;
      HideBowAndKillArrow;
      sndPulley.Stop;
      PostMessage(600);
    end;

    lrsWalkToTheLeft: begin
      LookAtLeft(True);
      X.AddConstant(-Dress.Width*2);
    end;
  end;
end;

procedure TLRWithBow.SetDeformationOnRightCloak;
const _cellCount = 5;
var i: integer;
begin
  RightCloak.SetGrid(_cellCount, _cellCount);
  RightCloak.ApplyDeformation(dtWaveH);
  RightCloak.Amplitude.Value := PointF(0.6, 0.6);
  RightCloak.DeformationSpeed.Value := PointF(5,5);
  for i:=0 to _cellCount do
    RightCloak.SetDeformationAmountOnRow(i, Power(i*(1/_cellCount), 2));
  RightCloak.SetTimeMultiplicatorOnRow(5, 1.5);
end;

procedure TLRWithBow.SetDeformationOnLeftCloak;
begin
  LeftCloak.SetGrid(5,5);
  LeftCloak.ApplyDeformation(dtWaveH);
  LeftCloak.Amplitude.Value := PointF(0.5, 0.5);
  LeftCloak.DeformationSpeed.Value := PointF(5,5);
  LeftCloak.SetDeformationAmountOnRow(0, 0);
  LeftCloak.SetDeformationAmountOnColumn(0, 0);
  LeftCloak.SetDeformationAmountOnColumn(1, 0);
  LeftCloak.SetTimeMultiplicatorOnRow(5, 1.5);
end;

procedure TLRWithBow.SetDeformationOnHood;
const _cellCount = 5;
var i: integer;
begin
  Hood.SetGrid(_cellCount, _cellCount);
  Hood.ApplyDeformation(dtWaveH);
  Hood.Amplitude.Value := PointF(0.3, 0.2);
  Hood.DeformationSpeed.Value := PointF(5,5);
  for i:=0 to _cellCount do
    Hood.SetDeformationAmountOnRow(i, 1-i*(1/_cellCount));
end;

procedure TLRWithBow.ComputeBowStringPositionAndPath;
var path: TOGLCPath;
  p: TPointF;
begin
  path := NIL;
  if (State in [ssPullingBowString,ssBowReadyToShoot]) then begin
    // create a path from top of the bow, passing by right hand and terminate to bottom of the bow
    SetLength(path, 3);
    path[0] := PointF(Bow.Width*0.06, Bow.Height*0.05);
    p := Bow.ParentToSurface(RightArm.SurfaceToParent(PointF(RightArm.Width*0.95, RightArm.Height*0.5)));
    path[1] := p;
    path[2] := PointF(Bow.Width*0.06, Bow.Height*0.95);
  end else begin
    // create a path from top of the bow to bottom of the bow
    SetLength(path, 2);
    path[0] := PointF(Bow.Width*0.06, Bow.Height*0.05);
    path[1] := PointF(Bow.Width*0.06, Bow.Height*0.95);
  end;
  BowString.InitFromPath(path, False);

  BowString.SetCoordinate(Bow.SurfaceToParent(PointF(0,0)));
end;

constructor TLRWithBow.Create;
begin
  inherited Create(FScene);

  FsndArrowWoosh := Audio.AddSound('quick-woosh.ogg');

  FArrowRearmTimeMultiplicator := 1.0;

  Dress := TLRDress.Create(texLRDress);
  AddChild(Dress, 0);
  Dress.X.Value := -Dress.Width*0.5;
  Dress.BottomY := 0;
  Dress.Pivot := PointF(0.5, 1.0);

    Hood := TDeformationGrid.Create(texLRHood, False);
    Dress.AddChild(Hood, 0);
    Hood.CenterX := Dress.Width*0.42;
    Hood.BottomY := Dress.Height*0.08;
    SetDeformationOnHood;
    Hood.ApplySymmetryWhenFlip := True;

    RightCloak := TDeformationGrid.Create(texLERightCloak, False);
    Dress.AddChild(RightCloak, 3);
    RightCloak.SetCenterCoordinate(Dress.Width*0.27, Dress.Height*0.4);
    SetDeformationOnRightCloak;
    RightCloak.ApplySymmetryWhenFlip := True;

    Face := TLRFace.Create;
    Dress.AddChild(Face, 4);
    Face.SetCenterCoordinate(Dress.Width*0.43, -Dress.Height*0.35);
    Face.OriginCenterCoor := Face.Center;
    Face.ApplySymmetryWhenFlip := True;

    LeftCloak := TDeformationGrid.Create(texLRLeftCloak, False);
    Dress.AddChild(LeftCloak, -2);
    LeftCloak.SetCenterCoordinate(Dress.Width*0.60, Dress.Height*0.45);
    SetDeformationOnLeftCloak;
    LeftCloak.ApplySymmetryWhenFlip := True;

    LeftArm := TSprite.Create(texLRArmForBow, False);
    Dress.AddChild(LeftArm, -1);
    LeftArm.SetCoordinate(Dress.Width*0.60, Dress.Height*0.1);
    LeftArm.Pivot := PointF(0, 0.5);
    LeftArm.ApplySymmetryWhenFlip := True;

    RightArm := TSprite.Create(texLRArmForBow, False);
    Dress.AddChild(RightArm, 2);
    RightArm.SetCoordinate(Dress.Width*0.20, Dress.Height*0.2);
    RightArm.Pivot := PointF(0,0.5);
    RightArm.ApplySymmetryWhenFlip := True;
    FRightArmMaxX := Dress.Width*0.30;
    FRightArmMinX := -Dress.Width*0.01;

    Bow := TSprite.Create(texLRBow, False);
    Dress.AddChild(Bow, 1);
    Bow.X.Value := LeftArm.X.Value+LeftArm.Width*0.99-Bow.Width;
    Bow.CenterY := LeftArm.CenterY;
    Bow.ApplySymmetryWhenFlip := True;

    BowString := TOGLCPathToFollow.Create(FScene);
    Dress.AddChild(BowString, 1);
    BowString.Border.Color := BGRA(47,45,45);
    BowString.Border.LinePosition := lpMiddle;
    BowString.Border.Width := PPIScale(3);

  LeftLeg := TSprite.Create(texLRLeftLeg, False);
  AddChild(LeftLeg, -1);
  LeftLeg.SetCoordinate(Dress.Width*0.05, -LeftLeg.Height*0.25);
  LeftLeg.Pivot := PointF(0.5, 0);
  LeftLeg.ApplySymmetryWhenFlip := True;

  FDeltaYFromGround := Round(LeftLeg.Height*0.8);

  RightLeg := TSprite.Create(texLRRightLeg, False);
  AddChild(RightLeg, -1);
  RightLeg.SetCoordinate(-Dress.Width*0.3, -RightLeg.Height*0.2);
  RightLeg.Pivot := PointF(0.5, 0);
  RightLeg.ApplySymmetryWhenFlip := True;

  State := ssReadyToPullBowString;
end;

destructor TLRWithBow.Destroy;
begin
  FsndArrowWoosh.Kill;
  FsndArrowWoosh := NIL;
  inherited Destroy;
end;

procedure TLRWithBow.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  ComputeBowStringPositionAndPath;

  if State = lrsWalkToTheLeft then begin
    if X.Value < -Dress.Width*2 then begin
      X.AddConstant(0);
      State := lrsDisappearedThroughTheDoor;
    end;
  end;
end;

procedure TLRWithBow.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of

    // Right arm pull the bow string
    500: begin
      CreateArrow;
      FState := ssPullingBowString;
      RightArm.X.ChangeTo(FRightArmMinX, 1*FArrowRearmTimeMultiplicator, idcSinusoid);
      FArrow.X.ChangeTo(FArrow.X.Value-(FRightArmMaxX-FRightArmMinX), 1*FArrowRearmTimeMultiplicator, idcSinusoid);
      PostMessage(501, 1*FArrowRearmTimeMultiplicator);
    end;
    501: begin
      FState := ssBowReadyToShoot;
    end;

    // Shoot an arrow
    510: begin
      if FState <> ssBowReadyToShoot then exit;
      // moves the arrow from child of Bow to Scene
      FArrow.MoveFromChildToScene(LAYER_ARROW);
      FArrow.Shoot;
      FArrow := NIL;
      FsndArrowWoosh.Play(True);
      FState := ssBowRestAfterShoot;
      Dress.Angle.ChangeTo(-2, 0.01);
      PostMessage(511, 0.2);
    end;
    511: begin
      if FState <> ssBowRestAfterShoot then exit;
      Dress.Angle.ChangeTo(0, 0.5, idcSinusoid);
      RightArm.Angle.ChangeTo(30, 1*FArrowRearmTimeMultiplicator, idcSinusoid);
      RightArm.X.ChangeTo(FRightArmMinX+FRightArmMaxX*0.2, 1*FArrowRearmTimeMultiplicator, idcSinusoid);
      PostMessage(512, 2*FArrowRearmTimeMultiplicator);
    end;
    512: begin
      if FState <> ssBowRestAfterShoot then exit;
      RightArm.Angle.ChangeTo(0, 1*FArrowRearmTimeMultiplicator, idcSinusoid);
      RightArm.X.ChangeTo(FRightArmMaxX, 1*FArrowRearmTimeMultiplicator, idcSinusoid);
      PostMessage(513, 1*FArrowRearmTimeMultiplicator);
    end;
    513: begin
      if FState <> ssBowRestAfterShoot then exit;
      FState := ssReadyToPullBowString;
      PostMessage(500);
    end;

    // STATE WINNER
    600: begin
      RightArm.X.Value := FRightArmMaxX;
      LeftArm.X.Value := LeftArm.X.Value-LeftArm.Width*0.15;
      RightArm.Angle.Value := 200;
      LeftArm.Angle.Value := 340;
      PostMessage(601, 0.5);
      FWinJumpCount := 0;
    end;
    601: begin
      Y.ChangeTo(Y.Value-LeftLeg.Height*0.3, 0.2, idcStartFastEndSlow);
      RightArm.Angle.ChangeTo(200, 0.2, idcStartFastEndSlow);
      LeftArm.Angle.ChangeTo(340, 0.2, idcStartFastEndSlow);
      PostMessage(602, 0.2);
    end;
    602: begin
      Y.ChangeTo(Y.Value+LeftLeg.Height*0.3, 0.2, idcStartSlowEndFast);
      RightArm.Angle.ChangeTo(195, 0.2, idcStartSlowEndFast);
      LeftArm.Angle.ChangeTo(345, 0.2, idcStartSlowEndFast);
      inc(FWinJumpCount);
      if FWinJumpCount < 4 then PostMessage(601, 0.3);
    end;

  end;
end;

procedure TLRWithBow.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  Hood.FlipH := AValue;
  RightCloak.FlipH := AValue;
  LeftCloak.FlipH := AValue;
  Face.FlipH := AValue;
  RightArm.FlipH := AValue;
  LeftArm.FlipH := AValue;
  RightLeg.FlipH := AValue;
  LeftLeg.FlipH := AValue;
end;

procedure TLRWithBow.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  Hood.FlipV := AValue;
  RightCloak.FlipV := AValue;
  LeftCloak.FlipV := AValue;
  Face.FlipV := AValue;
  RightArm.FlipV := AValue;
  LeftArm.FlipV := AValue;
  RightLeg.FlipV := AValue;
  LeftLeg.FlipV := AValue;
end;

procedure TLRWithBow.LookAtLeft(aValue: boolean);
begin
  SetFlipH(aValue);
end;

procedure TLRWithBow.ShootArrow;
begin
  if State = ssBowReadyToShoot then
    PostMessage(510);
end;

{ TUIBalloonExplodedCounter }

constructor TUIBalloonExplodedCounter.Create;
begin
  inherited Create(texIconBallonExploded, UIFontNumber, 3);
  Count := 0;
  PostMessage(0);
end;

procedure TUIBalloonExplodedCounter.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin
      Icon.Angle.ChangeTo(-5, 1.0, idcSinusoid);
      PostMessage(1, 1.0);
    end;
    1: begin
      Icon.Angle.ChangeTo(5, 1.0, idcSinusoid);
      PostMessage(0, 1.0);
    end;
  end;
end;

{ TUIHammerCounter }

constructor TUIHammerCounter.Create;
begin
  inherited Create(texIconHammer, UIFontNumber, 2);
end;

{ TUIStormCloudCounter }

constructor TUIStormCloudCounter.Create;
begin
  inherited Create(texIconStormCloud, UIFontNumber, 2);
end;

{ TInGamePanel }

function TInGamePanel.GetRemainHammer: integer;
begin
  Result := FHammerCounter.Count;
end;

constructor TInGamePanel.Create;
begin
  inherited Create;

{  FCoinCounter := TUICoinCounter.Create;
  AddItem(FCoinCounter);
  FCoinCounter.Count := PlayerInfo.CoinCount;  }

  FBalloonExplodedCounter := TUIBalloonExplodedCounter.Create;
  AddItem(FBalloonExplodedCounter);
  FBalloonExplodedCounter.Count := 0;

  if PlayerInfo.Forest.Hammer.Owned then begin
    FHammerCounter := TUIHammerCounter.Create;
    AddItem(FHammerCounter);
    FHammerCounter.Count := PlayerInfo.Forest.Hammer.UsesCount;
  end;

  if PlayerInfo.Forest.StormCloud.Owned then begin
    FStormCloudCounter := TUIStormCloudCounter.Create;
    AddItem(FStormCloudCounter);
    FStormCloudCounter.Count := PlayerInfo.Forest.StormCloud.UsesCount;
  end;

{  FClock := TUIClock.Create;
  AddItem(FClock);  }

  ResizeAndPlaceAtTopRight;
end;

procedure TInGamePanel.IncBalloonExploded;
begin
  FBalloonExplodedCounter.Count := FBalloonExplodedCounter.Count+1;
end;

procedure TInGamePanel.DecHammerCount;
begin
  if FHammerCounter <> NIL then
    FHammerCounter.Count := FHammerCounter.Count-1;
end;

function TInGamePanel.StormCloudAvailable: boolean;
begin
  Result := (FStormCloudCounter <> NIL) and (FStormCloudCounter.Count > 0);
end;

procedure TInGamePanel.DecStormCloudCount;
begin
  if FStormCloudCounter <> NIL then
    FStormCloudCounter.Count := FStormCloudCounter.Count-1;
end;

{ TEndGameScorePanel }

constructor TEndGameScorePanel.Create(aIngamePanel: TInGamePanel);
var lvlAchievedBonus, w: integer;
 t: TFreeText;
 equal: TUILabel;
begin
  inherited Create(3);

  FInGamePanel := aInGamePanel;

  // line 1  balloon
  equal := CreateLabelEqual;
  FBalloonCounter := TUIBalloonExplodedCounter.Create;
  equal.AddChild(FBalloonCounter);
  FBalloonCounter.SetCoordinate(-HMargin-FBalloonCounter.TotalWidth, 0);
  FBalloonCounter.Count := FInGamePanel.BalloonExplodedCounter.Count;
  t := TFreeText.Create(FScene);
  t.Tint.Value := BGRA(255,255,150);
  equal.AddChild(t);
  t.TexturedFont := UIFontNumber;
  t.Caption := (FInGamePanel.BalloonExplodedCounter.Count*5).ToString;
  t.RightX := HMargin*6;
  t.Y.Value := 0;
  w := HMargin+FBalloonCounter.TotalWidth + Round(t.RightX);
  CompareLineWidth(w);

  // line 2 level achieved
  equal := CreateLabelEqual;
  t := TFreeText.Create(FScene);
  t.Tint.Value := BGRA(220,220,220);
  equal.AddChild(t);
  t.TexturedFont := UIFontNumber;
  t.Caption := sLevelAchieved;
  t.SetCoordinate(-HMargin-t.Width, 0);
  w := HMargin+t.Width;
  t := TFreeText.Create(FScene);
  t.Tint.Value := BGRA(255,255,150);
  equal.AddChild(t);
  t.TexturedFont := UIFontNumber;
  if FInGamePanel.Second = 0 then lvlAchievedBonus := 100
    else lvlAchievedBonus := 0;
  t.Caption := lvlAchievedBonus.ToString;
  t.RightX := HMargin*6;
  t.Y.Value := 0;
  w := w + Round(t.RightX);
  CompareLineWidth(w);

  Gain := FInGamePanel.BalloonExplodedCounter.Count*5 + lvlAchievedBonus;

  // line 3 TOTAL
  CreateLineTotalGain(sTotal);

  StartCounting;
end;

procedure TEndGameScorePanel.AddGainToInGamePanel(aValue: integer);
begin
  Audio.PlayBlipIncrementScore;
  FInGamePanel.AddToCoin(aValue);
end;


{ TCloudForStorm }

constructor TCloudForStorm.Create(aMovingRectangle: TPointF; aTimeMultiplicator: single);
begin
  inherited Create(texStormCloud, False);
  FMovingRectangle := aMovingRectangle;
  FPulseFactor := aTimeMultiplicator;
  FPulse := PointF(PI*1.17, PI*0.777);
  FAccumulator.x := random*PI;
  FAccumulator.y := random*PI;
end;

procedure TCloudForStorm.Update(const aElapsedTime: single);
const PI2 = 3.1415*2;
begin
  inherited Update(aElapsedTime);

  FAccumulator.x += FPulse.x * FPulseFactor * aElapsedTime;
  if FAccumulator.x > PI2 then FAccumulator.x := FAccumulator.x - PI2;
  FAccumulator.y += FPulse.y * FPulseFactor * aElapsedTime;
  if FAccumulator.y > PI2 then FAccumulator.y := FAccumulator.y - PI2;

  CenterX := cos(FAccumulator.x) * FMovingRectangle.x + FCenterPosOrigin.x;
  CenterY := sin(FAccumulator.y) * FMovingRectangle.y + FCenterPosOrigin.y;
end;

{ TStormCloud }

procedure TStormCloud.Hide;
begin
  if FIsReadyToShoot then exit;
  ClearMessageList;
  PostMessage(100);
end;

constructor TStormCloud.Create(aAtlas: TOGLCTextureAtlas);
var i: integer;
  xx, yy, deltaX, deltaY: single;
  flagPos: boolean;
  o: TCloudForStorm;
begin
  inherited Create(FScene.Width, FScene.Height);
  FScene.Add(Self, LAYER_WEATHER);
  SetAllColorsTo(BGRA(60,0,60));
  Opacity.Value := 0;
  ChildsUseParentOpacity := False;

  // clouds
  FClouds := TSpriteContainer.Create(FScene);
  AddChild(FClouds, 0);
  FClouds.X.Value := 0;
  FClouds.Y.Value := 0;
  xx := -texStormCloud^.FrameWidth*0.2+texStormCloud^.FrameWidth*0.5;
  yy := -texStormCloud^.FrameHeight*0.1+texStormCloud^.FrameHeight*0.5;
  deltaX := texStormCloud^.FrameWidth*0.4;
  deltaY := texStormCloud^.FrameHeight*0.5;
  i := 0;
  flagPos := False;
  repeat
    o := TCloudForStorm.Create(PointF(ScaleW(20), ScaleH(10)), 0.3+random*0.5);
    FClouds.AddChild(o, i);
    if flagPos then o.CenterPosOrigin := PointF(xx,yy+deltaY)
      else o.CenterPosOrigin := PointF(xx,yy);
    flagPos := not flagPos;
    xx := xx + deltaX;
    inc(i);
  until xx > FScene.Width+deltaX;

  FYHide := -texStormCloud^.FrameHeight*2;
  FClouds.Y.Value := FYHide;

  // rain
  FRain := TPArticleEmitter.Create(FScene);
  FRain.LoadFromFile(ParticleFolder+'Rain.par', aAtlas);
  FScene.Add(FRain, LAYER_WEATHER);
  FRain.SetEmitterTypeRectangle(FScene.Width, FScene.Height);
  FRain.FlipH := True;
  FRain.Gravity.Value := PointF(-FScene.Height*0.2, FScene.Height*0.2);
  FRain.ParticlesToEmit.Value := 500;
  FRain.Opacity.Value := 0;

  Freeze := True;
  FIsReadyToShoot := True;
end;

procedure TStormCloud.ProcessMessage(UserValue: TUserMessageValue);
var o: TWolf;
  currentYValue: single;
  beam: TOGLCElectricalBeam;
  i: integer;
begin
  case UserValue of
    // SHOW and shoot multiple storm
    0: begin
      sndStorm.FadeIn(1.0, 1.0);
      Opacity.changeto(150, 0.5);
      FRain.Opacity.changeto(180, 0.5);
      FClouds.Opacity.changeto(255, 0.3);
      FClouds.Y.ChangeTo(0, 0.75);
      Freeze := False;
      FTargetDone := 0;
      PostMessage(1, 0.5);
    end;
    1: begin
      if FTargetDone < PlayerInfo.Forest.StormCloud.TargetCount then begin
        PostMessage(50);     // shoot
        PostMessage(1, 0.5); // and repeat
        inc(FTargetDone);
      end else begin
        PostMessage(100, 1.5); // hide
      end;
    end;

    // SEARCH a possible target and shoot
    50: begin
      // suivant le niveau du stormcloud, on va tirer n éclairs. (préparer
      // chercher les loups en mode wsFlying et crever les ballons de ceux qui sont le plus haut
      currentYValue := FScene.Height*2;
      FTargetWolf := NIL;
      for i:=0 to FScene.Layer[LAYER_WOLF].SurfaceCount-1 do
        if FScene.Layer[LAYER_WOLF].Surface[i] is TWolf then begin
          o := TWolf(FScene.Layer[LAYER_WOLF].Surface[i]);
          if (o.State = wsFlying) and (o.Y.Value < currentYValue) then begin
            currentYValue := o.Y.Value;
            FTargetWolf := TSpriteContainer(o);
          end;
        end;
      if FTargetWolf = NIL then exit;
      TWolf(FTargetWolf).State := wsTargetedByStormCloud;
      // create beam
      beam := TOGLCElectricalBeam.Create(FScene);
      FScene.Add(beam, LAYER_WEATHER);
      beam.BeamColor.Value := BGRA(255,255,255);
      beam.HaloColor.Value := BGRA(255,80,255);
      beam.BeamWidth := ScaleH(3);
      beam.HaloWidth := ScaleH(25);
      beam.SetCoordinate(random*(FScene.Width*0.5)+FScene.Width*0.25, texStormCloud^.FrameHeight*0.75);
      beam.SetTargetPoint(TWolf(FTargetWolf).GetSceneBallonCenterCoor);
      beam.RefreshTime := 0.05;
      beam.KillDefered(1.0);
    end;

    // HIDE
    100: begin
      sndStorm.FadeOut(2.0);
      FIsReadyToShoot := True;
      Opacity.changeto(0, 1.5);
      FRain.Opacity.changeto(0, 1.5);
      FClouds.Opacity.changeto(0, 1.5);
      FClouds.Y.ChangeTo(FYHide, 1);
      PostMessage(101, 1.5);
    end;
    101: begin
      Freeze := True;
    end;
  end;
end;

procedure TStormCloud.Shoot;
begin
  if FIsReadyToShoot then begin
    PostMessage(0, 1);
    FIsReadyToShoot := False;
  end;
end;

{ THammer }

constructor THammer.Create(aInGamePanel: TInGamePanel; aTimeMultiplicator: single);
var i: integer;
begin
  inherited Create(texHammerBox, False);
  FScene.Add(Self, LAYER_FXANIM);

  FTimeMultiplicator := aTimeMultiplicator;
  FInGamePanel := aInGamePanel;

  for i:=0 to High(Part) do begin
    if i < High(Part) then Part[i] := TSprite.Create(texHammerArmPart, False)
      else Part[i] := TSprite.Create(texHammerHead, False);
    if i = 0 then begin
      AddChild(Part[i], -1);
      Part[i].CenterX := Width*0.5;
      Part[i].BottomY := Height*0.9;
    end else begin
      Part[i-1].AddChild(Part[i], 1);
      Part[i].CenterX := Part[i-1].Width*0.5;
      Part[i].BottomY := Part[i-1].Height*0.1;
    end;
    Part[i].Pivot := PointF(0.5, 1);
  end;

  Paf := TSprite.Create(texHammerPaf, False);
  FScene.Add(Paf, LAYER_FXANIM);
  Paf.BindToSprite(Self, Width*1.4, -Height);
  Paf.Opacity.Value := 0;

  PostMessage(200, 1);
end;

procedure THammer.Update(const aElapsedTime: single);
var i: integer;
  xx, yy, w, h: single;
begin
  inherited Update(aElapsedTime);

  if (FInGamePanel.RemainHammer > 0) and (FState = hsReadyToHit) and
     (FScene.Layer[LAYER_WOLF].SurfaceCount > 0) then begin
    // check if there is a wolf into the bump area
    xx := Paf.X.Value;
    yy := Paf.Y.Value;
    w := Paf.Width*2 * TWolf(FScene.Layer[LAYER_WOLF].Surface[0]).TimeMultiplicator; // Paf.Width*3.6;
    h := Paf.Height;
    for i:=0 to FScene.Layer[LAYER_WOLF].SurfaceCount-1 do
      with FScene.Layer[LAYER_WOLF] do
        if Surface[i] is TWolf and (TWolf(Surface[i]).State = wsWalking) and
        TWolf(Surface[i]).CheckCollisionWith(RectF(xx, yy, xx+w, yy+h)) then begin
          if FInGamePanel.RemainHammer > 0 then begin
            FInGamePanel.DecHammerCount;
            Hit;
          end;
        end;
  end;
end;

procedure THammer.ProcessMessage(UserValue: TUserMessageValue);
const TIMEBASE = 1.0;
var i: integer;
d, xx, yy, w, h: single;
begin
  case UserValue of
    // DEVELOP AND HIT
    100: begin
      d := TIMEBASE*FTimeMultiplicator;
      Part[High(Part)].Angle.ChangeTo(0, d, idcSinusoid);
      PostMessage(101, d);
    end;
    101: begin
      d := TIMEBASE*FTimeMultiplicator;
      for i:=1 to High(Part)-1 do
        Part[i].Y.ChangeTo(-Part[0].Height*0.9, d, idcSinusoid);
      PostMessage(102, d);
    end;
    102: begin
      d := TIMEBASE*FTimeMultiplicator;
      for i:=1 to High(Part) do
        Part[i].Angle.ChangeTo(-18, d, idcStartFastEndSlow);
      PostMessage(103, d);
    end;
    103: begin
      d := TIMEBASE*FTimeMultiplicator;
      for i:=1 to High(Part) do
        Part[i].Angle.ChangeTo(24, d, idcBouncy);   //18
      PostMessage(104, d*0.5);
      PostMessage(105, d);
    end;
    104: begin
      sndHammer.Play(True);
      Paf.Opacity.Value := 255;
      Paf.Opacity.ChangeTo(0, 0.5, idcStartSlowEndFast);
      // check collision between Paf and each wolf
      xx := Paf.X.Value;
      yy := Paf.Y.Value;
      w := Paf.Width;
      h := Paf.Height;
      for i:=0 to FScene.Layer[LAYER_WOLF].SurfaceCount-1 do
        with FScene.Layer[LAYER_WOLF] do
          if Surface[i] is TWolf and TWolf(Surface[i]).CheckCollisionWith(RectF(xx, yy, xx+w, yy+h)) then
            TWolf(Surface[i]).State := wsFalling;
    end;
    105: begin
      d := TIMEBASE*FTimeMultiplicator;
      for i:=1 to High(Part) do
        Part[i].Angle.ChangeTo(0, d, idcSinusoid);
      PostMessage(200, d);
    end;

    // COLLAPSE
    200: begin
      d := TIMEBASE*FTimeMultiplicator;
      for i:=1 to High(Part)-1 do
        Part[i].Y.ChangeTo(0, d, idcSinusoid);
      PostMessage(201, d);
    end;
    201: begin
      d := TIMEBASE*FTimeMultiplicator;
      Part[High(Part)].Angle.ChangeTo(-90, d, idcSinusoid);
      PostMessage(202, d);
    end;
    202: begin
      FState := hsReadyToHit;
    end;
  end;
end;

procedure THammer.Hit;
begin
  if FState <> hsReadyToHit then exit;
  FState := hsHitting;
  PostMessage(100);
end;


{ TEscapeDoor }

function TEscapeDoor.GetDoorIsOpened: boolean;
begin
  Result := BelowPart.DoorIsOpened;
end;

constructor TEscapeDoor.Create;
begin
  inherited Create;

  BelowPart := TEscapeDoorBelow.Create;
  BelowPart.BindToSprite(Self, 0, Height*1.2);
end;

procedure TEscapeDoor.OpenTheDoor;
begin
  BelowPart.OpenTheDoor;
end;

{ TEscapeDoorBelow }

constructor TEscapeDoorBelow.Create;
begin
  inherited Create(texEscapeDoorBelowDown, False);
 // FScene.Add(Self, LAYER_GROUND);
  FScene.Insert(0, Self, LAYER_GROUND); // the sprite must be drawn first

  WoodenPillar := TSprite.Create(texEscapeDoorBelowUp, False);
  AddChild(WoodenPillar, 1);
  WoodenPillar.SetCoordinate(Width-WoodenPillar.Width, 0);

  Stone := TDeformationGrid.Create(texEscapeDoorStone, False);
  AddChild(Stone, 0);
  Stone.SetCoordinate(Width*0.3, Height*0.01);
  Stone.SetGrid(20, 1);
end;

procedure TEscapeDoorBelow.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // OPEN THE DOOR
    0: begin
      if FDoorIsOpened then exit;
      inc (FBlinkCount);
      if FBlinkCount = 5 then PostMessage(2)
      else begin
        Stone.Tint.Alpha.ChangeTo(255, 0.4);
        PostMessage(1, 0.4);
      end;
    end;
    1: begin
      if FDoorIsOpened then exit;
      Stone.Tint.Alpha.ChangeTo(0, 0.4);
      PostMessage(0, 0.4);
    end;
    2: begin
      FsndStoneRip := Audio.AddSound('stone_on_stone_st.ogg');
      FsndStoneRip.Loop := True;
      FsndStoneRip.Play(True);
      Stone.ApplyDeformation(dtWindingUp);
      Stone.DeformationSpeed.y.Value := PPIScale(60);
      PostMessage(3, 2.0);
      PostMessage(4, Stone.Height/60);
    end;
    3: begin
      FDoorIsOpened := True;
    end;
    4: begin
      FsndStoneRip.Kill;
      FsndStoneRip := NIL;
    end;
  end;
end;

procedure TEscapeDoorBelow.OpenTheDoor;
begin
  FBlinkCount := 0;
  FDoorIsOpened := False;
  Stone.Tint.Value := BGRA(255,255,255,0);
  PostMessage(0);
end;

{ TEscapeDoorAbove }

constructor TEscapeDoorAbove.Create;
begin
  inherited Create(texEscapeDoorAboveUp, False);
  //FScene.Add(Self, LAYER_GROUND);
  FScene.Insert(0, Self, LAYER_GROUND); // the sprite must be drawn first

  DoorPart2 := TSprite.Create(texEscapeDoorAboveDown, False);
  FScene.Add(DoorPart2, LAYER_PLAYER);
  DoorPart2.BindToSprite(Self, 0, Height*0.85);
end;

{ TElevatorEngine }

procedure TElevatorEngine.SetHitCount(AValue: integer);
begin
  FHitCount := AValue;
  if HitCount >= 3 then Explode;
end;

procedure TElevatorEngine.SetEngineON(AValue: boolean);
begin
  if FEngineON = AValue then Exit;
  FEngineON := AValue;
  if FEngineON then PostMessage(0);
end;

constructor TElevatorEngine.Create(aAtlas: TOGLCTextureAtlas);
var ropeWidth: Integer;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_FXANIM);
  FAtlas := aAtlas;

  Body := TSprite.Create(texMotorBody, False);
  AddChild(Body, 0);
  Body.SetCoordinate(0, 0);

  ropeWidth := PPIScale(3);
  BigWheel := TSprite.Create(texMotorBigWheel, False);
  AddChild(BigWheel, 2);
  BigWheel.RightX := Body.Width*0.5 + ropeWidth*0.5;
  BigWheel.CenterY := Body.Height*0.5;

  Rope := TShapeOutline.Create(FScene);
  Rope.LineColor := BGRA(66,31,5);
  Rope.LineWidth := ropeWidth;
  Rope.Antialiasing := False;
  AddChild(Rope, 1);
  Rope.Pivot := PointF(0.5, 0);

  SmallWheel := TSprite.Create(texMotorSmallWheel, False);
  AddChild(SmallWheel, 1);
  SmallWheel.SetCenterCoordinate(Body.Width*0.65, Body.Height*0.6);

  LeftPiston := TSprite.Create(texMotorLeftPiston, False);
  AddChild(LeftPiston, -1);
  FLeftPistonPosUp := PointF(Body.Width*0.08, LeftPiston.Height*0.1);
  FLeftPistonPosDown:= PointF(Body.Width*0.28, LeftPiston.Height*1.05);
  LeftPiston.SetCenterCoordinate(FLeftPistonPosUp);

  RightPiston := TSprite.Create(texMotorLeftPiston, False);
  AddChild(RightPiston, -1);
  RightPiston.FlipH := True;
  FRightPistonPosUp := PointF(Body.Width*0.83, LeftPiston.Height*0.1);
  FRightPistonPosDown:= PointF(Body.Width*0.63, LeftPiston.Height*1.05);
  RightPiston.SetCenterCoordinate(FRightPistonPosDown);

  EngineON := True;
end;

procedure TElevatorEngine.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // ANIM MOTOR PISTONS
    0: begin
      if not FEngineON then exit;
      Body.Angle.ChangeTo(0.5, 0.1, idcSinusoid);
      LeftPiston.MoveCenterTo(FLeftPistonPosUp, 0.2, idcSinusoid);
      RightPiston.MoveCenterTo(FRightPistonPosDown, 0.2, idcSinusoid);
      PostMessage(1, 0.1);
    end;
    1: begin
      if not FEngineON then exit;
      Body.Angle.ChangeTo(-0.5, 0.1, idcSinusoid);
      PostMessage(2, 0.1);
    end;
    2: begin
      if not FEngineON then exit;
      Body.Angle.ChangeTo(0.5, 0.1, idcSinusoid);
      LeftPiston.MoveCenterTo(FLeftPistonPosDown, 0.2, idcSinusoid);
      RightPiston.MoveCenterTo(FRightPistonPosUp, 0.2, idcSinusoid);
      PostMessage(3, 0.1);
    end;
    3: begin
      if not FEngineON then exit;
      Body.Angle.ChangeTo(-0.5, 0.1, idcSinusoid);
      PostMessage(0, 0.1);
    end;
  end;
end;

procedure TElevatorEngine.SetWheelRotation(aValue: integer);
const ANG_VALUE = 270;
begin
  if aValue < 0 then begin
    BigWheel.Angle.AddConstant(-ANG_VALUE);
    SmallWheel.Angle.AddConstant(ANG_VALUE);
    sndPulley.Play(False);
  end else if aValue = 0 then begin
    BigWheel.Angle.AddConstant(0);
    SmallWheel.Angle.AddConstant(0);
    sndPulley.Stop;
  end else begin
    BigWheel.Angle.AddConstant(ANG_VALUE);
    SmallWheel.Angle.AddConstant(-ANG_VALUE);
    sndPulley.Play(False);
  end;
end;

procedure TElevatorEngine.SetRopeEndPoint(aSceneY: single);
var ropeEndPoint: TPointF;
begin
  // since rope is a child of TElevatorEngine, coordinates are in self coordinates system.
  FRopeBeginPoint := PointF(Body.Width*0.5, Body.Height*0.5);

  ropeEndPoint.x := FRopeBeginPoint.x;
  ropeEndPoint.y := aSceneY-Y.Value;

  Rope.SetShapeLine(FRopeBeginPoint, ropeEndPoint);
end;

procedure TElevatorEngine.Explode;
begin
  if FBreaked then exit;
  FEngineON := False;
  FSmoke := TParticleEmitter.Create(FParentScene);
  AddChild(FSmoke, 5);
  FSmoke.LoadFromFile(ParticleFolder+'ElevatorSmoke.par', FAtlas);
  FSmoke.SetCoordinate(Body.Width*0.15, Body.Height*0.9);
  FSmoke.SetEmitterTypeLine(0, Body.Width*0.70);
  FBreaked := True;
end;

{ TGround1 }

constructor TGround1.Create;
begin
  inherited Create(texGround1, False);
  FScene.Add(Self, LAYER_GROUND);
end;

{ TGround1Right }

constructor TGround1Right.Create;
begin
  inherited Create(texGround1Right, False);
  FScene.Add(Self, LAYER_GROUND);
end;

{ TGround1Left }

constructor TGround1Left.Create;
begin
  inherited Create(texGround1Left, False);
  FScene.Add(Self, LAYER_GROUND);
end;

{ TBalloonCrate }

constructor TBalloonCrate.Create(aX, aY: single);
begin
  inherited Create(texBalloonCrate, False);
  FScene.Add(Self, LAYER_FXANIM);
  SetCoordinate(aX, aY);
end;

{ TPlatformLR }

constructor TPlatformLR.Create;
begin
  inherited Create(texPlatformLR, False);
  FScene.Add(Self, LAYER_PLAYER);
end;

end.

