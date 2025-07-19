unit MotherShip;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

type

TMotherShip = class(TSprite)
private
  class var FAdditionalScale: single;
  class var texMotherShipBody, texMotherShipWingLeft, texMotherShipRadar: PTexture;
private
  WingLeft: TSprite;
  MotherShipRadar: TSprite;
  MotherShipWingLeft: TSprite;
public
  // aAdditionalScale is used to scale the collision bodies
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single=1.0);
  constructor Create(aLayerIndex: integer=-1);
end;

implementation

{ TMotherShip }

class procedure TMotherShip.LoadTexture(aAtlas: TOGLCTextureAtlas; aAdditionalScale: single);
var dataFolder: string;
begin
  FAdditionalScale := aAdditionalScale;
  dataFolder := FScene.App.DataFolder;
  texMotherShipBody := aAtlas.AddFromSVG(dataFolder+'Sprites\WolfCastle\MotherShipBody.svg', ScaleW(417), -1);
  texMotherShipWingLeft := aAtlas.AddFromSVG(dataFolder+'Sprites\WolfCastle\MotherShipWingLeft.svg', ScaleW(461), -1);
  texMotherShipRadar := aAtlas.AddFromSVG(dataFolder+'Sprites\WolfCastle\MotherShipRadar.svg', ScaleW(21), -1);
end;

constructor TMotherShip.Create(aLayerIndex: integer);
begin
  inherited Create(texMotherShipBody, False);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);

  WingLeft := TSprite.Create(texMotherShipWingLeft, False);
  with WingLeft do begin
    SetChildOf(Self, -1);
    SetCoordinate(0.007*Self.Width, 0.655*Self.Height);
    Pivot := PointF(0.35, 0.04);
  end;

  MotherShipRadar := TSprite.Create(texMotherShipRadar, False);
  with MotherShipRadar do begin
    SetChildOf(WingLeft, 0);
    SetCoordinate(0.459*WingLeft.Width, 0.249*WingLeft.Height);
  end;

  MotherShipWingLeft := TSprite.Create(texMotherShipWingLeft, False);
  with MotherShipWingLeft do begin
    SetChildOf(Self, -2);
    SetCoordinate(0.007*Self.Width, -0.581*Self.Height);
  end;
end;

end.
