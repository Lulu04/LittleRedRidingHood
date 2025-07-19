unit u_wolfmothership;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

type

{ TMotherShip }

TMotherShip = class(TSprite)
private
  class var FAdditionalScale: single;
  class var texMotherShipBody, texMotherShipWingLeft, texMotherShipRadar: PTexture;
private
  WingLeft: TSprite;
  MotherShipRadar: TSprite;
  WingRight: TSprite;
  FPropulsorLeft, FPropulsorRight, FPropulsorMiddle: TParticleEmitter;
public
  // aAdditionalScale is used to scale the collision bodies
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single=1.0);
  constructor Create(aLayerIndex: integer; aAtlas: TAtlas);

  function GetLocalTransporterBayCenter: TPointF;
public // anim
  procedure StartPropulsors;
  procedure StopPropulsor;
end;

implementation

uses u_app, u_common;

{ TMotherShip }

class procedure TMotherShip.LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single);
var path: string;
begin
  FAdditionalScale := aAdditionalScale;
  path := FolderSpriteWolfCastle;
  texMotherShipBody := aAtlas.AddFromSVG(path+'MotherShipBody.svg', -1, ScaleH(417));
  texMotherShipWingLeft := aAtlas.AddFromSVG(path+'MotherShipWingLeft.svg', -1, ScaleH(461));
  texMotherShipRadar := aAtlas.AddFromSVG(path+'MotherShipRadar.svg', ScaleW(21), -1);
end;

constructor TMotherShip.Create(aLayerIndex: integer; aAtlas: TAtlas);
begin
  inherited Create(texMotherShipBody, False);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);

  WingLeft := TSprite.Create(texMotherShipWingLeft, False);
  with WingLeft do begin
    SetChildOf(Self, -1);
    SetCoordinate(-0.568*Self.Width, 0.007*Self.Height);
  end;

  MotherShipRadar := TSprite.Create(texMotherShipRadar, False);
  with MotherShipRadar do begin
    SetChildOf(WingLeft, 0);
    SetCoordinate(0.636*WingLeft.Width, 0.464*WingLeft.Height);
    Angle.AddConstant(180);
  end;

  WingRight := TSprite.Create(texMotherShipWingLeft, False);
  with WingRight do begin
    SetChildOf(Self, -2);
    SetCoordinate(0.667*Self.Width, 0.007*Self.Height);
    FlipH := True;
  end;

  FPropulsorLeft := TParticleEmitter.Create(FScene);
  with FPropulsorLeft do begin
    SetChildOf(WingLeft, -1);
    LoadFromFile(ParticleFolder+'WolfMotherShipFlame.par', aAtlas);
    SetCoordinate(WingLeft.Width*0.415, WingLeft.Height*0.969);
    ParticlesToEmit.Value := 0;
  end;

  FPropulsorRight := TParticleEmitter.Create(FScene);
  with FPropulsorRight do begin
    SetChildOf(WingRight, -1);
    LoadFromFile(ParticleFolder+'WolfMotherShipFlame.par', aAtlas);
    SetCoordinate(WingRight.Width*0.58, WingRight.Height*0.969);
    ParticlesToEmit.Value := 0;
  end;

  FPropulsorMiddle := TParticleEmitter.Create(FScene);
  with FPropulsorMiddle do begin
    SetChildOf(Self, -2);
    LoadFromFile(ParticleFolder+'WolfMotherShipFlame.par', aAtlas);
    SetCoordinate(Width*0.5, Height*0.969);
    ParticlesToEmit.Value := 0;
  end;
end;

function TMotherShip.GetLocalTransporterBayCenter: TPointF;
begin
  Result.x := Width*0.50;
  Result.y := Height*0.67;
end;

procedure TMotherShip.StartPropulsors;
begin
  FPropulsorLeft.ParticlesToEmit.ChangeTo(203, 1.0);
  FPropulsorRight.ParticlesToEmit.ChangeTo(203, 1.0);
  FPropulsorMiddle.ParticlesToEmit.ChangeTo(203, 1.0);
end;

procedure TMotherShip.StopPropulsor;
begin
  FPropulsorLeft.ParticlesToEmit.ChangeTo(0, 4.0);
  FPropulsorRight.ParticlesToEmit.ChangeTo(0, 4.0);
  FPropulsorMiddle.ParticlesToEmit.ChangeTo(0, 4.0);
end;

end.
