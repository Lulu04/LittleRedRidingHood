unit u_sprite_wolf;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes,
  u_sprite_lrcommon, u_sprite_gameforest,
  u_audio, u_common;

type

{ TBalloon }

TBalloon = class(TSprite)
private
  const BALLOON_SIZE_MULTIPLICATOR = 6;
        BALLOON_INFLATE_TIME = 6; //7;
private
  FInflateTerminated: boolean;
  FTimeMultiplicator: single;
  FPath: TOGLCPath;
  FSize: TFParam;
public
  Inflatable: TUIPAnel;
  BaseBalloon, Paf: TSprite;
  Glow: TOGLCGlow;
  function RandomColor: TBGRAPixel;
  procedure ComputePath;
  constructor Create;
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;

  procedure StartInflate;
  procedure Explode;
  function BalloonCollideWithArrow: boolean;
  function GetSceneBallonCenterCoor: TPointF;
  property InflateTerminated: boolean read FInflateTerminated;
  property TimeMultiplicator: single read FTimeMultiplicator write FTimeMultiplicator;
end;

{ TWolfHead }

TWolfHead = class(TSprite)
private
  FDontShowOriginalMouth: boolean;
  procedure SetDontShowOriginalMouth(AValue: boolean);
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  MouthClose, MouthTongue, MouthHurt, MouthFalling, MouthSurprise: TSprite;
  constructor Create;
  procedure HideAllMouth;
  procedure SetMouthClose;
  procedure SetMouthTongue;
  procedure SetMouthFalling;
  procedure SetMouthHurt;
  procedure SetMouthSurprise;
  property DontShowOriginalMouth: boolean read FDontShowOriginalMouth write SetDontShowOriginalMouth;
end;

//

TWolfState = (wsUndefined=0, wsIdle,
              wsWalking, wsFalling, wsSeatAndStunned,
              wsJumping,
              wsWinner, wsLoser,
              wsTakeObjectFromGround, wsPutObjectToGround,
              wsCarryingIdle, wsCarryingWalking,
              wsPissing, wsFart,
              //  specific "pin forest" game
              wsFlyingWithBallon, wsPickingBalloon, wsInflateBalloon,
              wsTargetedByStormCloud, wsDestroyingElevator,
              // specific in space
              wsSeatOnChair
              );

TFuncCheckIfLost = function(): boolean of object;
TSimpleCallback = procedure of object;
{ TWolf }

TWolf = class(TCharacterWithDialogPanel)
private
  EllipseStarStunned: TOGLCPathToFollow;
  FAtlas: TOGLCTextureAtlas;
  FOnBalloonExplode: TSimpleCallback;
  FOnCheckIfLost: TFuncCheckIfLost;
  FTargetElevatorEngine: TElevatorEngine;
  FYGroundAtTheTopOfTheScreen, FYGroundAtBottomOfTheScreen: single;
  StarStunned: array[0..2] of TSpriteOnPathToFollow;
  FState: TWolfState;
  FUsedBalloonCrate: TBalloonCrate;
  FIsForestGame: boolean;
  FObjectToCarry: TSimpleSurfaceWithEffect;
  FPEPiss: TParticleEmitter;
  FsndPiss: TALSSound;
  procedure SetState(AValue: TWolfState);
  procedure ForceIdlePosition(aImmediat: boolean=False);
  procedure ForceCarryingIdlePosition;
  procedure MoveYToSeatDown(aDuration: single);
  procedure MoveYToStandUp(aDuration: single);
  procedure CreateBalloon;
  procedure KillBalloon;
  procedure CreateStarStunned;
  procedure KillStarStunned;
  procedure CreatePiss;
  procedure CreateFart;
  procedure KillThePiss;
private
  FIsJumping: boolean;
  FCallbackDoOnJumpMove: TCallbackDoOnJumpMove;
  FJumpDeltaX: single;
  procedure ProcessCallbackDoOnJumpMove(aDuration: single; aJumpStep: integer);
private // behavior specific to mini game
  procedure ApplyForestGameBehavior;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  // The reference point is the top/center of the legs
  Head: TWolfHead;
  Abdomen, LeftArm, RightArm, LeftLeg, RightLeg, Tail, LeftLegSeat: TSprite;
  Balloon: TBalloon;
  // aLayerIndex can be -1 to avoid to add the sprite to a scene layer.
  // Usefull if the wolf is a child of another surface
  constructor Create(aIsForestGame: boolean; aLayerIndex: integer=LAYER_WOLF);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  function GetSceneBallonCenterCoor: TPointF;
  property State: TWolfState read FState write SetState;
  property YGroundAtTheTopOfTheScreen: single read FYGroundAtTheTopOfTheScreen write FYGroundAtTheTopOfTheScreen;
  property YGroundAtBottomOfTheScreen: single read FYGroundAtBottomOfTheScreen write FYGroundAtBottomOfTheScreen;

  property OnCheckIfLost: TFuncCheckIfLost read FOnCheckIfLost write FOnCheckIfLost;
  property OnBalloonExplode: TSimpleCallback read FOnBalloonExplode write FOnBalloonExplode;
  property TargetElevatorEngine: TElevatorEngine read FTargetElevatorEngine write FTargetElevatorEngine;
public // utils to control character during cinematics
  procedure WalkHorizontallyTo(aX: single; aTarget: TObject; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
  procedure Idle(aImmediat: boolean=False);
  procedure IdleLeft;
  procedure IdleRight;
  function IsOrientedToRight: boolean;
  procedure Jump;
  procedure SetRunMode; virtual;
  procedure SetWalkMode; virtual;

  procedure SetAsCarryingAnObject(aObject: TSimpleSurfaceWithEffect);
  property ObjectToCarry: TSimpleSurfaceWithEffect read FObjectToCarry write FObjectToCarry;
  // a default routine is assigned to this callback. Change to customize the jump
  // aJumpStep: 0=up  1=down  2=jump is done
  property CallbackDoOnJumpMove: TCallbackDoOnJumpMove read FCallbackDoOnJumpMove write FCallbackDoOnJumpMove;
  property IsJumping: boolean read FIsJumping;
  // The number of pixel to shift the character when s/he jumps
  // default value is FScene.Width*0.08
  property JumpDeltaX: single read FJumpDeltaX write FJumpDeltaX;
  property Atlas: TOGLCTextureAtlas read FAtlas write FAtlas;
end;


{ TWolfPenelope }
// the sister
TWolfPenelope = class(TWolf)
private
  FShirt, FSkirt, FNavelPiercing, FNosePiercing, FRightShoe, FLeftShoe,
  FMouth, FLashes, FHair, FPonyTail: TSprite;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  constructor Create(aIsForestGame: boolean; aLayerIndex: integer=LAYER_WOLF);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

{ TWolfMarcus }
// the brother

TWolfMarcus = class(TWolf)
private
  FShirt, FShortLeft, FShortRight, FHat: TSprite;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  constructor Create(aIsForestGame: boolean; aLayerIndex: integer=LAYER_WOLF);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

{ TWolfFather }

TWolfFather = class(TWolf)
private
  FHat, FGlasses, FBeard, FBelt: TSprite;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  constructor Create(aIsForestGame: boolean; aLayerIndex: integer=LAYER_WOLF);
end;

{ TWolfMother }

TWolfMother = class(TWolf)
private
  FHat, FMouth, FPonyTail, FDress, FLeftArmStrap,
  FLeftLegStrap, FRightLegStrap, FRightShoe, FLeftShoe: TSprite;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  constructor Create(aIsForestGame: boolean; aLayerIndex: integer=LAYER_WOLF);
end;

{ TWolfRomeo }

TWolfRomeo = class(TWolf)
private
 FHat: TSprite;
 protected
   procedure SetFlipH(AValue: boolean); override;
   procedure SetFlipV(AValue: boolean); override;
 public
   constructor Create(aIsForestGame: boolean; aLayerIndex: integer=LAYER_WOLF);
end;

{ TWolfJulia }

TWolfJulia = class(TWolf)
private
 FNewHead, FDress: TSprite;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  constructor Create(aIsForestGame: boolean; aLayerIndex: integer=LAYER_WOLF);
end;

{ TWolfGate }

TWolfGate = class
private
  FCount: integer;
  FAppearTime, FTimeAccu, FTimeMultiplicator: single;
  FOnBalloonExplode: TSimpleCallback;
  FOnCheckIfLost: TFuncCheckIfLost;
  FTargetElevatorEngine: TElevatorEngine;
  FAppearPosition: TPointF;
  FRightDirection: boolean;
  FYGroundAtTheTopOfTheScreen: single;
public
  // aWolfAppearsAtPosition is the center of the ground
  constructor Create(aWolfAppearsAtPosition: TPointF; aToTheRight: boolean);
  procedure Update(const aElapsedTime: single);

  property Count: integer read FCount write FCount;
  property AppearTime: single read FAppearTime write FAppearTime;
  property TimeMultiplicator: single read FTimeMultiplicator write FTimeMultiplicator;
  property YGroundAtTheTopOfTheScreen: single read FYGroundAtTheTopOfTheScreen write FYGroundAtTheTopOfTheScreen;
  property OnCheckIfLost: TFuncCheckIfLost read FOnCheckIfLost write FOnCheckIfLost;
  property OnBalloonExplode: TSimpleCallback read FOnBalloonExplode write FOnBalloonExplode;
  property TargetElevatorEngine: TElevatorEngine write FTargetElevatorEngine;
end;

var
  texWolfHead,  //EyeOpen + EyeClose + EyeHurt
  texWolfMouthClose,
  texWolfMouthTongue,
  texWolfMouthHurt,
  texWolfMouthFalling,
  texWolfMouthSurprise,
  texWolfLeftArm,
  texWolfRightArm,
  texWolfLeftLeg,
  texWolfRightLeg,
  texWolfAbdomen,
  texWolfTail,
  texWolfStarWhenStunned: PTexture;

  texBaseBalloon,
  texStringBalloon,
  texPafBalloon,

  texPenelopeShirt,
  texPenelopeSkirt,
  texPenelopeNavelPiercing,
  texPenelopeNosePiercing,
  texPenelopeShoe,
  texPenelopeMouth,
  texPenelopeLashes,
  texPenelopeHair,
  texPenelopePonytail,

  texMarcusShirt,
  texMarcusShortLeft,
  texMarcusShortRight,
  texMarcusHat,

  texFatherHat, texFatherGlasses, texFatherBeard, texFatherBelt,

  texMotherHat, texMotherMouth, texMotherPonytail, texMotherDress,
  texMotherLeftArmStrap, texMotherLeftLegStrap, texMotherRightLegStrap,
  texMotherShoe,

  texRomeoHat,

  texJuliaHead, texJuliaDress,


  texCastle: PTexture;

  procedure LoadWolfTextures(aAtlas: TAtlas);
  procedure LoadBaseBallonTexture(aAtlas: TAtlas);
  procedure LoadPenelopeTextures(aAtlas: TAtlas);
  procedure LoadMarcusTextures(aAtlas: TAtlas);
  procedure LoadFatherTextures(aAtlas: TAtlas);
  procedure LoadMotherTextures(aAtlas: TAtlas);
  procedure LoadRomeoTextures(aAtlas: TAtlas);
  procedure LoadJuliaTextures(aAtlas: TAtlas);

implementation
uses u_app, BGRAPath, GeometricShapes, u_resourcestring;

procedure LoadWolfTextures(aAtlas: TAtlas);
var path: string;
  ima: TBGRABitmap;
begin
  path := SpriteFolder+'Wolf'+DirectorySeparator;
  texWolfHead := aAtlas.AddMultiFrameImageFromSVG([path+'WolfHeadEyeOpen.svg',
                                                   path+'WolfHeadEyeClose.svg',
                                                   path+'WolfHeadEyeHurt.svg'], ScaleW(77), -1, 3, 1, 1);

  texWolfMouthClose := aAtlas.AddFromSVG(path+'WolfMouthClose.svg', ScaleW(21), -1);
  texWolfMouthTongue := aAtlas.AddFromSVG(path+'WolfMouthTongue.svg', ScaleW(29), -1);
  texWolfMouthHurt := aAtlas.AddFromSVG(path+'WolfMouthHurt.svg', ScaleW(30), -1);
  texWolfMouthFalling := aAtlas.AddFromSVG(path+'WolfMouthFalling.svg', ScaleW(22), -1);
  texWolfMouthSurprise := aAtlas.AddFromSVG(path+'WolfMouthSurprise.svg', ScaleW(20), -1);
  texWolfLeftArm := aAtlas.AddFromSVG(path+'WolfLeftArm.svg', ScaleW(40), -1);
  texWolfRightArm := aAtlas.AddFromSVG(path+'WolfRightArm.svg', ScaleW(40), -1);
  texWolfLeftLeg := aAtlas.AddFromSVG(path+'WolfLeftLeg.svg', ScaleW(34), -1);
  texWolfRightLeg := aAtlas.AddFromSVG(path+'WolfRightLeg.svg', ScaleW(37), -1);
  texWolfAbdomen := aAtlas.AddFromSVG(path+'WolfAbdomen.svg', -1, ScaleH(52));
  texWolfTail := aAtlas.AddFromSVG(path+'WolfTail.svg', ScaleW(50), -1);

  if aAtlas.LoadedFromFile then
    texWolfStarWhenStunned := aAtlas.RetrieveTextureByFileName('WolfStarWhenStunned')
  else begin
    ima := TBGRABitmap.Create(ScaleW(16), ScaleH(20));
    FGeometricShapes := TGeometricShapes.Create;
    FGeometricShapes.GlobalColor := BGRA(255,255,0);
    FGeometricShapes.DrawStar(ima);
    texWolfStarWhenStunned := aAtlas.Add(ima);
    texWolfStarWhenStunned^.Filename := 'WolfStarWhenStunned';
    FGeometricShapes.Free;
    FGeometricShapes := NIL;
  end;
end;

procedure LoadBaseBallonTexture(aAtlas: TAtlas);
var path: String;
begin
  path := SpriteFolder+'Common'+DirectorySeparator;
  texBaseBalloon := aAtlas.AddFromSVG(path+'BaseBalloon.svg', ScaleW(23), -1);
  texStringBalloon := aAtlas.AddFromSVG(path+'BalloonString.svg', -1, ScaleH(78));
  texPafBalloon := aAtlas.AddFromSVG(path+'Paf.svg', ScaleW(166), -1);
end;

procedure LoadPenelopeTextures(aAtlas: TOGLCTextureAtlas);
var path: string;
begin
  path := SpriteWolfFolder;
  texPenelopeShirt := aAtlas.AddFromSVG(path+'PenelopeShirt.svg', ScaleW(24), -1);
  texPenelopeSkirt := aAtlas.AddFromSVG(path+'PenelopeSkirt.svg', ScaleW(42), -1);
  texPenelopeNavelPiercing := aAtlas.AddFromSVG(path+'PenelopeNavelPiercing.svg', ScaleW(5), -1);
  texPenelopeNosePiercing := aAtlas.AddFromSVG(path+'PenelopeNosePiercing.svg', ScaleW(5), -1);
  texPenelopeShoe := aAtlas.AddFromSVG(path+'PenelopeShoe.svg', ScaleW(34), -1);
  texPenelopeMouth := aAtlas.AddFromSVG(path+'PenelopeMouth.svg', ScaleW(26), -1);
  texPenelopeLashes := aAtlas.AddFromSVG(path+'PenelopeLashes.svg', ScaleW(38), -1);
  texPenelopeHair := aAtlas.AddFromSVG(path+'PenelopeHair.svg', ScaleW(49), -1);
  texPenelopePonytail := aAtlas.AddFromSVG(path+'PenelopePonytail.svg', ScaleW(16), -1);
end;

procedure LoadMarcusTextures(aAtlas: TAtlas);
var path: string;
begin
  path := SpriteWolfFolder;
  texMarcusShirt := aAtlas.AddFromSVG(path+'MarcusShirt.svg', ScaleW(39), -1);
  texMarcusShortLeft := aAtlas.AddFromSVG(path+'MarcusLeftShort.svg', ScaleW(17), -1);
  texMarcusShortRight := aAtlas.AddFromSVG(path+'MarcusRightShort.svg', ScaleW(18), -1);
  texMarcusHat := aAtlas.AddFromSVG(path+'MarcusHat.svg', ScaleW(68), -1);
end;

procedure LoadFatherTextures(aAtlas: TAtlas);
var path: string;
begin
  path := SpriteWolfFolder;
  texFatherHat := aAtlas.AddFromSVG(path+'FatherHat.svg', ScaleW(63), -1);
  texFatherGlasses := aAtlas.AddFromSVG(path+'FatherGlasses.svg', ScaleW(27), -1);
  texFatherBeard := aAtlas.AddFromSVG(path+'FatherBeard.svg', ScaleW(31), -1);
  texFatherBelt := aAtlas.AddFromSVG(path+'FatherBelt.svg', ScaleW(35), -1);
end;

procedure LoadMotherTextures(aAtlas: TAtlas);
var path: string;
begin
  path := SpriteWolfFolder;
  texMotherHat := aAtlas.AddFromSVG(path+'MotherHat.svg', ScaleW(89), -1);
  texMotherMouth := aAtlas.AddFromSVG(path+'MotherMouth.svg', ScaleW(26), -1);
  texMotherPonytail := aAtlas.AddFromSVG(path+'MotherPonyTail.svg', -1, ScaleH(44));
  texMotherDress := aAtlas.AddFromSVG(path+'MotherDress.svg', ScaleW(45), -1);
  texMotherLeftArmStrap := aAtlas.AddFromSVG(path+'MotherLeftArmStrap.svg', ScaleW(6), -1);
  texMotherLeftLegStrap := aAtlas.AddFromSVG(path+'MotherLeftLegStrap.svg', ScaleW(11), -1);
  texMotherRightLegStrap := aAtlas.AddFromSVG(path+'MotherRightLegStrap.svg', ScaleW(11), -1);
  texMotherShoe := aAtlas.AddFromSVG(path+'MotherShoe.svg', ScaleW(34), -1);
end;

procedure LoadRomeoTextures(aAtlas: TAtlas);
begin
  texRomeoHat := aAtlas.AddFromSVG(SpriteWolfFolder+'RomeoHat.svg', ScaleW(61), -1);
end;

procedure LoadJuliaTextures(aAtlas: TAtlas);
var path: string;
begin
  path := SpriteWolfFolder;
  texJuliaHead := aAtlas.AddFromSVG(path+'JuliaHead.svg', ScaleW(79), -1);
  texJuliaDress := aAtlas.AddFromSVG(path+'JuliaDress.svg', ScaleW(67), -1);
end;


{ TWolfGate }

constructor TWolfGate.Create(aWolfAppearsAtPosition: TPointF; aToTheRight: boolean);
begin
  FAppearTime := 2.0;
  FTimeMultiplicator := 1.0;
  FAppearPosition := aWolfAppearsAtPosition;
  FRightDirection := aToTheRight;
end;

procedure TWolfGate.Update(const aElapsedTime: single);
var w: TWolf;
begin
  if FCount = 0 then exit;

  FTimeAccu := FTimeAccu + FTimeMultiplicator*aElapsedTime;
  if FTimeAccu >= FAppearTime then begin
    FTimeAccu := FTimeAccu - FAppearTime;
    dec(FCount);

    w := TWolf.Create(True);
    w.X.Value := FAppearPosition.x;
    w.Y.Value := FAppearPosition.y - w.DeltaYToBottom;
    w.TimeMultiplicator := FTimeMultiplicator;
    w.SetFlipH(FRightDirection);
    w.State := wsWalking;
    w.YGroundAtTheTopOfTheScreen := FYGroundAtTheTopOfTheScreen;
    w.YGroundAtBottomOfTheScreen := FAppearPosition.y;
    w.OnCheckIfLost := FOnCheckIfLost;
    w.OnBalloonExplode := FOnBalloonExplode;
    w.TargetElevatorEngine := FTargetElevatorEngine;
  end;
end;

{ TBalloon }

function TBalloon.RandomColor: TBGRAPixel;
begin
  case random(8) of
    0: Result := BGRA(255,0,0);
    1: Result := BGRA(0,255,0);
    2: Result := BGRA(0,0,255);
    3: Result := BGRA(255,255,0);
    4: Result := BGRA(255,0,255);
    5: Result := BGRA(0,255,255);
    6: Result := BGRA(255,128,64);
    7: Result := BGRA(64,128,255);
  end;
end;

procedure TBalloon.ComputePath;
var v, bw: single;
  r: TRectF;
begin
  v := FSize.Value;
  bw := BaseBalloon.Width*0.5;

  FPath := ComputeOpenedSpline([PointF(-bw, 0), // left base
                                PointF(-bw*v,-bw*v), // left side
                                PointF(0,-bw*v*2), // top
                                PointF(bw*v,-bw*v), // right side
                                PointF(bw,0)], // right base
                              0, 5, ssInside);
  r := FPath.Bounds;
  if (r.Top <> 0) or (r.Left <> 0) then
    FPath.Translate(PointF(-r.Left, -r.Top));

  FPath.RemoveIdenticalConsecutivePoint;
  FPath.ClosePath;
end;

constructor TBalloon.Create;
var c: TBGRAPixel;
  r: single;
begin
  inherited Create(texStringBalloon, False);
  c := RandomColor;
  FTimeMultiplicator := 1.0;

  BaseBalloon := TSprite.Create(texBaseBalloon, False);
  AddChild(BaseBalloon);
  BaseBalloon.Tint.Value := c;
  BaseBalloon.CenterX := Width*0.5;
  BaseBalloon.BottomY := 0;

  Paf := TSprite.Create(texPafBalloon, False);
  AddChild(Paf, 0);
  Paf.CenterX := Width*0.5;
  Paf.BottomY := 0;
  Paf.Visible := False;

  FSize := TFParam.Create;
  FSize.Value := 1;

  Inflatable := TUIPanel.Create(FScene);
  Inflatable.MouseInteractionEnabled := False;
  Inflatable.ChildClippingEnabled := False;
  Inflatable.BodyShape.Border.LinePosition := lpMiddle;
  ComputePath;
  Inflatable.BodyShape.SetCustomShape(FPath, 5.0);
  Inflatable.BodyShape.Border.Color := c;
  Inflatable.BodyShape.Fill.Color := c;
  AddChild(Inflatable, 0);

  r := Width*BALLOON_SIZE_MULTIPLICATOR*0.25{*1.3};
  Glow := TOGLCGlow.Create(FScene, r, r, BGRAWhite);
  AddChild(Glow, 1);
end;

destructor TBalloon.Destroy;
begin
  FSize.Free;
  FSize := NIL;
  inherited Destroy;
end;

procedure TBalloon.Update(const aElapsedTime: single);
var oldSize: single;
begin
  inherited Update(aElapsedTime);

  if FSize.State = psUSE_CURVE then begin
    oldSize := FSize.Value;
    FSize.OnElapse(aElapsedTime);
    if FSize.Value <> oldSize then begin
      ComputePath;
      Inflatable.BodyShape.SetCustomShape(FPath, 5.0);
    end;
    if FSize.State = psNO_CHANGE then FInflateTerminated := True;
  end;
  Inflatable.CenterX := Width*0.5;
  Inflatable.BottomY := -BaseBalloon.Height;

  Glow.SetCenterCoordinate(Inflatable.X.Value+Inflatable.Width*0.3, Inflatable.Y.Value+Inflatable.Width*0.3);
  Glow.SetSize(Inflatable.Width div 2, Inflatable.Width div 2);
end;

procedure TBalloon.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // AFTER EXPLODE
    0: begin
      Opacity.ChangeTo(0, 0.5);
      KillDefered(0.5);
    end;

    // BALLOON DISAPPEAR IN THE SKY
    100: begin
      MoveXRelative(Width, 0.5, idcSinusoid);
      PostMessage(101, 0.5);
    end;
    101: begin
      MoveXRelative(-Width*2, 0.5, idcSinusoid);
      PostMessage(102, 0.5);
    end;
    102: begin
      if Y.Value+Height*2 < 0 then begin
        Kill;
        exit;
      end;
      MoveXRelative(Width*2, 0.5, idcSinusoid);
      PostMessage(101, 0.5);
    end;
  end;
end;

procedure TBalloon.StartInflate;
begin
  FSize.ChangeTo(BALLOON_SIZE_MULTIPLICATOR, BALLOON_INFLATE_TIME*FTimeMultiplicator, idcStartSlowEndFast);
  Audio.PlayThenKillSound('balloon_inflate_4.ogg', 1.0);
end;

procedure TBalloon.Explode;
begin
  Glow.Visible := False;
  Inflatable.Visible := False;
  Paf.Visible := True;
  Audio.PlayThenKillSound('balloon-pop.ogg', 1.0);
  PostMessage(0, 0.2);
end;

function TBalloon.BalloonCollideWithArrow: boolean;
var o: TSimpleSurfaceWithEffect;
  p: TPointF;
begin
  if not FInflateTerminated then exit(False);

  p := Inflatable.SurfaceToScene(PointF(0,0));
  o := FParentScene.Layer[LAYER_ARROW].CollisionTest(p.x, p.y, Inflatable.Width, Inflatable.Height);
  Result := o <> NIL;
  if Result then o.Kill;
end;

function TBalloon.GetSceneBallonCenterCoor: TPointF;
begin
  Result := BaseBalloon.GetXY;
  Result.y := Result.y - Inflatable.Height*0.5;
  Result := SurfaceToScene(Result);
end;


{ TWolfHead }

procedure TWolfHead.SetDontShowOriginalMouth(AValue: boolean);
begin
  if FDontShowOriginalMouth = AValue then Exit;
  FDontShowOriginalMouth := AValue;
  if AValue then HideAllMouth;
end;

procedure TWolfHead.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  MouthClose.FlipH := AValue;
  MouthTongue.FlipH := AValue;
  MouthHurt.FlipH := AValue;
  MouthFalling.FlipH := AValue;
  MouthSurprise.FlipH := AValue;
end;

procedure TWolfHead.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  MouthClose.FlipV := AValue;
  MouthTongue.FlipV := AValue;
  MouthHurt.FlipV := AValue;
  MouthFalling.FlipV := AValue;
  MouthSurprise.FlipV := AValue;
end;

constructor TWolfHead.Create;
begin
  inherited Create(texWolfHead, False);
  Frame := 1;
  ApplySymmetryWhenFlip := True;

  MouthClose := TSprite.Create(texWolfMouthClose, False);
  AddChild(MouthClose);
  MouthClose.SetCenterCoordinate(Width*0.6, Height*0.85);
  MouthClose.ApplySymmetryWhenFlip := True;
  MouthClose.Freeze := True;

  MouthTongue := TSprite.Create(texWolfMouthTongue, False);
  AddChild(MouthTongue);
  MouthTongue.SetCenterCoordinate(Width*0.50, Height*0.945);
  MouthTongue.ApplySymmetryWhenFlip := True;
  MouthTongue.Freeze := True;

  MouthHurt := TSprite.Create(texWolfMouthHurt, False);
  AddChild(MouthHurt);
  MouthHurt.CenterX := Width*0.55;
  MouthHurt.Y.Value := Height*0.86;
  MouthHurt.ApplySymmetryWhenFlip := True;
  MouthHurt.Freeze := True;

  MouthFalling := TSprite.Create(texWolfMouthFalling, False);
  AddChild(MouthFalling);
  MouthFalling.CenterX := Width*0.55;
  MouthFalling.Y.Value := Height*0.86;
  MouthFalling.ApplySymmetryWhenFlip := True;
  MouthFalling.Freeze := True;

  MouthSurprise := TSprite.Create(texWolfMouthSurprise, False);
  AddChild(MouthSurprise);
  MouthSurprise.SetCenterCoordinate(Width*0.6, Height*0.85);
  MouthSurprise.ApplySymmetryWhenFlip := True;
  MouthSurprise.Freeze := True;
end;

procedure TWolfHead.HideAllMouth;
begin
  MouthClose.Visible := False;
  MouthTongue.Visible := False;
  MouthHurt.Visible := False;
  MouthFalling.Visible := False;
  MouthSurprise.Visible := False;
end;

procedure TWolfHead.SetMouthClose;
begin
  MouthClose.Visible := not FDontShowOriginalMouth;
  MouthTongue.Visible := False;
  MouthHurt.Visible := False;
  MouthFalling.Visible := False;
  MouthSurprise.Visible := False;
end;

procedure TWolfHead.SetMouthTongue;
begin
  MouthClose.Visible := False;
  MouthTongue.Visible := not FDontShowOriginalMouth;
  MouthHurt.Visible := False;
  MouthFalling.Visible := False;
  MouthSurprise.Visible := False;
end;

procedure TWolfHead.SetMouthFalling;
begin
  MouthClose.Visible := False;
  MouthTongue.Visible := False;
  MouthHurt.Visible := False;
  MouthFalling.Visible := not FDontShowOriginalMouth;
  MouthSurprise.Visible := False;
end;

procedure TWolfHead.SetMouthHurt;
begin
  MouthClose.Visible := False;
  MouthTongue.Visible := False;
  MouthHurt.Visible := not FDontShowOriginalMouth;
  MouthFalling.Visible := False;
  MouthSurprise.Visible := False;
end;

procedure TWolfHead.SetMouthSurprise;
begin
  MouthClose.Visible := False;
  MouthTongue.Visible := False;
  MouthHurt.Visible := False;
  MouthFalling.Visible := False;
  MouthSurprise.Visible := not FDontShowOriginalMouth;
end;

{ TWolf }

procedure TWolf.SetState(AValue: TWolfState);
begin
  if FState = AValue then Exit;
  if (AValue = wsJumping) and FIsJumping then exit;

  if FState = wsSeatAndStunned then MoveYToStandUp(0.5);

  FState := AValue;
  case FState of
    wsIdle: begin
      ForceIdlePosition;
      PostMessage(0);
      PostMessage(2);
    end;
    wsPickingBalloon: begin
      PostMessage(50);
    end;
    wsInflateBalloon: begin
      Balloon.StartInflate;
      Head.Angle.ChangeTo(20, 0.5, idcSinusoid);
      PostMessage(100);
      PostMessage(102);
    end;
    wsFlyingWithBallon: begin
      Speed.y.ChangeTo(FScene.ScaleDesignToSceneF(-40-random*20), 1, idcSinusoid);
      PostMessage(200);
      PostMessage(202);
      PostMessage(204);
      PostMessage(206);
      PostMessage(208);
    end;
    wsFalling: begin
      Speed.X.ChangeTo(0, 0.5);
      Speed.y.ChangeTo(FScene.ScaleDesignToScene(360), 1.5, idcSinusoid);
      Head.SetMouthFalling;
      PostMessage(250);
    end;
    wsTargetedByStormCloud: begin
      Speed.y.Value := 0;
      PostMessage(230);
    end;

    wsWalking, wsCarryingWalking: begin
      if not FFlipH then Speed.x.ChangeTo(-WalkSpeed, TimeMultiplicator, idcSinusoid)
        else Speed.x.ChangeTo(WalkSpeed, TimeMultiplicator, idcSinusoid);
      PostMessage(300);
    end;

    wsSeatAndStunned: begin
      PostMessage(280);
    end;

    wsSeatOnChair: begin
      PostMessage(900);
    end;

    wsDestroyingElevator: begin
      PostMessage(400);
    end;

    wsWinner: begin
      ForceIdlePosition;
      PostMessage(500, 0.2);
    end;

    wsLoser: begin
      ForceIdlePosition;
      PostMessage(600);
    end;

    wsTakeObjectFromGround: begin
      Speed.Value := PointF(0, 0);
      PostMessage(650);
    end;

    wsCarryingIdle: begin
      ForceCarryingIdlePosition;
      PostMessage(0);
      PostMessage(2);
    end;

    wsPutObjectToGround: begin
      Speed.Value := PointF(0, 0);
      ForceCarryingIdlePosition;
      PostMessage(700);
      //do anim to put object then set state to wsIdle
    end;

    wsPissing: begin
      Speed.Value := PointF(0, 0);
      PostMessage(750);
    end;

    wsFart: begin
      PostMessage(780);
    end;

    wsJumping: begin
      FIsJumping := True;
      Speed.Value := PointF(0, 0);
      PostMessage(850);
    end;
  end;
end;

procedure TWolf.ForceIdlePosition(aImmediat: boolean);
var d: single;
begin
  if aImmediat then d := 0.0 else d := 1.0;
  Speed.Value := PointF(0,0);
  Head.SetMouthClose;
  Head.Angle.ChangeTo(0, d, idcSinusoid);
  Head.Frame := 1;
  Abdomen.Angle.ChangeTo(0, d, idcSinusoid);
  LeftArm.Angle.ChangeTo(60, d, idcSinusoid);
  RightArm.Angle.ChangeTo(-28, d, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, d, idcSinusoid);
  RightLeg.Angle.ChangeTo(0, d, idcSinusoid);
  Tail.Angle.ChangeTo(0, d, idcSinusoid);
  LeftLegSeat.Angle.ChangeTo(0, d, idcSinusoid);
  LeftLegSeat.Visible := False;
  LeftLeg.Visible := True;
  // kill the 'piss' if any
  KillThePiss;
end;

procedure TWolf.ForceCarryingIdlePosition;
begin
  Speed.Value := PointF(0,0);
  Head.SetMouthClose;
  Head.Angle.ChangeTo(0, 1, idcSinusoid);
  Head.Frame := 1;
  Abdomen.Angle.ChangeTo(0, 1, idcSinusoid);
  LeftArm.Angle.ChangeTo(135, 1, idcSinusoid);
  RightArm.Angle.ChangeTo(0, 1, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, 1, idcSinusoid);
  RightLeg.Angle.ChangeTo(0, 1, idcSinusoid);
  Tail.Angle.ChangeTo(0, 1, idcSinusoid);
  LeftLegSeat.Angle.ChangeTo(0, 1, idcSinusoid);
  LeftLegSeat.Visible := False;
  LeftLeg.Visible := True;
  // kill the 'piss' if any
  KillThePiss;
end;

procedure TWolf.MoveYToSeatDown(aDuration: single);
begin
  Y.ChangeTo(Y.Value+DeltaYToBottom, aDuration*TimeMultiplicator, idcStartFastEndSlow);
end;

procedure TWolf.MoveYToStandUp(aDuration: single);
begin
  Y.ChangeTo(Y.Value-DeltaYToBottom, aDuration*TimeMultiplicator, idcStartFastEndSlow);
end;

procedure TWolf.CreateBalloon;
begin
  Balloon := TBalloon.Create;
  Abdomen.AddChild(Balloon, 0);
  Balloon.Pivot := PointF(0.5, 1);
  Balloon.CenterX := RightArm.X.Value+RightArm.Width*0.25;
  Balloon.BottomY := RightArm.Y.Value+RightArm.Height*0.7;
  Balloon.TimeMultiplicator := TimeMultiplicator;
end;

procedure TWolf.KillBalloon;
begin
  if FState in [wsPickingBalloon, wsInflateBalloon] then begin
    if Balloon <> NIL then DeleteChild(Balloon);
    Balloon := NIL;
  end;
end;

procedure TWolf.CreateStarStunned;
var path: TOGLCPath;
  i: integer;
begin
  path := NIL;
  path.CreateEllipse(0, 0, texWolfHead^.FrameWidth div 2, texWolfHead^.FrameWidth div 5, True);

  EllipseStarStunned := TOGLCPathToFollow.Create(FScene);
  EllipseStarStunned.InitFromPath(path);
  EllipseStarStunned.Loop := True;
  EllipseStarStunned.Border.Width := PPIScale(5);
  EllipseStarStunned.Border.Color := BGRA(200,200,10);
  EllipseStarStunned.ChildsUseParentOpacity := True;
  AddChild(EllipseStarStunned, 0);
  EllipseStarStunned.CenterX := EllipseStarStunned.Width*0.3;
  EllipseStarStunned.BottomY := (-Abdomen.Height-Head.Height)*0.8;
  EllipseStarStunned.ApplySymmetryWhenFlip := True;
  EllipseStarStunned.FlipH := FlipH;
  EllipseStarStunned.FlipV := FlipV;

  for i:=0 to High(StarStunned) do begin
    StarStunned[i] := TSpriteOnPathToFollow.CreateAsChildOf(EllipseStarStunned, texWolfStarWhenStunned, False);
    StarStunned[i].AutoRotate := False;
    StarStunned[i].DistanceTraveled.Value := i*EllipseStarStunned.PathLength/Length(StarStunned);
    StarStunned[i].DistanceTraveled.AddConstant(EllipseStarStunned.PathLength);
  end;
end;

procedure TWolf.KillStarStunned;
begin
  EllipseStarStunned.Opacity.ChangeTo(0, 1.0*TimeMultiplicator);
  EllipseStarStunned.KillDefered(1.0*TimeMultiplicator);
  EllipseStarStunned := NIL;
end;

procedure TWolf.CreatePiss;
begin
  FPEPiss := TParticleEmitter.Create(FScene);
  FPEPiss.LoadFromFile(ParticleFolder+'WolfPissing.par', FAtlas);
  AddChild(FPEPiss, 0);
  FPEPiss.SetCoordinate(-BodyWidth*0.25, 0);
  FsndPiss := Audio.AddSound('piss.ogg');
  FsndPiss.Loop := True;
  FsndPiss.Volume.Value := 0.85;
  FsndPiss.Play(True);
end;

procedure TWolf.CreateFart;
var pe: TParticleEmitter;
begin
  pe := TParticleEmitter.Create(FScene);
  pe.LoadFromFile(ParticleFolder+'WolfFart.par', FAtlas);
  AddChild(pe, -1);
  pe.SetCoordinate(BodyWidth*0.25, 0);
  pe.Shoot;
  pe.KillDefered(7);
  with Audio.AddSound('fart-1.ogg') do begin
    PlayThenKill(True);
  end;
end;

procedure TWolf.KillThePiss;
begin
  if FPEPiss <> NIL then begin
    FPEPiss.ParticlesToEmit.Value := 0;
    FPEPiss.Opacity.ChangeTo(0, 3.0);
    FPEPiss.KillDefered(3);
    FPEPiss := NIL;
  end;
  if FsndPiss <> NIL then begin
    FsndPiss.Kill;
    FsndPiss := NIL;
  end;
end;

procedure TWolf.ApplyForestGameBehavior;
var o: TSimpleSurfaceWithEffect;
  xx: single;
begin
  if (State = wsFlyingWithBallon) then begin
    // check if balloon collide with an arrow
    if Balloon.BalloonCollideWithArrow then begin
      if Balloon <> NIL then begin
        Balloon.Explode;
        Balloon := NIL;
        FOnBalloonExplode();
      end;
      State := wsFalling;
    end else
    // check if the wolf is at the top of the screen
      if Y.Value+DeltaYToBottom <= FYGroundAtTheTopOfTheScreen then begin
      // anim balloon disappear in the sky
      if Balloon <> NIL then begin
        Balloon.MoveFromChildToScene(LAYER_FXANIM);
        Balloon.Speed.y.Value := Speed.y.Value;
        Balloon.Angle.ChangeTo(0, 1, idcSinusoid);
        Balloon.PostMessage(100);
      end;

      Speed.Y.Value := 0;
      Y.ChangeTo(FYGroundAtTheTopOfTheScreen-DeltaYToBottom, 0.5, idcSinusoid);
      if TargetElevatorEngine.Breaked then State := wsWinner
        else State := wsWalking;
    end;
  end;

  if State = wsFalling then begin
    // check if there is a ground below the wolf
    if Y.Value+DeltaYToBottom >= FYGroundAtBottomOfTheScreen then begin
      Speed.y.Value := 0;
      Y.Value := FYGroundAtBottomOfTheScreen-DeltaYToBottom;
      State := wsSeatAndStunned;
    end;
  end;

  if State = wsWalking then begin
    // reverse direction on the left/right bounds of the scene
    if ((X.Value-Head.Width*0.5 <= 0) and not FFlipH) or
       ((X.Value+Head.Width*0.5 >= FScene.Width) and FFlipH) then begin
         SetFlipH(not FlipH);
         Speed.x.Value := -Speed.x.Value;
       end;

    // check if there is a balloon crate in front of the wolf
    if not FFlipH then xx := X.Value-texBalloonCrate^.FrameWidth*0.6
      else xx := X.Value-texBalloonCrate^.FrameWidth*1.3;
    o := FParentScene.Layer[LAYER_FXANIM].CollisionTest(xx, Y.Value, 1, 10);
    if (o is TBalloonCrate) and not TBalloonCrate(o).Busy then begin
      FUsedBalloonCrate := TBalloonCrate(o);
      FUsedBalloonCrate.Busy := True;
      if FFlipH then SetFlipH(False);
      Speed.Value := PointF(0, 0);
      ForceIdlePosition;
      State := wsPickingBalloon;
    end;

    // check if there is the elevator engine in front of the wolf
    if not FFlipH then xx := X.Value - Abdomen.Width*1 - texMotorBody^.FrameWidth
      else xx := X.Value + Abdomen.Width*1.1 + texMotorBody^.FrameWidth;
    o := FParentScene.Layer[LAYER_FXANIM].CollisionTest(xx, Y.Value-texMotorBody^.FrameHeight*0.5, texMotorBody^.FrameWidth*0.1, texMotorBody^.FrameHeight);
    if (o is TElevatorEngine) then begin
      ForceIdlePosition;
      State := wsDestroyingElevator;
    end;
  end;

  if FState = wsInflateBalloon then begin
    // check if the balloon is inflated
    if Balloon.InflateTerminated then begin
      FUsedBalloonCrate.Busy := False;
      FUsedBalloonCrate := NIL;
      State := wsFlyingWithBallon;
    end;
  end;

  // check if elevator is destroyed -> wolf win
  if (TargetElevatorEngine <> NIL) and TargetElevatorEngine.Breaked and
    (FState in [wsIdle, wsWalking, wsDestroyingElevator, wsPickingBalloon, wsInflateBalloon]) then begin
    KillBalloon;
    State := wsWinner;
  end;

  // check if wolf lose
  if (FOnCheckIfLost <> NIL) and FOnCheckIfLost() then begin
    if FState in [wsIdle, wsWalking, wsDestroyingElevator, wsPickingBalloon, wsInflateBalloon] then begin
      KillBalloon;
      State := wsLoser;
    end else if FState = wsFlyingWithBallon then begin
      Balloon.Explode;
      Balloon := NIL;
      State := wsFalling;
    end;
  end;
end;

procedure TWolf.SetFlipH(AValue: boolean);
begin
  if FObjectToCarry <> NIL then FObjectToCarry.FlipH := AVAlue;
  inherited SetFlipH(AValue);
  LeftLegSeat.FlipH := AValue;
  LeftLeg.FlipH := AValue;
  RightLeg.FlipH := AValue;
  Abdomen.FlipH := AValue;
  Head.SetFlipH(AValue);
  LeftArm.FlipH := AValue;
  RightArm.FlipH := AValue;
  Tail.FlipH := AValue;
end;

procedure TWolf.SetFlipV(AValue: boolean);
begin
  if FObjectToCarry <> NIL then FObjectToCarry.FlipV := AVAlue;
  inherited SetFlipV(AValue);
  LeftLegSeat.FlipV := AValue;
  LeftLeg.FlipV := AValue;
  RightLeg.FlipV := AValue;
  Abdomen.FlipV := AValue;
  Head.SetFlipV(AValue);
  LeftArm.FlipV := AValue;
  RightArm.FlipV := AValue;
  Tail.FlipV := AValue;
end;

function TWolf.GetSceneBallonCenterCoor: TPointF;
begin
  if Balloon <> NIL then
    Result := Balloon.GetSceneBallonCenterCoor;
end;

procedure TWolf.WalkHorizontallyTo(aX: single; aTarget: TObject;
  aMessageValueWhenFinish: TUserMessageValue; aDelay: single);
begin
  if X.Value < aX then begin
    SetFlipH(True);
    if FObjectToCarry = NIL then State := wsWalking
      else State := wsCarryingWalking;
    CheckHorizontalMoveToX(aX, aTarget, aMessageValueWhenFinish, aDelay);
  end else if X.Value > aX then begin
    SetFlipH(False);
    if FObjectToCarry = NIL then State := wsWalking
      else State := wsCarryingWalking;
    CheckHorizontalMoveToX(aX, aTarget, aMessageValueWhenFinish, aDelay);
  end else PostMessageToTargetObject(aTarget, aMessageValueWhenFinish, aDelay);
end;

procedure TWolf.Idle(aImmediat: boolean);
begin
  ForceIdlePosition(aImmediat);
end;

procedure TWolf.ProcessCallbackDoOnJumpMove(aDuration: single; aJumpStep: integer);
var v: single;
begin
  if IsOrientedToRight then v := 1 else v := -1;
  case aJumpStep of
    0: begin  // up
      Y.ChangeTo(Y.Value - FScene.Height*0.1, aDuration, idcStartFastEndSlow);
      X.ChangeTo(X.Value + FJumpDeltaX*v, aDuration, idcLinear);
    end;
    1: begin  // down
      Y.ChangeTo(Y.Value + FScene.Height*0.1, aDuration, idcStartSlowEndFast);// idcStartFastEndSlow);
      X.ChangeTo(X.Value + FJumpDeltaX*v, aDuration, idcLinear);
    end;
    2: FState := wsIdle;
  end;
end;

procedure TWolf.IdleLeft;
begin
  SetFlipH(False);
  State := wsIdle;
end;

procedure TWolf.IdleRight;
begin
  SetFlipH(True);
  State := wsIdle;
end;

function TWolf.IsOrientedToRight: boolean;
begin
  Result := FlipH;
end;

procedure TWolf.Jump;
begin
  State := wsJumping;
end;

procedure TWolf.SetRunMode;
begin
  TimeMultiplicator := 0.3;
  WalkSpeed := FScene.ScaleDesignToSceneF(1200);
end;

procedure TWolf.SetWalkMode;
begin
  TimeMultiplicator := 0.6;
  WalkSpeed := FScene.ScaleDesignToSceneF(90+(90*(1-TimeMultiplicator)));
end;

procedure TWolf.SetAsCarryingAnObject(aObject: TSimpleSurfaceWithEffect);
begin
  FObjectToCarry := aObject;
  FObjectToCarry.ApplySymmetryWhenFlip := True;
  Abdomen.AddChild(aObject, 2);
  aObject.RightX := Abdomen.Width*0.5;
  aObject.BottomY := Abdomen.Height*0.8;
  State := wsCarryingIdle;
end;

constructor TWolf.Create(aIsForestGame: boolean; aLayerIndex: integer);
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);

  TimeMultiplicator := 1.0;
  WalkSpeed := FScene.ScaleDesignToSceneF(90+(90*(1-TimeMultiplicator)));
  JumpDeltaX := FScene.Width*0.08;
  FCallbackDoOnJumpMove := @ProcessCallbackDoOnJumpMove;

  FIsForestGame := aIsForestGame;

  LeftLeg := CreateChildSprite(texWolfLeftLeg, 0);
  //LeftLeg.SetCoordinate(-LeftLeg.Width*0.45, -LeftLeg.Height*0.25);
  LeftLeg.SetCoordinate(-LeftLeg.Width*0.55, -LeftLeg.Height*0.3);
  LeftLeg.Pivot := PointF(0.8,0);

  RightLeg := CreateChildSprite(texWolfRightLeg, -1);
  //RightLeg.SetCoordinate(-RightLeg.Width*1, -RightLeg.Height*0.25);
  RightLeg.SetCoordinate(-RightLeg.Width*0.9, -RightLeg.Height*0.3);
  RightLeg.Pivot := PointF(0.75,0);

  Abdomen := CreateChildSprite(texWolfAbdomen, 1);
  Abdomen.CenterX := 0;
  Abdomen.BottomY := 0;
  Abdomen.Pivot := PointF(0.5, 1);

    Head := TWolfHead.Create;
    Abdomen.AddChild(Head, 1);
    Head.CenterX := Abdomen.Width*0.5;
    Head.BottomY := Head.Height*0.1;
    Head.Pivot := PointF(0.5, 1);
    Head.ApplySymmetryWhenFlip := True;

// arms are inversed....
    LeftArm := TSprite.Create(texWolfLeftArm, False);
    Abdomen.AddChild(LeftArm, 3);
    LeftArm.X.Value := Abdomen.Width*0.7;
    LeftArm.Y.Value := Abdomen.Height*0.25;
    LeftArm.Pivot := PointF(0,0.2);
    LeftArm.ApplySymmetryWhenFlip := True;

    RightArm := TSprite.Create(texWolfRightArm, False);
    Abdomen.AddChild(RightArm, -1);
    RightArm.RightX := Abdomen.Width*0.35;
    RightArm.Y.Value := Abdomen.Height*0.25;
    RightArm.Pivot := PointF(1.0,0.2);
    RightArm.ApplySymmetryWhenFlip := True;

    LeftLegSeat := TSprite.Create(texWolfRightLeg, False);
    Abdomen.AddChild(LeftLegSeat, 1);
    LeftLegSeat.SetCoordinate(Abdomen.Width*0.1, Abdomen.Height*0.85);
    LeftLegSeat.Pivot := PointF(0.75,0);
    LeftLegSeat.ApplySymmetryWhenFlip := True;
    LeftLegSeat.Visible := False;


  Tail := CreateChildSprite(texWolfTail, -1);
  Tail.SetCoordinate(Tail.Width*0.1, -Tail.Height*0.55);
  Tail.Pivot := PointF(0,0);

  DeltaYToTop := Round(Abdomen.Height + Head.Height); // Head.Height*0.1);
  DeltaYToBottom := Round(LeftLeg.Height*0.75);

  BodyHeight := Round(LeftLeg.Height*0.8+Abdomen.Height*0.8+Head.Height);
  BodyWidth := Head.Width;

  State := wsIdle;
  DialogTextColor := BGRA(255,220,220);
end;

procedure TWolf.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if FIsForestGame then ApplyForestGameBehavior;
end;

procedure TWolf.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // STATE IDLE
    0: begin       // head
      if not (FState in [wsIdle, wsCarryingIdle, wsSeatOnChair]) then exit;
      d := random*2+1;
      Head.Angle.ChangeTo(-random*10, d, idcSinusoid);
      PostMessage(1, d+random*2);
    end;
    1: begin
      if not (FState in [wsIdle, wsCarryingIdle, wsSeatOnChair]) then exit;
      d := random*2+1;
      Head.Angle.ChangeTo(random*10, d, idcSinusoid);
      PostMessage(0, d+random*2);
    end;
    2: begin        // tail
      if not (FState in [wsIdle, wsCarryingIdle, wsSeatOnChair]) then exit;
      d := random*0.5+0.5;
      Tail.Angle.ChangeTo(-3-random*8, d, idcSinusoid);
      PostMessage(3, d);
    end;
    3: begin
      if not (FState in [wsIdle, wsCarryingIdle, wsSeatOnChair]) then exit;
      d := random*0.5+0.5;
      Tail.Angle.ChangeTo(3+random*4, d, idcSinusoid);
      PostMessage(2, d);
    end;

    // STATE PICKING BALLOON
    50: begin   // body bends
      if FState <> wsPickingBalloon then exit;
      Abdomen.Angle.ChangeTo(-15, 0.7, idcSinusoid);
      Head.Angle.ChangeTo(-10, 0.7, idcSinusoid);
      PostMessage(51, 0.7);
    end;
    51: begin    // right arm take
      if FState <> wsPickingBalloon then exit;
      RightArm.Angle.ChangeTo(-20, 0.3);
      PostMessage(52, 0.3);
    end;
    52: begin
      if FState <> wsPickingBalloon then exit;
      CreateBalloon;
      Balloon.Opacity.Value := 0;
      Balloon.Opacity.ChangeTo(255, 1, idcStartSlowEndFast);
      Balloon.Angle.ChangeTo(-90, 0.0001);
      Balloon.Update(0.001);
      Balloon.Angle.ChangeTo(0, 1, idcSinusoid);
      RightArm.Angle.ChangeTo(0, 0.3);
      PostMessage(53, 0.3);
    end;
    53: begin   // body straightens
      if FState <> wsPickingBalloon then exit;
      Abdomen.Angle.ChangeTo(0, 0.7, idcSinusoid);
      Head.Angle.ChangeTo(0, 1, idcSinusoid);
      PostMessage(54, 0.7);
    end;
    54: begin
      if FState <> wsPickingBalloon then exit;
      State := wsInflateBalloon;
    end;

    // STATE BALLOON INFLATE
    100: begin      // tail
      if FState <> wsInflateBalloon then exit;
      Tail.Angle.ChangeTo(5, 0.25, idcSinusoid);
      PostMessage(101, 0.25);
    end;
    101: begin
      if FState <> wsInflateBalloon then exit;
      Tail.Angle.ChangeTo(-5, 0.25, idcSinusoid);
      PostMessage(100, 0.25);
    end;
    102: begin  // left arm
      if FState <> wsInflateBalloon then exit;
      LeftArm.Angle.ChangeTo(-5, 0.3, idcSinusoid);
      PostMessage(103, 0.3);
    end;
    103: begin
      if FState <> wsInflateBalloon then exit;
      LeftArm.Angle.ChangeTo(5, 0.3, idcSinusoid);
      PostMessage(102, 0.3);
    end;

    // STATE FLYING WITH BALLON
    200: begin         // legs
      if FState <> wsFlyingWithBallon then exit;
      RightLeg.Angle.ChangeTo(0, 0.4, idcSinusoid);
      LeftLeg.Angle.ChangeTo(5, 0.4, idcSinusoid);
      PostMessage(201, 0.4);
    end;
    201: begin
      if FState <> wsFlyingWithBallon then exit;
      RightLeg.Angle.ChangeTo(10, 0.4, idcSinusoid);
      LeftLeg.Angle.ChangeTo(-5, 0.4, idcSinusoid);
      PostMessage(200, 0.4);
    end;
    202: begin         // abdomen
      if FState <> wsFlyingWithBallon then exit;
      Abdomen.Angle.ChangeTo(20, 2, idcSinusoid);
      PostMessage(203, 2);
    end;
    203: begin
      if FState <> wsFlyingWithBallon then exit;
      Abdomen.Angle.ChangeTo(10, 2, idcSinusoid);
      PostMessage(202, 2);
    end;
    204: begin         // balloon
      if FState <> wsFlyingWithBallon then exit;
      Balloon.Angle.ChangeTo(-25, 2, idcSinusoid);
      PostMessage(205, 2);
    end;
    205: begin
      if FState <> wsFlyingWithBallon then exit;
      Balloon.Angle.ChangeTo(-5, 2, idcSinusoid);
      PostMessage(204, 2);
    end;
    206: begin        // tail
      if FState <> wsFlyingWithBallon then exit;
      d := random*0.5+0.5;
      Tail.Angle.ChangeTo(-3-random*8, d, idcSinusoid);
      PostMessage(207, d);
    end;
    207: begin
      if FState <> wsFlyingWithBallon then exit;
      d := random*0.5+0.5;
      Tail.Angle.ChangeTo(3+random*4, d, idcSinusoid);
      PostMessage(206, d);
    end;
    208: begin       // head
      if FState <> wsFlyingWithBallon then exit;
      d := random*2+1;
      Head.Angle.ChangeTo(-random*10-10, d, idcSinusoid);
      PostMessage(209, d+random*2);
    end;
    209: begin
      if FState <> wsFlyingWithBallon then exit;
      d := random*2+1;
      Head.Angle.ChangeTo(-random*10, d, idcSinusoid);
      PostMessage(208, d+random*2);
    end;

    // TARGETED BY STORM CLOUD
    230: begin
      if Balloon <> NIL then begin
        Balloon.Explode;
        Balloon := NIL;
      end;
      FOnBalloonExplode();
      State := wsFalling;
    end;

    // STATE FALLING
    250: begin
      if FState <> wsFalling then exit;
      LeftArm.Angle.ChangeTo(30, 0.05, idcSinusoid);
      RightArm.Angle.ChangeTo(-30, 0.05, idcSinusoid);
      PostMessage(251, 0.05);
    end;
    251: begin
      if FState <> wsFalling then exit;
      LeftArm.Angle.ChangeTo(-30, 0.05, idcSinusoid);
      RightArm.Angle.ChangeTo(30, 0.05, idcSinusoid);
      PostMessage(250, 0.05);
    end;

    // SEAT AND STUNNED THEN WAKEUP
    280: begin
      d := 0.4*TimeMultiplicator;
      LeftLegSeat.Angle.ChangeTo(85, d, idcSinusoid);
      LeftLegSeat.Visible := True;
      LeftLeg.Visible := False;
      LeftLeg.Angle.ChangeTo(85, d, idcSinusoid);
      RightLeg.Angle.ChangeTo(90, d, idcSinusoid);
      MoveYToSeatDown(0.4);
      Head.Angle.ChangeTo(15, 0.4, idcSinusoid);
      Head.Frame := 3;
      Head.SetMouthHurt;
      Tail.Angle.ChangeTo(-20, 0.4, idcSinusoid);
      LeftArm.Angle.ChangeTo(50, 0.4, idcSinusoid);
      RightArm.Angle.ChangeTo(-25, 0.4, idcSinusoid);
      PostMessage(281, 0.4);
    end;
    281: begin
      CreateStarStunned;
      PostMessage(282, 6*TimeMultiplicator);
    end;
    282: begin
      KillStarStunned;
      PostMessage(283, 1*TimeMultiplicator);
    end;
    283: begin
      if TargetElevatorEngine.Breaked then State := wsWinner
        else begin
          ForceIdlePosition;
          State := wsWalking;
        end;
    end;

    // STATE WALKING
    300: begin
      if not (FState in [wsWalking, wsCarryingWalking]) then exit;
      d := 0.5*TimeMultiplicator;
      LeftLeg.Angle.ChangeTo(-24, d, idcDrop);      //idcSinusoid   -40   idcExtend    idcDrop
      RightLeg.Angle.ChangeTo(15, d, idcDrop);
      Abdomen.Angle.ChangeTo(-3, d, idcSinusoid);
      Head.Angle.ChangeTo(2, d, idcSinusoid);
      if FState = wsWalking then begin
        LeftArm.Angle.ChangeTo(80, d, idcSinusoid);
        RightArm.Angle.ChangeTo(-45, d, idcSinusoid);
      end;
      PostMessage(301, d);
    end;
    301: begin
      if not (FState in [wsWalking, wsCarryingWalking]) then exit;
      d := 0.5*TimeMultiplicator;
      LeftLeg.Angle.ChangeTo(20, d, idcDrop);
      RightLeg.Angle.ChangeTo(-60, d, idcDrop);  //idcSinusoid   idcExtend
      Abdomen.Angle.ChangeTo(3, d, idcSinusoid);
      Head.Angle.ChangeTo(-2, d, idcSinusoid);
      if FState = wsWalking then begin
        LeftArm.Angle.ChangeTo(40, d, idcSinusoid);
        RightArm.Angle.ChangeTo(-28, d, idcSinusoid);
      end;
      PostMessage(300, d);
    end;

    // STATE DESTROYING ELEVATOR ENGINE (pine forest game)
    400: begin
      if FState <> wsDestroyingElevator then exit;
      RightLeg.Angle.ChangeTo(-20, 0.3, idcSinusoid);
      PostMessage(401, 0.3);
    end;
    401: begin
      if FState <> wsDestroyingElevator then exit;
      if TargetElevatorEngine <> NIL then begin
        if TargetElevatorEngine.Breaked then exit;
        TargetElevatorEngine.HitCount := TargetElevatorEngine.HitCount+1;
      end;
      RightLeg.Angle.ChangeTo(10, 0.3, idcSinusoid);
      PostMessage(400, 0.3);
    end;

    // STATE WINNER
    500: begin
      Head.SetMouthTongue;
      LeftArm.Angle.ChangeTo(-30, 0.5, idcSinusoid);
      RightArm.Angle.ChangeTo(30, 0.5, idcSinusoid);
      PostMessage(501, 0.5+random*0.5);
    end;
    501: begin
      Y.ChangeTo(Y.Value-LeftLeg.Height*0.5, 0.3, idcStartFastEndSlow);
      PostMessage(502, 0.3);
    end;
    502: begin
      Y.ChangeTo(Y.Value+LeftLeg.Height*0.5, 0.3, idcStartSlowEndFast);
      PostMessage(501, 0.3);
    end;

    // STATE LOSER
    600: begin
      Head.SetMouthFalling;
      Head.Frame := 2;
      Head.Angle.ChangeTo(-20, 1, idcSinusoid);
      LeftArm.Angle.ChangeTo(30, 1, idcSinusoid);
      RightArm.Angle.ChangeTo(-30, 1, idcSinusoid);
    end;

    // TAKE AN OBJECT FROM GROUND
    650: begin
      if FState <> wsTakeObjectFromGround then exit;
      d := 1.0*TimeMultiplicator;
      Abdomen.Angle.ChangeTo(-45, d, idcSinusoid);
      PostMessage(651, d);
    end;
    651: begin
      if FState <> wsTakeObjectFromGround then exit;
      d := 0.5*TimeMultiplicator;
      FObjectToCarry.MoveFromSceneToChildOf(Abdomen, 2);
      FObjectToCarry.RightX := Abdomen.Width*0.5;
      FObjectToCarry.BottomY := Abdomen.Height*0.8;
      FObjectToCarry.ApplySymmetryWhenFlip := True;
      if FlipH then FObjectToCarry.FlipH := True;

      PostMessage(652, d);
    end;
    652: begin
      ForceCarryingIdlePosition;
      State := wsCarryingIdle;
    end;

    // PUT AN OBJECT TO GROUND
    700: begin
      if FState <> wsPutObjectToGround then exit;
      d := 1.0*TimeMultiplicator;
      FObjectToCarry.MoveFromChildToScene(LAYER_ARROW);
      FObjectToCarry.Y.ChangeTo(BodyBottomY-FObjectToCarry.Height, d, idcSinusoid);
      FObjectToCarry.X.ChangeTo(X.Value-FObjectToCarry.Width, d, idcSinusoid);
      FObjectToCarry := NIL;
      Abdomen.Angle.ChangeTo(-45, d, idcSinusoid);
      PostMessage(701, d);
    end;
    701: begin
      ForceIdlePosition;
      PostMessage(702, 1);
    end;
    702: begin
      State := wsIdle;
    end;

    // STATE PISSING
    750: begin
      if FState <> wsPissing then exit;
      d := 0.5*TimeMultiplicator;
      LeftArm.Angle.ChangeTo(15, d, idcSinusoid);
      RightArm.Angle.ChangeTo(-15, d, idcSinusoid);
      Head.Angle.ChangeTo(-25, d, idcSinusoid);
      PostMessage(751, d);
    end;
    751: begin
      CreatePiss;
    end;

    // ANIM WOLF FART
    780: begin
      d := 0.75*TimeMultiplicator;
      Tail.Angle.ChangeTo(-90, d, idcSinusoid);
      PostMessage(781, d*1.5);
    end;
    781: begin
      CreateFart;
      PostMessage(782, 2);
    end;
    782: begin
      Tail.Angle.ChangeTo(0, d, idcSinusoid);
      FState := wsPissing;
    end;

  // 800 to 820 used by Penelope ponytail

    // JUMP ANIM
    850: begin
      // start position
      Abdomen.Angle.Value := -20;

      // in air
      d := TimeMultiplicator*0.625; //0.5;
      Abdomen.Angle.ChangeTo(17, d);
      LeftArm.Angle.ChangeTo(0, d);
      RightArm.Angle.ChangeTo(0, d);
      LeftLeg.Angle.ChangeTo(-20, d);
      RightLeg.Angle.ChangeTo(-30, d);
      FCallbackDoOnJumpMove(d, 0);
      PostMessage(851, d);
    end;
    851: begin
      d := TimeMultiplicator*0.625; //0.5;
      Abdomen.Angle.ChangeTo(17, d, idcStartSlowEndFast);
      LeftArm.Angle.ChangeTo(0, d, idcStartSlowEndFast);
      RightArm.Angle.ChangeTo(0, d, idcStartSlowEndFast);
      LeftLeg.Angle.ChangeTo(-20, d, idcStartSlowEndFast);
      RightLeg.Angle.ChangeTo(-30, d, idcStartSlowEndFast);
      FCallbackDoOnJumpMove(d, 1);
      PostMessage(852, d);
    end;
    852: begin
      FIsJumping := False;
      ForceIdlePosition(True);
      FCallbackDoOnJumpMove(0, 2);
      State := wsIdle;
    end;

    // anim seat on chair : arms move slowly
    900: begin
      if State <> wsSeatOnChair then exit;
      RightLeg.Angle.Value := 45;
      LeftLeg.Angle.Value := 30;
      LeftArm.Angle.Value := 120;
      RightArm.Angle.Value := -30;
      PostMessage(905);
      PostMessage(910);
    end;
    905: begin
      if State <> wsSeatOnChair then exit;
      d := random*2+1;
      LeftArm.Angle.ChangeTo(120+Random*30, d, idcSinusoid);
      PostMessage(905, d);
    end;
    910: begin
      if State <> wsSeatOnChair then exit;
      d := random*2+1;
      RightArm.Angle.ChangeTo(-30+Random*30, d, idcSinusoid);
      PostMessage(910, d);
    end;

  end;//case
end;

{ TWolfPenelope }

procedure TWolfPenelope.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FShirt.FlipH := AValue;
  FSkirt.FlipH := AValue;
  FNavelPiercing.FlipH := AValue;
  FNosePiercing.FlipH := AValue;
  FRightShoe.FlipH := AValue;
  FLeftShoe.FlipH := AValue;
  FMouth.FlipH := AValue;
  FLashes.FlipH := AValue;
  FHair.FlipH := AValue;
  FPonyTail.FlipH := AValue;
end;

procedure TWolfPenelope.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FShirt.FlipV := AValue;
  FSkirt.FlipV := AValue;
  FNavelPiercing.FlipV := AValue;
  FNosePiercing.FlipV := AValue;
  FRightShoe.FlipV := AValue;
  FLeftShoe.FlipV := AValue;
  FMouth.FlipV := AValue;
  FLashes.FlipV := AValue;
  FHair.FlipV := AValue;
  FPonyTail.FlipV := AValue;
end;

constructor TWolfPenelope.Create(aIsForestGame: boolean; aLayerIndex: integer);
begin
  inherited Create(aIsForestGame, aLayerIndex);
  DialogAuthorName := 'Penelope';
  Head.DontShowOriginalMouth := True;

  // add shirt
  FShirt := TSprite.Create(texPenelopeShirt, False);
  Abdomen.AddChild(FShirt, 2);
  FShirt.SetCoordinate(Abdomen.Width*0.1, Abdomen.Height*0.4);
  FShirt.ApplySymmetryWhenFlip := True;
  // add skirt
  FSkirt := TSprite.Create(texPenelopeSkirt, False);
  Abdomen.AddChild(FSkirt, 2);
  FSkirt.SetCoordinate(-FSkirt.Width*0.02, Abdomen.Height-FSkirt.Height*0.6);
  FSkirt.ApplySymmetryWhenFlip := True;
  // add navel piercing
  FNavelPiercing := TSprite.Create(texPenelopeNavelPiercing, False);
  Abdomen.AddChild(FNavelPiercing, 2);
  FNavelPiercing.SetCoordinate(Abdomen.Width*0.3, Abdomen.Height*0.75);
  FNavelPiercing.ApplySymmetryWhenFlip := True;
  // add nose piercing
  FNosePiercing := TSprite.Create(texPenelopeNosePiercing, False);
  Head.AddChild(FNosePiercing, 1);
  FNosePiercing.SetCoordinate(Head.Width*0.05, Head.Height-FNosePiercing.Height);
  FNosePiercing.ApplySymmetryWhenFlip := True;
  // add right shoe
  FRightShoe := TSprite.Create(texPenelopeShoe, False);
  RightLeg.AddChild(FRightShoe, 1);
  FRightShoe.SetCoordinate(0, RightLeg.Height-FRightShoe.Height*0.9);
  FRightShoe.ApplySymmetryWhenFlip := True;
  // add left shoe
  FLeftShoe := TSprite.Create(texPenelopeShoe, False);
  LeftLeg.AddChild(FLeftShoe, 1);
  FLeftShoe.SetCoordinate(0, LeftLeg.Height-FLeftShoe.Height*0.9);
  FLeftShoe.ApplySymmetryWhenFlip := True;
  // add mouth
  Head.HideAllMouth;
  FMouth := TSprite.Create(texPenelopeMouth, False);
  Head.AddChild(FMouth, 1);
  FMouth.SetCoordinate(Head.Width*0.5-FMouth.Width*0.5, Head.Height-FMouth.Height*1.15);
  FMouth.ApplySymmetryWhenFlip := True;
  // add lashes
  FLashes := TSprite.Create(texPenelopeLashes, False);
  Head.AddChild(FLashes, 1);
  FLashes.SetCoordinate(Head.Width*0.5-FLashes.Width*0.6, Head.Height*0.5-FLashes.Height*0.6);
  FLashes.ApplySymmetryWhenFlip := True;
  // add hair
  FHair := TSprite.Create(texPenelopeHair, False);
  Head.AddChild(FHair, 1);
  FHair.SetCoordinate(Head.Width*0.25, Head.Height*0.23);
  FHair.ApplySymmetryWhenFlip := True;
  // add ponytail
  FPonyTail := TSprite.Create(texPenelopePonytail, False);
  Head.AddChild(FPonyTail, -5);
  FPonyTail.SetCoordinate(Head.Width*0.7, Head.Height*0.65);
  FPonyTail.Pivot := PointF(0.5, 0);
  FPonyTail.ApplySymmetryWhenFlip := True;
  PostMessage(800); // ponytail swing
end;

procedure TWolfPenelope.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    800: begin
      d := random*2.0+1.0;
      FPonyTail.Angle.ChangeTo(-5, d);
      PostMessage(801, d);
    end;
    801: begin
      d := random*2.0+1.0;
      FPonyTail.Angle.ChangeTo(5, d);
      PostMessage(800, d);
    end;
  end;
end;

{ TWolfMarcus }

procedure TWolfMarcus.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FShirt.FlipH := AValue;
  FShortLeft.FlipH := AValue;
  FShortRight.FlipH := AValue;
  FHat.FlipH := AValue;
end;

procedure TWolfMarcus.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FShirt.FlipV := AValue;
  FShortLeft.FlipV := AValue;
  FShortRight.FlipV := AValue;
  FHat.FlipV := AValue;
end;

constructor TWolfMarcus.Create(aIsForestGame: boolean; aLayerIndex: integer);
begin
  inherited Create(aIsForestGame, aLayerIndex);
  DialogAuthorName := 'Marcus';
  // add shirt
  FShirt := TSprite.Create(texMarcusShirt, False);
  Abdomen.AddChild(FShirt, 2);
  FShirt.SetCoordinate(0, Abdomen.Height*0.25);
  FShirt.ApplySymmetryWhenFlip := True;
  // add short on left leg
  FShortLeft := TSprite.Create(texMarcusShortLeft, False);
  LeftLeg.AddChild(FShortLeft, 1);
  FShortLeft.SetCoordinate(LeftLeg.Width*0.5, 0);
  FShortLeft.ApplySymmetryWhenFlip := True;
  // add short on right leg
  FShortRight := TSprite.Create(texMarcusShortRight, False);
  RightLeg.AddChild(FShortRight, 1);
  FShortRight.SetCoordinate(RightLeg.Width*0.5, 0);
  FShortRight.ApplySymmetryWhenFlip := True;
  // add hat
  FHat := TSprite.Create(texMarcusHat, False);
  Head.AddChild(FHat, 2);
  FHat.SetCoordinate(-FHat.Width*0.1, Head.Height*0.3);
  FHat.ApplySymmetryWhenFlip := True;
end;

procedure TWolfMarcus.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
end;

{ TWolfFather }

procedure TWolfFather.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FHat.FlipH := AValue;
  FGlasses.FlipH := AValue;
  FBeard.FlipH := AValue;
  FBelt.FlipH := AValue;
end;

procedure TWolfFather.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FHat.FlipV := AValue;
  FGlasses.FlipV := AValue;
  FBeard.FlipV := AValue;
  FBelt.FlipV := AValue;
end;

constructor TWolfFather.Create(aIsForestGame: boolean; aLayerIndex: integer);
begin
  inherited Create(aIsForestGame, aLayerIndex);
  DialogAuthorName := sFatherOfWolfs;

  FHat := TSprite.Create(texFatherHat, False);
  Head.AddChild(FHat, 2);
  FHat.SetCoordinate(Head.Width*0.18, Head.Height*25);
  FHat.ApplySymmetryWhenFlip := True;
  FHat.SetChildOf(Abdomen, 1);

  FGlasses := TSprite.Create(texFatherGlasses, False);
  Head.AddChild(FGlasses, 2);
  FGlasses.SetCoordinate(Head.Width*0.18, Head.Height*0.55);
  FGlasses.ApplySymmetryWhenFlip := True;

  FBeard := TSprite.Create(texFatherBeard, False);
  Head.AddChild(FBeard, -1);
  FBeard.SetCoordinate(Head.Width*0.3, Head.Height*0.96);
  FBeard.ApplySymmetryWhenFlip := True;

  FBelt := TSprite.Create(texFatherBelt, False);
  Abdomen.AddChild(FBelt, 0);
  FBelt.SetCoordinate(Abdomen.Width*0, Abdomen.Height*0.6);
  FBelt.ApplySymmetryWhenFlip := True;
end;

{ TWolfMother }

procedure TWolfMother.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FHat.FlipH := AValue;
  FMouth.FlipH := AValue;
  FPonyTail.FlipH := AValue;
  FDress.FlipH := AValue;
  FLeftArmStrap.FlipH := AValue;
  FLeftLegStrap.FlipH := AValue;
  FRightLegStrap.FlipH := AValue;
  FRightShoe.FlipH := AValue;
  FLeftShoe.FlipH := AValue;
end;

procedure TWolfMother.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FHat.FlipV := AValue;
  FMouth.FlipV := AValue;
  FPonyTail.FlipV := AValue;
  FDress.FlipV := AValue;
  FLeftArmStrap.FlipV := AValue;
  FLeftLegStrap.FlipV := AValue;
  FRightLegStrap.FlipV := AValue;
  FRightShoe.FlipV := AValue;
  FLeftShoe.FlipV := AValue;
end;

constructor TWolfMother.Create(aIsForestGame: boolean; aLayerIndex: integer);
begin
  inherited Create(aIsForestGame, aLayerIndex);
  DialogAuthorName := sMotherOfWolfs;

  FHat := TSprite.Create(texMotherHat, False);
  Head.AddChild(FHat, 2);
  FHat.SetCoordinate(ScaleW(0), ScaleH(7));
  FHat.ApplySymmetryWhenFlip := True;

  Head.HideAllMouth;
  FMouth := TSprite.Create(texMotherMouth, False);
  Head.AddChild(FMouth, 2);
  FMouth.SetCoordinate(Head.Width*0.5-FMouth.Width*0.5, Head.Height-FMouth.Height*1.15);
  FMouth.ApplySymmetryWhenFlip := True;

  FPonyTail := TSprite.Create(texMotherPonyTail, False);
  Head.AddChild(FPonyTail, -1);
  FPonyTail.SetCoordinate(Head.Width*0.7, Head.Height*0.65);
  FPonyTail.Pivot := PointF(0.5, 0);
  FPonyTail.ApplySymmetryWhenFlip := True;

  FDress := TSprite.Create(texMotherDress, False);
  Abdomen.AddChild(FDress, 0);
  FDress.SetCoordinate(-Abdomen.Width*0.18, Abdomen.Height*0.24);
  FDress.ApplySymmetryWhenFlip := True;

  FLeftArmStrap := TSprite.Create(texMotherLeftArmStrap, False);
  LeftArm.AddChild(FLeftArmStrap, 0);
  FLeftArmStrap.SetCoordinate(LeftArm.Width*0.48, LeftArm.Height*0.08);
  FLeftArmStrap.ApplySymmetryWhenFlip := True;

  FLeftLegStrap := TSprite.Create(texMotherLeftLegStrap, False);
  LeftLeg.AddChild(FLeftLegStrap, 0);
  FLeftLegStrap.SetCoordinate(LeftLeg.Width*0.62, LeftLeg.Height*0.56);
  FLeftLegStrap.ApplySymmetryWhenFlip := True;

  FRightLegStrap := TSprite.Create(texMotherRightLegStrap, False);
  RightLeg.AddChild(FRightLegStrap, 0);
  FRightLegStrap.SetCoordinate(RightLeg.Width*0.60, RightLeg.Height*0.45);
  FRightLegStrap.ApplySymmetryWhenFlip := True;

  FRightShoe := TSprite.Create(texMotherShoe, False);
  RightLeg.AddChild(FRightShoe, 1);
  FRightShoe.SetCoordinate(0, RightLeg.Height-FRightShoe.Height*0.9);
  FRightShoe.ApplySymmetryWhenFlip := True;

  FLeftShoe := TSprite.Create(texMotherShoe, False);
  LeftLeg.AddChild(FLeftShoe, 1);
  FLeftShoe.SetCoordinate(0, LeftLeg.Height-FLeftShoe.Height*0.9);
  FLeftShoe.ApplySymmetryWhenFlip := True;

end;

{ TWolfRomeo }

procedure TWolfRomeo.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FHat.FlipH := AValue;
end;

procedure TWolfRomeo.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FHat.FlipV := AValue;
end;

constructor TWolfRomeo.Create(aIsForestGame: boolean; aLayerIndex: integer);
begin
  inherited Create(aIsForestGame, aLayerIndex);
  DialogAuthorName := 'Romeo';

  FHat := TSprite.Create(texRomeoHat, False);
  Head.AddChild(FHat, 2);
  FHat.SetCoordinate(Head.Width*0.1, Head.Height*0.24);
  FHat.ApplySymmetryWhenFlip := True;
end;

{ TWolfJulia }

procedure TWolfJulia.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FNewHead.FlipH := AValue;
  FDress.FlipH := AValue;
end;

procedure TWolfJulia.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FNewHead.FlipV := AValue;
  FDress.FlipV := AValue;
end;

constructor TWolfJulia.Create(aIsForestGame: boolean; aLayerIndex: integer);
begin
  inherited Create(aIsForestGame, aLayerIndex);
  DialogAuthorName := 'Julia';

  FNewHead := TSprite.Create(texJuliaHead, False);
  Abdomen.AddChild(FNewHead, 1);
  FNewHead.CenterX := Abdomen.Width*0.5;
  FNewHead.BottomY := FNewHead.Height*0.1;
  FNewHead.Pivot := PointF(0.5, 1);
  FNewHead.ApplySymmetryWhenFlip := True;
  Head.Visible := False;
  Head.Freeze := True;

  FDress := TSprite.Create(texJuliaDress, False);
  Abdomen.AddChild(FDress, 1);
  FDress.SetCoordinate(-0.51*Abdomen.Width, 0.21*Abdomen.Height);
  FDress.ApplySymmetryWhenFlip := True;
end;

end.

