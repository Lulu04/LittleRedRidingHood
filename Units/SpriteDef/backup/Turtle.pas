unit Turtle;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

type

TTurtle = class(TSprite)
private
  class var FAdditionalScale: single;
  class var texTurtleBody, texTurtleBackwardLeg, texTurtleEyeOpen, texTurtleForwardLeg, texTurtleHead, 
  texTurtleTail: PTexture;
private
  TurtleHead: TSprite;
  TurtleEyeOpen: TSprite;
  TurtleForwardLeg: TSprite;
  TurtleBackwardLeg: TSprite;
  TurtleTail: TSprite;
  BackwardLegRight: TSprite;
  ForwardLegRight: TSprite;
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
end;

implementation

{ TTurtle }

class procedure TTurtle.LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single);
var dataFolder: string;
begin
  FAdditionalScale := aAdditionalScale;
  dataFolder := FScene.App.DataFolder;
  texTurtleBody := aAtlas.AddFromSVG(dataFolder+'Sprites\SnakeFissure\TurtleBody.svg', ScaleW(219), -1);
  texTurtleBackwardLeg := aAtlas.AddFromSVG(dataFolder+'Sprites\SnakeFissure\TurtleBackwardLeg.svg', -1, ScaleH(73));
  texTurtleEyeOpen := aAtlas.AddFromSVG(dataFolder+'Sprites\SnakeFissure\TurtleEyeOpen.svg', -1, ScaleH(22));
  texTurtleForwardLeg := aAtlas.AddFromSVG(dataFolder+'Sprites\SnakeFissure\TurtleForwardLeg.svg', -1, ScaleH(79));
  texTurtleHead := aAtlas.AddFromSVG(dataFolder+'Sprites\SnakeFissure\TurtleHead.svg', ScaleW(100), -1);
  texTurtleTail := aAtlas.AddFromSVG(dataFolder+'Sprites\SnakeFissure\TurtleTail.svg', ScaleW(38), -1);
end;

procedure TTurtle.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  TurtleHead.SetFlipH(AValue);
  TurtleEyeOpen.SetFlipH(AValue);
  TurtleForwardLeg.SetFlipH(AValue);
  TurtleBackwardLeg.SetFlipH(AValue);
  TurtleTail.SetFlipH(AValue);
  BackwardLegRight.SetFlipH(AValue);
  ForwardLegRight.SetFlipH(AValue);
end;

procedure TTurtle.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  TurtleHead.SetFlipV(AValue);
  TurtleEyeOpen.SetFlipV(AValue);
  TurtleForwardLeg.SetFlipV(AValue);
  TurtleBackwardLeg.SetFlipV(AValue);
  TurtleTail.SetFlipV(AValue);
  BackwardLegRight.SetFlipV(AValue);
  ForwardLegRight.SetFlipV(AValue);
end;

constructor TTurtle.Create(aLayerIndex: integer);
begin
  inherited Create(texTurtleBody, False);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);

  TurtleHead := TSprite.Create(texTurtleHead, False);
  with TurtleHead do begin
    SetChildOf(Self, -2);
    SetCoordinate(-0.319*TurtleBody.Width, 0.111*TurtleBody.Height);
    Pivot := PointF(0.85, 0.70);
    ApplySymmetryWhenFlip := True;
  end;

  TurtleEyeOpen := TSprite.Create(texTurtleEyeOpen, False);
  with TurtleEyeOpen do begin
    SetChildOf(TurtleHead, 0);
    SetCoordinate(0.189*TurtleHead.Width, 0.139*TurtleHead.Height);
    ApplySymmetryWhenFlip := True;
  end;

  TurtleForwardLeg := TSprite.Create(texTurtleForwardLeg, False);
  with TurtleForwardLeg do begin
    SetChildOf(Self, -1);
    SetCoordinate(-0.007*TurtleBody.Width, 0.565*TurtleBody.Height);
    Pivot := PointF(0.70, 0.23);
    ApplySymmetryWhenFlip := True;
  end;

  TurtleBackwardLeg := TSprite.Create(texTurtleBackwardLeg, False);
  with TurtleBackwardLeg do begin
    SetChildOf(Self, -1);
    SetCoordinate(0.591*TurtleBody.Width, 0.653*TurtleBody.Height);
    Pivot := PointF(0.44, 0.17);
    ApplySymmetryWhenFlip := True;
  end;

  TurtleTail := TSprite.Create(texTurtleTail, False);
  with TurtleTail do begin
    SetChildOf(Self, -1);
    SetCoordinate(0.883*TurtleBody.Width, 0.692*TurtleBody.Height);
    Pivot := PointF(0.03, 0.27);
    ApplySymmetryWhenFlip := True;
  end;

  BackwardLegRight := TSprite.Create(texTurtleBackwardLeg, False);
  with BackwardLegRight do begin
    SetChildOf(Self, -2);
    SetCoordinate(0.690*TurtleBody.Width, 0.646*TurtleBody.Height);
    Pivot := PointF(0.59, 0.14);
    ApplySymmetryWhenFlip := True;
  end;

  ForwardLegRight := TSprite.Create(texTurtleForwardLeg, False);
  with ForwardLegRight do begin
    SetChildOf(Self, -2);
    SetCoordinate(0.090*TurtleBody.Width, 0.557*TurtleBody.Height);
    Pivot := PointF(0.72, 0.21);
    ApplySymmetryWhenFlip := True;
  end;
end;

procedure TTurtle.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin
    end;
  end;//case
end;

procedure TTurtle.Posture_Idle(aDuration: single);
begin
  TurtleHead.MoveTo(-0.319*TurtleBody.Width, 0.111*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(-0.007*TurtleBody.Width, 0.565*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.591*TurtleBody.Width, 0.653*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.883*TurtleBody.Width, 0.692*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.690*TurtleBody.Width, 0.646*TurtleBody.Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.090*TurtleBody.Width, 0.557*TurtleBody.Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTurtle.Posture_Sleep(aDuration: single);
begin
  TurtleHead.MoveTo(-0.075*TurtleBody.Width, 0.098*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(-42.187, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(-0.007*TurtleBody.Width, 0.393*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.591*TurtleBody.Width, 0.456*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.843*TurtleBody.Width, 0.619*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(23.966, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.690*TurtleBody.Width, 0.444*TurtleBody.Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.090*TurtleBody.Width, 0.377*TurtleBody.Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTurtle.Posture_Walk1(aDuration: single);
begin
  TurtleHead.MoveTo(-0.319*TurtleBody.Width, 0.111*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(0.032*TurtleBody.Width, 0.479*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(25.851, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.591*TurtleBody.Width, 0.653*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.883*TurtleBody.Width, 0.692*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.662*TurtleBody.Width, 0.620*TurtleBody.Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(30.876, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.090*TurtleBody.Width, 0.557*TurtleBody.Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTurtle.Posture_Walk2(aDuration: single);
begin
  TurtleHead.MoveTo(-0.319*TurtleBody.Width, 0.111*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(-4.079, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(-0.007*TurtleBody.Width, 0.565*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.547*TurtleBody.Width, 0.588*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(-47.975, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.883*TurtleBody.Width, 0.692*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(15.475, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.660*TurtleBody.Width, 0.636*TurtleBody.Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(2.912, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.083*TurtleBody.Width, 0.437*TurtleBody.Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(-27.261, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTurtle.Posture_Walk3(aDuration: single);
begin
  TurtleHead.MoveTo(-0.319*TurtleBody.Width, 0.111*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(-11.216, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(-0.007*TurtleBody.Width, 0.565*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(-13.999, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.543*TurtleBody.Width, 0.533*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(11.785, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.883*TurtleBody.Width, 0.692*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.660*TurtleBody.Width, 0.636*TurtleBody.Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(-18.401, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.083*TurtleBody.Width, 0.437*TurtleBody.Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(19.981, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTurtle.Posture_Walk4(aDuration: single);
begin
  TurtleHead.MoveTo(-0.319*TurtleBody.Width, 0.111*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(-2.255, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(-0.007*TurtleBody.Width, 0.565*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(-29.066, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.497*TurtleBody.Width, 0.632*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(11.785, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.883*TurtleBody.Width, 0.692*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(20.457, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.660*TurtleBody.Width, 0.636*TurtleBody.Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(-36.718, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.083*TurtleBody.Width, 0.587*TurtleBody.Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(19.981, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTurtle.Posture_Walk5(aDuration: single);
begin
  TurtleHead.MoveTo(-0.319*TurtleBody.Width, 0.111*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleHead.Angle.ChangeTo(-11.696, aDuration, idcSinusoid);
  TurtleHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleEyeOpen.MoveTo(0.189*TurtleHead.Width, 0.139*TurtleHead.Height, aDuration, idcSinusoid);
  TurtleEyeOpen.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleEyeOpen.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleForwardLeg.MoveTo(0.030*TurtleBody.Width, 0.487*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleForwardLeg.Angle.ChangeTo(29.595, aDuration, idcSinusoid);
  TurtleForwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleBackwardLeg.MoveTo(0.591*TurtleBody.Width, 0.653*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleBackwardLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleBackwardLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  TurtleTail.MoveTo(0.883*TurtleBody.Width, 0.692*TurtleBody.Height, aDuration, idcSinusoid);
  TurtleTail.Angle.ChangeTo(0, aDuration, idcSinusoid);
  TurtleTail.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BackwardLegRight.MoveTo(0.660*TurtleBody.Width, 0.636*TurtleBody.Height, aDuration, idcSinusoid);
  BackwardLegRight.Angle.ChangeTo(29.850, aDuration, idcSinusoid);
  BackwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  ForwardLegRight.MoveTo(0.090*TurtleBody.Width, 0.557*TurtleBody.Height, aDuration, idcSinusoid);
  ForwardLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  ForwardLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

end.
