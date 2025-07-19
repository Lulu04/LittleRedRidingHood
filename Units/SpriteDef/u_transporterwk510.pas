unit u_transporterwk510;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

type

{ TTransporterWK510 }

TTransporterWK510 = class(TSprite)
private
  class var FAdditionalScale: single;
  class var texTransporterBody, texTransporterLeg, texTransporterPlatform, texTransporterActuator: PTexture;
private
  MainPropulsor: TParticleEmitter;
  FAtlas: TAtlas;
  FTargetScreen: TScreenTemplate;
  FUserValueWhenDone: TUserMessageValue;
  FDelay: Single;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  LeftLeg: TSprite;
  RightLeg: TSprite;
  LeftActuator: TSprite;
  RightActuator: TSprite;
  Platform: TSprite;
  // aAdditionalScale is used to scale the collision bodies
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single=1.0);
  constructor Create(aAtlas: TAtlas; aLayerIndex: integer=-1);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
public
  procedure Posture_IdleOnGround(aDuration: single=0.5);
  procedure Posture_OnlyLegs(aDuration: single=0.5);
  procedure Posture_HalfPlatformOut(aDuration: single=0.5);
  procedure Posture_InAir(aDuration: single=0.5);
public
  procedure StartMainPropulsor;
  procedure StopMainPropulsor;
  procedure DoLandingShockAbsorberAnim;
  procedure ShootDustWhenLanding;
  procedure OpenPlatform(aTargetScreen: TScreenTemplate; aUserValueWhenDone: TUserMessageValue; aDelay: single);
  procedure ClosePlatform(aTargetScreen: TScreenTemplate; aUserValueWhenDone: TUserMessageValue; aDelay: single);
end;

implementation

uses u_common, u_app, u_audio;

{ TTransporterWK510 }

class procedure TTransporterWK510.LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single);
var path: string;
begin
  FAdditionalScale := aAdditionalScale;
  path := FolderSpriteWolfCastle;
  texTransporterBody := aAtlas.AddFromSVG(path+'TransporterBody.svg', ScaleW(880), -1);
  texTransporterLeg := aAtlas.AddFromSVG(path+'TransporterLeg.svg', -1, ScaleH(152));
  texTransporterPlatform := aAtlas.AddFromSVG(path+'TransporterPlatform.svg', ScaleW(422), -1);
  texTransporterActuator := aAtlas.AddFromSVG(path+'TransporterActuator.svg', -1, ScaleH(40));
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

constructor TTransporterWK510.Create(aAtlas: TAtlas; aLayerIndex: integer);
begin
  FAtlas := aAtlas;
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

  Platform := TSprite.Create(texTransporterPlatform, False);
  with Platform do begin
    SetChildOf(LeftActuator, -1);
    SetCoordinate(-0.712*LeftActuator.Width, 0.969*LeftActuator.Height);
    ApplySymmetryWhenFlip := True;
  end;

  MainPropulsor := TParticleEmitter.Create(FScene);
  with MainPropulsor do begin
    SetChildOf(Self, -1);
    LoadFromFile(ParticleFolder+'TransporterFlame.par', aAtlas);
    SetEmitterTypePoint;
    SetCoordinate(Self.Width*0.97, Self.Height*0.53);
    ParticlesToEmit.Value := 0;
  end;
end;

procedure TTransporterWK510.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // open platform
    0: begin
      with Audio.AddSound('pneumatic-grease-bomb.ogg', 0.9, False) do begin
        ApplyEffect(Audio.FXReverbLong);
        SetEffectDryWetVolume(Audio.FXReverbLong, 0.8);
        PlayThenKill(True);
      end;
      Posture_HalfPlatformOut(2.5);
      PostMessage(5, 2.5);
    end;
    5: begin
      Posture_IdleOnGround(2.5);
      PostMessage(10, 2.5);
    end;
    10: FTargetScreen.PostMessage(FUserValueWhenDone, FDelay);

    // close platform
    50: begin
      Posture_HalfPlatformOut(2.0);
      with Audio.AddSound('pneumatic-grease-bomb.ogg', 0.9, False) do begin
        ApplyEffect(Audio.FXReverbLong);
        SetEffectDryWetVolume(Audio.FXReverbLong, 0.8);
        PlayThenKill(True);
      end;
      PostMessage(55, 2.0);
    end;
    55: begin
      Posture_OnlyLegs(2.0);
      PostMessage(10, 2.0);
    end;

    // Landing Shock Absorber Anim
    100: begin
      MoveYRelative(Height*0.06, 0.6, idcSinusoid);     //idcDrop
      LeftLeg.MoveYRelative(-Height*0.06, 0.6, idcSinusoid);
      RightLeg.MoveYRelative(-Height*0.06, 0.6, idcSinusoid);
      PostMessage(105, 0.8);
    end;
    105: begin
      MoveYRelative(-Height*0.06, 0.6, idcSinusoid);
      LeftLeg.MoveYRelative(Height*0.06, 0.6, idcSinusoid);
      RightLeg.MoveYRelative(Height*0.06, 0.6, idcSinusoid);
    end;

  end;//case
end;

procedure TTransporterWK510.Posture_IdleOnGround(aDuration: single);
begin
  LeftLeg.MoveTo(0.081*Width, 0.858*Height, aDuration, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightLeg.MoveTo(0.768*Width, 0.859*Height, aDuration, idcSinusoid);
  RightLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Platform.MoveTo(-0.712*LeftActuator.Width, 0.969*LeftActuator.Height, aDuration, idcSinusoid);
  Platform.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Platform.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftActuator.MoveTo(0.271*Width, 0.948*Height, aDuration, idcSinusoid);
  LeftActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightActuator.MoveTo(0.686*Width, 0.950*Height, aDuration, idcSinusoid);
  RightActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTransporterWK510.Posture_OnlyLegs(aDuration: single);
begin
  LeftLeg.MoveTo(0.081*Width, 0.858*Height, aDuration, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightLeg.MoveTo(0.768*Width, 0.859*Height, aDuration, idcSinusoid);
  RightLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Platform.MoveTo(-0.712*LeftActuator.Width, -0.384*LeftActuator.Height, aDuration, idcSinusoid);
  Platform.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Platform.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftActuator.MoveTo(0.271*Width, 0.599*Height, aDuration, idcSinusoid);
  LeftActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightActuator.MoveTo(0.686*Width, 0.601*Height, aDuration, idcSinusoid);
  RightActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTransporterWK510.Posture_HalfPlatformOut(aDuration: single);
begin
  LeftLeg.MoveTo(0.081*Width, 0.858*Height, aDuration, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightLeg.MoveTo(0.768*Width, 0.859*Height, aDuration, idcSinusoid);
  RightLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Platform.MoveTo(-0.712*LeftActuator.Width, -0.434*LeftActuator.Height, aDuration, idcSinusoid);
  Platform.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Platform.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftActuator.MoveTo(0.271*Width, 0.948*Height, aDuration, idcSinusoid);
  LeftActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightActuator.MoveTo(0.686*Width, 0.950*Height, aDuration, idcSinusoid);
  RightActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTransporterWK510.Posture_InAir(aDuration: single);
begin
  LeftLeg.MoveTo(0.081*Width, 0.203*Height, aDuration, idcSinusoid);
  LeftLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightLeg.MoveTo(0.768*Width, 0.204*Height, aDuration, idcSinusoid);
  RightLeg.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightLeg.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  Platform.MoveTo(-0.712*LeftActuator.Width, -0.384*LeftActuator.Height, aDuration, idcSinusoid);
  Platform.Angle.ChangeTo(0, aDuration, idcSinusoid);
  Platform.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  LeftActuator.MoveTo(0.271*Width, 0.599*Height, aDuration, idcSinusoid);
  LeftActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  LeftActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
  RightActuator.MoveTo(0.686*Width, 0.601*Height, aDuration, idcSinusoid);
  RightActuator.Angle.ChangeTo(0, aDuration, idcSinusoid);
  RightActuator.Scale.ChangeTo(PointF(1.0, 1.0), aDuration, idcSinusoid);
end;

procedure TTransporterWK510.StartMainPropulsor;
begin
  MainPropulsor.ParticlesToEmit.ChangeTo(203, 1.0);
end;

procedure TTransporterWK510.StopMainPropulsor;
begin
  MainPropulsor.ParticlesToEmit.ChangeTo(0, 4.0);
end;

procedure TTransporterWK510.DoLandingShockAbsorberAnim;
begin
  PostMessage(100);
end;

procedure TTransporterWK510.ShootDustWhenLanding;
var pe: TParticleEmitter;
   procedure DoCreatePE(aParent: TSprite);
   begin
     pe := TParticleEmitter.Create(FScene);
     aParent.AddChild(pe, 1);
     pe.LoadFromFile(ParticleFolder+'TransporterLandingDust.par', FAtlas);
     pe.SetCoordinate(0, aParent.Height);
     pe.SetEmitterTypeLine(0, aParent.Width);
     pe.Shoot;
     pe.KillDefered(5.0);
     pe.Opacity.Value := 200;
   end;

begin
  DoCreatePE(LeftLeg);
  DoCreatePE(RightLeg);
end;

procedure TTransporterWK510.OpenPlatform(aTargetScreen: TScreenTemplate;
  aUserValueWhenDone: TUserMessageValue; aDelay: single);
begin
  FTargetScreen := aTargetScreen;
  FUserValueWhenDone := aUserValueWhenDone;
  FDelay := aDelay;
  PostMessage(0);
end;

procedure TTransporterWK510.ClosePlatform(aTargetScreen: TScreenTemplate;
  aUserValueWhenDone: TUserMessageValue; aDelay: single);
begin
  FTargetScreen := aTargetScreen;
  FUserValueWhenDone := aUserValueWhenDone;
  FDelay := aDelay;
  PostMessage(50);
end;

end.
