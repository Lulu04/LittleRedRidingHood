unit u_gamebackground;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

type

{ TGrassLarge }

TGrassLarge = class(TDeformationGrid)
  constructor Create(aTexture: PTexture; aX, aY: single; aLayerIndex: integer);
end;

{ TFlower }

TFlower = class(TDeformationGrid)
  constructor Create(aTexture: PTexture; aX, aY: single; aLayerIndex: integer);
end;

{ TCloud }

TCloud = class(TSprite)
private
  FScaleValue: single;
public
  // aDistance range is [0..1]  0=near 1=far
  // aDirection is equal to -1, 0 or 1
  constructor Create(aX, aY, aDistance: single; aDirection: integer);
  procedure Update(const aElapsedTime: single); override;
end;

{ TPine }

TPine = class(TSprite)
private
  FScaleValue: single;
public
  // aDistance range is [0..1]  0=near 1=far
  constructor Create(aCenterX, aBottomY, aDistance: single);
end;

{ TForestBG }

TForestBG = class
private
  procedure CreatePineAt(aCenterX: single; aLayer: integer);
public
  constructor Create;
end;

var
texPine,
texCloudTitle: PTexture;

procedure LoadForestBGTexture(aAtlas: TOGLCTextureAtlas);
procedure LoadCloudsTexture(aAtlas: TOGLCTextureAtlas);

implementation
uses u_app, u_common, Graphics;

procedure LoadForestBGTexture(aAtlas: TOGLCTextureAtlas);
begin
  texPine := aAtlas.AddFromSVG(SpriteBGFolder+'TreePine.svg', ScaleW(234), -1);
end;

procedure LoadCloudsTexture(aAtlas: TOGLCTextureAtlas);
begin
  texCloudTitle := aAtlas.AddFromSVG(SpriteBGFolder+'CloudTitle.svg', ScaleW(234), -1);
end;

{ TFlower }

constructor TFlower.Create(aTexture: PTexture; aX, aY: single; aLayerIndex: integer);
begin
  inherited Create(aTexture, False);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
  SetGrid(1, 1);
  ApplyDeformation(dtWaveH);
  SetDeformationAmountOnRow(1, 0.0);
  Amplitude.Value := PointF(0.5, 0);
  Update(Random);
end;

{ TGrassLarge }

constructor TGrassLarge.Create(aTexture: PTExture; aX, aY: single; aLayerIndex: integer);
var i: integer;
begin
  inherited Create(aTexture, False);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aY);
  SetGrid(1, aTexture^.FrameWidth div ScaleW(20));
  ApplyDeformation(dtWaveH);
  SetDeformationAmountOnRow(1, 0.0);
 // Amplitude.Value := PointF(ScaleW(15), 0);
  for i:=0 to ColumnCount-1 do begin
    Grid[0,i].TimeMultiplicator := 1.0 + Random*0.5-0.25;
    Grid[0,i].DeformationAmount := 1.0 + Random*0.3-0.15;
  end;
end;

{ TPine }

constructor TPine.Create(aCenterX, aBottomY, aDistance: single);
begin
  inherited Create(texPine, False);
  FScene.Add(Self, LAYER_BG1);
  CenterX := aCenterX;
  FScaleValue := 1-aDistance;
  Y.Value := aBottomY - texPine^.FrameHeight*FScaleValue;

  Scale.Value := PointF(FScaleValue, FScaleValue);
  Tint.Value := BGRA(0,0,0);
  Tint.Alpha.Value := 255*aDistance;
end;

{ TCloud }

constructor TCloud.Create(aX, aY, aDistance: single; aDirection: integer);
var v: single;
begin
  inherited Create(texCloudTitle, False);
  FScene.Add(Self, LAYER_BG1);
  FScaleValue := 1-aDistance;
  v := FScene.Width*0.02;
  Speed.x.Value := (random*v+v)*aDirection*FScaleValue;
  Scale.Value := PointF(FScaleValue, FScaleValue);
  SetCoordinate(aX, aY);
  Tint.Value := BGRA(0,128,255);
  Tint.Alpha.Value := 180*(1-FScaleValue);
end;

procedure TCloud.Update(const aElapsedTime: single);
var flag: Boolean;
begin
  inherited Update(aElapsedTime);

  flag := False;
  if Speed.x.Value > 0 then begin
    if X.Value > FScene.Width then begin
      X.Value := -Width*1.05;
      flag := True;
    end;
  end else if Speed.x.Value < 0 then begin
    if X.Value < -Width*1.1 then begin
      X.Value := FScene.Width+Width*0.05;
      flag := True;
    end;
  end;
  if flag then begin
    Scale.Value := PointF((1+(random(20)-10)*0.02)*FScaleValue, (1+(random(20)-10)*0.02)*FScaleValue);
    if random > 0.5 then FlipH := True;
    if random > 0.5 then FlipV := True;
  end;
end;

{ TForestBackground }

procedure TForestBG.CreatePineAt(aCenterX: single; aLayer: integer);
var tree: TSprite;
begin
  tree := TSprite.Create(texpine, False);
  case aLayer of
    0: begin
      FScene.Add(tree, LAYER_BG1);
      tree.Scale.Value := PointF(0.8,0.9);
      tree.Y.Value := FScene.Height*0.98-tree.Height*0.9;
      tree.Tint.Value := BGRA(0,0,0,90);
    end;
    1: begin
      FScene.Add(tree, LAYER_BG2);
      tree.Scale.Value := PointF(0.7,0.8);
      tree.Y.Value := FScene.Height*0.98-tree.Height*0.8;
      tree.Tint.Value := BGRA(0,0,0,150);
    end;
    2: begin
      FScene.Add(tree, LAYER_BG2);
      tree.Scale.Value := PointF(0.4,0.5);
      tree.Y.Value := FScene.Height*0.86-tree.Height*0.5;
      tree.Tint.Value := BGRA(0,0,0,180);
    end;
  end;
  tree.CenterX := aCenterX;
end;

constructor TForestBG.Create;
var sky: TMultiColorRectangle;
begin
  sky := TMultiColorRectangle.Create(FScene.Width, FScene.Height);
  sky.SetTopColors(BGRA(110,142,255));
  sky.SetBottomColors(BGRA(13,31,178)); //(BGRA(65,209,99)); //(BGRA(8,242,130));
  FScene.Add(sky, LAYER_BG2);

  CreatePineAt(FScene.Width*0.85, 0);
  CreatePineAt(FScene.Width*0.05, 0);
  CreatePineAt(FScene.Width*0.35, 0);
  CreatePineAt(FScene.Width*0.65, 0);

  CreatePineAt(FScene.Width*0.16, 2);
  CreatePineAt(FScene.Width*0.35, 2);
  CreatePineAt(FScene.Width*0.45, 2);
  CreatePineAt(FScene.Width*0.60, 2);
  CreatePineAt(FScene.Width*0.70, 2);
  CreatePineAt(FScene.Width*0.8, 2);
  CreatePineAt(FScene.Width*0.98, 2);

  CreatePineAt(FScene.Width*0.75, 1);
  CreatePineAt(FScene.Width*0.5, 1);
  CreatePineAt(FScene.Width*0.25, 1);
end;


end.

