unit u_submarine;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

type

TSubState = (subsUndefined, subsIdle);

{ TSubmarine }

TSubmarine = class(TSprite)
public
  class var FAdditionalScale: single;
  class var texSubmarine, texSubmarineDoor, texSubmarineArmPart, texSubmarineLeftPlier, texSubmarineRightPlier, 
  texSubmarineBG, texLeftTrapdoor, texRightTrapdoor: PTexture;
private
  SubmarineDoor: TSprite;
  SubmarineArmPart: TSprite;
  SubmarineArmPart2: TSprite;
  SubmarineArmPart3: TSprite;
  SubmarineArmPart4: TSprite;
  SubmarineArmPart5: TSprite;
  SubmarineLeftPlier: TSprite;
  SubmarineRightPlier: TSprite;
  SubmarineBG, FLeftTrapdoor, FRightTrapdoor: TSprite;
private
  FFloating: boolean;
  FFloatingYOrigin: single;
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
  procedure Posture_ArmDeployed(aDuration: single=0.5);
  procedure Posture_ArmAboveTank(aDuration: single=0.5);
  procedure Posture_OpenDoor(aDuration: single=0.5);
  procedure OpenTrapDoor(aDuration: single=0.5);
  procedure CloseTrapDoor(aDuration: single=0.5);
public
  procedure StartFloating;
  procedure StopFloating;
end;

implementation

uses u_common, u_app;

{ TSubmarine }

class procedure TSubmarine.LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single);
var path: string;
begin
  FAdditionalScale := aAdditionalScale;
  path := FolderSpriteGameMermaidsPort;
  texSubmarine := aAtlas.AddFromSVG(path+'Submarine.svg', ScaleW(192), -1);
  texSubmarineDoor := aAtlas.AddFromSVG(path+'SubmarineDoor.svg', ScaleW(49), -1);
  texSubmarineArmPart := aAtlas.AddFromSVG(path+'SubmarineArmPart.svg', ScaleW(43), -1);
  texSubmarineLeftPlier := aAtlas.AddFromSVG(path+'SubmarineLeftPlier.svg', ScaleW(11), -1);
  texSubmarineRightPlier := aAtlas.AddFromSVG(path+'SubmarineRightPlier.svg', ScaleW(11), -1);
  texSubmarineBG := aAtlas.AddFromSVG(path+'SubmarineBG.svg', ScaleW(54), -1);
  texLeftTrapdoor := aAtlas.AddFromSVG(path+'SubmarineLeftTrapdoor.svg', ScaleW(32), -1);
  texRightTrapdoor := aAtlas.AddFromSVG(path+'SubmarineRightTrapdoor.svg', ScaleW(32), -1);
end;

procedure TSubmarine.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  SubmarineDoor.FlipH := AValue;
  SubmarineArmPart.FlipH := AValue;
  SubmarineArmPart2.FlipH := AValue;
  SubmarineArmPart3.FlipH := AValue;
  SubmarineArmPart4.FlipH := AValue;
  SubmarineArmPart5.FlipH := AValue;
  SubmarineLeftPlier.FlipH := AValue;
  SubmarineRightPlier.FlipH := AValue;
  SubmarineBG.FlipH := AValue;
  FLeftTrapdoor.FlipH := AValue;
  FRightTrapdoor.FlipH := AValue;
end;

procedure TSubmarine.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  SubmarineDoor.FlipV := AValue;
  SubmarineArmPart.FlipV := AValue;
  SubmarineArmPart2.FlipV := AValue;
  SubmarineArmPart3.FlipV := AValue;
  SubmarineArmPart4.FlipV := AValue;
  SubmarineArmPart5.FlipV := AValue;
  SubmarineLeftPlier.FlipV := AValue;
  SubmarineRightPlier.FlipV := AValue;
  SubmarineBG.FlipV := AValue;
  FLeftTrapdoor.FlipV := AValue;
  FRightTrapdoor.FlipV := AValue;
end;

constructor TSubmarine.Create(aLayerIndex: integer);
begin
  inherited Create(texSubmarine, False);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);

  SubmarineDoor := TSprite.Create(texSubmarineDoor, False);
  with SubmarineDoor do begin
    SetChildOf(Self, 0);
    SetCoordinate(0.359*Self.Width, 0.039*Self.Height);
    ApplySymmetryWhenFlip := True;
  end;

  SubmarineArmPart := TSprite.Create(texSubmarineArmPart, False);
  with SubmarineArmPart do begin
    SetChildOf(Self, 1);
    SetCoordinate(0.507*Self.Width, 0.112*Self.Height);
    Pivot := PointF(0.96, 0.53);
    Angle.Value := 105.31;
    ApplySymmetryWhenFlip := True;
  end;

  SubmarineArmPart2 := TSprite.Create(texSubmarineArmPart, False);
  with SubmarineArmPart2 do begin
    SetChildOf(SubmarineArmPart, 0);
    SetCoordinate(0.005*SubmarineArmPart.Width, -0.029*SubmarineArmPart.Height);
    Pivot := PointF(0.07, 0.47);
    Angle.Value := -107.58;
    ApplySymmetryWhenFlip := True;
  end;

  SubmarineArmPart3 := TSprite.Create(texSubmarineArmPart, False);
  with SubmarineArmPart3 do begin
    SetChildOf(SubmarineArmPart2, 0);
    SetCoordinate(0.855*SubmarineArmPart2.Width, -0.001*SubmarineArmPart2.Height);
    Pivot := PointF(0.07, 0.51);
    Angle.Value := -35.63;
    ApplySymmetryWhenFlip := True;
  end;

  SubmarineArmPart4 := TSprite.Create(texSubmarineArmPart, False);
  with SubmarineArmPart4 do begin
    SetChildOf(SubmarineArmPart3, 0);
    SetCoordinate(0.865*SubmarineArmPart3.Width, 0);
    Pivot := PointF(0.08, 0.53);
    Angle.Value := 46.71;
    ApplySymmetryWhenFlip := True;
  end;

  SubmarineArmPart5 := TSprite.Create(texSubmarineArmPart, False);
  with SubmarineArmPart5 do begin
    SetChildOf(SubmarineArmPart4, 0);
    SetCoordinate(0.856*SubmarineArmPart4.Width, 0);
    Pivot := PointF(0.08, 0.53);
    Angle.Value := 12.57;
    ApplySymmetryWhenFlip := True;
  end;

  SubmarineLeftPlier := TSprite.Create(texSubmarineLeftPlier, False);
  with SubmarineLeftPlier do begin
    SetChildOf(SubmarineArmPart5, 0);
    SetCoordinate(0.799*SubmarineArmPart5.Width, -2.456*SubmarineArmPart5.Height);
    Pivot := PointF(0.60, 0.90);
    Angle.Value := -284.27;
    ApplySymmetryWhenFlip := True;
  end;

  SubmarineRightPlier := TSprite.Create(texSubmarineRightPlier, False);
  with SubmarineRightPlier do begin
    SetChildOf(SubmarineArmPart5, 0);
    SetCoordinate(0.823*SubmarineArmPart5.Width, -1.943*SubmarineArmPart5.Height);
    Pivot := PointF(0.47, 0.92);
    Angle.Value := -241.32;
    ApplySymmetryWhenFlip := True;
  end;

  SubmarineBG := TSprite.Create(texSubmarineBG, False);
  with SubmarineBG do begin
    SetChildOf(Self, -5);
    SetCoordinate(0.343*Self.Width,0.03*Self.Height);
    ApplySymmetryWhenFlip := True;
  end;

  FLeftTrapdoor := TSprite.Create(texLeftTrapdoor, False);
  with FLeftTrapdoor do begin
    SetChildOf(Self, -6);
    SetCoordinate(0.365*Self.Width, -0.136*Self.Height);
    Pivot := PointF(1.0, 1.88);
    ApplySymmetryWhenFlip := True;
  end;

  FRightTrapdoor := TSprite.Create(texRightTrapdoor, False);
  with FRightTrapdoor do begin
    SetChildOf(Self, -6);
    SetCoordinate(0.525*Self.Width, -0.136*Self.Height);
    Pivot := PointF(0.0, 1.88);
    ApplySymmetryWhenFlip := True;
  end;

  // Collision body
  CollisionBody.AddPolygon([PointF(0.390*Width, 0.051*Height)*FAdditionalScale, PointF(0.467*Width, 0.000*Height)*FAdditionalScale,
    PointF(0.529*Width, -0.000*Height)*FAdditionalScale, PointF(0.606*Width, 0.057*Height)*FAdditionalScale,
    PointF(0.648*Width, 0.118*Height)*FAdditionalScale, PointF(0.685*Width, 0.119*Height)*FAdditionalScale,
    PointF(0.687*Width, 0.152*Height)*FAdditionalScale, PointF(0.803*Width, 0.152*Height)*FAdditionalScale,
    PointF(0.872*Width, 0.171*Height)*FAdditionalScale, PointF(0.962*Width, 0.256*Height)*FAdditionalScale,
    PointF(0.996*Width, 0.357*Height)*FAdditionalScale, PointF(1.001*Width, 0.468*Height)*FAdditionalScale,
    PointF(0.981*Width, 0.559*Height)*FAdditionalScale, PointF(0.945*Width, 0.628*Height)*FAdditionalScale,
    PointF(0.894*Width, 0.683*Height)*FAdditionalScale, PointF(0.857*Width, 0.706*Height)*FAdditionalScale,
    PointF(0.889*Width, 0.755*Height)*FAdditionalScale, PointF(0.902*Width, 0.833*Height)*FAdditionalScale,
    PointF(0.887*Width, 0.918*Height)*FAdditionalScale, PointF(0.825*Width, 0.960*Height)*FAdditionalScale,
    PointF(0.596*Width, 0.960*Height)*FAdditionalScale, PointF(0.162*Width, 0.959*Height)*FAdditionalScale,
    PointF(0.143*Width, 0.791*Height)*FAdditionalScale, PointF(0.076*Width, 0.784*Height)*FAdditionalScale,
    PointF(0.079*Width, 0.471*Height)*FAdditionalScale, PointF(0.128*Width, 0.466*Height)*FAdditionalScale,
    PointF(0.130*Width, 0.370*Height)*FAdditionalScale, PointF(0.012*Width, 0.263*Height)*FAdditionalScale,
    PointF(-0.001*Width, 0.175*Height)*FAdditionalScale, PointF(0.297*Width, 0.171*Height)*FAdditionalScale,
    PointF(0.312*Width, 0.123*Height)*FAdditionalScale, PointF(0.343*Width, 0.116*Height)*FAdditionalScale,
    PointF(0.390*Width, 0.051*Height)*FAdditionalScale]);
end;

procedure TSubmarine.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // ANIM FLOATING
    0: begin
      if not FFloating then exit;
      d := Random+1.0;
      Angle.ChangeTo(Random*4-2.0, d, idcSinusoid);
      PostMessage(0, d);
    end;
    2: begin
      if not FFloating then exit;
      d := Random+1.0;
      Y.ChangeTo(FFloatingYOrigin+ScaleW(Random(10)-5), d, idcSinusoid);
      PostMessage(2, d);
    end;
  end;//case
end;

procedure TSubmarine.Posture_Idle(aDuration: single);
begin
  SubmarineDoor.MoveTo(0.363*Width, 0.039*Height, aDuration, idcSinusoid);
  SubmarineDoor.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SubmarineDoor.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart.MoveTo(0.507*Width, 0.0*Height, aDuration, idcSinusoid);   //0.112
  SubmarineArmPart.Angle.ChangeTo(0.032, aDuration, idcSinusoid);
  SubmarineArmPart.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart2.MoveTo(0.005*SubmarineArmPart.Width, -0.029*SubmarineArmPart.Height, aDuration, idcSinusoid);
  SubmarineArmPart2.Angle.ChangeTo(-0.343, aDuration, idcSinusoid);
  SubmarineArmPart2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart3.MoveTo(0.855*SubmarineArmPart2.Width, -0.001*SubmarineArmPart2.Height, aDuration, idcSinusoid);
  SubmarineArmPart3.Angle.ChangeTo(-179.453, aDuration, idcSinusoid);
  SubmarineArmPart3.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart4.MoveTo(0.865*SubmarineArmPart3.Width, 0, aDuration, idcSinusoid);
  SubmarineArmPart4.Angle.ChangeTo(179.303, aDuration, idcSinusoid);
  SubmarineArmPart4.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart5.MoveTo(0.856*SubmarineArmPart4.Width, 0, aDuration, idcSinusoid);
  SubmarineArmPart5.Angle.ChangeTo(-177.193, aDuration, idcSinusoid);
  SubmarineArmPart5.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineLeftPlier.MoveTo(0.799*SubmarineArmPart5.Width, -2.456*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  SubmarineLeftPlier.Angle.ChangeTo(92.635, aDuration, idcSinusoid);
  SubmarineLeftPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineRightPlier.MoveTo(0.823*SubmarineArmPart5.Width, -1.943*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  SubmarineRightPlier.Angle.ChangeTo(96.089, aDuration, idcSinusoid);
  SubmarineRightPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TSubmarine.Posture_ArmDeployed(aDuration: single);
begin
  SubmarineArmPart.MoveTo(0.507*Width, 0.0*Height, aDuration, idcSinusoid);
  SubmarineArmPart.Angle.ChangeTo(145.669, aDuration, idcSinusoid);
  SubmarineArmPart.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart2.MoveTo(0.005*SubmarineArmPart.Width, -0.029*SubmarineArmPart.Height, aDuration, idcSinusoid);
  SubmarineArmPart2.Angle.ChangeTo(-114.857, aDuration, idcSinusoid);
  SubmarineArmPart2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart3.MoveTo(0.855*SubmarineArmPart2.Width, -0.001*SubmarineArmPart2.Height, aDuration, idcSinusoid);
  SubmarineArmPart3.Angle.ChangeTo(-27.024, aDuration, idcSinusoid);
  SubmarineArmPart3.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart4.MoveTo(0.865*SubmarineArmPart3.Width, 0, aDuration, idcSinusoid);
  SubmarineArmPart4.Angle.ChangeTo(60.131, aDuration, idcSinusoid);
  SubmarineArmPart4.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart5.MoveTo(0.856*SubmarineArmPart4.Width, 0, aDuration, idcSinusoid);
  SubmarineArmPart5.Angle.ChangeTo(-26.938, aDuration, idcSinusoid);
  SubmarineArmPart5.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineLeftPlier.MoveTo(0.799*SubmarineArmPart5.Width, -2.456*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  SubmarineLeftPlier.Angle.ChangeTo(66.883, aDuration, idcSinusoid);
  SubmarineLeftPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineRightPlier.MoveTo(0.823*SubmarineArmPart5.Width, -1.943*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  SubmarineRightPlier.Angle.ChangeTo(109.868, aDuration, idcSinusoid);
  SubmarineRightPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TSubmarine.Posture_ArmAboveTank(aDuration: single);
begin
  SubmarineArmPart.MoveTo(0.507*Width, 0.0*Height, aDuration, idcSinusoid);
  SubmarineArmPart.Angle.ChangeTo(114.739, aDuration, idcSinusoid);
  SubmarineArmPart.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart2.MoveTo(0.005*SubmarineArmPart.Width, -0.029*SubmarineArmPart.Height, aDuration, idcSinusoid);
  SubmarineArmPart2.Angle.ChangeTo(-198.125, aDuration, idcSinusoid);
  SubmarineArmPart2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart3.MoveTo(0.855*SubmarineArmPart2.Width, -0.001*SubmarineArmPart2.Height, aDuration, idcSinusoid);
  SubmarineArmPart3.Angle.ChangeTo(-56.109, aDuration, idcSinusoid);
  SubmarineArmPart3.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart4.MoveTo(0.865*SubmarineArmPart3.Width, 0, aDuration, idcSinusoid);
  SubmarineArmPart4.Angle.ChangeTo(-64.613, aDuration, idcSinusoid);
  SubmarineArmPart4.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart5.MoveTo(0.856*SubmarineArmPart4.Width, 0, aDuration, idcSinusoid);
  SubmarineArmPart5.Angle.ChangeTo(-64.438, aDuration, idcSinusoid);
  SubmarineArmPart5.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineLeftPlier.MoveTo(0.799*SubmarineArmPart5.Width, -2.456*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  SubmarineLeftPlier.Angle.ChangeTo(66.883, aDuration, idcSinusoid);
  SubmarineLeftPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineRightPlier.MoveTo(0.823*SubmarineArmPart5.Width, -1.943*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  SubmarineRightPlier.Angle.ChangeTo(109.868, aDuration, idcSinusoid);
  SubmarineRightPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TSubmarine.Posture_OpenDoor(aDuration: single);
begin
  SubmarineDoor.MoveTo(0.126*Width, 0.039*Height, aDuration, idcSinusoid);
  SubmarineDoor.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SubmarineDoor.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart.MoveTo(0.507*Width, 0.0*Height, aDuration, idcSinusoid);
  SubmarineArmPart.Angle.ChangeTo(0.032, aDuration, idcSinusoid);
  SubmarineArmPart.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart2.MoveTo(0.005*SubmarineArmPart.Width, -0.029*SubmarineArmPart.Height, aDuration, idcSinusoid);
  SubmarineArmPart2.Angle.ChangeTo(-0.343, aDuration, idcSinusoid);
  SubmarineArmPart2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart3.MoveTo(0.855*SubmarineArmPart2.Width, -0.001*SubmarineArmPart2.Height, aDuration, idcSinusoid);
  SubmarineArmPart3.Angle.ChangeTo(-179.453, aDuration, idcSinusoid);
  SubmarineArmPart3.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart4.MoveTo(0.865*SubmarineArmPart3.Width, 0, aDuration, idcSinusoid);
  SubmarineArmPart4.Angle.ChangeTo(179.303, aDuration, idcSinusoid);
  SubmarineArmPart4.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart5.MoveTo(0.856*SubmarineArmPart4.Width, 0, aDuration, idcSinusoid);
  SubmarineArmPart5.Angle.ChangeTo(-177.193, aDuration, idcSinusoid);
  SubmarineArmPart5.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineLeftPlier.MoveTo(0.799*SubmarineArmPart5.Width, -2.456*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  SubmarineLeftPlier.Angle.ChangeTo(92.635, aDuration, idcSinusoid);
  SubmarineLeftPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineRightPlier.MoveTo(0.823*SubmarineArmPart5.Width, -1.943*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  SubmarineRightPlier.Angle.ChangeTo(96.089, aDuration, idcSinusoid);
  SubmarineRightPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TSubmarine.OpenTrapDoor(aDuration: single);
begin
  FLeftTrapdoor.Angle.ChangeTo(-45, aDuration, idcSinusoid);
  FRightTrapdoor.Angle.ChangeTo(45, aDuration, idcSinusoid);
end;

procedure TSubmarine.CloseTrapDoor(aDuration: single);
begin
  FLeftTrapdoor.Angle.ChangeTo(0, aDuration, idcSinusoid);
  FRightTrapdoor.Angle.ChangeTo(0, aDuration, idcSinusoid);
end;

procedure TSubmarine.StartFloating;
begin
  if FFloating then exit;
  FFloating := True;
  FFloatingYOrigin := Y.Value;
  PostMessage(0);
  PostMessage(2);
end;

procedure TSubmarine.StopFloating;
begin
  FFloating := False;
  Y.ChangeTo(FFloatingYOrigin, 1.0, idcSinusoid);
  Angle.ChangeTo(0, 1.0, idcSinusoid);
end;

end.
