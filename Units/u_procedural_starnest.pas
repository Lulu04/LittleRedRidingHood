unit u_procedural_starnest;

{$mode ObjFPC}{$H+}
{$modeswitch AdvancedRecords}

interface

uses
  Classes, SysUtils, Graphics,
  BGRABitmapTypes,
  OGLCScene, glcorearb;

type


{ TStarNestRenderer }

TStarNestRenderer = class(specialize TOGLCGenericPrimitiveRenderer<Txyuv>)
private const
  VERTEX_SHADER =
    '#version 330 core'#10+
    '  layout(location = 0) in vec4 aVertexAndTextureCoor;'#10+
    '  uniform mat4 uMVP;'#10+
    '  out vec2 TexCoords;'#10+
    'void main()'#10+
    '{'#10+
    '  gl_Position = uMVP*vec4(aVertexAndTextureCoor.xy, 0.0, 1.0);'#10+
    '  TexCoords = aVertexAndTextureCoor.zw;'#10+
    '}';

  FRAGMENT_SHADER =
    '#version 330 core'#10+
    '  layout(location = 0) out vec4 FragColor;'#10+
    '  in vec2 TexCoords;'#10+
    '  uniform vec2 uSize;'#10+
    '  uniform float uTime;'#10+

    // Star Nest by Pablo Roman Andrioli
    // This fragment shader is under the MIT License.
    // Source : https://www.shadertoy.com/view/XlfGRj
    '#define iterations 17'#10+      //17
    '#define formuparam 0.53'#10+
    '#define volsteps 20'#10+
    '#define stepsize 0.1'#10+
    '#define zoom   2.800'#10+      //0.800
    '#define tile   0.850'#10+       //0.850
    '#define speed  0.00000'#10+       //0.010
    '#define brightness 0.0015'#10+
    '#define darkmatter 0.800'#10+   //0.300
    '#define distfading 0.730'#10+   //730
    '#define saturation 0.850'#10+   //0.850
    '#define opacityTheshold 0.4'#10+
    '#define normalOpacity 1.0'#10+
     'void main()'#10+
    '{'#10+
    //get coords and direction
    'vec2 uv = gl_FragCoord.xy/uSize.xy-.5;'#10+
    'uv.y *= uSize.y / uSize.x;'#10+
    //'vec2 uv = TexCoords;'#10+
    'vec3 direc = vec3(vec2(uv*zoom),1.);'#10+
    'float time = uTime*speed+.25;'#10+

     //mouse rotation
    'float a1 = .5;'#10+
    'float a2 = .8;'#10+
    'mat2 rot1 = mat2(cos(a1),sin(a1),-sin(a1),cos(a1));'#10+
    'mat2 rot2 = mat2(cos(a2),sin(a2),-sin(a2),cos(a2));'#10+
    'direc.xz = direc.xz * rot1;'#10+      ///25
    'direc.xy *= rot2;'#10+
    'vec3 from = vec3(1.,.5,0.5);'#10+
    'from += vec3(time*2., time, -2.);'#10+
    'from.xz *= rot1;'#10+
    'from.xy *= rot2;'#10+

    //volumetric rendering
    'float s = 0.1;'#10+
    'float fade = 1.0;'#10+
    'vec3 v = vec3(0.0);'#10+
    'for (int r=0; r<volsteps; r++) {'#10+
    '    vec3 p = from + s*direc*.5;'#10+
    '    p = abs(vec3(tile)-mod(p,vec3(tile*2.)));'#10+ // tiling fold
    '    float pa = 0.0;'#10+
    '    float a = 0.0;'#10+
    '    for (int i=0; i<iterations; i++) {'#10+
    '        p = abs(p)/dot(p,p) - formuparam;'#10+ // the magic formula
    '        a += abs(length(p) - pa);'#10+ // absolute sum of average change
    '        pa = length(p);'#10+
    '    }'#10+
    '    float dm = max(0., darkmatter-a*a*.001);'#10+ //dark matter
    '    a *= a*a;'#10+ // add contrast
    '    if (r > 6) fade *= 1.-dm;'#10+ // dark matter, don't render near
    '    //v+=vec3(dm,dm*.5,0.);'#10+
    '    v += fade;'#10+
    '    v += vec3(s,s*s,s*s*s*s)*a*brightness*fade;'#10+ // coloring based on distance
    '    fade *= distfading;'#10+ // distance fading
    '    s += stepsize;'#10+
    '}'#10+
    'v = mix(vec3(length(v)), v, saturation);'#10+ //color adjust
    // compute alpha value: stars becomes transparent to the bottom
    'vec3 col = v*.02;'#10+
//    'if ( all( lessThan(col, vec3(0.08)) )) discard;'#10+
    'float alpha = normalOpacity;'#10+
    'if (TexCoords.y > opacityTheshold)'#10+
    '   alpha = normalOpacity-smoothstep(opacityTheshold, 1.0, TexCoords.y)*normalOpacity;'#10+
    'FragColor = vec4(col, alpha);'#10+
   '}';
private
  FLocMVP,
  FLocOpacity,
  FLocTime,
  FLocSize: glint;

  FMVP: TOGLCMatrix;
  FOpacity, FTimeAccu, FWidth, FHeight: single;
protected
  procedure InitShaderCodeAndCallBack; override;
private
  procedure DefineVertexAttribPointer;
  procedure GetUniformLocation;
  procedure SetUniformValuesAndTexture;
public
  procedure Prepare(aTriangleType: TTriangleType; const aMVP: TOGLCMatrix;
                    const aOpacity: single; aBlendMode: byte;
                    aTimeAccu: single; aWidth, aHeight: single);
  procedure PushQuad(aFlipIndex: integer);
end;


{ TStarNest }

TStarNest = class(TSimpleSurfaceWithEffect)
private
  FWidth, FHeight: integer;
  FCustomRenderer: TStarNestRenderer;
  FTimeAccu: single;
protected
  function GetWidth: integer; override;
  function GetHeight: integer; override;
public
  procedure Update(const aElapsedTime: single); override;
  procedure DoDraw; override;
public
  constructor Create(aParentScene: TOGLCScene; aCustomRenderer: TStarNestRenderer);

  procedure SetSize(aWidth, aHeight: integer);
end;

implementation

{ TStarNestRenderer }

procedure TStarNestRenderer.InitShaderCodeAndCallBack;
begin
  FShaderName := 'TStarNestRenderer';
  FVertexShaderCode := PChar(VERTEX_SHADER);
  FFragmentShaderCode := PChar(FRAGMENT_SHADER);
  FDefineVertexAttribPointer := @DefineVertexAttribPointer;
  FGetUniformLocation := @GetUniformLocation;
  FSetUniformValuesAndTexture := @SetUniformValuesAndTexture;
end;

procedure TStarNestRenderer.DefineVertexAttribPointer;
begin
  glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, sizeof(Txyuv), PChar(0));
  glEnableVertexAttribArray(0);
end;

procedure TStarNestRenderer.GetUniformLocation;
begin
  with Shader do begin
    FLocMVP := GetUniform('uMVP');
    FLocOpacity := GetUniform('uOpacity');
    FLocTime := GetUniform('uTime');
    FLocSize := GetUniform('uSize');
  end;
end;

procedure TStarNestRenderer.SetUniformValuesAndTexture;
begin
    glUniformMatrix4fv(FLocMVP, 1, GL_FALSE, @FMVP.Matrix[0,0]);
    glUniform1f(FLocOpacity, FOpacity);
    glUniform1f(FLocTime, FTimeAccu);
    glUniform2f(FLocSize, FWidth, FHeight);
//  glGetError();

  ParentScene.TexMan.UnbindTexture;
end;

procedure TStarNestRenderer.Prepare(aTriangleType: TTriangleType;
  const aMVP: TOGLCMatrix; const aOpacity: single; aBlendMode: byte;
  aTimeAccu: single; aWidth, aHeight: single);
var forceFlush: Boolean;
begin
  forceFlush := not FMVP.EqualTo(aMVP) or
                (FOpacity <> aOpacity) or
                (aTimeAccu <> FTimeAccu) or
                (aWidth <> FWidth) or
                (aHeight <> FHeight);
  Batch_CheckIfNeedFlush(Self, aTriangleType, NIL, 0, aBlendMode, forceFlush);
  FMVP.CopyFrom(aMVP);
  FOpacity := aOpacity;
  FTimeAccu := aTimeAccu;
  FWidth := aWidth;
  FHeight := aHeight;
end;

procedure TStarNestRenderer.PushQuad(aFlipIndex: integer);
var area, texCoords: TQuadCoor;
  tci: PQuadCornerIndexes;
    p: Pxyuv;
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

  texCoords[cBL].x := 0;
  texCoords[cBL].y := 0;
  texCoords[cTL].x := 0;
  texCoords[cTL].y := 1;
  texCoords[cBR].x := 1;
  texCoords[cBR].y := 0;
  texCoords[cTR].x := 1;
  texCoords[cTR].y := 1;

  tci := @FLIP_INDEXES[aFlipIndex];
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
    //tint.CopyFrom(aComputedTint);
    //mv.CopyFrom(aModelViewMatrix);
    u := texCoords[ tci^[0] ].x;
    v := texCoords[ tci^[0] ].y;
    x := area[cBL].x;
    y := area[cBL].y;
    //opacity := aOpacity;
  end;
  with p[1] do begin
    //tint.CopyFrom(aComputedTint);
    //mv.CopyFrom(aModelViewMatrix);
    u := texCoords[ tci^[1] ].x;
    v := texCoords[ tci^[1] ].y;
    x := area[cTL].x;
    y := area[cTL].y;
    //opacity := aOpacity;
  end;
  with p[2] do begin
    //tint.CopyFrom(aComputedTint);
    //mv.CopyFrom(aModelViewMatrix);
    u := texCoords[ tci^[2] ].x;
    v := texCoords[ tci^[2] ].y;
    x := area[cBR].x;
    y := area[cBR].y;
    //opacity := aOpacity;
  end;
  with p[3] do begin
    //tint.CopyFrom(aComputedTint);
    //mv.CopyFrom(aModelViewMatrix);
    u := texCoords[ tci^[3] ].x;
    v := texCoords[ tci^[3] ].y;
    x := area[cTR].x;
    y := area[cTR].y;
    //opacity := aOpacity;
  end;
end;

{ TStarNest }

function TStarNest.GetWidth: integer;
begin
  Result := FWidth;
end;

function TStarNest.GetHeight: integer;
begin
  Result := FHeight;
end;

procedure TStarNest.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  FTimeAccu := FTimeAccu + aElapsedTime;
end;

procedure TStarNest.DoDraw;
begin
  FCustomRenderer.Prepare(ptTriangleStrip, FParentScene.MVPMatrix, FComputedOpacity, FBlendMode,
                          FTimeAccu, Width, Height);
  FCustomRenderer.PushQuad(FlipToIndex);
end;

constructor TStarNest.Create(aParentScene: TOGLCScene; aCustomRenderer: TStarNestRenderer);
begin
  inherited Create;
  FParentScene := aParentScene;
  FCustomRenderer := aCustomRenderer;

  FWidth := 100;
  FHeight := 100;
end;

procedure TStarNest.SetSize(aWidth, aHeight: integer);
begin
  FWidth := aWidth;
  FHeight := aHeight;
end;

end.

