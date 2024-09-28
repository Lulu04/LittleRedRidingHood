unit u_weather_effects;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene, ALSound,
  u_common;

type

{ TFogRightToLeft }

TFogRightToLeft = class(TSpriteContainer)
private
  FtexCloud: PTexture;
  FCrossDuration, FOpacity: single;
  procedure CreateFogItem(aX: single=-1);
public
  // need texture 'Cloud128x128.png' loaded in the atlas
  constructor Create(aAtlas: TOGLCTextureAtlas; aFillScreen: boolean; aCrossDuration, aOpacity: single);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

{ TRain }

TRain = class(TParticleEmitter)
  // need texture 'RainDrop.png' loaded in the atlas
  constructor Create(aAtlas: TOGLCTextureAtlas);
end;

implementation
uses u_app;

{ TRain }

constructor TRain.Create(aAtlas: TOGLCTextureAtlas);
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_WEATHER);
  LoadFromFile(ParticleFolder+'Rain.par', aAtlas);
  SetEmitterTypeRectangle(FScene.Width, FScene.Height);
end;

{ TFogRightToLeft }

procedure TFogRightToLeft.CreateFogItem(aX: single);
var o: TSprite;
const scaleFactor = 4.0;
begin
  o := TSprite.Create(FtexCloud, False);
  FScene.Add(o, LAYER_WEATHER);
  if aX = -1 then aX := FScene.Width+o.Width*scaleFactor;
  o.SetCenterCoordinate(aX, Random(FScene.Height));
  o.Scale.Value := PointF(scaleFactor, scaleFactor);
  o.X.ChangeTo(-o.Width*scaleFactor, FCrossDuration+Random*5);
  o.Opacity.Value := FOpacity;

end;

constructor TFogRightToLeft.Create(aAtlas: TOGLCTextureAtlas;
  aFillScreen: boolean; aCrossDuration, aOpacity: single);
var i: integer;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_WEATHER);
  Opacity.Value := 35;
  FtexCloud := aAtlas.RetrieveTextureByFileName('Cloud128x128.png');
  if aCrossDuration <= 0 then aCrossDuration := 1.0;
  FCrossDuration := aCrossDuration;
  FOpacity := aOpacity;

  if aFillScreen then // generate some fog items
    for i:=0 to Round(FCrossDuration) do
      CreateFogItem(Random(FScene.Width));
  PostMessage(0);
end;

procedure TFogRightToLeft.ProcessMessage(UserValue: TUserMessageValue);
var sp: single;
begin
  case UserValue of
    0: begin
      CreateFogItem;
      sp := FScene.Width / FCrossDuration;// speed in pixel/s
      PostMessage(0, 0.25+Random*1/sp);
    end;
  end;
end;

end.

