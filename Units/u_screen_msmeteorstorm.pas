unit u_screen_msmeteorstorm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes, BGRAPath,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon,
  u_procedural_starnest, gvector;

type



{ TScreenMeteorStorm }

TScreenMeteorStorm = class(TGameScreenTemplate)
private type TGameState=(gsUndefined, gsRunning, gsFinalAnim, gsEnd);
  var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FPausePanel: TInGamePausePanel;
  FAction2Pressed: boolean;

  FTimeAccuAsteroid, FTimeAccuMeteor: single;

  procedure ResetVariables;
  procedure CreateLevel;
  procedure CreateSurfaceContainers;
  procedure FreeSurfaceContainers;
  procedure ProcessOnBulletCheckCollision(aBullet: TSimpleSurfaceWithEffect);
  procedure AsteroidCreation(const aElapsedTime: single);
  procedure MeteorCreation(const aElapsedTime: single);
public
  procedure DefineSubTextures(aAtlas: TAtlas); override;
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenMeteorStorm: TScreenMeteorStorm;

implementation

uses Forms, u_app, u_mousepointer, u_screen_map, u_utils, u_resourcestring,
  u_sprite_def2, u_screen_msmainbridge, u_wolfmothership, Math;

type

TExplosion = class(TParticleEmitter)
  constructor Create(aTopLeft: TPointF);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Go;
end;

TReusableExplosionContainer = class(specialize TGenericReusableSurfaceContainer<TExplosion>)
  function CreateNewSurface: TExplosion; override;
end;


{ TBaseAsteroid }

TBaseAsteroid = class(TSprite)  // LAYER_GROUND    explosion on LAYER_WEATHER
private
  class var FTexAsteroidIndex, FTexMeteorIndex: integer;
  var FGenerateParticleCount: integer;
  FmaxW, Fmarg, FmaxWmarg: single;
  FDelayCheckCollision: integer;
  FIsAsteroid: boolean;
  procedure SetInactive;
  procedure Explode; virtual;
public
  FminW: single;
  FHitCount: integer;
  constructor Create(aIsAsteroid: boolean; aCenterX, aCenterY: single; aHitCount: integer; aLayerIndex: integer);
  procedure Update(const aElapsedTime: single); override;
  procedure SetSpeed;
  procedure Hit;
end;


TAsteroid = class(TBaseAsteroid)  // LAYER_GROUND
  constructor Create(aCenterX, aCenterY: single; aHitCount: integer=2; aLayerIndex: integer=LAYER_GROUND);
end;

TReusableAsteroidContainer = class(specialize TGenericReusableSurfaceContainer<TAsteroid>)
  function CreateNewSurface: TAsteroid; override;
end;


TMeteorParticle = class(TSprite)  // LAYER_WOLF
  FPSpeed: single;
  constructor Create(aCenterX, aCenterY: single);
  procedure Update(const aElapsedTime: single); override;
  procedure InitSpeed;
end;

TReusableMeteorParticleContainer = class(specialize TGenericReusableSurfaceContainer<TMeteorParticle>)
  function CreateNewSurface: TMeteorParticle; override;
end;

TMeteor = class(TBaseAsteroid)  // LAYER_FXANIM
  constructor Create(aCenterX, aCenterY: single; aHitCount: integer=10; aLayerIndex: integer=LAYER_FXANIM);
end;

TReusableMeteorContainer = class(specialize TGenericReusableSurfaceContainer<TMeteor>)
  function CreateNewSurface: TMeteor; override;
end;


var
  texAsteroid1, texAsteroid2, texAsteroid3, texAsteroid4,
  texMeteorRed, texMeteorGreen, texMeteorOrange, texMeteorParticle,
  texGaugeBody, texShieldGaugeBody, texGaugeArrow: PTexture;

  FAtlas: TAtlas;
  FFontText, FFontRadioMessage: TTexturedFont;
  FStars: TStarsBG;
  FMotherShip: TMotherShipTopView;
  FCombatShip: TCombatShip;
  FHUD: THUD;
  FParticleGauge, FShieldGauge: TCircularGauge;
  FCamera: TOGLCCamera;
  FMeteorParticleContainer: TReusableMeteorParticleContainer;
  FAsteroidContainer: TReusableAsteroidContainer;
  FMeteorContainer: TReusableMeteorContainer;
  FExplosionContainer: TReusableExplosionContainer;
  FsndPropulsor, FSndMusic: TALSSound;
  FSndExplosion: array[0..9] of TALSSound;
  FDelayToPlayExplosionSound: single;
  // allow to select the particle target
  FParticleTargetMode: integer; //0=player ship  1=mother ship
  FMotherShipCanMove, FFinalSequenceStarted: boolean;
  FAsteroidSpeedCoeff: single;

procedure LoadExplosionSound;
var i: integer;
begin
  for i:=0 to High(FSndExplosion) do begin
    FSndExplosion[i] := Audio.AddSound('Explode3.ogg', 0.8, False);
    FSndExplosion[i].ApplyEffect(Audio.FXReverbLong);
    FSndExplosion[i].SetEffectDryWetVolume(Audio.FXReverbLong, 0.6);
  end;
end;
procedure FreeExplosionSound;
var i: integer;
begin
  for i:=0 to High(FSndExplosion) do
    FSndExplosion[i].Kill;
end;
procedure PlayExplosionSound;
var i: integer;
begin
  if FDelayToPlayExplosionSound > 0 then exit;
  FDelayToPlayExplosionSound := 0.2;
  for i:=0 to High(FSndExplosion) do
    if FSndExplosion[i].State <> ALS_PLAYING then begin
      FSndExplosion[i].Play(True);
      exit;
    end;
end;

{ TReusableExplosionContainer }

function TReusableExplosionContainer.CreateNewSurface: TExplosion;
begin
  Result := TExplosion.Create(PointF(0, 0));
end;

{ TExplosion }

constructor TExplosion.Create(aTopLeft: TPointF);
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_WEATHER);  //LAYER_FXANIM);
  LoadFromFile(ParticleFolder+'AsteroidExplosion.par', FAtlas);
  SetCoordinate(aTopLeft);
end;

procedure TExplosion.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: FExplosionContainer.SetInactive(Self);
  end;
end;

procedure TExplosion.Go;
begin
  Shoot;
  PostMessage(0, 1.0);
end;

{ TAsteroid }

constructor TAsteroid.Create(aCenterX, aCenterY: single; aHitCount: integer; aLayerIndex: integer);
begin
  inherited Create(True, aCenterX, aCenterY, aHitCount, aLayerIndex);
  FGenerateParticleCount := 1;
end;

{ TReusableMeteorContainer }

function TReusableMeteorContainer.CreateNewSurface: TMeteor;
begin
  Result := TMeteor.Create(0, 0);
end;

{ TReusableAsteroidContainer }

function TReusableAsteroidContainer.CreateNewSurface: TAsteroid;
begin
  Result := TAsteroid.Create(0, 0);
end;

{ TReusableMeteorParticleContainer }

function TReusableMeteorParticleContainer.CreateNewSurface: TMeteorParticle;
begin
  Result := TMeteorParticle.Create(0, 0);
end;

{ TMeteorParticle }

constructor TMeteorParticle.Create(aCenterX, aCenterY: single);
begin
  inherited Create(texMeteorParticle, False);
  FScene.Add(Self, LAYER_WOLF);
  SetCenterCoordinate(aCenterX, aCenterY);
end;

procedure TMeteorParticle.Update(const aElapsedTime: single);
var polar: TPolarCoor;
  targetPoint: TPointF;
begin
  inherited Update(aElapsedTime);
  if Freeze then exit;

  if (Speed.x.Value <> 0) or (Speed.Y.Value <> 0) then exit;

  if FParticleTargetMode = 0 then targetPoint := FCombatShip.Center
    else targetPoint := PointF(FMotherShip.X.Value+FMotherShip.Width*0.5, FMotherShip.Y.Value+FMotherShip.Height*0.22);

  polar := CartesianToPolar(targetPoint, Center);
  if polar.Distance < 10 then begin
    FMeteorParticleContainer.SetInactive(Self);
    Visible := False;
    Freeze := True;
    // increment the particule gauge
    if FParticleTargetMode = 0 then
      FParticleGauge.Percent := FParticleGauge.Percent + 1/((FCombatShip.ShootLevelIndex+1)*100);
    exit;
  end;

  FPSpeed := FPSpeed + FPSpeed*0.01;
  if FPSpeed > 1.0 then FPSpeed := 1.0;
  polar.Distance := polar.Distance - 100*FPSpeed;
  SetCenterCoordinate(PolarToCartesian(targetPoint, polar));
end;

procedure TMeteorParticle.InitSpeed;
begin
  FPSpeed := 0.07;
  Speed.x.Value := PPIScale(Random(300)-150);
  Speed.y.Value := PPIScale(Random(300)-150);
  Speed.ChangeTo(PointF(0, 0), 0.25+Random*0.5, idcDrop);
end;

{ TMeteor }

constructor TMeteor.Create(aCenterX, aCenterY: single; aHitCount: integer; aLayerIndex: integer);
var sc: single;
begin
  sc := 1 + Random*0.75;
  inherited Create(False, aCenterX, aCenterY, Round(aHitCount*sc), aLayerIndex);
  FGenerateParticleCount := 7;
  Scale.x.Value := sc;
  Scale.y.Value := sc;
  FminW := Min(ScaledWidth, ScaledHeight);
end;

{ TBaseAsteroid }

procedure TBaseAsteroid.SetInactive;
begin
  if FIsAsteroid then FAsteroidContainer.SetInactive(TAsteroid(Self))
    else FMeteorContainer.SetInactive(TMeteor(Self));
  Visible := False;
  Freeze := True;
end;

procedure TBaseAsteroid.Explode;
var p: TPointF;
  i: SizeUInt;
  o: TMeteorParticle;
  pc: integer;
  explosion: TExplosion;
begin
  SetInactive;

  if FIsAsteroid then PlayExplosionSound
    else Audio.PlayThenKillSound('custom_short_explosion.ogg', 0.6, 0.0, 1.0+Random*0.1-0.2);

  // generate explosion
  explosion := FExplosionContainer.GetInactiveSurface;
  explosion.SetCoordinate(GetXY);
  explosion.SetEmitterTypeRectangle(Width, Height);
  explosion.Go;

  // generate particle
  p := Center;
  pc := FGenerateParticleCount;
  while pc > 0 do begin
    o := FMeteorParticleContainer.GetInactiveSurface;
    o.InitSpeed;
    o.SetCenterCoordinate(p.x + Random*Width-Width*0.5, p.y + Random*Height-Height*0.5);
    dec(pc);
  end;
end;

constructor TBaseAsteroid.Create(aIsAsteroid: boolean; aCenterX,
  aCenterY: single; aHitCount: integer; aLayerIndex: integer);
var r: integer;
  sc: single;
begin
  FHitCount := aHitCount;
  FDelayCheckCollision := 5;

  // texture
  if aIsAsteroid then begin
    repeat
      r := Random(4);
    until r <> FTexAsteroidIndex;
    FTexAsteroidIndex := r;
    case FTexAsteroidIndex of
      0: inherited Create(texAsteroid1, False);
      1: inherited Create(texAsteroid2, False);
      2: inherited Create(texAsteroid3, False);
      3: inherited Create(texAsteroid4, False);
    end;
  end else begin
    repeat
      r := Random(3);
    until r <> FTexMeteorIndex;
    FTexMeteorIndex := r;
    case FTexMeteorIndex of
      0: inherited Create(texMeteorRed, False);
      1: inherited Create(texMeteorGreen, False);
      2: inherited Create(texMeteorOrange, False);
    end;
  end;

  FIsAsteroid := aIsAsteroid;
  Angle.Value := Random*360;
  Angle.AddConstant(Random*20-10);

  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  SetCenterCoordinate(aCenterX, aCenterY);
  sc := 1.0 + Random*0.5-0.25;
  Scale.Value := PointF(sc, sc);

  SetSpeed;

  FminW := Min(ScaledWidth, ScaledHeight);
  FmaxW := Max(Width, Height);
  Fmarg := FmaxW * 0.3;
  FmaxWmarg := FmaxW + Fmarg;


  // collision body
  if aIsAsteroid then
    case FTexAsteroidIndex of
      0: CollisionBody.AddPolygon([PointF(0.416*Width, 0.033*Height), PointF(0.007*Width, 0.592*Height),
        PointF(0.007*Width, 0.687*Height), PointF(0.088*Width, 0.809*Height),
        PointF(0.254*Width, 0.939*Height), PointF(0.515*Width, 0.993*Height),
        PointF(0.799*Width, 0.843*Height), PointF(1.001*Width, 0.408*Height),
        PointF(0.821*Width, 0.061*Height), PointF(0.718*Width, 0.013*Height),
        PointF(0.416*Width, 0.033*Height)]);
      1: CollisionBody.AddPolygon([PointF(0.963*Width, 0.032*Height), PointF(0.700*Width, 0.032*Height),
        PointF(0.483*Width, 0.162*Height), PointF(0.308*Width, 0.181*Height),
        PointF(0.048*Width, 0.149*Height), PointF(0.010*Width, 0.311*Height),
        PointF(0.060*Width, 0.499*Height), PointF(0.157*Width, 0.610*Height),
        PointF(0.293*Width, 0.655*Height), PointF(0.417*Width, 0.895*Height),
        PointF(0.572*Width, 0.979*Height), PointF(0.738*Width, 0.902*Height),
        PointF(0.839*Width, 0.921*Height), PointF(0.905*Width, 0.804*Height),
        PointF(0.824*Width, 0.622*Height), PointF(0.839*Width, 0.447*Height),
        PointF(0.932*Width, 0.369*Height), PointF(0.983*Width, 0.298*Height),
        PointF(1.006*Width, 0.116*Height), PointF(0.963*Width, 0.032*Height)]);
      2: CollisionBody.AddPolygon([PointF(1.017*Width, 0.452*Height), PointF(0.732*Width, 0.135*Height),
        PointF(0.543*Width, -0.006*Height), PointF(0.317*Width, 0.032*Height),
        PointF(0.006*Width, 0.419*Height), PointF(0.006*Width, 0.574*Height),
        PointF(0.169*Width, 0.923*Height), PointF(0.264*Width, 0.968*Height),
        PointF(0.601*Width, 1.000*Height), PointF(0.785*Width, 0.884*Height),
        PointF(0.785*Width, 0.774*Height), PointF(1.001*Width, 0.555*Height),
        PointF(1.017*Width, 0.452*Height)]);
      3: CollisionBody.AddPolygon([PointF(0.801*Width, 0.316*Height), PointF(0.808*Width, 0.216*Height),
        PointF(0.706*Width, 0.086*Height), PointF(0.562*Width, 0.013*Height),
        PointF(0.365*Width, 0.170*Height), PointF(0.421*Width, 0.260*Height),
        PointF(0.215*Width, 0.573*Height), PointF(0.001*Width, 0.770*Height),
        PointF(0.005*Width, 0.930*Height), PointF(0.074*Width, 0.973*Height),
        PointF(0.565*Width, 0.966*Height), PointF(0.641*Width, 1.000*Height),
        PointF(0.749*Width, 0.990*Height), PointF(0.805*Width, 0.940*Height),
        PointF(0.808*Width, 0.750*Height), PointF(0.772*Width, 0.660*Height),
        PointF(0.818*Width, 0.623*Height), PointF(0.916*Width, 0.620*Height),
        PointF(0.998*Width, 0.556*Height), PointF(0.969*Width, 0.453*Height),
        PointF(0.801*Width, 0.316*Height)]);
    end
  else CollisionBody.AddCircle(PointF(Width*0.5, Height*0.5), PPIScale(169));

end;

procedure TBaseAsteroid.Update(const aElapsedTime: single);
var v: single;
begin
  inherited Update(aElapsedTime);
  if Freeze then exit;

  dec(FDelayCheckCollision);
  if FDelayCheckCollision > 0 then exit;
  FDelayCheckCollision := 5;

  // check if it is not visible
  if Y.Value > FScene.Height*1.1 then begin
    SetInactive;
    exit;
  end;

  // check collision with player
  if ScreenMeteorStorm.GameState = gsRunning then begin
    FCombatShip.CollisionBody.SetTransformMatrix(FCombatShip.GetMatrixSurfaceToWorld);
    CollisionBody.SetTransformMatrix(GetMatrixSurfaceToWorld);
    if CollisionBody.CheckCollisionWith(FCombatShip) then begin
      FCombatShip.Hit;
      SetInactive;
      exit;
    end;
  end;

  // check collision with mother ship shield
  if Collision.CircleCircle(Center, FminW*0.5, FMotherShip.Center, FMotherShip.Height*1.40*0.5) then begin
    if ScreenMeteorStorm.GameState = gsRunning then begin
      v := FShieldGauge.Percent;
      if v > 0.15 then
        FShieldGauge.Percent := v - 0.01*v;
    end;
    Explode;
  end;
end;

procedure TBaseAsteroid.SetSpeed;
begin
  Speed.Y.Value := FScene.Height * FAsteroidSpeedCoeff;
end;

procedure TBaseAsteroid.Hit;
begin
  dec(FHitCount);
  if FHitCount <= 0 then Explode;
end;

{ TScreenMeteorStorm }

procedure TScreenMeteorStorm.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;
end;

procedure TScreenMeteorStorm.ResetVariables;
begin
  FAction2Pressed := False;
end;

procedure TScreenMeteorStorm.CreateLevel;
begin
  FStars := TStarsBG.Create(LAYER_BG3);
  FStars.Starnest.LoadParamsFromString(STARNEST_SIMPLEHOT);
  FStars.Starnest.ScrollingAngle.Value := 90;

  // HUD
  FHUD := THUD.Create(FFontRadioMessage);
  FHUD.Radar.Visible := False;
  FHUD.SetBGColor(BGRA(84,126,69,100));
  //FHUD.SetBGColor(BGRA(224,122,183,100));

  FParticleGauge := TCircularGauge.Create(texGaugeBody, texGaugeArrow);
  FScene.Add(FParticleGauge, LAYER_GAMEUI);
  FParticleGauge.SetCoordinate(ScaleW(24), ScaleH(678));
  FParticleGauge.Percent := 0;

  FShieldGauge := TCircularGauge.Create(texShieldGaugeBody, texGaugeArrow);
  FScene.Add(FShieldGauge, LAYER_GAMEUI);
  FShieldGauge.SetCoordinate(ScaleW(131), ScaleH(678));
  FShieldGauge.Percent := 1.0;


  // mother ship   LAYER_GROUND
  FMotherShip := TMotherShipTopView.Create(LAYER_BG2, FAtlas, True);
  FMotherShip.CenterOnScene;
  FMotherShip.StartShield;
  FMotherShip.ShowDockingBay;

  FsndPropulsor := Audio.AddSound('rocket-launch-boost-and-burning.ogg', 0.60, True);
  FSndMusic := Audio.AddMusic('spaceship-arcade-shooter-game.ogg', True);
  FSndMusic.Volume.Value := 0.8;
  FSndMusic.SetLoopBounds(15.921, FSndMusic.TotalDuration);

  FCombatShip := TCombatShip.Create(FAtlas, False);
  FCombatShip.Scale.Value := PointF(0.66, 0.66);
  FCombatShip.OnBulletCheckCollision := @ProcessOnBulletCheckCollision;
  FMotherShip.DockShip(FCombatShip);

  PostMessage(100);
end;

procedure TScreenMeteorStorm.CreateSurfaceContainers;
begin
  FMeteorParticleContainer := TReusableMeteorParticleContainer.Create;
  FAsteroidContainer := TReusableAsteroidContainer.Create;
  FMeteorContainer := TReusableMeteorContainer.Create;
  FExplosionContainer := TReusableExplosionContainer.Create;
end;

procedure TScreenMeteorStorm.FreeSurfaceContainers;
begin
  FScene.LogInfo('container '+FMeteorParticleContainer.ClassName+' '+FMeteorParticleContainer.Count.ToString);
  FScene.LogInfo('container '+FAsteroidContainer.ClassName+' '+FAsteroidContainer.Count.ToString);
  FScene.LogInfo('container '+FMeteorContainer.ClassName+' '+FMeteorContainer.Count.ToString);
  FScene.LogInfo('container '+FExplosionContainer.ClassName+' '+FExplosionContainer.Count.ToString);

  FreeAndNil(FMeteorParticleContainer);
  FreeAndNil(FAsteroidContainer);
  FreeAndNil(FMeteorContainer);
  FreeAndNil(FExplosionContainer);
end;

procedure TScreenMeteorStorm.ProcessOnBulletCheckCollision(aBullet: TSimpleSurfaceWithEffect);
var i: integer;
  asteroid: TAsteroid;
  meteor: TMeteor;
  r1, r2: TRectF;
begin
  r2 := RectF(aBullet.GetXY, PointF(aBullet.RightX, aBullet.BottomY));
  for i:=0 to FScene.Layer[LAYER_GROUND].SurfaceCount-1 do
    if FScene.Layer[LAYER_GROUND].Surface[i] is TAsteroid then begin
      asteroid := FScene.Layer[LAYER_GROUND].Surface[i] as TAsteroid;
      if asteroid.Visible then begin
        r1 := RectF(PointF(asteroid.ScaledX, asteroid.ScaledY), PointF(asteroid.ScaledRightX, asteroid.ScaledBottomY));
        if Collision.RectFRectF(r1, r2) then begin
          aBullet.Kill;
          asteroid.Hit;
        end;
      end;
    end;

  for i:=0 to FScene.Layer[LAYER_FXANIM].SurfaceCount-1 do
    if FScene.Layer[LAYER_FXANIM].Surface[i] is TMeteor then begin
      meteor := FScene.Layer[LAYER_FXANIM].Surface[i] as TMeteor;
      if meteor.Visible then begin
        r1 := RectF(PointF(meteor.ScaledX, meteor.ScaledY), PointF(meteor.ScaledRightX, meteor.ScaledBottomY));
        if Collision.RectFRectF(r1, r2) then begin
          aBullet.Kill;
          meteor.Hit;
        end;
      end;
    end;
end;

procedure TScreenMeteorStorm.AsteroidCreation(const aElapsedTime: single);
var asteroid: TAsteroid;
  i: SizeUInt;
begin
  FTimeAccuAsteroid := FTimeAccuAsteroid - aElapsedTime;
  if FTimeAccuAsteroid <= 0 then begin
    case GameState of
      gsRunning: begin
        case FCombatShip.ShootLevelIndex of
          0: FTimeAccuAsteroid := Random*0.24;
          1: FTimeAccuAsteroid := Random*0.20;
          2: FTimeAccuAsteroid := Random*0.20;
          3: FTimeAccuAsteroid := Random*0.15;
          4: FTimeAccuAsteroid := Random*0.10;
          5: FTimeAccuAsteroid := Random*0.05;
        end;
      end;
      gsFinalAnim: FTimeAccuAsteroid := 0.125/FAsteroidSpeedCoeff*0.05;
    end;

    asteroid := FAsteroidContainer.GetInactiveSurface;
    asteroid.SetCenterCoordinate(Random*FScene.Width, -FScene.Height*0.25);
    asteroid.FHitCount := 2;
  end;
end;

procedure TScreenMeteorStorm.MeteorCreation(const aElapsedTime: single);
var i: integer;
  meteor: TMeteor;
begin
  FTimeAccuMeteor := FTimeAccuMeteor - aElapsedTime;
  if FTimeAccuMeteor <= 0 then begin
    case GameState of
      gsRunning: begin
        case FCombatShip.ShootLevelIndex of
          0: FTimeAccuMeteor := Random*3+5.0;
          1: FTimeAccuMeteor := Random*3+4.0;
          2: FTimeAccuMeteor := Random*2+3.0;
          3: FTimeAccuMeteor := Random+2.0;
          4: FTimeAccuMeteor := Random+1.0;
          5: FTimeAccuMeteor := Random+0.5;
        end;
      end;
      gsFinalAnim: FTimeAccuMeteor := 0.125/FAsteroidSpeedCoeff*0.75;
    end;
    if FCombatShip.ShootLevelIndex > 0 then begin
      meteor := FMeteorContainer.GetInactiveSurface;
      meteor.SetCenterCoordinate(Random*FScene.Width*0.6+FScene.Width*0.2, -FScene.Height*0.25);
      meteor.FHitCount := Round(10*meteor.Scale.x.Value);
    end;
  end;
end;

procedure TScreenMeteorStorm.DefineSubTextures(aAtlas: TAtlas);
var path: string;
  fd: TFontDescriptor;
begin
  AdditionnalScale := 1.5;
  LoadRedCombatShipTextures(aAtlas);
  AdditionnalScale := 1.0;
  TMotherShipTopView.LoadTexture(aAtlas);
  LoadRadioMessageTextures(aAtlas);
  LoadRadarTextures(aAtlas);
  LoadScrollingStar2DTextures(aAtlas);
  path := FolderSpriteInSpace;
  texAsteroid1 := aAtlas.AddFromSVG(path+'Asteroid1.svg', ScaleW(62), -1);
  texAsteroid2 := aAtlas.AddFromSVG(path+'Asteroid2.svg', ScaleW(72), -1);
  texAsteroid3 := aAtlas.AddFromSVG(path+'Asteroid3.svg', ScaleW(78), -1);
  texAsteroid4 := aAtlas.AddFromSVG(path+'Asteroid4.svg', ScaleW(74), -1);
  texMeteorParticle := aAtlas.AddFromSVG(path+'MeteorParticle.svg', ScaleW(18), -1);
  texMeteorRed := aAtlas.AddFromSVG(path+'MeteorRed.svg', ScaleW(164), -1);
  texMeteorGreen := aAtlas.AddFromSVG(path+'MeteorGreen.svg', ScaleW(170), -1);
  texMeteorOrange := aAtlas.AddFromSVG(path+'MeteorOrange.svg', ScaleW(164), -1);

  texGaugeBody := aAtlas.AddFromSVG(path+'GaugeParticleBody.svg', ScaleW(60), -1);
  texShieldGaugeBody := aAtlas.AddFromSVG(path+'GaugeShieldBody.svg', ScaleW(60), -1);
  texGaugeArrow := aAtlas.AddFromSVG(FolderSpriteSnakeFissure+'GaugeArrow.svg', -1, ScaleH(32));

  AddSphereParticleToAtlas(aAtlas);
  AddCrossParticleToAtlas(aAtlas);
  AddCloud128x128ParticleToAtlas(aAtlas);

  // ui
  CreateGameFontNumber(aAtlas); // < must be first !
  // font for button in pause panel
  FFontText := CreateGameFontText(aAtlas);

  fd.Create('Arial', Round(FScene.Height/60), [], BGRA(0,0,0));
  FFontRadioMessage := aAtlas.AddTexturedFont(fd, FSaveGame.LanguageCharSet);

  LoadGameDialogTextures(aAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(aAtlas);
  LoadMousePointerTexture(aAtlas);
  SetGameInstructions(PlayerInfo.InSpace.HelpText);
end;

procedure TScreenMeteorStorm.CreateObjects;

begin
  ResetVariables;
  GameState := gsUndefined;
  Audio.PauseMusicTitleMap(3.0);

  CheckAtlas(FAtlas, 'spacemeteorstorm.atlas');

  CreateLevel;
  FParticleTargetMode := 0; // particle target is the player ship
  FFinalSequenceStarted := False;
  FAsteroidSpeedCoeff := 0.125; // initial speed asteroid/meteor speed

  CreateSurfaceContainers;
  LoadExplosionSound;

  // pause panel
  FPausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  CustomizeMousePointer(False);
end;

procedure TScreenMeteorStorm.FreeObjects;
begin
  FreeSurfaceContainers;
  FreeExplosionSound;
  if FsndPropulsor <> NIL then FsndPropulsor.FadeOutThenKill(2.0);
  FsndPropulsor := NIL;
  if FSndMusic <> NIL then FSndMusic.FadeOutThenKill(2.0);
  FSndMusic := NIL;

  FScene.KillCamera(FCamera);
  FreeAndNil(FHUD);
  if FScene.RequestedScreen = ScreenMap then
    Audio.ResumeMusicTitleMap;

  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
  ChallengeMode := False;
end;

procedure TScreenMeteorStorm.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
  i: Integer;
begin
  case UserValue of
    // combat ship exit the mother ship
    100: begin
      FSndMusic.Play;
      FCombatShip.ExitFromDockingBay_RunPath(FolderSpriteInSpace+'PathForCombatShipExitDockingBayForMeteorStorm.txt');
      PostMessage(105);
      PostMessage(102, 3.0);
    end;
    102: FCombatShip.Scale.ChangeTo(PointF(1, 1), 3.0, idcSinusoid);
    105: if FCombatShip.AnimDone then PostMessage(110) else PostMessage(105);
    110: begin
      FCombatShip.Angle.Value := 0;
      FCombatShip.MoveToLayer(LAYER_PLAYER);
      FCombatShip.Angle.Value := -90;
      PostMessage(119);
      ShowGameInstructions(PlayerInfo.InSpace.HelpText);
    end;
    119: begin
      FHUD.Radio.AddMessageFromFather(sAlrightKidsForward);
      PostMessage(120, 2.0);
    end;
    120: begin
      FHUD.Radio.AddMessageFromPenelope(Format(sEngagingThrusters, [PlayerInfo.Name]));
      PostMessage(125, 1.0);
    end;
    125: begin
      FsndPropulsor.FadeIn(1.0, 1.0); ;
      FMotherShip.StartPropulsors;
      FCombatShip.StartPropulsor;
      FStars.Starnest.ScrollingAngle.Value := 90;
      FStars.Starnest.ScrollingSpeed.ChangeTo(FScene.Width*0.000001, 2.0, idcSinusoid);
     // FStars.ScrollingStars2D.ScrollingSpeed.ChangeTo(PointF(0, FScene.Height*0.05), 2.0, idcSinusoid);
      PostMessage(130, 2.5);
    end;
    130: begin
      FHUD.Radio.AddMessageFromLR(sOkImGoingInFirst);
      PostMessage(135, 0.5);
    end;
    135: begin
      FMotherShip.Y.ChangeTo(ScaleH(537), 7.0, idcSinusoid);
      PostMessage(140, 7.0);
      FCombatShip.X.ChangeTo((FScene.Width-FCombatShip.Width)*0.5, 2.0, idcSinusoid);
      FTimeAccuAsteroid := 3.0;
      FTimeAccuMeteor := 5.0;
      GameState := gsRunning;
    end;
    140: begin
      FHUD.Radio.AddMessageFromPenelope(sSomeExplanation);
      FMotherShip.StopPropulsor;
      FMotherShipCanMove := True;
      PostMessage(145); // anim x axis
      PostMessage(150); // anim y axis
      FsndPropulsor.FadeOutThenKill(10.0);
      FsndPropulsor := NIL;
    end;
    // move mother ship horizontally
    145: begin
      if not FMotherShipCanMove then exit;
      d := 3+Random*3;
      FMotherShip.X.ChangeTo(FScene.Width*0.3*Random+FScene.Width*0.3, d, idcSinusoid);
      PostMessage(145, d*1.2);
    end;
    // move mother ship vertically
    150: begin
      if not FMotherShipCanMove then exit;
      d := 2+Random*4;
      FMotherShip.Y.ChangeTo(FScene.Height-FScene.Height*0.1-FScene.Height*0.3*Random, d, idcSinusoid);
      PostMessage(150, d*1.2);
    end;

    // final dialogs
    200: begin // wait gauje is at 0.25%
      if FParticleGauge.Percent >= 0.25 then PostMessage(205) else PostMessage(200);
    end;
    205: begin
      FHUD.Radio.AddMessageFromPenelope(sMWAreInstalling);
      PostMessage(210, 5.0);
    end;
    210: begin
      FHUD.Radio.AddMessageFromPenelope(sJustALittleLonger);
      PostMessage(215, 5.0);
    end;
    215: begin
      FHUD.Radio.AddMessageFromPenelope(sIfItWorkWellHave);
      FMotherShipCanMove := False;
      FMotherShip.X.ChangeTo((FScene.Width-FMotherShip.Width)*0.5, 6.0, idcSinusoid);
      FMotherShip.Y.ChangeTo(ScaleH(537), 6.0, idcSinusoid);
      PostMessage(220, 8.0);
    end;
    220: begin
      FHUD.Radio.AddMessageFromPenelope(sSystemInstalled);
      FParticleTargetMode := 1;
      PostMessage(225, 6.0);
    end;
    225: begin
      FShieldGauge.Percent := 1.0;
      FHUD.Radio.AddMessageFromPenelope(sTheShieldIsRecharging);
      PostMessage(230, 3.0);
    end;
    230: begin
      FHUD.Radio.AddMessageFromPenelope(Format(sPTakeFormation, [PlayerInfo.Name]));
      PostMessage(235, 3.0);
    end;
    235: begin
      FHUD.Radio.AddMessageFromLR(sUnderstood);
      PostMessage(240, 1.0);
    end;
    240: begin
      GameState := gsFinalAnim;
      d := Sqrt(Distance2BetweenCenters(FCombatShip, FMotherShip));
      d := Max(d / (FCombatShip.VelocityMax*50), 1.5);
      FCombatShip.MoveTo((FScene.Width-FCombatShip.Width)*0.5, ScaleH(702), d, idcSinusoid);
      PostMessage(242, d);
    end;
    242: begin
      FCombatShip.Scale.ChangeTo(PointF(0.66, 0.66), 2.0, idcSinusoid);
      PostMessage(243, 1.0);
    end;
    243: begin
      FCombatShip.SetChildOf(FMotherShip, 2);
      PostMessage(245, 1.0);
    end;
    245: begin
      FHUD.Radio.AddMessageFromLR(sInPosition);
      PostMessage(250, 2.0);
    end;
    250: begin
      FHUD.Radio.AddMessageFromPenelope(sAlrightMyWayNow);
      PostMessage(255, 1.0);
    end;
    255: begin
      FMotherShip.StartPropulsors;
      FMotherShip.Y.ChangeTo(ScaleH(251), 13.0, idcSinusoid);
      PostMessage(260, 13.0);
      PostMessage(257, 3.0); // asteroid/meteor accelerate
      FShieldGauge.Opacity.ChangeTo(0, 5.0);
      FParticleGauge.Opacity.ChangeTo(0, 5.0);
    end;
    257: begin
      if GameState = gsEnd then exit;
      FAsteroidSpeedCoeff := Min(FAsteroidSpeedCoeff*1.1, 3.0);
      for i:=0 to FAsteroidContainer.Count-1 do
        TAsteroid(FAsteroidContainer.Surfaces[i]).SetSpeed;
      for i:=0 to FMeteorContainer.Count-1 do
        TMeteor(FMeteorContainer.Surfaces[i]).SetSpeed;
      PostMessage(257, 0.5);
    end;
    260: begin
      FHUD.Radio.AddMessageFromPenelope(sGodILoveThis);
      PostMessage(265, 8.0);
    end;
    265: begin
      GameState := gsEnd; // no more asteroid
      PostMessage(270, 4.0);
    end;
    270: begin
      FHUD.Radio.AddMessageFromFather(sWeHaveMadeItThrough);
      PostMessage(275, 1.0);
    end;
    275: begin
      Audio.PlayVoiceWhowhooo;
      PostMessage(277, 3.0);
    end;
    277: begin
      FHUD.Radio.AddMessageFromFather(sEveryoneGetSomeRest);
      PostMessage(280, 5.0);
    end;
    280: begin
      PlayerInfo.InSpace.IncCurrentStep;
      FSaveGame.Save;
      PlayerInfo.InSpace.StepPlayed := PlayerInfo.InSpace.StepPlayed + 1;
      FScene.RunScreen(ScreenMotherShipMainBridge);
    end;

  end;
end;

procedure TScreenMeteorStorm.Update(const aElapsedTime: single);
var
  v: Single;
begin
  inherited Update(aElapsedTime);

  if FDelayToPlayExplosionSound > 0 then
    FDelayToPlayExplosionSound := FDelayToPlayExplosionSound - aElapsedTime;

  case FGameState of
    gsRunning: begin

      if Input.LeftPressed then
        FCombatShip.MoveLeft(aElapsedTime);

      if Input.RightPressed then
        FCombatShip.MoveRight(aElapsedTime);

      if Input.UpPressed then
        FCombatShip.MoveUp(aElapsedTime);

      if Input.DownPressed then
        FCombatShip.MoveDown(aElapsedTime);

      if Input.Action2Pressed then begin
        if not FAction2Pressed then begin
          FAction2Pressed := True;
          // shoot a bomb if any
        end;
      end else FAction2Pressed := False;

      if Input.Action1Pressed then
        FCombatShip.Shoot;

      // avoid player ship to exit the scene
      FCombatShip.X.Value := EnsureRange(FCombatShip.X.Value, 0, FScene.Width-FCombatShip.Width);
      FCombatShip.Y.Value := EnsureRange(FCombatShip.Y.Value, 0, FScene.Height-FCombatShip.Height);

      AsteroidCreation(aElapsedTime);
      MeteorCreation(aElapsedTime);

      // survey particle gauge
      if FParticleGauge.Percent = 1.0 then begin
        if FCombatShip.ShootLevelIndex < 4 then begin
          FParticleGauge.Percent := 0.0;
          Audio.PlayThenKillSound('ai-technology.ogg', 0.8, 0);
          FCombatShip.UpgradeWeapon;
          FHUD.Radio.AddMessageFromPenelope(Format(sWeaponryLevel, [FCombatShip.ShootLevelIndex+1]));
        end;
        case FCombatShip.ShootLevelIndex of
          1: FHUD.Radio.AddMessageFromPenelope(sLargeMeteorApproaching);
          2: FHUD.Radio.AddMessageFromPenelope(sKeepItUp);
          3: FHUD.Radio.AddMessageFromPenelope(sWeCanDoIt);
          4: if not FFinalSequenceStarted then begin
              FFinalSequenceStarted := True;
              PostMessage(200);
             end;
        end;
      end;

      // shield gauge: it must not be low than 0.15
      v := FShieldGauge.Percent;
      if v < 0.7 then begin
        if v < 0.35 then FShieldGauge.Percent := v + 0.05*aElapsedTime
          else FShieldGauge.Percent := v + 0.01*aElapsedTime;
      end;
    end;// gsRunning

    gsFinalAnim: begin
      AsteroidCreation(aElapsedTime);
      MeteorCreation(aElapsedTime);
    end;

  end;//case

  // check if player pause the game
  if Input.PausePressed then
    FPausePanel.ShowModal;
end;

end.

