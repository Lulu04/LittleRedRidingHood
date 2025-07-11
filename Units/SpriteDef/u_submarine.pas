unit u_submarine;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

type

TSubState = (subsIdle,
             subsDigging, subsWaitAfterDig, subsHarvestingDebris,
             subsBuildMissile, subsMissileReadyToLaunch, subsMissileLaunched, subsHideMissileRamp,
             subsContactWithMine);

{ TSubmarine }

TSubmarine = class(TSprite)
public
  class var FAdditionalScale: single;
  class var texSubmarine, texSubmarineDoor, texSubmarineArmPart, texSubmarineLeftPlier, texSubmarineRightPlier, 
  texSubmarineBG, texLeftTrapdoor, texRightTrapdoor, texHarvestDebris, texMissileRamp, texMissile: PTexture;
private
  SubmarineDoor: TSprite;
  SubmarineArmPart: TSprite;
  SubmarineArmPart2: TSprite;
  SubmarineArmPart3: TSprite;
  SubmarineArmPart4: TSprite;
  SubmarineArmPart5: TSprite;
  SubmarineBG, FLeftTrapdoor, FRightTrapdoor: TSprite;
private
  FFloating: boolean;
  FFloatingYOrigin: single;
  FState: TSubState;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  LeftPlier, RightPlier: TSprite;
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
  procedure Posture_DigForward(aDuration: single=0.5);
  procedure Posture_DigGround(aDuration: single=0.5);
  procedure OpenPlier(aDuration: single=0.5);
  procedure ClosePlier(aDuration: single=0.5);
public  // floating on water
  procedure StartFloating;
  procedure StopFloating;
private
  FHarvestDebrisColor: TBGRAPixel;
  FExplodeAnimDone: boolean;
  procedure SetState(AValue: TSubState);
public
  procedure StartDigAnimation;
  procedure StopDigAnimation;
  procedure StartHarvestDebrisAnimation(aDebrisColor: TBGRAPixel);
  procedure StopHarvestDebrisAnimation;
public
  FMissileRamp: TSprite;
  procedure StartShowMissileAnimation;
  procedure HideMissileRamp;
public
  procedure ProcessContactWithMine;
  property ExplodeAnimDone: boolean read FExplodeAnimDone;
  property State: TSubState read FState write SetState;
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
  texHarvestDebris := aAtlas.AddFromSVG(path+'SubmarineHarvestDebris.svg', ScaleW(17), -1);
  texMissileRamp := aAtlas.AddFromSVG(path+'SubmarineMissileRamp.svg', ScaleW(31), -1);
  texMissile := aAtlas.AddFromSVG(path+'SubmarineMissile.svg', ScaleW(30), -1);
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
  LeftPlier.FlipH := AValue;
  RightPlier.FlipH := AValue;
  SubmarineBG.FlipH := AValue;
  FLeftTrapdoor.FlipH := AValue;
  FRightTrapdoor.FlipH := AValue;
  FMissileRamp.FlipH := AValue;
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
  LeftPlier.FlipV := AValue;
  RightPlier.FlipV := AValue;
  SubmarineBG.FlipV := AValue;
  FLeftTrapdoor.FlipV := AValue;
  FRightTrapdoor.FlipV := AValue;
  FMissileRamp.FlipV := AValue;
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

  LeftPlier := TSprite.Create(texSubmarineLeftPlier, False);
  with LeftPlier do begin
    SetChildOf(SubmarineArmPart5, 0);
    SetCoordinate(0.799*SubmarineArmPart5.Width, -2.456*SubmarineArmPart5.Height);
    Pivot := PointF(0.60, 0.90);
    Angle.Value := -284.27;
    ApplySymmetryWhenFlip := True;
    CollisionBody.AddPolygon([PointF(0, 0), PointF(Width, 0), PointF(Width, Height), PointF(0, Height)]);
  end;

  RightPlier := TSprite.Create(texSubmarineRightPlier, False);
  with RightPlier do begin
    SetChildOf(SubmarineArmPart5, 0);
    SetCoordinate(0.823*SubmarineArmPart5.Width, -1.943*SubmarineArmPart5.Height);
    Pivot := PointF(0.47, 0.92);
    Angle.Value := -241.32;
    ApplySymmetryWhenFlip := True;
    CollisionBody.AddPolygon([PointF(0, 0), PointF(Width, 0), PointF(Width, Height), PointF(0, Height)]);
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

  FMissileRamp := TSprite.Create(texMissileRamp, False);
  AddChild(FMissileRamp,-7);
  FMissileRamp.SetCoordinate(ScaleW(86), ScaleH(17));
  FMissileRamp.ApplySymmetryWhenFlip := True;

  // Collision body
  CollisionBody.AddLine(PointF(0.346*Width, 0.028*Height)*FAdditionalScale, PointF(0.073*Width, 0.050*Height)*FAdditionalScale);
  CollisionBody.AddLine(PointF(0.730*Width, 0.015*Height)*FAdditionalScale, PointF(0.514*Width, -0.109*Height)*FAdditionalScale);
  CollisionBody.AddLine(PointF(-0.001*Width, 0.058*Height)*FAdditionalScale, PointF(0.080*Width, 0.406*Height)*FAdditionalScale);
  CollisionBody.AddLine(PointF(0.075*Width, 0.745*Height)*FAdditionalScale, PointF(0.168*Width, 0.923*Height)*FAdditionalScale);
  CollisionBody.AddLine(PointF(0.353*Width, 0.940*Height)*FAdditionalScale, PointF(0.662*Width, 0.940*Height)*FAdditionalScale);
  CollisionBody.AddLine(PointF(0.831*Width, 0.949*Height)*FAdditionalScale, PointF(0.901*Width, 0.814*Height)*FAdditionalScale);
  CollisionBody.AddLine(PointF(0.996*Width, 0.384*Height)*FAdditionalScale, PointF(0.901*Width, 0.623*Height)*FAdditionalScale);
  CollisionBody.AddLine(PointF(0.991*Width, 0.284*Height)*FAdditionalScale, PointF(0.893*Width, 0.093*Height)*FAdditionalScale);
end;

procedure TSubmarine.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
  o: TSprite;
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

    // anim dig
    100: begin
      if State <> subsDigging then exit;
      RightPlier.Angle.ChangeTo(120, 0.1, idcSinusoid);
      LeftPlier.Angle.ChangeTo(60, 0.1, idcSinusoid);
      PostMessage(105, 0.1);
    end;
    105: begin
      if State <> subsDigging then exit;
      RightPlier.Angle.ChangeTo(80, 0.1, idcSinusoid);
      LeftPlier.Angle.ChangeTo(80, 0.1, idcSinusoid);
      PostMessage(100, 0.1);
    end;
    110: begin
      if State <> subsDigging then exit;
      SubmarineArmPart4.Angle.Value := SubmarineArmPart4.Angle.Value-6;
      PostMessage(115, 0.05);
    end;
    115: begin
      if State <> subsDigging then exit;
      SubmarineArmPart4.Angle.Value := SubmarineArmPart4.Angle.Value+6;
      PostMessage(110, 0.05);
    end;

    // anim harvest debris fall into the trap door
    200: begin
      if State <> subsHarvestingDebris then exit;
      o := TSprite.Create(texHarvestDebris, False);
      AddChild(o, -1);
      o.Angle.Value := Random*360;
      o.SetCenterCoordinate(Width*0.5, -Height*0.2);
      o.Y.ChangeTo(o.Y.Value + Height*0.5, 1.0, idcDrop);
      o.KillDefered(1.0);
      o.Tint.Value := FHarvestDebrisColor;
      PostMessage(200, 0.3);
    end;

    // show missile animation
    300: begin
      OpenTrapDoor(0.5);
      PostMessage(305, 0.75);
    end;
    305: begin
      FMissileRamp.Y.ChangeTo(ScaleH(1)-FMissileRamp.Height, 1.0, idcSinusoid);
      PostMessage(310, 1.0);
    end;
    310: begin
      State := subsMissileReadyToLaunch;
    end;

    // hide missile ramp animation
    350: begin
      FMissileRamp.Y.ChangeTo(ScaleH(17), 1.0, idcSinusoid);
      PostMessage(355, 1.0);
    end;
    355: begin
      CloseTrapDoor(0.5);
      PostMessage(360, 0.5);
    end;
    360: State := subsIdle;

    // contact with mine
    400: begin
      Scale.ChangeTo(PointF(3,3), 2.0);
      Angle.ChangeTo(-360*3, 2.0);
      PostMessage(410, 1.5);
    end;
    410: begin
      Opacity.ChangeTo(0, 0.5);
      PostMessage(415, 1.0);
    end;
    415: FExplodeAnimDone := True;
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
  LeftPlier.MoveTo(0.799*SubmarineArmPart5.Width, -2.456*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  LeftPlier.Angle.ChangeTo(92.635, aDuration, idcSinusoid);
  LeftPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightPlier.MoveTo(0.823*SubmarineArmPart5.Width, -1.943*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  RightPlier.Angle.ChangeTo(96.089, aDuration, idcSinusoid);
  RightPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
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
  LeftPlier.MoveTo(0.799*SubmarineArmPart5.Width, -2.456*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  LeftPlier.Angle.ChangeTo(66.883, aDuration, idcSinusoid);
  LeftPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightPlier.MoveTo(0.823*SubmarineArmPart5.Width, -1.943*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  RightPlier.Angle.ChangeTo(109.868, aDuration, idcSinusoid);
  RightPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
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
  LeftPlier.MoveTo(0.799*SubmarineArmPart5.Width, -2.456*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  LeftPlier.Angle.ChangeTo(80, aDuration, idcSinusoid);
  LeftPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightPlier.MoveTo(0.823*SubmarineArmPart5.Width, -1.943*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  RightPlier.Angle.ChangeTo(80, aDuration, idcSinusoid);
  RightPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
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
  LeftPlier.MoveTo(0.799*SubmarineArmPart5.Width, -2.456*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  LeftPlier.Angle.ChangeTo(92.635, aDuration, idcSinusoid);
  LeftPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightPlier.MoveTo(0.823*SubmarineArmPart5.Width, -1.943*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  RightPlier.Angle.ChangeTo(96.089, aDuration, idcSinusoid);
  RightPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
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

procedure TSubmarine.Posture_DigForward(aDuration: single);
begin
  SubmarineArmPart.MoveTo(0.498*Width, 0.035*Height, aDuration, idcSinusoid);
  SubmarineArmPart.Angle.ChangeTo(145.669, aDuration, idcSinusoid);
  SubmarineArmPart.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart2.MoveTo(0.005*SubmarineArmPart.Width, -0.029*SubmarineArmPart.Height, aDuration, idcSinusoid);
  SubmarineArmPart2.Angle.ChangeTo(-161.621, aDuration, idcSinusoid);
  SubmarineArmPart2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart3.MoveTo(0.855*SubmarineArmPart2.Width, -0.001*SubmarineArmPart2.Height, aDuration, idcSinusoid);
  SubmarineArmPart3.Angle.ChangeTo(73.431, aDuration, idcSinusoid);
  SubmarineArmPart3.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart4.MoveTo(0.865*SubmarineArmPart3.Width, 0, aDuration, idcSinusoid);
  SubmarineArmPart4.Angle.ChangeTo(35, aDuration, idcSinusoid);
  SubmarineArmPart4.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart5.MoveTo(0.856*SubmarineArmPart4.Width, 0, aDuration, idcSinusoid);
  SubmarineArmPart5.Angle.ChangeTo(-91, aDuration, idcSinusoid);
  SubmarineArmPart5.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftPlier.MoveTo(0.799*SubmarineArmPart5.Width, -2.456*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  LeftPlier.Angle.ChangeTo(66.883, aDuration, idcSinusoid);
  LeftPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightPlier.MoveTo(0.823*SubmarineArmPart5.Width, -1.943*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  RightPlier.Angle.ChangeTo(109.868, aDuration, idcSinusoid);
  RightPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TSubmarine.Posture_DigGround(aDuration: single);
begin
  SubmarineArmPart.MoveTo(0.498*Width, 0.035*Height, aDuration, idcSinusoid);
  SubmarineArmPart.Angle.ChangeTo(174.128, aDuration, idcSinusoid);
  SubmarineArmPart.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart2.MoveTo(0.005*SubmarineArmPart.Width, -0.029*SubmarineArmPart.Height, aDuration, idcSinusoid);
  SubmarineArmPart2.Angle.ChangeTo(-161.621, aDuration, idcSinusoid);
  SubmarineArmPart2.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart3.MoveTo(0.855*SubmarineArmPart2.Width, -0.001*SubmarineArmPart2.Height, aDuration, idcSinusoid);
  SubmarineArmPart3.Angle.ChangeTo(47.883, aDuration, idcSinusoid);
  SubmarineArmPart3.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart4.MoveTo(0.865*SubmarineArmPart3.Width, 0, aDuration, idcSinusoid);
  SubmarineArmPart4.Angle.ChangeTo(31, aDuration, idcSinusoid);
  SubmarineArmPart4.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  SubmarineArmPart5.MoveTo(0.856*SubmarineArmPart4.Width, 0, aDuration, idcSinusoid);
  SubmarineArmPart5.Angle.ChangeTo(0, aDuration, idcSinusoid);
  SubmarineArmPart5.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftPlier.MoveTo(0.799*SubmarineArmPart5.Width, -2.456*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  LeftPlier.Angle.ChangeTo(66.883, aDuration, idcSinusoid);
  LeftPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightPlier.MoveTo(0.823*SubmarineArmPart5.Width, -1.943*SubmarineArmPart5.Height, aDuration, idcSinusoid);
  RightPlier.Angle.ChangeTo(109.868, aDuration, idcSinusoid);
  RightPlier.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TSubmarine.OpenPlier(aDuration: single);
begin
  LeftPlier.Angle.ChangeTo(60, aDuration, idcSinusoid);
  RightPlier.Angle.ChangeTo(120, aDuration, idcSinusoid);
end;

procedure TSubmarine.ClosePlier(aDuration: single);
begin
  LeftPlier.Angle.ChangeTo(80, aDuration, idcSinusoid);
  RightPlier.Angle.ChangeTo(80, aDuration, idcSinusoid);
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

procedure TSubmarine.SetState(AValue: TSubState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  case AValue of
    subsContactWithMine: PostMessage(400);
  end;
end;

procedure TSubmarine.StartDigAnimation;
begin
  State := subsDigging;
  PostMessage(100);
  PostMessage(110);
end;

procedure TSubmarine.StopDigAnimation;
begin
  State := subsWaitAfterDig;
end;

procedure TSubmarine.StartHarvestDebrisAnimation(aDebrisColor: TBGRAPixel);
begin
  State := subsHarvestingDebris;
  FHarvestDebrisColor := aDebrisColor;
  PostMessage(200);
end;

procedure TSubmarine.StopHarvestDebrisAnimation;
begin
  State := subsIdle;
end;

procedure TSubmarine.StartShowMissileAnimation;
begin
  State := subsBuildMissile;
  PostMessage(300);
end;

procedure TSubmarine.HideMissileRamp;
begin
  State := subsHideMissileRamp;
  PostMessage(350);
end;

procedure TSubmarine.ProcessContactWithMine;
begin
  State := subsContactWithMine;
end;

end.
