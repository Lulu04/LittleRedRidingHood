unit u_screen_msharvesting;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes, BGRAPath,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon,
  u_procedural_starnest;

type


{ TScreenHarvestingInSpace }

TScreenHarvestingInSpace = class(TGameScreenTemplate)
private type TGameState=(gsUndefined, gsRunning, gsHarvestingAsteroid, gsDocking);
var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FPausePanel: TInGamePausePanel;
  FAction1Pressed, FAction2Pressed, FProbeLaunched: boolean;
  FsndMusic: TALSSound;

  procedure ResetVariables;
  procedure CreateAsteroidWithOre(aOreIndex: integer; aCenterX, aCenterY: single);
  procedure CreateLevelStep4;
  procedure CreateLevelStep6;
  procedure CreateLevelStep11;
  procedure CreateLevel;
public
  procedure DefineSubTextures(aAtlas: TAtlas); override;
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenHarvestingInSpace: TScreenHarvestingInSpace;

implementation
uses Forms, Graphics, u_app, u_mousepointer, u_screen_map, u_utils,
  u_resourcestring, u_screen_msconstruction, u_wolfmothership,
  gvector, Math;

//FLocalArea is the world rectangle expressed in Mothership.DockingBay coordinates
var FWorldArea: TRectF;

type

{ TBaseAsteroid }

TBaseAsteroid = class(Tsprite)
  FOre: TSprite;
  constructor Create(aShapeIndex: integer; aAddOre: boolean);
  procedure Update(const aElapsedTime: single); override;
  procedure MakeOreDisappear;
end;

TAsteroid = class(TBaseAsteroid)
private
  class var FTexIndex: integer;
public
  constructor Create(aCenterX, aCenterY: single; aLayerIndex: integer);
end;

TAsteroidField = class(TSpriteContainer)
private
  FShipToFollow: TBaseLittleShip;
  FArea: TRectF;
  FCellW, FWidthOrigin, FHeightOrigin: single;
  procedure ComputeArea;
public
  constructor Create(aShipToFollow: TBaseLittleShip; aLayerIndex: integer);
  procedure Update(const aElapsedTime: single); override;
end;

TAsteroidWithOre = class(TBaseAsteroid)   // LAYER_BG1
  OreIndex: integer;
  constructor Create(aOreIndex: integer; aCenterX, aCenterY: single);
end;

TAsteroidWithOreList = class(specialize TVector<TAsteroidWithOre>)
private
  FNearestIndex: SizeUInt;
public
  function GetNearest: TAsteroidWithOre;
  procedure DeleteNearest;
end;

{ TProbe }

TProbe = class(TSprite)
  Launched: boolean;
  constructor Create;
  // return:  0 if the probe can be launched
  //          1 if the probe is too far
  //          2 if the probe is too near
  function CanBeLaunched: integer;
  procedure Launch;
end;



var
  texAsteroid1, texAsteroid2, texAsteroid3, texAsteroid4,
  texAsteroid1Ore, texAsteroid2Ore, texAsteroid3Ore, texAsteroid4Ore,
  texProbe: PTexture;
  FAtlas: TAtlas;
  FFontText, FFontRadioMessage: TTexturedFont;
  FCamera: TOGLCCamera;
  FCameraZoomed: boolean;
  FStars: TStarsBG;
  FMiningShip: TMiningShip;
  FProbe: TProbe;
  FGate: THyperSpaceGate;
  FMotherShip: TMotherShipTopView;
  FHUD: THUD;
  FListOfAsteroidWithOre: TAsteroidWithOreList;
  FAsteroidHarvested: TAsteroidWithOre;
  FAsteroidField: TAsteroidField;

{ TAsteroidField }

procedure TAsteroidField.ComputeArea;
var p: TPointF;
begin
  p := FShipToFollow.GetCenterInWorldCoor;
  p.y := EnsureRange(p.y, FWorldArea.Top + FScene.Height*2, FWorldArea.Bottom - FScene.Height*2);
  if (FWidthOrigin = 0) and (FHeightOrigin = 0) then begin
    FArea.Left := p.x - FScene.Width;
    FArea.Right := p.x + FScene.Width;
    FArea.Top := p.y - FScene.Height;
    FArea.Bottom := p.y + FScene.Height;
  end else begin
    FArea.Left := p.x - FWidthOrigin*0.5;
    FArea.Right := p.x + FWidthOrigin*0.5;
    FArea.Top := p.y - FHeightOrigin*0.5;
    FArea.Bottom := p.y + FHeightOrigin*0.5;
  end;
end;

constructor TAsteroidField.Create(aShipToFollow: TBaseLittleShip; aLayerIndex: integer);
var xx, yy, xx1, yy1, xmin, xmax, ymin, ymax: single;
  o: TAsteroid;
begin
  inherited Create(FScene);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);

  FShipToFollow := aShipToFollow;

  FCellW := PPIScale(190);   //140
  ComputeArea;
  // create the asteroids
  xmin := MaxSingle;
  ymin := MaxSingle;
  xmax := MinSingle;
  ymax := MinSingle;
  yy := FArea.Top;
  repeat
    xx := FArea.Left;
    while xx < FArea.Right-FCellW*0.5 do begin
      xx1 := xx + Random*FCellW*0.5-FCellW;
      yy1 := yy + Random*FCellW-FCellW*2;
      if InRange(xx1, FArea.Left, FArea.Right) and
         InRange(yy1, FArea.Top, FArea.Bottom) then begin
        o := TAsteroid.Create(xx1, yy1, aLayerIndex);
        o.Angle.AddConstant(Random*20-10);
        if xmin > xx1 then xmin :=xx1;
        if xmax < xx1 then xmax := xx1;
        if ymin > yy1 then ymin := yy1;
        if ymax < yy1 then ymax := yy1;
      end;
      xx := xx1 + FCellW*(Random+1.0);
    end;
    yy := yy + FCellW;
  until yy > FArea.Bottom;

  FWidthOrigin := xmax - xmin;
  FHeightOrigin := ymax - ymin;
end;

procedure TAsteroidField.Update(const aElapsedTime: single);
var p: TPointF;
  o: TAsteroid;
  i: Integer;
begin
  inherited Update(aElapsedTime);
  ComputeArea;
  // check if asteroid are in the area
  for i:=0 to ParentLayer.SurfaceCount-1 do
    if ParentLayer.Surface[i] is TAsteroid then begin
      o := ParentLayer.Surface[i] as TAsteroid;
      p := o.Center;
      if p.x > FArea.Right then p.x := FArea.Left + (p.x-FArea.Right)
      else
      if p.x < FArea.Left then p.x := FArea.Right - (FArea.Left-p.x);

      if p.y > FArea.Bottom then
        p.y := FArea.Top + (p.y-FArea.Bottom)
      else
      if p.y < FArea.Top then
        p.y := FArea.Bottom - (FArea.Top-p.y);
      o.SetCenterCoordinate(p);
  end;
end;

{ TAsteroidWithOreList }

function TAsteroidWithOreList.GetNearest: TAsteroidWithOre;
var o: TAsteroidWithOre;
  centerShip: TPointF;
  dist, ang: single;
  polar: TPolarCoor;
  i: SizeUInt;
begin
  Result := NIL;
  if Size = 0 then exit;

  // retrieve the nearest asteroid
  centerShip := FMiningShip.SurfaceToWorld(PointF(FMiningShip.Width*0.5, FMiningShip.Height*0.5));
  dist := MaxSingle;
  for i:=0 to Size-1 do begin
    o := Mutable[i]^;
    polar := CartesianToPolar(centerShip, o.Center);
    if polar.Distance < dist then begin
      dist := polar.Distance;
      ang := polar.Angle;
      Result := o;
      FNearestIndex := i;
    end;
  end;

  if Result = NIL then exit;
  // the nearest is too far ?
  if dist > FMiningShip.Width*3 then begin
    Result := NIL;
    exit;
  end;

  // ship orientation is good ?
  // more ship is near we accept a delta angle of 45
  // more ship is far, we accep a delta angle less than 45, proportionnaly of the distance
  dist := 1.0 - (dist / (FMiningShip.Width*3));  // 0..1  0=far
  if Abs(DeltaAngle(ang, FMiningShip.Angle.Value)) > 45*dist then Result := NIL;
end;

procedure TAsteroidWithOreList.DeleteNearest;
begin
  Erase(FNearestIndex);
end;

{ TBaseAsteroid }

constructor TBaseAsteroid.Create(aShapeIndex: integer; aAddOre: boolean);
var tex: PTexture;
begin
  // texture
  case aShapeIndex of
    0: inherited Create(texAsteroid1, False);
    1: inherited Create(texAsteroid2, False);
    2: inherited Create(texAsteroid3, False);
    3: inherited Create(texAsteroid4, False);
  end;

  Angle.Value := Random*360;

  // ore
  if aAddOre then begin
    case aShapeIndex of
      0: tex := texAsteroid1Ore;
      1: tex := texAsteroid2Ore;
      2: tex := texAsteroid3Ore;
      3: tex := texAsteroid4Ore;
    end;
    FOre := TSprite.Create(tex, False);
    FOre.SetChildOf(Self, 0);
    FOre.CenterOnParent;
  end;

  // collision body
  case aShapeIndex of
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
  end;
end;

procedure TBaseAsteroid.Update(const aElapsedTime: single);
var r: TRectF;
begin
  inherited Update(aElapsedTime);
  // check collision with ship
  // first check if asteroid is on camera view rect
  r := FCamera.GetViewRect;
  if (X.Value > r.Right) or (RightX < r.Left) or (Y.Value > r.Bottom) or (BottomY < r.Top) then exit;
  // if coordinates have passed, check collision body
  CollisionBody.SetTransformMatrix(GetMatrixSurfaceToWorld);
  FMiningShip.CollisionBody.SetTransformMatrix(FMiningShip.GetMatrixSurfaceToWorld);
  if CollisionBody.CheckCollisionWith(FMiningShip) then
    FMiningShip.Bump;
end;

procedure TBaseAsteroid.MakeOreDisappear;
begin
  if FOre <> NIL then begin
    FOre.Opacity.ChangeTo(0, 2.0);
    FOre.KillDefered(2.0);
    FOre := NIL;
  end;
end;

{ TAsteroidWithOre }

constructor TAsteroidWithOre.Create(aOreIndex: integer; aCenterX, aCenterY: single);
begin
  inherited Create(Random(4), True);
  FScene.Add(Self, LAYER_BG1);
  SetCenterCoordinate(aCenterX, aCenterY);

  FOre.Tint.Value := GetOreColor(aOreIndex);
  if aOreindex <> 3 then FOre.BlendMode := FX_BLEND_ADD;
  OreIndex := aOreIndex;

  if PlayerInfo.InSpace.StepPlayed = 11 then begin
    if OreIndex in [1,5,6] then Tint.Value := BGRA(222,168,88,120);
  end;
end;

{ TProbe }

constructor TProbe.Create;
begin
  inherited Create(texProbe, False);
end;

function TProbe.CanBeLaunched: integer;
var d: single;
begin
  d := Distance2BetweenCenters(Self, FGate);
  if d < sqr(FGate.ScaledWidth*0.5) then exit(2)
  else if d > sqr(FGate.Width*1.6) then exit(1);
  Result := 0;
end;

procedure TProbe.Launch;
begin
  Audio.PlayThenKillSound('missile-launch-2.ogg', 0.7);
  MoveToLayer(LAYER_GROUND);
  RotationAroundPoint(FGate.Center, 45, True);
  Launched := True;
end;

{ TAsteroid }

constructor TAsteroid.Create(aCenterX, aCenterY: single; aLayerIndex: integer);
var r: integer;
  sc: single;
begin
  repeat
    r := Random(4);
  until r <> FTexIndex;
  FTexIndex := r;
  inherited Create(FTexIndex, False);

  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  SetCenterCoordinate(aCenterX, aCenterY);
  sc := 1.0 + Random*0.5-0.25;
  Scale.Value := PointF(sc, sc);

  if (PlayerInfo.InSpace.StepPlayed = 11) and (Random > 0.7) then
    Tint.Value := BGRA(222,168,88,120);
end;

{ TScreenHarvestingInSpace }

procedure TScreenHarvestingInSpace.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;
  case AValue of
    gsHarvestingAsteroid: PostMessage(2000);
  end;
end;

procedure TScreenHarvestingInSpace.ResetVariables;
begin
  FCameraZoomed := False;
  FProbeLaunched := False;
  FProbe := NIL;
end;

procedure TScreenHarvestingInSpace.CreateAsteroidWithOre(aOreIndex: integer;
  aCenterX, aCenterY: single);
var o: TAsteroidWithOre;
begin
  o := TAsteroidWithOre.Create(aOreIndex, aCenterX, aCenterY);
  FListOfAsteroidWithOre.PushBack(o);
  FHUD.Radar.RegisterObject(texIconItemSpaceHarvesting[aOreIndex], True, o, False);
end;

procedure TScreenHarvestingInSpace.CreateLevelStep4;
begin
  FWorldArea := RectF(0, 0, FScene.Width*6, FScene.Height*7);

  // star bg   LAYER_BG3
  FStars := TStarsBG.Create(LAYER_BG3);
  FStars.Starnest.LoadParamsFromString(STARNEST_SIMPLEHOT);
  FStars.Starnest.ScrollingAngle.Value := Random*180+90;
  FStars.ScrollingStars2D.ScrollingSpeed.Value := PointF(0, 0);
  //FHUD.SetBGColor(BGRA(224,122,183,100));
  FHUD.SetBGColor(BGRA(84,126,69,100));
  //FHUD.SetBGColor(BGRA(224,224,25,100));

  // mother ship   LAYER_GROUND
  FMotherShip := TMotherShipTopView.Create(LAYER_GROUND, FAtlas, True);
  FMotherShip.SetCenterCoordinate(FWorldArea.Width*0.5, FWorldArea.Bottom);
  FMotherShip.ShowDockingBay;
  FHUD.Radar.RegisterMotherShip(FMotherShip);

  FMiningShip := TMiningShip.Create(FAtlas, True);
  FMotherShip.DockShip(FMiningShip);
  FHUD.Radar.RegisterOwnerShip(FMiningShip);

  // probe on mining ship
  FProbe := TProbe.Create;
  FProbe.SetChildOf(FMiningShip, 0);
  FProbe.CenterOnParent;

  // asteroid field
  FAsteroidField := TAsteroidField.Create(FMiningShip, LAYER_BG1);

  // gate
  FGate := THyperSpaceGate.Create(FWorldArea.Width*0.5, FWorldArea.Top, LAYER_BG1, FAtlas);

  FMiningShip.ExitFromDockingBay_RunPath(FolderSpriteInSpace+'PathForMiningShipExitDockingBay.txt');
  PostMessage(0); // wait anim done
end;

procedure TScreenHarvestingInSpace.CreateLevelStep6;
begin
  FWorldArea := RectF(0, 0, FScene.Width*6, FScene.Height*7);

  // star bg   LAYER_BG3
  FStars := TStarsBG.Create(LAYER_BG3);
  FStars.Starnest.LoadParamsFromString(STARNEST_SIMPLEHOT);
  FStars.Starnest.ScrollingAngle.Value := Random*180+90;
  FStars.ScrollingStars2D.ScrollingSpeed.Value := PointF(0, 0);

  FHUD.SetBGColor(BGRA(84,126,69,100));

  // mother ship   LAYER_GROUND
  FMotherShip := TMotherShipTopView.Create(LAYER_GROUND, FAtlas, True);
  FMotherShip.SetCenterCoordinate(FWorldArea.Width*0.5, FWorldArea.Bottom);
  FMotherShip.ShowDockingBay;
  FMotherShip.StartShield;
  FHUD.Radar.RegisterMotherShip(FMotherShip);

  FMiningShip := TMiningShip.Create(FAtlas, True);
  FMotherShip.DockShip(FMiningShip);
  FHUD.Radar.RegisterOwnerShip(FMiningShip);

  // asteroid field
  FAsteroidField := TAsteroidField.Create(FMiningShip, LAYER_BG1);

  // gate
  FGate := THyperSpaceGate.Create(FWorldArea.Width*0.5, FWorldArea.Top, LAYER_BG1, FAtlas);

  FMiningShip.ExitFromDockingBay_RunPath(FolderSpriteInSpace+'PathForMiningShipExitDockingBay.txt');
  PostMessage(0); // wait anim done
end;

procedure TScreenHarvestingInSpace.CreateLevelStep11;
begin
  FWorldArea := RectF(0, 0, FScene.Width*6, FScene.Height*7);

  // star bg   LAYER_BG3
  FStars := TStarsBG.Create(LAYER_BG3);
  FStars.Starnest.LoadParamsFromString(STARNEST_SIMPLEHOT);
  FStars.Starnest.ScrollingAngle.Value := Random*180+90;
  FStars.ScrollingStars2D.ScrollingSpeed.Value := PointF(0, 0);

  FHUD.SetBGColor(BGRA(84,126,69,100));

  // gate
  FGate := THyperSpaceGate.Create(FWorldArea.Width*0.5, FWorldArea.Top-FScene.Height, LAYER_BG1, FAtlas);
  FHUD.Radar.RegisterGate(FGate);

  // mother ship   LAYER_GROUND
  FMotherShip := TMotherShipTopView.Create(LAYER_GROUND, FAtlas, True);
  FMotherShip.SetCenterCoordinate(FWorldArea.Width*0.5, FGate.Y.Value+FGate.Height*2);
  FMotherShip.ShowDockingBay;
  FHUD.Radar.RegisterMotherShip(FMotherShip);

  FMiningShip := TMiningShip.Create(FAtlas, True);
  FMotherShip.DockShip(FMiningShip);
  FHUD.Radar.RegisterOwnerShip(FMiningShip);

  // asteroid field
  FAsteroidField := TAsteroidField.Create(FMiningShip, LAYER_BG1);

  FMiningShip.ExitFromDockingBay_RunPath(FolderSpriteInSpace+'PathForMiningShipExitDockingBay2.txt');
  PostMessage(0); // wait anim done
end;

procedure TScreenHarvestingInSpace.CreateLevel;
begin
  case PlayerInfo.InSpace.StepPlayed of
    4: CreateLevelStep4;
    6: CreateLevelStep6;
    11: CreateLevelStep11;
    else Exception.Create('bug!  (InSpace.StepPlayed='+PlayerInfo.InSpace.StepPlayed.ToString);
  end;
end;

procedure TScreenHarvestingInSpace.DefineSubTextures(aAtlas: TAtlas);
var path: string;
  fd: TFontDescriptor;
begin
  AdditionnalScale := 1.0;
  LoadScrollingStar2DTextures(aAtlas);
  TMotherShipTopView.LoadTexture(aAtlas);
  LoadMiningShipTextures(aAtlas);
  LoadHyperSpaceGateTextures(aAtlas);
  LoadRadioMessageTextures(aAtlas);
  LoadRadarTextures(aAtlas);
  path := FolderSpriteInSpace;
  texAsteroid1 := aAtlas.AddFromSVG(path+'Asteroid1.svg', ScaleW(62), -1);
  texAsteroid2 := aAtlas.AddFromSVG(path+'Asteroid2.svg', ScaleW(72), -1);
  texAsteroid3 := aAtlas.AddFromSVG(path+'Asteroid3.svg', ScaleW(78), -1);
  texAsteroid4 := aAtlas.AddFromSVG(path+'Asteroid4.svg', ScaleW(74), -1);
  texAsteroid1Ore  := aAtlas.AddFromSVG(path+'Asteroid1Ore.svg', ScaleW(59), -1);
  texAsteroid2Ore  := aAtlas.AddFromSVG(path+'Asteroid2Ore.svg', ScaleW(68), -1);
  texAsteroid3Ore  := aAtlas.AddFromSVG(path+'Asteroid3Ore.svg', ScaleW(71), -1);
  texAsteroid4Ore  := aAtlas.AddFromSVG(path+'Asteroid4Ore.svg', ScaleW(66), -1);
  texProbe := aAtlas.AddFromSVG(path+'Probe.svg', ScaleW(15), -1);

  AddSphereParticleToAtlas(aAtlas);
  AddCrossParticleToAtlas(aAtlas);

  // ui
  CreateGameFontNumber(aAtlas); // < must be first !
  LoadIconSpaceHarvestingItem(aAtlas);
  // font for button in pause panel
  FFontText := CreateGameFontText(aAtlas);

  fd.Create('Arial', Round(FScene.Height/60), [], BGRA(0,0,0));
  FFontRadioMessage := aAtlas.AddTexturedFont(fd, FSaveGame.LanguageCharSet);

  LoadGameDialogTextures(aAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(aAtlas);
  LoadMousePointerTexture(aAtlas);
end;

procedure TScreenHarvestingInSpace.CreateObjects;
begin
  ResetVariables;
  GameState := gsUndefined;
  Audio.PauseMusicTitleMap(3.0);
  FsndMusic := Audio.AddMusic('this_1s_for_abbie.ogg', True);
  FsndMusic.SetLoopBounds(0.881, FsndMusic.TotalDuration);
  FsndMusic.Play(True);

  CheckAtlas(FAtlas, 'spaceharvest.atlas');

  // HUD
  FHUD := THUD.Create(FFontRadioMessage);

  // list of asteroid with ore
  FListOfAsteroidWithOre := TAsteroidWithOreList.Create;

  CreateLevel;

  // camera
  FCamera := FScene.CreateCamera;
  FCamera.AssignToLayerRange(LAYER_PLAYER, LAYER_BG2);
  FCamera.AutoFollow.ApplyBounds := False;
  FCamera.AutoFollow.SetTargetSurfaceCenter(FMiningShip, True);

  // pause panel
  FPausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  CustomizeMousePointer(False);
  SetGameInstructions(PlayerInfo.InSpace.HelpText);
end;

procedure TScreenHarvestingInSpace.FreeObjects;
begin
  FreeAndNil(FHUD);
  FreeAndNil(FListOfAsteroidWithOre);
  if FsndMusic <> NIL then FsndMusic.FadeOutThenKill(2.0);
  FsndMusic := NIL;

  FScene.KillCamera(FCamera);
  if FScene.RequestedScreen = ScreenMap then
    Audio.ResumeMusicTitleMap;

  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
  ChallengeMode := False;
end;

procedure TScreenHarvestingInSpace.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    //wait anim done exit from docking bay
    0: if not FMiningShip.AnimDone then PostMessage(0)
         else begin
           GameState := gsRunning;
           FCamera.AutoFollow.SetTargetSurfaceCenter(FMiningShip, False);
           FMiningShip.SetManualDrive;
           case PlayerInfo.InSpace.StepPlayed of
             4: PostMessage(100); // launch a probe near the gate
             6: PostMessage(200);  // harvest for fighter
             11: PostMessage(300); // harvest for Gigatron and Annihilator
             else raise exception.create('bug with InSpace.StepPlayed='+PlayerInfo.InSpace.StepPlayed.tostring);
           end;
         end;

    // launch a probe near the gate
    100: begin
      ShowGameInstructions(sInstructionLittleShip+LineEnding+
                           sInstructionMiningShipOre+LineEnding+
                           sInstructionMiningShipProbe);
      PostMessage(102, 3.0);
    end;
    102: begin
      FHUD.Radio.AddMessageFromPenelope(sWeHaveAttachedThe);
      PostMessage(104, 4.0);
    end;
    104: begin // gate appear on radar + beep
      FHUD.Radar.PlayBeep;
      FHUD.Radar.RegisterGate(FGate);
      PostMessage(105, 2.0);
    end;
    105: begin
      FHUD.Radio.AddMessageFromPenelope(sDoneTheBlueSymbol);
      PostMessage(110, 6.0);
    end;
    110: FHUD.Radio.AddMessageFromLR(sGotIt);
    //
    115: begin // player have droped the probe near the gate
      FHUD.Radio.AddMessageFromPenelope(Format(sTheProbeHasJustSent, [PlayerInfo.Name]));
      PostMessage(120, 4.0);
    end;
    120: begin
      FHUD.Radio.AddMessageFromPenelope(sApparentlyTheGateIsEquipped);
      PostMessage(125, 2.0);
    end;
    125: begin
      FHUD.ItemAsked.AddItem(TUIItemSpaceHarvesting.Create(4, 3));
      FHUD.ItemAsked.AddItem(TUIItemSpaceHarvesting.Create(0, 1));
      FHUD.ItemAsked.AddItem(TUIItemSpaceHarvesting.Create(3, 2));
      FHUD.Radar.PlayBeep;
      CreateAsteroidWithOre(4, FWorldArea.Width*0.5, FWorldArea.Height*0.25);
      CreateAsteroidWithOre(4, FWorldArea.Width*0.5, FWorldArea.Height*0.35);
      CreateAsteroidWithOre(4, FWorldArea.Width*0.50, FWorldArea.Height*0.40);
      CreateAsteroidWithOre(0, FWorldArea.Width*0.55, FWorldArea.Height*0.55);
      CreateAsteroidWithOre(3, FWorldArea.Width*0.65, FWorldArea.Height*0.30);
      CreateAsteroidWithOre(3, FWorldArea.Width*0.68, FWorldArea.Height*0.34);
      PostMessage(130, 2.0);
    end;
    130: begin // check if item asked is empty
      if FHUD.ItemAsked.IsEmpty then PostMessage(135)
        else PostMessage(130);
    end;
    135: begin
      FHUD.Radio.AddMessageFromPenelope(sWellDoneYouCanReturn);
      PostMessage(137, 2.0);
    end;
    137: begin
      FHUD.Radio.AddMessageFromPenelope(sIllBeAbleToDrawUp);
      PostMessage(140, 2.0);
    end;
    140: begin // check if mining ship is returned to the docking bay
      if Distance2BetweenCenters(FMiningShip, FMotherShip) < sqr(FMotherShip.Height*1.2) then
          PostMessage(145)
        else PostMessage(140);
    end;
    145: begin
      FHUD.Radio.AddMessageFromMarcus(sToEnterTheDockCircleAround);
      PostMessage(150, 2.0);
    end;
    150: begin // check if the mining ship position, angle and speed are good
      if FMiningShip.ParamsAreOkToDock then begin
        GameState := gsDocking;
        Audio.PlayMusicSuccessShort1;
        FMiningShip.StopPropulsor;
        FMiningShip.EnterDockingBay; // land
        PostMessage(155);
      end else PostMessage(150);
    end;
    155: if FMiningShip.AnimDone then PostMessage(160, 1.0)
           else PostMessage(155);
    160: begin
      PlayerInfo.InSpace.IncCurrentStep;
      PlayerInfo.InSpace.StepPlayed := PlayerInfo.InSpace.StepPlayed + 1;
      FSaveGame.Save;
      FScene.RunScreen(ScreenMotherShipConstruction);
    end;

    // HARVEST FOR FIGHTER
    200: begin
      FHUD.Radio.AddMessageFromPenelope(sGreatWeHaveANiceShield);
      PostMessage(205, 5.0);
    end;
    205: begin
      FHUD.Radio.AddMessageFromLR(sILikeItsColor);
      PostMessage(210, 3.0);
    end;
    210: begin
      FHUD.Radio.AddMessageFromPenelope(sMeTooHeeHee);
      PostMessage(215, 4.0);
    end;
    215: begin
      FHUD.Radio.AddMessageFromFather(sSorryToInterruptGirls);
      PostMessage(220, 9.0);
    end;
    220: begin
      FHUD.Radio.AddMessageFromPenelope(sWouldACombatShip);
      PostMessage(225, 9.0);
    end;
    225: begin
      FHUD.Radio.AddMessageFromFather(sIBelieveSoButCanYou);
      PostMessage(230, 5.0);
    end;
    230: begin
      FHUD.Radio.AddMessageFromPenelope(sWeAlreadyHaveTheMeansTo);
      PostMessage(235, 6.0);
    end;
    235: begin
      FHUD.Radio.AddMessageFromLR(sInThatCaseGiveMeTheList);
      PostMessage(240, 5.0);
    end;
    240: begin
      FHUD.Radio.AddMessageFromPenelope(sW7JustSCompiledIt);
      PostMessage(245, 4.0);
    end;
    245: begin
      FHUD.Radar.PlayBeep;
      FHUD.ItemAsked.AddItem(TUIItemSpaceHarvesting.Create(1, 2));
      FHUD.ItemAsked.AddItem(TUIItemSpaceHarvesting.Create(2, 1));
      FHUD.ItemAsked.AddItem(TUIItemSpaceHarvesting.Create(0, 1));
      FHUD.ItemAsked.AddItem(TUIItemSpaceHarvesting.Create(4, 1));
      CreateAsteroidWithOre(1, FWorldArea.Width*0.37, FWorldArea.Height*0.1);
      CreateAsteroidWithOre(1, FWorldArea.Width*0.5, FWorldArea.Height*0.3);
      CreateAsteroidWithOre(2, FWorldArea.Width*0.6, FWorldArea.Height*0.6);
      CreateAsteroidWithOre(0, FWorldArea.Width*0.65, FWorldArea.Height*0.5);
      CreateAsteroidWithOre(4, FWorldArea.Width*0.4, FWorldArea.Height*0.4);
      PostMessage(250, 1.0);
    end;
    250: begin
      FHUD.Radio.AddMessageFromLR(sOnIt);
      PostMessage(255, 4.0);
    end;
    255: begin // check if item asked is empty
      if FHUD.ItemAsked.IsEmpty then PostMessage(260)
        else PostMessage(255);
    end;
    260: begin
      FHUD.Radio.AddMessageFromPenelope(sThePlanToBuildTheCombatShip);
      PostMessage(150, 1.0);  // landing sequence
    end;


    // HARVEST FOR GIGATRON AND ANNIHILATOR
    300: begin
      FHUD.Radio.AddMessageFromPenelope(sWeveLocatedTheAsteroids);
      PostMessage(305, 5.0);
    end;
    305: begin
      FHUD.Radar.PlayBeep;
      FHUD.ItemAsked.AddItem(TUIItemSpaceHarvesting.Create(1, 2));
      CreateAsteroidWithOre(1, FWorldArea.Width*0.37, FWorldArea.Height*0.29);
      CreateAsteroidWithOre(1, FWorldArea.Width*0.5, FWorldArea.Height*0.3);

      FHUD.ItemAsked.AddItem(TUIItemSpaceHarvesting.Create(6, 4));
      CreateAsteroidWithOre(6, FWorldArea.Width*0.7, FWorldArea.Height*0.23);
      CreateAsteroidWithOre(6, FWorldArea.Width*0.5, FWorldArea.Height*0.37);
      CreateAsteroidWithOre(6, FWorldArea.Width*0.3, FWorldArea.Height*0.2);
      CreateAsteroidWithOre(6, FWorldArea.Width*0.1, FWorldArea.Height*0.5);

      FHUD.ItemAsked.AddItem(TUIItemSpaceHarvesting.Create(5, 4));
      CreateAsteroidWithOre(5, FWorldArea.Width*0.35, FWorldArea.Height*0.25);
      CreateAsteroidWithOre(5, FWorldArea.Width*0.68, FWorldArea.Height*0.75);
      CreateAsteroidWithOre(5, FWorldArea.Width*0.24, FWorldArea.Height*0.47);
      CreateAsteroidWithOre(5, FWorldArea.Width*0.9, FWorldArea.Height*0.53);

      FHUD.ItemAsked.AddItem(TUIItemSpaceHarvesting.Create(3, 3));
      CreateAsteroidWithOre(3, FWorldArea.Width*0.12, FWorldArea.Height*0.54);
      CreateAsteroidWithOre(3, FWorldArea.Width*0.55, FWorldArea.Height*0.37);
      CreateAsteroidWithOre(3, FWorldArea.Width*0.67, FWorldArea.Height*0.27);

      FHUD.ItemAsked.AddItem(TUIItemSpaceHarvesting.Create(2, 1));
      CreateAsteroidWithOre(2, FWorldArea.Width*0.64, FWorldArea.Height*0.29);

      FHUD.ItemAsked.AddItem(TUIItemSpaceHarvesting.Create(4, 1));
      CreateAsteroidWithOre(4, FWorldArea.Width*0.46, FWorldArea.Height*0.72);

      PostMessage(310, 1.0);
    end;
    310: begin
      FHUD.Radio.AddMessageFromLR(sWowThatsALongList);
      PostMessage(315, 2.0);
    end;
    315: begin
      FHUD.Radio.AddMessageFromPenelope(sYesWeHaveTwo);
      PostMessage(320, 4.0);
    end;
    320: begin
      FHUD.Radio.AddMessageFromLR(sOkLetsGo2);
      PostMessage(325, 2.0);
    end;
    325: begin // check if item asked is empty
      if FHUD.ItemAsked.IsEmpty then PostMessage(330)
        else PostMessage(325);
    end;
    330: begin
      FHUD.Radio.AddMessageFromPenelope(sGreatNowAllWeHaveToDo);
      PostMessage(335, 6.0);
    end;
    335: begin
      FHUD.Radio.AddMessageFromMarcus(sPJustToldMeThatYou);
      PostMessage(150);    // landing sequence
    end;



    // ANIM Harvesting Asteroid
    2000: begin
      FMiningShip.Velocity := 0;
      FMiningShip.StartHarvesting;
      PostMessage(2005);
    end;
    2005: begin
      if FMiningShip.AnimDone then begin
        FListOfAsteroidWithOre.DeleteNearest; // delete from the list of asteroid+ore
        FHUD.Radar.RemoveObject(FAsteroidHarvested); // delete on radar
        FHUD.ItemAsked.Substract(FAsteroidHarvested.OreIndex, 1); // delete on panel of asked item
        FAsteroidHarvested.MakeOreDisappear;
        FAsteroidHarvested := NIL;
        PostMessage(2010, 1.5);
      end else PostMessage(2005);
    end;
    2010: GameState := gsRunning;
  end;
end;

procedure TScreenHarvestingInSpace.Update(const aElapsedTime: single);
var d, a: single;
begin
  inherited Update(aElapsedTime);
  case FGameState of
    gsRunning: begin

      if Input.LeftPressed then
        FMiningShip.TurnLeft(aElapsedTime);

      if Input.RightPressed then
        FMiningShip.TurnRight(aElapsedTime);

      if Input.UpPressed then begin
        FMiningShip.StartPropulsor;
        FMiningShip.Accelerate(aElapsedTime);
      end else FMiningShip.StopPropulsor;

      if Input.DownPressed then
        FMiningShip.Decelerate(aElapsedTime);

      if Input.Action2Pressed then begin
        if not FAction2Pressed then begin
          FAction2Pressed := True;
          case PlayerInfo.InSpace.StepPlayed of
            4: begin  // check if the probe can be launched
              if not FProbe.Launched then begin
                case FProbe.CanBeLaunched of
                  0: begin
                    FProbe.Launch;
                    PostMessage(115, 5.0);
                  end;
                  1: FHUD.Radio.AddMessageFromPenelope(sImCancelingTheDropTooFar);
                  2: FHUD.Radio.AddMessageFromPenelope(sImCancelingTheDropOutside);
                end;
              end;
            end;
            6:;
            else raise exception.create('bug');
          end;//case
        end;
      end else FAction2Pressed := False;

      if Input.Action1Pressed then begin
        if not FAction1Pressed then begin
          FAction1Pressed := True;
          case PlayerInfo.InSpace.StepPlayed of
            4, 6, 11: begin  // check to harvest the nearest asteroid
              FAsteroidHarvested := FListOfAsteroidWithOre.GetNearest;
              if FAsteroidHarvested <> NIL then GameState := gsHarvestingAsteroid;
            end
            else raise exception.create('bug');
          end;
        end;
      end else FAction1Pressed := False;


      // change the camera zoom according the distance between mining ship and top/left docking bay
      d := Distance2(FMiningShip.GetXY, PointF(0,0));
      if not FCameraZoomed and (d < sqr(FMotherShip.Height*0.5)) then begin
        FCameraZoomed := True;
        FCamera.Scale.ChangeTo(PointF(1.5, 1.5), 4.0, idcSinusoid);
      end
      else
      if FCameraZoomed and (d > sqr(FMotherShip.Height)) then begin
        FCameraZoomed := False;
        FCamera.Scale.ChangeTo(PointF(1.0, 1.0), 4.0, idcSinusoid);
      end;
    end;
  end;//case

  // update scrolling stars
  if FMiningShip <> NIL then begin
    d := -FMiningShip.Velocity * 5.0;
    a := Deg2Rad*FMiningShip.Angle.Value;
    FStars.ScrollingStars2D.ScrollingSpeed.Value := PointF(d*cos(a), d*sin(a));
  end;

  // check if player pause the game
  if Input.PausePressed then
    FPausePanel.ShowModal;
end;

end.

