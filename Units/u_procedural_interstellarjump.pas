unit u_procedural_interstellarjump;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Graphics,
  BGRABitmap, BGRABitmapTypes, BGRAGradients,
  OGLCScene, glcorearb;


type

{ TInterStellarJumpRenderer }

TInterStellarJumpRenderer = class(specialize TOGLCGenericPrimitiveRenderer<Txyuv>)
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
    '  uniform vec4 uSizexy_Opacity_Time;'#10+
    '  uniform sampler2D uTexUnit;'#10+

  // Interstellar
  // Hazel Quantock
  // This code is licensed under the CC0 license http://creativecommons.org/publicdomain/zero/1.0/
  // https://www.shadertoy.com/view/Xdl3D2
    'const float tau = 6.28318530717958647692;'#10+

    // Gamma correction
    '#define GAMMA (2.2)'#10+

    'vec3 ToLinear( in vec3 col )'#10+
    '{'#10+
	// simulate a monitor, converting colour values into light values
    '  return pow( col, vec3(GAMMA) );'#10+
    '}'#10+

    'vec3 ToGamma( in vec3 col )'#10+
    '{'#10+
	// convert back into colour values, so the correct light will come out of the monitor
      'return pow( col, vec3(1.0/GAMMA) );'#10+
    '}'#10+

    'vec4 Noise( in ivec2 x )'#10+
    '{'#10+
      'return texture(uTexUnit, (vec2(x)+0.5)/256.0, -100.0 );'#10+
    '}'#10+

    'vec4 Rand( in int x )'#10+
    '{'#10+
      'vec2 uv;'#10+
      'uv.x = (float(x)+0.5)/256.0;'#10+
      'uv.y = (floor(uv.x)+0.5)/256.0;'#10+
      'return texture(uTexUnit, uv, -100.0);'#10+
    '}'#10+

   'void main()'#10+
   '{'#10+
     'vec3 ray;'#10+
     'ray.xy = 2.0*(TexCoords-uSizexy_Opacity_Time.xy*.5)/uSizexy_Opacity_Time.x;'#10+
     'ray.z = 1.0;'#10+

     'float offset = uSizexy_Opacity_Time.w*.5;'#10+
     'float speed2 = (cos(offset)+1.0)*2.0;'#10+
     'float speed = speed2+.1;'#10+
     'offset += sin(offset)*.96;'#10+
     'offset *= 2.0;'#10+

     'vec3 col = vec3(0);'#10+

     'vec3 stp = ray/max(abs(ray.x),abs(ray.y));'#10+

     'vec3 pos = 2.0*stp+.5;'#10+
     'for ( int i=0; i < 20; i++ )'#10+
     '{'#10+
       'float z = Noise(ivec2(pos.xy)).x;'#10+
       'z = fract(z-offset);'#10+
       'float d = 50.0*z-pos.z;'#10+
        'float w = pow(max(0.0,1.0-8.0*length(fract(pos.xy)-.5)),2.0);'#10+
       'vec3 c = max(vec3(0),vec3(1.0-abs(d+speed2*.5)/speed,1.0-abs(d)/speed,1.0-abs(d-speed2*.5)/speed));'#10+
       'col += 1.5*(1.0-z)*c*w;'#10+
       'pos += stp;'#10+
     '}'#10+

     'FragColor = vec4(ToGamma(col),1.0);'#10+
   '}';
private
  FLocMVP,
  FLocSizexy_Opacity_Time: glint;

  FMVP: TOGLCMatrix;
  FOpacity, FTimeAccu, FWidth, FHeight: single;
  var FtextureNoise: PTexture;
protected
  procedure InitShaderCodeAndCallBack; override;
private
  procedure DefineVertexAttribPointer;
  procedure GetUniformLocation;
  procedure SetUniformValuesAndTexture;
public
  // construct the noise texture
  //class procedure CreateTexture(aAtlas: TAtlas);
  constructor Create(aParentScene: TOGLCScene; aUseIndicesBuffer: boolean); reintroduce;
  destructor Destroy; override;
  procedure Prepare(aTriangleType: TTriangleType; const aMVP: TOGLCMatrix;
    const aOpacity: single; aBlendMode: byte; aTimeAccu, aWidth, aHeight: single);
  procedure PushQuad(aFlipIndex: integer);
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
  // Don't forget to create the texture by calling TInterStellarJumpRenderer.CreateTexture()
  constructor Create(aParentScene: TOGLCScene; aRenderer: TInterStellarJumpRenderer);

  procedure SetSize(aWidth, aHeight: integer);
end;



implementation

{ TInterStellarJumpRenderer }

procedure TInterStellarJumpRenderer.InitShaderCodeAndCallBack;
begin
  FShaderName := 'TInterStellarJumpRenderer';
  FVertexShaderCode := PChar(VERTEX_SHADER);
  FFragmentShaderCode := PChar(FRAGMENT_SHADER);
  FDefineVertexAttribPointer := @DefineVertexAttribPointer;
  FGetUniformLocation := @GetUniformLocation;
  FSetUniformValuesAndTexture := @SetUniformValuesAndTexture;
end;

procedure TInterStellarJumpRenderer.DefineVertexAttribPointer;
begin
  glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, sizeof(Txyuv), PChar(0));
  glEnableVertexAttribArray(0);
end;

procedure TInterStellarJumpRenderer.GetUniformLocation;
begin
  with Shader do begin
    FLocMVP := GetUniform('uMVP');
    FLocSizexy_Opacity_Time := GetUniform('uSizexy_Opacity_Time');
  end;
end;

procedure TInterStellarJumpRenderer.SetUniformValuesAndTexture;
begin
  glUniformMatrix4fv(FLocMVP, 1, GL_FALSE, @FMVP.Matrix[0,0]);
  glUniform4f(FLocSizexy_Opacity_Time, FWidth, FHeight, FOpacity, FTimeAccu);
  //  glGetError();

  ParentScene.TexMan.Bind(FtextureNoise, 0);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
end;

{class procedure TInterStellarJumpRenderer.CreateTexture(aAtlas: TAtlas);
var ima: TBGRABitmap;
  i, g: integer;
begin
  ima := TBGRABitmap.Create(256, 256, BGRA(0,0,0)); //BGRAPixelTransparent);
  for i := 0 to (ima.Width*ima.Height) div 2 do begin
    g := 80+Random(175);
    ima.SetPixel(Random(ima.Width), Random(ima.Height), BGRA(g, g, g));
  end;
  FtextureNoise := ParentScene.TexMan.Add(ima);
  ima.Free;


{  FtextureNoise := aAtlas.RetrieveTextureByFileName('TextureForInterStellarJumpRenderer');
  if FtextureNoise = NIL then begin
    ima := TBGRABitmap.Create(256, 256, BGRA(0,0,0)); //BGRAPixelTransparent);
    for i := 0 to (ima.Width*ima.Height) div 2 do begin
      g := 80+Random(175);
      ima.SetPixel(Random(ima.Width), Random(ima.Height), BGRA(g, g, g));
    end;
    FtextureNoise := aAtlas.Add(ima);
    FtextureNoise^.Filename := 'TextureForInterStellarJumpRenderer';
  end;   }
end; }

constructor TInterStellarJumpRenderer.Create(aParentScene: TOGLCScene;
  aUseIndicesBuffer: boolean);
var ima: TBGRABitmap;
  i, g: integer;
begin
  inherited Create(aParentScene, aUseIndicesBuffer);

  ima := TBGRABitmap.Create(256, 256, BGRA(0,0,0)); //BGRAPixelTransparent);
  for i := 0 to (ima.Width*ima.Height) div 2 do begin
    g := 80+Random(175);
    ima.SetPixel(Random(ima.Width), Random(ima.Height), BGRA(g, g, g));
  end;
  FtextureNoise := ParentScene.TexMan.Add(ima);
  ima.Free;
end;

destructor TInterStellarJumpRenderer.Destroy;
begin
  ParentScene.TexMan.Delete(FtextureNoise);
  inherited Destroy;
end;

procedure TInterStellarJumpRenderer.Prepare(aTriangleType: TTriangleType;
  const aMVP: TOGLCMatrix; const aOpacity: single; aBlendMode: byte;
  aTimeAccu, aWidth, aHeight: single);
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

procedure TInterStellarJumpRenderer.PushQuad(aFlipIndex: integer);
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
    u := texCoords[ tci^[0] ].x;
    v := texCoords[ tci^[0] ].y;
    x := area[cBL].x;
    y := area[cBL].y;
  end;
  with p[1] do begin
    u := texCoords[ tci^[1] ].x;
    v := texCoords[ tci^[1] ].y;
    x := area[cTL].x;
    y := area[cTL].y;
  end;
  with p[2] do begin
    u := texCoords[ tci^[2] ].x;
    v := texCoords[ tci^[2] ].y;
    x := area[cBR].x;
    y := area[cBR].y;
  end;
  with p[3] do begin
    u := texCoords[ tci^[3] ].x;
    v := texCoords[ tci^[3] ].y;
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

  FTimeAccu := FTimeAccu + aElapsedTime;
end;

procedure TInterStellarJump.DoDraw;
begin
  FRenderer.Prepare(ptTriangleStrip, FParentScene.MVPMatrix, FComputedOpacity, FBlendMode,
                    FTimeAccu, Width, Height);
  FRenderer.PushQuad(FlipToIndex);
end;

constructor TInterStellarJump.Create(aParentScene: TOGLCScene; aRenderer: TInterStellarJumpRenderer);
begin
  inherited Create;
  FParentScene := aParentScene;
  FRenderer := aRenderer;

  FWidth := 100;
  FHeight := 100;
end;

procedure TInterStellarJump.SetSize(aWidth, aHeight: integer);
begin
  FWidth := aWidth;
  FHeight := aHeight;
end;

end.

