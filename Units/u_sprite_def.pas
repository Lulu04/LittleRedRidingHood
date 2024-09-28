unit u_sprite_def;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  ALSound,OGLCScene, BGRABitmap, BGRABitmapTypes,
  u_audio, u_sprite_lrcommon, u_ui_panels;

type

{ TProgressLine }

TProgressLine = class(TShapeOutline)
private class var texLRIcon: PTexture;
private
  FDistanceToTravel: single;
  FDistanceTraveled: single;
  FLRIcon: TSprite;
  procedure SetDistanceTraveled(AValue: single);
public
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas);
  constructor Create;
  property DistanceToTravel: single read FDistanceToTravel write FDistanceToTravel;
  property DistanceTraveledByLR: single read FDistanceTraveled write SetDistanceTraveled;
end;


{ TBigFire }

TBigFire = class(TParticleEmitter)
  // need texture Cloud128x128.png loaded in the atlas
  constructor Create(aX, aY: single; aLayerIndex: integer; aAtlas: TOGLCTextureAtlas);
end;

{ TFireLine }

TFireLine = class(TParticleEmitter)
private
  FSmoke: TParticleEmitter;
public
  // need texture Flame.png and sphere_particle.png loaded in the atlas
  constructor Create(aX, aY: single; aLayerIndex: integer; aAtlas: TOGLCTextureAtlas);
end;

{ TSmokeLine }

TSmokeLine = class(TParticleEmitter)
  // need texture sphere_particle.png loaded in the atlas
  constructor Create(aX, aY: single; aLayerIndex: integer; aAtlas: TOGLCTextureAtlas);
end;

{ TSmokePoint }

TSmokePoint = class(TParticleEmitter)
  // need texture sphere_particle.png loaded in the atlas
  constructor Create(aX, aY: single; aLayerIndex: integer; aAtlas: TOGLCTextureAtlas);
end;

{ TImpact1 }

TImpact1 = class(TSprite)
  // need texture sphere_particle.png loaded in the atlas
private class var texImpact1: PTexture;
  class var FAtlas: TOGLCTextureAtlas;
private
  FSmoke: TSmokePoint;
public
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas);
  constructor Create(aX, aY: single; aLayerIndex: integer);
  procedure Update(const aElapsedTime: single); override;
end;

{ TPanelDecodingDigicode }

TPanelDecodingDigicode = class(TPanelWithBGDarkness)
public
  class var texWallBG, texDigicode, texLRArm,
            texDecoderBody, texDecoderLightOff, texDecoderWheel, texDecoderBeam: PTexture;
private
  FDigicode: TSprite;
  FDecoderBody, FWheel, FLightOnOff, FLight1, FLight2, FLight3, FLight4, FBeam, FLRArm: TSprite;
  FScanIsDone: boolean;
  FsndDecoderScanning: TALSSound;
  class var FComputedWidth: single;
public
  class procedure LoadTextures(aAtlas: TOGLCTextureAtlas);
  constructor Create;
  procedure Show; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  property ScanIsDone: boolean read FScanIsDone;
end;

{ TPanelUsingComputer }

TPanelUsingComputer = class(TPanelWithBGDarkness)
private class var texArm, texSDCard, texKeyboard, texSDSlot, texMouse,
       texIconConversation, texJuliaFace, texRomeoFace: PTexture;
private
  FArmRight, FArmLeft, FSDCard, FSDSlot, FKeyboard, FMouse: TSprite;
  FBoard: TUIPanel;
  FFont: TTexturedFont;
  FAnimIsDone: boolean;
  procedure HideArmsToBottom;
  procedure CenterArmsAboveKeyboard;
  procedure MoveRightArmOnMouse;
private // console mode
  FConsole: TUITextArea;
  FCursorBlink: boolean;
  FConsoleText: string;
  procedure SetConsoleMode(aClearContent: boolean);
  procedure SetConsoleText(const s: string);
private // gui mode
  FSB: TUIScrollBox;
  FFakeMouseFollowPlayerMouse: boolean;
  FMousePositionOrigin: TPointF;
  FYNext: single;
  FBOpenConversation, FBOpenArmouredDoor: TUIButton;
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
  procedure AddTextToGui(aFaceTexture: PTexture; const Name, s: string; aNameColor: TBGRAPixel; aOnLeftSide: boolean);
  procedure SetGUIMode(aClearContent: boolean);
  procedure CreateButtonOpenConversation;
  procedure AddConversationBetweenRomeoAndJulia;
public
  class procedure LoadTextures(aAtlas: TOGLCTextureAtlas);
  constructor Create(aFont: TTexturedFont);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure StartAnimSDCardVolcano;
  // True when player click button 'open armored door'
  property AnimIsDone: boolean read FAnimIsDone;
end;

{ TLittleRobot }

TLittleRobot = class(TWalkingCharacter)
private class var texWheel, texBody, texArm, texFingerLeft, texFingerRight: PTexture;
private
  FWheel1, FWheel2, FBody, FArm, FFingerLeft, FFingerRight: TSprite;
  FTimeMultiplicator: single;
  FFingerKnitting: boolean;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas);
  constructor Create(aX, aYBottomWheel: single; aLayerIndex: integer=-1);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
public // move utils
  procedure FingerStartKnitting;
  procedure FingerStopKnitting;
  procedure MoveArmForward;
  procedure MoveArmDown;
  procedure WalkHorizontallyTo(aX: single; aMessageReceiver: TObject; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);

  property TimeMultiplicator: single read FTimeMultiplicator write FTimeMultiplicator;
end;

{ TLittleRobotConstructor }

TLittleRobotConstructor = class(TBaseComplexContainer)
public class var
  texWheel, texLegLeft, texLegRight, texLavaReceptor, texArm, texFingerLeft, texFingerRight,
  texArmAxis, texGear, texParticle: PTexture;
  class var FAtlas: TOGLCTextureAtlas;
private type
  TArm = class(TSpriteContainer)
  private
    FAxis, FArm, FFingerLeft, FFingerRight: TSprite;
    FFingerKnitting: boolean;
  protected
    procedure SetFlipH(AValue: boolean); override;
  public
    constructor Create(aXCenterAxis, aYBottomAxis: single);
    procedure ProcessMessage(UserValue: TUserMessageValue); override;
    procedure FingerStartKnitting;
    procedure FingerStopKnitting;
    procedure PrepareToConstructNewOne;
    procedure MoveArmToTop;
    procedure MoveArmToReleaseRobot;
  end;
private
  FBody: TUIPanel;
  FWheelLeft, FWheelRight, FLegLeft, FLegRight, FLavaReceptorLeft, FLavaReceptorRight, FGearSmall, FGearBig: TSprite;
  FArmLeft, FArmRight: TArm;
  FPE: TParticleEmitter;
  FsndBlowtorch, FsndElectricalMotor: TALSSound;
  FLittleRobot: TLittleRobot;
  FImpact1, FImpact2: TImpact1;
  FConstructing, FRobotConstructed, FConstructionFinished: boolean;
  function GetBodyPath: TOGLCPath;
  function GetRobotConstructed: boolean;
public
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas);
  constructor Create(aXCenter, aYBottomWheel: single; aLayerIndex: integer);
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure StartConstructing;
  procedure StopConstructing;
  procedure StopGearsRotation;
  procedure PlaySoundMoveMotor;
  procedure PlaySoundMoveMotorAtMaxSpeed;
  procedure StopSoundMoveMotor;
  procedure SetWheelsAngleTo(aAngle, aDuration: single; aCurve: integer);
  procedure CreateImpacts;
  property RobotConstructed: boolean read GetRobotConstructed;
  property ConstructionFinished: boolean read FConstructionFinished;
end;

{ TPump }

TPump = class(TSpriteWithElasticCorner)
public class var texPumpBody, texPumpGaugeDial, texPumpGaugeArrow: PTexture;
  class var FAtlas: TOGLCTextureAtlas;
//private
public
  FGauge, FArrow: TSprite;
  FSmoke: TParticleEmitter;
  FInitialCoor: TPointF;
  FShakeDuration: single;
  FAccelerateShakeToMax: boolean;
  FsndEngine: TALSSound;
public
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas);
  constructor Create(aX, aY: single; aLayerIndex: integer);
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure SetNormalSpeed;
  procedure SetMaximumSpeed;
  procedure CreateSmoke;
  procedure StopSmoke;
end;

{ TPropulsorConstructor }

TPropulsorConstructor = class(TBaseComplexContainer)
public class var texPropulsorForMachine: PTexture;
private
  FLavaReceptorLeft, FLavaReceptorRight, FGearSmall, FGearBig: TSprite;
  FPE: TParticleEmitter;
  FBody: TUIPanel;
  FPropulsor: TSprite;
  FRobot: TLittleRobot;
  FsndBlowtorch: TALSSound;
  function GetBodyPath: TOGLCPath;
  procedure PlacePropulsorIntoTheMachine;
public
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas);
  // need TLittleRobotConstructor texture loaded.
  constructor Create(aX, aY: single; aLayerIndex: integer);
  destructor Destroy; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

{ TDino }
TDinoState = (dsUnknown, dsIdle, dsRush, dsBendDown, dsArmGoodbye, dsHugPosition);
TDino = class(TCharacterWithDialogPanel)
private class var texHead, texJaw, texBody, texRightArm, texLeftArm, texLeftLeg, texRightThigh, texRightFeet, texTail: PTexture;
private
  FDinoState: TDinoState;
  FBody, FLeftArm, FLeftLeg, FRightThigh, FRightFeet, FTail: TSprite;
  FCanMoveInRushPosition, FHeadIsTurnedBackward: boolean;
  FsndRunningStep, FsndDinoOvertakeLR, FsndDinoOvertakenByLR: TALSSound;
  procedure SetDinoState(AValue: TDinoState);
  procedure SetIdlePosition(aImmediate: boolean);
  procedure TurnHeadForward;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  FHead, FJaw, FRightArm: TSprite;
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas);
  constructor Create(aX, aY: single; aLayerIndex: integer);
  destructor destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure TurnHeadBackward(aStayTime: single);
  procedure PlaySoundDinoOvertakeLR;
  procedure PlaySoundDinoOvertakenByLR;
  procedure BendDown(aDuration: single);
  procedure SetHugPosition(aDuration: single);
  property State: TDinoState read FDinoState write SetDinoState;
  property CanMoveInRushPosition: boolean read FCanMoveInRushPosition;
end;


implementation
uses u_common, u_app, u_resourcestring, BGRAPath;

{ TDino }

procedure TDino.SetDinoState(AValue: TDinoState);
begin
  if FDinoState = AValue then Exit;
  FDinoState := AValue;
  FsndRunningStep.Stop;

  case AValue of
    dsIdle: begin
      SetIdlePosition(False);
      PostMessage(0);
    end;

    dsRush: begin
      FCanMoveInRushPosition := False;
      PostMessage(100);
    end;

    dsArmGoodbye: PostMessage(300);
  end;
end;

class procedure TDino.LoadTexture(aAtlas: TOGLCTextureAtlas);
var path: string;
begin
  path := SpriteDinoFolder;
  texJaw := aAtlas.AddFromSVG(path+'Jaw.svg', ScaleW(86), -1);
  texLeftArm := aAtlas.AddFromSVG(path+'LeftArm.svg', -1, ScaleH(74));
  texRightArm := aAtlas.AddFromSVG(path+'RightArm.svg', -1, ScaleH(65));
  texRightThigh := aAtlas.AddFromSVG(path+'RightThigh.svg', ScaleW(50), -1);
  texRightFeet := aAtlas.AddFromSVG(path+'RightFeet.svg', ScaleW(40), -1);
  texLeftLeg := aAtlas.AddFromSVG(path+'LeftLeg.svg', ScaleW(74), -1);
  texTail := aAtlas.AddFromSVG(path+'Tail.svg', ScaleW(149), -1);
  texBody := aAtlas.AddFromSVG(path+'Body.svg', ScaleW(133), -1);
  texHead := aAtlas.AddFromSVG(path+'Head.svg', ScaleW(96), -1);
end;

constructor TDino.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
  DialogAuthorName := 'Dino';
  MarkOffset := PointF(texhead^.FrameWidth*0.6, -texhead^.FrameHeight*0.2);

  FBody := TSprite.Create(texBody, False);
  AddChild(FBody, 0);
  FBody.CenterX := 0;
  FBody.BottomY := 0;
  FBody.ApplySymmetryWhenFlip := True;
  FBody.Pivot := PointF(0.0, 0.7);

    FTail := TSprite.Create(texTail, False);
    FBody.AddChild(FTail, -1);
    FTail.X.Value := -FTail.Width*0.5;
    FTail.Y.Value := FBody.Height - FTail.Height;
    FTail.ApplySymmetryWhenFlip := True;
    FTail.Pivot := PointF(0.7, 0.8);

    FHead := TSprite.Create(texHead, False);
    FBody.AddChild(FHead, 0);
    FHead.X.Value := FBody.Width*0.75;
    FHead.Y.Value := -FHead.Height*0.4;
    FHead.ApplySymmetryWhenFlip := True;
    FHead.Pivot := PointF(0.2, 0.4);
      FJaw := TSprite.Create(texJaw, False);
      FHead.AddChild(FJaw, -1);
      FJaw.X.Value := FHead.Width*0.05;
      FJaw.Y.Value := FHead.Height*0.5;
      FJaw.ApplySymmetryWhenFlip := True;
      FJaw.Pivot := PointF(0, 0);

    FRightArm := TSprite.Create(texRightArm, False);
    FBody.AddChild(FRightArm, 2);
    FRightArm.CenterX := FBody.Width*0.5;
    FRightArm.Y.Value := FBody.Height*0.5;
    FRightArm.ApplySymmetryWhenFlip := True;
    FRightArm.Pivot := PointF(1, 0);

    FLeftArm := TSprite.Create(texLeftArm, False);
    FBody.AddChild(FLeftArm, -1);
    FLeftArm.X.Value := FBody.Width*0.65;
    FLeftArm.Y.Value := FBody.Height*0.55;
    FLeftArm.ApplySymmetryWhenFlip := True;
    FLeftArm.Pivot := PointF(0.9, 0.0);

  FLeftLeg := TSprite.Create(texLeftLeg, False);
  AddChild(FLeftLeg, -1);
  FLeftLeg.X.Value := FBody.Width*0.0;
  FLeftLeg.Y.Value := -FLeftLeg.Height*0.18;
  FLeftLeg.ApplySymmetryWhenFlip := True;
  FLeftLeg.Pivot := PointF(0.1, 0.0);

  FRightThigh := TSprite.Create(texRightThigh, False);
  AddChild(FRightThigh, 1);
  FRightThigh.X.Value := -FRightThigh.Width*1.3; //1.2;
  FRightThigh.Y.Value := -FRightThigh.Height*0.95;
  FRightThigh.ApplySymmetryWhenFlip := True;
  FRightThigh.Pivot := PointF(0.5, 0.35);
    FRightFeet := TSprite.Create(texRightFeet, False);
    FRightThigh.AddChild(FRightFeet, 0);
    FRightFeet.X.Value := -FRightFeet.Width*0.15;
    FRightFeet.Y.Value := FRightThigh.Height*0.85;
    FRightFeet.ApplySymmetryWhenFlip := True;
    FRightFeet.Pivot := PointF(0.6, 0.05);

  DeltaYToTop := FBody.Height + FHead.Height*0.2;
  DeltaYToBottom := Trunc(FRightFeet.Height*0.9);
  BodyWidth := Trunc(FBody.Width*1.8);
  BodyHeight := Trunc(DeltaYToBottom + DeltaYToTop);

  FsndRunningStep := Audio.AddSound('DinoRunningStepLoop.ogg', 1.0, True);
  FsndRunningStep.PositionRelativeToListener := False;
  FsndRunningStep.DistanceModel := AL_INVERSE_DISTANCE_CLAMPED;
  FsndRunningStep.Attenuation3D(FBody.Width*3, FScene.Width*2, 3.0, 1.0);

  FsndDinoOvertakeLR := Audio.AddSound('DinoOvertakeLR.ogg', 1.0, False);
  FsndDinoOvertakeLR.Pitch.Value := 0.8;
  FsndDinoOvertakeLR.PositionRelativeToListener := False;
  FsndDinoOvertakeLR.DistanceModel := AL_INVERSE_DISTANCE_CLAMPED;
  FsndDinoOvertakeLR.Attenuation3D(FBody.Width*3, FScene.Width*2, 3.0, 1.0);

  FsndDinoOvertakenByLR := Audio.AddSound('DinoOvertakenByLR.ogg', 1.0, False);
  FsndDinoOvertakenByLR.Pitch.Value := 0.8;
  FsndDinoOvertakenByLR.PositionRelativeToListener := False;
  FsndDinoOvertakenByLR.DistanceModel := AL_INVERSE_DISTANCE_CLAMPED;
  FsndDinoOvertakenByLR.Attenuation3D(FBody.Width*3, FScene.Width*2, 3.0, 1.0);

  TimeMultiplicator := 1.0;
end;

destructor TDino.destroy;
begin
  FsndRunningStep.Kill;
  FsndRunningStep := NIL;
  FsndDinoOvertakeLR.Kill;
  FsndDinoOvertakeLR := NIL;
  FsndDinoOvertakenByLR.Kill;
  FsndDinoOvertakenByLR := NIL;
  inherited destroy;
end;

procedure TDino.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  // update sound position to dino position
  FsndRunningStep.Position3D(X.Value, Y.Value, -1.0);
  FsndDinoOvertakeLR.Position3D(X.Value, Y.Value, -1.0);
  FsndDinoOvertakenByLR.Position3D(X.Value, Y.Value, -1.0);
end;

procedure TDino.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // IDLE state
    0: begin
      PostMessage(10);
      PostMessage(15);
    end;
    10: begin // Tail random balancing
      if not (FDinoState in [dsIdle, dsArmGoodbye, dsHugPosition]) then exit;
      d := (1.0 + Random) * TimeMultiplicator;
      FTail.Angle.ChangeTo(Random*40-20, d, idcSinusoid);
      PostMessage(10, d + random*TimeMultiplicator);
    end;
    15: begin // body balancing
      if not (FDinoState in [dsIdle, dsArmGoodbye]) then exit;
      FBody.Angle.ChangeTo(Random, 1.5, idcSinusoid);
      PostMessage(16, 1.5);
    end;
    16: begin
      if FDinoState <> dsIdle then exit;
      FBody.Angle.ChangeTo(-Random, 1.5, idcSinusoid);
      PostMessage(15, 1.5);
    end;

    // RUSH anim
    100: begin  // dino bend down
      Angle.ChangeTo(15, 0.5, idcSinusoid);
      PostMessage(110, 0.5);
      PostMessage(101, 0.5);
    end;
    101: FsndRunningStep.Play(True);
    110: begin  // repeat fast legs moves
      d := 0.1;
      if FDinoState <> dsRush then exit;
      FCanMoveInRushPosition := True;
      FLeftLeg.Angle.ChangeTo(-31, d, idcSinusoid);
      FRightThigh.Angle.ChangeTo(31, d, idcSinusoid);
      FRightFeet.Angle.ChangeTo(94, d, idcSinusoid);
      FLeftArm.Angle.ChangeTo(0, d, idcSinusoid);
      FRightArm.Angle.ChangeTo(-122, d, idcSinusoid);
      FBody.Angle.ChangeTo(13, d, idcSinusoid);
      PostMessage(112, d);
    end;
    112: begin
      d := 0.1;
      if FDinoState <> dsRush then exit;
      FLeftLeg.Angle.ChangeTo(109, d, idcSinusoid);
      FRightThigh.Angle.ChangeTo(-60, d, idcSinusoid);
      FRightFeet.Angle.ChangeTo(0, d, idcSinusoid);
      FLeftArm.Angle.ChangeTo(-105, d, idcSinusoid);
      FRightArm.Angle.ChangeTo(45, d, idcSinusoid);
      FBody.Angle.ChangeTo(17, d, idcSinusoid);
      PostMessage(110, d);
    end;

    // End of TurnHeadBackward
    200: TurnHeadForward;

    // Dino say good bye with its arm
    300: begin
      if FDinoState <> dsArmGoodbye then exit;
      FRightArm.Angle.ChangeTo(-140, 0.8, idcSinusoid);
      PostMessage(301, 0.8);
    end;
    301: begin
      if FDinoState <> dsArmGoodbye then exit;
      FRightArm.Angle.ChangeTo(-103, 0.8, idcSinusoid);
      PostMessage(300, 0.8);
    end;


    // reset the pivot to normal
    350: FBody.Pivot := PointF(0.0, 0.7);
  end;
end;

procedure TDino.TurnHeadBackward(aStayTime: single);
begin
  if FHeadIsTurnedBackward then exit;
  FHeadIsTurnedBackward := True;
  FHead.ApplySymmetryWhenFlip := False;
  FJaw.ApplySymmetryWhenFlip := False;
  FHead.FlipH := not FHead.FlipH;
  FJaw.FlipH := not FJaw.FlipH;
  FHead.X.Value := FHead.X.Value-FHead.Width*0.5;
  PostMessage(200, aStayTime);
end;

procedure TDino.PlaySoundDinoOvertakeLR;
begin
  FsndDinoOvertakeLR.Play;
end;

procedure TDino.PlaySoundDinoOvertakenByLR;
begin
  FsndDinoOvertakenByLR.Play;
end;

procedure TDino.BendDown(aDuration: single);
begin
  FDinoState := dsBendDown;
  FBody.Pivot := PointF(0.5, 0.7);
  FBody.Angle.ChangeTo(87, aDuration, idcSinusoid);
  FHead.Angle.ChangeTo(-35, aDuration, idcSinusoid);
  FRightArm.Angle.ChangeTo(-113, aDuration, idcSinusoid);
  FLeftArm.Angle.ChangeTo(-130, aDuration, idcSinusoid);
end;

procedure TDino.SetHugPosition(aDuration: single);
begin
  FDinoState := dsHugPosition;
  FLeftLeg.MoveYRelative(-FLeftLeg.Height*0.65, aDuration, idcSinusoid);
  FRightThigh.Angle.ChangeTo(-80, aDuration, idcSinusoid);
  FRightFeet.Angle.ChangeTo(70, aDuration, idcSinusoid);
end;

procedure TDino.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FHead.FlipH := AValue;
  FJaw.FlipH := AValue;
  FBody.FlipH := AValue;
  FRightArm.FlipH := AValue;
  FLeftArm.FlipH := AValue;
  FLeftLeg.FlipH := AValue;
  FRightThigh.FlipH := AValue;
  FRightFeet.FlipH := AValue;
  FTail.FlipH := AValue;
end;

procedure TDino.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FHead.FlipV := AValue;
  FJaw.FlipV := AValue;
  FBody.FlipV := AValue;
  FRightArm.FlipV := AValue;
  FLeftArm.FlipV := AValue;
  FLeftLeg.FlipV := AValue;
  FRightThigh.FlipV := AValue;
  FRightFeet.FlipV := AValue;
  FTail.FlipV := AValue;
end;

procedure TDino.SetIdlePosition(aImmediate: boolean);
var d: single;
begin
  TurnHeadForward;
  if aImmediate then d := 0 else d := 1.0*TimeMultiplicator;
  Angle.ChangeTo(0, d);
  FJaw.Angle.ChangeTo(0, d);
  FTail.Angle.ChangeTo(0, d);
  FRightArm.Angle.ChangeTo(-25, d);
  FLeftArm.Angle.ChangeTo(-25, d);
  FLeftLeg.Angle.ChangeTo(0, d);
  FRightThigh.Angle.ChangeTo(0, d);
  FRightFeet.Angle.ChangeTo(0, d);
  FHead.Angle.ChangeTo(0, d);
  FJaw.Angle.ChangeTo(0, d);
  PostMessage(350, d); // reset the pivot
end;

procedure TDino.TurnHeadForward;
begin
  if not FHeadIsTurnedBackward then exit;
  FHeadIsTurnedBackward := False;
  FHead.FlipH := not FHead.FlipH;
  FHead.ApplySymmetryWhenFlip := True;
  FJaw.FlipH := not FJaw.FlipH;
  FJaw.ApplySymmetryWhenFlip := True;
  FHead.X.Value := FHead.X.Value+FHead.Width*0.5;
end;

{ TPanelUsingComputer }

procedure TPanelUsingComputer.HideArmsToBottom;
begin
  FArmRight.Angle.Value := 0;
  FArmRight.RightX := FKeyboard.RightX;
  FArmRight.Y.Value := FBoard.BottomY;

  FArmLeft.Angle.Value := 0;
  FArmLeft.X.Value := FKeyboard.X.Value;
  FArmLeft.Y.Value := FBoard.BottomY;
end;

procedure TPanelUsingComputer.CenterArmsAboveKeyboard;
var yy: single;
begin
  yy := FKeyBoard.Y.Value+FKeyBoard.Height*0.5;
  FArmRight.Angle.ChangeTo(-16, 1.0, idcSinusoid);
  FArmRight.MoveTo(FKeyBoard.RightX-FArmRight.Width*1.2, yy, 1.0, idcSinusoid);
  FArmLeft.Angle.ChangeTo(16, 1.0, idcSinusoid);
  FArmLeft.MoveTo(FKeyBoard.X.Value+FArmLeft.Width*0.2, yy, 1.0, idcSinusoid);
end;

procedure TPanelUsingComputer.MoveRightArmOnMouse;
begin
  FArmRight.Angle.ChangeTo(9, 1.0, idcSinusoid);
  FArmRight.MoveTo(FMouse.X.Value, FMouse.Y.Value+FMouse.Height*0.4, 1.0, idcSinusoid);
end;

procedure TPanelUsingComputer.SetConsoleText(const s: string);
begin
  FConsole.Text.Caption := s;
end;

procedure TPanelUsingComputer.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  if Sender = FBOpenConversation then begin
    PostMessage(300);
  end;

  if Sender = FBOpenArmouredDoor then begin
    Hide(False);
    FAnimIsDone := True;
   // if FBOpenArmouredDoor.MouseIsOver then FSB.Tint.Value:=BGRA(255,255,0,128)
   //   else FSB.Tint.Value:=BGRA(255,255,0,0);
  end;
end;

procedure TPanelUsingComputer.SetConsoleMode(aClearContent: boolean);
begin
  FConsole.BodyShape.Fill.Color := BGRA(153,219,254);
  FConsole.Text.Tint.Value := BGRABlack;
  FConsole.Visible := True;
  FSB.Visible := False;
  if aClearContent then begin
    FConsoleText := '';
    FConsole.Text.Caption := '';
  end;
end;

procedure TPanelUsingComputer.SetGUIMode(aClearContent: boolean);
begin
  FConsole.Visible := False;
  FSB.Visible := True;
  if aClearContent then begin
    FSB.DeleteAllChilds;
    FYNext := PPIScale(3);
  end;
end;

procedure TPanelUsingComputer.CreateButtonOpenConversation;
begin
  FBOpenConversation := TUIButton.Create(FScene, sConversation+'.txt', FFont, texIconConversation);
  FSB.AddChild(FBOpenConversation);
  FBOpenConversation.BodyShape.SetShapeRoundRect(Round(FSB.Width*0.5), Round(texIconConversation^.FrameHeight*1.1),
             PPIScale(8), PPIScale(8), PPIScale(2));
  FBOpenConversation._Label.Tint.Value := BGRA(220,220,220);
  FBOpenConversation.AnchorPosToParent(haCenter, haCenter, 0, vaCenter, vaCenter, 0);
  FBOpenConversation.OnClick := @ProcessButtonClick;

  //FBOpenConversation._Label.Tint.Value := BGRAWhite;
end;

procedure TPanelUsingComputer.AddConversationBetweenRomeoAndJulia;
const R='ROMEO'; J='JULIA';
begin
  AddTextToGui(texRomeoFace, R, sRomeo1, BGRA(107,192,255), True);
  AddTextToGui(texJuliaFace, J, sJulia1, BGRA(245,94,140), False);
  AddTextToGui(texRomeoFace, R, sRomeo2, BGRA(107,192,255), True);
  AddTextToGui(texJuliaFace, J, sJulia2, BGRA(245,94,140), False);

  FBOpenArmouredDoor := TUIButton.Create(FScene, sOpenArmouredDoor, FFont, NIL);
  FBOpenArmouredDoor.BodyShape.SetShapeRoundRect(10, 10, PPIScale(8), PPIScale(8), PPIScale(2));
  FSB.AddChild(FBOpenArmouredDoor);
  FBOpenArmouredDoor._Label.Tint.Value := BGRA(255,255,175);
  FBOpenArmouredDoor.CenterX := FSB.Width*0.5;
  FBOpenArmouredDoor.Y.Value := FYNext;
  FBOpenArmouredDoor.OnClick := @ProcessButtonClick;
end;

procedure TPanelUsingComputer.AddTextToGui(aFaceTexture: PTexture; const Name, s: string; aNameColor: TBGRAPixel; aOnLeftSide: boolean);
var lab: TUILabel;
    t: TFreeTextAligned;
    face: TSprite;
begin
  // face
  face := TSprite.Create(aFaceTexture, False);
  FSB.AddChild(face);
  face.Y.Value := FYNext;
  // name
  lab := TUILabel.Create(FScene, Name, FFont);
  lab.Tint.Value := aNameColor;
  FSB.AddChild(lab);
  if aOnLeftSide then begin
    face.X.Value := 0;
    lab.X.Value := face.RightX + PPIScale(5);
  end else begin
    lab.RightX := FSB.Width*0.95; //-PPIScale(3);
    face.RightX := lab.X.Value - PPIScale(5);
  end;
  lab.BottomY := face.BottomY;

  t := TFreeTextAligned.Create(FScene, FFont, Round(FSB.Width*0.9), MaxInt);
  t.Tint.Value := aNameColor; //BGRA(220,220,220);
  t.Align := taTopLeft;
  t.Caption := s;
  t.SetSize(t.DrawingRect.Width, t.DrawingRect.Height);
  FSB.AddChild(t);
  if aOnLeftSide then t.X.Value := 0 //PPIScale(3)
    else t.RightX := FSB.Width*0.95; //-PPIScale(3);
  t.Y.Value := lab.BottomY;

  FYNext := {FYNext +} t.Y.Value + t.Height + PPIScale(20);
end;

class procedure TPanelUsingComputer.LoadTextures(aAtlas: TOGLCTextureAtlas);
begin
  texArm := aAtlas.RetrieveTextureByFileName('PanelDecodeLRArm.svg');
  if texArm = NIL then
    texArm := aAtlas.AddFromSVG(SpriteGameVolcanoEntranceFolder+'PanelDecodeLRArm.svg', ScaleW(41), -1);

  texSDCard := aAtlas.RetrieveTextureByFileName('SDCardGreen.svg');
  if texSDCard = NIL then
    texSDCard := aAtlas.AddFromSVG(SpriteUIFolder+'SDCardGreen.svg', ScaleW(45), -1);

  texKeyboard := aAtlas.AddFromSVG(SpriteGameVolcanoDinoFolder+'ComputerKeyboard.svg', ScaleW(125), -1);
  texSDSlot := aAtlas.AddFromSVG(SpriteGameVolcanoDinoFolder+'ComputerSDCardSlot.svg', ScaleW(55), -1);
  texMouse := aAtlas.AddFromSVG(SpriteGameVolcanoDinoFolder+'ComputerMouse.svg', ScaleW(35), -1);
  texIconConversation := aAtlas.AddFromSVG(SpriteGameVolcanoDinoFolder+'ComputerIconConversation.svg', ScaleW(32), -1);
  texJuliaFace := aAtlas.AddFromSVG(SpriteUIFolder+'FaceJulia.svg', ScaleW(64), -1);
  texRomeoFace := aAtlas.AddFromSVG(SpriteUIFolder+'FaceRomeo.svg', ScaleW(64), -1);
end;

constructor TPanelUsingComputer.Create(aFont: TTexturedFont);
var w, h, marg: integer;
begin
  w := FScene.Width div 2;
  h := FScene.Height div 2;
  inherited CreateAsRect(w, h);
  CenterOnScene;
  FFont := aFont;
  marg := PPIScale(10);

  FConsole := TUITextArea.Create(FScene);
  AddChild(FConsole, 3);
  FConsole.BodyShape.SetShapeRoundRect(Round(w-marg*2), Round((h-marg)*0.75), PPIScale(8), PPIScale(8), 2.0);  //Round(h*0.79), PPIScale(8), PPIScale(8), 2.0);
  FConsole.BodyShape.Fill.Color := BGRA(0,75,128);
  FConsole.BodyShape.Border.Width := 4.0;
  FConsole.BodyShape.Border.Color := BGRA(0,75,128);
  FConsole.Text.TexturedFont := aFont;
  FConsole.Text.Tint.Value := BGRA(0,0,0);
  FConsole.Text.Align := taTopLeft;
  FConsole.CenterX := w*0.5;
  FConsole.Y.Value := marg;

  FSB := TUIScrollBox.Create(FScene, True, False);
  FSB.VScrollBarMode := sbmAuto;
  AddChild(FSB, 3);
  FSB.BodyShape.SetShapeRoundRect(FConsole.Width, FConsole.Height, PPIScale(8), PPIScale(8), 2.0);  //Round(h*0.79), PPIScale(8), PPIScale(8), 2.0);
  FSB.BodyShape.Border.Width := 4.0;
  FSB.BodyShape.Border.Color := BGRA(0,75,128);
  //FSB.BodyShape.Fill.Color := BGRA(0,75,128);
  FSB.SetCoordinate(FConsole.GetXY);


  FBoard := TUIPanel.Create(FScene);
  AddChild(FBoard, 0);
  FBoard.BodyShape.SetShapeRectangle(FConsole.Width, h-FConsole.Height, 2.0);
  FBoard.BodyShape.Fill.Color := BGRA(142,160,164);
  FBoard.BodyShape.Border.Color := BGRABlack;
  FBoard.SetCoordinate(FConsole.X.Value, FConsole.BottomY);

  FKeyboard := TSprite.Create(texKeyboard, False);
  AddChild(FKeyboard, 1);
  FKeyboard.CenterX := FBoard.CenterX;
  FKeyboard.CenterY := FBoard.Y.Value+FBoard.Height*0.6;

  FMouse := TSprite.Create(texMouse, False);
  AddChild(FMouse, 1);
  FMouse.X.Value := FKeyboard.RightX + FMouse.Width*1.3;
  FMouse.CenterY := FKeyboard.CenterY;
  FMouse.Angle.Value := -12;
  FMousePositionOrigin := FMouse.GetXY;

  FSDSlot := TSprite.Create(texSDSlot, False);
  AddChild(FSDSlot, 1);
  FSDSlot.SetCoordinate(Round(FBoard.X.Value+FBoard.Width*0.65), Round(FBoard.Y.Value)); // Round(FBoard.BottomY-FSDSlot.Height*1.08));

  FArmRight := TSprite.Create(texArm, False);
  AddChild(FArmRight, 2);
  FArmRight.Pivot := pointF(0.5, 0);
  FArmRight.Angle.Value := -16;

  FArmLeft := TSprite.Create(texArm, False);
  AddChild(FArmLeft, 2);
  FArmLeft.FlipH := True;
  FArmLeft.Pivot := pointF(0.5, 0);
  FArmLeft.Angle.Value := 16;

  HideArmsToBottom;

  FSDCard := TSprite.Create(texSDCard, False);
  AddChild(FSDCard, 2);
  FSDCard.Visible := False;

end;

procedure TPanelUsingComputer.ProcessMessage(UserValue: TUserMessageValue);
var p: TPointF;
  p1: TPoint;
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // ANIM LR put SDCard in the slot
    0: begin   // show 'Insert SD Card'
      FCursorBlink := True;
      PostMessage(100);   // looped anim console cursor blink
      PostMessage(1, 1.5);
    end;
    1: begin    // LR arm moves to sd card slot
      RemoveChild(FArmRight);     // LR arm put becomes child of SDCardS
      FSDCard.AddChild(FArmRight, 0);
      FArmRight.Angle.Value := 0;
      FArmRight.CenterX := FSDCard.Width*0.5;
      FArmRight.Y.Value := FSDCard.Height*0.8;
      FSDCard.SetZOrder(2);     // sdcard is above the slot
      FSDCard.Visible := True;
      FSDCard.SetCoordinate(FBoard.Width*0.6, FBoard.BottomY);
      FSDCard.MoveTo(FSDSlot.CenterX-FSDCard.Width*0.5, FSDSlot.Y.Value-FSDCard.Height*0.75, 1.0, idcSinusoid);
      PostMessage(3, 1.5);
    end;
    3: begin // arms idle above keyboard
      FArmRight.MoveFromChildToScene(0);
      FArmRight.MoveFromSceneToChildOf(Self, 3);
      CenterArmsAboveKeyboard;
      PostMessage(5, 1.0);
    end;
    5: begin  //
      FConsoleText := FConsoleText + 'SD Card detected, please wait';
      PostMessage(6, 1.0);
    end;
    6: begin
      FConsoleText := FConsoleText + '.';
      PostMessage(7, 1.0);
    end;
    7: begin
      FConsoleText := FConsoleText + '.';
      PostMessage(8, 1.0);
    end;
    8: begin
      FConsoleText := FConsoleText + '.';
      PostMessage(9, 1.0);
    end;
    9: begin
      FConsoleText := FConsoleText + LineEnding + 'Running auto-executable';
      PostMessage(10, 2.0);
    end;
    10: begin
      FConsoleText := FConsoleText + LineEnding + 'Starting graphic interface GTK version 14';
      PostMessage(11, 2.5);
    end;
    11: begin
      FCursorBlink := False;
      MoveRightArmOnMouse;
      PostMessage(12, 1.0);
    end;
    12: begin // bind right arm to mouse pos and activate GUI mode
      FArmRight.BindToSprite(FMouse, 0, FMouse.Height*0.4);
      FFakeMouseFollowPlayerMouse := True;
      SetGUIMode(True);
      PostMessage(200);
      PostMessage(15, 0.75);
    end;
    15: begin
      CreateButtonOpenConversation;
    end;

    // cursor blink  (add and remove '|')
    100: begin // wait a little with a blink cursor
      if not FCursorBlink then exit;
      SetConsoleText(FConsoleText+'|');
      PostMessage(101, 0.5);
    end;
    101: begin
      if not FCursorBlink then exit;
      SetConsoleText(FConsoleText);
      PostMessage(100, 0.5);
    end;

    // Fake mouse follow player mouse
    200: begin
      if not FFakeMouseFollowPlayerMouse then exit;
      if FSB.MouseIsOver then begin
        p1 := FScene.Mouse.Position;
        p := FSB.ScreenToSurface(PointF(p1));
        p.x := p.x / FSB.Width * FMouse.Width*1.0;
        p.y := p.y / FSB.Height * FMouse.Width*0.6;
        FMouse.SetCenterCoordinate(p + FMousePositionOrigin);
      end;
      PostMessage(200);
    end;

    // show the conversation
    300: begin
      SetGUIMode(True);
      AddConversationBetweenRomeoAndJulia;
    end;

  end;
end;

procedure TPanelUsingComputer.StartAnimSDCardVolcano;
begin
  FAnimIsDone := False;
  SetConsoleMode(True);
  FConsoleText := 'WinWolf 3.1 - console mode'+LineEnding+'>';
  SetConsoleText(FConsoleText);
  Show;
  PostMessage(0, 1.5);
//postmessage(12, 1.5);
end;

{ TPropulsorConstructor }

function TPropulsorConstructor.GetBodyPath: TOGLCPath;
var r: TRectF;
begin
  Result := NIL;
  Result.ConcatPoints([PointF(ScaleW(224), 0),  // top right
                       PointF(0, 0),
                       PointF(0, ScaleH(96)),
                       PointF(ScaleW(224), ScaleH(96))]);
  Result.ConcatPoints(ComputeOpenedSpline([
                     PointF(ScaleW(224), ScaleH(96)), PointF(ScaleW(249), ScaleH(48)), PointF(ScaleW(224), ScaleH(0))
                     ], 0, 3, ssInsideWithEnds));
  r := Result.Bounds;
  if (r.Top <> 0) or (r.Left <> 0) then
    Result.Translate(PointF(-r.Left, -r.Top));
  Result.RemoveIdenticalConsecutivePoint;
  Result.ClosePath;
end;

procedure TPropulsorConstructor.PlacePropulsorIntoTheMachine;
begin
  AddChild(FPropulsor, -2);
  FPropulsor.X.Value := FPropulsor.Width;
  FPropulsor.CenterY := FBody.Height *0.5;
end;

class procedure TPropulsorConstructor.LoadTexture(aAtlas: TOGLCTextureAtlas);
begin
  texPropulsorForMachine := aAtlas.AddFromSVG(SpriteGameVolcanoInnerFolder+'PropulsorForMachine.svg', ScaleW(65), -1);
end;

constructor TPropulsorConstructor.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(FScene);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);

  // machine body
  FBody := TUIPanel.Create(FScene);
  FBody.MouseInteractionEnabled := False;
  FBody.ChildClippingEnabled := True;
  FBody.BodyShape.Border.LinePosition := lpMiddle;
  FBody.BodyShape.SetCustomShape(GetBodyPath, 3.0);
  FBody.BodyShape.Border.Color := BGRABlack;
  FBody.BodyShape.Fill.Visible := False;
  FBody.BackGradient.CreateVertical([BGRA(56,56,56), BGRA(192,192,192), BGRA(56,56,56)], [0.0, 0.5, 1.0]);
  AddChild(FBody, 0);
  FBody.SetCoordinate(0, 0);

  FGearSmall := CreateChildSprite(TLittleRobotConstructor.texGear, 1);
  FGearSmall.SetCenterCoordinate(FBody.Width*0.3, FBody.Height*0.5);

  FGearBig := CreateChildSprite(TLittleRobotConstructor.texGear, 1);
  FGearBig.SetCenterCoordinate(FBody.Width*0.6, FBody.Height*0.5);
  FGearBig.Scale.Value := PointF(1.5, 1.5);
  PostMessage(0); // gear anim

  FLavaReceptorLeft := CreateChildSprite(TLittleRobotConstructor.texLavaReceptor, -1);
  FLavaReceptorLeft.CenterX := ScaleW(127);
  FLavaReceptorLeft.BottomY := FBody.Y.Value + ScaleH(6);
  FLavaReceptorLeft.Pivot := PointF(0.5, 1.0);
  FLavaReceptorLeft.Angle.Value := -30;

  FLavaReceptorRight := CreateChildSprite(TLittleRobotConstructor.texLavaReceptor, -1);
  FLavaReceptorRight.CenterX := ScaleW(185);
  FLavaReceptorRight.BottomY := FBody.Y.Value + ScaleH(6);
  FLavaReceptorRight.Pivot := PointF(0.5, 1.0);
  FLavaReceptorRight.Angle.Value := 30;

  FPE := TParticleEmitter.Create(FScene);
  AddChild(FPE, -1);
  FPE.LoadFromFile(ParticleFolder+'LittleRobotConstructor.par', TLittleRobotConstructor.FAtlas);
  FPE.SetCoordinate(0, FBody.Height*0.5);
  FPE.Scale.Value := PointF(0.5, 0.5);
  FPE.ParticlesPosRelativeToEmitterPos := True;
  FPE.ParticlesToEmit.Value := 0;

  FPropulsor := TSprite.Create(texPropulsorForMachine, False);
  PlacePropulsorIntoTheMachine;

  FRobot := TLittleRobot.Create(ScaleW(-100), aY+FBody.Height, aLayerIndex);
  FRobot.TimeMultiplicator := 0.5;

  DeltaYToBottom := 0.0;
  DeltaYToTop := FBody.Height;
  BodyWidth := FBody.Width;
  BodyHeight := FBody.Height;

  FsndBlowtorch := Audio.AddSound('BlowtorchLoop.ogg');
  FsndBlowtorch.Loop := True;
  FsndBlowtorch.Volume.Value := 0.6;
  FsndBlowtorch.PositionRelativeToListener := False;
  FsndBlowtorch.DistanceModel := AL_LINEAR_DISTANCE; //AL_EXPONENT_DISTANCE;
  FsndBlowtorch.Attenuation3D(FScene.Width*0.5, FScene.Width*1.2, 2.0, 1.0);
  FsndBlowtorch.Position3D(aX+FBody.Width*0.5, aY+FBody.Height*0.5, -1);

  PostMessage(50); // build anim
end;

destructor TPropulsorConstructor.Destroy;
begin
  FsndBlowtorch.FadeOutThenKill(2.0);
  FsndBlowtorch := NIL;
  inherited Destroy;
end;

procedure TPropulsorConstructor.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // gear rotation
    0: begin
      FGearSmall.Angle.ChangeTo(900, 3.0, idcSinusoid2);
      FGearBig.Angle.ChangeTo(-900, 3.0, idcSinusoid2);
      PostMessage(1, 3.0);
    end;
    1: begin
      FGearSmall.Angle.ChangeTo(-900, 3.0, idcSinusoid2);
      FGearBig.Angle.ChangeTo(900, 3.0, idcSinusoid2);
      PostMessage(0, 3.0);
    end;

    // build propulsor anim
    50: begin
      FPE.ParticlesToEmit.Value := 476;
      FsndBlowtorch.Play;
      FPropulsor.X.ChangeTo(-FPropulsor.Width*0.5, 2.0, idcSinusoid);
      FRobot.WalkHorizontallyTo(ScaleW(325), Self, 54);
      FRobot.MoveArmForward;
      PostMessage(52, 2.0);
    end;
    52: begin
      FPE.ParticlesToEmit.Value := 0;
      FsndBlowtorch.Stop;
    end;
    54: begin
      PostMessage(56, 0.5);
    end;
    56: begin
      FPropulsor.FlipH := True;
      RemoveChild(FPropulsor);
      FRobot.AddChild(FPropulsor, -1);
      FPropulsor.X.Value := -FPropulsor.Width-FRobot.BodyWidth*0.5;
      FPropulsor.Y.Value := -ScaleH(12)-FPropulsor.Height;
      FRobot.WalkHorizontallyTo(ScaleW(-100), Self, 60);
      PostMessage(58, 0.5);
    end;
    58: begin
      FPE.ParticlesToEmit.Value := 476;
      FsndBlowtorch.Play;
    end;
    60: begin
      FRobot.RemoveChild(FPropulsor);
      PlacePropulsorIntoTheMachine;
      FPropulsor.FlipH := False;
      FRobot.MoveArmDown;
      PostMessage(50);
    end;
  end;
end;


{ TBigFire }

constructor TBigFire.Create(aX, aY: single; aLayerIndex: integer; aAtlas: TOGLCTextureAtlas);
begin
  inherited Create(FScene);
  LoadFromFile(ParticleFolder+'BigFire.par', aAtlas);
  if aLayerIndex > -1 then FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
end;

{ TImpact1 }

class procedure TImpact1.LoadTexture(aAtlas: TOGLCTextureAtlas);
begin
  FAtlas := aAtlas;
  texImpact1 := FAtlas.AddFromSVG(SpriteGameVolcanoInnerFolder+'Impact1.svg', ScaleW(46), -1);
end;

constructor TImpact1.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(texImpact1, False);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
  AddAndPlayScenario(
       'TintChange 255 99 0 255 0.6 idcLinear'#10+
       'Wait 0.6'#10+
   //    'TintChange 255 192 0 0 0.6 idcLinear'#10+
   //    'Wait 0.6'#10+
       'TintChange 255 192 0 255 0.6 idcLinear'#10+
       'Wait 0.6'#10+
   //    'TintChange 255 192 0 0 0.6 idcLinear'#10+
   //    'Wait 0.6'#10+
       'Loop');
  FSmoke := TSmokePoint.Create(Width*0.5, Height*0.5, -1, FAtlas);
  AddChild(FSmoke, 0);
end;

procedure TImpact1.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  // force smoke to go up
  FSmoke.Angle.Value := -Angle.Value;
end;

{ TSmokePoint }

constructor TSmokePoint.Create(aX, aY: single; aLayerIndex: integer; aAtlas: TOGLCTextureAtlas);
begin
  inherited Create(FScene);
  LoadFromFile(ParticleFolder+'SmokePointBlack.par', aAtlas);
  if aLayerIndex > -1 then FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
  self.ParticlesPosRelativeToEmitterPos := False;
end;

{ TSmokeLine }

constructor TSmokeLine.Create(aX, aY: single; aLayerIndex: integer; aAtlas: TOGLCTextureAtlas);
begin
  inherited Create(FScene);
  LoadFromFile(ParticleFolder+'WorkShopSmoke.par', aAtlas);
  if aLayerIndex > -1 then FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
end;

{ TFireLine }

constructor TFireLine.Create(aX, aY: single; aLayerIndex: integer; aAtlas: TOGLCTextureAtlas);
begin
  inherited Create(FScene);
  LoadFromFile(ParticleFolder+'FireWorkShop.par', aAtlas);
  if aLayerIndex > -1 then FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);

  FSmoke := TParticleEmitter.Create(FScene);
  AddChild(FSmoke, -1);
  FSmoke.LoadFromFile(ParticleFolder+'WorkShopSmoke.par', aAtlas);
  FSmoke.SetCoordinate(Width*0.40, Height*0.70);
  FSmoke.SetEmitterTypeRectangle(Round(Width*0.40), Round(Height*0.70));
end;

{ TPump }

class procedure TPump.LoadTexture(aAtlas: TOGLCTextureAtlas);
var path: string;
begin
  FAtlas := aAtlas;
  path := SpriteGameVolcanoInnerFolder;
  texPumpBody := aAtlas.AddFromSVG(path+'PumpBody.svg', ScaleW(216), -1);
  texPumpGaugeArrow := aAtlas.AddFromSVG(path+'PumpGaugeArrow.svg', ScaleW(11), -1);
  texPumpGaugeDial := aAtlas.AddFromSVG(path+'PumpGaugeDial.svg', ScaleW(69), -1);
end;

constructor TPump.Create(aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(texPumpBody, False);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
  FInitialCoor := PointF(aX, aY);

  FGauge := TSprite.Create(texPumpGaugeDial, False);
  AddChild(FGauge, 0);
  FGauge.SetCenterCoordinate(Width*0.3, Height*0.5);

  FArrow := TSprite.Create(texPumpGaugeArrow, False);
  FGauge.AddChild(FArrow, 0);
  FArrow.CenterX := FGauge.Width*0.5;
  FArrow.BottomY := FGauge.Height*0.5;
  FArrow.Pivot := PointF(0.5, 1.0);

  FsndEngine := Audio.AddSound('MotorEngineLoop.ogg');
  FsndEngine.Loop := True;
  FsndEngine.Volume.Value := 0.6;
  FsndEngine.PositionRelativeToListener := False;
  FsndEngine.DistanceModel := AL_LINEAR_DISTANCE_CLAMPED; //AL_EXPONENT_DISTANCE;
  FsndEngine.Attenuation3D(Width*0.25, FScene.Width*1.5, 2.0, 1.0);
  FsndEngine.Position3D(aX+Width*0.5, aY+Height*0.5, -1.0);

  SetNormalSpeed;
end;

destructor TPump.Destroy;
begin
  FsndEngine.FadeOutThenKill(2.0);
  FsndEngine := NIL;
  inherited Destroy;
end;

procedure TPump.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if FAccelerateShakeToMax then begin
    FShakeDuration := FShakeDuration-aElapsedTime*0.01;
    if FShakeDuration < 0.04 then FShakeDuration := 0.04;
  end;
end;

procedure TPump.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // arrow to normal
    0: begin
      d := random*0.5+0.25;
      FArrow.Angle.ChangeTo(random*20-10, d);
      PostMessage(0, d);
    end;
    // body shake
    1: begin
      FsndEngine.Pitch.Value := 1.0 + Abs(FShakeDuration-0.12)*32;
      CornerOffset.TopLeft.ChangeTo(PointF(0,PPIScale(5)), FShakeDuration, idcSinusoid);
      CornerOffset.TopRight.ChangeTo(PointF(0,PPIScale(5)), FShakeDuration, idcSinusoid);
      PostMessage(2, FShakeDuration);
    end;
    2: begin
      CornerOffset.TopLeft.ChangeTo(PointF(0,0), FShakeDuration, idcSinusoid);
      CornerOffset.TopRight.ChangeTo(PointF(0,0), FShakeDuration, idcSinusoid);
      PostMessage(1, FShakeDuration);
    end;

    // arrow to max
    10: begin
      FArrow.Angle.ChangeTo(120, 5.0);
      PostMessage(11, 5.0);
    end;
    11: begin
      d := random*0.25+0.125;
      FArrow.Angle.ChangeTo(120+random*10-5, d);
      PostMessage(11, d);
    end;
  end;
end;

procedure TPump.SetNormalSpeed;
begin
  FsndEngine.Play(False);
  FShakeDuration := 0.12;
  FAccelerateShakeToMax := False;
  ClearMessageList;
  PostMessage(0);
  PostMessage(1);
end;

procedure TPump.SetMaximumSpeed;
begin
  FsndEngine.Play(False);
  ClearMessageList;
  PostMessage(1);
  PostMessage(10);
  FAccelerateShakeToMax := True;
end;

procedure TPump.CreateSmoke;
begin
  if FSmoke <> NIL then exit;
  FSmoke := TParticleEmitter.Create(FScene);
  FSmoke.LoadFromFile(ParticleFolder+'PumpSmoke.par', FAtlas);
  FSmoke.SetCoordinate(0, Height*0.75);
  AddChild(FSmoke);
  FSmoke.Opacity.Value := 0;
  FSmoke.Opacity.ChangeTo(128, 3.0);
end;

procedure TPump.StopSmoke;
begin
  if FSmoke = NIL then exit;
  FSmoke.Opacity.ChangeTo(0, 3.0);
  FSmoke.KillDefered(3.0);
  FSmoke := NIL;
end;

{ TPanelDecodingDigicode }

class procedure TPanelDecodingDigicode.LoadTextures(aAtlas: TOGLCTextureAtlas);
var path: string;
begin
  path := SpriteGameVolcanoEntranceFolder;
  FComputedWidth := FScene.Width/3;
  texWallBG := aAtlas.AddFromSVG(path+'PanelDecodeWallBG.svg', ScaleW(114), -1);
  texDigicode := aAtlas.AddFromSVG(path+'Digicode.svg', Round(FComputedWidth*0.314), -1);
  texDecoderBody := aAtlas.AddFromSVG(path+'DecoderBody.svg', ScaleW(69), -1);
  texDecoderLightOff := aAtlas.AddFromSVG(path+'DecoderLightOff.svg', ScaleW(10), -1);
  texDecoderWheel := aAtlas.AddFromSVG(path+'DecoderWheel.svg', ScaleW(25), -1);
  texDecoderBeam := aAtlas.AddFromSVG(path+'DecoderBeam.svg', ScaleW(78), -1);
  texLRArm := aAtlas.AddFromSVG(path+'PanelDecodeLRArm.svg', ScaleW(41), -1);
end;

constructor TPanelDecodingDigicode.Create;
var o: TSpriteWithElasticCorner;
  d: single;
begin
  inherited CreateAsCircle(Round(FComputedWidth));
  CenterOnScene;

  o := TSpriteWithElasticCorner.Create(texWallBG, False);
  AddChild(o, 0);
  d := FComputedWidth - texWallBG^.FrameWidth;
  o.CornerOffset.TopRight.Value := PointF(d, 0);
  o.CornerOffset.BottomRight.Value := PointF(d, d);
  o.CornerOffset.BottomLeft.Value := PointF(0, d);

  FDigicode := TSprite.Create(texDigicode, False);
  AddChild(FDigicode, 1);
  FDigicode.SetCoordinate(Width*2/7, Height/3);

  FDecoderBody := TSprite.Create(texDecoderBody, False);
  FDigicode.AddChild(FDecoderBody, 0);
  FDecoderBody.SetCoordinate(FDigicode.Width*2, FDigicode.Height*3);

  FWheel := TSprite.Create(texDecoderWheel, False);
  FDecoderBody.AddChild(FWheel, 0);
  FWheel.SetCoordinate(FDecoderBody.Width*0.168, FDecoderBody.Height*0.061);

  FLightOnOff := TSprite.Create(texDecoderLightOff, False);
  FDecoderBody.AddChild(FLightOnOff, 0);
  FLightOnOff.SetCoordinate(FDecoderBody.Width*0.708, FDecoderBody.Height*0.218);

  FLight1 := TSprite.Create(texDecoderLightOff, False);
  FDecoderBody.AddChild(FLight1, 0);
  FLight1.SetCoordinate(FDecoderBody.Width*0.074, FDecoderBody.Height*0.598);

  FLight2 := TSprite.Create(texDecoderLightOff, False);
  FDecoderBody.AddChild(FLight2, 0);
  FLight2.SetCoordinate(FDecoderBody.Width*0.293, FDecoderBody.Height*0.695);

  FLight3 := TSprite.Create(texDecoderLightOff, False);
  FDecoderBody.AddChild(FLight3, 0);
  FLight3.SetCoordinate(FDecoderBody.Width*0.512, FDecoderBody.Height*0.695);

  FLight4 := TSprite.Create(texDecoderLightOff, False);
  FDecoderBody.AddChild(FLight4, 0);
  FLight4.SetCoordinate(FDecoderBody.Width*0.731, FDecoderBody.Height*0.598);

  FBeam := TSprite.Create(texDecoderBeam, False);
  FDecoderBody.AddChild(FBeam, -1);
  FBeam.RightX := FDecoderBody.Width*0.1;
  FBeam.CenterY := FDecoderBody.Height*0.5;
  FBeam.Pivot := PointF(1.0, 0);
  FBeam.Visible := False;

  FLRArm := TSprite.Create(texLRArm, False);
  FDecoderBody.AddChild(FLRArm, 1);
  FLRArm.SetCoordinate(FDecoderBody.Width*0.6, FDecoderBody.Height*0.5);
  FLRArm.Pivot := PointF(0.5, 1.0);
  FLRArm.Angle.Value := -16;
end;

procedure TPanelDecodingDigicode.Show;
begin
  inherited Show;
  PostMessage(50, 1.5);
end;

procedure TPanelDecodingDigicode.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // SCANNING ANIMATION
    0: begin
      with Audio.AddSound('Beep1.ogg') do PlayThenKill(True);
      FLightOnOff.Tint.Value := BGRA(255,227,159);
      FWheel.Angle.ChangeTo(359, 2, idcStartSlowEndFast);
      PostMessage(1, 2.0);
    end;
    1: begin
      FsndDecoderScanning := Audio.AddSound('DecoderScanning.ogg');
      FsndDecoderScanning.Pitch.Value := 0.7;
      FsndDecoderScanning.Pitch.ChangeTo(1.0, 2.0);
      FsndDecoderScanning.Volume.Value := 0.5;
      FsndDecoderScanning.Loop := True;
      FsndDecoderScanning.Play(True);
      FWheel.Angle.AddConstant(360*4);
      FBeam.Visible := True;
      PostMessage(2, 2.5+Random);
      PostMessage(20, 0.5); // beam rotation
    end;
    2: begin
      with Audio.AddSound('Beep1.ogg') do PlayThenKill(True);
      FLight1.Tint.Value := BGRA(115,248,115);
      PostMessage(3, 1.5+Random);
    end;
    3: begin
      with Audio.AddSound('Beep1.ogg') do PlayThenKill(True);
      FLight2.Tint.Value := BGRA(115,248,115);
      PostMessage(4, 1.5+Random);
    end;
    4: begin
      with Audio.AddSound('Beep1.ogg') do PlayThenKill(True);
      FLight3.Tint.Value := BGRA(115,248,115);
      PostMessage(5, 1.5+Random);
    end;
    5: begin
      with Audio.AddSound('Beep2.ogg') do PlayThenKill(True);
      FsndDecoderScanning.Kill;
      FLight4.Tint.Value := BGRA(115,248,115);
      FBeam.Opacity.ChangeTo(0, 1);
      FWheel.Angle.Value := -359;
      FWheel.Angle.ChangeTo(0, 1, idcStartFastEndSlow);
      PostMessage(6, 1);
    end;
    6: begin
      FBeam.Visible := False;
      PostMessage(60);   // LR arm take the decoder
    end;
    // beam rotation
    20:begin
      if FScanIsDone then exit;
      FBeam.Angle.ChangeTo(50, 0.75, idcSinusoid);
      PostMessage(21, 0.75);
    end;
    21:begin
      FBeam.Angle.ChangeTo(-50, 0.75, idcSinusoid);
      PostMessage(20, 0.75);
    end;

    // LR ARM APPEAR AND PUT THE DECODER ON THE DIGICODE
    50: begin
      FDecoderBody.X.ChangeTo(FDigicode.Width, 1.0, idcSinusoid);
      FDecoderBody.Y.ChangeTo((FDigicode.Height-FDecoderBody.Height)*0.5, 1.0, idcSinusoid);
      PostMessage(51, 1.0);
    end;
    51: begin
      with Audio.AddSound('PutObject.ogg') do begin
        PlayThenKill(True);
      end;
      PostMessage(52, 0.5);
    end;
    52: begin    //LR arm go away
      FLRArm.MoveTo(FDigicode.Width*2, FDigicode.Height*3, 1.0, idcSinusoid);
      PostMessage(0, 0.75);
    end;

    // LR ARM TAKE THE DECODER
    60: begin
      FLRArm.MoveTo(FDecoderBody.Width*0.6, FDecoderBody.Height*0.5, 1.0, idcSinusoid);
      PostMessage(61, 1.0);
    end;
    61: begin
      FDecoderBody.MoveTo(FDigicode.Width*2, FDigicode.Height*3, 1.0, idcSinusoid);
      PostMessage(62, 1.0);
    end;
    62: begin
      FScanIsDone := True;
    end;
  end;
end;

{ TLittleRobot }

class procedure TLittleRobot.LoadTexture(aAtlas: TOGLCTextureAtlas);
var path: string;
begin
  path := SpriteGameVolcanoInnerFolder;
  texWheel := aAtlas.AddFromSVG(path+'LittleRobotWheel.svg', ScaleW(19), -1);
  texBody := aAtlas.AddFromSVG(path+'LittleRobotBody.svg', ScaleW(47), -1);
  texArm := aAtlas.AddFromSVG(path+'LittleRobotArm.svg', -1, ScaleH(33));
  texFingerLeft := aAtlas.AddFromSVG(path+'LittleRobotFingerLeft.svg', -1, ScaleH(16));
  texFingerRight := aAtlas.AddFromSVG(path+'LittleRobotFingerRight.svg', -1, ScaleH(16));
end;

constructor TLittleRobot.Create(aX, aYBottomWheel: single; aLayerIndex: integer);
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  X.Value := aX;
  Y.Value := aYBottomWheel;

  FBody := CreateChildSprite(texBody, 0);
  FBody.CenterX := 0.0;
  FBody.BottomY := -texWheel^.FrameHeight*0.5;

  FWheel1 := CreateChildSprite(texWheel, 1);
  FWheel1.CenterX := FBody.X.Value + FBody.Width*0.22;
  FWheel1.CenterY := FBody.BottomY;

  FWheel2 := CreateChildSprite(texWheel, 1);
  FWheel2.CenterX := FBody.X.Value + FBody.Width*0.78;
  FWheel2.CenterY := FBody.BottomY;

  FArm := CreateChildSprite(texArm, 2);
  FArm.CenterX := 0.0;
  FArm.Y.Value := FBody.Y.Value + FBody.Height*0.5;
  FArm.Pivot := PointF(0.5, 0.1);
  FArm.ApplySymmetryWhenFlip := True;
//  FArm.Angle.Value := 80;

  FFingerLeft := TSprite.Create(texFingerLeft, False);
  FArm.AddChild(FFingerLeft, 0);
  FFingerLeft.X.Value := FArm.Width*0.5;
  FFingerLeft.Y.Value := FArm.Height*0.85;
  FFingerLeft.Pivot := PointF(0.1,0.1);
  FFingerLeft.ApplySymmetryWhenFlip := True;

  FFingerRight := TSprite.Create(texFingerRight, False);
  FArm.AddChild(FFingerRight, 0);
  FFingerRight.RightX := FArm.Width*0.5;
  FFingerRight.Y.Value := FArm.Height*0.85;
  FFingerRight.Pivot := PointF(0.9,0.1);
  FFingerRight.ApplySymmetryWhenFlip := True;

  DeltaYToBottom := 0.0;
  DeltaYToTop := FWheel1.Height*0.5+FBody.Height;
  BodyWidth := FBody.Width;
  BodyHeight := Round(DeltaYToTop);

  FTimeMultiplicator := 1.0;
end;

procedure TLittleRobot.Update(const aElapsedTime: single);
var v: single;
begin
  inherited Update(aElapsedTime);

  // wheel rotation versus speed.X.Value
  v := -Abs(Speed.X.Value*2.2);  // /(FWheel1.Width*3.14);
  FWheel1.Angle.AddConstant(v);
  FWheel2.Angle.AddConstant(v);

end;

procedure TLittleRobot.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of

    // finger knitting
    100: begin  // open fingers
      if not FFingerKnitting then exit;
      FFingerLeft.Angle.ChangeTo(-30, 0.1);
      FFingerRight.Angle.ChangeTo(30, 0.1);
      PostMessage(101, 0.1);
    end;
    101: begin
      if not FFingerKnitting then exit;
      FFingerLeft.Angle.ChangeTo(10, 0.1);
      FFingerRight.Angle.ChangeTo(-10, 0.1);
      PostMessage(100, 0.1);
    end;
  end;
end;

procedure TLittleRobot.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FWheel1.FlipH := AValue;
  FWheel2.FlipH := AValue;
  FBody.FlipH := AValue;
  FArm.FlipH := AValue;
  FFingerLeft.FlipH := AValue;
  FFingerRight.FlipH := AValue;
end;

procedure TLittleRobot.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FWheel1.FlipV := AValue;
  FWheel2.FlipV := AValue;
  FBody.FlipV := AValue;
  FArm.FlipV := AValue;
  FFingerLeft.FlipV := AValue;
  FFingerRight.FlipV := AValue;
end;

procedure TLittleRobot.FingerStartKnitting;
begin
  if FFingerKnitting then exit;
  FFingerKnitting := True;
  PostMessage(100);
end;

procedure TLittleRobot.FingerStopKnitting;
begin
  FFingerKnitting := False;
  FFingerLeft.Angle.ChangeTo(0, 1.0*FTimeMultiplicator);
  FFingerRight.Angle.ChangeTo(0, 1.0*FTimeMultiplicator);
end;

procedure TLittleRobot.MoveArmForward;
begin
  FArm.Angle.ChangeTo(80, 1.0*FTimeMultiplicator, idcSinusoid);
end;

procedure TLittleRobot.MoveArmDown;
begin
  FArm.Angle.ChangeTo(0, 1.0*FTimeMultiplicator, idcSinusoid);
end;

procedure TLittleRobot.WalkHorizontallyTo(aX: single; aMessageReceiver: TObject;
  aMessageValueWhenFinish: TUserMessageValue; aDelay: single);
var sp: single;
begin
  if TimeMultiplicator = 0 then sp := 0
    else sp := FScene.Width*0.1 * 1/TimeMultiplicator;

  if X.Value < aX then begin
    SetFlipH(True);
    Speed.X.Value := sp;
    CheckHorizontalMoveToX(aX, aMessageReceiver, aMessageValueWhenFinish, aDelay);
  end else if X.Value > aX then begin
    SetFlipH(False);
    Speed.X.Value := -sp;
    CheckHorizontalMoveToX(aX, aMessageReceiver, aMessageValueWhenFinish, aDelay);
  end else begin
    PostMessageToTargetObject(aMessageReceiver, aMessageValueWhenFinish, aDelay);
    Speed.X.Value := 0.0;
  end;
end;

{ TLittleRobotConstructor.TArm }

constructor TLittleRobotConstructor.TArm.Create(aXCenterAxis, aYBottomAxis: single);
begin
  inherited Create(FScene);
  SetCoordinate(aXCenterAxis, aYBottomAxis);

  FAxis := TSprite.Create(texArmAxis, False); // TArm.CreateChildSprite(texArmAxis, 0);
  AddChild(FAxis, 0);
  FAxis.CenterX := 0;
  FAxis.BottomY := 0;

  FArm := TSprite.Create(texArm, False);
  FAxis.AddChild(FArm, 0);
  FArm.CenterX := FAxis.Width*0.5;
  FArm.Y.Value := FAxis.Height*0.5;
  FArm.Pivot := PointF(0.5, 0.05);
  FArm.Angle.Value := 30;
  FArm.ApplySymmetryWhenFlip := True;

  FFingerLeft := TSprite.Create(texFingerLeft, False);
  FArm.AddChild(FFingerLeft, 0);
  FFingerLeft.X.Value := FArm.Width*0.6;
  FFingerLeft.Y.Value := FArm.Height*0.95;
  FFingerLeft.Pivot := PointF(0.1,0.1);
  FFingerLeft.ApplySymmetryWhenFlip := True;

  FFingerRight := TSprite.Create(texFingerRight, False);
  FArm.AddChild(FFingerRight, 0);
  FFingerRight.RightX := FArm.Width*0.4;
  FFingerRight.Y.Value := FArm.Height*0.95;
  FFingerRight.Pivot := PointF(0.9,0.1);
  FFingerRight.ApplySymmetryWhenFlip := True;
end;

procedure TLittleRobotConstructor.TArm.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of

    // finger knitting
    100: begin  // open fingers
      if not FFingerKnitting then exit;
      FFingerLeft.Angle.ChangeTo(-30, 0.1);
      FFingerRight.Angle.ChangeTo(30, 0.1);
      PostMessage(101, 0.1);
    end;
    101: begin
      if not FFingerKnitting then exit;
      FFingerLeft.Angle.ChangeTo(10, 0.1);
      FFingerRight.Angle.ChangeTo(-10, 0.1);
      PostMessage(100, 0.1);
    end;
  end;
end;

procedure TLittleRobotConstructor.TArm.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FArm.FlipH := AValue;
  FFingerLeft.FlipH := AValue;
  FFingerRight.FlipH := AValue;
end;

procedure TLittleRobotConstructor.TArm.FingerStartKnitting;
begin
  if FFingerKnitting then exit;
  FFingerKnitting := True;
  PostMessage(100);
end;

procedure TLittleRobotConstructor.TArm.FingerStopKnitting;
begin
  FFingerKnitting := False;
  FFingerLeft.Angle.ChangeTo(0, 1.0);
  FFingerRight.Angle.ChangeTo(0, 1.0);
end;

procedure TLittleRobotConstructor.TArm.PrepareToConstructNewOne;
begin
  FArm.Angle.ChangeTo(40, 2.0, idcSinusoid);
  FArm.Y.ChangeTo(FAxis.Height*0.9, 2.0, idcSinusoid);
end;

procedure TLittleRobotConstructor.TArm.MoveArmToTop;
begin
  FArm.Y.ChangeTo(FAxis.Height*0.1, 3.0);
end;

procedure TLittleRobotConstructor.TArm.MoveArmToReleaseRobot;
begin
  FArm.Angle.ChangeTo(-45, 2.0, idcSinusoid);
end;

{ TLittleRobotConstructor }

function TLittleRobotConstructor.GetRobotConstructed: boolean;
begin
  Result := FRobotConstructed;
  FRobotConstructed := False;
end;

function TLittleRobotConstructor.GetBodyPath: TOGLCPath;
var r: TRectF;
begin
  Result := NIL;
  Result.ConcatPoints([PointF(ScaleW(80), 0),              // top left
                                PointF(ScaleW(160), 0)]); // top right
  Result.ConcatPoints(ComputeOpenedSpline([
                     PointF(ScaleW(160), 0), PointF(ScaleW(217), ScaleH(117)), PointF(ScaleW(240), ScaleH(235))
                     ], 0, 3, ssInsideWithEnds));
  Result.ConcatPoints(ComputeOpenedSpline([
                     PointF(ScaleW(240), ScaleH(235)), PointF(ScaleW(125), ScaleH(256)), PointF(ScaleW(0), ScaleH(235))
                     ], 0, 3, ssInsideWithEnds));
  Result.ConcatPoints(ComputeOpenedSpline([
                     PointF(ScaleW(0), ScaleH(235)), PointF(ScaleW(24), ScaleH(117)), PointF(ScaleW(80), ScaleH(0))
                     ], 0, 3, ssInsideWithEnds));
  r := Result.Bounds;
  if (r.Top <> 0) or (r.Left <> 0) then
    Result.Translate(PointF(-r.Left, -r.Top));
  Result.RemoveIdenticalConsecutivePoint;
  Result.ClosePath;
end;

class procedure TLittleRobotConstructor.LoadTexture(aAtlas: TOGLCTextureAtlas);
var path: string;
begin
  path := SpriteGameVolcanoInnerFolder;
  texWheel := aAtlas.AddFromSVG(path+'RobotConstructorWheel.svg', ScaleW(53), -1);
  texLegLeft := aAtlas.AddFromSVG(path+'RobotConstructorLegLeft.svg', ScaleW(56), -1);
  texLegRight := aAtlas.AddFromSVG(path+'RobotConstructorLegRight.svg', ScaleW(56), -1);
  texLavaReceptor := aAtlas.AddFromSVG(path+'RobotConstructorLavaReceptor.svg', -1, ScaleH(59));
  texArm := aAtlas.AddFromSVG(path+'RobotConstructorArm.svg', -1, ScaleH(124));
  texFingerLeft := aAtlas.AddFromSVG(path+'RobotConstructorFingerLeft.svg', ScaleW(12), -1);
  texFingerRight := aAtlas.AddFromSVG(path+'RobotConstructorFingerRight.svg', ScaleW(12), -1);
  texArmAxis := aAtlas.AddFromSVG(path+'RobotConstructorArmAxis.svg', -1, ScaleH(67));
  texGear := aAtlas.AddFromSVG(path+'RobotConstructorGear.svg', ScaleW(28), -1);
  texParticle := aAtlas.AddFromSVG(ParticleFolder+'sphere_particle.svg', PPIScale(32), -1);
  texParticle^.Filename := 'sphere_particle.png';
  FAtlas := aAtlas;
end;

constructor TLittleRobotConstructor.Create(aXCenter, aYBottomWheel: single; aLayerIndex: integer);
begin
  inherited Create(FScene);
  FScene.Add(Self, aLayerIndex);
  SetCoordinate(aXCenter, aYBottomWheel);

  FWheelLeft := CreateChildSprite(texWheel, 0);
  FWheelLeft.CenterX := ScaleW(111);
  FWheelLeft.BottomY := 0;

  FWheelRight := CreateChildSprite(texWheel, 0);
  FWheelRight.CenterX := -ScaleW(111);
  FWheelRight.BottomY := 0;

  FLegLeft := CreateChildSprite(texLegLeft, -1);
  FLegLeft.X.Value := FWheelLeft.X.Value - ScaleW(14);
  FLegLeft.BottomY := -texWheel^.FrameHeight*0.5;

  FLegRight := CreateChildSprite(texLegRight, -1);
  FLegRight.X.Value := FWheelRight.X.Value + ScaleW(14);
  FLegRight.BottomY := -texWheel^.FrameHeight*0.5;

  // machine body
  FBody := TUIPanel.Create(FScene);
  FBody.MouseInteractionEnabled := False;
  FBody.ChildClippingEnabled := True;
  FBody.BodyShape.Border.LinePosition := lpMiddle;
  FBody.BodyShape.SetCustomShape(GetBodyPath, 3.0);
  FBody.BodyShape.Border.Color := BGRABlack;
  FBody.BodyShape.Fill.Visible := False;
  FBody.BackGradient.CreateVertical([BGRA(56,56,56), BGRA(192,192,192), BGRA(56,56,56)], [0.0, 0.5, 1.0]);
  AddChild(FBody, 0);
  FBody.CenterX := 0;
  FBody.BottomY := FLegRight.Y.Value + ScaleH(15);

  FGearSmall := CreateChildSprite(texGear, 1);
  FGearSmall.SetCenterCoordinate(FBody.X.Value+FBody.Width*0.3, FBody.Y.Value+FBody.Height*0.5);

  FGearBig := CreateChildSprite(texGear, 1);
  FGearBig.SetCenterCoordinate(FBody.X.Value+FBody.Width*0.6, FBody.Y.Value+FBody.Height*0.35);
  FGearBig.Scale.Value := PointF(2.0, 2.0);
  PostMessage(0); // gear animation

  FLavaReceptorLeft := CreateChildSprite(texLavaReceptor, -1);
  FLavaReceptorLeft.CenterX := ScaleW(14);
  FLavaReceptorLeft.BottomY := FBody.Y.Value + ScaleH(6);
  FLavaReceptorLeft.Pivot := PointF(0.5, 1.0);
  FLavaReceptorLeft.Angle.Value := 30;

  FLavaReceptorRight := CreateChildSprite(texLavaReceptor, -1);
  FLavaReceptorRight.CenterX := -ScaleW(14);
  FLavaReceptorRight.BottomY := FBody.Y.Value + ScaleH(6);
  FLavaReceptorRight.Pivot := PointF(0.5, 1.0);
  FLavaReceptorRight.Angle.Value := -30;

  FArmLeft := TArm.Create(ScaleW(94), -ScaleH(121));
  AddChild(FArmLeft, 3);

  FArmRight := TArm.Create(-ScaleW(94), -ScaleH(121));
  FArmRight.SetFlipH(True);
  AddChild(FArmRight, 3);

  FPE := TParticleEmitter.Create(FScene);
  AddChild(FPE, 2);
  FPE.SetCoordinate(0,0);
  FPE.LoadFromFile(ParticleFolder+'LittleRobotConstructor.par', FAtlas);
  FPE.ParticlesToEmit.Value := 0;

  DeltaYToBottom := 0.0;
  DeltaYToTop := FBody.Y.Value;
  BodyWidth := Round(FWheelLeft.RightX - FWheelRight.X.Value);
  BodyHeight := Round(Abs(DeltaYToTop));

  FsndBlowtorch := Audio.AddSound('BlowtorchLoop.ogg');
  FsndBlowtorch.Loop := True;
  FsndBlowtorch.Volume.Value := 0.7;
  FsndBlowtorch.PositionRelativeToListener := False;
  FsndBlowtorch.DistanceModel := AL_LINEAR_DISTANCE; //AL_EXPONENT_DISTANCE;
  FsndBlowtorch.Attenuation3D(FScene.Width, FScene.Width*2, 2.0, 1.0);

  FsndElectricalMotor := Audio.AddSound('ElectricalMotorLoop.ogg');
  FsndElectricalMotor.Loop := True;
  FsndElectricalMotor.Volume.Value := 0.55;
  FsndElectricalMotor.PositionRelativeToListener := False;
  FsndElectricalMotor.DistanceModel := AL_LINEAR_DISTANCE; //AL_EXPONENT_DISTANCE;
  FsndElectricalMotor.Attenuation3D(FScene.Width, FScene.Width*2, 2.0, 1.0);
end;

destructor TLittleRobotConstructor.Destroy;
begin
  FsndBlowtorch.Kill;
  FsndBlowtorch := NIL;
  FsndElectricalMotor.Kill;
  FsndElectricalMotor := NIL;
  inherited Destroy;
end;

procedure TLittleRobotConstructor.Update(const aElapsedTime: single);
var yy: single;
begin
  inherited Update(aElapsedTime);

  // sound position
  yy := Y.Value-FBody.Height*0.5;
  FsndBlowtorch.Position3D(X.Value, yy, -1.0);
  FsndElectricalMotor.Position3D(X.Value, yy, -1.0);

  // force the smoke of the impact object to go up
  if FImpact1 <> NIL then FImpact1.Angle.Value := -Angle.Value;
  if FImpact2 <> NIL then FImpact2.Angle.Value := -Angle.Value;
end;

procedure TLittleRobotConstructor.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // gear rotation
    0: begin
      FGearSmall.Angle.ChangeTo(900, 3.0, idcSinusoid2);
      FGearBig.Angle.ChangeTo(-900, 3.0, idcSinusoid2);
      PostMessage(1, 3.0);
    end;
    1: begin
      FGearSmall.Angle.ChangeTo(-900, 3.0, idcSinusoid2);
      FGearBig.Angle.ChangeTo(900, 3.0, idcSinusoid2);
      PostMessage(0, 3.0);
    end;

    // constructing robot animation
    100: begin
      FConstructionFinished := False;
      FArmRight.PrepareToConstructNewOne;
      FArmLeft.PrepareToConstructNewOne;
      PostMessage(101, 2.0);
    end;
    101: begin   // start flash fx
      FsndElectricalMotor.Stop;
      FArmRight.FingerStartKnitting;
      FArmLeft.FingerStartKnitting;
      FPE.Y.Value := -texArmAxis^.FrameHeight*0.3;
      FPE.ParticlesToEmit.Value := 476;
      FsndBlowtorch.Play(True);
      PostMessage(102, 0.5);
    end;
    102: begin  // create robot as child and arms moves up
      FLittleRobot := TLittleRobot.Create(0, 0, -1);
      AddChild(FLittleRobot, 1);
      FArmRight.MoveArmToTop;
      FArmLeft.MoveArmToTop;
      FPE.MoveYRelative(-texArmAxis^.FrameHeight*0.8, 4.0);
      PostMessage(103, 3.0);
    end;
    103: begin  // evacuate arms and robot
      FPE.ParticlesToEmit.Value := 0;
      FsndBlowtorch.Stop;
      FsndElectricalMotor.Play(True);
      FArmRight.MoveArmToReleaseRobot;
      FArmRight.FingerStopKnitting;
      FArmLeft.MoveArmToReleaseRobot;
      FArmLeft.FingerStopKnitting;
      //FLittleRobot.WalkHorizontallyTo(-(X.Value+FLittleRobot.BodyWidth*2), Self, 99999);
      FLittleRobot.MoveFromChildToScene(LAYER_BG1);
      FLittleRobot.WalkHorizontallyTo(-FLittleRobot.BodyWidth*2, Self, 99999);
      FLittleRobot.MoveArmForward;
      FLittleRobot.KillDefered(8.0);
      FRobotConstructed := True;
      if FConstructing then PostMessage(100, 2.0)
        else PostMessage(104, 2.0);
      FConstructionFinished := True;
    end;
    //104: FsndElectricalMotor.Stop;
  end;
end;

procedure TLittleRobotConstructor.StartConstructing;
begin
  if FConstructing then exit;
  FConstructing := True;
  PostMessage(100);
  PostMessage(0);
end;

procedure TLittleRobotConstructor.StopConstructing;
begin
  if not FConstructing then exit;
  FConstructing := False;
end;

procedure TLittleRobotConstructor.StopGearsRotation;
begin
  ClearMessageList;
end;

procedure TLittleRobotConstructor.PlaySoundMoveMotor;
begin
  FsndElectricalMotor.Pitch.Value := 1.0;
  FsndElectricalMotor.Pitch.ChangeTo(0.4, 0.5);
  FsndElectricalMotor.Play(True);
end;

procedure TLittleRobotConstructor.PlaySoundMoveMotorAtMaxSpeed;
begin
  FsndElectricalMotor.Pitch.Value := 0.4;
  FsndElectricalMotor.Pitch.ChangeTo(1.5, 0.5);
  FsndElectricalMotor.Play(True);
end;

procedure TLittleRobotConstructor.StopSoundMoveMotor;
begin
  FsndElectricalMotor.Pitch.ChangeTo(1.0, 0.5);
  FsndElectricalMotor.Stop;
end;

procedure TLittleRobotConstructor.SetWheelsAngleTo(aAngle, aDuration: single; aCurve: integer);
begin
  FWheelLeft.Angle.ChangeTo(aAngle, aDuration, aCurve);
  FWheelRight.Angle.ChangeTo(aAngle, aDuration, aCurve);
end;

procedure TLittleRobotConstructor.CreateImpacts;
begin
  FImpact1 := TImpact1.Create(-BodyWidth*0.5*0.4, -BodyHeight*0.45, -1);
  AddChild(FImpact1, 3);
  FImpact2 := TImpact1.Create(BodyWidth*0.5*0.3, -BodyHeight*0.55, -1);
  AddChild(FImpact2, 3);
end;

{ TProgressLine }

procedure TProgressLine.SetDistanceTraveled(AValue: single);
begin
  FDistanceTraveled := AValue;
  FLRIcon.CenterX := FDistanceTraveled/FDistanceToTravel * Width;
end;

class procedure TProgressLine.LoadTexture(aAtlas: TOGLCTextureAtlas);
begin
  texLRIcon := aAtlas.AddFromSVG(SpriteBGFolder+'LR.svg', -1, ScaleH(32));
end;

constructor TProgressLine.Create;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_GAMEUI);
  SetShapeLine(PointF(FScene.Width*0.05, texLRIcon^.FrameHeight*1.1),
                PointF(FScene.Width*0.4,texLRIcon^.FrameHeight*1.1));
  LineWidth := 2;
  LineColor := BGRA(200,200,200);

  FLRIcon := TSprite.Create(texLRIcon, False);
  AddChild(FLRIcon, 0);
  FLRIcon.Y.Value := -FLRIcon.Height*0.9;
  FLRIcon.CenterX := 0;
end;

end.

