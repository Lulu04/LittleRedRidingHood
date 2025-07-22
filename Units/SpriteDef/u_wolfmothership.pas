unit u_wolfmothership;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes,
  u_sprite_wolf;

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

{ TScreenAnim }

TScreenAnimType = (satNone, satRotate, satFlipH, satFlipV);
TScreenAnim = class(TSprite)
private
  FInverse: TSprite;
  procedure CreateFlippedH(aTex: PTexture);
  procedure CreateFlippedV(aTex: PTexture);
public
  constructor Create(aTex: PTexture; aX, aY: single; aWidth, aHeight: integer; aAnimType: TScreenAnimType;
    aLayerIndex: integer);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

{ TScreenAnimScrollingText }

TScreenAnimScrollingText = class(TTileEngine)
  constructor Create(aTex: PTexture; aX, aY: single; aWidth, aHeight, aLayerIndex: integer);
end;

{ TSeatWithCharacter }

TSeatWithCharacter = class(TSprite)
private class var texSeat, texSeatArmrest: PTexture;
private
  FArmrest: TSprite;
  FSeatedCharacter: TWolf;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  class procedure LoadTexture(aAtlas: TAtlas);
  constructor Create(aLayerIndex: integer);
  procedure SetCharacter(aWolfCharacter: TWolf);
  procedure RaiseCharacter(aLayerIndex: integer);
end;

{ TMainBridgeBG }

TMainBridgeBG = class(TSprite)
private class var texBG, texDeskCenter: PTexture;
private
  FDeskCenter: TSprite;
public
  LeftSeat, RightSeat: TSeatWithCharacter;
  class procedure LoadTexture(aAtlas: TAtlas);
  constructor Create(aLayerIndex: integer);
  procedure CreateDeskCenter(aLayerIndex: integer);
  procedure CreateSeats(aLayerIndex: integer);
end;

procedure LoadWolfMotherShipMainBridgeTextures(aAtlas: TAtlas);

implementation

uses u_app, u_common;

var
  texScreen1, texScreen2, texScreen3, texScreen4: PTexture;

procedure LoadWolfMotherShipMainBridgeTextures(aAtlas: TAtlas);
var path: String;
begin
  path := FolderSpriteInSpace;
  TMainBridgeBG.LoadTexture(aAtlas);
  TSeatWithCharacter.LoadTexture(aAtlas);
  texScreen1 := aAtlas.AddFromSVG(path+'Screen1.svg', ScaleW(40), -1);
  texScreen2 := aAtlas.AddFromSVG(path+'Screen2.svg', ScaleW(25), -1);
  texScreen3 := aAtlas.AddFromSVG(path+'Screen3.svg', ScaleW(23), -1);
  texScreen4 := aAtlas.AddFromSVG(path+'Screen4.svg', ScaleW(44), -1);
end;

{ TScreenAnimScrollingText }

constructor TScreenAnimScrollingText.Create(aTex: PTexture; aX, aY: single; aWidth,
  aHeight, aLayerIndex: integer);
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  LoadMapFile(FolderSpriteInSpace+'Screen4Main_Map.map', [aTex]);
  SetCoordinate(aX, aY);
  SetViewSize(aWidth, aHeight);
end;

{ TScreenAnim }

procedure TScreenAnim.CreateFlippedH(aTex: PTexture);
begin
  FInverse := TSprite.Create(aTex, False);
  AddChild(FInverse, -1);
  FInverse.FlipH := True;
  FInverse.X.Value := Width*0.5;
  FInverse.Y.Value := 0;
end;

procedure TScreenAnim.CreateFlippedV(aTex: PTexture);
begin
  FInverse := TSprite.Create(aTex, False);
  AddChild(FInverse, -1);
  FInverse.FlipV := True;
  FInverse.Y.Value := Height*0.5;
  FInverse.X.Value := 0;
end;

constructor TScreenAnim.Create(aTex: PTexture; aX, aY: single; aWidth,
  aHeight: integer; aAnimType: TScreenAnimType; aLayerIndex: integer);
begin
  inherited Create(aTex, False);
  SetCoordinate(aX, aY);
  SetSize(aWidth, aHeight);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  case aAnimType of
    satRotate: Angle.AddConstant(180);
    satFlipH: begin
      CreateFlippedH(aTex);
      PostMessage(0);
    end;
    satFlipV: begin
      CreateFlippedV(aTex);
      PostMessage(50);
    end;
  end;
end;

procedure TScreenAnim.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // anim flipped H
    0: begin
      MoveXRelative(Width*0.5, 1.5, idcSinusoid);
      FInverse.MoveXRelative(-Width, 1.5, idcSinusoid);
      PostMessage(5, 1.5);
    end;
    5: begin
      MoveXRelative(-Width*0.5, 1.5, idcSinusoid);
      FInverse.MoveXRelative(Width, 1.5, idcSinusoid);
      PostMessage(0, 1.5);
    end;

    // anim flipped V
    50: begin
      MoveYRelative(Height*0.5, 1.5, idcSinusoid);
      FInverse.MoveYRelative(-Height, 1.5, idcSinusoid);
      PostMessage(55, 1.5);
    end;
    55: begin
      MoveYRelative(-Height*0.5, 1.5, idcSinusoid);
      FInverse.MoveYRelative(Height, 1.5, idcSinusoid);
      PostMessage(50, 1.5);
    end;
  end;
end;

{ TSeatWithCharacter }

procedure TSeatWithCharacter.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FArmrest.FlipH := AValue;
  if FSeatedCharacter <> NIL then
    FSeatedCharacter.FlipH := AValue;
end;

procedure TSeatWithCharacter.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FArmrest.FlipV := AValue;
  if FSeatedCharacter <> NIL then
    FSeatedCharacter.FlipV := AValue;
end;

class procedure TSeatWithCharacter.LoadTexture(aAtlas: TAtlas);
begin
  texSeat := aAtlas.AddFromSVG(FolderSpriteInSpace+'Seat.svg', ScaleW(120), -1);
  texSeatArmrest := aAtlas.AddFromSVG(FolderSpriteInSpace+'SeatArmrest.svg', ScaleW(69), -1);
end;

constructor TSeatWithCharacter.Create(aLayerIndex: integer);
begin
  inherited Create(texSeat, False);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);

  FArmrest := CreateSpriteChild(texSeatArmrest, False, 1);
  FArmrest.SetCoordinate(0.378*Width, 0.389*Height);
  FArmrest.ApplySymmetryWhenFlip := True;
end;

procedure TSeatWithCharacter.SetCharacter(aWolfCharacter: TWolf);
begin
  FSeatedCharacter := aWolfCharacter;
  FSeatedCharacter.SetChildOf(Self, 0);
  FSeatedCharacter.X.Value := Width*0.40;
  FSeatedCharacter.Y.Value := Height*0.60;
  FSeatedCharacter.State := wsSeatOnChair;
end;

procedure TSeatWithCharacter.RaiseCharacter(aLayerIndex: integer);
begin
  if FSeatedCharacter = NIL then exit;
  FSeatedCharacter.Y.Value := FSeatedCharacter.Y.Value + Height*0.20;
  if aLayerIndex <> -1 then FSeatedCharacter.MoveToLayer(aLayerIndex);
  FSeatedCharacter.Idle(True);
  FSeatedCharacter := NIL;
end;

{ TMainBridgeBG }

class procedure TMainBridgeBG.LoadTexture(aAtlas: TAtlas);
var path: String;
begin
  path := FolderSpriteInSpace;
  texBG := aAtlas.AddFromSVG(path+'MainBridgeInner.svg', ScaleW(768), -1);
  texDeskCenter := aAtlas.AddFromSVG(path+'DeskCenter.svg', ScaleW(222), -1);
end;

constructor TMainBridgeBG.Create(aLayerIndex: integer);
begin
  inherited Create(texBG, False);
  SetSize(FScene.Width, FScene.Height);
  if aLayerIndex <> -1 then begin
    FScene.Add(Self, aLayerIndex);
    CenterOnScene;
  end;
  // screen 1
  TScreenAnim.Create(texScreen3, ScaleW(25), ScaleH(505), ScaleW(23), ScaleH(23), satRotate, aLayerIndex);
  // screen 3
  with TScreenAnim.Create(texScreen2, ScaleW(323), ScaleH(454), ScaleW(25), ScaleH(21), satFlipH, aLayerIndex) do
    Angle.Value := -2.7;
  // screen 5
  TScreenAnim.Create(texScreen1, ScaleW(588), ScaleH(448), ScaleW(40), ScaleH(15), satFlipV, aLayerIndex);
  // screen 6
  with TScreenAnim.Create(texScreen2, ScaleW(667), ScaleH(454), ScaleW(25), ScaleH(21), satFlipH, aLayerIndex) do
    Angle.Value := 2.7;
  // screen 7
  with TScreenAnim.Create(texScreen1, ScaleW(874), ScaleH(476), ScaleW(26), ScaleH(15), satFlipV, aLayerIndex) do
    Angle.Value := 17;
  // screen 2
  with TScreenAnimScrollingText.Create(texScreen4, ScaleW(153), ScaleH(470), ScaleW(35), ScaleH(29), aLayerIndex) do begin
    ScrollSpeed.Y.Value := FScene.Height*0.01;
    Angle.Value := -18;
    Tint.Value := BGRA(255,0,255,80);
  end;
  // screen 4
  with TScreenAnimScrollingText.Create(texScreen4, ScaleW(393), ScaleH(447), ScaleW(48), ScaleH(28), aLayerIndex) do
    ScrollSpeed.Y.Value := -FScene.Height*0.01;
end;

procedure TMainBridgeBG.CreateDeskCenter(aLayerIndex: integer);
begin
  FDeskCenter := FScene.AddSprite(texDeskCenter, False, aLayerIndex);
  FDeskCenter.SetCoordinate(ScaleW(401), ScaleH(619));
end;

procedure TMainBridgeBG.CreateSeats(aLayerIndex: integer);
begin
  LeftSeat := TSeatWithCharacter.Create(aLayerIndex);
  LeftSeat.SetCoordinate(ScaleW(172), ScaleH(487));

  RightSeat := TSeatWithCharacter.Create(aLayerIndex);
  RightSeat.SetCoordinate(ScaleW(748), ScaleH(493));
  RightSeat.FlipH := True;
end;

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
    SetCoordinate(Self.Width*0.5, Self.Height*0.969);
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
