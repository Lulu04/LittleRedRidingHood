unit u_robotw7;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, u_sprite_lrcommon, BGRABitmap, BGRABitmapTypes;

const
  W7_BASE_TIME_MOVE = 0.4;

type

{ TRobotW7Back }

TRobotW7Back = class(TWalkingCharacter)
private
  class var FAdditionalScale: single;
  class var texW7bAbdomen, texW7bHead, texW7bShoe: PTexture;
private type TW7BackViewState = (w7bvsIdle, w7bvsWalking);
private
  W7bAbdomen: TSprite;
  W7bHead: TSprite;
  ArmLeft1: TSprite;
  ArmRight1: TSprite;
  ArmLeft2: TSprite;
  ArmRight2: TSprite;
  HandLeft: TSprite;
  HandRight: TSprite;
  LegLeft1: TSprite;
  LegRight1: TSprite;
  LegLeft2: TSprite;
  LegRight2: TSprite;
  ShoeLeft: TSprite;
  ShoeRight: TSprite;
  FState: TW7BackViewState;
  procedure SetState(AValue: TW7BackViewState);
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  // aAdditionalScale is used to scale the collision bodies
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single=1.0);
  constructor Create(aLayerIndex: integer=-1);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
public
  procedure Posture_Idle(aDuration: single=0.5);
  procedure Posture_Walk1(aDuration: single=0.5);
  procedure Posture_Walk2(aDuration: single=0.5);

  property State: TW7BackViewState read FState write SetState;
end;

{ TRobotW7FrontView }

TRobotW7FrontView = class(TWalkingCharacter)
private
  class var FAdditionalScale: single;
  class var texW7fAbdomen, texW7fHead, texW7fShoe: PTexture;
private type TW7FrontViewState = (w7fvsIdle, w7fvsWalking);
private
  Abdomen: TSprite;
  Head: TSprite;
  LegLeft1: TSprite;
  LegRight1: TSprite;
  LegLeft2: TSprite;
  LegRight2: TSprite;
  ShoeLeft: TSprite;
  ShoeRight: TSprite;
  ArmRight1: TSprite;
  ArmRight2: TSprite;
  HandRight: TSprite;
  ArmLeft1: TSprite;
  ArmLeft2: TSprite;
  HandLeft: TSprite;
  FState: TW7FrontViewState;
  procedure SetState(AValue: TW7FrontViewState);
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  // aAdditionalScale is used to scale the collision bodies
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single=1.0);
  constructor Create(aLayerIndex: integer=-1);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
public
  procedure Posture_Idle(aDuration: single=0.5);
  procedure Posture_Walk1(aDuration: single=0.5);
  procedure Posture_Walk2(aDuration: single=0.5);
  procedure Posture_OnWall(aDuration: single=0.5);
public
  property State: TW7FrontViewState read FState write SetState;
end;

{ TRobotW7Right }

TRobotW7Right = class(TWalkingCharacter)
private
  class var FAdditionalScale: single;
  class var texW7rAbdomen, texW7rHead, texW7rLeg1, texW7rShoe,
  texW7rLegLeft1: PTexture;
private type TW7RightViewState = (w7rvsIdle, w7rvsWalking);
private
  W7rAbdomen: TSprite;
  W7rHead: TSprite;
  LegRight1: TSprite;
  LegRight2: TSprite;
  ShoeRight: TSprite;
  LegLeft1: TSprite;
  LegLeft2: TSprite;
  ShoeLeft: TSprite;
  ArmRight1: TSprite;
  ArmRight2: TSprite;
  W7Hand: TSprite;
  ArmLeft1: TSprite;
  ArmLeft2: TSprite;
  HandLeft: TSprite;
  FState: TW7RightViewState;
  FWalkingStep: integer;
  procedure SetState(AValue: TW7RightViewState);
  function GetWalkingDeltaPixelPerStep: integer;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  // aAdditionalScale is used to scale the collision bodies
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single=1.0);
  constructor Create(aLayerIndex: integer=-1);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
public
  procedure Posture_Idle(aDuration: single=0.5);
  procedure Posture_Walk1(aDuration: single=0.5);
  procedure Posture_Walk2(aDuration: single=0.5);
  procedure Posture_Walk3(aDuration: single=0.5);
  procedure Posture_Walk4(aDuration: single=0.5);
  procedure WalkHorizontallyTo(aX: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);

  property State: TW7RightViewState read FState write SetState;
end;

TRobotW74State = (w74sUndefined=0,
               w74sRightIdle, w74sLeftIdle, w74sUpIdle, w74sDownIdle,
               w74sRightWalking, w74sLeftWalking, w74sUpWalking, w74sDownWalking);

{ TRobotW74Direction }

TRobotW74Direction = class(TCharacterWithDialogPanel)
private
  FState: TRobotW74State;
  FW7Front: TRobotW7FrontView;
  FW7Right: TRobotW7Right;
  FW7Back: TRobotW7Back;
  procedure SetState(AValue: TRobotW74State);
protected
  procedure SetTimeMultiplicator(AValue: single); override;
  procedure SetWalkSpeed(AValue: single); override;
  public
  constructor Create(aLayerIndex: integer);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
public // utils for move
  function IsIdle: boolean;
  function IsOrientedRight: boolean;
  function IsOrientedLeft: boolean;
  function IsOrientedBack: boolean;
  function IsOrientedFront: boolean;
public // utils to control character during cinematics
  procedure IdleLeft;
  procedure IdleRight;
  procedure IdleUp;
  procedure IdleDown;
  procedure WalkHorizontallyTo(aX: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
  // aY is relative to the feets of LR
  procedure WalkVerticallyTo(aY: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
public
  property State: TRobotW74State read FState write SetState;
public // direct access to child instances
  property W7Right: TRobotW7Right read FW7Right;
  property W7Front: TRobotW7FrontView read FW7Front;
  property W7Back: TRobotW7Back read FW7Back;
end;

var
  texW7ArmHalf, texW7Hand,
  texW7LegLeft1, texW7LegRight1, texW7Leg2
  :PTexture;

procedure LoadRobotW7Textures(aAtlas: TAtlas);

implementation
uses u_common, u_app;

procedure LoadRobotW7Textures(aAtlas: TAtlas);
var path: string;
begin
  path := FolderSpriteRobotW7;
  texW7ArmHalf := aAtlas.AddFromSVG(path+'W7ArmHalf.svg', -1, ScaleH(25));
  texW7Hand := aAtlas.AddFromSVG(path+'W7Hand.svg', ScaleW(10), -1);
  texW7LegLeft1 := aAtlas.AddFromSVG(path+'W7LegLeft1.svg', -1, ScaleH(39));
  texW7LegRight1 := aAtlas.AddFromSVG(path+'W7LegRight1.svg', -1, ScaleH(39));
  texW7Leg2 := aAtlas.AddFromSVG(path+'W7Leg2.svg', -1, ScaleH(24));
  TRobotW7Back.LoadTexture(aAtlas);
  TRobotW7FrontView.LoadTexture(aAtlas);
  TRobotW7Right.LoadTexture(aAtlas);
end;

{ TRobotW7Right }

class procedure TRobotW7Right.LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single);
var path: string;
begin
  FAdditionalScale := aAdditionalScale;
  path := FolderSpriteRobotW7;
  texW7rAbdomen := aAtlas.AddFromSVG(path+'W7rAbdomen.svg', -1, ScaleH(50));
  texW7rHead := aAtlas.AddFromSVG(path+'W7rHead.svg', -1, ScaleH(43));
  texW7rLeg1 := aAtlas.AddFromSVG(path+'W7rLeg1.svg', -1, ScaleH(39));
  texW7rShoe := aAtlas.AddFromSVG(path+'W7rShoe.svg', ScaleW(24), -1);
  texW7rLegLeft1 := aAtlas.AddFromSVG(path+'W7rLegLeft1.svg', -1, ScaleH(39));
end;

procedure TRobotW7Right.SetState(AValue: TW7RightViewState);
begin
  if FState = AValue then Exit;
  FState := AValue;

  case FState of
    w7rvsIdle: begin
      Posture_Idle(0.5);
    end;
    w7rvsWalking: begin
      ClearMessageList;
      PostMessage(100);
    end;
  end;
end;

function TRobotW7Right.GetWalkingDeltaPixelPerStep: integer;
begin
  Result := Round(FScene.Width*0.03);
  if FlipH then Result := -Result;
end;

procedure TRobotW7Right.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  W7rAbdomen.FlipH := AValue;
  W7rHead.FlipH := AValue;
  LegRight1.FlipH := AValue;
  LegRight2.FlipH := AValue;
  ShoeRight.FlipH := AValue;
  LegLeft1.FlipH := AValue;
  LegLeft2.FlipH := AValue;
  ShoeLeft.FlipH := AValue;
  ArmRight1.FlipH := AValue;
  ArmRight2.FlipH := AValue;
  W7Hand.FlipH := AValue;
  ArmLeft1.FlipH := AValue;
  ArmLeft2.FlipH := AValue;
  HandLeft.FlipH := AValue;
end;

procedure TRobotW7Right.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  W7rAbdomen.FlipV := AValue;
  W7rHead.FlipV := AValue;
  LegRight1.FlipV := AValue;
  LegRight2.FlipV := AValue;
  ShoeRight.FlipV := AValue;
  LegLeft1.FlipV := AValue;
  LegLeft2.FlipV := AValue;
  ShoeLeft.FlipV := AValue;
  ArmRight1.FlipV := AValue;
  ArmRight2.FlipV := AValue;
  W7Hand.FlipV := AValue;
  ArmLeft1.FlipV := AValue;
  ArmLeft2.FlipV := AValue;
  HandLeft.FlipV := AValue;
end;

constructor TRobotW7Right.Create(aLayerIndex: integer);
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);
  WalkDontUseSpeed := True;

  W7rAbdomen := TSprite.Create(texW7rAbdomen, False);
  with W7rAbdomen do begin
    SetChildOf(Self, 0);
    SetCoordinate(-0.502*W7rAbdomen.Width, -0.994*W7rAbdomen.Height);
    Pivot := PointF(0.50, 1.00);
    ApplySymmetryWhenFlip := True;
  end;

  W7rHead := TSprite.Create(texW7rHead, False);
  with W7rHead do begin
    SetChildOf(W7rAbdomen, 0);
    SetCoordinate(0.134*W7rAbdomen.Width, -0.848*W7rAbdomen.Height);
    Pivot := PointF(0.35, 0.99);
    ApplySymmetryWhenFlip := True;
  end;

  LegRight1 := TSprite.Create(texW7rLeg1, False);
  with LegRight1 do begin
    SetChildOf(Self, -1);
    SetCoordinate(-0.501*LegRight1.Width, -0.179*LegRight1.Height);
    Pivot := PointF(0.50, 0.08);
    Angle.Value := 29.00;
    ApplySymmetryWhenFlip := True;
  end;

  LegRight2 := TSprite.Create(texW7Leg2, False);
  with LegRight2 do begin
    SetChildOf(LegRight1, 0);
    SetCoordinate(-0.032*LegRight1.Width, 0.851*LegRight1.Height);
    Pivot := PointF(0.50, 0.13);
    ApplySymmetryWhenFlip := True;
  end;

  ShoeRight := TSprite.Create(texW7rShoe, False);
  with ShoeRight do begin
    SetChildOf(LegRight2, 0);
    SetCoordinate(-0.300*LegRight2.Width, 0.890*LegRight2.Height);
    Pivot := PointF(0.32, 0.05);
    ApplySymmetryWhenFlip := True;
  end;

  LegLeft1 := TSprite.Create(texW7rLegLeft1, False);
  with LegLeft1 do begin
    SetChildOf(Self, 0);
    SetCoordinate(-0.501*LegLeft1.Width, -0.179*LegLeft1.Height);
    Pivot := PointF(0.50, 0.09);
    ApplySymmetryWhenFlip := True;
  end;

  LegLeft2 := TSprite.Create(texW7Leg2, False);
  with LegLeft2 do begin
    SetChildOf(LegLeft1, 0);
    SetCoordinate(-0.021*LegLeft1.Width, 0.851*LegLeft1.Height);
    Pivot := PointF(0.50, 0.11);
    ApplySymmetryWhenFlip := True;
  end;

  ShoeLeft := TSprite.Create(texW7rShoe, False);
  with ShoeLeft do begin
    SetChildOf(LegLeft2, 0);
    SetCoordinate(-0.300*LegLeft2.Width, 0.890*LegLeft2.Height);
    Pivot := PointF(0.34, 0.05);
    ApplySymmetryWhenFlip := True;
  end;

  ArmRight1 := TSprite.Create(texW7ArmHalf, False);
  with ArmRight1 do begin
    SetChildOf(W7rAbdomen, 2);
    SetCoordinate(0.349*W7rAbdomen.Width, 0.133*W7rAbdomen.Height);
    Pivot := PointF(0.50, 0.10);
    Angle.Value := 38.31;
    ApplySymmetryWhenFlip := True;
  end;

  ArmRight2 := TSprite.Create(texW7ArmHalf, False);
  with ArmRight2 do begin
    SetChildOf(ArmRight1, 0);
    SetCoordinate(0, 0.801*ArmRight1.Height);
    Pivot := PointF(0.50, 0.10);
    ApplySymmetryWhenFlip := True;
  end;

  W7Hand := TSprite.Create(texW7Hand, False);
  with W7Hand do begin
    SetChildOf(ArmRight2, 0);
    SetCoordinate(-0.204*ArmRight2.Width, 0.843*ArmRight2.Height);
    Pivot := PointF(0.50, 0.26);
    ApplySymmetryWhenFlip := True;
  end;

  ArmLeft1 := TSprite.Create(texW7ArmHalf, False);
  with ArmLeft1 do begin
    SetChildOf(W7rAbdomen, -6);
    SetCoordinate(0.349*W7rAbdomen.Width, 0.133*W7rAbdomen.Height);
    Pivot := PointF(0.50, 0.09);
    Angle.Value := -35.02;
    ApplySymmetryWhenFlip := True;
  end;

  ArmLeft2 := TSprite.Create(texW7ArmHalf, False);
  with ArmLeft2 do begin
    SetChildOf(ArmLeft1, 0);
    SetCoordinate(0, 0.767*ArmLeft1.Height);
    Pivot := PointF(0.50, 0.10);
    ApplySymmetryWhenFlip := True;
  end;

  HandLeft := TSprite.Create(texW7Hand, False);
  with HandLeft do begin
    SetChildOf(ArmLeft2, 0);
    SetCoordinate(-0.169*ArmLeft2.Width, 0.809*ArmLeft2.Height);
    Pivot := PointF(0.50, 0.28);
    ApplySymmetryWhenFlip := True;
  end;

  DeltaYToTop := Round(W7rAbdomen.Height + W7rHead.Height*0.75);
  DeltaYToBottom := LegRight1.Y.Value + LegRight2.Y.Value + ShoeRight.Y.Value + ShoeRight.Height;
  BodyWidth := W7rAbdomen.Width;
  BodyHeight := Trunc(DeltaYToBottom + DeltaYToTop);
end;

procedure TRobotW7Right.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  // check the end of a walk
  if State = w7rvsWalking then
    if ((MovingDirection = mdLeft) and (ParentSurface.X.Value <= WalkingTargetPoint.x)) or
       ((MovingDirection = mdRight) and (ParentSurface.X.Value >= WalkingTargetPoint.x)) then begin
      ParentSurface.X.Value := WalkingTargetPoint.x;
      State := w7rvsIdle;
      //if FlipH then State := gsIdleLeft else State := gsIdleRight;
      EndOfWalk_SendMessageToScreen;
    end;
end;

procedure TRobotW7Right.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // walking anim
    100: begin
      if State <> w7rvsWalking then exit;
      d := 0.25;
      case FWalkingStep of
        0: Posture_Walk1(d);
        1: Posture_Walk2(d);
        2: Posture_Walk3(d);
        3: Posture_Walk4(d);
      end;
      if FWalkingStep in [0, 2] then
       ParentSurface.X.ChangeTo(ParentSurface.X.Value+GetWalkingDeltaPixelPerStep*0.6, d)
      else ParentSurface.X.ChangeTo(ParentSurface.X.Value+GetWalkingDeltaPixelPerStep, d);
      inc(FWalkingStep);
      if FWalkingStep = 4 then FWalkingStep := 0;
      PostMessage(100, d);
    end;


{
    // WALKING
    100: begin
      if FState <> w7rvsWalking then exit;
      d := W7_BASE_TIME_MOVE*TimeMultiplicator;
      Posture_Walk1(d);
      PostMessage(105);
    end;
    105: begin
      if FState <> w7rvsWalking then exit;
      d := W7_BASE_TIME_MOVE*TimeMultiplicator;
      Posture_Walk2(d);
      PostMessage(110, d);
    end;
    110: begin
      if FState <> w7rvsWalking then exit;
      d := W7_BASE_TIME_MOVE*TimeMultiplicator;
      Posture_Walk3(d);
      PostMessage(115, d);
    end;
    115: begin
      if FState <> w7rvsWalking then exit;
      d := W7_BASE_TIME_MOVE*TimeMultiplicator;
      Posture_Walk4(d);
      PostMessage(100, d);
    end;   }
  end;//case
end;

procedure TRobotW7Right.Posture_Idle(aDuration: single);
begin
  W7rAbdomen.MoveTo(-0.502*W7rAbdomen.Width, -0.994*W7rAbdomen.Height, aDuration, idcSinusoid);
  W7rAbdomen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  W7rAbdomen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  W7rHead.MoveTo(0.134*W7rAbdomen.Width, -0.848*W7rAbdomen.Height, aDuration, idcSinusoid);
  W7rHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  W7rHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight1.MoveTo(-0.501*LegRight1.Width, -0.179*LegRight1.Height, aDuration, idcSinusoid);
  LegRight1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight2.MoveTo(-0.032*LegRight1.Width, 0.851*LegRight1.Height, aDuration, idcSinusoid);
  LegRight2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeRight.MoveTo(-0.300*LegRight2.Width, 0.890*LegRight2.Height, aDuration, idcSinusoid);
  ShoeRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft1.MoveTo(-0.501*LegLeft1.Width, -0.179*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft2.MoveTo(-0.021*LegLeft1.Width, 0.851*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeLeft.MoveTo(-0.300*LegLeft2.Width, 0.890*LegLeft2.Height, aDuration, idcSinusoid);
  ShoeLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight1.MoveTo(0.349*W7rAbdomen.Width, 0.133*W7rAbdomen.Height, aDuration, idcSinusoid);
  ArmRight1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ArmRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight2.MoveTo(0, 0.801*ArmRight1.Height, aDuration, idcSinusoid);
  ArmRight2.Angle.ChangeTo(-17.422, aDuration, idcSinusoid);
  ArmRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  W7Hand.MoveTo(-0.204*ArmRight2.Width, 0.843*ArmRight2.Height, aDuration, idcSinusoid);
  W7Hand.Angle.ChangeTo(0, aDuration, idcSinusoid);
  W7Hand.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft1.MoveTo(0.349*W7rAbdomen.Width, 0.133*W7rAbdomen.Height, aDuration, idcSinusoid);
  ArmLeft1.Angle.ChangeTo(-20.000, aDuration, idcSinusoid);
  ArmLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft2.MoveTo(0, 0.767*ArmLeft1.Height, aDuration, idcSinusoid);
  ArmLeft2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ArmLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandLeft.MoveTo(-0.169*ArmLeft2.Width, 0.809*ArmLeft2.Height, aDuration, idcSinusoid);
  HandLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TRobotW7Right.Posture_Walk1(aDuration: single);
begin
  W7rAbdomen.MoveTo(-0.502*W7rAbdomen.Width, -0.994*W7rAbdomen.Height, aDuration, idcSinusoid);
  W7rAbdomen.Angle.ChangeTo(3.397, aDuration, idcSinusoid);
  W7rAbdomen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  W7rHead.MoveTo(0.134*W7rAbdomen.Width, -0.848*W7rAbdomen.Height, aDuration, idcSinusoid);
  W7rHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  W7rHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight1.MoveTo(-0.421*LegRight1.Width, -0.285*LegRight1.Height, aDuration, idcSinusoid);
  LegRight1.Angle.ChangeTo(10.339, aDuration, idcSinusoid);
  LegRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight2.MoveTo(-0.032*LegRight1.Width, 0.851*LegRight1.Height, aDuration, idcSinusoid);
  LegRight2.Angle.ChangeTo(21.008, aDuration, idcSinusoid);
  LegRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeRight.MoveTo(-0.300*LegRight2.Width, 0.890*LegRight2.Height, aDuration, idcSinusoid);
  ShoeRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft1.MoveTo(-0.501*LegLeft1.Width, -0.179*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft1.Angle.ChangeTo(-39.289, aDuration, idcSinusoid);
  LegLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft2.MoveTo(-0.021*LegLeft1.Width, 0.851*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft2.Angle.ChangeTo(37.860, aDuration, idcSinusoid);
  LegLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeLeft.MoveTo(-0.300*LegLeft2.Width, 0.890*LegLeft2.Height, aDuration, idcSinusoid);
  ShoeLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight1.MoveTo(0.349*W7rAbdomen.Width, 0.133*W7rAbdomen.Height, aDuration, idcSinusoid);
  ArmRight1.Angle.ChangeTo(22.428, aDuration, idcSinusoid);
  ArmRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight2.MoveTo(0, 0.801*ArmRight1.Height, aDuration, idcSinusoid);
  ArmRight2.Angle.ChangeTo(-19.117, aDuration, idcSinusoid);
  ArmRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  W7Hand.MoveTo(-0.204*ArmRight2.Width, 0.843*ArmRight2.Height, aDuration, idcSinusoid);
  W7Hand.Angle.ChangeTo(0, aDuration, idcSinusoid);
  W7Hand.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft1.MoveTo(0.349*W7rAbdomen.Width, 0.133*W7rAbdomen.Height, aDuration, idcSinusoid);
  ArmLeft1.Angle.ChangeTo(-20.000, aDuration, idcSinusoid);
  ArmLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft2.MoveTo(0, 0.767*ArmLeft1.Height, aDuration, idcSinusoid);
  ArmLeft2.Angle.ChangeTo(-19.589, aDuration, idcSinusoid);
  ArmLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandLeft.MoveTo(-0.169*ArmLeft2.Width, 0.809*ArmLeft2.Height, aDuration, idcSinusoid);
  HandLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TRobotW7Right.Posture_Walk2(aDuration: single);
begin
  W7rAbdomen.MoveTo(-0.502*W7rAbdomen.Width, -0.994*W7rAbdomen.Height, aDuration, idcSinusoid);
  W7rAbdomen.Angle.ChangeTo(1.184, aDuration, idcSinusoid);
  W7rAbdomen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  W7rHead.MoveTo(0.134*W7rAbdomen.Width, -0.848*W7rAbdomen.Height, aDuration, idcSinusoid);
  W7rHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  W7rHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight1.MoveTo(-0.421*LegRight1.Width, -0.285*LegRight1.Height, aDuration, idcSinusoid);
  LegRight1.Angle.ChangeTo(23.498, aDuration, idcSinusoid);
  LegRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight2.MoveTo(-0.032*LegRight1.Width, 0.851*LegRight1.Height, aDuration, idcSinusoid);
  LegRight2.Angle.ChangeTo(37.192, aDuration, idcSinusoid);
  LegRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeRight.MoveTo(-0.300*LegRight2.Width, 0.890*LegRight2.Height, aDuration, idcSinusoid);
  ShoeRight.Angle.ChangeTo(18.818, aDuration, idcSinusoid);
  ShoeRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft1.MoveTo(-0.501*LegLeft1.Width, -0.179*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft1.Angle.ChangeTo(-11.833, aDuration, idcSinusoid);
  LegLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft2.MoveTo(-0.021*LegLeft1.Width, 0.851*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft2.Angle.ChangeTo(13.853, aDuration, idcSinusoid);
  LegLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeLeft.MoveTo(-0.300*LegLeft2.Width, 0.890*LegLeft2.Height, aDuration, idcSinusoid);
  ShoeLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight1.MoveTo(0.349*W7rAbdomen.Width, 0.133*W7rAbdomen.Height, aDuration, idcSinusoid);
  ArmRight1.Angle.ChangeTo(12.588, aDuration, idcSinusoid);
  ArmRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight2.MoveTo(0, 0.801*ArmRight1.Height, aDuration, idcSinusoid);
  ArmRight2.Angle.ChangeTo(-62.161, aDuration, idcSinusoid);
  ArmRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  W7Hand.MoveTo(-0.204*ArmRight2.Width, 0.843*ArmRight2.Height, aDuration, idcSinusoid);
  W7Hand.Angle.ChangeTo(0, aDuration, idcSinusoid);
  W7Hand.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft1.MoveTo(0.349*W7rAbdomen.Width, 0.133*W7rAbdomen.Height, aDuration, idcSinusoid);
  ArmLeft1.Angle.ChangeTo(-20.000, aDuration, idcSinusoid);
  ArmLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft2.MoveTo(0, 0.767*ArmLeft1.Height, aDuration, idcSinusoid);
  ArmLeft2.Angle.ChangeTo(5.996, aDuration, idcSinusoid);
  ArmLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandLeft.MoveTo(-0.169*ArmLeft2.Width, 0.809*ArmLeft2.Height, aDuration, idcSinusoid);
  HandLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TRobotW7Right.Posture_Walk3(aDuration: single);
begin
  W7rAbdomen.MoveTo(-0.502*W7rAbdomen.Width, -0.994*W7rAbdomen.Height, aDuration, idcSinusoid);
  W7rAbdomen.Angle.ChangeTo(3.397, aDuration, idcSinusoid);
  W7rAbdomen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  W7rHead.MoveTo(0.134*W7rAbdomen.Width, -0.848*W7rAbdomen.Height, aDuration, idcSinusoid);
  W7rHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  W7rHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight1.MoveTo(-0.421*LegRight1.Width, -0.285*LegRight1.Height, aDuration, idcSinusoid);
  LegRight1.Angle.ChangeTo(-40.525, aDuration, idcSinusoid);
  LegRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight2.MoveTo(-0.032*LegRight1.Width, 0.851*LegRight1.Height, aDuration, idcSinusoid);
  LegRight2.Angle.ChangeTo(39.697, aDuration, idcSinusoid);
  LegRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeRight.MoveTo(-0.300*LegRight2.Width, 0.890*LegRight2.Height, aDuration, idcSinusoid);
  ShoeRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft1.MoveTo(-0.501*LegLeft1.Width, -0.179*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft1.Angle.ChangeTo(10.970, aDuration, idcSinusoid);
  LegLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft2.MoveTo(-0.021*LegLeft1.Width, 0.851*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft2.Angle.ChangeTo(16.172, aDuration, idcSinusoid);
  LegLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeLeft.MoveTo(-0.300*LegLeft2.Width, 0.890*LegLeft2.Height, aDuration, idcSinusoid);
  ShoeLeft.Angle.ChangeTo(-8.934, aDuration, idcSinusoid);
  ShoeLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight1.MoveTo(0.349*W7rAbdomen.Width, 0.133*W7rAbdomen.Height, aDuration, idcSinusoid);
  ArmRight1.Angle.ChangeTo(22.428, aDuration, idcSinusoid);
  ArmRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight2.MoveTo(0, 0.801*ArmRight1.Height, aDuration, idcSinusoid);
  ArmRight2.Angle.ChangeTo(-19.117, aDuration, idcSinusoid);
  ArmRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  W7Hand.MoveTo(-0.204*ArmRight2.Width, 0.843*ArmRight2.Height, aDuration, idcSinusoid);
  W7Hand.Angle.ChangeTo(0, aDuration, idcSinusoid);
  W7Hand.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft1.MoveTo(0.349*W7rAbdomen.Width, 0.133*W7rAbdomen.Height, aDuration, idcSinusoid);
  ArmLeft1.Angle.ChangeTo(-20.000, aDuration, idcSinusoid);
  ArmLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft2.MoveTo(0, 0.767*ArmLeft1.Height, aDuration, idcSinusoid);
  ArmLeft2.Angle.ChangeTo(-19.589, aDuration, idcSinusoid);
  ArmLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandLeft.MoveTo(-0.169*ArmLeft2.Width, 0.809*ArmLeft2.Height, aDuration, idcSinusoid);
  HandLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TRobotW7Right.Posture_Walk4(aDuration: single);
begin
  W7rAbdomen.MoveTo(-0.502*W7rAbdomen.Width, -0.994*W7rAbdomen.Height, aDuration, idcSinusoid);
  W7rAbdomen.Angle.ChangeTo(1.184, aDuration, idcSinusoid);
  W7rAbdomen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  W7rHead.MoveTo(0.134*W7rAbdomen.Width, -0.848*W7rAbdomen.Height, aDuration, idcSinusoid);
  W7rHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  W7rHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight1.MoveTo(-0.501*LegRight1.Width, -0.179*LegRight1.Height, aDuration, idcSinusoid);
  LegRight1.Angle.ChangeTo(-16.196, aDuration, idcSinusoid);
  LegRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight2.MoveTo(-0.032*LegRight1.Width, 0.851*LegRight1.Height, aDuration, idcSinusoid);
  LegRight2.Angle.ChangeTo(13.471, aDuration, idcSinusoid);
  LegRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeRight.MoveTo(-0.300*LegRight2.Width, 0.890*LegRight2.Height, aDuration, idcSinusoid);
  ShoeRight.Angle.ChangeTo(2.370, aDuration, idcSinusoid);
  ShoeRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft1.MoveTo(-0.501*LegLeft1.Width, -0.179*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft1.Angle.ChangeTo(26.228, aDuration, idcSinusoid);
  LegLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft2.MoveTo(-0.021*LegLeft1.Width, 0.851*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft2.Angle.ChangeTo(31.126, aDuration, idcSinusoid);
  LegLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeLeft.MoveTo(-0.300*LegLeft2.Width, 0.890*LegLeft2.Height, aDuration, idcSinusoid);
  ShoeLeft.Angle.ChangeTo(18.336, aDuration, idcSinusoid);
  ShoeLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight1.MoveTo(0.349*W7rAbdomen.Width, 0.133*W7rAbdomen.Height, aDuration, idcSinusoid);
  ArmRight1.Angle.ChangeTo(12.588, aDuration, idcSinusoid);
  ArmRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight2.MoveTo(0, 0.801*ArmRight1.Height, aDuration, idcSinusoid);
  ArmRight2.Angle.ChangeTo(-19.117, aDuration, idcSinusoid);
  ArmRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  W7Hand.MoveTo(-0.204*ArmRight2.Width, 0.843*ArmRight2.Height, aDuration, idcSinusoid);
  W7Hand.Angle.ChangeTo(0, aDuration, idcSinusoid);
  W7Hand.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft1.MoveTo(0.349*W7rAbdomen.Width, 0.133*W7rAbdomen.Height, aDuration, idcSinusoid);
  ArmLeft1.Angle.ChangeTo(-20.000, aDuration, idcSinusoid);
  ArmLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft2.MoveTo(0, 0.767*ArmLeft1.Height, aDuration, idcSinusoid);
  ArmLeft2.Angle.ChangeTo(5.996, aDuration, idcSinusoid);
  ArmLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandLeft.MoveTo(-0.169*ArmLeft2.Width, 0.809*ArmLeft2.Height, aDuration, idcSinusoid);
  HandLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TRobotW7Right.WalkHorizontallyTo(aX: single;
  aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue;
  aDelay: single);
begin
  CheckHorizontalMoveToX(aX, aTargetScreen, aMessageValueWhenFinish, aDelay);
  case MovingDirection of
    mdLeft, mdRight: State := w7rvsWalking;
    mdNone: State := w7rvsIdle;
  end;
end;

{ TRobotW74Direction }

procedure TRobotW74Direction.SetState(AValue: TRobotW74State);
begin
  if FState = AValue then Exit;
  FState := AValue;

  FW7Front.Visible := AValue in [w74sDownIdle, w74sDownWalking];
  FW7Front.Freeze := not FW7Front.Visible;

  FW7Right.Visible := AValue in [w74sRightIdle, w74sLeftIdle, w74sRightWalking, w74sLeftWalking];
  FW7Right.Freeze := not FW7Right.Visible;
  if FW7Right.Visible then FW7Right.FlipH := AValue in [w74sLeftIdle, w74sLeftWalking];

  FW7Back.Visible := AValue in [w74sUpIdle, w74sUpWalking];
  FW7Back.Freeze := not FW7Back.Visible;

  // we keep the same  value for all positions
  DeltaYToTop := FW7Right.DeltaYToTop;
  DeltaYToBottom := FW7Right.DeltaYToBottom;
  BodyWidth := FW7Right.BodyWidth;
  BodyHeight := FW7Right.BodyHeight;

  case FState of
    w74sRightIdle, w74sLeftIdle: begin
      Speed.Value := PointF(0, 0);
      FW7Right.State := w7rvsIdle;
    end;

    w74sUpIdle: begin
      Speed.Value := PointF(0, 0);
      FW7Back.State := w7bvsIdle;
    end;
    w74sDownIdle: begin
      Speed.Value := PointF(0, 0);
      FW7Front.State := w7fvsIdle;
    end;
    w74sRightWalking: begin
      FW7Right.State := w7rvsWalking;
     { if Speed.X.Value < 0 then Speed.X.Value := WalkSpeed
        else Speed.X.ChangeTo(WalkSpeed, 0.2, idcSinusoid); }
      Speed.Y.Value := 0;
    end;
    w74sLeftWalking: begin
      FW7Right.State := w7rvsWalking;
   {   if Speed.X.Value > 0 then Speed.X.Value := -WalkSpeed
        else Speed.X.ChangeTo(-WalkSpeed, 0.2, idcSinusoid);  }
      Speed.Y.Value := 0;
    end;
    w74sUpWalking: begin
      FW7Back.State := w7bvsWalking;
      if Speed.Y.Value > 0 then Speed.Y.Value := -WalkSpeed
        else Speed.Y.ChangeTo(-WalkSpeed, 0.2, idcSinusoid);
      Speed.X.Value := 0;
    end;
    w74sDownWalking: begin
      FW7Front.State := w7fvsWalking;
      if Speed.Y.Value < 0 then Speed.Y.Value := WalkSpeed
        else Speed.Y.ChangeTo(WalkSpeed, 0.2, idcSinusoid);
      Speed.X.Value := 0;
    end;
  end;

end;

procedure TRobotW74Direction.SetTimeMultiplicator(AValue: single);
const COEFF_SPEED_WALKING = 0.05;
begin
  inherited SetTimeMultiplicator(AValue);
  FW7Front.TimeMultiplicator := AValue;
  FW7Right.TimeMultiplicator := AValue;
  FW7Back.TimeMultiplicator := AValue;

  WalkSpeed := FScene.Width * (COEFF_SPEED_WALKING + (1-TimeMultiplicator)*0.25);
end;

procedure TRobotW74Direction.SetWalkSpeed(AValue: single);
begin
  inherited SetWalkSpeed(AValue);
  FW7Front.WalkSpeed := AValue;
  FW7Right.WalkSpeed := AValue;
  FW7Back.WalkSpeed := AValue;
end;

constructor TRobotW74Direction.Create(aLayerIndex: integer);
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  MarkOffset := PointF(0, -ScaleH(10));

  FW7Front := TRobotW7FrontView.Create;
  AddChild(FW7Front);
  FW7Front.Posture_Idle(0);

  FW7Right := TRobotW7Right.Create;
  AddChild(FW7Right);
  FW7Right.Posture_Idle(0);

  FW7Back := TRobotW7Back.Create;
  AddChild(FW7Back);
  FW7Back.Posture_Idle(0);

  State := w74sDownIdle;
  DialogTextColor := BGRA(255,220,220);
  DialogAuthorName := 'W7';

  DeltaYToTop := FW7Right.DeltaYToTop;
  DeltaYToBottom := FW7Right.DeltaYToBottom;
  BodyWidth := FW7Right.BodyWidth;
  BodyHeight := FW7Right.BodyHeight;
  TimeMultiplicator := 0.7;
end;

procedure TRobotW74Direction.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin

    end;
  end;
end;

function TRobotW74Direction.IsIdle: boolean;
begin
  Result := FState in [w74sRightIdle, w74sLeftIdle, w74sUpIdle, w74sDownIdle];
end;

function TRobotW74Direction.IsOrientedRight: boolean;
begin
  Result := FW7Right.Visible and not FW7Right.FlipH;
end;

function TRobotW74Direction.IsOrientedLeft: boolean;
begin
  Result := FW7Right.Visible and FW7Right.FlipH;
end;

function TRobotW74Direction.IsOrientedBack: boolean;
begin
  Result := FW7Back.Visible;
end;

function TRobotW74Direction.IsOrientedFront: boolean;
begin
  Result := FW7Front.Visible;
end;

procedure TRobotW74Direction.IdleLeft;
begin
  State := w74sLeftIdle;
end;

procedure TRobotW74Direction.IdleRight;
begin
  State := w74sRightIdle;
end;

procedure TRobotW74Direction.IdleUp;
begin
  State := w74sUpIdle;
end;

procedure TRobotW74Direction.IdleDown;
begin
  State := w74sDownIdle;
end;

procedure TRobotW74Direction.WalkHorizontallyTo(aX: single;
  aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue;
  aDelay: single);
begin
  FW7Right.WalkHorizontallyTo(aX, aTargetScreen, aMessageValueWhenFinish, aDelay);

{  if X.Value < aX then begin
    CheckHorizontalMoveToX(aX, aTargetScreen, aMessageValueWhenFinish, aDelay);
    if MovingDirection <> mdNone then State := w74sRightWalking;
  end else if X.Value > aX then begin
    CheckHorizontalMoveToX(aX, aTargetScreen, aMessageValueWhenFinish, aDelay);
    if MovingDirection <> mdNone then State := w74sLeftWalking;
  end else aTargetScreen.PostMessage(aMessageValueWhenFinish, aDelay);   }
end;

procedure TRobotW74Direction.WalkVerticallyTo(aY: single;
  aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue;
  aDelay: single);
begin
  if Y.Value+DeltaYToBottom < aY then begin
    State := w74sDownWalking;
    CheckVerticalMoveToY(aY, aTargetScreen, aMessageValueWhenFinish, aDelay);
  end else if Y.Value+DeltaYToBottom > aY then begin
    State := w74sUpWalking;
    CheckVerticalMoveToY(aY, aTargetScreen, aMessageValueWhenFinish, aDelay);
  end else aTargetScreen.PostMessage(aMessageValueWhenFinish, aDelay);
end;

{ TRobotW7FrontView }

class procedure TRobotW7FrontView.LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single);
var path: string;
begin
  FAdditionalScale := aAdditionalScale;
  path := FolderSpriteRobotW7;
  texW7fAbdomen := aAtlas.AddFromSVG(path+'W7fAbdomen.svg', -1, ScaleH(54));
  texW7fHead := aAtlas.AddFromSVG(path+'W7fHead.svg', ScaleW(45), -1);
  texW7fShoe := aAtlas.AddFromSVG(path+'W7fShoe.svg', -1, ScaleH(14));
end;

procedure TRobotW7FrontView.SetState(AValue: TW7FrontViewState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  case FState of
    w7fvsIdle: begin
      Posture_Idle(0.5);
    end;
    w7fvsWalking: begin
      PostMessage(100);
    end;
  end;
end;

procedure TRobotW7FrontView.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  Abdomen.FlipH := AValue;
  Head.FlipH := AValue;
  LegLeft1.FlipH := AValue;
  LegRight1.FlipH := AValue;
  LegLeft2.FlipH := AValue;
  LegRight2.FlipH := AValue;
  ShoeLeft.FlipH := AValue;
  ShoeRight.FlipH := AValue;
  ArmRight1.FlipH := AValue;
  ArmRight2.FlipH := AValue;
  HandRight.FlipH := AValue;
  ArmLeft1.FlipH := AValue;
  ArmLeft2.FlipH := AValue;
  HandLeft.FlipH := AValue;
end;

procedure TRobotW7FrontView.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  Abdomen.FlipV := AValue;
  Head.FlipV := AValue;
  LegLeft1.FlipV := AValue;
  LegRight1.FlipV := AValue;
  LegLeft2.FlipV := AValue;
  LegRight2.FlipV := AValue;
  ShoeLeft.FlipV := AValue;
  ShoeRight.FlipV := AValue;
  ArmRight1.FlipV := AValue;
  ArmRight2.FlipV := AValue;
  HandRight.FlipV := AValue;
  ArmLeft1.FlipV := AValue;
  ArmLeft2.FlipV := AValue;
  HandLeft.FlipV := AValue;
end;

constructor TRobotW7FrontView.Create(aLayerIndex: integer);
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);

  Abdomen := TSprite.Create(texW7fAbdomen, False);
  with Abdomen do begin
    SetChildOf(Self, 0);
    SetCoordinate(-0.492*Abdomen.Width, -0.999*Abdomen.Height);
    Pivot := PointF(0.49, 1.00);
    ApplySymmetryWhenFlip := True;
  end;

  Head := TSprite.Create(texW7fHead, False);
  with Head do begin
    SetChildOf(Abdomen, 0);
    SetCoordinate(0.023*Abdomen.Width, -0.807*Abdomen.Height);
    Pivot := PointF(0.50, 0.99);
    ApplySymmetryWhenFlip := True;
  end;

  LegLeft1 := TSprite.Create(texW7LegLeft1, False);
  with LegLeft1 do begin
    SetChildOf(Self, -1);
    SetCoordinate(-1.328*LegLeft1.Width, -0.410*LegLeft1.Height);
    Pivot := PointF(0.59, 0.08);
    ApplySymmetryWhenFlip := True;
  end;

  LegRight1 := TSprite.Create(texW7LegRight1, False);
  with LegRight1 do begin
    SetChildOf(Self, -1);
    SetCoordinate(0.398*LegRight1.Width, -0.410*LegRight1.Height);
    Pivot := PointF(0.38, 0.09);
    ApplySymmetryWhenFlip := True;
  end;

  LegLeft2 := TSprite.Create(texW7Leg2, False);
  with LegLeft2 do begin
    SetChildOf(LegLeft1, 0);
    SetCoordinate(0.206*LegLeft1.Width, 0.846*LegLeft1.Height);
    Pivot := PointF(0.50, 0.13);
    ApplySymmetryWhenFlip := True;
  end;

  LegRight2 := TSprite.Create(texW7Leg2, False);
  with LegRight2 do begin
    SetChildOf(LegRight1, 0);
    SetCoordinate(0, 0.846*LegRight1.Height);
    Pivot := PointF(0.50, 0.11);
    ApplySymmetryWhenFlip := True;
  end;

  ShoeLeft := TSprite.Create(texW7fShoe, False);
  with ShoeLeft do begin
    SetChildOf(LegLeft2, -1);
    SetCoordinate(-0.193*LegLeft2.Width, 0.729*LegLeft2.Height);
    Pivot := PointF(0.50, 0.16);
    ApplySymmetryWhenFlip := True;
  end;

  ShoeRight := TSprite.Create(texW7fShoe, False);
  with ShoeRight do begin
    SetChildOf(LegRight2, -1);
    SetCoordinate(-0.193*LegRight2.Width, 0.729*LegRight2.Height);
    Pivot := PointF(0.50, 0.22);
    ApplySymmetryWhenFlip := True;
  end;

  ArmRight1 := TSprite.Create(texW7ArmHalf, False);
  with ArmRight1 do begin
    SetChildOf(Abdomen, 0);
    SetCoordinate(0, 0.100*Abdomen.Height);
    Pivot := PointF(0.50, 0.12);
    ApplySymmetryWhenFlip := True;
  end;

  ArmRight2 := TSprite.Create(texW7ArmHalf, False);
  with ArmRight2 do begin
    SetChildOf(ArmRight1, 0);
    SetCoordinate(0, 0.790*ArmRight1.Height);
    Pivot := PointF(0.50, 0.09);
    ApplySymmetryWhenFlip := True;
  end;

  HandRight := TSprite.Create(texW7Hand, False);
  with HandRight do begin
    SetChildOf(ArmRight2, 0);
    SetCoordinate(-0.177*ArmRight2.Width, 0.812*ArmRight2.Height);
    Pivot := PointF(0.50, 0.29);
    ApplySymmetryWhenFlip := True;
  end;

  ArmLeft1 := TSprite.Create(texW7ArmHalf, False);
  with ArmLeft1 do begin
    SetChildOf(Abdomen, 0);
    SetCoordinate(0.852*Abdomen.Width, 0.100*Abdomen.Height);
    Pivot := PointF(0.50, 0.08);
    ApplySymmetryWhenFlip := True;
  end;

  ArmLeft2 := TSprite.Create(texW7ArmHalf, False);
  with ArmLeft2 do begin
    SetChildOf(ArmLeft1, 0);
    SetCoordinate(0, 0.790*ArmLeft1.Height);
    Pivot := PointF(0.50, 0.10);
    ApplySymmetryWhenFlip := True;
  end;

  HandLeft := TSprite.Create(texW7Hand, False);
  with HandLeft do begin
    SetChildOf(ArmLeft2, 0);
    SetCoordinate(-0.177*ArmLeft2.Width, 0.812*ArmLeft2.Height);
    Pivot := PointF(0.50, 0.29);
    ApplySymmetryWhenFlip := True;
  end;
end;

procedure TRobotW7FrontView.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // WALKING
    100: begin
      if FState <> w7fvsWalking then exit;
      d := W7_BASE_TIME_MOVE*TimeMultiplicator;
      Posture_Walk1(d);
      PostMessage(105, d);
    end;
    105: begin
      if FState <> w7fvsWalking then exit;
      d := W7_BASE_TIME_MOVE*TimeMultiplicator;
      Posture_Walk2(d);
      PostMessage(100, d);
    end;
  end;//case
end;

procedure TRobotW7FrontView.Posture_Idle(aDuration: single);
begin
  Abdomen.MoveTo(-0.492*Abdomen.Width, -0.999*Abdomen.Height, aDuration, idcSinusoid);
  Abdomen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Abdomen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Head.MoveTo(0.023*Abdomen.Width, -0.807*Abdomen.Height, aDuration, idcSinusoid);
  Head.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Head.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft1.MoveTo(-1.328*LegLeft1.Width, -0.410*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight1.MoveTo(0.398*LegRight1.Width, -0.410*LegRight1.Height, aDuration, idcSinusoid);
  LegRight1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft2.MoveTo(0.206*LegLeft1.Width, 0.846*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight2.MoveTo(0, 0.846*LegRight1.Height, aDuration, idcSinusoid);
  LegRight2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeLeft.MoveTo(-0.193*LegLeft2.Width, 0.729*LegLeft2.Height, aDuration, idcSinusoid);
  ShoeLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeRight.MoveTo(-0.193*LegRight2.Width, 0.729*LegRight2.Height, aDuration, idcSinusoid);
  ShoeRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight1.MoveTo(0, 0.100*Abdomen.Height, aDuration, idcSinusoid);
  ArmRight1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ArmRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight2.MoveTo(0, 0.790*ArmRight1.Height, aDuration, idcSinusoid);
  ArmRight2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ArmRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandRight.MoveTo(-0.177*ArmRight2.Width, 0.812*ArmRight2.Height, aDuration, idcSinusoid);
  HandRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft1.MoveTo(0.852*Abdomen.Width, 0.100*Abdomen.Height, aDuration, idcSinusoid);
  ArmLeft1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ArmLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft2.MoveTo(0, 0.790*ArmLeft1.Height, aDuration, idcSinusoid);
  ArmLeft2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ArmLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandLeft.MoveTo(-0.177*ArmLeft2.Width, 0.812*ArmLeft2.Height, aDuration, idcSinusoid);
  HandLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TRobotW7FrontView.Posture_Walk1(aDuration: single);
begin
  Abdomen.MoveTo(-0.492*Abdomen.Width, -0.999*Abdomen.Height, aDuration, idcSinusoid);
  Abdomen.Angle.ChangeTo(1.922, aDuration, idcSinusoid);
  Abdomen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Head.MoveTo(0.023*Abdomen.Width, -0.807*Abdomen.Height, aDuration, idcSinusoid);
  Head.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Head.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft1.MoveTo(-1.328*LegLeft1.Width, -0.559*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight1.MoveTo(0.398*LegRight1.Width, -0.410*LegRight1.Height, aDuration, idcSinusoid);
  LegRight1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft2.MoveTo(0.206*LegLeft1.Width, 0.705*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight2.MoveTo(0, 0.846*LegRight1.Height, aDuration, idcSinusoid);
  LegRight2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeLeft.MoveTo(-0.193*LegLeft2.Width, 0.729*LegLeft2.Height, aDuration, idcSinusoid);
  ShoeLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeRight.MoveTo(-0.193*LegRight2.Width, 0.729*LegRight2.Height, aDuration, idcSinusoid);
  ShoeRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight1.MoveTo(0, 0.100*Abdomen.Height, aDuration, idcSinusoid);
  ArmRight1.Angle.ChangeTo(3.043, aDuration, idcSinusoid);
  ArmRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight2.MoveTo(0, 0.790*ArmRight1.Height, aDuration, idcSinusoid);
  ArmRight2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ArmRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandRight.MoveTo(-0.177*ArmRight2.Width, 0.812*ArmRight2.Height, aDuration, idcSinusoid);
  HandRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft1.MoveTo(0.852*Abdomen.Width, 0.100*Abdomen.Height, aDuration, idcSinusoid);
  ArmLeft1.Angle.ChangeTo(-3.618, aDuration, idcSinusoid);
  ArmLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft2.MoveTo(0, 0.790*ArmLeft1.Height, aDuration, idcSinusoid);
  ArmLeft2.Angle.ChangeTo(20.981, aDuration, idcSinusoid);
  ArmLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandLeft.MoveTo(-0.177*ArmLeft2.Width, 0.812*ArmLeft2.Height, aDuration, idcSinusoid);
  HandLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TRobotW7FrontView.Posture_Walk2(aDuration: single);
begin
  Abdomen.MoveTo(-0.492*Abdomen.Width, -0.999*Abdomen.Height, aDuration, idcSinusoid);
  Abdomen.Angle.ChangeTo(-1.536, aDuration, idcSinusoid);
  Abdomen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Head.MoveTo(0.023*Abdomen.Width, -0.807*Abdomen.Height, aDuration, idcSinusoid);
  Head.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Head.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft1.MoveTo(-1.328*LegLeft1.Width, -0.410*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight1.MoveTo(0.398*LegRight1.Width, -0.559*LegRight1.Height, aDuration, idcSinusoid);
  LegRight1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft2.MoveTo(0.206*LegLeft1.Width, 0.846*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight2.MoveTo(0, 0.690*LegRight1.Height, aDuration, idcSinusoid);
  LegRight2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeLeft.MoveTo(-0.193*LegLeft2.Width, 0.729*LegLeft2.Height, aDuration, idcSinusoid);
  ShoeLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeRight.MoveTo(-0.193*LegRight2.Width, 0.729*LegRight2.Height, aDuration, idcSinusoid);
  ShoeRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight1.MoveTo(0, 0.100*Abdomen.Height, aDuration, idcSinusoid);
  ArmRight1.Angle.ChangeTo(2.552, aDuration, idcSinusoid);
  ArmRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight2.MoveTo(0, 0.790*ArmRight1.Height, aDuration, idcSinusoid);
  ArmRight2.Angle.ChangeTo(-21.207, aDuration, idcSinusoid);
  ArmRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandRight.MoveTo(-0.177*ArmRight2.Width, 0.812*ArmRight2.Height, aDuration, idcSinusoid);
  HandRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft1.MoveTo(0.852*Abdomen.Width, 0.100*Abdomen.Height, aDuration, idcSinusoid);
  ArmLeft1.Angle.ChangeTo(-2.703, aDuration, idcSinusoid);
  ArmLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft2.MoveTo(0, 0.790*ArmLeft1.Height, aDuration, idcSinusoid);
  ArmLeft2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ArmLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandLeft.MoveTo(-0.177*ArmLeft2.Width, 0.812*ArmLeft2.Height, aDuration, idcSinusoid);
  HandLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TRobotW7FrontView.Posture_OnWall(aDuration: single);
begin
  Abdomen.MoveTo(-0.492*Abdomen.Width, -0.999*Abdomen.Height, aDuration, idcSinusoid);
  Abdomen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Abdomen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Head.MoveTo(0.023*Abdomen.Width, -0.807*Abdomen.Height, aDuration, idcSinusoid);
  Head.Angle.ChangeTo(8.121, aDuration, idcSinusoid);
  Head.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft1.MoveTo(-1.328*LegLeft1.Width, -0.410*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight1.MoveTo(0.398*LegRight1.Width, -0.410*LegRight1.Height, aDuration, idcSinusoid);
  LegRight1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft2.MoveTo(0.206*LegLeft1.Width, 0.846*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight2.MoveTo(0, 0.846*LegRight1.Height, aDuration, idcSinusoid);
  LegRight2.Angle.ChangeTo(69.383, aDuration, idcSinusoid);
  LegRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeLeft.MoveTo(-0.193*LegLeft2.Width, 0.729*LegLeft2.Height, aDuration, idcSinusoid);
  ShoeLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeRight.MoveTo(-0.193*LegRight2.Width, 0.729*LegRight2.Height, aDuration, idcSinusoid);
  ShoeRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight1.MoveTo(0, 0.100*Abdomen.Height, aDuration, idcSinusoid);
  ArmRight1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ArmRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight2.MoveTo(0, 0.790*ArmRight1.Height, aDuration, idcSinusoid);
  ArmRight2.Angle.ChangeTo(-7.280, aDuration, idcSinusoid);
  ArmRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandRight.MoveTo(-0.177*ArmRight2.Width, 0.812*ArmRight2.Height, aDuration, idcSinusoid);
  HandRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft1.MoveTo(0.852*Abdomen.Width, 0.100*Abdomen.Height, aDuration, idcSinusoid);
  ArmLeft1.Angle.ChangeTo(4.880, aDuration, idcSinusoid);
  ArmLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft2.MoveTo(0, 0.790*ArmLeft1.Height, aDuration, idcSinusoid);
  ArmLeft2.Angle.ChangeTo(17.206, aDuration, idcSinusoid);
  ArmLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandLeft.MoveTo(-0.177*ArmLeft2.Width, 0.812*ArmLeft2.Height, aDuration, idcSinusoid);
  HandLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

{ TRobotW7Back }

class procedure TRobotW7Back.LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single);
var path: string;
begin
  FAdditionalScale := aAdditionalScale;
  path := FolderSpriteRobotW7;
  texW7bAbdomen := aAtlas.AddFromSVG(path+'W7bAbdomen.svg', -1, ScaleH(54));
  texW7bHead := aAtlas.AddFromSVG(path+'W7bHead.svg', ScaleW(45), -1);
  texW7bShoe := aAtlas.AddFromSVG(path+'W7bShoe.svg', -1, ScaleH(19));
end;

procedure TRobotW7Back.SetState(AValue: TW7BackViewState);
begin
  if FState = AValue then Exit;
  FState := AValue;

  case FState of
    w7bvsIdle: Posture_Idle(0.5);
    w7bvsWalking: PostMessage(100);
  end;
end;

procedure TRobotW7Back.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  W7bAbdomen.FlipH := AValue;
  W7bHead.FlipH := AValue;
  ArmLeft1.FlipH := AValue;
  ArmRight1.FlipH := AValue;
  ArmLeft2.FlipH := AValue;
  ArmRight2.FlipH := AValue;
  HandLeft.FlipH := AValue;
  HandRight.FlipH := AValue;
  LegLeft1.FlipH := AValue;
  LegRight1.FlipH := AValue;
  LegLeft2.FlipH := AValue;
  LegRight2.FlipH := AValue;
  ShoeLeft.FlipH := AValue;
  ShoeRight.FlipH := AValue;
end;

procedure TRobotW7Back.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  W7bAbdomen.FlipV := AValue;
  W7bHead.FlipV := AValue;
  ArmLeft1.FlipV := AValue;
  ArmRight1.FlipV := AValue;
  ArmLeft2.FlipV := AValue;
  ArmRight2.FlipV := AValue;
  HandLeft.FlipV := AValue;
  HandRight.FlipV := AValue;
  LegLeft1.FlipV := AValue;
  LegRight1.FlipV := AValue;
  LegLeft2.FlipV := AValue;
  LegRight2.FlipV := AValue;
  ShoeLeft.FlipV := AValue;
  ShoeRight.FlipV := AValue;
end;

constructor TRobotW7Back.Create(aLayerIndex: integer);
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);
  Pivot := PointF(0.50, 0.50);

  W7bAbdomen := TSprite.Create(texW7bAbdomen, False);
  with W7bAbdomen do begin
    SetChildOf(Self, 0);
    SetCoordinate(-0.500*W7bAbdomen.Width, -0.994*W7bAbdomen.Height);
    Pivot := PointF(0.50, 0.99);
    ApplySymmetryWhenFlip := True;
  end;

  W7bHead := TSprite.Create(texW7bHead, False);
  with W7bHead do begin
    SetChildOf(W7bAbdomen, 0);
    SetCoordinate(0.022*W7bAbdomen.Width, -0.802*W7bAbdomen.Height);
    Pivot := PointF(0.50, 1.00);
    ApplySymmetryWhenFlip := True;
  end;

  ArmLeft1 := TSprite.Create(texW7ArmHalf, False);
  with ArmLeft1 do begin
    SetChildOf(W7bAbdomen, -1);
    SetCoordinate(0, 0.103*W7bAbdomen.Height);
    Pivot := PointF(0.50, 0.10);
    Angle.Value := 45.30;
    ApplySymmetryWhenFlip := True;
  end;

  ArmRight1 := TSprite.Create(texW7ArmHalf, False);
  with ArmRight1 do begin
    SetChildOf(W7bAbdomen, -1);
    SetCoordinate(0.847*W7bAbdomen.Width, 0.103*W7bAbdomen.Height);
    Pivot := PointF(0.50, 0.10);
    Angle.Value := -47.60;
    ApplySymmetryWhenFlip := True;
  end;

  ArmLeft2 := TSprite.Create(texW7ArmHalf, False);
  with ArmLeft2 do begin
    SetChildOf(ArmLeft1, 0);
    SetCoordinate(0, 0.740*ArmLeft1.Height);
    Pivot := PointF(0.50, 0.12);
    ApplySymmetryWhenFlip := True;
  end;

  ArmRight2 := TSprite.Create(texW7ArmHalf, False);
  with ArmRight2 do begin
    SetChildOf(ArmRight1, 0);
    SetCoordinate(0, 0.740*ArmRight1.Height);
    Pivot := PointF(0.50, 0.11);
    ApplySymmetryWhenFlip := True;
  end;

  HandLeft := TSprite.Create(texW7Hand, False);
  with HandLeft do begin
    SetChildOf(ArmLeft2, 0);
    SetCoordinate(-0.187*ArmLeft2.Width, 0.788*ArmLeft2.Height);
    Pivot := PointF(0.50, 0.28);
    ApplySymmetryWhenFlip := True;
  end;

  HandRight := TSprite.Create(texW7Hand, False);
  with HandRight do begin
    SetChildOf(ArmRight2, 0);
    SetCoordinate(-0.187*ArmRight2.Width, 0.788*ArmRight2.Height);
    Pivot := PointF(0.50, 0.28);
    ApplySymmetryWhenFlip := True;
  end;

  LegLeft1 := TSprite.Create(texW7LegLeft1, False);
  with LegLeft1 do begin
    SetChildOf(Self, -1);
    SetCoordinate(-1.385*LegLeft1.Width, -0.400*LegLeft1.Height);
    Pivot := PointF(0.59, 0.09);
    ApplySymmetryWhenFlip := True;
  end;

  LegRight1 := TSprite.Create(texW7LegRight1, False);
  with LegRight1 do begin
    SetChildOf(Self, -1);
    SetCoordinate(0.443*LegRight1.Width, -0.400*LegRight1.Height);
    Pivot := PointF(0.41, 0.09);
    ApplySymmetryWhenFlip := True;
  end;

  LegLeft2 := TSprite.Create(texW7Leg2, False);
  with LegLeft2 do begin
    SetChildOf(LegLeft1, 0);
    SetCoordinate(0.217*LegLeft1.Width, 0.841*LegLeft1.Height);
    Pivot := PointF(0.50, 0.12);
    ApplySymmetryWhenFlip := True;
  end;

  LegRight2 := TSprite.Create(texW7Leg2, False);
  with LegRight2 do begin
    SetChildOf(LegRight1, 0);
    SetCoordinate(0, 0.841*LegRight1.Height);
    Pivot := PointF(0.50, 0.12);
    ApplySymmetryWhenFlip := True;
  end;

  ShoeLeft := TSprite.Create(texW7bShoe, False);
  with ShoeLeft do begin
    SetChildOf(LegLeft2, -1);
    SetCoordinate(-0.221*LegLeft2.Width, 0.421*LegLeft2.Height);
    ApplySymmetryWhenFlip := True;
  end;

  ShoeRight := TSprite.Create(texW7bShoe, False);
  with ShoeRight do begin
    SetChildOf(LegRight2, -1);
    SetCoordinate(-0.221*LegRight2.Width, 0.421*LegRight2.Height);
    ApplySymmetryWhenFlip := True;
  end;
end;

procedure TRobotW7Back.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // WALKING
    100: begin
      if FState <> w7bvsWalking then exit;
      d := W7_BASE_TIME_MOVE*TimeMultiplicator;
      Posture_Walk1(d);
      PostMessage(105, d);
    end;
    105: begin
      if FState <> w7bvsWalking then exit;
      d := W7_BASE_TIME_MOVE*TimeMultiplicator;
      Posture_Walk2(d);
      PostMessage(100, d);
    end;
  end;//case
end;

procedure TRobotW7Back.Posture_Idle(aDuration: single);
begin
  W7bAbdomen.MoveTo(-0.500*W7bAbdomen.Width, -0.994*W7bAbdomen.Height, aDuration, idcSinusoid);
  W7bAbdomen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  W7bAbdomen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  W7bHead.MoveTo(0.022*W7bAbdomen.Width, -0.802*W7bAbdomen.Height, aDuration, idcSinusoid);
  W7bHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  W7bHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft1.MoveTo(0, 0.103*W7bAbdomen.Height, aDuration, idcSinusoid);
  ArmLeft1.Angle.ChangeTo(2.803, aDuration, idcSinusoid);
  ArmLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight1.MoveTo(0.847*W7bAbdomen.Width, 0.103*W7bAbdomen.Height, aDuration, idcSinusoid);
  ArmRight1.Angle.ChangeTo(-3.061, aDuration, idcSinusoid);
  ArmRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft2.MoveTo(0, 0.740*ArmLeft1.Height, aDuration, idcSinusoid);
  ArmLeft2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ArmLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight2.MoveTo(0, 0.740*ArmRight1.Height, aDuration, idcSinusoid);
  ArmRight2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ArmRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandLeft.MoveTo(-0.187*ArmLeft2.Width, 0.788*ArmLeft2.Height, aDuration, idcSinusoid);
  HandLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandRight.MoveTo(-0.187*ArmRight2.Width, 0.788*ArmRight2.Height, aDuration, idcSinusoid);
  HandRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft1.MoveTo(-1.385*LegLeft1.Width, -0.400*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight1.MoveTo(0.444*LegRight1.Width, -0.400*LegRight1.Height, aDuration, idcSinusoid);
  LegRight1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft2.MoveTo(0.217*LegLeft1.Width, 0.841*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight2.MoveTo(0, 0.841*LegRight1.Height, aDuration, idcSinusoid);
  LegRight2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeLeft.MoveTo(-0.221*LegLeft2.Width, 0.421*LegLeft2.Height, aDuration, idcSinusoid);
  ShoeLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeRight.MoveTo(-0.221*LegRight2.Width, 0.421*LegRight2.Height, aDuration, idcSinusoid);
  ShoeRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TRobotW7Back.Posture_Walk1(aDuration: single);
begin
  W7bAbdomen.MoveTo(-0.500*W7bAbdomen.Width, -0.994*W7bAbdomen.Height, aDuration, idcSinusoid);
  W7bAbdomen.Angle.ChangeTo(4.924, aDuration, idcSinusoid);
  W7bAbdomen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  W7bHead.MoveTo(0.022*W7bAbdomen.Width, -0.802*W7bAbdomen.Height, aDuration, idcSinusoid);
  W7bHead.Angle.ChangeTo(-3.574, aDuration, idcSinusoid);
  W7bHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft1.MoveTo(0, 0.103*W7bAbdomen.Height, aDuration, idcSinusoid);
  ArmLeft1.Angle.ChangeTo(8.539, aDuration, idcSinusoid);
  ArmLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight1.MoveTo(0.847*W7bAbdomen.Width, 0.103*W7bAbdomen.Height, aDuration, idcSinusoid);
  ArmRight1.Angle.ChangeTo(-13.575, aDuration, idcSinusoid);
  ArmRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft2.MoveTo(0, 0.740*ArmLeft1.Height, aDuration, idcSinusoid);
  ArmLeft2.Angle.ChangeTo(-7.385, aDuration, idcSinusoid);
  ArmLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight2.MoveTo(0, 0.740*ArmRight1.Height, aDuration, idcSinusoid);
  ArmRight2.Angle.ChangeTo(11.888, aDuration, idcSinusoid);
  ArmRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandLeft.MoveTo(-0.187*ArmLeft2.Width, 0.788*ArmLeft2.Height, aDuration, idcSinusoid);
  HandLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandRight.MoveTo(-0.187*ArmRight2.Width, 0.788*ArmRight2.Height, aDuration, idcSinusoid);
  HandRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft1.MoveTo(-1.385*LegLeft1.Width, -0.592*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight1.MoveTo(0.444*LegRight1.Width, -0.400*LegRight1.Height, aDuration, idcSinusoid);
  LegRight1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft2.MoveTo(0.217*LegLeft1.Width, 0.610*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight2.MoveTo(0, 0.841*LegRight1.Height, aDuration, idcSinusoid);
  LegRight2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeLeft.MoveTo(-0.221*LegLeft2.Width, 0.421*LegLeft2.Height, aDuration, idcSinusoid);
  ShoeLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeRight.MoveTo(-0.221*LegRight2.Width, 0.421*LegRight2.Height, aDuration, idcSinusoid);
  ShoeRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TRobotW7Back.Posture_Walk2(aDuration: single);
begin
  W7bAbdomen.MoveTo(-0.500*W7bAbdomen.Width, -0.994*W7bAbdomen.Height, aDuration, idcSinusoid);
  W7bAbdomen.Angle.ChangeTo(-3.686, aDuration, idcSinusoid);
  W7bAbdomen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  W7bHead.MoveTo(0.022*W7bAbdomen.Width, -0.802*W7bAbdomen.Height, aDuration, idcSinusoid);
  W7bHead.Angle.ChangeTo(4.944, aDuration, idcSinusoid);
  W7bHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft1.MoveTo(0, 0.103*W7bAbdomen.Height, aDuration, idcSinusoid);
  ArmLeft1.Angle.ChangeTo(15.941, aDuration, idcSinusoid);
  ArmLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight1.MoveTo(0.847*W7bAbdomen.Width, 0.103*W7bAbdomen.Height, aDuration, idcSinusoid);
  ArmRight1.Angle.ChangeTo(-10.797, aDuration, idcSinusoid);
  ArmRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmLeft2.MoveTo(0, 0.740*ArmLeft1.Height, aDuration, idcSinusoid);
  ArmLeft2.Angle.ChangeTo(-7.450, aDuration, idcSinusoid);
  ArmLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ArmRight2.MoveTo(0, 0.740*ArmRight1.Height, aDuration, idcSinusoid);
  ArmRight2.Angle.ChangeTo(4.937, aDuration, idcSinusoid);
  ArmRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandLeft.MoveTo(-0.187*ArmLeft2.Width, 0.788*ArmLeft2.Height, aDuration, idcSinusoid);
  HandLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  HandRight.MoveTo(-0.187*ArmRight2.Width, 0.788*ArmRight2.Height, aDuration, idcSinusoid);
  HandRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  HandRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft1.MoveTo(-1.385*LegLeft1.Width, -0.400*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight1.MoveTo(0.444*LegRight1.Width, -0.567*LegRight1.Height, aDuration, idcSinusoid);
  LegRight1.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight1.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegLeft2.MoveTo(0.217*LegLeft1.Width, 0.841*LegLeft1.Height, aDuration, idcSinusoid);
  LegLeft2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegLeft2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LegRight2.MoveTo(0, 0.687*LegRight1.Height, aDuration, idcSinusoid);
  LegRight2.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LegRight2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeLeft.MoveTo(-0.221*LegLeft2.Width, 0.421*LegLeft2.Height, aDuration, idcSinusoid);
  ShoeLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ShoeRight.MoveTo(-0.221*LegRight2.Width, 0.421*LegRight2.Height, aDuration, idcSinusoid);
  ShoeRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ShoeRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

end.

