unit u_sprite_wolf;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes,
  u_sprite_lrcommon, u_sprite_gameforest,
  u_audio;

type

{ TBalloon }

TBalloon = class(TSprite)
private
  const BALLOON_SIZE_MULTIPLICATOR = 6;
        BALLOON_INFLATE_TIME = 7;
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
  MouthClose, MouthTongue, MouthHurt, MouthFalling, MouthSurprise: TSprite;
  procedure SetFlipH(AValue: boolean);
  procedure SetFlipV(AValue: boolean);
  constructor Create;
  procedure SetMouthClose;
  procedure SetMouthTongue;
  procedure SetMouthFalling;
  procedure SetMouthHurt;
  procedure SetMouthSurprise;
end;

//

TWolfState = (wsUndefined=0, wsIdle,
              wsPickingBalloon, wsInflateBalloon,
              wsFlying, wsLanding, wsWalking, wsFalling, wsSeatAndStunned,
              wsTargetedByStormCloud,
              wsDestroyingElevator,
              wsWinner, wsLoser,
              wsTakeObjectFromGround, wsCarryingIdle, wsCarryingWalking, wsPutObjectToGround,
              wsPissing, wsFart);

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
  FTimeMultiplicator: single;
  FUsedBalloonCrate: TBalloonCrate;
  FIsForestGame: boolean;
  FObjectToCarry: TSimpleSurfaceWithEffect;
  FPEPiss: TParticleEmitter;
  FsndPiss: TALSSound;
  procedure SetState(AValue: TWolfState);
  procedure ForceIdlePosition;
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
public
  // The reference point is the middle of the top of the legs
  Head: TWolfHead;
  Abdomen, LeftArm, RightArm, LeftLeg, RightLeg, Tail, LeftLegSeat: TSprite;
  Balloon: TBalloon;
  constructor Create(aIsForestGame: boolean);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure SetFlipH(AValue: boolean);
  procedure SetFlipV(AValue: boolean);
  function GetSceneBallonCenterCoor: TPointF;
  property State: TWolfState read FState write SetState;
  property YGroundAtTheTopOfTheScreen: single read FYGroundAtTheTopOfTheScreen write FYGroundAtTheTopOfTheScreen;
  property YGroundAtBottomOfTheScreen: single read FYGroundAtBottomOfTheScreen write FYGroundAtBottomOfTheScreen;
  property TimeMultiplicator: single read FTimeMultiplicator write FTimeMultiplicator;

  property OnCheckIfLost: TFuncCheckIfLost read FOnCheckIfLost write FOnCheckIfLost;
  property OnBalloonExplode: TSimpleCallback read FOnBalloonExplode write FOnBalloonExplode;
  property TargetElevatorEngine: TElevatorEngine read FTargetElevatorEngine write FTargetElevatorEngine;
public // utils to control character during cinematics
  procedure WalkHorizontallyTo(aX: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);

  procedure SetAsCarryingAnObject(aObject: TSimpleSurfaceWithEffect);
  property ObjectToCarry: TSimpleSurfaceWithEffect read FObjectToCarry write FObjectToCarry;
  property Atlas: TOGLCTextureAtlas read FAtlas write FAtlas;
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

  texCastle: PTexture;

  sndBallonPop: TALSSound;

  procedure LoadWolfTextures(aAtlas: TOGLCTextureAtlas);
  procedure LoadBaseBallonTexture(aAtlas: TOGLCTextureAtlas);
  procedure LoadBallonSound;
  procedure FreeBallonSound;

implementation
uses u_common, u_app, BGRAPath, GeometricShapes;

procedure LoadWolfTextures(aAtlas: TOGLCTextureAtlas);
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

  ima := TBGRABitmap.Create(ScaleW(16), ScaleH(20));
  FGeometricShapes := TGeometricShapes.Create;
  FGeometricShapes.GlobalColor := BGRA(255,255,0);
  FGeometricShapes.DrawStar(ima);
  texWolfStarWhenStunned := aAtlas.Add(ima);
  FreeAndNil(FGeometricShapes);
end;

procedure LoadBaseBallonTexture(aAtlas: TOGLCTextureAtlas);
var path: String;
begin
  path := SpriteFolder+'Common'+DirectorySeparator;
  texBaseBalloon := aAtlas.AddFromSVG(path+'BaseBalloon.svg', ScaleW(23), -1);
  texStringBalloon := aAtlas.AddFromSVG(path+'BalloonString.svg', -1, ScaleH(78));
  texPafBalloon := aAtlas.AddFromSVG(path+'Paf.svg', ScaleW(166), -1);
end;

procedure LoadBallonSound;
begin
  sndBallonPop := Audio.AddSound('balloon-pop.ogg');
end;

procedure FreeBallonSound;
begin
  if sndBallonPop <> NIL then sndBallonPop.Kill;
  sndBallonPop := NIL;
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
  if (r.Top <> 0) or (r.Left <> 0) then begin
    FPath.Translate(PointF(-r.Left, -r.Top));
  end;
  FPath.RemoveIdenticalConsecutivePoint;
  FPath.ClosePath;
end;

constructor TBalloon.Create;
var c: TBGRAPixel;
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

  Glow := TOGLCGlow.Create(FScene, Width*BALLOON_SIZE_MULTIPLICATOR*0.5{*1.3}, BGRAWhite);
  AddChild(Glow, 1);
end;

destructor TBalloon.Destroy;
begin
  FreeAndNil(FSize);
  inherited Destroy;
end;

procedure TBalloon.Update(const aElapsedTime: single);
const coeff1 = BALLOON_SIZE_MULTIPLICATOR*0.1;
  coeff2 = 1-coeff1-0.02;
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
 // Glow.Power.Value := 0.6 + 0.38*(FSize.Value/BALLOON_SIZE_MULTIPLICATOR);
  Glow.Power.Value := coeff1 + coeff2*(FSize.Value/BALLOON_SIZE_MULTIPLICATOR);
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
  with Audio.AddSound('balloon_inflate_4.ogg') do
    PlayThenKill(True);
end;

procedure TBalloon.Explode;
begin
  Glow.Visible := False;
  Inflatable.Visible := False;
  Paf.Visible := True;
  if sndBallonPop <> NIL then sndBallonPop.Play(True);
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

procedure TWolfHead.SetFlipH(AValue: boolean);
begin
  FlipH := AValue;
  MouthClose.FlipH := AValue;
  MouthTongue.FlipH := AValue;
  MouthHurt.FlipH := AValue;
end;

procedure TWolfHead.SetFlipV(AValue: boolean);
begin
  FlipV := AValue;
  MouthClose.FlipV := AValue;
  MouthTongue.FlipV := AValue;
  MouthHurt.FlipV := AValue;
end;

constructor TWolfHead.Create;
begin
  inherited Create(texWolfHead, False);
  ApplySymmetryWhenFlip := True;

  MouthClose := TSprite.Create(texWolfMouthClose, False);
  AddChild(MouthClose);
  MouthClose.SetCenterCoordinate(Width*0.6, Height*0.85);
  MouthClose.ApplySymmetryWhenFlip := True;

  MouthTongue := TSprite.Create(texWolfMouthTongue, False);
  AddChild(MouthTongue);
  MouthTongue.SetCenterCoordinate(Width*0.50, Height*0.945);
  MouthTongue.ApplySymmetryWhenFlip := True;

  MouthHurt := TSprite.Create(texWolfMouthHurt, False);
  AddChild(MouthHurt);
  MouthHurt.CenterX := Width*0.55;
  MouthHurt.Y.Value := Height*0.86;
  MouthHurt.ApplySymmetryWhenFlip := True;

  MouthFalling := TSprite.Create(texWolfMouthFalling, False);
  AddChild(MouthFalling);
  MouthFalling.CenterX := Width*0.55;
  MouthFalling.Y.Value := Height*0.86;
  MouthFalling.ApplySymmetryWhenFlip := True;

  MouthSurprise := TSprite.Create(texWolfMouthSurprise, False);
  AddChild(MouthSurprise);
  MouthSurprise.SetCenterCoordinate(Width*0.6, Height*0.85);
  MouthSurprise.ApplySymmetryWhenFlip := True;
end;

procedure TWolfHead.SetMouthClose;
begin
  MouthClose.Visible := True;
  MouthTongue.Visible := False;
  MouthHurt.Visible := False;
  MouthFalling.Visible := False;
  MouthSurprise.Visible := False;
end;

procedure TWolfHead.SetMouthTongue;
begin
  MouthClose.Visible := False;
  MouthTongue.Visible := True;
  MouthHurt.Visible := False;
  MouthFalling.Visible := False;
  MouthSurprise.Visible := False;
end;

procedure TWolfHead.SetMouthFalling;
begin
  MouthClose.Visible := False;
  MouthTongue.Visible := False;
  MouthHurt.Visible := False;
  MouthFalling.Visible := True;
  MouthSurprise.Visible := False;
end;

procedure TWolfHead.SetMouthHurt;
begin
  MouthClose.Visible := False;
  MouthTongue.Visible := False;
  MouthHurt.Visible := True;
  MouthFalling.Visible := False;
  MouthSurprise.Visible := False;
end;

procedure TWolfHead.SetMouthSurprise;
begin
  MouthClose.Visible := False;
  MouthTongue.Visible := False;
  MouthHurt.Visible := False;
  MouthFalling.Visible := False;
  MouthSurprise.Visible := True;
end;

{ TWolf }

procedure TWolf.SetState(AValue: TWolfState);
begin
  if FState = AValue then Exit;

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
    wsFlying: begin
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
      if not FFlipH then Speed.x.ChangeTo(FScene.ScaleDesignToSceneF(-80-(80*(1-FTimeMultiplicator))), FTimeMultiplicator, idcSinusoid)
        else Speed.x.ChangeTo(FScene.ScaleDesignToSceneF(80+(80*(1-FTimeMultiplicator))), FTimeMultiplicator, idcSinusoid);
      PostMessage(300);
    end;

    wsSeatAndStunned: begin
      PostMessage(280);
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
  end;
end;

procedure TWolf.ForceIdlePosition;
begin
  Speed.Value := PointF(0,0);
  Head.SetMouthClose;
  Head.Angle.ChangeTo(0, 1, idcSinusoid);
  Head.Frame := 1;
  Abdomen.Angle.ChangeTo(0, 1, idcSinusoid);
  LeftArm.Angle.ChangeTo(60, 1, idcSinusoid);
  RightArm.Angle.ChangeTo(-28, 1, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, 1, idcSinusoid);
  RightLeg.Angle.ChangeTo(0, 1, idcSinusoid);
  Tail.Angle.ChangeTo(0, 1, idcSinusoid);
  LeftLegSeat.Angle.ChangeTo(0, 1, idcSinusoid);
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
  Y.ChangeTo(Y.Value+DeltaYToBottom, aDuration*FTimeMultiplicator, idcStartFastEndSlow);
end;

procedure TWolf.MoveYToStandUp(aDuration: single);
begin
  Y.ChangeTo(Y.Value-DeltaYToBottom, aDuration*FTimeMultiplicator, idcStartFastEndSlow);
end;

procedure TWolf.CreateBalloon;
begin
  Balloon := TBalloon.Create;
  Abdomen.AddChild(Balloon, 0);
  Balloon.Pivot := PointF(0.5, 1);
  Balloon.CenterX := RightArm.X.Value+RightArm.Width*0.25;
  Balloon.BottomY := RightArm.Y.Value+RightArm.Height*0.7;
  Balloon.TimeMultiplicator := FTimeMultiplicator;
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
  EllipseStarStunned.Opacity.ChangeTo(0, 1.0*FTimeMultiplicator);
  EllipseStarStunned.KillDefered(1.0*FTimeMultiplicator);
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
  FsndPiss.Volume.Value := 0.7;
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

procedure TWolf.SetFlipH(AValue: boolean);
begin
  if FObjectToCarry <> NIL then FObjectToCarry.FlipH := AVAlue;
  FlipH := AValue;
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
  FlipV := AValue;
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

procedure TWolf.WalkHorizontallyTo(aX: single; aTargetScreen: TScreenTemplate;
  aMessageValueWhenFinish: TUserMessageValue; aDelay: single);
begin
  if X.Value < aX then begin
    SetFlipH(True);
    if FObjectToCarry = NIL then State := wsWalking
      else State := wsCarryingWalking;
    CheckHorizontalMoveToX(aX, aTargetScreen, aMessageValueWhenFinish, aDelay);
  end else if X.Value > aX then begin
    SetFlipH(False);
    if FObjectToCarry = NIL then State := wsWalking
      else State := wsCarryingWalking;
    CheckHorizontalMoveToX(aX, aTargetScreen, aMessageValueWhenFinish, aDelay);
  end else aTargetScreen.PostMessage(aMessageValueWhenFinish, aDelay);
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

constructor TWolf.Create(aIsForestGame: boolean);
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_WOLF);
  FTimeMultiplicator := 1.0;
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
    RightArm.Pivot := PointF(1,0.2);
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
var o: TSimpleSurfaceWithEffect;
  xx: single;
begin
  inherited Update(aElapsedTime);
  if not FIsForestGame then exit;

  if (State = wsFlying) then begin
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
        Abdomen.RemoveChild(Balloon);
        FScene.Add(Balloon, LAYER_FXANIM);
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
      State := wsFlying;
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
    end else if FState = wsFlying then begin
      Balloon.Explode;
      Balloon := NIL;
      State := wsFalling;
    end;
  end;
end;

procedure TWolf.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // STATE IDLE
    0: begin       // head
      if not (FState in [wsIdle, wsCarryingIdle]) then exit;
      d := random*2+1;
      Head.Angle.ChangeTo(-random*10, d, idcSinusoid);
      PostMessage(1, d+random*2);
    end;
    1: begin
      if not (FState in [wsIdle, wsCarryingIdle]) then exit;
      d := random*2+1;
      Head.Angle.ChangeTo(random*10, d, idcSinusoid);
      PostMessage(0, d+random*2);
    end;
    2: begin        // tail
      if not (FState in [wsIdle, wsCarryingIdle]) then exit;
      d := random*0.5+0.5;
      Tail.Angle.ChangeTo(-3-random*8, d, idcSinusoid);
      PostMessage(3, d);
    end;
    3: begin
      if not (FState in [wsIdle, wsCarryingIdle]) then exit;
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

    // STATE FLYING
    200: begin         // legs
      if FState <> wsFlying then exit;
      RightLeg.Angle.ChangeTo(0, 0.4, idcSinusoid);
      LeftLeg.Angle.ChangeTo(5, 0.4, idcSinusoid);
      PostMessage(201, 0.4);
    end;
    201: begin
      if FState <> wsFlying then exit;
      RightLeg.Angle.ChangeTo(10, 0.4, idcSinusoid);
      LeftLeg.Angle.ChangeTo(-5, 0.4, idcSinusoid);
      PostMessage(200, 0.4);
    end;
    202: begin         // abdomen
      if FState <> wsFlying then exit;
      Abdomen.Angle.ChangeTo(20, 2, idcSinusoid);
      PostMessage(203, 2);
    end;
    203: begin
      if FState <> wsFlying then exit;
      Abdomen.Angle.ChangeTo(10, 2, idcSinusoid);
      PostMessage(202, 2);
    end;
    204: begin         // balloon
      if FState <> wsFlying then exit;
      Balloon.Angle.ChangeTo(-25, 2, idcSinusoid);
      PostMessage(205, 2);
    end;
    205: begin
      if FState <> wsFlying then exit;
      Balloon.Angle.ChangeTo(-5, 2, idcSinusoid);
      PostMessage(204, 2);
    end;
    206: begin        // tail
      if FState <> wsFlying then exit;
      d := random*0.5+0.5;
      Tail.Angle.ChangeTo(-3-random*8, d, idcSinusoid);
      PostMessage(207, d);
    end;
    207: begin
      if FState <> wsFlying then exit;
      d := random*0.5+0.5;
      Tail.Angle.ChangeTo(3+random*4, d, idcSinusoid);
      PostMessage(206, d);
    end;
    208: begin       // head
      if FState <> wsFlying then exit;
      d := random*2+1;
      Head.Angle.ChangeTo(-random*10-10, d, idcSinusoid);
      PostMessage(209, d+random*2);
    end;
    209: begin
      if FState <> wsFlying then exit;
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
      d := 0.4*FTimeMultiplicator;
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
      PostMessage(282, 6*FTimeMultiplicator);
    end;
    282: begin
      KillStarStunned;
      PostMessage(283, 1*FTimeMultiplicator);
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
      d := 0.5*FTimeMultiplicator;
      LeftLeg.Angle.ChangeTo(-40, d, idcExtend);      //idcSinusoid
      RightLeg.Angle.ChangeTo(15, d, idcExtend);
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
      d := 0.5*FTimeMultiplicator;
      LeftLeg.Angle.ChangeTo(20, d, idcExtend);
      RightLeg.Angle.ChangeTo(-60, d, idcExtend);  //idcSinusoid
      Abdomen.Angle.ChangeTo(3, d, idcSinusoid);
      Head.Angle.ChangeTo(-2, d, idcSinusoid);
      if FState = wsWalking then begin
        LeftArm.Angle.ChangeTo(40, d, idcSinusoid);
        RightArm.Angle.ChangeTo(-28, d, idcSinusoid);
      end;
      PostMessage(300, d);
    end;

    // STATE DESTROYING ELEVATOR ENGINE
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
      d := 1.0*FTimeMultiplicator;
      Abdomen.Angle.ChangeTo(-45, d, idcSinusoid);
      PostMessage(651, d);
    end;
    651: begin
      if FState <> wsTakeObjectFromGround then exit;
      d := 0.5*FTimeMultiplicator;
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
      d := 1.0*FTimeMultiplicator;
      FObjectToCarry.MoveFromChildToScene(LAYER_ARROW);
      FObjectToCarry.Y.ChangeTo(GetYBottom-FObjectToCarry.Height, d, idcSinusoid);
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
      d := 0.5*FTimeMultiplicator;
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
      d := 0.75*FTimeMultiplicator;
      Tail.Angle.ChangeTo(-90, d, idcSinusoid);
      PostMessage(781, d*2);
    end;
    781: begin
      CreateFart;
      PostMessage(782, 2);
    end;
    782: begin
      Tail.Angle.ChangeTo(0, d, idcSinusoid);
      FState := wsPissing;
    end;
  end;
end;

end.

