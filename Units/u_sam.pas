unit u_sam;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

type

TSam = class(TSprite)
private
  class var FAdditionalScale: single;
  class var texSamAbdomen, texSamArmLeft, texSamArmRight, texSamHead, texSamLegLeft, 
  texSamLegRight: PTexture;
private
  SamArmLeft: TSprite;
  SamArmRight: TSprite;
  SamHead: TSprite;
  SamLegLeft: TSprite;
  SamLegRight: TSprite;
  FScratchCount, FLastMove: integer;
public
  // aAdditionalScale is used to scale the collision bodies
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single=1.0);
  constructor Create(aLayerIndex: integer=-1);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
public
  procedure Posture_Idle(aDuration: single=0.5);
  procedure Posture_ArmOpen(aDuration: single=0.5);
  procedure Posture_LeftBend(aDuration: single=0.5);
  procedure Posture_ScratchLeftArm(aDuration: single=0.5);
  procedure Posture_ScratchLeftArm2(aDuration: single=0.5);
  procedure Posture_RightBend(aDuration: single=0.5);
  procedure Posture_LeftLeg(aDuration: single=0.5);
end;

implementation
uses u_common, u_app;

{ TSam }

class procedure TSam.LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single);
var dataFolder: string;
begin
  FAdditionalScale := aAdditionalScale;
  dataFolder := FScene.App.DataFolder;
  texSamAbdomen := aAtlas.AddFromSVG(dataFolder+'Sprites\Sam\SamAbdomen.svg', ScaleW(62), -1);
  texSamArmLeft := aAtlas.AddFromSVG(dataFolder+'Sprites\Sam\SamArmLeft.svg', -1, ScaleH(62));
  texSamArmRight := aAtlas.AddFromSVG(dataFolder+'Sprites\Sam\SamArmRight.svg', -1, ScaleH(62));
  texSamHead := aAtlas.AddFromSVG(dataFolder+'Sprites\Sam\SamHead.svg', ScaleW(103), -1);
  texSamLegLeft := aAtlas.AddFromSVG(dataFolder+'Sprites\Sam\SamLegLeft.svg', ScaleW(59), -1);
  texSamLegRight := aAtlas.AddFromSVG(dataFolder+'Sprites\Sam\SamLegRight.svg', ScaleW(60), -1);
end;

constructor TSam.Create(aLayerIndex: integer);
begin
  inherited Create(texSamAbdomen, False);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);
  Pivot := PointF(0.50, 0.99);

  SamArmLeft := TSprite.Create(texSamArmLeft, False);
  with SamArmLeft do begin
    SetChildOf(Self, 1);
    SetCoordinate(0.545*Width, 0.334*Height);
    Pivot := PointF(0.44, 0.11);
  end;

  SamArmRight := TSprite.Create(texSamArmRight, False);
  with SamArmRight do begin
    SetChildOf(Self, 1);
    SetCoordinate(-0.013*Width, 0.331*Height);
    Pivot := PointF(0.54, 0.10);
  end;

  SamHead := TSprite.Create(texSamHead, False);
  with SamHead do begin
    SetChildOf(Self, 0);
    SetCoordinate(-0.348*Width, -0.950*Height);
    Pivot := PointF(0.50, 0.99);
  end;

  SamLegLeft := TSprite.Create(texSamLegLeft, False);
  with SamLegLeft do begin
    SetChildOf(Self, -1);
    SetCoordinate(0.549*Width, 0.877*Height);
    Pivot := PointF(0.15, 0.03);
  end;

  SamLegRight := TSprite.Create(texSamLegRight, False);
  with SamLegRight do begin
    SetChildOf(Self, -1);
    SetCoordinate(-0.509*Width, 0.873*Height);
    Pivot := PointF(0.83, 0.04);
  end;

  Posture_Idle(0);
  PostMessage(0, 3.0); // anim
  PostMessage(100); // anim head
end;

procedure TSam.ProcessMessage(UserValue: TUserMessageValue);
var mvt: integer;
  d: Extended;
begin
  case UserValue of
    // SAM ANIMATION
    0: begin
      repeat
        mvt := Random(5);
      until mvt <> FLastMove;
      FLastMove := mvt;
      case mvt of
       0: PostMessage(20);
       1: PostMessage(30);
       2: PostMessage(40);
       3: PostMessage(50);
       4: PostMessage(60);
      end;
    end;

    // arm open
    20: begin
      Posture_ArmOpen(0.4);
      PostMessage(25, 1.0);
    end;
    25: begin
      Posture_Idle(0.5);
      PostMessage(0, 2+Random*4);
    end;
    // scratch left arm
    30: begin
      Posture_ScratchLeftArm(0.5);
      FScratchCount := 0;
      PostMessage(31, 0.5);
    end;
    31: begin
      Posture_ScratchLeftArm2(0.1);
      PostMessage(32, 0.1);
    end;
    32: begin
      Posture_ScratchLeftArm(0.1);
      inc(FScratchCount);
      if FScratchCount > 6 then PostMessage(25)
        else PostMessage(31, 0.1);
    end;
    // left leg
    40: begin
      Posture_LeftLeg(0.3);
      PostMessage(25, 0.3);
    end;
    // left bend
    50: begin
      Posture_LeftBend(0.5);
      PostMessage(25, 0.5);
    end;
    // right bend
    60: begin
      Posture_RightBend(0.5);
      PostMessage(25, 0.5);
    end;

    // anim head
    100: begin
      d := 1*Random+0.5;
      SamHead.Angle.ChangeTo(Random*6-3, d, idcSinusoid);
      PostMessage(100, d);
    end;
  end;//case
end;

procedure TSam.Posture_Idle(aDuration: single);
begin
  Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamArmLeft.MoveTo(0.545*Width, 0.334*Height, aDuration, idcSinusoid);
  SamArmLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamArmLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamArmRight.MoveTo(-0.013*Width, 0.331*Height, aDuration, idcSinusoid);
  SamArmRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamArmRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamHead.MoveTo(-0.348*Width, -0.950*Height, aDuration, idcSinusoid);
  SamHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegLeft.MoveTo(0.549*Width, 0.877*Height, aDuration, idcSinusoid);
  SamLegLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamLegLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegRight.MoveTo(-0.509*Width, 0.873*Height, aDuration, idcSinusoid);
  SamLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TSam.Posture_ArmOpen(aDuration: single);
begin
  SamArmLeft.MoveTo(0.545*Width, 0.334*Height, aDuration, idcSinusoid);
  SamArmLeft.Angle.ChangeTo(-35.413, aDuration, idcSinusoid);
  SamArmLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamArmRight.MoveTo(-0.013*Width, 0.331*Height, aDuration, idcSinusoid);
  SamArmRight.Angle.ChangeTo(33.726, aDuration, idcSinusoid);
  SamArmRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamHead.MoveTo(-0.348*Width, -0.950*Height, aDuration, idcSinusoid);
  SamHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegLeft.MoveTo(0.549*Width, 0.877*Height, aDuration, idcSinusoid);
  SamLegLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamLegLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegRight.MoveTo(-0.509*Width, 0.873*Height, aDuration, idcSinusoid);
  SamLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TSam.Posture_LeftBend(aDuration: single);
begin
  Angle.ChangeTo(-3, aDuration, idcSinusoid);
  SamArmLeft.MoveTo(0.545*Width, 0.334*Height, aDuration, idcSinusoid);
  SamArmLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamArmLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamArmRight.MoveTo(-0.013*Width, 0.331*Height, aDuration, idcSinusoid);
  SamArmRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamArmRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamHead.MoveTo(-0.348*Width, -0.950*Height, aDuration, idcSinusoid);
  SamHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegLeft.MoveTo(0.549*Width, 0.877*Height, aDuration, idcSinusoid);
  SamLegLeft.Angle.ChangeTo(8.352, aDuration, idcSinusoid);
  SamLegLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegRight.MoveTo(-0.509*Width, 0.873*Height, aDuration, idcSinusoid);
  SamLegRight.Angle.ChangeTo(4.081, aDuration, idcSinusoid);
  SamLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TSam.Posture_ScratchLeftArm(aDuration: single);
begin
  SamArmLeft.MoveTo(0.545*Width, 0.334*Height, aDuration, idcSinusoid);
  SamArmLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamArmLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamArmRight.MoveTo(-0.013*Width, 0.331*Height, aDuration, idcSinusoid);
  SamArmRight.Angle.ChangeTo(-66.926, aDuration, idcSinusoid);
  SamArmRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamHead.MoveTo(-0.348*Width, -0.950*Height, aDuration, idcSinusoid);
  SamHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegLeft.MoveTo(0.549*Width, 0.877*Height, aDuration, idcSinusoid);
  SamLegLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamLegLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegRight.MoveTo(-0.509*Width, 0.873*Height, aDuration, idcSinusoid);
  SamLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TSam.Posture_ScratchLeftArm2(aDuration: single);
begin
  SamArmLeft.MoveTo(0.545*Width, 0.334*Height, aDuration, idcSinusoid);
  SamArmLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamArmLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamArmRight.MoveTo(-0.013*Width, 0.331*Height, aDuration, idcSinusoid);
  SamArmRight.Angle.ChangeTo(-63.363, aDuration, idcSinusoid);
  SamArmRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamHead.MoveTo(-0.348*Width, -0.950*Height, aDuration, idcSinusoid);
  SamHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegLeft.MoveTo(0.549*Width, 0.877*Height, aDuration, idcSinusoid);
  SamLegLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamLegLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegRight.MoveTo(-0.509*Width, 0.873*Height, aDuration, idcSinusoid);
  SamLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TSam.Posture_RightBend(aDuration: single);
begin
  Angle.ChangeTo(3, aDuration, idcSinusoid);
  SamArmLeft.MoveTo(0.545*Width, 0.334*Height, aDuration, idcSinusoid);
  SamArmLeft.Angle.ChangeTo(-4.013, aDuration, idcSinusoid);
  SamArmLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamArmRight.MoveTo(-0.013*Width, 0.331*Height, aDuration, idcSinusoid);
  SamArmRight.Angle.ChangeTo(-3.672, aDuration, idcSinusoid);
  SamArmRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamHead.MoveTo(-0.348*Width, -0.950*Height, aDuration, idcSinusoid);
  SamHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegLeft.MoveTo(0.549*Width, 0.877*Height, aDuration, idcSinusoid);
  SamLegLeft.Angle.ChangeTo(-5.332, aDuration, idcSinusoid);
  SamLegLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegRight.MoveTo(-0.509*Width, 0.873*Height, aDuration, idcSinusoid);
  SamLegRight.Angle.ChangeTo(-5.451, aDuration, idcSinusoid);
  SamLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TSam.Posture_LeftLeg(aDuration: single);
begin
  SamArmLeft.MoveTo(0.545*Width, 0.334*Height, aDuration, idcSinusoid);
  SamArmLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamArmLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamArmRight.MoveTo(-0.013*Width, 0.331*Height, aDuration, idcSinusoid);
  SamArmRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamArmRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamHead.MoveTo(-0.348*Width, -0.950*Height, aDuration, idcSinusoid);
  SamHead.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamHead.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegLeft.MoveTo(0.534*Width, 0.791*Height, aDuration, idcSinusoid);
  SamLegLeft.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamLegLeft.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SamLegRight.MoveTo(-0.509*Width, 0.873*Height, aDuration, idcSinusoid);
  SamLegRight.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SamLegRight.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

end.
