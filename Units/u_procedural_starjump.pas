unit u_procedural_starjump;

{$mode ObjFPC}{$H+}
{$modeswitch AdvancedRecords}

interface

uses
  Classes, SysUtils, Graphics,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene, glcorearb;


type

{ TStarJumpParameters }

TStarJumpParameters = record
private
  FParticleSize: single;
  FChanged: boolean;
  function GetChanged: boolean;
  procedure SetParticleSize(AValue: single);
public
  procedure InitDefault;
  property ParticleSize: single read FParticleSize write SetParticleSize;
  property Changed: boolean read GetChanged;
end;
PStarJumpParameters = ^TStarJumpParameters;

{ TStarJumpRenderer }

TStarJumpRenderer = class(specialize TOGLCGenericPrimitiveRenderer<Txy>)
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
    '  uniform vec4 uSizexy_Opacity_Time;'#10+
    '  uniform vec4 uParticleSize;'#10+

    // fragment shader by notchris
    // https://www.shadertoy.com/view/wdKBRh
    // modified version
    '#define PASS_COUNT 1'#10+
    'float fBrightness=2.5;'#10+
    'float fSteps=222.;'#10+
//    'float fParticleSize=.015;'#10+
    'float fParticleLength=.5/60.;'#10+
    'float fMinDist=.8;'#10+
    'float fMaxDist=5.;'#10+
    'float fRepeatMin=1.;'#10+
    'float fRepeatMax=2.;'#10+
    'float fDepthFade=1.2;'#10+

    'const float sharpness=2.;'#10+

    'float Random(float x)'#10+
    '{'#10+
    '    return fract(sin(x*123.456)*23.4567+sin(x*345.678)*45.6789+sin(x*456.789)*56.789);'#10+
    '}'#10+

    'vec3 GetParticleColour(const in vec3 vParticlePos,const in float fParticleSize,const in vec3 vRayDir)'#10+
    '{'#10+
    '    vec2 vNormDir=normalize(vRayDir.xy);'#10+
    '    float d1=dot(vParticlePos.xy,vNormDir.xy)/length(vRayDir.xy);'#10+
    '    vec3 vClosest2d=vRayDir*d1;'#10+

    '    vec3 vClampedPos=vParticlePos;'#10+

    '    vClampedPos.z=clamp(vClosest2d.z,vParticlePos.z-fParticleLength,vParticlePos.z+fParticleLength);'#10+

    '    float d=dot(vClampedPos,vRayDir);'#10+

    '    vec3 vClosestPos=vRayDir*d;'#10+

    '    vec3 vDeltaPos=vClampedPos-vClosestPos;'#10+

    '    float fClosestDist=length(vDeltaPos)/fParticleSize;'#10+

    '    float fShade=clamp(1.-fClosestDist,0.,1.);'#10+

    '    fShade=fShade*exp2(-d*fDepthFade)*fBrightness;'#10+

    '    return vec3(fShade);'#10+
    '}'#10+

    'vec3 GetParticlePos(const in vec3 vRayDir,const in float fZPos,const in float fSeed)'#10+
    '{'#10+
    '    float fAngle=atan(vRayDir.x,vRayDir.y);'#10+
    '    float fAngleFraction=fract(fAngle/(3.14*2.));'#10+

    '    float fSegment=floor(fAngleFraction*fSteps+fSeed)+.5-fSeed;'#10+
    '    float fParticleAngle=fSegment/fSteps*(3.14*2.);'#10+

    '    float fSegmentPos=fSegment/fSteps;'#10+
    '    float fRadius=fMinDist+Random(fSegmentPos+fSeed)*(fMaxDist-fMinDist);'#10+

    '    float tunnelZ=vRayDir.z/length(vRayDir.xy/fRadius);'#10+

    '    tunnelZ+=fZPos;'#10+

    '    float fRepeat=fRepeatMin+Random(fSegmentPos+.1+fSeed)*(fRepeatMax-fRepeatMin);'#10+

    '    float fParticleZ=(ceil(tunnelZ/fRepeat)-.5)*fRepeat-fZPos;'#10+

    '    return vec3(sin(fParticleAngle)*fRadius,cos(fParticleAngle)*fRadius,fParticleZ);'#10+
    '}'#10+

    'vec3 Starfield(const in vec3 vRayDir,const in float fZPos,const in float fSeed)'#10+
    '{'#10+
    '    vec3 vParticlePos=GetParticlePos(vRayDir,fZPos,fSeed);'#10+
    '    return GetParticleColour(vParticlePos,uParticleSize.x,vRayDir);'#10+
    '}'#10+

    'float sharpen(float pix_coord){'#10+
    '    float norm=(fract(pix_coord)-.5)*2.;'#10+
    '    float norm2=norm*norm;'#10+
    '    return floor(pix_coord)+norm*pow(norm2,sharpness)/2.+.5;'#10+
    '}'#10+

  'void main()'#10+
  '{'#10+
    // Normalized pixel coordinates (from 0 to 1)
  '  vec2 uv = gl_FragCoord.xy / uSizexy_Opacity_Time.xy;'#10+
  '  vec2 vScreenPos=uv*2.-1.;'#10+

  '  vScreenPos.x*=uSizexy_Opacity_Time.x/uSizexy_Opacity_Time.y;'#10+

  '  vec3 vRayDir=normalize(vec3(vScreenPos,1.));'#10+
  '  float fShade=0.;'#10+
  '  float fZPos=5.+uSizexy_Opacity_Time.w;'#10+

  '  fParticleLength=.00001;'#10+

  '  float fSeed=0.;'#10+

  '  vec3 vResult=mix(vec3(0.),vec3(0.),vRayDir.y*.5+.5);'#10+

  '  for(int i=0;i<PASS_COUNT;i++)'#10+
  '  {'#10+
  '    vResult+=Starfield(vRayDir,fZPos,fSeed);'#10+
  '    fSeed+=1.234;'#10+
  '  }'#10+

  '  float total=vResult.r+vResult.g+vResult.b;'#10+
  '  if (total < 0.001) discard;'#10+

  '  vec4 resultA = vec4(sqrt(vResult),uSizexy_Opacity_Time.z);'#10+
  '  FragColor = resultA;'#10+
  '}';


private
  FLocMVP,
  FLocSizexy_Opacity_Time,
  FLocParticleSize: glint;

  FMVP: TOGLCMatrix;
  FOpacity, FTimeAccu, FWidth, FHeight: single;
protected
  procedure InitShaderCodeAndCallBack; override;
private
  procedure DefineVertexAttribPointer;
  procedure GetUniformLocation;
  procedure SetUniformValuesAndTexture;
public
  Params: TStarJumpParameters;
  procedure Prepare(aTriangleType: TTriangleType; const aMVP: TOGLCMatrix;
    const aOpacity: single; aBlendMode: byte; aTimeAccu, aWidth, aHeight: single);
  procedure PushQuad;
end;



TStarJump = class(TSimpleSurfaceWithEffect)
private
  FWidth, FHeight: integer;
  FTimeAccu: single;
  FRenderer: TStarJumpRenderer;
protected
  function GetWidth: integer; override;
  function GetHeight: integer; override;
public
  procedure Update(const aElapsedTime: single); override;
  procedure DoDraw; override;
public
  // control the length of the particle trail. Default value is 0.015 (no trail)
  ParticleSize: TFParam;
  // control the scrolling on the z axis
  ZSpeed: TFParam;
  constructor Create(aParentScene: TOGLCScene; aRenderer: TStarJumpRenderer);
  destructor Destroy; override;

  procedure SetSize(aWidth, aHeight: integer);
public // parameters
  function Params: PStarJumpParameters;
end;

implementation

{ TStarJumpParameters }

function TStarJumpParameters.GetChanged: boolean;
begin
  Result := FChanged;
  FChanged := False;
end;

procedure TStarJumpParameters.SetParticleSize(AValue: single);
begin
  if FParticleSize = AValue then exit;
  FParticleSize := AValue;
  FChanged := True;
end;

procedure TStarJumpParameters.InitDefault;
begin
  FParticleSize := 0.015;
  FChanged := True;
end;

{ TStarJumpRenderer }

procedure TStarJumpRenderer.InitShaderCodeAndCallBack;
begin
  FShaderName := 'TStarJumpRenderer';
  FVertexShaderCode := PChar(VERTEX_SHADER);
  FFragmentShaderCode := PChar(FRAGMENT_SHADER);
  FDefineVertexAttribPointer := @DefineVertexAttribPointer;
  FGetUniformLocation := @GetUniformLocation;
  FSetUniformValuesAndTexture := @SetUniformValuesAndTexture;
end;

procedure TStarJumpRenderer.DefineVertexAttribPointer;
begin
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(Txy), PChar(0));
  glEnableVertexAttribArray(0);
end;

procedure TStarJumpRenderer.GetUniformLocation;
begin
  with Shader do begin
    FLocMVP := GetUniform('uMVP');
    FLocSizexy_Opacity_Time := GetUniform('uSizexy_Opacity_Time');
    FLocParticleSize := GetUniform('uParticleSize');
  end;
end;

procedure TStarJumpRenderer.SetUniformValuesAndTexture;
begin
  glUniformMatrix4fv(FLocMVP, 1, GL_FALSE, @FMVP.Matrix[0,0]);
  glUniform4f(FLocSizexy_Opacity_Time, FWidth, FHeight, FOpacity, FTimeAccu);
  if Params.Changed then begin
    glUniform4f(FLocParticleSize, Params.ParticleSize, 0, 0, 0);
  end;
  //  glGetError();

  ParentScene.TexMan.UnbindTexture;
end;

procedure TStarJumpRenderer.Prepare(aTriangleType: TTriangleType;
  const aMVP: TOGLCMatrix; const aOpacity: single; aBlendMode: byte; aTimeAccu,
  aWidth, aHeight: single);
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

procedure TStarJumpRenderer.PushQuad;
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

function TStarJump.GetWidth: integer;
begin
  Result := FWidth;
end;

function TStarJump.GetHeight: integer;
begin
  Result := FHeight;
end;

procedure TStarJump.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if Freeze then exit;

  ParticleSize.OnElapse(aElapsedTime);
  ZSpeed.OnElapse(aElapsedTime);

  FTimeAccu := FTimeAccu + ZSpeed.Value*aElapsedTime;
end;

procedure TStarJump.DoDraw;
begin
  FRenderer.Params.ParticleSize := ParticleSize.Value;

  FRenderer.Prepare(ptTriangleStrip, FParentScene.MVPMatrix, FComputedOpacity, FBlendMode,
                    FTimeAccu, Width, Height);
  FRenderer.PushQuad;
end;

constructor TStarJump.Create(aParentScene: TOGLCScene; aRenderer: TStarJumpRenderer);
begin
  inherited Create;
  FParentScene := aParentScene;
  FRenderer := aRenderer;

  FWidth := 100;
  FHeight := 100;

  ParticleSize := TFParam.Create;
  ParticleSize.Value := 0.015;
  ZSpeed := TFParam.Create;
ZSpeed.Value := 0.5;

end;

destructor TStarJump.Destroy;
begin
  FreeAndNil(ParticleSize);
  FreeAndNil(ZSpeed);
  inherited Destroy;
end;

procedure TStarJump.SetSize(aWidth, aHeight: integer);
begin
  FWidth := aWidth;
  FHeight := aHeight;
end;

function TStarJump.Params: PStarJumpParameters;
begin
  Result := @FRenderer.Params;
end;

end.

