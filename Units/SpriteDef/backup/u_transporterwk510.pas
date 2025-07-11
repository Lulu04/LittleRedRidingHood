unit u_transporterwk510;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

type

TTransporterWK510 = class(TSprite)
private
  class var FAdditionalScale: single;
  class var texTransporterBody, texTransporterLeg, texTransporterPlatform, texTransporterActuator: PTexture;
private
  LeftLeg: TSprite;
  RightLeg: TSprite;
  Platform: TSprite;
  LeftActuator: TSprite;
  RightActuator: TSprite;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  // aAdditionalScale is used to scale the collision bodies
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single=1.0);
  constructor Create(aLayerIndex: integer=-1);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
public
  procedure Posture_IdleOnGround(aDuration: single=0.5);
  procedure Posture_OnlyLegs(aDuration: single=0.5);
  procedure Posture_HalfPlatformOut(aDuration: single=0.5);
  procedure Posture_InAir(aDuration: single=0.5);
end;

implementation

uses u_common, u_app;

{ TTransporterWK510 }

class procedure TTransporterWK510.LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single);
var path: string;
begin
  FAdditionalScale := aAdditionalScale;
  path := FolderSpriteWolfCastle;
  texTransporterBody := aAtlas.AddFromSVG(path+'TransporterBody.svg', ScaleW(1040), -1);
  texTransporterLeg := aAtlas.AddFromSVG(path+'TransporterLeg.svg', -1, ScaleH(180));
  texTransporterPlatform := aAtlas.AddFromSVG(path+'TransporterPlatform.svg', ScaleW(498), -1);
  texTransporterActuator := aAtlas.AddFromSVG(path+'TransporterActuator.svg', -1, ScaleH(47));
end;

procedure TTransporterWK510.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  LeftLeg.FlipH := AValue;
  RightLeg.FlipH := AValue;
  Platform.FlipH := AValue;
  LeftActuator.FlipH := AValue;
  RightActuator.FlipH := AValue;
end;

procedure TTransporterWK510.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  LeftLeg.FlipV := AValue;
  RightLeg.FlipV := AValue;
  Platform.FlipV := AValue;
  LeftActuator.FlipV := AValue;
  RightActuator.FlipV := AValue;
end;

constructor TTransporterWK510.Create(aLayerIndex: integer);
begin
  inherited Create(texTransporterBody, False);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);
  SetCoordinate(-5.43, 13.56);

  LeftLeg := TSprite.Create(texTransporterLeg, False);
  with LeftLeg do begin
    SetChildOf(Self, -1);
    SetCoordinate(0.081*Self.Width, 0.858*Self.Height);
    ApplySymmetryWhenFlip := True;
  end;

  RightLeg := TSprite.Create(texTransporterLeg, False);
  with RightLeg do begin
    SetChildOf(Self, -1);
    SetCoordinate(0.768*Self.Width, 0.859*Self.Height);
    ApplySymmetryWhenFlip := True;
  end;

  Platform := TSprite.Create(texTransporterPlatform, False);
  with Platform do begin
    SetChildOf(LeftActuator, -1);
    SetCoordinate(-0.712*LeftActuator.Width, 0.969*LeftActuator.Height);
    ApplySymmetryWhenFlip := True;
  end;

  LeftActuator := TSprite.Create(texTransporterActuator, False);
  with LeftActuator do begin
    SetChildOf(Self, -2);
    SetCoordinate(0.271*Self.Width, 0.948*Self.Height);
    ApplySymmetryWhenFlip := True;
  end;

  RightActuator := TSprite.Create(texTransporterActuator, False);
  with RightActuator do begin
    SetChildOf(Self, -1);
    SetCoordinate(0.686*Self.Width, 0.950*Self.Height);
    ApplySymmetryWhenFlip := True;
  end;
end;

procedure TTransporterWK510.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin
    end;
  end;//case
end;

procedure TTransporterWK510.Posture_IdleOnGround(aDuration: single);
begin
  LeftLeg.MoveTo(0.081*TransporterBody.Width, 0.858*TransporterBody.Height, aDuration, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightLeg.MoveTo(0.768*TransporterBody.Width, 0.859*TransporterBody.Height, aDuration, idcSinusoid);
  RightLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Platform.MoveTo(-0.712*LeftActuator.Width, 0.969*LeftActuator.Height, aDuration, idcSinusoid);
  Platform.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Platform.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftActuator.MoveTo(0.271*TransporterBody.Width, 0.948*TransporterBody.Height, aDuration, idcSinusoid);
  LeftActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightActuator.MoveTo(0.686*TransporterBody.Width, 0.950*TransporterBody.Height, aDuration, idcSinusoid);
  RightActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTransporterWK510.Posture_OnlyLegs(aDuration: single);
begin
  LeftLeg.MoveTo(0.081*TransporterBody.Width, 0.858*TransporterBody.Height, aDuration, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightLeg.MoveTo(0.768*TransporterBody.Width, 0.859*TransporterBody.Height, aDuration, idcSinusoid);
  RightLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Platform.MoveTo(-0.712*LeftActuator.Width, -0.384*LeftActuator.Height, aDuration, idcSinusoid);
  Platform.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Platform.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftActuator.MoveTo(0.271*TransporterBody.Width, 0.599*TransporterBody.Height, aDuration, idcSinusoid);
  LeftActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightActuator.MoveTo(0.686*TransporterBody.Width, 0.601*TransporterBody.Height, aDuration, idcSinusoid);
  RightActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTransporterWK510.Posture_HalfPlatformOut(aDuration: single);
begin
  LeftLeg.MoveTo(0.081*TransporterBody.Width, 0.858*TransporterBody.Height, aDuration, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightLeg.MoveTo(0.768*TransporterBody.Width, 0.859*TransporterBody.Height, aDuration, idcSinusoid);
  RightLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Platform.MoveTo(-0.712*LeftActuator.Width, -0.434*LeftActuator.Height, aDuration, idcSinusoid);
  Platform.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Platform.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftActuator.MoveTo(0.271*TransporterBody.Width, 0.948*TransporterBody.Height, aDuration, idcSinusoid);
  LeftActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightActuator.MoveTo(0.686*TransporterBody.Width, 0.950*TransporterBody.Height, aDuration, idcSinusoid);
  RightActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTransporterWK510.Posture_InAir(aDuration: single);
begin
  LeftLeg.MoveTo(0.081*TransporterBody.Width, 0.203*TransporterBody.Height, aDuration, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightLeg.MoveTo(0.768*TransporterBody.Width, 0.204*TransporterBody.Height, aDuration, idcSinusoid);
  RightLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Platform.MoveTo(-0.712*LeftActuator.Width, -0.384*LeftActuator.Height, aDuration, idcSinusoid);
  Platform.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Platform.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftActuator.MoveTo(0.271*TransporterBody.Width, 0.599*TransporterBody.Height, aDuration, idcSinusoid);
  LeftActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightActuator.MoveTo(0.686*TransporterBody.Width, 0.601*TransporterBody.Height, aDuration, idcSinusoid);
  RightActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

end.
