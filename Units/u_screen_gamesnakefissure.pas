unit u_screen_gamesnakefissure;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon;

type



{ TScreenSnakeFissure }

TScreenSnakeFissure = class(TGameScreenTemplate)
private type TGameState=(gsUndefined, gsRunning, gsSubmarineExploded, gsLRWin, gsNoMoreCristal);
var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FPausePanel: TInGamePausePanel;
  FsndUnderWater: TALSSound;

  procedure CreateAndSaveTileSet;

  procedure ResetVariables;
  procedure CreateLevel;
  procedure CreateSpriteFromTileEvent;
  procedure ProcessTileEvent(Sender: TTileEngine; const TileTopLeftCoor: TPointF; aTile: PTile);
public
  procedure DefineSubTextures(aAtlas: TAtlas); override;
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenSnakeFissure: TScreenSnakeFissure;

implementation
uses Forms, u_app, u_mousepointer, u_screen_map, u_utils,
  u_resourcestring, u_sprite_def2, u_submarine, u_turtle, Math;

  // Ground type
  const
    GROUND_HOLE    = 0;
    GROUND_NEUTRAL = 1;
    GROUND_ROCK    = 2;
    // Tile event
    const
      TILE_EVENT_BARRIER_RIGHT     = 0;
      TILE_EVENT_BARRIER_LEFT      = 1;
      TILE_EVENT_STONE1_LEFT       = 2;
      TILE_EVENT_STONE1_RIGHT      = 3;
      TILE_EVENT_MINE              = 4;
      TILE_EVENT_BG1               = 5;
      TILE_EVENT_BG2               = 6;
      TILE_EVENT_BG3               = 7;
      TILE_EVENT_SW_PURPLE_0       = 8;
      TILE_EVENT_SW_PURPLE_180     = 9;
      TILE_EVENT_SW_GREEN_0        = 10;
      TILE_EVENT_SW_GREEN_180      = 11;
      TILE_EVENT_SEA_WEED3         = 12;
      TILE_EVENT_SEA_WEED3_FLIPV   = 13;
      TILE_EVENT_BUBBLE            = 14;
      TILE_EVENT_SW_ORANGE_0       = 15;
      TILE_EVENT_SW_ORANGE_180     = 16;
      TILE_EVENT_FISH_BLUE_RIGHT   = 17;
      TILE_EVENT_FISH_BLUE_LEFT    = 18;
      TILE_EVENT_FISH_ORANGE_RIGHT = 19;
      TILE_EVENT_FISH_ORANGE_LEFT  = 20;
      TILE_EVENT_CRISTAL_GROUND    = 21;
      TILE_EVENT_CRISTAL_90        = 22;
      TILE_EVENT_SW_GRAY_0         = 23;
      TILE_EVENT_SW_GRAY_180       = 24;
      TILE_EVENT_CRISTAL_270       = 25;
      TILE_EVENT_CRISTAL_180       = 26;
      TILE_EVENT_SW_GRAY_90        = 27;
      TILE_EVENT_SW_GRAY_270       = 28;
      TILE_EVENT_SW_PURPLE_90      = 29;
      TILE_EVENT_SW_PURPLE_270     = 30;
      TILE_EVENT_SW_ORANGE_90      = 31;
      TILE_EVENT_SW_ORANGE_270     = 32;
      TILE_EVENT_SW_GREEN_90       = 33;
      TILE_EVENT_SW_GREEN_270      = 34;
      TILE_EVENT_TURTLE_STONE      = 35;
      TILE_EVENT_GEYSER_UP         = 36;
      TILE_EVENT_TURTLE            = 37;
      TILE_EVENT_BOAT_BROKEN       = 38;
      TILE_EVENT_EXIT              = 39;

var FWorldArea, FViewArea: TRectF;

type

TCristalGauge = class(TCircularGauge)
  constructor Create;
end;
TSeaWeedPurpleGauge = class(TCircularGauge)
  constructor Create;
end;
TSeaWeedOrangeGauge = class(TCircularGauge)
  constructor Create;
end;
TSeaWeedGrayGauge = class(TCircularGauge)
  constructor Create;
end;
TSeaWeedGreenGauge = class(TCircularGauge)
  constructor Create;
end;

TItemHarvested = (ihNone,
                  ihCristal,
                  ihSeaweedPurple, ihSeaweedOrange, ihSeaweedGreen{, ihSeaweedGray});

TSubmarineArmState = (sasIn, sasOut,
                      sasDigForward, sasDigGround, sasPlierFull,
                      sasHarvest,
                      sasMissileLoaded, sasMissileLaunched);

{ TDashboard }
const CRISTALCOST_PER_ACTION = 0.02;
      CRISTALCOST_PER_BUILD = 0.24;
type
TDashboard = class(TUIPanel)
private
  BArmIn, BArmOut, BDigForward, BDigGround, BHarvest: TUIButton;
  BBuildMissile, BMissileGO: TUIButton;
  FArmState: TSubmarineArmState;
  FItemHarvested: TItemHarvested;
  FDebrisColor: TBGRAPixel;
  FCanDecreaseCristalWhenSubmarineMove: boolean;
  procedure FormatButton(aButton: TUIButton);
  procedure FormatGoButton(aButton: TUIButton);
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
  procedure SetArmState(AValue: TSubmarineArmState);
  procedure SetItemHarvested(AValue: TItemHarvested);
private // dashboard 2
  FsndJackhammer: TALSSound;
  FDashboard2: TUIPanel;
  procedure CreateDashboard2;
  procedure AddScrew(aParentPanel: TUIPanel; aX, aY: single);
private
  procedure PlaySoundGoodCommand;
  procedure PlaySoundWrongCommand;
  function CheckPurpleGauge(aNeededAmount: single): boolean;
  function CheckOrangeGauge(aNeededAmount: single): boolean;
  function CheckGreenGauge(aNeededAmount: single): boolean;
  //function CheckGrayGauge(aNeededAmount: single): boolean;
public
  CristalGauge: TCristalGauge;
  SWPurpleGauge: TSeaWeedPurpleGauge;
  SWOrangeGauge: TSeaWeedOrangeGauge;
  SWGreenGauge: TSeaWeedGreenGauge;
  //SWGrayGauge: TSeaWeedGrayGauge;
  LedCristalGauge: TLed;
  constructor Create;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure DecreaseCristalWhenSubmarineMoves;
  procedure ShowDashboard2;
  property ItemHarvested: TItemHarvested read FItemHarvested write SetItemHarvested;
  property ArmState: TSubmarineArmState read FArmState write SetArmState;
end;

TMissile = class(TSprite)  // child, LAYER_WOLF when launched
private
  texBubble: PTexture;
  FIsLaunched: boolean;
  procedure Explode;
public
  constructor Create;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Go;
end;

TExplosion = class(TSprite)  // LAYER_GROUND  sound + anim + kill
  constructor Create(aCenterX, aCenterY: single);
end;

TBarrier = class(TSprite)  // LAYER_BG2
  constructor Create(aX, aY: single; aFlipH: boolean);
  procedure Open;
end;

{ TCustomDirectionnalArrow }

TCustomDirectionnalArrow = class(TDirectionnalArrow)
  constructor Create(aX, aY: single);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

{ TStone1 }

TStone1 = class(TSprite)  // LAYER_FXANIM
  FPrepareToFall, FFalling: boolean;
  FTremblingCount: integer;
  FOrigin: TPointF;
  procedure ProcessFalling;
  constructor Create(aX, aY: single; aFlipH: boolean);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  function CanInteractWithPlier: boolean;
  procedure Fall;
  procedure Explode;
end;

{ TGeyserUp }

TGeyserUp = class(TParticleEmitter)  // LAYER_BG2
  FGeyserWidth: single;
  constructor Create(aX, aY: single);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

{ TRepopableItem }

TRepopableItem = class(TSprite)
  ItemHarvested: TItemHarvested;
  constructor Create(aTex: PTexture; aX, aY: single; aAngle: integer;
    aItemHarvested: TItemHarvested);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  function CanInteractWithPlier: boolean; virtual;
  procedure Disappear; virtual;
end;

{ TFallingStoneTurtle }

TFallingStoneTurtle = class(TSprite)
  FPrepareToFall, FFalling: boolean;
  FTremblingCount: integer;
  FOrigin: TPointF;
  constructor Create(aCenter: TPointF);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Fall;
  procedure Explode;
end;

TStoneTurtle = class(TRepopableItem)  // LAYER_FXANIM
  constructor Create(aX, aY: single);
  procedure Disappear; override;
end;

TCristal = class(TRepopableItem) // LAYER_FXANIM
  constructor Create(aCenterX, aBottomY: single; aAngle: integer);
end;
TSeaWeed1 = class(TRepopableItem)  //       purple
  constructor Create(aCenterX, aBottomY: single; aAngle: integer);
end;
TSeaWeed2 = class(TRepopableItem)  //   green
  constructor Create(aCenterX, aBottomY: single; aAngle: integer);
end;
TSeaWeed4 = class(TRepopableItem)  //      orange
  constructor Create(aCenterX, aBottomY: single; aAngle: integer);
end;

{ TSeaWeed5 }

TSeaWeed5 = class(TRepopableItem)  //      gray
  constructor Create(aCenterX, aBottomY: single; aAngle: integer);
  function CanInteractWithPlier: boolean; override;
end;

TMine = class(TSprite)  // LAYER_BG2
  FExploded: boolean;
  FExplosion: TSprite;
  constructor Create(aX, aY: single);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Explode;
  procedure ExplodeDefered(aDelay: single);
end;

TBG = class(TSprite)  // LAYER_BG2
  constructor Create(aTex: PTexture; aCenterX, aCenterY: single);
end;

{ TWoodBoard }

TWoodBoard = class(TSprite)  // child of TBoatBroken, then LAYER_FXANIM
  constructor Create;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

{ TBoatBroken }

TBoatBroken = class(TSprite)  // LAYER_FXANIM
  FWoodBoardCreated: boolean;
  constructor Create(aX, aY: single);
  procedure CreateWoodBoard;
end;

TSeaWeed3 = class(TSprite)  // LAYER_GROUND
  constructor Create(aCenterX, aBottomY: single; aFlipV: boolean);
end;

TBubbleUnderSea = class(TParticleEmitter)
  FTimeBeforeNextShoot, FBaseTime: single;
  constructor Create(aX, aY: single);
  procedure Update(const aElapsedTime: single); override;
end;

TFish = class(TSprite) //  LAYER_GROUND
  FOrigin, FMinMax: TPointF;
  FDeltaPos: TPointFParam;
  FFishSpeed, FDistance: single;
  constructor Create(aTex: PTexture; aX, aY: single; aOrientedToRight: boolean);
  destructor Destroy; override;
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;


{ TCustomSubMarine }

TCustomSubMarine = class(TSubmarine)  // LAYER_PLAYER
private type
  TReboundDirection = (rebdE, rebdW, rebdN, rebdS, rebdSE, rebdSW, rebdNE, rebdNW);
  TCollisionPoint = record
    pt: TPointF;
    dir: TReboundDirection;
  end;
private
  FCollisionPoints: array of TCollisionPoint;
  procedure CreateCollisionPoints;
  procedure DoRebound(aDir: TReboundDirection; aElapsedTime: single);
  function ModifySpeed(aValue, aDeltaSpeed: single): single; inline;
public
  constructor Create(aLayerIndex: integer=-1);
  procedure Update(const aElapsedTime: single); override;
public  // check if pliers harvest something
  procedure CheckPlierActionOnObject;
  procedure PlayReboundSound;
end;

{ TCustomTurtle }

TCustomTurtle = class(TTurtle)  // LAYER_WOLF
  constructor Create;
  procedure WakeUpAndWalkToTheRight;
end;


var
  texTileset, texBarrierLeft, texStone1, texMine, texMineExplosion,
  texBG1, texBG2, texBG3, texBoatBroken, texWoodBoard,
  texSeaWeed1, texSeaWeed2, texSeaWeed3, texSeaWeed4, texSeaWeed5,
  texFishBlue, texFishOrange,
  texScrew,
  texIconArmIn, texIconArmOut, texIconDigForward, texIconDigGround, texIconHarvest,
  texIconSeparatorMinus, texIconSeparatorSplit, texIconSeparatorMerge,
  texIconBuildMissile, texIconGO,
  texCristal, texCristalGaugeBody, texCristalGaugeArrow, texLedBlack,
  texSmallGaugeArrow, texSWPurpleGaugeBody, texSWOrangeGaugeBody, texSWGrayGaugeBody,
  texSWGreenGaugeBody,
  texMissile, texArrowYellow: PTexture;
  FAtlas: TAtlas;
  FFontText: TTexturedFont;
  FSubmarine: TCustomSubMarine;
  FTileEngine: TTileEngine;
  FWaterBG: TQuad4Color;
  FDashboard: TDashboard;
  FCamera: TOGLCCamera;
  FMissile: TMissile;
  FTurtle: TCustomTurtle;

{ TCustomDirectionnalArrow }

constructor TCustomDirectionnalArrow.Create(aX, aY: single);
begin
  inherited Create(d4Up, texArrowYellow, LAYER_FXANIM);
  CenterX := aX + (FTileEngine.TileSize.cx-Width)*0.5;
  CenterY := aY + (FTileEngine.TileSize.cy-Height)*0.5;

  CollisionBody.AddRect(RectF(0, 0, Width, Height));
  Show;
  PostMessage(100);
end;

procedure TCustomDirectionnalArrow.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // check collision with Submarine -> win
    100: begin
      if ScreenSnakeFissure.GameState <> gsRunning then exit;
      CollisionBody.SetTransformMatrix(GetMatrixSurfaceToScene);
      FSubmarine.CollisionBody.SetTransformMatrix(FSubmarine.GetMatrixSurfaceToScene);
      if CollisionBody.CheckCollisionWith(FSubmarine)
        then ScreenSnakeFissure.GameState := gsLRWin
        else PostMessage(100, 0.1);
    end;
  end;
end;

{ TWoodBoard }

constructor TWoodBoard.Create;
begin
  inherited Create(texWoodBoard, False);
  Speed.ChangeTo(PointF(0,-FScene.Height*0.1), 2.0);
  Angle.AddConstant(10);
  CollisionBody.AddPolygon([PointF(0, 0), PointF(Width, 0), PointF(Width, Height), PointF(0, Height)]);
  PostMessage(0, 1.5);
end;

procedure TWoodBoard.Update(const aElapsedTime: single);
var i: integer;
  mine: TMine;
begin
  inherited Update(aElapsedTime);

  // check collision with mine
  CollisionBody.SetTransformMatrix(GetMatrixSurfaceToScene);
  for i:=0 to FScene.Layer[LAYER_BG2].SurfaceCount-1 do
    if FScene.Layer[LAYER_BG2].Surface[i] is TMine then begin
      mine := TMine(FScene.Layer[LAYER_BG2].Surface[i]);
      mine.CollisionBody.SetTransformMatrix(mine.GetMatrixSurfaceToScene);
      if CollisionBody.CheckCollisionWith(mine) then begin
        mine.Explode;
        Kill;
        exit;
      end;
    end;
end;

procedure TWoodBoard.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // move to layer defered
    0: MoveToLayer(LAYER_FXANIM);
  end;
end;

{ TBoatBroken }

constructor TBoatBroken.Create(aX, aY: single);
begin
  inherited Create(texBoatBroken, False);
  FScene.Add(Self, LAYER_FXANIM);
  CenterX := aX+FTileEngine.TileSize.cx*0.5;
  BottomY := aY+FTileEngine.TileSize.cy*0.3;

  // Collision body
  CollisionBody.AddPolygon([PointF(0.138*Width, 0.408*Height), PointF(0.366*Width, 0.984*Height),
    PointF(0.824*Width, 0.984*Height), PointF(0.465*Width, 0.363*Height),
    PointF(0.193*Width, 0.327*Height), PointF(0.138*Width, 0.408*Height)]);
end;

procedure TBoatBroken.CreateWoodBoard;
var o: TWoodBoard;
begin
  if FWoodBoardCreated then exit;
  FWoodBoardCreated := True;
  o := TWoodBoard.Create;
  AddChild(o, -1);
  o.CenterOnParent;
end;

{ TFallingStoneTurtle }

constructor TFallingStoneTurtle.Create(aCenter: TPointF);
begin
  inherited Create(texStone1, False);
  FScene.Add(Self, LAYER_FXANIM);
  Angle.Value := 90;
  SetCenterCoordinate(aCenter);
  FOrigin := aCenter;
  CollisionBody.AddPolygon([PointF(0, 0), PointF(Width, 0), PointF(Width, Height), PointF(0, Height)]);
  Fall;
end;

procedure TFallingStoneTurtle.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if not FFalling then exit;
  // check collision with turtle
  if FTurtle.State <> tursSleep then exit;
  FTurtle.CollisionBody.SetTransformMatrix(FTurtle.GetMatrixSurfaceToScene);
  CollisionBody.SetTransformMatrix(GetMatrixSurfaceToScene);
  if CollisionBody.CheckCollisionWith(FTurtle) then begin
    Explode;
    FTurtle.WakeUpAndWalkToTheRight;
  end;
end;

procedure TFallingStoneTurtle.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // anim fall
    0: begin
      inc(FTremblingCount);
      if FTremblingCount = 7 then begin
        PostMessage(10);
        exit;
      end;
      SetCenterCoordinate(FOrigin+PointF(Random*PPIScale(5), Random*PPIScale(5)));
      PostMessage(0, 0.1);
    end;
    10: begin
      SetCenterCoordinate(FOrigin);
      Angle.AddConstant(-360);
      Speed.y.ChangeTo(FScene.Height*0.5, 0.5, idcDrop);
      //KillDefered(0.5);
      FFalling := True;
    end;

  end;
end;

procedure TFallingStoneTurtle.Fall;
begin
  if FPrepareToFall or FFalling then exit;
  FPrepareToFall := True;
  FTremblingCount := 0;
  PostMessage(0);
end;

procedure TFallingStoneTurtle.Explode;
begin
  Audio.PlayThenKillSound('CollisionPunchShort.ogg', 0.5, 0.0, 1.0+Random*0.25-0.125, Audio.FXReverbUnderWater, 1.0);
  Kill;
  ExplodeTexture(FScene, LAYER_FXANIM, texStone1, 5, 3, Center, 0.5, PointF(1,1),
  60, 180, FScene.Width*0.2, 0.2, 1.5);
end;

{ TStoneTurtle }

constructor TStoneTurtle.Create(aX, aY: single);
begin
  inherited Create(texStone1, aX, aY+FTileEngine.TileSize.cy*1.2, 90, ihNone);
  Pivot := PointF(0.5,0.5);
end;

procedure TStoneTurtle.Disappear;
begin
  Freeze := False;
  Opacity.Value := 0;
  PostMessage(0, 17.0);
  TFallingStoneTurtle.Create(Center);
end;


{ TGeyserUp }

constructor TGeyserUp.Create(aX, aY: single);
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_BG2);
  LoadFromFile(ParticleFolder+'UnderSeaGeyser.par', FAtlas);
  SetCoordinate(aX, aY);
  FGeyserWidth := FTileEngine.TileSize.cx*1.5;
  SetEmitterTypeLine(0, FGeyserWidth);
  FParticleParam.Velocity := 10*FTileEngine.TileSize.cy*2;
  FParticleParam.Life := 11*FTileEngine.TileSize.cy/FParticleParam.Velocity;
  PostMessage(0); // survey the turtle position
end;

procedure TGeyserUp.Update(const aElapsedTime: single);
var geyserLength: single;
  rSub: TRectF;
  p: TPointF;
begin
  inherited Update(aElapsedTime);

  // check if submarine collide the geyser
  geyserLength := FParticleParam.Velocity * FParticleParam.Life;
  rSub := FSubmarine.GetRectAreaInLocalSpace;
  p := FTileEngine.PositionOnMap.Value + FSubmarine.GetXY;
  rSub.Offset(p.x, p.y);

  p := GetXY;
  if (rSub.Right > p.x) and (rSub.Left < p.x+FGeyserWidth) and
     (rSub.Bottom > p.y-geyserLength) and (rSub.Top < p.y) then begin
    FSubMarine.PlayReboundSound;
    if FTileEngine.ScrollSpeed.x.Value < 0 then FTileEngine.ScrollSpeed.x.Value := FScene.Width*0.5
      else FTileEngine.ScrollSpeed.x.Value := -FScene.Width*0.5;
    FTileEngine.ScrollSpeed.x.ChangeTo(0, 1.0);
  end;
end;

procedure TGeyserUp.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // survey the turtle position: if turtle is above the geyser, it stops
    0: begin
      if Abs(FTurtle.CenterX - (X.Value+FTileEngine.TileSize.cx*0.75)) < FTileEngine.TileSize.cx*3 then begin
        FParticleParam.Life := FTileEngine.TileSize.cy/FParticleParam.Velocity;
        PostMessage(5, 5.0);
      end else PostMessage(0, 0.1);
    end;
    5: Kill;
  end;
end;

{ TCustomTurtle }

constructor TCustomTurtle.Create;
begin
  inherited Create(LAYER_WOLF);
  Posture_Idle(0);
  FlipH := True;
  State := tursSleep;
  CenterX := 21*FTileEngine.TileSize.cx + FTileEngine.TileSize.cx*0.5;
  BottomY := 69*FTileEngine.TileSize.cy + FTileEngine.TileSize.cy*0.3;
end;

procedure TCustomTurtle.WakeUpAndWalkToTheRight;
begin
  WakeUpAndWalkTo(CenterX + FTileEngine.TileSize.cx*16);
end;

{ TExplosion }

constructor TExplosion.Create(aCenterX, aCenterY: single);
begin
  Audio.PlayThenKillSound('big-boom.ogg', 0.8, 0.0, 1.0+Random*0.5-0.25, Audio.FXReverbUnderWater, 1.0);
  inherited Create(texMineExplosion, False);
  FScene.Add(Self, LAYER_GROUND);
  SetCenterCoordinate(aCenterX, aCenterY);
  AddAndPlayScenario('ScaleChange 2.0 0.125 idcLinear'#10+
                     'Wait 0.125'#10+
                     'ScaleChange 1.0 0.125 idcLinear'#10+
                     'Wait 0.125'#10+
                     'ScaleChange 2.0 0.125 idcLinear'#10+
                     'Wait 0.125'#10+
                     'ScaleChange 1.0 0.125 idcLinear'#10+
                     'Wait 0.125'#10+
                     'OpacityChange 0 0.5 idcLinear'#10+
                     'ScaleChange 1.5 0.5 idcLinear'#10+
                     'Wait 0.5'#10+
                     'Kill');
end;

{ TMissile }

procedure TMissile.Explode;
begin
  TExplosion.Create(CenterX, CenterY);
  Kill;
end;

constructor TMissile.Create;
begin
  inherited Create(texMissile, False);
  CollisionBody.AddRect(RectF(0, Height*0.25, Width, Height*0.75));

  texBubble := FAtlas.RetrieveTextureByFileName('bubble_particle_less_transparent.svg');
end;

procedure TMissile.Update(const aElapsedTime: single);
var i: integer;
  barrier: TBarrier;
  mine: TMine;
  stone: TStone1;
  stoneTurtle: TStoneTurtle;
  boat: TBoatBroken;
  function CollisionWithTile(aLocalPt: TPointF): boolean;
  begin
    aLocalPt := SurfaceToWorld(aLocalPt) - FTileEngine.PositionOnMap.Value;
    Result := FTileEngine.GetGroundType(aLocalPt) = GROUND_ROCK;
  end;
begin
  inherited Update(aElapsedTime);
  if not FIsLaunched then
    FlipH := FSubmarine.FlipH
  else begin
    // check collision with tile ground
    if CollisionWithTile(PointF(0, Height*0.25)) or
       CollisionWithTile(PointF(0, Height*0.75)) or
       CollisionWithTile(PointF(Width, Height*0.25)) or
       CollisionWithTile(PointF(Width, Height*0.75)) then begin
      Explode;
    end;
    // check collision with barrier and mine
    CollisionBody.SetTransformMatrix(GetMatrixSurfaceToScene);
    for i:=0 to FScene.Layer[LAYER_BG2].SurfaceCount-1 do
      if FScene.Layer[LAYER_BG2].Surface[i] is TBarrier then begin
        barrier := TBarrier(FScene.Layer[LAYER_BG2].Surface[i]);
        barrier.CollisionBody.SetTransformMatrix(barrier.GetMatrixSurfaceToScene);
        if CollisionBody.CheckCollisionWith(barrier) then begin
          barrier.Open;
          Explode;
          exit;
        end;
      end
      else
      if FScene.Layer[LAYER_BG2].Surface[i] is TMine then begin
        mine := TMine(FScene.Layer[LAYER_BG2].Surface[i]);
        mine.CollisionBody.SetTransformMatrix(mine.GetMatrixSurfaceToScene);
        if CollisionBody.CheckCollisionWith(mine) then begin
          mine.Explode;
          Explode;
          exit;
        end;
      end;
      // check collision with stone1, TStoneTurtle or TBoatBroken
      for i:=0 to FScene.Layer[LAYER_FXANIM].SurfaceCount-1 do begin
        if FScene.Layer[LAYER_FXANIM].Surface[i] is TStone1 then begin
          stone := TStone1(FScene.Layer[LAYER_FXANIM].Surface[i]);
          stone.CollisionBody.SetTransformMatrix(stone.GetMatrixSurfaceToScene);
          if CollisionBody.CheckCollisionWith(stone) then begin
            stone.Fall;
            Explode;
            exit;
          end;
        end
        else    //TStoneTurtle
        if FScene.Layer[LAYER_FXANIM].Surface[i] is TStoneTurtle then begin
          stoneTurtle := TStoneTurtle(FScene.Layer[LAYER_FXANIM].Surface[i]);
          stoneTurtle.CollisionBody.SetTransformMatrix(stoneTurtle.GetMatrixSurfaceToScene);
          if CollisionBody.CheckCollisionWith(stoneTurtle) then begin
            stoneTurtle.Disappear;
            Explode;
            exit;
          end;
        end
        else
        if FScene.Layer[LAYER_FXANIM].Surface[i] is TBoatBroken then begin
          boat := TBoatBroken(FScene.Layer[LAYER_FXANIM].Surface[i]);
          boat.CollisionBody.SetTransformMatrix(boat.GetMatrixSurfaceToScene);
          if CollisionBody.CheckCollisionWith(boat) then begin
            boat.CreateWoodBoard;
            Explode;
            exit;
          end;
        end;
      end;
  end;
end;

procedure TMissile.ProcessMessage(UserValue: TUserMessageValue);
var o: TSprite;
  v: single;
begin
  case UserValue of
    0: begin
      o := TSprite.Create(texBubble, False);
      FScene.Add(o, LAYER_WOLF);
      o.SetCenterCoordinate(CenterX, CenterY);
      o.Speed.Y.ChangeTo(-FScene.Height*0.1, 0.5);
      v := 0.3 - Random*0.15;
      o.Scale.Value := PointF(v, v);
      o.Scale.ChangeTo(PointF(0.1, 0.1), 2.0);
      o.Opacity.ChangeTo(0, 2.0);
      o.KillDefered(2.0);
      PostMessage(0, Random*0.05);
    end;
  end;
end;

procedure TMissile.Go;
begin
  with Audio.AddSound('rocket-launch.ogg', 0.7, False) do begin
    if FlipH then Pan.ChangeTo(-1.0, 1.0) else Pan.ChangeTo(1.0, 1.0);
    ApplyEffect(Audio.FXReverbUnderWater);
    SetEffectDryWetVolume(Audio.FXReverbUnderWater, 0.8);
    ApplyEffect(Audio.FXReverbLong);
    SetEffectDryWetVolume(Audio.FXReverbLong, 0.8);
    PlayThenKill(True);
  end;
  MoveToLayer(LAYER_WOLF);
  SetCoordinate(GetXY+FTileEngine.PositionOnMap.Value);
  Speed.x.Value := FScene.Width*0.5;
  if FSubmarine.FlipH then Speed.x.Value := -Speed.x.Value;
  KillDefered(5.0);
  FIsLaunched := True;

  PostMessage(0); // bubble
end;

{ TSeaWeedGreenGauge }

constructor TSeaWeedGreenGauge.Create;
begin
  inherited Create(texSWGreenGaugeBody, texSmallGaugeArrow);
  Percent := 0.0;
end;

{ TSeaWeedGrayGauge }

constructor TSeaWeedGrayGauge.Create;
begin
  inherited Create(texSWGrayGaugeBody, texSmallGaugeArrow);
  Percent := 0.0;
end;

{ TSeaWeedOrangeGauge }

constructor TSeaWeedOrangeGauge.Create;
begin
  inherited Create(texSWOrangeGaugeBody, texSmallGaugeArrow);
  Percent := 0.0;
end;

{ TSeaWeedPurpleGauge }

constructor TSeaWeedPurpleGauge.Create;
begin
  inherited Create(texSWPurpleGaugeBody, texSmallGaugeArrow);
  Percent := 0.0;
end;

{ TSeaWeed5 }

constructor TSeaWeed5.Create(aCenterX, aBottomY: single; aAngle: integer);
begin
  inherited Create(texSeaWeed5, aCenterX, aBottomY, aAngle, ihNone); // ihSeaweedGray);
  FlipH := Random > 0.5;

{  inherited Create(texSeaWeed5, False);
  FScene.Add(Self, LAYER_FXANIM);
  CenterX := aCenterX;
  if aFlipV then Y.Value := aBottomY
    else BottomY := aBottomY;
  FlipV := aFlipV;
  FlipH := Random > 0.5;
  Freeze := True;
  AddCollisionRect;
  ItemHarvested := ihSeaweedGray;  }
end;

function TSeaWeed5.CanInteractWithPlier: boolean;
begin
  // avoid the harvest of the gray sea seed
  Result := False;
end;

{ TRepopableItem }

constructor TRepopableItem.Create(aTex: PTexture; aX, aY: single;
  aAngle: integer; aItemHarvested: TItemHarvested);
var wt, ht: single;
begin
  inherited Create(aTex, False);
  FScene.Add(Self, LAYER_FXANIM);
  Angle.Value := aAngle;
  ItemHarvested := aItemHarvested;
  //CollisionBody.AddRect(RectF(0, 0, Width, Height));
  CollisionBody.AddPolygon([PointF(0,0), PointF(Width,0), PointF(Width,Height), PointF(0, Height)]);
  Freeze := True;

  Pivot := PointF(0.5, 1.0);

  // adjust coor according to the angle
  wt := FTileEngine.TileSize.cx*0.5;
  ht := FTileEngine.TileSize.cy*0.5;
  case aAngle of
    0: begin
      CenterX := aX + wt;
      BottomY := aY + ht*0.5;
    end;
    90: begin   // wall left
      CenterX := aX + wt*1.4;
      BottomY := aY + ht;
    end;
    180: begin  // vertical inversion
      CenterX := aX + wt;
      BottomY := aY + ht*1.4;
    end;
    270, -90: begin  // wall right
      CenterX := aX + wt*0.5;
      BottomY := aY + ht;
    end;
  end;
end;

procedure TRepopableItem.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin
      Opacity.ChangeTo(255, 1.0);
      PostMessage(5, 1.0);
    end;
    5: Freeze := True;
  end;
end;

function TRepopableItem.CanInteractWithPlier: boolean;
begin
  Result := Opacity.Value = 255;
end;

procedure TRepopableItem.Disappear;
begin
  Freeze := False;
  Opacity.ChangeTo(0, 1.0);
  PostMessage(0, 17.0);
end;


constructor TCristalGauge.Create;
begin
  inherited Create(texCristalGaugeBody, texCristalGaugeArrow);
  Percent := 1.0;
end;

constructor TCristal.Create(aCenterX, aBottomY: single; aAngle: integer);
begin
  inherited Create(texCristal, aCenterX, aBottomY, aAngle, ihCristal);
  Tint.Value := GetBlueCristalTint;
end;

{ TDashboard }

procedure TDashboard.FormatButton(aButton: TUIButton);
begin
  aButton.BodyShape.SetShapeRoundRect(20, 20, PPIScale(8), PPIScale(8), PPIScale(3));
  aButton.BodyShape.Fill.Color := BGRA(75,150,50);
  aButton.OnClick := @ProcessButtonClick;
end;

procedure TDashboard.FormatGoButton(aButton: TUIButton);
begin
  aButton.AutoSize := False;
  aButton.BodyShape.SetShapeEllipse(ScaleW(24), ScaleW(24), PPIScale(3));
  aButton.BodyShape.Fill.Color := BGRA(75,150,50);
  aButton.OnClick := @ProcessButtonClick;
end;

procedure TDashboard.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  if Sender = BArmIn then begin
    if ArmState = sasOut then begin
      PlaySoundGoodCommand;
      ArmState := sasIn;
    end else PlaySoundWrongCommand;
  end;

  if Sender = BArmOut then begin
    if ArmState = sasIn then begin
      PlaySoundGoodCommand;
      ArmState := sasOut;
    end else PlaySoundWrongCommand;
  end;

  if Sender = BDigForward then begin
    if ArmState = sasOut then begin
      PlaySoundGoodCommand;
      ArmState := sasDigForward;
    end else PlaySoundWrongCommand;
  end;

  if Sender = BDigGround then begin
    if ArmState = sasOut then begin
      PlaySoundGoodCommand;
      ArmState := sasDigGround;
    end else PlaySoundWrongCommand;
  end;

  if Sender = BHarvest then begin
    if ArmState = sasPlierFull {FItemHarvested <> ihNone} then begin
      PlaySoundGoodCommand;
      ArmState := sasHarvest;
    end else PlaySoundWrongCommand;
  end;

  if Sender = BBuildMissile then
    if ArmState = sasIn {not FSubmarine.MissileReadyToLaunch} then begin
      CheckPurpleGauge(CRISTALCOST_PER_BUILD);
      CheckOrangeGauge(CRISTALCOST_PER_BUILD);
      CheckGreenGauge(CRISTALCOST_PER_BUILD);
      if CheckPurpleGauge(CRISTALCOST_PER_BUILD) and
         CheckOrangeGauge(CRISTALCOST_PER_BUILD) and
         CheckGreenGauge(CRISTALCOST_PER_BUILD) then begin
        PlaySoundGoodCommand;
        SWPurpleGauge.AddDelta(-CRISTALCOST_PER_BUILD);
        SWOrangeGauge.AddDelta(-CRISTALCOST_PER_BUILD);
        SWGreenGauge.AddDelta(-CRISTALCOST_PER_BUILD);
        FMissile := TMissile.Create;
        FSubmarine.FMissileRamp.AddChild(FMissile, 0);
        FMissile.CenterX := FSubmarine.FMissileRamp.Width*0.5;
        FMissile.BottomY := FSubmarine.FMissileRamp.Height*0.1;
        FSubmarine.StartShowMissileAnimation;
        PostMessage(600);  // wait the end of the anim
      end else PlaySoundWrongCommand;
    end else PlaySoundWrongCommand;

  if Sender = BMissileGO then
    if ArmState = sasMissileLoaded then begin
      ArmState := sasMissileLaunched;
      PlaySoundGoodCommand;
      FMissile.GO;
      FSubmarine.HideMissileRamp;
      PostMessage(610);
    end else PlaySoundWrongCommand;

end;

procedure TDashboard.SetArmState(AValue: TSubmarineArmState);
begin
  if FArmState = AValue then Exit;
  FArmState := AValue;
  case AValue of
    sasIn: begin
      FSubmarine.Posture_Idle(1.5);
      CristalGauge.Percent := CristalGauge.Percent-CRISTALCOST_PER_ACTION;
    end;
    sasOut: begin
      FSubmarine.Posture_ArmDeployed(1.5);
      CristalGauge.Percent := CristalGauge.Percent-CRISTALCOST_PER_ACTION;
    end;
    sasDigForward: begin
      FSubmarine.Posture_DigForward(0.7);
      CristalGauge.Percent := CristalGauge.Percent-CRISTALCOST_PER_ACTION;
      PostMessage(0, 0.7);
    end;
    sasDigGround: begin
      FSubmarine.Posture_DigGround(0.7);
      CristalGauge.Percent := CristalGauge.Percent-CRISTALCOST_PER_ACTION;
      PostMessage(0, 0.7);
    end;
    sasHarvest: begin
      CristalGauge.Percent := CristalGauge.Percent-CRISTALCOST_PER_ACTION;
      PostMessage(200);
    end;
  end;
end;

procedure TDashboard.SetItemHarvested(AValue: TItemHarvested);
begin
  FItemHarvested := AValue;
  case AValue of
    ihNone:;
    ihCristal: FDebrisColor := BGRA(38,131,250);
    ihSeaweedPurple: FDebrisColor := BGRA(181,21,154);
    ihSeaweedOrange: FDebrisColor := BGRA(253,180,52);
    ihSeaweedGreen: FDebrisColor := BGRA(120,155,39);
    //ihSeaweedGray: FDebrisColor := BGRA(203,196,248);
  end;

  if AValue <> ihNone then PostMessage(300); // harvest button blink
end;

procedure TDashboard.CreateDashboard2;
var
  o: TSprite;
begin
  FDashboard2 := TUIPanel.Create(FScene);
  FScene.Add(FDashboard2, LAYER_GAMEUI);
  with FDashboard2 do begin
    BodyShape.SetShapeRoundRect(ScaleW(130), ScaleH(169), PPIScale(8), PPIScale(8), PPIScale(3));
    BodyShape.Fill.Color := BGRA(30,30,30,120);
    ChildClippingEnabled := False;    // clipping is not necessary
    SetCoordinate(FScene.Width - Width, 0);
    Visible := False;
  end;

  SWPurpleGauge := TSeaWeedPurpleGauge.Create;
  FDashboard2.AddChild(SWPurpleGauge, 0);
  SWPurpleGauge.SetCoordinate(ScaleW(16), ScaleH(14));
//SWPurpleGauge.Percent:=1.0;

  SWOrangeGauge := TSeaWeedOrangeGauge.Create;
  FDashboard2.AddChild(SWOrangeGauge, 0);
  SWOrangeGauge.SetCoordinate(ScaleW(71), ScaleH(14));
//SWOrangeGauge.Percent:=1.0;

  SWGreenGauge := TSeaWeedGreenGauge.Create;
  FDashboard2.AddChild(SWGreenGauge, 0);
  SWGreenGauge.SetCoordinate(ScaleW(16), ScaleH(62));
//SWGreenGauge.Percent:=1.0;

{  SWGrayGauge := TSeaWeedGrayGauge.Create;
  FDashboard2.AddChild(SWGrayGauge, 0);
  SWGrayGauge.SetCoordinate(ScaleW(71), ScaleH(62)); }
//SWGrayGauge.Percent:=1.0;

  BBuildMissile := TUIButton.Create(FScene, '', NIL, texIconBuildMissile);
  FDashboard2.AddChild(BBuildMissile, 0);
  FormatButton(BBuildMissile);
  BBuildMissile.BodyShape.ResizeCurrentShape(ScaleW(65), ScaleH(32), True);
  BBuildMissile.SetCoordinate(ScaleW(11), ScaleH(127));

  o := TSprite.Create(texIconSeparatorMinus, False);
  FDashboard2.AddChild(o, 0);
  o.BindToSprite(BBuildMissile, BBuildMissile.Width+PPIScale(2), (BBuildMissile.Height-o.Height)*0.5);

  BMissileGo := TUIButton.Create(FScene, '', NIL, texIconGO);
  FDashboard2.AddChild(BMissileGo, 0);
  FormatGoButton(BMissileGo);
  BMissileGo.AnchorPosToSurface(o, haLeft, haRight, PPIScale(2), vaCenter, vaCenter, 0);

  AddScrew(FDashboard2, ScaleW(3), ScaleH(3));
  AddScrew(FDashboard2, FDashboard2.Width-texScrew^.FrameWidth-ScaleW(3), ScaleH(3));
  AddScrew(FDashboard2, ScaleW(3), FDashboard2.Height-texScrew^.FrameHeight-ScaleH(3));
  AddScrew(FDashboard2, FDashboard2.Width-texScrew^.FrameWidth-ScaleW(3), FDashboard2.Height-texScrew^.FrameHeight-ScaleH(3));

end;

procedure TDashboard.AddScrew(aParentPanel: TUIPanel; aX, aY: single);
var o: TSprite;
begin
  o := TSprite.Create(texScrew, False);
  aParentPanel.Addchild(o, 0);
  o.SetCoordinate(aX, aY);
  o.Freeze := True;
  o.Angle.Value := Random*180;
end;

procedure TDashboard.PlaySoundGoodCommand;
begin
  Audio.PlayThenKillSound('button-beep_Short.ogg', 1.0);
end;

procedure TDashboard.PlaySoundWrongCommand;
begin
  Audio.PlayThenKillSound('buzzing-relay.ogg', 1.0);
end;

function TDashboard.CheckPurpleGauge(aNeededAmount: single): boolean;
begin
  Result := SWPurpleGauge.Percent >= aNeededAmount;
  if not Result then SWPurpleGauge.BlinkRed;
end;

function TDashboard.CheckOrangeGauge(aNeededAmount: single): boolean;
begin
  Result := SWOrangeGauge.Percent >= aNeededAmount;
  if not Result then SWOrangeGauge.BlinkRed;
end;

function TDashboard.CheckGreenGauge(aNeededAmount: single): boolean;
begin
  Result := SWGreenGauge.Percent >= aNeededAmount;
  if not Result then SWGreenGauge.BlinkRed;
end;

{function TDashboard.CheckGrayGauge(aNeededAmount: single): boolean;
begin
  Result := SWGrayGauge.Percent >= aNeededAmount;
  if not Result then SWGrayGauge.BlinkRed;
end; }

constructor TDashboard.Create;
var o: TSprite;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_GAMEUI);
  BodyShape.SetShapeRoundRect(ScaleW(418), ScaleH(71), PPIScale(8), PPIScale(8), PPIScale(3));
  BodyShape.Fill.Color := BGRA(30,30,30,120);
  ChildClippingEnabled := False;    // clipping is not necessary
  SetCoordinate(FScene.Width - Width, 0);

  BArmIn := TUIButton.Create(FScene, '', NIL, texIconArmIn);
  AddChild(BArmIn, 1);
  FormatButton(BArmIn);
  BArmIn.AnchorPosToParent(haLeft, haLeft, PPIScale(5), vaCenter, vaCenter, 0);

  o := TSprite.Create(texIconSeparatorMinus, False);
  AddChild(o, 1);
  o.BindToSprite(BArmIn, BArmIn.Width+PPIScale(2), (BArmIn.Height-o.Height)*0.5);

  BArmOut := TUIButton.Create(FScene, '', NIL, texIconArmOut);
  AddChild(BArmOut, 1);
  FormatButton(BArmOut);
  BArmOut.AnchorPosToSurface(o, haLeft, haRight, PPIScale(2), vaCenter, vaCenter, 0);

  o := TSprite.Create(texIconSeparatorSplit, False);
  AddChild(o, 1);
  o.BindToSprite(BArmOut, BArmOut.Width+PPIScale(2), (BArmOut.Height-o.Height)*0.5);

  BDigForward := TUIButton.Create(FScene, '', NIL, texIconDigForward);
  AddChild(BDigForward, 1);
  FormatButton(BDigForward);
  BDigForward.AnchorPosToSurface(o, haLeft, haRight, PPIScale(2), vaBottom, vaCenter, -PPIScale(2));

  BDigGround := TUIButton.Create(FScene, '', NIL, texIconDigGround);
  AddChild(BDigGround, 1);
  FormatButton(BDigGround);
  BDigGround.AnchorPosToSurface(o, haLeft, haRight, PPIScale(2), vaTop, vaCenter, PPIScale(2));

  o := TSprite.Create(texIconSeparatorMerge, False);
  AddChild(o, 1);
  o.CenterY := CenterY;;
  o.BindToSprite(BDigGround, BDigGround.Width+PPIScale(2), -PPIScale(2)-o.Height*0.5);

  BHarvest := TUIButton.Create(FScene, '', NIL, texIconHarvest);
  AddChild(BHarvest, 1);
  FormatButton(BHarvest);
  BHarvest.AnchorPosToSurface(o, haLeft, haRight, PPIScale(2), vaCenter, vaCenter, 0);

  CristalGauge := TCristalGauge.Create;
  AddChild(CristalGauge, 1);
  CristalGauge.CenterY := CenterY;
  CristalGauge.RightX := Width - PPIScale(15);

  LedCristalGauge := TLed.Create(texLedBlack);
  AddChild(LedCristalGauge, 1);
  LedCristalGauge.RightX := CristalGauge.X.Value+CristalGauge.Width*0.1;
  LedCristalGauge.BottomY := CristalGauge.BottomY;

  AddScrew(Self, ScaleW(3), ScaleH(3));
  AddScrew(Self, ScaleW(185), ScaleH(3));
  AddScrew(Self, ScaleW(408), ScaleH(3));
  AddScrew(Self, ScaleW(3), ScaleH(61));
  AddScrew(Self, ScaleW(185), ScaleH(61));
  AddScrew(Self, ScaleW(408), ScaleH(61));

  CreateDashboard2;

  PostMessage(400); // cristal gauge survey
  FCanDecreaseCristalWhenSubmarineMove := True;
end;

procedure TDashboard.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // dig forward anim
    0: begin
      FsndJackhammer := Audio.AddSound('jackhammer.ogg', 0.8, True);
      FsndJackhammer.ApplyEffect(Audio.FXReverbUnderWater);
      FsndJackhammer.SetEffectDryWetVolume(Audio.FXReverbUnderWater, 1.0);
      FsndJackhammer.Play(True);
      FSubmarine.StartDigAnimation;
      PostMessage(10, 3.0);
    end;
    10: begin
      FsndJackhammer.Stop;
      FsndJackhammer.Kill;
      FsndJackhammer := NIL;
      FSubmarine.StopDigAnimation;
      FSubMarine.CheckPlierActionOnObject;
      if self.ItemHarvested = ihNone then ArmState := sasOut
        else ArmState := sasPlierFull;
    end;

    // harvest anim
    200: begin
      FSubmarine.Posture_ArmAboveTank(1.5);
      PostMessage(202, 1.5);
    end;
    202: begin
      FSubmarine.OpenTrapDoor(0.5);
      PostMessage(203, 0.5);
    end;
    203: begin
      FSubmarine.OpenPlier(0.5);
      PostMessage(205, 0.5);
    end;
    205: begin
      FSubmarine.StartHarvestDebrisAnimation(FDebrisColor);
      PostMessage(207, 2.0);
    end;
    207: begin
      FSubmarine.StopHarvestDebrisAnimation;
      PostMessage(210, 0.5);
    end;
    210: begin
      FSubmarine.ClosePlier(0.5);
      PostMessage(215, 0.5);
    end;
    215: begin
      FSubmarine.Posture_Idle(1.75);
      FSubmarine.CloseTrapDoor(0.5);
      ArmState := sasIn;
      PostMessage(220, 0.5);
    end;
    220: begin  // increase gauge
      case FItemHarvested of
        ihNone:;
        ihCristal: CristalGauge.Percent := 1.0;
        ihSeaweedPurple: SWPurpleGauge.AddDelta(1.0);
        ihSeaweedOrange: SWOrangeGauge.AddDelta(1.0);
        //ihSeaweedGray: SWGrayGauge.AddDelta(1.0);
        ihSeaweedGreen: SWGreenGauge.AddDelta(1.0);
      end;
      FItemHarvested := ihNone;
    end;

    // the pliers are full -> harvest button blink
    300: begin
      if FItemHarvested = ihNone then exit;
      BHarvest.BodyShape.Fill.Color := BGRAWhite;
      PostMessage(305, 0.4);
    end;
    305: begin
      BHarvest.BodyShape.Fill.Color := BGRA(75,150,50);
      if FItemHarvested = ihNone then exit;
      PostMessage(300, 0.4);
    end;

    // LED BLINK when cristal gauge is low
    400: begin
      if CristalGauge.Percent < 0.3 then LedCristalGauge.StartToBlink(BGRA(255,50,50), True)
        else LedCristalGauge.StopToBlink;
      PostMessage(400, 0.1);
    end;

    500: FCanDecreaseCristalWhenSubmarineMove := True;

    // wait the end of the load of the missile
    600: if FSubmarine.State = subsMissileReadyToLaunch then ArmState := sasMissileLoaded
           else PostMessage(600);

    // wait the end of the ramp hide animation
    610: if FSubmarine.State = subsIdle then ArmState := sasIn
           else PostMessage(610);

  end;
end;

procedure TDashboard.DecreaseCristalWhenSubmarineMoves;
begin
  if not FCanDecreaseCristalWhenSubmarineMove then exit;
  FCanDecreaseCristalWhenSubmarineMove := False;
  CristalGauge.AddDelta(-0.005);
  PostMessage(500, 0.3);
end;

procedure TDashboard.ShowDashboard2;
begin
  FDashboard2.Visible := True;
  RightX := FDashboard2.X.Value;
end;

{ TFish }

constructor TFish.Create(aTex: PTexture; aX, aY: single;
  aOrientedToRight: boolean);
begin
  inherited Create(aTex, False);
  FScene.Add(Self, LAYER_GROUND);
  SetCoordinate(aX, aY);
  FOrigin := PointF(aX, aY);
  Pivot := PointF(1.0, 0.5);
 // SetGrid(2, 4);
 // ApplyDeformation(dtWaveV);
  FDeltaPos := TPointFParam.Create;
  FFishSpeed := 10.0 + Random*5.0;
  FDistance := FScene.Width;
  if aOrientedToRight then begin
    FlipH := True;
    FDeltaPos.x.ChangeTo(FDistance, FFishSpeed, idcSinusoid);
    FMinMax := PointF(0, FDistance);
  end else begin
    FlipH := False;
    FDeltaPos.x.ChangeTo(-FDistance, FFishSpeed, idcSinusoid);
    FMinMax := PointF(-FDistance, 0);
  end;
  PostMessage(0); // swim anim
end;

destructor TFish.Destroy;
begin
  FDeltaPos.Free;
  inherited Destroy;
end;

procedure TFish.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  // fish moves
  FDeltaPos.OnElapse(aElapsedTime);
  SetCoordinate(FOrigin + FDeltaPos.Value);

  if FDeltaPos.x.State = psNO_CHANGE then begin
    if FDeltaPos.x.Value = FMinMax.y then begin
      FlipH := False;
      FDeltaPos.x.ChangeTo(FMinMax.x, FFishSpeed, idcSinusoid);
    end else begin
      FlipH := True;
      FDeltaPos.x.ChangeTo(FMinMax.y, FFishSpeed, idcSinusoid);
    end;
  end;
end;

procedure TFish.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // swim animation
    0: begin
      d := FFishSpeed*0.2;
      Angle.ChangeTo(2, d, idcSinusoid);
      FDeltaPos.y.ChangeTo(-FTileEngine.TileSize.cy*0.25, d, idcSinusoid);
      PostMessage(5, d);
    end;
    5: begin
      d := FFishSpeed*0.2;
      Angle.ChangeTo(-2, d, idcSinusoid);
      FDeltaPos.y.ChangeTo(FTileEngine.TileSize.cy*0.25, d, idcSinusoid);
      PostMessage(0, d);
    end;
  end;

end;

{ TSeaWeed4 }

constructor TSeaWeed4.Create(aCenterX, aBottomY: single; aAngle: integer);
begin
  inherited Create(texSeaWeed4, aCenterX, aBottomY, aAngle, ihSeaweedOrange);
  FlipH := Random > 0.5;

 { inherited Create(texSeaWeed4, False);
  FScene.Add(Self, LAYER_FXANIM);
  CenterX := aCenterX;
  if aFlipV then Y.Value := aBottomY
    else BottomY := aBottomY;
  FlipV := aFlipV;
  FlipH := Random > 0.5;
  Freeze := True;
  AddCollisionRect;
  ItemHarvested := ihSeaweedOrange;    }
end;

{ TBubbleUnderSea }

constructor TBubbleUnderSea.Create(aX, aY: single);
begin
  inherited Create(FScene);
  LoadFromFile(ParticleFolder+'BubbleUnderSea.par', FAtlas);
  FScene.Add(Self, LAYER_GROUND);
  SetCoordinate(aX, aY);
  SetEmitterTypeLine(PointF(aX - FTileEngine.TileSize.cx*0.5, aY));
  FBaseTime := 0.45+Random;
end;

procedure TBubbleUnderSea.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  // shoot
  if FTimeBeforeNextShoot > 0 then
    FTimeBeforeNextShoot := FTimeBeforeNextShoot - aElapsedTime;
  if FTimeBeforeNextShoot <= 0 then begin
    FTimeBeforeNextShoot := FBaseTime + Random*FBaseTime;
    ParticlesToEmit.Value := 8 + Random*5;
    EmitterLife := 0.3+Random*0.3;
    FParticleParam.Size := 0.2 + Random*0.29;
    Shoot;
  end;
end;

{ TSeaWeed3 }

constructor TSeaWeed3.Create(aCenterX, aBottomY: single; aFlipV: boolean);
begin
  inherited Create(texSeaWeed3, False);
  FScene.Add(Self, LAYER_GROUND);
  CenterX := aCenterX;
  if aFlipV then Y.Value := aBottomY
    else BottomY := aBottomY;
  FlipV := aFlipV;
  FlipH := Random > 0.5;
  Freeze := True;
end;

{ TSeaWeed2 }

constructor TSeaWeed2.Create(aCenterX, aBottomY: single; aAngle: integer);
begin
  inherited Create(texSeaWeed2, aCenterX, aBottomY, aAngle, ihSeaweedGreen);
  FlipH := Random > 0.5;

{  inherited Create(texSeaWeed2, False);
  FScene.Add(Self, LAYER_FXANIM);
  CenterX := aCenterX;
  if aFlipV then Y.Value := aBottomY
    else BottomY := aBottomY;
  FlipV := aFlipV;
  FlipH := Random > 0.5;
  Freeze := True;
  AddCollisionRect;
  ItemHarvested := ihSeaweedGreen; }
end;

{ TSeaWeed1 }

constructor TSeaWeed1.Create(aCenterX, aBottomY: single; aAngle: integer);
begin
  inherited Create(texSeaWeed1, aCenterX, aBottomY, aAngle, ihSeaweedPurple);
  FlipH := Random > 0.5;

{  inherited Create(texSeaWeed1, False);
  FScene.Add(Self, LAYER_FXANIM);
  CenterX := aCenterX;
  if aFlipV then Y.Value := aBottomY
    else BottomY := aBottomY;
  FlipV := aFlipV;
  FlipH := Random > 0.5;
  Freeze := True;
  AddCollisionRect;
  ItemHarvested := ihSeaweedPurple;  }
end;

{ TBG }

constructor TBG.Create(aTex: PTexture; aCenterX, aCenterY: single);
begin
  inherited Create(aTex, False);
  FScene.Add(Self, LAYER_BG2);
  SetCenterCoordinate(aCenterX, aCenterY);
  Scale.Value := PointF(2, 2);
  Opacity.Value := 80;
  FlipH := Random > 0.5;
  FlipV := Random > 0.5;
  Freeze := True;
end;

{ TMine }

constructor TMine.Create(aX, aY: single);
begin
  inherited Create(texMine, False);
  FScene.Add(Self, LAYER_BG2);
  SetCenterCoordinate(aX, aY);
  Angle.Value := Random*360;
  Angle.AddConstant(1+Random);

  CollisionBody.AddCircle(PointF(Width*0.5, Height*0.5), Width*0.5);

  // check collision with submarine
  PostMessage(100);
end;

procedure TMine.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // explode defered
    0: Explode;

    // check collision with submarine
    100: begin
      if ScreenSnakeFissure.GameState <> gsRunning then exit;
      FSubmarine.CollisionBody.SetTransformMatrix(FSubmarine.GetMatrixSurfaceToScene);
      CollisionBody.SetTransformMatrix(GetMatrixSurfaceToScene);
      if CollisionBody.CheckCollisionWith(FSubmarine) then begin
        FTileEngine.ScrollSpeed.Value := PointF(0, 0);
        FSubmarine.ProcessContactWithMine;
        Explode;
        ScreenSnakeFissure.GameState := gsSubmarineExploded;
      end else PostMessage(100, 0.1);
    end;
  end;
end;

procedure TMine.Explode;
var circle: TOGLCBodyItem;
  i: integer;
  mine: TMine;
begin
  if FExploded then exit;
  FExploded := True;

  TExplosion.Create(CenterX, CenterY);
  Kill;
  // check if there is another mine near and make it explode defered 0.5s
  circle.BodyType := _btCircle;
  circle.center := Center;
  circle.radius := Width;
  for i:=0 to FScene.Layer[LAYER_BG2].SurfaceCount-1 do
    if FScene.Layer[LAYER_BG2].Surface[i] is TMine then begin
      mine := TMine(FScene.Layer[LAYER_BG2].Surface[i]);
      if mine = self then continue;
      if Collision.CircleCircle(circle.center, circle.radius, mine.Center, mine.Width*0.5) then
        mine.ExplodeDefered(0.3);
    end;
end;

procedure TMine.ExplodeDefered(aDelay: single);
begin
  PostMessage(0, aDelay);
end;

{ TStone1 }

procedure TStone1.ProcessFalling;
var i: integer;
  barrier: TBarrier;
  mine: TMine;
begin
  CollisionBody.SetTransformMatrix(GetMatrixSurfaceToScene);

  for i:=0 to FScene.Layer[LAYER_BG2].SurfaceCount-1 do begin
    // check collision with barriers
    if FScene.Layer[LAYER_BG2].Surface[i] is TBarrier then begin
      barrier := TBarrier(FScene.Layer[LAYER_BG2].Surface[i]);
      barrier.CollisionBody.SetTransformMatrix(barrier.GetMatrixSurfaceToScene);
      if CollisionBody.CheckCollisionWith(barrier) then begin
        Explode;
        barrier.Open;
        exit;
      end;
    end;
    // check collision with mines
    if FScene.Layer[LAYER_BG2].Surface[i] is TMine then begin
      mine := TMine(FScene.Layer[LAYER_BG2].Surface[i]);
      mine.CollisionBody.SetTransformMatrix(mine.GetMatrixSurfaceToScene);
      if CollisionBody.CheckCollisionWith(mine) then begin
        Explode;
        mine.Explode;
        exit;
      end;
    end;
  end;
end;

constructor TStone1.Create(aX, aY: single; aFlipH: boolean);
begin
  inherited Create(texStone1, False);
  FScene.Add(Self, LAYER_FXANIM);
  SetCoordinate(aX, aY);
  FlipH := aFlipH;
  FOrigin := PointF(aX, aY);

  CollisionBody.AddPolygon([PointF(0, 0), PointF(Width, 0), PointF(Width, Height), PointF(0, Height)]);
end;

procedure TStone1.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if FFalling then ProcessFalling;
end;

procedure TStone1.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // anim fall
    0: begin
      inc(FTremblingCount);
      if FTremblingCount = 7 then begin
        PostMessage(10);
        exit;
      end;
      SetCoordinate(FOrigin+PointF(Random*PPIScale(5), Random*PPIScale(5)));
      PostMessage(0, 0.1);
    end;
    10: begin
      SetCoordinate(FOrigin);
      if FlipH then begin
        Angle.AddConstant(-360);
        Speed.x.ChangeTo(-FScene.Width*0.1, 0.5, idcDrop);
      end else begin
        Angle.AddConstant(360);
        Speed.x.ChangeTo(FScene.Width*0.1, 0.5, idcDrop);
      end;
      Speed.y.ChangeTo(FScene.Height*0.5, 0.5, idcDrop);
      FFalling := True;
    end;
  end;
end;

function TStone1.CanInteractWithPlier: boolean;
begin
  Result := not FPrepareToFall and not FFalling;
end;

procedure TStone1.Fall;
begin
  if FPrepareToFall or FFalling then exit;
  FPrepareToFall := True;
  FTremblingCount := 0;
  PostMessage(0);
end;

procedure TStone1.Explode;
begin
  Audio.PlayThenKillSound('CollisionPunchShort.ogg', 0.5, 0.0, 1.0+Random*0.25-0.125, Audio.FXReverbUnderWater, 1.0);
  Kill;
  ExplodeTexture(FScene, LAYER_FXANIM, texStone1, 5, 3, Center, 0.5, PointF(1,1),
  60, 180, FScene.Width*0.2, 0.2, 1.5);
end;

{ TCustomSubMarine }

procedure TCustomSubMarine.CreateCollisionPoints;
begin
  FCollisionPoints := NIL;
  SetLength(FCollisionPoints, 15);
  FCollisionPoints[0].pt := PointF(0.730*Width, 0.015*Height); // first is on the arm base, then go to left
  FCollisionPoints[0].dir := rebdS;

  FCollisionPoints[1].pt := PointF(0.557*Width, -0.120*Height);
  FCollisionPoints[1].dir := rebdS;

  FCollisionPoints[2].pt := PointF(0.346*Width, 0.028*Height);
  FCollisionPoints[2].dir := rebdS;

  FCollisionPoints[3].pt := PointF(-0.001*Width, 0.058*Height);
  FCollisionPoints[3].dir := rebdSE;

  FCollisionPoints[4].pt := PointF(0.080*Width, 0.406*Height);
  FCollisionPoints[4].dir := rebdE;

  FCollisionPoints[5].pt := PointF(0.075*Width, 0.745*Height);
  FCollisionPoints[5].dir := rebdE;

  FCollisionPoints[6].pt := PointF(0.168*Width, 0.923*Height);
  FCollisionPoints[6].dir := rebdN; //rebdNE;

  FCollisionPoints[7].pt := PointF(0.353*Width, 0.940*Height);
  FCollisionPoints[7].dir := rebdN;

  FCollisionPoints[8].pt := PointF(0.662*Width, 0.940*Height);
  FCollisionPoints[8].dir := rebdN;

  FCollisionPoints[9].pt := PointF(0.831*Width, 0.949*Height);
  FCollisionPoints[9].dir := rebdN; //rebdNW;

  FCollisionPoints[10].pt := PointF(0.901*Width, 0.814*Height);
  FCollisionPoints[10].dir := rebdW;

  FCollisionPoints[11].pt := PointF(0.996*Width, 0.384*Height);
  FCollisionPoints[11].dir := rebdW;

  FCollisionPoints[12].pt := PointF(0.901*Width, 0.623*Height);
  FCollisionPoints[12].dir := rebdW;

  FCollisionPoints[13].pt := PointF(0.991*Width, 0.284*Height);
  FCollisionPoints[13].dir := rebdW;

  FCollisionPoints[14].pt := PointF(0.893*Width, 0.093*Height);
  FCollisionPoints[14].dir := rebdSW;
end;

procedure TCustomSubMarine.DoRebound(aDir: TReboundDirection;
  aElapsedTime: single);
var   spx, spy: single;
begin
  PlayReboundSound;

  spx := Abs(FTileEngine.ScrollSpeed.x.Value);
  spy := Abs(FTileEngine.ScrollSpeed.y.Value);
  if spx < FScene.Width*0.1 then spx := FScene.Width*0.1;
  if spy < FScene.Width*0.1 then spy := FScene.Width*0.1;

  if aDir in [rebdE, rebdSE, rebdNE] then begin
    FTileEngine.ScrollSpeed.x.Value := spx*0.5;
    FTileEngine.PositionOnMap.x.Value := FTileEngine.PositionOnMap.x.Value + spx*aElapsedTime;
  end;

  if aDir in [rebdW, rebdSW, rebdNW] then begin
    FTileEngine.ScrollSpeed.x.Value := -spx*0.5;
    FTileEngine.PositionOnMap.x.Value := FTileEngine.PositionOnMap.x.Value - spx*aElapsedTime;
  end;

  if aDir in [rebdN, rebdNE, rebdNW] then begin
    FTileEngine.ScrollSpeed.y.Value := spy*0.5;
    FTileEngine.PositionOnMap.y.Value := FTileEngine.PositionOnMap.y.Value - spy*aElapsedTime;
  end;

  if aDir in [rebdS, rebdSE, rebdSW] then begin
    FTileEngine.ScrollSpeed.y.Value := -spy*0.5;
    FTileEngine.PositionOnMap.y.Value := FTileEngine.PositionOnMap.y.Value + spy*aElapsedTime;
  end;
end;

function TCustomSubMarine.ModifySpeed(aValue, aDeltaSpeed: single): single;
begin
  Result := EnsureRange(aValue + aDeltaSpeed, -FScene.Width*0.125, FScene.Width*0.125);
end;

constructor TCustomSubMarine.Create(aLayerIndex: integer);
begin
  inherited Create(aLayerIndex);
  CreateCollisionPoints;
end;

procedure TCustomSubMarine.Update(const aElapsedTime: single);
var i, j: integer;
  barrier: TBarrier;
  colItem: TOGLCBodyItem;
begin
  inherited Update(aElapsedTime);

  // check collision points with rock in tile engine
  for i:=0 to High(FCollisionPoints) do
    if FTileEngine.GetGroundType(FCollisionPoints[i].pt+GetXY) = GROUND_ROCK then begin
      DoRebound(FCollisionPoints[i].dir, aElapsedTime);
      exit;
    end;

  // check collision points with barrier in LAYER_BG2
  // (with barriers, collision appear only from the bottom)
  colItem.BodyType := _btPoint;
  for i:=6 to 9 do
    for j:=0 to FScene.Layer[LAYER_BG2].SurfaceCount-1 do
      if FScene.Layer[LAYER_BG2].Surface[j] is TBarrier then begin
        barrier := TBarrier(FScene.Layer[LAYER_BG2].Surface[j]);
        barrier.CollisionBody.SetTransformMatrix(barrier.GetMatrixSurfaceToScene);
        colItem.pt := FCollisionPoints[i].pt+GetXY;
        if barrier.CollisionBody.CheckCollisionWith(colItem) then begin
          DoRebound(rebdN, aElapsedTime);
          exit;
        end;
      end;
end;

procedure TCustomSubMarine.CheckPlierActionOnObject;
var stone1: TStone1;
  i: integer;
  surf: TSimpleSurfaceWithEffect;
  repopable: TRepopableItem;
  boat: TBoatBroken;
begin
  LeftPlier.CollisionBody.SetTransformMatrix(LeftPlier.GetMatrixSurfaceToScene);
  RightPlier.CollisionBody.SetTransformMatrix(RightPlier.GetMatrixSurfaceToScene);

  for i:=0 to FScene.Layer[LAYER_FXANIM].SurfaceCount-1 do begin
    surf := FScene.Layer[LAYER_FXANIM].Surface[i];
    // stone1
    if surf is TStone1 then begin
      stone1 := TStone1(surf);
      if stone1.CanInteractWithPlier then begin
        stone1.CollisionBody.SetTransformMatrix(stone1.GetMatrixSurfaceToScene);
        if LeftPlier.CollisionBody.CheckCollisionWith(stone1) or
           RightPlier.CollisionBody.CheckCollisionWith(stone1) then begin
          stone1.Fall;
          exit;
        end;
      end;
    end;
    // broken boat
    if surf is TBoatBroken then begin
      boat := TBoatBroken(surf);
      boat.CollisionBody.SetTransformMatrix(boat.GetMatrixSurfaceToScene);
      if LeftPlier.CollisionBody.CheckCollisionWith(boat) or
         RightPlier.CollisionBody.CheckCollisionWith(boat) then begin
        boat.CreateWoodBoard;
        exit;
      end;
    end;
    // repopable item
    if surf is TRepopableItem then begin
      repopable := TRepopableItem(surf);
      if repopable.CanInteractWithPlier then begin
        repopable.CollisionBody.SetTransformMatrix(repopable.GetMatrixSurfaceToScene);
        if LeftPlier.CollisionBody.CheckCollisionWith(repopable) or
           RightPlier.CollisionBody.CheckCollisionWith(repopable) then begin
          repopable.Disappear;
          FSubmarine.ClosePlier(0.25);
          FDashboard.SetItemHarvested(repopable.ItemHarvested);
          exit;
        end;
      end;
    end;

  end;//for
end;

procedure TCustomSubMarine.PlayReboundSound;
begin
  with Audio.AddSound('footstep06.ogg',0.4, False) do begin
    ApplyEffect(Audio.FXReverbLong);
    SetEffectDryWetVolume(Audio.FXReverbLong, 0.6);
    ApplyEffect(Audio.FXReverbUnderWater);
    SetEffectDryWetVolume(Audio.FXReverbLong, 1.0);
    PlayThenKill(True);
  end;
end;

{ TBarrier }

constructor TBarrier.Create(aX, aY: single; aFlipH: boolean);
begin
  inherited Create(texBarrierLeft, False);
  FScene.Add(Self, LAYER_BG2);
  BottomY := aY + Height*0.25;
  FlipH := aFlipH;
  if aFlipH then X.Value := aX - Width
    else X.Value := aX;

  CollisionBody.AddLine(PointF(ScaleW(7), ScaleH(55)), PointF(ScaleW(137), ScaleH(4)));
  CollisionBody.AddLine(PointF(ScaleW(137), ScaleH(4)), PointF(ScaleW(245), ScaleH(59)));
end;

procedure TBarrier.Open;
begin
  Kill;
  ExplodeTextureDirectionnal(FScene, LAYER_BG2, texBarrierLeft, 2, 15, GetXY, PointF(1,1),15, 180,
                   60, 120, FScene.Height*0.25, 0.5, 3.0);
end;

{ TScreenSnakeFissure }

procedure TScreenSnakeFissure.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;
  case AValue of
    gsSubmarineExploded: PostMessage(100);
    gsLRWin: PostMessage(200);
    gsNoMoreCristal: PostMessage(300);
  end;
end;

procedure TScreenSnakeFissure.CreateAndSaveTileSet;
var wholeIma, ima: TBGRABitmap;
  i, ro, co: integer;
  path: string;
const files: TStringArray=('tile1.svg', 'tile2.svg', 'tile3.svg', 'tile4.svg', 'tile5.svg',
                           'tile6.svg', 'tile7.svg', 'tile8.svg', 'tile9.svg', 'tile10.svg',
                           'tile11.svg', 'tile12.svg', 'tile13.svg', 'tile14.svg');
  COL=10;
  ROW=2;
  TILESIZE=64;
begin
  path := FolderSpriteSnakeFissure;
  wholeIma := TBGRABitmap.Create(COL*TILESIZE, ROW*TILESIZE, BGRAPixelTransparent);
  i := 0;
  for ro:=0 to ROW-1 do
    for co:=0 to COL-1 do begin
      if i < Length(files) then begin
        ima := LoadBitmapFromSVG(path+files[i], TILESIZE, TILESIZE);
        wholeIma.PutImage(TILESIZE*co, TILESIZE*ro, ima, dmDrawWithTransparency);
        ima.Free;
        inc(i);
      end;
    end;

  wholeIma.SaveToFile('C:\Pascal\LittleRedRidingHood\Design\6-SnakeFissure\tileset.png');
  wholeIma.Free;
end;

procedure TScreenSnakeFissure.ResetVariables;
begin

end;

procedure TScreenSnakeFissure.CreateLevel;
begin
  // water bg   LAYER_BG3
  FWaterBG := TQuad4Color.Create(FScene);
  FScene.Add(FWaterBG, LAYER_BG3);
  FWaterBG.SetAllColorsTo(BGRA(18,30,71));
  FWaterBG.SetSize(FScene.Width, FScene.Height);
  //FScene.BackgroundColor := BGRA(18,30,71);
end;

procedure TScreenSnakeFissure.CreateSpriteFromTileEvent;
var ro, co: integer;
  tile: PTile;
  p: TPointF;
begin
  for ro:=0 to FTileEngine.MapTileCount.cy-1 do
    for co:=0 to FTileEngine.MapTileCount.cx-1 do begin
      tile := FTileEngine.GetPTile(ro, co);
      p := PointF(FTileEngine.TileSize.cx*co, FTileEngine.TileSize.cy*ro);
      ProcessTileEvent(FTileEngine, p, tile);
    end;
end;

procedure TScreenSnakeFissure.ProcessTileEvent(Sender: TTileEngine;
  const TileTopLeftCoor: TPointF; aTile: PTile);
var p: TPointF;
  wt, ht: single;
begin
  p := TileTopLeftCoor + Sender.PositionOnMap.Value;
  wt := Sender.TileSize.cx*0.5;
  ht := Sender.TileSize.cy*0.5;
  case aTile^.UserEvent of
    TILE_EVENT_BARRIER_RIGHT: begin
      aTile^.UserEvent := -1;
      TBarrier.Create(p.x + wt, p.y + ht, True);
    end;
    TILE_EVENT_BARRIER_LEFT: begin
      aTile^.UserEvent := -1;
      TBarrier.Create(p.x + wt, p.y + ht, False);
    end;
    TILE_EVENT_STONE1_RIGHT: begin
      aTile^.UserEvent := -1;
      TStone1.Create(p.x-wt, p.y, True);
    end;
    TILE_EVENT_STONE1_LEFT: begin
      aTile^.UserEvent := -1;
      TStone1.Create(p.x+wt, p.y, False);
    end;
    TILE_EVENT_MINE: begin
      aTile^.UserEvent := -1;
      TMine.Create(p.x+wt, p.y+ht);
    end;
    TILE_EVENT_BG1: begin
      aTile^.UserEvent := -1;
      TBG.Create(texBG1, p.x+wt, p.y+ht);
    end;
    TILE_EVENT_BG2: begin
      aTile^.UserEvent := -1;
      TBG.Create(texBG2, p.x+wt, p.y+ht);
    end;
    TILE_EVENT_BG3: begin
      aTile^.UserEvent := -1;
      TBG.Create(texBG3, p.x+wt, p.y+ht);
    end;
    TILE_EVENT_SW_PURPLE_0: begin
      aTile^.UserEvent := -1;
      TSeaWeed1.Create(p.x, p.y, 0);
    end;
    TILE_EVENT_SW_PURPLE_90: begin
      aTile^.UserEvent := -1;
      TSeaWeed1.Create(p.x, p.y, 90);
    end;
    TILE_EVENT_SW_PURPLE_180: begin
      aTile^.UserEvent := -1;
      TSeaWeed1.Create(p.x, p.y, 180);
    end;
    TILE_EVENT_SW_PURPLE_270: begin
      aTile^.UserEvent := -1;
      TSeaWeed1.Create(p.x, p.y, 270);
    end;
    TILE_EVENT_SW_GREEN_0: begin
      aTile^.UserEvent := -1;
      TSeaWeed2.Create(p.x, p.y, 0);
    end;
    TILE_EVENT_SW_GREEN_90: begin
      aTile^.UserEvent := -1;
      TSeaWeed2.Create(p.x, p.y, 90);
    end;
    TILE_EVENT_SW_GREEN_180: begin
      aTile^.UserEvent := -1;
      TSeaWeed2.Create(p.x, p.y, 180);
    end;
    TILE_EVENT_SW_GREEN_270: begin
      aTile^.UserEvent := -1;
      TSeaWeed2.Create(p.x, p.y, 270);
    end;
    TILE_EVENT_SEA_WEED3: begin
      aTile^.UserEvent := -1;
      TSeaWeed3.Create(p.x+wt, p.y+ht*0.4, False);
    end;
    TILE_EVENT_SEA_WEED3_FLIPV: begin
      aTile^.UserEvent := -1;
      TSeaWeed3.Create(p.x+wt, p.y+ht*1.5, True);
    end;
    TILE_EVENT_BUBBLE: begin
      aTile^.UserEvent := -1;
      TBubbleUnderSea.Create(p.x+wt*0.4, p.y);
    end;
    TILE_EVENT_SW_ORANGE_0: begin
      aTile^.UserEvent := -1;
      TSeaWeed4.Create(p.x, p.y, 0);
    end;
    TILE_EVENT_SW_ORANGE_90: begin
      aTile^.UserEvent := -1;
      TSeaWeed4.Create(p.x, p.y, 90);
    end;
    TILE_EVENT_SW_ORANGE_180: begin
      aTile^.UserEvent := -1;
      TSeaWeed4.Create(p.x, p.y, 180);
    end;
    TILE_EVENT_SW_ORANGE_270: begin
      aTile^.UserEvent := -1;
      TSeaWeed4.Create(p.x, p.y, 270);
    end;
    TILE_EVENT_FISH_BLUE_RIGHT: begin
      aTile^.UserEvent := -1;
      TFish.Create(texFishBlue, p.x+wt, p.y+ht, True);
    end;
    TILE_EVENT_FISH_BLUE_LEFT: begin
      aTile^.UserEvent := -1;
      TFish.Create(texFishBlue, p.x+wt, p.y+ht, False);
    end;
    TILE_EVENT_FISH_ORANGE_RIGHT: begin
      aTile^.UserEvent := -1;
      TFish.Create(texFishOrange, p.x+wt, p.y+ht, True);
    end;
    TILE_EVENT_FISH_ORANGE_LEFT: begin
      aTile^.UserEvent := -1;
      TFish.Create(texFishOrange, p.x+wt, p.y+ht, False);
    end;
    TILE_EVENT_CRISTAL_GROUND: begin
      aTile^.UserEvent := -1;
      TCristal.Create(p.x, p.y, 0);
    end;
    TILE_EVENT_CRISTAL_90: begin
      aTile^.UserEvent := -1;
      TCristal.Create(p.x, p.y, 90);
    end;
    TILE_EVENT_CRISTAL_180: begin
      aTile^.UserEvent := -1;
      TCristal.Create(p.x, p.y, 180);
    end;
    TILE_EVENT_CRISTAL_270: begin
      aTile^.UserEvent := -1;
      TCristal.Create(p.x, p.y, 270);
    end;
    TILE_EVENT_SW_GRAY_0: begin
      aTile^.UserEvent := -1;
      TSeaWeed5.Create(p.x, p.y, 0);
    end;
    TILE_EVENT_SW_GRAY_90: begin
      aTile^.UserEvent := -1;
      TSeaWeed5.Create(p.x, p.y, 90);
    end;
    TILE_EVENT_SW_GRAY_180: begin
      aTile^.UserEvent := -1;
      TSeaWeed5.Create(p.x, p.y, 180);
    end;
    TILE_EVENT_SW_GRAY_270: begin
      aTile^.UserEvent := -1;
      TSeaWeed5.Create(p.x, p.y, 270);
    end;
    TILE_EVENT_GEYSER_UP: begin
      aTile^.UserEvent := -1;
      TGeyserUp.Create(p.x, p.y);
    end;
    TILE_EVENT_TURTLE_STONE: begin
      aTile^.UserEvent := -1;
      TStoneTurtle.Create(p.x, p.y);
    end;
    TILE_EVENT_BOAT_BROKEN: begin
      aTile^.UserEvent := -1;
      TBoatBroken.Create(p.x, p.y);
    end;
    TILE_EVENT_EXIT: begin
      aTile^.UserEvent := -1;
      TCustomDirectionnalArrow.Create(p.x, p.y);
    end;
  end;//case
end;

procedure TScreenSnakeFissure.DefineSubTextures(aAtlas: TAtlas);
var path: string;
begin
  AdditionnalScale := 1.0;
  TSubmarine.LoadTexture(aAtlas, AdditionnalScale);
  TTurtle.LoadTexture(aAtlas, AdditionnalScale);

  path := FolderSpriteSnakeFissure;
  texTileset := aAtlas.AddTileSetFromSVG('tileset', PPIScale(64), 2, 10,
      [path+'tile1.svg', path+'tile2.svg', path+'tile3.svg', path+'tile4.svg',
       path+'tile5.svg', path+'tile6.svg', path+'tile7.svg', path+'tile8.svg',
       path+'tile9.svg', path+'tile10.svg', path+'tile11.svg', path+'tile12.svg',
       path+'tile13.svg', path+'tile14.svg']);
  texBarrierLeft := aAtlas.AddFromSVG(path+'BarrierLeft.svg', ScaleW(256), -1);
  texStone1 := aAtlas.AddFromSVG(path+'Stone1.svg', ScaleW(46), -1);
  texMine := aAtlas.AddFromSVG(path+'Mine.svg', ScaleW(45), -1);
  texMineExplosion := aAtlas.AddFromSVG(path+'MineExplosion.svg', ScaleW(45), -1);
  texBG1 := aAtlas.AddFromSVG(path+'bg1.svg', ScaleW(73), -1);
  texBG2 := aAtlas.AddFromSVG(path+'bg2.svg', ScaleW(82), -1);
  texBG3 := aAtlas.AddFromSVG(path+'bg3.svg', ScaleW(106), -1);
  texBoatBroken := aAtlas.AddFromSVG(path+'BoatBroken.svg', ScaleW(228), -1);
  texWoodBoard := aAtlas.AddFromSVG(path+'WoodBoard.svg', ScaleW(40), -1);
  texSeaWeed1 := aAtlas.AddFromSVG(path+'SeaWeed1.svg', ScaleW(45), -1);
  texSeaWeed2 := aAtlas.AddFromSVG(path+'SeaWeed2.svg', ScaleW(70), -1);
  texSeaWeed3 := aAtlas.AddFromSVG(path+'SeaWeed3.svg', ScaleW(60), -1);
  texSeaWeed4 := aAtlas.AddFromSVG(path+'SeaWeed4.svg', ScaleW(50), -1);
  texSeaWeed5 := aAtlas.AddFromSVG(path+'SeaWeed5.svg', ScaleW(48), -1);
  texFishBlue := aAtlas.AddFromSVG(path+'FishBlue.svg', ScaleW(88), -1);
  texFishOrange := aAtlas.AddFromSVG(path+'FishOrange.svg', ScaleW(70), -1);

  texScrew := aAtlas.AddFromSVG(path+'Screw.svg', ScaleW(6), -1);
  texIconArmIn := aAtlas.AddFromSVG(path+'IconArmIn.svg', ScaleW(59), -1);
  texIconArmOut := aAtlas.AddFromSVG(path+'IconArmOut.svg', ScaleW(79), -1);
  texIconDigForward := aAtlas.AddFromSVG(path+'IconDigForward.svg', ScaleW(20), -1);
  texIconDigGround := aAtlas.AddFromSVG(path+'IconDigGround.svg', ScaleW(20), -1);
  texIconHarvest := aAtlas.AddFromSVG(path+'IconHarvest.svg', ScaleW(53), -1);
  texIconSeparatorMinus := aAtlas.AddFromSVG(path+'IconSeparatorMinus.svg', ScaleW(8), -1);
  texIconSeparatorSplit := aAtlas.AddFromSVG(path+'IconSeparatorSplit.svg', ScaleW(14), -1);
  texIconSeparatorMerge := aAtlas.AddFromSVG(path+'IconSeparatorMerge.svg', ScaleW(14), -1);
  texIconBuildMissile := aAtlas.AddFromSVG(path+'IconBuildMissile.svg', ScaleW(48), -1);
  texIconGO := aAtlas.AddFromSVG(path+'IconGO.svg', ScaleW(11), -1);
  texMissile := aAtlas.AddFromSVG(path+'Missile.svg', ScaleW(30), -1);

  texCristal := aAtlas.AddFromSVG(SpriteUIFolder+'CristalGray.svg', ScaleW(34), -1);
  texCristalGaugeBody := aAtlas.AddFromSVG(path+'GaugeBody.svg', ScaleW(60), -1);
  texCristalGaugeArrow := aAtlas.AddFromSVG(path+'GaugeArrow.svg', -1, ScaleH(32));
  texLedBlack := aAtlas.AddFromSVG(path+'LedBlack.svg', ScaleW(14), -1);

  texSmallGaugeArrow := aAtlas.AddFromSVG(path+'GaugeArrowSmall.svg', -1, ScaleH(24));
  texSWPurpleGaugeBody := aAtlas.AddFromSVG(path+'GaugePurpleSeaweed.svg', ScaleW(45), -1);
  texSWOrangeGaugeBody := aAtlas.AddFromSVG(path+'GaugeOrangeSeaweed.svg', ScaleW(45), -1);
  texSWGrayGaugeBody := aAtlas.AddFromSVG(path+'GaugeGraySeaweed.svg', ScaleW(45), -1);
  texSWGreenGaugeBody := aAtlas.AddFromSVG(path+'GaugeGreenSeaweed.svg', ScaleW(45), -1);
  texArrowYellow := aAtlas.AddFromSVG(SpriteUIFolder+'ArrowYellow.svg', ScaleW(40), -1);

  AddBubbleLessTransparentParticleToAtlas(aAtlas);
  AddDustParticleToAtlas(aAtlas);

  // ui
  CreateGameFontNumber(aAtlas); // < must be first !
  // font for button in pause panel
  FFontText := CreateGameFontText(aAtlas);
  LoadGameDialogTextures(aAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(aAtlas);
  LoadMousePointerTexture(aAtlas);
end;

procedure TScreenSnakeFissure.CreateObjects;
begin
  //CreateAndSaveTileSet;

  FGameState := gsUndefined;
  ResetVariables;
  Audio.PauseMusicTitleMap(3.0);
  FsndUnderWater := Audio.AddSound('heavy-bubbles-35889.ogg', 0.0, True);
  FsndUnderWater.ApplyEffect(Audio.FXReverbUnderWater);
  FsndUnderWater.SetEffectDryWetVolume(Audio.FXReverbUnderWater, 1.0);
  FsndUnderWater.FadeIn(0.3, 3.0);

  CheckAtlas(FAtlas, 'snakefissure.atlas');

  CreateLevel;

  //submarine
  FSubmarine := TCustomSubMarine.Create(LAYER_PLAYER);
  //FSubmarine.SetCoordinate(ScaleW(254), ScaleH(496));
  FSubmarine.CenterOnScene;
  FSubmarine.Posture_Idle(0);

  // dashboard
  FDashboard := TDashboard.Create;
  FDashboard.ShowDashboard2;

  // tile engine
  FTileEngine := TTileEngine.Create(FScene);
  FScene.Add(FTileEngine, LAYER_BG1);
  FTileEngine.LoadMapFile(FolderSpriteSnakeFissure+'Main_Map.map', [texTileset]);
  FTileEngine.SetCoordinate(0, 0);
  FTileEngine.SetViewSize(FScene.Width, FScene.Height);
  FTileEngine.OnTileEvent := @ProcessTileEvent;
  CreateSpriteFromTileEvent;
  FTileEngine.PositionOnMap.Value := PointF(FTileEngine.TileSize.cx*2, 0);

  // turtle
  FTurtle := TCustomTurtle.Create;

  FWorldArea := RectF(0, 0, FTileEngine.MapSize.cx, FTileEngine.MapSize.cy);
  // constrained size for the camera
  FViewArea.Left := FWorldArea.Left + FScene.Width*0.5;
  FViewArea.Top := FWorldArea.Top + FScene.Height*0.5;
  FViewArea.Right := FWorldArea.Right - FScene.Width*0.5;
  FViewArea.Bottom := FWorldArea.Bottom - FScene.Height*0.5;

  // camera
  FCamera := FScene.CreateCamera;
  FCamera.AssignToLayers([LAYER_WOLF, LAYER_FXANIM, LAYER_GROUND, LAYER_BG2]);

  // under water effect
  FScene.PostProcessing.StartEngine;
  FScene.PostProcessing.EnableFXOnLayerRange([ppUnderWater], LAYER_PLAYER, LAYER_BG3);
  FScene.PostProcessing.SetUnderWaterParamsOnLayerRange(5, 15, 0.5, LAYER_PLAYER, LAYER_BG3);

  // pause panel
  FPausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  CustomizeMousePointer(True);
  GameState := gsRunning;
  PostMessage(30, 0.05); // show instructions
end;

procedure TScreenSnakeFissure.FreeObjects;
begin
  FScene.KillCamera(FCamera);
  FScene.PostProcessing.StopEngine;
  if FsndUnderWater <> NIL then FsndUnderWater.FadeOutThenKill(2.0);
  FsndUnderWater := NIL;
  if FScene.RequestedScreen = ScreenMap then
    Audio.ResumeMusicTitleMap;

  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
  ChallengeMode := False;
end;

procedure TScreenSnakeFissure.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // show instructions
    30: ShowGameInstructions(PlayerInfo.SnakeFissure.HelpText);

    // LR lose
    100: begin // wait the end of the submarine explode animation
      if FSubmarine.ExplodeAnimDone then PostMessage(105)
        else PostMessage(100);
    end;
    105: with TDialogQuestion.Create(sWouldYouLikeToTryAgain, sYes, sNo, FFontText, Self, 115, 110, FAtlas) do
           ShowModal;
    110: FScene.RunScreen(ScreenMap);
    115: FScene.RunScreen(ScreenSnakeFissure);

    // LR WIN
    200: begin
      FTileEngine.ScrollSpeed.Value := PointF(0, 0);
      FSubMarine.Speed.Value := PointF(0, -FScene.Height*0.2);
      Audio.PlayVoiceWhowhooo;
      PostMessage(205, 2.0);
    end;
    205: begin
      PlayerInfo.SnakeFissure.IncCurrentStep;
      FSaveGame.Save;
      FScene.RunScreen(ScreenMap);
    end;

    // tank cristal is empty
    300: begin
      Audio.PlayMusicLose1;
      with SpriteMessage(sOutOfCristals) do
        Y.Value := FScene.Height*0.25;
      FTileEngine.ScrollSpeed.Value := PointF(0, 0);
      PostMessage(105, 2.0);
    end;
  end;
end;

procedure TScreenSnakeFissure.Update(const aElapsedTime: single);
var v, friction: single;
  p, scrollSpeed: TPointF;
  procedure ApplyFriction(var aSpeed: single);
  begin
    if aSpeed > 0.0 then v := Max(0.0, aSpeed-friction)
    else if aSpeed < 0.0 then v := Min(0.0, aSpeed+friction);
  end;
begin
  inherited Update(aElapsedTime);
  case GameState of
    gsRunning: begin
      if Input.LeftPressed then begin
        if FDashboard.ArmState in [sasIn, sasMissileLoaded] then FSubmarine.FlipH := True;
        FTileEngine.ScrollSpeed.x.Value  := Max(FTileEngine.ScrollSpeed.x.Value - FScene.Width*0.002,
                                                -FScene.Width*0.2);  // 0.1
        FDashboard.DecreaseCristalWhenSubmarineMoves;
      end else
      if Input.RightPressed then begin
        if FDashboard.ArmState in [sasIn, sasMissileLoaded] then FSubmarine.FlipH := False;
        FTileEngine.ScrollSpeed.x.Value := Min(FTileEngine.ScrollSpeed.x.Value + FScene.Width*0.002,
                                               FScene.Width*0.2);
        FDashboard.DecreaseCristalWhenSubmarineMoves;
      end;

      if Input.UpPressed then begin
        FTileEngine.ScrollSpeed.y.Value := Min(FTileEngine.ScrollSpeed.y.Value + FScene.Width*0.002,
                                               FScene.Width*0.2);
        FDashboard.DecreaseCristalWhenSubmarineMoves;
      end else
      if Input.DownPressed then begin
        FTileEngine.ScrollSpeed.y.Value := Max(FTileEngine.ScrollSpeed.y.Value - FScene.Width*0.002,
                                               -FScene.Width*0.2);  //0.1
        FDashboard.DecreaseCristalWhenSubmarineMoves;
      end;
      // apply friction
      if FTileEngine.ScrollSpeed.State = psNO_CHANGE then begin
        friction := FScene.Width*0.0005;
        v := FTileEngine.ScrollSpeed.x.Value;
        ApplyFriction(v);
        FTileEngine.ScrollSpeed.x.Value := v;
        v := FTileEngine.ScrollSpeed.y.Value;
        ApplyFriction(v);
        FTileEngine.ScrollSpeed.y.Value := v;
      end;

      // avoid to exit the map
      p := FTileEngine.PositionOnMap.Value;
      scrollSpeed := FTileEngine.ScrollSpeed.Value;
      if (p.x <= 0) and (scrollSpeed.x < 0) then begin
        FTileEngine.PositionOnMap.x.Value := 0;
        FTileEngine.ScrollSpeed.x.Value := 0;
      end
      else
      if (p.y <= 0) and (scrollSpeed.y > 0) then begin
        FTileEngine.PositionOnMap.y.Value := 0;
        FTileEngine.ScrollSpeed.y.Value := 0;
      end;

      // update camera
      FCamera.MoveTo(FTileEngine.PositionOnMap.Value +
                     PointF(FTileEngine.Width*0.5, FTileEngine.Height*0.5));

      // check if cristal tank is empty
      if FDashboard.CristalGauge.Percent = 0 then
        GameState := gsNoMoreCristal;
    end;

  end;
  // check if player pause the game
  if Input.PausePressed then
    FPausePanel.ShowModal;
end;

end.

