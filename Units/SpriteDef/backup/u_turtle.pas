unit u_turtle;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

type

{ TTurtle }
TTurtleState = (tursUnknow, tursWakeUp, tursIdle, tursSleep, tursWalk);

TTurtle = class(TSprite)
private
  class var FAdditionalScale: single;
  class var texTurtleBody, texTurtleBackwardLeg, texTurtleEyeOpen, texTurtleForwardLeg, texTurtleHead, 
  texTurtleTail, texTurtleEyeClosed, texZ: PTexture;
private
  FTurtleState: TTurtleState;
  TurtleHead: TSprite;
  TurtleEyeOpen, EyeClosed: TSprite;
  TurtleForwardLeg: TSprite;
  TurtleBackwardLeg: TSprite;
  TurtleTail: TSprite;
  BackwardLegRight: TSprite;
  ForwardLegRight: TSprite;
  FLayerIndex: integer;
  FNewCenterXToWalk, FPixelPerStep: single;
  procedure SetTurtleState(AValue: TTurtleState);
  procedure KillZSprites;
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
  procedure Posture_Sleep(aDuration: single=0.5);
  procedure Posture_Walk1(aDuration: single=0.5);
  procedure Posture_Walk2(aDuration: single=0.5);
  procedure Posture_Walk3(aDuration: single=0.5);
  procedure Posture_Walk4(aDuration: single=0.5);
  procedure Posture_Walk5(aDuration: single=0.5);
  procedure CloseEye;
  procedure OpenEye;
  procedure WakeUpAndWalkTo(aCenterX: single);
  property State: TTurtleState read FTurtleState write SetTurtleState;
end;

implementation

uses u_app, u_common;

{ TTurtle }

class procedure TTurtle.LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single);
var path: string;
begin
  FAdditionalScale := aAdditionalScale;
  path := FolderSpriteSnakeFissure;
  texTurtleBody := aAtlas.AddFromSVG(path+'TurtleBody.svg', ScaleW(219), -1);
  texTurtleBackwardLeg := aAtlas.AddFromSVG(path+'TurtleBackwardLeg.svg', -1, ScaleH(73));
  texTurtleEyeOpen := aAtlas.AddFromSVG(path+'TurtleEyeOpen.svg', -1, ScaleH(22));
  texTurtleEyeClosed := aAtlas.AddFromSVG(path+'TurtleEyeClosed.svg', -1, ScaleH(22));
  texTurtleForwardLeg := aAtlas.AddFromSVG(path+'TurtleForwardLeg.svg', -1, ScaleH(79));
  texTurtleHead := aAtlas.AddFromSVG(path+'TurtleHead.svg', ScaleW(100), -1);
  texTurtleTail := aAtlas.AddFromSVG(path+'TurtleTail.svg', ScaleW(38), -1);
  texZ := aAtlas.AddFromSVG(path+'TurtleZ.svg', -1, ScaleH(18));
end;

procedure TTurtle.SetTurtleState(AValue: TTurtleState);
begin
  if FTurtleState = AValue then Exit;
  FTurtleState := AValue;
  case AValue of
    tursIdle: Posture_Idle(2.0);
    tursSleep: PostMessage(0);
    tursWalk: PostMessage(100);
  end;
end;

procedure TTurtle.KillZSprites;
var i: integer;
  o: TSimpleSurfaceWithEffect;
begin
  for i:=0 to TurtleHead.ChildCount-1 do begin
    o := TurtleHead.Childs[i];
    if (o is TSprite) and (TSprite(o).Texture = texZ) then o.Kill;
  end;
end;

procedure TTurtle.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  TurtleHead.FlipH := AValue;
  TurtleEyeOpen.FlipH := AValue;
  EyeClosed.FlipH := AValue;
  TurtleForwardLeg.FlipH := AValue;
  TurtleBackwardLeg.FlipH := AValue;
  TurtleTail.FlipH := AValue;
  BackwardLegRight.FlipH := AValue;
  ForwardLegRight.FlipH := AValue;
end;

procedure TTurtle.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  TurtleHead.FlipV := AValue;
  TurtleEyeOpen.FlipV := AValue;
  EyeClosed.FlipV := AValue;
  TurtleForwardLeg.FlipV := AValue;
  TurtleBackwardLeg.FlipV := AValue;
  TurtleTail.FlipV := AValue;
  BackwardLegRight.FlipV := AValue;
  ForwardLegRight.FlipV := AValue;
end;

constructor TTurtle.Create(aLayerIndex: integer);
begin
  FLayerIndex := aLayerIndex;
  inherited Create(texTurtleBody, False);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);

  TurtleHead := TSprite.Create(texTurtleHead, False);
  with TurtleHead do begin
    SetChildOf(Self, -2);
    SetCoordinate(-0.319*Width, 0.111*Height);
    Pivot := PointF(0.85, 0.70);
    ApplySymmetryWhenFlip := True;
  end;

  TurtleEyeOpen := TSprite.Create(texTurtleEyeOpen, False);
  with TurtleEyeOpen do begin
    SetChildOf(TurtleHead, 0);
    SetCoordinate(0.189*TurtleHead.Width, 0.139*TurtleHead.Height);
    ApplySymmetryWhenFlip := True;
  end;

  EyeClosed := TSprite.Create(texTurtleEyeClosed, False);
  with EyeClosed do begin
    SetChildOf(TurtleHead, 0);
    SetCoordinate(0.189*TurtleHead.Width, 0.139*TurtleHead.Height);
    ApplySymmetryWhenFlip := True;
  end;

  TurtleForwardLeg := TSprite.Create(texTurtleForwardLeg, False);
  with TurtleForwardLeg do begin
    SetChildOf(Self, -1);
    SetCoordinate(-0.007*Width, 0.565*Height);
    Pivot := PointF(0.70, 0.23);
    ApplySymmetryWhenFlip := True;
  end;

  TurtleBackwardLeg := TSprite.Create(texTurtleBackwardLeg, False);
  with TurtleBackwardLeg do begin
    SetChildOf(Self, -1);
    SetCoordinate(0.591*Width, 0.653*Height);
    Pivot := PointF(0.44, 0.17);
    ApplySymmetryWhenFlip := True;
  end;

  TurtleTail := TSprite.Create(texTurtleTail, False);
  with TurtleTail do begin
    SetChildOf(Self, -1);
    SetCoordinate(0.883*Width, 0.692*Height);
    Pivot := PointF(0.03, 0.27);
    ApplySymmetryWhenFlip := True;
  end;

  BackwardLegRight := TSprite.Create(texTurtleBackwardLeg, False);
  with BackwardLegRight do begin
    SetChildOf(Self, -2);
    SetCoordinate(0.690*Width, 0.646*Height);
    Pivot := PointF(0.59, 0.14);
    ApplySymmetryWhenFlip := True;
  end;

  ForwardLegRight := TSprite.Create(texTurtleForwardLeg, False);
  with ForwardLegRight do begin
    SetChildOf(Self, -2);
    SetCoordinate(0.090*Width, 0.557*Height);
    Pivot := PointF(0.72, 0.21);
    ApplySymmetryWhenFlip := True;
  end;

  // Collision body
  CollisionBody.AddPolygon([PointF(0.484*Width, 0.003*Height)*FAdditionalScale, PointF(0.239*Width, 0.138*Height)*FAdditionalScale,
    PointF(0.082*Width, 0.389*Height)*FAdditionalScale, PointF(0.002*Width, 0.413*Height)*FAdditionalScale,
    PointF(0.088*Width, 0.711*Height)*FAdditionalScale, PointF(0.940*Width, 0.758*Height)*FAdditionalScale,
    PointF(1.000*Width, 0.698*Height)*FAdditionalScale, PointF(0.864*Width, 0.453*Height)*FAdditionalScale,
    PointF(0.679*Width, 0.077*Height)*FAdditionalScale, PointF(0.484*Width, 0.003*Height)*FAdditionalScale]);

  CloseEye;
end;

procedure TTurtle.ProcessMessage(UserValue: TUserMessageValue);
var z: TSprite;
  v: single;
begin
  case UserValue of
    // sleep
    0: begin
      Posture_Sleep(2.0);
      PostMessage(5, 2.0);
    end;
    5: begin
      if State <> tursSleep then exit;
      z := TSprite.Create(texZ, False);
      TurtleHead.AddChild(z, 0);
      z.CenterX := TurtleHead.Width*0.5 + Random*PPIScale(20)-PPIScale(10);
      z.BottomY := z.Height;
      z.MoveToLayer(FLayerIndex);
      z.Opacity.Value := 0;
      z.Opacity.ChangeTo(255, 1.0);
      v := 1.0 + Random*0.15 - 0.3;
      z.Scale.Value := PointF(v, v);
      z.MoveYRelative(-z.Height*3, 4.0, idcSinusoid);
      z.KillDefered(4.0);
      if Random > 0.5 then
        z.AddAndPlayScenario('MoveXRelative -'+z.Width.ToString+' 1.0 idcsinusoid'#10+
                             'Wait 1.0'#10+
                             'MoveXRelative '+z.Width.ToString+' 1.0 idcsinusoid'#10+
                             'Wait 1.0'#10+
                             'Goto Here')
      else
        z.AddAndPlayScenario('MoveXRelative '+z.Width.ToString+' 1.0 idcsinusoid'#10+
                             'Wait 1.0'#10+
                             'MoveXRelative -'+z.Width.ToString+' 1.0 idcsinusoid'#10+
                             'Wait 1.0'#10+
                             'Loop');
      z.AddAndPlayScenario('Wait 3.0'#10+
                           'OpacityChange 0 1.0 idcLinear');
      PostMessage(5, 1.8);
    end;

    // WakeUp and walk to new x pos
    50: begin
      State := tursWakeUp;
      OpenEye;
      PostMessage(55, 1.0);
    end;
    55: begin
      MoveYRelative(-Height*0.2, 1.5, idcSinusoid);
      Posture_Idle(1.5);
      PostMessage(60, 1.5);
    end;
    60: begin   // flipH
      FlipH := CenterX < FNewCenterXToWalk;
      FPixelPerStep := FScene.Width*0.05;
      if not FlipH then FPixelPerStep := -FPixelPerStep;
      PostMessage(65, 0.5);
    end;
    65: begin  //start to walk
      State := tursWalk;
      PostMessage(70);
    end;
    70: begin // survey the end of the walk
      if FlipH then begin
        if CenterX >= FNewCenterXToWalk then begin
          CenterX := FNewCenterXToWalk;
          State := tursUnknow;
          PostMessage(75, 0.5);
          exit;
        end;
      end else begin
        if CenterX <= FNewCenterXToWalk then begin
          CenterX := FNewCenterXToWalk;
          State := tursUnknow;
          PostMessage(75, 0.5);
          exit;
        end;
      end;
      PostMessage(70);
    end;
    75: begin  // reach the target pos -> turtle sleep
      MoveYRelative(Height*0.2, 1.5, idcSinusoid);
      Posture_Sleep(1.5);
      PostMessage(80, 1.5);
    end;
    80: begin
      CloseEye;
      State := tursSleep;   // Z anim
    end;

    // walk animation
    100: begin
      if State <> tursWalk then exit;
      Posture_Walk1(1.0);
      MoveXRelative(FPixelPerStep, 1.0, idcSinusoid);
      PostMessage(105, 1.0);
    end;
    105: begin
      if State <> tursWalk then exit;
      Posture_Walk2(1.0);
      MoveXRelative(FPixelPerStep, 1.0, idcSinusoid);
      PostMessage(110, 1.0);
    end;
    110: begin
      if State <> tursWalk then exit;
      Posture_Walk3(1.0);
      MoveXRelative(FPixelPerStep, 1.0, idcSinusoid);
      PostMessage(115, 1.0);
    end;
    115: begin
      if State <> tursWalk then exit;
      Posture_Walk4(1.0);
      MoveXRelative(FPixelPerStep, 1.0, idcSinusoid);
      PostMessage(100, 1.0);
    end;
  end;//case
end;

procedure TTurtle.Posture_Idle(aDuration: single);
begin
  TurtleHead.MoveTo(-0.319*Width, 0.111*Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(-0.007*Width, 0.565*Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.591*Width, 0.653*Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.883*Width, 0.692*Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.690*Width, 0.646*Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.090*Width, 0.557*Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTurtle.Posture_Sleep(aDuration: single);
begin
  TurtleHead.MoveTo(-0.075*Width, 0.098*Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(-42.187, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(-0.007*Width, 0.393*Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.591*Width, 0.456*Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.843*Width, 0.619*Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(23.966, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.690*Width, 0.444*Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.090*Width, 0.377*Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTurtle.Posture_Walk1(aDuration: single);
begin
  TurtleHead.MoveTo(-0.319*Width, 0.111*Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(0.032*Width, 0.479*Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(25.851, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.591*Width, 0.653*Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.883*Width, 0.692*Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.662*Width, 0.620*Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(30.876, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.090*Width, 0.557*Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTurtle.Posture_Walk2(aDuration: single);
begin
  TurtleHead.MoveTo(-0.319*Width, 0.111*Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(-4.079, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(-0.007*Width, 0.565*Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.547*Width, 0.588*Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(-47.975, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.883*Width, 0.692*Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(15.475, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.660*Width, 0.636*Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(2.912, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.083*Width, 0.437*Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(-27.261, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTurtle.Posture_Walk3(aDuration: single);
begin
  TurtleHead.MoveTo(-0.319*Width, 0.111*Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(-11.216, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(-0.007*Width, 0.565*Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(-13.999, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.543*Width, 0.533*Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(11.785, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.883*Width, 0.692*Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.660*Width, 0.636*Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(-18.401, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.083*Width, 0.437*Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(19.981, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTurtle.Posture_Walk4(aDuration: single);
begin
  TurtleHead.MoveTo(-0.319*Width, 0.111*Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(-2.255, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(-0.007*Width, 0.565*Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(-29.066, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.497*Width, 0.632*Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(11.785, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.883*Width, 0.692*Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(20.457, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.660*Width, 0.636*Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(-36.718, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.083*Width, 0.587*Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(19.981, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTurtle.Posture_Walk5(aDuration: single);
begin
  TurtleHead.MoveTo(-0.319*Width, 0.111*Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(-11.696, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(0.030*Width, 0.487*Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(29.595, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.591*Width, 0.653*Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.883*Width, 0.692*Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.660*Width, 0.636*Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(29.850, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.090*Width, 0.557*Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTurtle.CloseEye;
begin
  TurtleEyeOpen.Visible := False;
  EyeClosed.Visible := True;
end;

procedure TTurtle.OpenEye;
begin
  TurtleEyeOpen.Visible := True;
  EyeClosed.Visible := False;
  KillZSprites;
end;

procedure TTurtle.WakeUpAndWalkTo(aCenterX: single);
begin
  FNewCenterXToWalk := aCenterX;
  PostMessage(50);
end;

end.
