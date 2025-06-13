unit u_dartboard_bird;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

type

{ TDartboardBird }

TDartboardBird = class(TSprite)
private
  class var FAdditionalScale: single;
  class var texBirdBody, texBirdLeftLeg, texBirdRightLeg, texBirdLeftWing, texBirdRightWing,
            texBirdShadow: PTexture;
  type TBirdState=(birdIdleGround, birdStartFly, birdWingFlap, birdFall, birdArrival);
private
  BirdLeftLeg, BirdRightLeg ,BirdLeftWing , RightWing: TSprite;
  FState: TBirdState;
  FFlapCount: integer;
  procedure SetState(AValue: TBirdState);
  procedure Posture_Idle(aDuration: single=0.5);
  procedure Posture_IdleFly(aDuration: single=0.5);
  procedure Posture_FlyLow(aDuration: single=0.5);
  function Gravity: single;
  function GravityH: single;
  property State: TBirdState read FState write SetState;
public
  Shadow: TSprite;
  // aAdditionalScale is used to scale the collision bodies
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single=1.0);
  constructor Create(aLayerIndex: integer=-1);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;
public
  procedure IdleGround;
  procedure StartFly;
  procedure WingFlap;
  procedure GoLeft;
  procedure GoRight;
  procedure Arrival;
  // d: [1..0]
  procedure AdjustShadowPosition(d: single);
  function ImpactPosition: TPointF;
end;

implementation

uses u_common, u_app, u_audio, Math;

{ TDartboardBird }

procedure TDartboardBird.SetState(AValue: TBirdState);
begin
  if (FState = AValue) and (FState = birdWingFlap) then
    FState := birdIdleGround;

  if FState = AValue then Exit;
  FState := AValue;
  case AValue of
    birdIdleGround: Posture_Idle(0);
    birdStartFly: Posture_IdleFly(0);
    birdWingFlap: begin
      Speed.Y.Value := Speed.Y.Value - Gravity*8;
      FFlapCount := 0;
      PostMessage(0);
    end;
    birdFall: Posture_IdleFly(0);
    birdArrival: begin
      Posture_Idle(0);
      Speed.Value := PointF(0, 0);
    end;
  end;
end;

class procedure TDartboardBird.LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single);
var path: string;
begin
  FAdditionalScale := aAdditionalScale;
  path := FolderSpriteDartboard;
  texBirdBody := aAtlas.AddFromSVG(path+'BirdBody.svg', -1, ScaleH(32));
  texBirdLeftLeg := aAtlas.AddFromSVG(path+'BirdLeftLeg.svg', ScaleW(10), -1);
  texBirdRightLeg := aAtlas.AddFromSVG(path+'BirdRightLeg.svg', ScaleW(10), -1);
  texBirdLeftWing := aAtlas.AddFromSVG(path+'BirdLeftWing.svg', ScaleW(29), -1);
  texBirdRightWing := aAtlas.AddFromSVG(path+'BirdRightWing.svg', ScaleW(29), -1);
  texBirdShadow := aAtlas.AddFromSVG(path+'BirdShadow.svg', ScaleW(29), -1);
end;

constructor TDartboardBird.Create(aLayerIndex: integer);
begin
  inherited Create(texBirdBody, False);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);

  BirdLeftLeg := TSprite.Create(texBirdLeftLeg, False);
  with BirdLeftLeg do begin
    SetChildOf(Self, 0);
    SetCoordinate(0.113*Width, 0.863*Height);
    Pivot := PointF(0.56, 0.0);
  end;

  BirdRightLeg := TSprite.Create(texBirdRightLeg, False);
  with BirdRightLeg do begin
    SetChildOf(Self, 0);
    SetCoordinate(0.513*Width, 0.863*Height);
    Pivot := PointF(0.44, 0.0);
  end;

  BirdLeftWing := TSprite.Create(texBirdLeftWing, False);
  with BirdLeftWing do begin
    SetChildOf(Self, 0);
    SetCoordinate(-0.867*Width, 0.219*Height);
    Pivot := PointF(1.0, 0.55);
  end;

  RightWing := TSprite.Create(texBirdRightWing, False);
  with RightWing do begin
    SetChildOf(Self, 0);
    SetCoordinate(0.900*Width, 0.219*Height);
    Pivot := PointF(0.0, 0.63);
  end;

  Shadow := TSprite.Create(texBirdShadow, False);
  with Shadow do begin
    SetChildOf(Self, -1);
    CenterOnParent;
    Visible := False;
  end;

  Posture_Idle(0);
end;

procedure TDartboardBird.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // ANIM WING FLAP
    0: begin
      if State <> birdWingFlap then exit;
      inc(FFlapCount);
      if FFlapCount = 5 then PostMessage(10)
      else begin
        //Speed.Y.Value := Speed.Y.Value - Gravity;
        Posture_FlyLow(0.03);
        PostMessage(5, 0.03);
      end;
    end;
    5: begin
      if State <> birdWingFlap then exit;
      Posture_IdleFly(0.03);
      PostMessage(0, 0.03);
    end;
    10: State := birdFall;
  end;//case
end;

procedure TDartboardBird.Update(const aElapsedTime: single);
var g: single;
begin
  inherited Update(aElapsedTime);

  // vertical gravity
  if not (State in [birdIdleGround, birdArrival]) then begin
    g := Gravity;
    Speed.Y.Value := Speed.Y.Value + g*0.25;
    if Speed.Y.Value > g*7 then Speed.Y.Value := g*7;
    if Speed.Y.Value < -g*7 then Speed.Y.Value := -g*7;
  end;

  // horizontal gravity
  if not (State in [birdIdleGround, birdArrival]) then begin
    g := Gravity;
    if Speed.X.Value < 0 then
      Speed.X.Value := Min(Speed.X.Value+g*0.25, 0)
    else if Speed.X.Value > 0 then
      Speed.X.Value := Max(Speed.X.Value-g*0.25, 0);
  end;

  if ParentSurface = NIL then begin
    X.Value := EnsureRange(X.Value, FScene.Width*0.25, FScene.Width*0.75);
    Y.Value := EnsureRange(Y.Value, 0, FScene.Height-Height);
  end;
end;

procedure TDartboardBird.IdleGround;
begin
  State := birdIdleGround;
end;

procedure TDartboardBird.StartFly;
begin
  State := birdStartFly;
end;

procedure TDartboardBird.WingFlap;
begin
  State := birdWingFlap;
  Audio.PlayThenKillSound('birdwingflap.ogg', 1.0);
end;

procedure TDartboardBird.GoLeft;
begin
  Speed.X.Value := Speed.X.Value - GravityH;
end;

procedure TDartboardBird.GoRight;
begin
  Speed.X.Value := Speed.X.Value + GravityH;
end;

procedure TDartboardBird.Arrival;
begin
  State := birdArrival;
end;

procedure TDartboardBird.AdjustShadowPosition(d: single);
begin
  Shadow.Visible := True;
  Shadow.Y.Value := Shadow.Height*3*d;
end;

function TDartboardBird.ImpactPosition: TPointF;
begin
  Result := Center + PointF(0, ScaleH(6));
end;

procedure TDartboardBird.Posture_Idle(aDuration: single);
begin
  BirdLeftLeg.MoveTo(0.113*Width, 0.863*Height, aDuration, idcSinusoid);
  BirdLeftLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  BirdLeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BirdRightLeg.MoveTo(0.513*Width, 0.863*Height, aDuration, idcSinusoid);
  BirdRightLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  BirdRightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BirdLeftWing.MoveTo(-0.107*Width, 0.219*Height, aDuration, idcSinusoid);
  BirdLeftWing.Angle.ChangeTo(-105.000, aDuration, idcSinusoid);
  BirdLeftWing.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightWing.MoveTo(0.087*Width, 0.206*Height, aDuration, idcSinusoid);
  RightWing.Angle.ChangeTo(105.000, aDuration, idcSinusoid);
  RightWing.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TDartboardBird.Posture_IdleFly(aDuration: single);
begin
  BirdLeftLeg.MoveTo(0.113*Width, 0.863*Height, aDuration, idcSinusoid);
  BirdLeftLeg.Angle.ChangeTo(45.000, aDuration, idcSinusoid);
  BirdLeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BirdRightLeg.MoveTo(0.513*Width, 0.863*Height, aDuration, idcSinusoid);
  BirdRightLeg.Angle.ChangeTo(-45.000, aDuration, idcSinusoid);
  BirdRightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BirdLeftWing.MoveTo(-0.867*Width, 0.219*Height, aDuration, idcSinusoid);
  BirdLeftWing.Angle.ChangeTo(0, aDuration, idcSinusoid);
  BirdLeftWing.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightWing.MoveTo(0.900*Width, 0.219*Height, aDuration, idcSinusoid);
  RightWing.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightWing.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TDartboardBird.Posture_FlyLow(aDuration: single);
begin
  BirdLeftLeg.MoveTo(0.113*Width, 0.863*Height, aDuration, idcSinusoid);
  BirdLeftLeg.Angle.ChangeTo(34.052, aDuration, idcSinusoid);
  BirdLeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BirdRightLeg.MoveTo(0.513*Width, 0.863*Height, aDuration, idcSinusoid);
  BirdRightLeg.Angle.ChangeTo(-36.426, aDuration, idcSinusoid);
  BirdRightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  BirdLeftWing.MoveTo(-0.867*Width, 0.219*Height, aDuration, idcSinusoid);
  BirdLeftWing.Angle.ChangeTo(-45.000, aDuration, idcSinusoid);
  BirdLeftWing.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightWing.MoveTo(0.900*Width, 0.219*Height, aDuration, idcSinusoid);
  RightWing.Angle.ChangeTo(45.000, aDuration, idcSinusoid);
  RightWing.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

function TDartboardBird.Gravity: single;
begin
  Result := FScene.Height*0.05;
end;

function TDartboardBird.GravityH: single;
begin
  Result := FScene.Height*0.04;
end;

end.
