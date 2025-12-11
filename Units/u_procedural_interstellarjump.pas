unit u_procedural_interstellarjump;

{$mode ObjFPC}{$H+}
{$modeswitch AdvancedRecords}

interface

uses
  Classes, SysUtils, Graphics,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene, glcorearb;


type

{ TInterStellarJumpParameters }

TInterStellarJumpParameters = record
private
  FStretch: single;
  FTrailLength: single; // 5 .. 35
  FChanged: boolean;
  function GetChanged: boolean;
  procedure SetStretch(AValue: single);
  procedure SetTrailLength(AValue: single);
public
  procedure InitDefault;
  property TrailLength: single read FTrailLength write SetTrailLength;
  property Stretch: single read FStretch write SetStretch;
  property Changed: boolean read GetChanged;
end;
PInterStellarJumpParameters = ^TInterStellarJumpParameters;

{ TInterStellarJumpRenderer }

TInterStellarJumpRenderer = class(specialize TOGLCGenericPrimitiveRenderer<Txy>)
private const
  VERTEX_SHADER =
    '#version 330 core'#10+
    '  layout(location = 0) in vec2 aVertexCoor;'#10+
    '  uniform mat4 uMVP;'#10+
    'void main()'#10+
    '{'#10+
    '  gl_Position = uMVP*vec4(aVertexCoor, 0.0, 1.0);'#10+
    '}';

  FRAGMENT_SHADER =
    '#version 330 core'#10+
    '  layout(location = 0) out vec4 FragColor;'#10+
    '  uniform vec4 uTintColor;'#10+
    '  uniform vec4 uSizexy_Opacity_Time;'#10+
    '  uniform vec4 uTrailLength_Stretch;'#10+

    // V-Drop - Del 19/11/2019 - (Tunnel mix - Enjoy)
    // https://www.shadertoy.com/view/wsKXRK
    // vertical version: https://www.shadertoy.com/view/tdGXWm
    '#define PI 3.14159'#10+

    'float vDrop(vec2 uv,float t)'#10+
    '{'#10+
    '  uv.x = uv.x*128.0;'#10+        // H-Count      128.0
    '  float dx = fract(uv.x);'#10+
    '  uv.x = floor(uv.x);'#10+
    '  uv.y *= uTrailLength_Stretch.y;'#10+             // stretch    0.05       0.01 étoiles plus fines
    '  float o=sin(uv.x*215.4);'#10+  // offset     215.4
    '  float s=cos(uv.x*33.1)*.3 +.7;'#10+  // speed
    '  float trail = mix(95.0, uTrailLength_Stretch.x, s);'#10+  // trail length       95.0,35.0,s
    '  float yv = fract(uv.y + t*s + o) * trail;'#10+
    '  yv = 1.0/yv;'#10+
    '  yv = smoothstep(0.0,1.0,yv*yv);'#10+
    '  yv = sin(yv*PI)*(s*5.0);'#10+
    '  float d2 = sin(dx*PI);'#10+
    '  return yv*(d2*d2);'#10+
    '}'#10+

    'void main()'#10+
    '{'#10+
    '  vec2 p = (gl_FragCoord.xy - 0.5 * uSizexy_Opacity_Time.xy) / uSizexy_Opacity_Time.y;'#10+
    //'  p += vec2(0.0, -0.5);'#10+
    '  float d = length(p)+0.1;'#10+
    '  p = vec2(atan(p.x, p.y) / PI, 2.5 / d);'#10+
    '  float t =  uSizexy_Opacity_Time.w*0.4;'#10+
    '  vec3 col = vec3(1.55,0.65,.225) * vDrop(p,t);'#10+	// red
    '  col += vec3(0.55,0.75,1.225) * vDrop(p,t+0.33);'#10+	// blue
    '  col += vec3(0.45,1.15,0.425) * vDrop(p,t+0.66);'#10+	// green

    '  col *= d*0.3;'#10+

    // Tint
    '  float a = uSizexy_Opacity_Time.z;'#10+    // d*d     d*0.5
    //'  if (a == 0) discard;'#10+
    '  float tintAlphaX2 = uTintColor.a*2;'#10+
    '  if (uTintColor.a >= 0.5)'#10+
    '   {'#10+
    '     tintAlphaX2 = tintAlphaX2-1;'#10+
    '     col = mix(col, uTintColor.rgb, tintAlphaX2);'#10+ // replace mode
    '   }'#10+
    '  else if (uTintColor.a > 0)'#10+
    '     col = col + uTintColor.rgb*tintAlphaX2;'#10+     // mix mode
    '  FragColor = vec4(col, a);'#10+


    //'  FragColor = vec4(col, d*0.5 * uSizexy_Opacity_Time.z);'#10+
    '}';

private
  FLocMVP,
  FLocTintColor,
  FLocSizexy_Opacity_Time,
  FLocTrailLength_Stretch: glint;

  FMVP: TOGLCMatrix;
  FTintF: TColorF;
  FOpacity, FTimeAccu, FWidth, FHeight: single;
protected
  procedure InitShaderCodeAndCallBack; override;
private
  procedure DefineVertexAttribPointer;
  procedure GetUniformLocation;
  procedure SetUniformValuesAndTexture;
public
  Params: TInterStellarJumpParameters;
  procedure Prepare(aTriangleType: TTriangleType; const aMVP: TOGLCMatrix;
    const aOpacity: single; const aComputedTint: TColorF; aBlendMode: byte; aTimeAccu, aWidth, aHeight: single
  );
  procedure PushQuad;
end;



TInterStellarJump = class(TSimpleSurfaceWithEffect)
private
  FWidth, FHeight: integer;
  FRenderer: TInterStellarJumpRenderer;
  FTimeAccu: single;
protected
  function GetWidth: integer; override;
  function GetHeight: integer; override;
public
  procedure Update(const aElapsedTime: single); override;
  procedure DoDraw; override;
public
  // 0..1   0=short  1=long
  TrailLength: TBoundedFParam;
  // Star stretch. range is 0..1   0=thin  1=large
  Stretch: TBoundedFParam;
  // allow to control the speed on the z axis. default value is 0
  ZSpeed: TFParam;
  constructor Create(aParentScene: TOGLCScene; aRenderer: TInterStellarJumpRenderer);
  destructor Destroy; override;

  procedure SetSize(aWidth, aHeight: integer);
public // parameters
  function Params: PInterStellarJumpParameters;
end;



implementation

{ TInterStellarJumpParameters }

procedure TInterStellarJumpParameters.SetTrailLength(AValue: single);
begin
  if FTrailLength = AValue then Exit;
  FTrailLength := AValue;
  FChanged := True;
end;

function TInterStellarJumpParameters.GetChanged: boolean;
begin
  Result := FChanged;
  FChanged := False;
end;

procedure TInterStellarJumpParameters.SetStretch(AValue: single);
begin
  if FStretch = AValue then Exit;
  FStretch := AValue;
  FChanged := True;
end;

procedure TInterStellarJumpParameters.InitDefault;
begin
  FTrailLength := 35.0;
  FStretch := 0.05;
  FChanged := True;
end;

{ TInterStellarJumpRenderer }

procedure TInterStellarJumpRenderer.InitShaderCodeAndCallBack;
begin
  FShaderName := 'TInterStellarJumpRenderer';
  FVertexShaderCode := PChar(VERTEX_SHADER);
  FFragmentShaderCode := PChar(FRAGMENT_SHADER);
  FDefineVertexAttribPointer := @DefineVertexAttribPointer;
  FGetUniformLocation := @GetUniformLocation;
  FSetUniformValuesAndTexture := @SetUniformValuesAndTexture;

  Params.InitDefault;
end;

procedure TInterStellarJumpRenderer.DefineVertexAttribPointer;
begin
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(Txy), PChar(0));
  glEnableVertexAttribArray(0);
end;

procedure TInterStellarJumpRenderer.GetUniformLocation;
begin
  with Shader do begin
    FLocMVP := GetUniform('uMVP');
    FLocTintColor := GetUniform('uTintColor');
    FLocSizexy_Opacity_Time := GetUniform('uSizexy_Opacity_Time');
    FLocTrailLength_Stretch := GetUniform('uTrailLength_Stretch');
  end;
end;

procedure TInterStellarJumpRenderer.SetUniformValuesAndTexture;
begin
  glUniformMatrix4fv(FLocMVP, 1, GL_FALSE, @FMVP.Matrix[0,0]);
  glUniform4fv(FLocTintColor, 1, @FTintF);
  glUniform4f(FLocSizexy_Opacity_Time, FWidth, FHeight, FOpacity, FTimeAccu);
  if Params.Changed then begin
    glUniform4f(FLocTrailLength_Stretch, Params.TrailLength, Params.Stretch, 0, 0);
  end;
  //  glGetError();

  ParentScene.TexMan.UnbindTexture;
end;

procedure TInterStellarJumpRenderer.Prepare(aTriangleType: TTriangleType;
  const aMVP: TOGLCMatrix; const aOpacity: single;
  const aComputedTint: TColorF; aBlendMode: byte; aTimeAccu, aWidth,
  aHeight: single);
var forceFlush: Boolean;
begin
  forceFlush := not FMVP.EqualTo(aMVP) or
                (FOpacity <> aOpacity) or
                not FTintF.EqualTo(aComputedTint) or
                (aTimeAccu <> FTimeAccu) or
                (aWidth <> FWidth) or
                (aHeight <> FHeight);
  Batch_CheckIfNeedFlush(Self, aTriangleType, NIL, 0, aBlendMode, forceFlush);
  FMVP.CopyFrom(aMVP);
  FOpacity := aOpacity;
  FTintF.CopyFrom(aComputedTint);
  FTimeAccu := aTimeAccu;
  FWidth := aWidth;
  FHeight := aHeight;
end;

procedure TInterStellarJumpRenderer.PushQuad;
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

function TInterStellarJump.GetWidth: integer;
begin
  Result := FWidth;
end;

function TInterStellarJump.GetHeight: integer;
begin
  Result := FHeight;
end;

procedure TInterStellarJump.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if Freeze then exit;
  TrailLength.OnElapse(aElapsedTime);
  TrailLength.OnElapse(aElapsedTime);
  ZSpeed.OnElapse(aElapsedTime);
  FTimeAccu :=  FTimeAccu + ZSpeed.Value * aElapsedTime;
end;

procedure TInterStellarJump.DoDraw;
begin
  //FRenderer.Params.TrailLength := (1.0-TrailLength.Value)*(75-1)+1;
  FRenderer.Params.TrailLength := (1.0-TrailLength.Value)*(75-0.1)+0.1;

  FRenderer.Params.Stretch := Stretch.Value*(0.1-0.05)+0.05;

  FRenderer.Prepare(ptTriangleStrip, FParentScene.MVPMatrix, FComputedOpacity, FComputedTint, FBlendMode,
                    FTimeAccu, Width, Height);
  FRenderer.PushQuad;
end;

constructor TInterStellarJump.Create(aParentScene: TOGLCScene; aRenderer: TInterStellarJumpRenderer);
begin
  inherited Create;
  FParentScene := aParentScene;
  FRenderer := aRenderer;

  FWidth := 100;
  FHeight := 100;
  TrailLength := CreateBoundedFParam(0.0, 1.0, False);
  TrailLength.Value := 0.5;

  Stretch := CreateBoundedFParam(0.0, 1.0, False);
  Stretch.Value := 0.5;

  ZSpeed := TFParam.Create;
end;

destructor TInterStellarJump.Destroy;
begin
  FreeAndNil(TrailLength);
  FreeAndNil(Stretch);
  FreeAndNil(ZSpeed);
  inherited Destroy;
end;

procedure TInterStellarJump.SetSize(aWidth, aHeight: integer);
begin
  FWidth := aWidth;
  FHeight := aHeight;
end;

function TInterStellarJump.Params: PInterStellarJumpParameters;
begin
  Result := @FRenderer.Params;
end;

end.

