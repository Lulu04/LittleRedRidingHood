unit u_procedural_topdownsunray;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmapTypes,
  OGLCScene, glcorearb;

type

{ TTopDownSunRayRenderer }

TTopDownSunRayRenderer = class(specialize TOGLCGenericPrimitiveRenderer<Txy>)
private const
  VERTEX_SHADER =
    '#version 330 core'#10+
    '  layout(location = 0) in vec2 aVertexCoor;'#10+
    '  uniform mat4 uMVP;'#10+
    'void main()'#10+
    '{'#10+
    '  gl_Position = uMVP*vec4(aVertexCoor, 0.0, 1.0);'#10+
    '}';

// fragment shader adapted from Basic Light Rays by RynsArgent
// Source : https://www.shadertoy.com/view/tdcXzX
  FRAGMENT_SHADER =
    '#version 330 core'#10+
    '  layout(location = 0) out vec4 FragColor;'#10+
    '  uniform vec4 uColor;'#10+    // the rgb color and opacity of the rays
    '  uniform vec3 uResolution_Time;'#10+  // screen resolution xy and time
    '  uniform vec2 uStartStrength_EndStrength;'#10+ // StartStrength 0.0 to 2.0
                                                     // EndStrength 0.0 to 2.0

    // coord: (texture coordinate: [0-1], [0-1])
    // frequency: rate at which ray appears
    // travel rate: direction the ray travels in the x directions
    // max strength: light intensity of the ray
    'float rayValue(in vec2 coord, in float frequency, in float travelRate, in float maxStrength)'#10+
    '{'#10+
       // Fade out along borders of fragment
    '  float nx = 2.0f * (coord.x - 0.5f);'#10+
    '  float nx2 = min(1.0f, 3.5f - 3.5f * nx * nx);'#10+
    '  float xModifier = 0.5f * (cos(uResolution_Time.z * travelRate + coord.x * frequency) + 1.0f);'#10+
    '  float yModifier = mix(uStartStrength_EndStrength.y, uStartStrength_EndStrength.x, coord.y);'#10+
    '  return maxStrength * xModifier * nx2 * yModifier;'#10+
    '}'#10+

  'void main()'#10+
  '{'#10+
     // Normalized pixel coordinates (from 0 to 1)
  '  vec2 uv = gl_FragCoord.xy/uResolution_Time.xy;'#10+

  '  float total = rayValue(uv, 28.0f, -0.7f, 0.3) +'#10+
  '                rayValue(uv, 34.0f, 0.1f, 0.4) +'#10+
  '                rayValue(uv, 43.0f, -0.5f, 0.4) +'#10+
  '                rayValue(uv, 72.0f, 0.9f, 0.1) +'#10+
  '                rayValue(uv, 150.0f, -0.3f, 0.03) +'#10+
  '                rayValue(uv, 120.0f, 0.7f, 0.05) +'#10+
  '                rayValue(uv, 130.0f, -0.43f, 0.04) +'#10+
  '                rayValue(uv, 130.0f, 0.44f, 0.035);'#10+
   // Output to screen
  '  FragColor = vec4(uColor.rgb, uColor.a*total);'#10+
//  '  FragColor = vec4(total)*uColor;'#10+
  '}';
private
  FLocMVP,
  FLocColor,
  FLocResolution_Time,
  FLocStartStrength_EndStrength: glint;

  FMVP: TOGLCMatrix;
  FColorF: TColorF;
  FWidth, FHeight, FTimeAccu, FStartStrength, FEndStrength: single;
protected
  procedure InitShaderCodeAndCallBack; override;
private
  procedure DefineVertexAttribPointer;
  procedure GetUniformLocation;
  procedure SetUniformValuesAndTexture;
public
  procedure Prepare(aTriangleType: TTriangleType; const aMVP: TOGLCMatrix;
                    aBlendMode: byte;
                    const aColorF: TColorF; // the rgb color and opacity
                    aWidth, aHeight, aTimeAccu, aStartStrength, aEndStrength: single);
  procedure PushQuad;
end;



TTopDownSunRay = class(TSimpleSurfaceWithEffect)
private
  FWidth, FHeight: integer;
  FRenderer: TTopDownSunRayRenderer;
  FEndStrength,FStartStrength, FTimeAccu: single;
  FRayColor: TBGRAPixel;
  procedure SetEndStrength(AValue: single);
  procedure SetStartStrength(AValue: single);
protected
  function GetWidth: integer; override;
  function GetHeight: integer; override;
public
  procedure Update(const aElapsedTime: single); override;
  procedure DoDraw; override;
public
  constructor Create(aParentScene: TOGLCScene; aRenderer: TTopDownSunRayRenderer);
  destructor Destroy; override;

  procedure SetSize(aWidth, aHeight: integer);
  // the color of the rays
  property RayColor: TBGRAPixel read FRayColor write FRayColor;
  // the strength of the ray at the top of the screen
  // Range is 0.0 to 2.0   Default value is 1.0
  property StartStrength: single read FStartStrength write SetStartStrength;
  // The strength of the ray at the bottom of the screen
  // Range is 0.0 to 2.0   Default value is 0.3
  property EndStrength: single read FEndStrength write SetEndStrength;
end;

implementation
uses Math;

{ TTopDownSunRayRenderer }

procedure TTopDownSunRayRenderer.InitShaderCodeAndCallBack;
begin
  FShaderName := 'TTopDownSunRayRenderer';
  FVertexShaderCode := PChar(VERTEX_SHADER);
  FFragmentShaderCode := PChar(FRAGMENT_SHADER);
  FDefineVertexAttribPointer := @DefineVertexAttribPointer;
  FGetUniformLocation := @GetUniformLocation;
  FSetUniformValuesAndTexture := @SetUniformValuesAndTexture;
end;

procedure TTopDownSunRayRenderer.DefineVertexAttribPointer;
begin
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(Txy), PChar(0));
  glEnableVertexAttribArray(0);
end;

procedure TTopDownSunRayRenderer.GetUniformLocation;
begin
  with Shader do begin
    FLocMVP := GetUniform('uMVP');
    FLocColor := GetUniform('uColor');
    FLocResolution_Time := GetUniform('uResolution_Time');
    FLocStartStrength_EndStrength := GetUniform('uStartStrength_EndStrength');
  end;
end;

procedure TTopDownSunRayRenderer.SetUniformValuesAndTexture;
begin
  glUniformMatrix4fv(FLocMVP, 1, GL_FALSE, @FMVP.Matrix[0,0]);
  glUniform4fv(FLocColor, 1, @FColorF);
  gluniform3f(FLocResolution_Time, FWidth, FHeight, FTimeAccu);
  gluniform2f(FLocStartStrength_EndStrength, FStartStrength, FEndStrength);
end;

procedure TTopDownSunRayRenderer.Prepare(aTriangleType: TTriangleType;
  const aMVP: TOGLCMatrix; aBlendMode: byte; const aColorF: TColorF; aWidth,
  aHeight, aTimeAccu, aStartStrength, aEndStrength: single);
var forceFlush: Boolean;
begin
  forceFlush := not FMVP.EqualTo(aMVP) or
                not FColorF.EqualTo(aColorF) or
                (aWidth <> FWidth) or
                (aHeight <> FHeight) or
                (aTimeAccu <> FTimeAccu) or
                (FStartStrength <> aStartStrength) or
                (FEndStrength <> aEndStrength);
  Batch_CheckIfNeedFlush(Self, aTriangleType, NIL, 0, aBlendMode, forceFlush);
  FMVP.CopyFrom(aMVP);
  FColorF.CopyFrom(aColorF);
  FTimeAccu := aTimeAccu;
  FWidth := aWidth;
  FHeight := aHeight;
  FStartStrength := aStartStrength;
  FEndStrength := aEndStrength;
end;

procedure TTopDownSunRayRenderer.PushQuad;
var area: TQuadF;
    p: Pxy;
    pIndex: PVertexIndex;
    currentIndex: TVertexIndex;
begin
  area[cBL].x := 0;
  area[cBL].y := FHeight;
  area[cTL].x := 0;
  area[cTL].y := 0;
  area[cBR].x := FWidth;
  area[cBR].y := FHeight;
  area[cTR].x := FWidth;
  area[cTR].y := 0;

  currentIndex := FIndexInAttribsArray;

  case Batch^.CurrentPrimitiveType of
    ptTriangleStrip: begin           // 24
      AddPrimitiveRestartIfNeeded;   // 13
      pIndex := QueryIndex(4);
      pIndex[0] := currentIndex;
      pIndex[1] := currentIndex+1;
      pIndex[2] := currentIndex+2;
      pIndex[3] := currentIndex+3;
    end;
    ptTriangles: begin              // B   BD
      pIndex := QueryIndex(6);      // AC  C
      pIndex[0] := currentIndex;
      pIndex[1] := currentIndex+1;
      pIndex[2] := currentIndex+2;
      pIndex[3] := currentIndex+2;
      pIndex[4] := currentIndex+1;
      pIndex[5] := currentIndex+3;
    end;
  end;

  // push the 4 vertex        // vertex coord      24
  p := QueryVertex(4);        //                   13
  with p[0] do begin
    x := area[cBL].x;
    y := area[cBL].y;
  end;
  with p[1] do begin
    x := area[cTL].x;
    y := area[cTL].y;
  end;
  with p[2] do begin
    x := area[cBR].x;
    y := area[cBR].y;
  end;
  with p[3] do begin
    x := area[cTR].x;
    y := area[cTR].y;
  end;
end;

procedure TTopDownSunRay.SetEndStrength(AValue: single);
begin
  FEndStrength := EnsureRange(AValue, 0.0, 2.0);
end;

procedure TTopDownSunRay.SetStartStrength(AValue: single);
begin
  FStartStrength := EnsureRange(AValue, 0.0, 2.0);
end;

function TTopDownSunRay.GetWidth: integer;
begin
  Result := FWidth;
end;

function TTopDownSunRay.GetHeight: integer;
begin
  Result := FHeight;
end;

procedure TTopDownSunRay.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if Freeze then exit;
  FTimeAccu :=  FTimeAccu + aElapsedTime;
end;

procedure TTopDownSunRay.DoDraw;
var colorF: TColorF;
begin
  colorF.InitFromBGRA(FRayColor);
  colorF.a := colorF.a * FComputedOpacity;
  if colorF.a = 0 then exit;

  FRenderer.Prepare(ptTriangleStrip, FParentScene.MVPMatrix, FBlendMode, colorF,
                    FWidth, FHeight, FTimeAccu, FStartStrength, FEndStrength);
  FRenderer.PushQuad;
end;

constructor TTopDownSunRay.Create(aParentScene: TOGLCScene; aRenderer: TTopDownSunRayRenderer);
begin
  inherited Create;
  FParentScene := aParentScene;
  FRenderer := aRenderer;

  FWidth := 100;
  FHeight := 100;
  StartStrength := 1.0;
  FEndStrength := 0.3;
end;

destructor TTopDownSunRay.Destroy;
begin
  inherited Destroy;
end;

procedure TTopDownSunRay.SetSize(aWidth, aHeight: integer);
begin
  FWidth := aWidth;
  FHeight := aHeight;
end;

end.

