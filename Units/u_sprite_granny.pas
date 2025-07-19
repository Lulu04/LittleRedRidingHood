unit u_sprite_granny;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes,
  u_sprite_lrcommon, u_common;

type

{ TGrannyHead }

TGrannyHead = class(TSprite)
private
  FBun, FMouthNormal, FMouthHurt: TSprite;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  constructor Create;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure SetMouthNormal;
  procedure SetMouthHurt;
end;

TGrannyState = (gsUnknown, gsIdleRight, gsIdleLeft, gsCooking, gsKidnapped,
                gsWalking);
TGranny = class(TCharacterWithDialogPanel)
private
  FFork: TSprite;
  FState: TGrannyState;
  FWalkingStep: integer;
  procedure SetState(AValue: TGrannyState);
  function GetWalkingDeltaPixelPerStep: integer;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  // reference is middle/bottom of the dress
  Head: TGrannyHead;
  Dress, LeftArm, RightArm, LeftLeg, RightLeg: TSprite;
  constructor Create(aLayerIndex: integer);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Posture_Idle(aDuration: single=0.5);
  procedure Posture_Walking1(aDuration: single=0.5);
  procedure Posture_Walking2(aDuration: single=0.5);
  procedure Posture_Walking3(aDuration: single=0.5);
  procedure Posture_Walking4(aDuration: single=0.5);
public
  procedure SetIdlePosition(aImmediate: boolean);
  procedure SetCookingAnim;
  procedure SetKidnapedPosition;
public
  procedure IdleRight;
  procedure IdleLeft;
  procedure WalkHorizontallyTo(aX: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
  property State: TGrannyState read FState write SetState;
end;

procedure LoadGranMaTextures(aAtlas: TOGLCTextureAtlas);

implementation

uses u_app, u_resourcestring;

var texGMBun, texGMMouthNormal, texGMMouthHurt, texGMHead, texGMDress, texGMArm, texGMLeg, texFork: PTexture;

procedure LoadGranMaTextures(aAtlas: TOGLCTextureAtlas);
var path: string;
begin
  path := SpriteGranMaFolder;
  texGMBun := aAtlas.AddFromSVG(path+'Bun.svg', ScaleW(43), -1);
  texGMMouthNormal := aAtlas.AddFromSVG(path+'MouthNormal.svg', ScaleW(14), -1);
  texGMMouthHurt := aAtlas.AddFromSVG(path+'MouthHurt.svg', ScaleW(16), -1);
  texGMHead := aAtlas.AddFromSVG(path+'Head.svg', ScaleW(77), -1);
  texGMDress := aAtlas.AddFromSVG(path+'Dress.svg', ScaleW(55), -1);
  texGMArm := aAtlas.AddFromSVG(path+'Arm.svg', -1, ScaleH(38));
  texGMLeg := aAtlas.AddFromSVG(path+'Leg.svg', -1, ScaleH(25));
  texFork := aAtlas.AddFromSVG(path+'Fork.svg', -1, ScaleH(42));
end;

{ TGranny }

procedure TGranny.SetState(AValue: TGrannyState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  case AValue of
    gsIdleRight: begin
      FlipH := False;
      Posture_Idle(1.0);
      PostMessage(0);
    end;
    gsIdleLeft: begin
      FlipH := True;
      Posture_Idle(1.0);
      PostMessage(0);
    end;
    gsCooking: PostMessage(100);
    gsKidnapped: SetKidnapedPosition;
    gsWalking: PostMessage(200);
  end;
end;

function TGranny.GetWalkingDeltaPixelPerStep: integer;
begin
  Result := Round(FScene.Width*0.01);
  if FlipH then Result := -Result;
end;

procedure TGranny.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  Head.FlipH := AValue;
  Dress.FlipH := AValue;
  LeftArm.FlipH := AValue;
  RightArm.FlipH := AValue;
  LeftLeg.FlipH := AValue;
  RightLeg.FlipH := AValue;
  FFork.FlipH := AValue;
end;

procedure TGranny.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  Head.FlipV := AValue;
  Dress.FlipV := AValue;
  LeftArm.FlipV := AValue;
  RightArm.FlipV := AValue;
  LeftLeg.FlipV := AValue;
  RightLeg.FlipV := AValue;
  FFork.FlipV := AValue;
end;

constructor TGranny.Create(aLayerIndex: integer);
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  self.DialogAuthorName := sGranny;
  WalkDontUseSpeed := True;

  Dress := CreateChildSprite(texGMDress, 0);
  Dress.CenterX := 0;
  Dress.BottomY := 0;
  Dress.Pivot := PointF(0.5, 1);

    Head := TGrannyHead.Create;
    Dress.AddChild(Head, -1);
    Head.SetCoordinate(-Head.Width*0.05, -Head.Height*0.95);
    Head.Pivot := PointF(0.45, 1.0);
    Head.ApplySymmetryWhenFlip := True;

    LeftArm := TSprite.Create(texGMArm, False);
    Dress.AddChild(LeftArm, -2);
    LeftArm.SetCoordinate(Dress.Width*0.55, Dress.Height*0.1);
    LeftArm.Pivot := PointF(0.5, 0.2);
    LeftArm.ApplySymmetryWhenFlip := True;
      FFork := TSprite.Create(texFork, False);
      LeftArm.AddChild(FFork, 0);
      //FFork.FlipV := True;
      FFork.SetCoordinate(LeftArm.Width*0.5, LeftArm.Height*0.85);
      //FFork.Angle.Value := 90;
      FFork.Pivot := PointF(0.0, 0.5);
      FFork.ApplySymmetryWhenFlip := True;
      FFork.Visible := False;

    RightArm := TSprite.Create(texGMArm, False);
    Dress.AddChild(RightArm, 0);
    RightArm.SetCoordinate(Dress.Width*0.25, Dress.Height*0.1);
    RightArm.Pivot := PointF(0.15, 0.2);
    RightArm.ApplySymmetryWhenFlip := True;

  LeftLeg := CreateChildSprite(texGMLeg, -3);
  LeftLeg.SetCoordinate(LeftLeg.Width*0.15, -LeftLeg.Height*0.3);
  LeftLeg.Pivot := PointF(0.25, 0.1);

  RightLeg := CreateChildSprite(texGMLeg, -2);
  RightLeg.SetCoordinate(-RightLeg.Width*0.55, LeftLeg.Y.Value);
  RightLeg.Pivot := PointF(0.25, 0.1);

  DeltaYToTop := Round(Dress.Height + Head.Height); // Head.Height*0.1);
  DeltaYToBottom := Round(LeftLeg.Height*0.7);

  BodyHeight := Round((LeftLeg.Height+Dress.Height+Head.Height)*0.8);
  BodyWidth := Head.Width;

  TimeMultiplicator := 1.0;
  State := gsIdleRight;
end;

procedure TGranny.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  // check the end of a walk
  if State = gsWalking then
    if ((MovingDirection = mdLeft) and (X.Value <= WalkingTargetPoint.x)) or
       ((MovingDirection = mdRight) and (X.Value >= WalkingTargetPoint.x)) then begin
      X.Value := WalkingTargetPoint.x;
      if FlipH then State := gsIdleLeft else State := gsIdleRight;
      EndOfWalk_SendMessageToScreen;
    end;
end;

procedure TGranny.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // Body moves in idle position
    0: begin
      if not(State in [gsIdleRight, gsIdleLeft, gsCooking]) then exit;
      d := Random*1.5+1.5;
      Dress.Angle.ChangeTo(-Random, d, idcSinusoid);
      PostMessage(1, d);
    end;
    1: begin
      if not(State in [gsIdleRight, gsIdleLeft, gsCooking]) then exit;
      d := Random*1.5+1.5;
      Dress.Angle.ChangeTo(Random, d, idcSinusoid);
      PostMessage(0, d);
    end;

    // cooking anim
    100: begin
      FFork.Visible := True;
      PostMessage(105); // head + lefta rmanim
      PostMessage(110); // right arm anim
      PostMessage(120); // left arm
    end;
    105: begin
      Head.Angle.ChangeTo(15, 1.0*TimeMultiplicator, idcSinusoid);
      //LeftArm.Angle.ChangeTo(-70+FLeftArmAngleDelta, 1.0*TimeMultiplicator, idcSinusoid);
      PostMessage(106, 2.0+Random*3);
    end;
    106: begin
      Head.Angle.ChangeTo(0, 1.0*TimeMultiplicator, idcSinusoid);
      //LeftArm.Angle.ChangeTo(-87+FLeftArmAngleDelta, 1.0*TimeMultiplicator, idcSinusoid);
      PostMessage(105, 2.0+Random*4);
    end;
    110: begin
      d := 1+Random;
      RightArm.Angle.ChangeTo(-35, d, idcSinusoid);
      PostMessage(111, d*2);
    end;
    111: begin
      d := 1+Random;
      RightArm.Angle.ChangeTo(-Random*20-15, d, idcSinusoid);
      PostMessage(110, d*2);
    end;
    120: begin
      LeftArm.Angle.ChangeTo(-70+Random*2.5-5, 1.0*TimeMultiplicator, idcSinusoid);
      PostMessage(121, 0.5+Random*0.5);
    end;
    121: begin
      LeftArm.Angle.ChangeTo(-80+Random*2.5-5, 1.0*TimeMultiplicator, idcSinusoid);
      PostMessage(120, 0.5+Random*0.5);
    end;

    // walking anim
    200: begin
      if State <> gsWalking then exit;
      case FWalkingStep of
        0: Posture_Walking1(0.2);
        1: Posture_Walking2(0.2);
        2: Posture_Walking3(0.2);
        3: Posture_Walking4(0.2);
      end;
      inc(FWalkingStep);
      if FWalkingStep = 4 then FWalkingStep := 0;
      X.ChangeTo(x.Value+GetWalkingDeltaPixelPerStep, 0.2);//, idcSinusoid);
      PostMessage(200, 0.2);
    end;

  end;
end;

procedure TGranny.Posture_Idle(aDuration: single);
begin
  Dress.MoveTo(-0.509*Dress.Width, -0.985*Dress.Height, aDuration, idcSinusoid);
  Dress.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Dress.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightArm.MoveTo(0.246*Dress.Width, 0.037*Dress.Height, aDuration, idcSinusoid);
  RightArm.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightArm.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftArm.MoveTo(0.509*Dress.Width, 0.059*Dress.Height, aDuration, idcSinusoid);
  LeftArm.Angle.ChangeTo(-45.555, aDuration, idcSinusoid);
  LeftArm.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Head.MoveTo(-0.086*Dress.Width, -1.119*Dress.Height, aDuration, idcSinusoid);
  Head.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Head.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  FFork.MoveTo(0.400*RightArm.Width, 0.900*RightArm.Height, aDuration, idcSinusoid);
  FFork.Angle.ChangeTo(0, aDuration, idcSinusoid);
  FFork.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftLeg.MoveTo(0.173*LeftLeg.Width, -0.246*LeftLeg.Height, aDuration, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightLeg.MoveTo(-0.564*RightLeg.Width, -0.223*RightLeg.Height, aDuration, idcSinusoid);
  RightLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TGranny.Posture_Walking1(aDuration: single);
begin
  Dress.MoveTo(-0.509*Dress.Width, -0.985*Dress.Height, aDuration, idcSinusoid);
  Dress.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Dress.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightArm.MoveTo(0.246*Dress.Width, 0.037*Dress.Height, aDuration, idcSinusoid);
  RightArm.Angle.ChangeTo(9.580, aDuration, idcSinusoid);
  RightArm.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftArm.MoveTo(0.509*Dress.Width, 0.059*Dress.Height, aDuration, idcSinusoid);
  LeftArm.Angle.ChangeTo(-45.555, aDuration, idcSinusoid);
  LeftArm.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Head.MoveTo(-0.086*Dress.Width, -1.119*Dress.Height, aDuration, idcSinusoid);
  Head.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Head.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftLeg.MoveTo(-0.028*LeftLeg.Width, -0.370*LeftLeg.Height, aDuration, idcSinusoid);
  LeftLeg.Angle.ChangeTo(-30.000, aDuration, idcSinusoid);
  LeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightLeg.MoveTo(-0.564*RightLeg.Width, -0.223*RightLeg.Height, aDuration, idcSinusoid);
  RightLeg.Angle.ChangeTo(45.000, aDuration, idcSinusoid);
  RightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TGranny.Posture_Walking2(aDuration: single);
begin
  Dress.MoveTo(-0.509*Dress.Width, -0.985*Dress.Height, aDuration, idcSinusoid);
  Dress.Angle.ChangeTo(2.134, aDuration, idcSinusoid);
  Dress.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightArm.MoveTo(0.246*Dress.Width, 0.037*Dress.Height, aDuration, idcSinusoid);
  RightArm.Angle.ChangeTo(-12.112, aDuration, idcSinusoid);
  RightArm.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftArm.MoveTo(0.509*Dress.Width, 0.059*Dress.Height, aDuration, idcSinusoid);
  LeftArm.Angle.ChangeTo(-34.617, aDuration, idcSinusoid);
  LeftArm.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Head.MoveTo(-0.086*Dress.Width, -1.119*Dress.Height, aDuration, idcSinusoid);
  Head.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Head.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftLeg.MoveTo(0.173*LeftLeg.Width, -0.246*LeftLeg.Height, aDuration, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightLeg.MoveTo(-0.564*RightLeg.Width, -0.223*RightLeg.Height, aDuration, idcSinusoid);
  RightLeg.Angle.ChangeTo(75.000, aDuration, idcSinusoid);
  RightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TGranny.Posture_Walking3(aDuration: single);
begin
  Dress.MoveTo(-0.509*Dress.Width, -0.985*Dress.Height, aDuration, idcSinusoid);
  Dress.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Dress.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightArm.MoveTo(0.246*Dress.Width, 0.037*Dress.Height, aDuration, idcSinusoid);
  RightArm.Angle.ChangeTo(-28.203, aDuration, idcSinusoid);
  RightArm.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftArm.MoveTo(0.509*Dress.Width, 0.059*Dress.Height, aDuration, idcSinusoid);
  LeftArm.Angle.ChangeTo(-23.924, aDuration, idcSinusoid);
  LeftArm.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Head.MoveTo(-0.086*Dress.Width, -1.119*Dress.Height, aDuration, idcSinusoid);
  Head.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Head.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftLeg.MoveTo(0.173*LeftLeg.Width, -0.246*LeftLeg.Height, aDuration, idcSinusoid);
  LeftLeg.Angle.ChangeTo(45.000, aDuration, idcSinusoid);
  LeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightLeg.MoveTo(-0.625*RightLeg.Width, -0.365*RightLeg.Height, aDuration, idcSinusoid);
  RightLeg.Angle.ChangeTo(-30.000, aDuration, idcSinusoid);
  RightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TGranny.Posture_Walking4(aDuration: single);
begin
  Dress.MoveTo(-0.509*Dress.Width, -0.985*Dress.Height, aDuration, idcSinusoid);
  Dress.Angle.ChangeTo(-1.796, aDuration, idcSinusoid);
  Dress.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightArm.MoveTo(0.246*Dress.Width, 0.037*Dress.Height, aDuration, idcSinusoid);
  RightArm.Angle.ChangeTo(-14.966, aDuration, idcSinusoid);
  RightArm.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftArm.MoveTo(0.509*Dress.Width, 0.059*Dress.Height, aDuration, idcSinusoid);
  LeftArm.Angle.ChangeTo(-22.224, aDuration, idcSinusoid);
  LeftArm.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Head.MoveTo(-0.086*Dress.Width, -1.119*Dress.Height, aDuration, idcSinusoid);
  Head.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Head.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftLeg.MoveTo(0.173*LeftLeg.Width, -0.246*LeftLeg.Height, aDuration, idcSinusoid);
  LeftLeg.Angle.ChangeTo(75.000, aDuration, idcSinusoid);
  LeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightLeg.MoveTo(-0.564*RightLeg.Width, -0.223*RightLeg.Height, aDuration, idcSinusoid);
  RightLeg.Angle.ChangeTo(-15.000, aDuration, idcSinusoid);
  RightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TGranny.SetIdlePosition(aImmediate: boolean);
var d: single;
begin
  if aImmediate then d := 0 else d := 0.5*TimeMultiplicator;
  Head.Angle.ChangeTo(0, d, idcSinusoid);
  RightArm.Angle.ChangeTo(-28, d, idcSinusoid);
  LeftArm.Angle.ChangeTo(-47, d, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, d, idcSinusoid);
  RightLeg.Angle.ChangeTo(0, d, idcSinusoid);
  FFork.Visible := False;
  PostMessage(0);
end;

procedure TGranny.SetCookingAnim;
begin
  State := gsCooking;
end;

procedure TGranny.SetKidnapedPosition;
begin
  FFork.Visible := False;
  LeftLeg.SetCoordinate(LeftLeg.Width*0.1, -LeftLeg.Height*0.3);
  RightLeg.SetCoordinate(RightLeg.Width*0.55, LeftLeg.Y.Value);
end;

procedure TGranny.IdleRight;
begin
  State := gsIdleRight;
end;

procedure TGranny.IdleLeft;
begin
  State := gsIdleLeft;
end;

procedure TGranny.WalkHorizontallyTo(aX: single;
  aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue;
  aDelay: single);
begin
  CheckHorizontalMoveToX(aX, aTargetScreen, aMessageValueWhenFinish, aDelay);
  FWalkingStep := 0;
  if MovingDirection <> mdNone then
    State := gsWalking;
end;

{ TGrannyHead }

procedure TGrannyHead.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FBun.FlipH := AValue;
  FMouthNormal.FlipH := AValue;
  FMouthHurt.FlipH := AValue;
end;

procedure TGrannyHead.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FBun.FlipV := AValue;
  FMouthNormal.FlipV := AValue;
  FMouthHurt.FlipV := AValue;
end;

constructor TGrannyHead.Create;
begin
  inherited Create(texGMHead, False);
  ApplySymmetryWhenFlip := True;

  FBun := TSprite.Create(texGMBun, False);
  AddChild(FBun, -1);
  FBun.SetCoordinate(0, -FBun.Height*0.7);
  FBun.Pivot := PointF(0.75, 0.74);
  FBun.ApplySymmetryWhenFlip := True;

  FMouthNormal := TSprite.Create(texGMMouthNormal, False);
  AddChild(FMouthNormal, 0);
  FMouthNormal.SetCoordinate(Width*0.45, Height*0.83);
  FMouthNormal.ApplySymmetryWhenFlip := True;

  FMouthHurt := TSprite.Create(texGMMouthHurt, False);
  AddChild(FMouthHurt, 0);
  FMouthHurt.SetCoordinate(Width*0.4, Height*0.75);
  FMouthHurt.ApplySymmetryWhenFlip := True;

  SetMouthNormal;
  PostMessage(0); // bun anim
end;

procedure TGrannyHead.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // Bun anim
    0: begin
      d := Random+0.5;
      FBun.Angle.ChangeTo(-Random*10, d, idcSingleRebound);
      PostMessage(1, d+Random*2);
    end;
    1: begin
      d := Random+0.5;
      FBun.Angle.ChangeTo(Random*10, d, idcSingleRebound);
      PostMessage(0, d+Random*2);
    end;
  end;
end;

procedure TGrannyHead.SetMouthNormal;
begin
  FMouthNormal.Visible := True;
  FMouthHurt.Visible := False;
end;

procedure TGrannyHead.SetMouthHurt;
begin
  FMouthNormal.Visible := False;
  FMouthHurt.Visible := True;
end;

end.

