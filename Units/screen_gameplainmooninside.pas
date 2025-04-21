unit screen_gameplainmooninside;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon, u_sprite_def;

type

{ TScreenPlainMoonInside }

TScreenPlainMoonInside = class(TGameScreenTemplate)
private type TGameState=(gsUndefined,
                         gsRunning,
                         gsAllRobotDestroyed);
var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FDoor: TAutomaticDoor;
  FInGamePausePanel: TInGamePausePanel;
  FTimeAccuToCreateRobot: single;
  FWagonSwingAndShake: boolean;
  procedure ResetVariables;
  procedure CreatePerspectiveDecors;
  procedure PlayLaserShootSound;
  procedure CheckShootOnWagonWall(aWorldPos: TPointF);
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenPlainMoonInside: TScreenPlainMoonInside;



implementation

uses Forms, screen_gameplainmoon, u_app, u_utils, Math;

type

{ TRobot }

TRobot = class(TSprite)
  FRightArm, FLeftArm: TSprite;
  FLineIndex, FSlotIndex: integer;
  constructor Create;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure StartAnim(aSlotIndex: integer);
  procedure CheckShootPosition(aWorldPos: TPointF);
end;

{ TSeat }

TSeat = class(TSprite)
  constructor Create(aFlipH: boolean);
  function CheckShootPosition(aWorldPos: TPointF): boolean;
end;

{ TSeats }

TSeats = class(TSpriteContainer)   // layer= LAYER_GROUND
private const
  LINE_COUNT = 7;
  SLOTPERLINE = 6;
  SCALE_VALUES: array[0..LINE_COUNT-1] of single =(1.0, 0.619, 0.46, 0.315, 0.211, 0.145, 0.094);
  ZORDER_VALUES: array[0..LINE_COUNT-1] of integer =(-5, -10, -15, -20, -25, -30, -35);
private type
  // il faut garder: les sprites de chaque siège:
  //   > on pourra positionner le robot en fonction
  //   > on pourra positionner le robot.zOrder à siège.z>Order-5
  //   > on pourra récupérer le scale value
  //   > siege.tag1 = le numero de l'animation à lancer dans TRobot.processMessage

private
  FYAppearance: array[0..LINE_COUNT-1] of single;
  FSlots: array[0..LINE_COUNT-1, 0..SLOTPERLINE-1] of TSprite; // a slot is set to NIL if there isn't a robot on it
  procedure Slots_InitDefault;
  // return True if a slot is found
  function GetRandomSlot(out aLineIndex, aSlotIndex: integer): boolean;
  procedure FreeSlot(aLineIndex, aSlotIndex: integer);
  procedure CreateRobot;
private
  FSeatSprite: array[0..LINE_COUNT-1, 0..3] of TSeat;
public
  constructor Create;
  function CheckShootPosition(aWorldPos: TPointF): boolean;
  function GetSeatSprite(aLineIndex, aSlotIndex: integer): TSeat;
end;

{ TGameInventory }

TGameInventory = class(TInGameInventoryPanel)
  Clock: TUIClock;
  procedure AddClock;
end;

var
  FAtlas: TOGLCTextureAtlas;
  texRobotBody, texRobotWheel, texRobotArm,
  texTarget,
  texSeat, texSeatImpact, texLeftWallWindow, texWallBG, texDirectionnalArrow,
  texMountain: PTexture;
  FFontText: TTexturedFont;
  FSeats: TSeats;
  FCamera: TOGLCCamera;
  FARobotIsAlreadyDestroyedWithTheLastShoot: boolean;
  FAction2Released: boolean;
  FRobotCount, FRobotCreated, FRobotDestroyed: integer;
  FGameInventory: TGameInventory;

{ TGameInventory }

procedure TGameInventory.AddClock;
begin
  if Clock = NIL then begin
    Clock := TUIClock.Create;
    AddItem(Clock);
    Clock.Second := PlayerInfo.PlainMoon.RemainingSeconds;
  end;
end;

constructor TSeat.Create(aFlipH: boolean);
var path: TOGLCPath;
begin
  inherited Create(texSeat, False);
  FlipH := aFlipH;
  // add a polygon to collision body
  path := [PointF(ScaleW(35), ScaleH(0)), PointF(ScaleW(17), ScaleH(13)),
                     PointF(ScaleW(10), ScaleH(27)), PointF(ScaleW(10), ScaleH(42)),
                     PointF(ScaleW(15), ScaleH(59)), PointF(ScaleW(24), ScaleH(66)),
                     PointF(ScaleW(8), ScaleH(79)), PointF(ScaleW(0), ScaleH(94)),
                     PointF(ScaleW(0), ScaleH(287)), PointF(ScaleW(8), ScaleH(300)),
                     PointF(ScaleW(25), ScaleH(307)), PointF(ScaleW(148), ScaleH(307)),
                     PointF(ScaleW(164), ScaleH(300)), PointF(ScaleW(172), ScaleH(284)),
                     PointF(ScaleW(196), ScaleH(229)), PointF(ScaleW(196), ScaleH(201)),
                     PointF(ScaleW(194), ScaleH(195)), PointF(ScaleW(188), ScaleH(193)),
                     PointF(ScaleW(180), ScaleH(193)), PointF(ScaleW(180), ScaleH(87)),
                     PointF(ScaleW(173), ScaleH(72)), PointF(ScaleW(161), ScaleH(64)),
                     PointF(ScaleW(153), ScaleH(63)), PointF(ScaleW(161), ScaleH(53)),
                     PointF(ScaleW(166), ScaleH(41)), PointF(ScaleW(166), ScaleH(27)),
                     PointF(ScaleW(164), ScaleH(16)), PointF(ScaleW(155), ScaleH(5)),
                     PointF(ScaleW(144), ScaleH(0)), PointF(ScaleW(35), ScaleH(0))];
  if aFlipH then path.FlipHorizontally;
  CollisionBody.AddPolygon(path);
end;

function TSeat.CheckShootPosition(aWorldPos: TPointF): boolean;
var item: TOGLCBodyItem;
  o: TSprite;
  p: TPointF;
begin
  item.BodyType := _btPoint;
  item.pt := aWorldPos;

  CollisionBody.SetSurfaceToWordMatrix(GetMatrixSurfaceToWorld);
  Result := CollisionBody.CheckCollisionWith(item);
  if Result then begin
    o := TSprite.Create(texSeatImpact, False);
    AddChild(o, 1);
    o.Angle.Value := random*360;
    p := SceneToSurface(aWorldPos);
    o.CenterX := p.x;
    o.CenterY := p.y;
    if o.Y.Value < 0 then o.Y.Value := 0;
    o.Opacity.Value := 200;
  end;
end;

{ TRobot }

constructor TRobot.Create;
var o: TSprite;
begin
  inherited Create(texRobotBody, False);

  FRightArm := CreateSpriteChild(texRobotArm, False, 0);
  FRightArm.SetCoordinate(0, Height*0.45);
  FRightArm.Pivot := PointF(0.5, 0.1);

  FLeftArm := CreateSpriteChild(texRobotArm, False, 0);
  FLeftArm.SetCoordinate(Width-texRobotArm^.FrameWidth, Height*0.45);
  FLeftArm.Pivot := PointF(0.5, 0.1);

  o := CreateSpriteChild(texRobotWheel, False, -1);
  o.SetCoordinate(Width*0.2, Height*0.95);

  o := CreateSpriteChild(texRobotWheel, False, -1);
  o.SetCoordinate(Width*0.8-texRobotWheel^.FrameWidth, Height*0.95);

  // define the collision body
  CollisionBody.AddCircle(PointF(texRobotBody^.FrameWidth*0.5, texRobotBody^.FrameWidth*0.5),
                          texRobotBody^.FrameWidth*0.5);
  CollisionBody.AddPolygon([PointF(0,texRobotBody^.FrameWidth*0.5),
                            PointF(texRobotBody^.FrameWidth, texRobotBody^.FrameWidth*0.5),
                            PointF(texRobotBody^.FrameWidth, texRobotBody^.FrameHeight),
                            PointF(0,texRobotBody^.FrameHeight)]);
end;

procedure TRobot.ProcessMessage(UserValue: TUserMessageValue);
var a,d: single;
begin
  case UserValue of
    // ANIM ARMS
    0: begin
      d := Random*0.5+0.3;
      a := 150+Random*20;
      FRightArm.Angle.ChangeTo(a, d, idcSinusoid);
      FLeftArm.Angle.ChangeTo(-a, d, idcSinusoid);
      PostMessage(2, d);
    end;
    2: begin
      d := Random*0.5+0.3;
      a := 110+Random*20;
      FRightArm.Angle.ChangeTo(a, d, idcSinusoid);
      FLeftArm.Angle.ChangeTo(-a, d, idcSinusoid);
      PostMessage(0, d);
    end;
    // ANIM WITHOUT ROTATION   slot 1, 2, 5, 6
    100: begin
      MoveYRelative(-ScaledHeight*0.7, 1.0, idcSinusoid);
      PostMessage(105, 1.5);
    end;
    105: begin
      MoveYRelative(ScaledHeight*0.7, 1.0, idcDrop);
      PostMessage(100, 2.0);
    end;

    // ANIM WITH ROTATION slot 3
    200: begin
      Angle.Value := 48;
      MoveXRelative(ScaledWidth, 1.0, idcSinusoid);
      PostMessage(205, 1.5);
    end;
    205: begin
      MoveXRelative(-ScaledWidth, 1.0, idcDrop);
      PostMessage(200, 2.0);
    end;

    // ANIM WITH ROTATION slot 4
    300: begin
      Angle.Value :=-48;
      MoveXRelative(-ScaledWidth*0.8, 1.0, idcSinusoid);
      PostMessage(305, 1.5);
    end;
    305: begin
      MoveXRelative(ScaledWidth*0.8, 1.0, idcDrop);
      PostMessage(300, 2.0);
    end;
  end;
end;

procedure TRobot.StartAnim(aSlotIndex: integer);
begin
  case aSlotIndex of
    0,1,4,5: PostMessage(100);
    2: PostMessage(200);
    3: PostMessage(300);
  end;
  PostMessage(0);
end;

procedure TRobot.CheckShootPosition(aWorldPos: TPointF);
var item: TOGLCBodyItem;
  p: TPointF;
  volume, pan: single;
begin
  item.BodyType := _btPoint;
  item.pt := aWorldPos;

  //if FARobotIsAlreadyDestroyedWithTheLastShoot then exit;

  CollisionBody.SetSurfaceToWordMatrix(GetMatrixSurfaceToWorld);
  if CollisionBody.CheckCollisionWith(item) then begin
    FARobotIsAlreadyDestroyedWithTheLastShoot := True;
    Kill;
    ExplodeTextureToChildOf(FSeats.GetSeatSprite(FLineIndex, FSlotIndex), -1,
       texRobotBody, 4, 4, PointF(ScaledWidth*0.5, ScaledHeight*0.5), ScaledWidth*0.2,
       PointF(1.0,1.0), -360, 360, FScene.Width*0.3, FScene.Width*0.1, 1.5);
    FSeats.FreeSlot(FLineIndex, FSlotIndex);
    inc(FRobotDestroyed);

    p := SurfaceToScene(PointF(Width*0.5, Height*0.5));
    pan := EnsureRange((p.x/FScene.Width*2.0-1.0), -1.0, 1.0);
    volume := (Scale.X.Value-0.094)/(1.0-0.094);   // scale range is 0.094 to 1.0
    volume := volume * (0.8 - 0.5) + 0.5;
    //volume := Min(Max(Scale.X.Value, 0.5), 0.7);
    Audio.PlayThenKillSound('big-boom.ogg', volume, pan, 1.0+Random*0.25-0.125, Audio.FXReverbShort, 0.4);
  end;
end;

{ TSeats }

procedure TSeats.Slots_InitDefault;
var i, j: integer;
begin
  for i:=0 to LINE_COUNT-1 do
    for j:=0 to SLOTPERLINE-1 do
      FSlots[i,j] := NIL;
end;

function TSeats.GetRandomSlot(out aLineIndex, aSlotIndex: integer): boolean;
var i, j, c: integer;
  empty: array of array[0..1] of integer;
begin
  // retrieve the number of empty slot
  c := 0;
  for i:=0 to LINE_COUNT-1 do
    for j:=0 to SLOTPERLINE-1 do
      if FSlots[i,j] = NIL then inc(c);

  if c = 0 then exit(False);

  // gets the indexes of empty slots
  empty := NIL;
  SetLength(empty, c);
  c := 0;
  for i:=0 to LINE_COUNT-1 do
    for j:=0 to SLOTPERLINE-1 do
      if FSlots[i,j] = NIL then begin
        empty[c][0] := i;
        empty[c][1] := j;
        inc(c);
      end;

  if Length(empty) = 1 then c := 0
    else c := Random(Length(empty));

  aLineIndex := empty[c][0];
  aSlotIndex := empty[c][1];
  Result := True;
end;

procedure TSeats.FreeSlot(aLineIndex, aSlotIndex: integer);
begin
  FSlots[aLineIndex, aSlotIndex] := NIL;
end;

procedure TSeats.CreateRobot;
var lineindex, slotIndex: integer;
  o: TRobot;
  seat: TSeat;
  function SlotIndexToSeatIndex(aSlotIndex: integer): integer;
  begin
    case aSlotIndex of
      0: Result := 0;
      1, 2: Result := 1;
      3, 4: Result := 2;
      5: Result := 3;
    end;
  end;
begin
  if not GetRandomSlot(lineindex, slotIndex) then exit;

  seat := FSeatSprite[lineindex, SlotIndexToSeatIndex(slotIndex)];

  o := TRobot.Create;
  FSlots[lineindex, slotIndex] := o;
  o.FLineIndex := lineindex;
  o.FSlotIndex := slotIndex;
  o.Scale.Value := seat.Scale.Value; // PointF(SCALE_VALUES[lineindex], SCALE_VALUES[lineindex]);
  //o.Pivot := PointF(0.5, 1.0);
  AddChild(o, seat.ZOrderAsChild-5); // ZORDER_VALUES[lineindex]);
  o.ScaledY := seat.ScaledY + seat.ScaledHeight*0.1; // FYAppearance[lineindex];
  o.ScaledX := seat.ScaledX + seat.ScaledWidth*0.1;
  o.StartAnim(slotIndex);
end;

constructor TSeats.Create;
var yy, zoom: single;
  tintAmount: integer;
  o: TSeat;
  procedure CreateSeatChild(ax: single; aZOrder, aLineIndex, aSlotIndex: integer; aFlipH: boolean=False);
  begin
    o := TSeat.Create(aFlipH);
    FScene.Add(o, LAYER_GROUND);
    o.Scale.Value := PointF(zoom, zoom);
    o.ScaledX := ax;
    o.ScaledY := yy;
    o.Tint.Value := BGRA(0,0,0,tintAmount);
    o.SetChildOf(Self, aZOrder);
    o.Tag1 := aSlotIndex;
    FSeatSprite[aLineIndex, aSlotIndex] := o;
  end;

begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_GROUND);

  // line 1
  zoom := SCALE_VALUES[0];
  tintAmount := 0;
  yy := ScaleH(444);
  CreateSeatChild(ScaleW(-13), -1, 0, 0);
  CreateSeatChild(ScaleW(177), 0, 0, 1);
  CreateSeatChild(ScaleW(842), -3, 0, 3, True);
  CreateSeatChild(ScaleW(651), -2, 0, 2, True);

  // line 2
  zoom := SCALE_VALUES[1];
  tintAmount := 20;
  yy := ScaleH(428);
  CreateSeatChild(ScaleW(150), -11, 1, 0);
  CreateSeatChild(ScaleW(297), -10, 1, 1);   //280
  CreateSeatChild(ScaleW(741),- 13, 1, 3, True);
  CreateSeatChild(ScaleW(604), -12, 1, 2, True);   //611

  // line 3
  zoom := 0.463;
  tintAmount := 40;
  yy := ScaleH(417);
  CreateSeatChild(ScaleW(261), -21, 2, 0);
  CreateSeatChild(ScaleW(349), -20, 2, 1);
  CreateSeatChild(ScaleW(672), -23, 2, 3, True);
  CreateSeatChild(ScaleW(584), -22, 2, 2, True);

  // line 4
  zoom := 0.315;
  tintAmount := 60;
  yy := ScaleH(410);
  CreateSeatChild(ScaleW(336), -31, 3, 0);
  CreateSeatChild(ScaleW(397), -30, 3, 1);
  CreateSeatChild(ScaleW(626), -33, 3, 3, True);
  CreateSeatChild(ScaleW(566), -32, 3, 2, True);

  // line 5
  zoom := 0.211;
  tintAmount := 80;
  yy := ScaleH(406);
  CreateSeatChild(ScaleW(389), -41, 4, 0);
  CreateSeatChild(ScaleW(429), -40, 4, 1);
  CreateSeatChild(ScaleW(594), -43, 4, 3, True);
  CreateSeatChild(ScaleW(554), -42, 4, 2, True);

  // line 6
  zoom := 0.145;
  tintAmount := 100;
  yy := ScaleH(402);
  CreateSeatChild(ScaleW(423), -51, 5, 0);
  CreateSeatChild(ScaleW(451), -50, 5, 1);
  CreateSeatChild(ScaleW(573), -53, 5, 3, True);
  CreateSeatChild(ScaleW(545), -52, 5, 2, True);

  // line 7
  zoom := 0.094;
  tintAmount := 120;
  yy := ScaleH(401);
  CreateSeatChild(ScaleW(449), -61, 6, 0);
  CreateSeatChild(ScaleW(467), -60, 6, 1);
  CreateSeatChild(ScaleW(558), -63, 6, 3, True);
  CreateSeatChild(ScaleW(540), -62, 6, 2, True);

  Slots_InitDefault;
  FYAppearance[0] := ScaleH(469);
  FYAppearance[1] := ScaleH(444);
  FYAppearance[2] := ScaleH(429);
  FYAppearance[3] := ScaleH(418);
  FYAppearance[4] := ScaleH(410);
  FYAppearance[5] := ScaleH(406);
  FYAppearance[6] := ScaleH(404);
end;

function TSeats.CheckShootPosition(aWorldPos: TPointF): boolean;
var i: integer;
  o: TSimpleSurfaceWithEffect;
begin
  Result := False;
  for i:=ChildCount-1 downto 0 do begin
    o := Childs[i];
    if o is TSeat then
      if TSeat(o).CheckShootPosition(aWorldPos) then exit(True);
    if o is TRobot then
      TRobot(o).CheckShootPosition(aWorldPos);

    if FARobotIsAlreadyDestroyedWithTheLastShoot then exit(True);
  end;
end;

function TSeats.GetSeatSprite(aLineIndex, aSlotIndex: integer): TSeat;
var i: integer;
begin
  case aSlotIndex of
    0: i := 0;
    1, 2: i := 1;
    3, 4: i := 2;
    5: i := 3;
  end;
  Result := FSeatSprite[aLineIndex, i];
end;

{ TScreenPlainMoonInside }

procedure TScreenPlainMoonInside.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;
  case AValue of
    gsAllRobotDestroyed: begin
      PostMessage(100, 1.0);
    end;
  end;
end;

procedure TScreenPlainMoonInside.ResetVariables;
begin
  FAction2Released := True;
end;

procedure TScreenPlainMoonInside.CreatePerspectiveDecors;
var o: TQuad4Color;
  quad: TQuadCoor;
  sprite: TSprite;
  arrow: TDirectionnalArrow;
  mountain: TScrollableSprite;
  sky: TQuad4Color;
begin
  // ground left
  quad[cTL] := PointF(ScaleW(641), 0);
  quad[cTR] := PointF(ScaleW(649), 0);     //648
  quad[cBR] := PointF(ScaleW(469), ScaleH(414));
  quad[cBL] := PointF(ScaleW(0), ScaleH(414));
  o := TQuad4Color.Create(FScene);
  o.SetSize(quad);
  o.SetTopColors(BGRA(49,42,16));
  o.SetBottomColors(BGRA(102,100,49));
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(-157), ScaleH(409));
  o.CollisionBody.AddPolygon(quad);

  // ground center
  quad[cTL] := PointF(ScaleW(172), 0);
  quad[cTR] := PointF(ScaleW(230), 0);
  quad[cBR] := PointF(ScaleW(403), ScaleH(395));
  quad[cBL] := PointF(ScaleW(0), ScaleH(395));
  o := TQuad4Color.Create(FScene);
  o.SetSize(quad);
  o.SetTopColors(BGRA(124,48,34));
  o.SetBottomColors(BGRA(254,142,124));
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(312), ScaleH(428));
  o.CollisionBody.AddPolygon(quad);

  // ground right
  quad[cTL] := PointF(ScaleW(0), 0);
  quad[cTR] := PointF(ScaleW(8), 0);
  quad[cBR] := PointF(ScaleW(652), ScaleH(414));
  quad[cBL] := PointF(ScaleW(182), ScaleH(414));
  o := TQuad4Color.Create(FScene);
  o.SetSize(quad);
  o.SetTopColors(BGRA(49,42,16));
  o.SetBottomColors(BGRA(102,100,49));
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(532), ScaleH(409));
  o.CollisionBody.AddPolygon(quad);

  // low left wall
  quad[cTL] := PointF(ScaleW(0), ScaleH(61));
  quad[cTR] := PointF(ScaleW(638), ScaleH(0));
  quad[cBR] := PointF(ScaleW(638), ScaleH(24));
  quad[cBL] := PointF(ScaleW(0), ScaleH(437));
  o := TQuad4Color.Create(FScene);
  o.SetSize(quad);
  o.SetLeftColors(BGRA(255,247,108));
  o.SetRightColors(BGRA(185,175,0));
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(-154), ScaleH(385));
  o.CollisionBody.AddPolygon(quad);

  // low right wall
  quad[cTL] := PointF(ScaleW(0), ScaleH(-1));  //0
  quad[cTR] := PointF(ScaleW(644), ScaleH(62));   //63
  quad[cBR] := PointF(ScaleW(644), ScaleH(438));
  quad[cBL] := PointF(ScaleW(0), ScaleH(24));
  o := TQuad4Color.Create(FScene);
  o.SetSize(quad);
  o.SetRightColors(BGRA(255,247,108));
  o.SetLeftColors(BGRA(185,175,0));
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(539), ScaleH(385));
  o.CollisionBody.AddPolygon(quad);

  // sky behind the left window
  sky := TQuad4Color.Create(FScene);
  sky.SetSize(QuadCoor(PointF(0,0), PointF(ScaleW(490), ScaleH(192)),
                       PointF(ScaleW(490), ScaleH(240)),  PointF(ScaleW(0), ScaleH(315))));
  sky.SetCoordinate(ScaleW(-1), ScaleH(156));
  sky.SetTopColors(BGRA(212,68,119));
  sky.SetBottomColors(BGRA(57,4,37));
  FScene.Add(sky, LAYER_BG3);
  // mountain behind the left window
  mountain := TScrollableSprite.Create(texMountain, False);
  mountain.SetShape(QuadCoor(PointF(0,0), PointF(ScaleW(611), ScaleH(140)),
                              PointF(ScaleW(611), ScaleH(212)),  PointF(ScaleW(0), ScaleH(212))));
  mountain.SetCoordinate(ScaleW(-142), ScaleH(216));
  mountain.Offset.x.AddConstant(100);
  mountain.Tint.Value := BGRA(0,0,0,100);
  mountain.Opacity.Value := 150;
  FScene.Add(mountain, LAYER_BG3);
  // middle wall left + windows
  sprite := TSprite.Create(texLeftWallWindow, False);
  FScene.Add(sprite, LAYER_BG2);
  sprite.SetCoordinate(ScaleW(-155), ScaleH(156));
  sprite.CollisionBody.AddPolygon([PointF(ScaleW(154), ScaleH(50)),
                                   PointF(ScaleW(639), ScaleH(205)),
                                   PointF(ScaleW(639), ScaleH(229)),
                                   PointF(ScaleW(154), ScaleH(276))]);

  // sky behind the right window
  sky := TQuad4Color.Create(FScene);
  sky.SetSize(QuadCoor(PointF(0,192), PointF(ScaleW(490), ScaleH(0)),
                       PointF(ScaleW(490), ScaleH(315)),  PointF(ScaleW(0), ScaleH(240))));
  sky.SetCoordinate(ScaleW(548), ScaleH(156));
  sky.SetTopColors(BGRA(212,68,119));
  sky.SetBottomColors(BGRA(57,4,37));
  FScene.Add(sky, LAYER_BG3);
  // mountain behind the right window
  mountain := TScrollableSprite.Create(texMountain, False);
  mountain.SetShape(QuadCoor(PointF(0,140), PointF(ScaleW(611), ScaleH(0)),
                              PointF(ScaleW(611), ScaleH(212)),  PointF(ScaleW(0), ScaleH(212))));
  mountain.SetCoordinate(ScaleW(555), ScaleH(216));
  mountain.Offset.x.AddConstant(-100);
  mountain.Tint.Value := BGRA(0,0,0,100);
  mountain.Opacity.Value := 150;
  FScene.Add(mountain, LAYER_BG3);
  // middle wall right + windows
  sprite := TSprite.Create(texLeftWallWindow, False);
  FScene.Add(sprite, LAYER_BG2);
  sprite.FlipH := True;
  sprite.SetCoordinate(ScaleW(539), ScaleH(156));
  sprite.CollisionBody.AddPolygon([PointF(ScaleW(0), ScaleH(205)),
                                   PointF(ScaleW(485), ScaleH(50)),
                                   PointF(ScaleW(485), ScaleH(276)),
                                   PointF(ScaleW(0), ScaleH(229))]);

  // high wall left
  quad[cTL] := PointF(ScaleW(0), ScaleH(0));
  quad[cTR] := PointF(ScaleW(639), ScaleH(555)); //421
  quad[cBR] := PointF(ScaleW(639), ScaleH(577));
  quad[cBL] := PointF(ScaleW(0), ScaleH(373));
  o := TQuad4Color.Create(FScene);
  o.SetSize(quad);
  o.SetRightColors(BGRA(111,94,35));
  o.SetLeftColors(BGRA(253,243,121));
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(-155), ScaleH(-215));
  o.CollisionBody.AddPolygon(quad);

  // high wall right
  quad[cTL] := PointF(ScaleW(0), ScaleH(555));
  quad[cTR] := PointF(ScaleW(640), ScaleH(0));
  quad[cBR] := PointF(ScaleW(640), ScaleH(370));
  quad[cBL] := PointF(ScaleW(0), ScaleH(575));
  o := TQuad4Color.Create(FScene);
  o.SetSize(quad);
  o.SetLeftColors(BGRA(111,94,35));
  o.SetRightColors(BGRA(253,243,121));
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(539), ScaleH(-213));
  o.CollisionBody.AddPolygon(quad);

  // roof left
  quad[cTL] := PointF(ScaleW(0), ScaleH(0));
  quad[cTR] := PointF(ScaleW(313), ScaleH(0));
  quad[cBR] := PointF(ScaleW(507), ScaleH(441));
  quad[cBL] := PointF(ScaleW(507), ScaleH(441));
  o := TQuad4Color.Create(FScene);
  o.SetSize(quad);
  o.SetTopColors(BGRA(255,248,193));
  o.SetBottomColors(BGRA(200,191,111));
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(-21), ScaleH(-98));
  o.CollisionBody.AddPolygon(quad);

  // roof right
  quad[cTL] := PointF(ScaleW(194), ScaleH(0));
  quad[cTR] := PointF(ScaleW(509), ScaleH(0));
  quad[cBR] := PointF(ScaleW(0), ScaleH(443));
  quad[cBL] := PointF(ScaleW(0), ScaleH(443));
  o := TQuad4Color.Create(FScene);
  o.SetSize(quad);
  o.SetTopColors(BGRA(255,248,193));
  o.SetBottomColors(BGRA(200,191,111));
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(538), ScaleH(-98));
  o.CollisionBody.AddPolygon(quad);

  // roof center
  quad[cTL] := PointF(ScaleW(0), ScaleH(0));
  quad[cTR] := PointF(ScaleW(440), ScaleH(0));
  quad[cBR] := PointF(ScaleW(247), ScaleH(441));
  quad[cBL] := PointF(ScaleW(194), ScaleH(441));
  o := TQuad4Color.Create(FScene);
  o.SetSize(quad);
  o.SetTopColors(BGRA(70,163,221));
  o.SetBottomColors(BGRA(23,91,134));
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(292), ScaleH(-98));
  o.CollisionBody.AddPolygon(quad);

  // wall background + arrow + door
  sprite := FScene.AddSprite(texWallBG, False, LAYER_BG2);
  sprite.SetCoordinate(ScaleW(483), ScaleH(341));
  arrow := TDirectionnalArrow.Create(d4Right, texDirectionnalArrow, -1);
  sprite.AddChild(arrow, 0);
  arrow.CenterX := sprite.Width*0.35;
  arrow.CenterY := sprite.Height*0.5;
  arrow.Show;
  FDoor := TAutomaticDoor.Create(0, 0, -1);
  FDoor.CenterX := sprite.Width*0.5;
  FDoor.BottomY := sprite.Height;
  sprite.AddChild(FDoor, 1);
  //FDoor.Open;
 end;

procedure TScreenPlainMoonInside.PlayLaserShootSound;
begin
  Audio.PlayThenKillSound('laser-gunshot.ogg', 0.8, 0.0, 1.0+Random*0.1-0.05, Audio.FXReverbShort, 0.5);
end;

procedure TScreenPlainMoonInside.CheckShootOnWagonWall(aWorldPos: TPointF);
var i: integer;
  o: TSimpleSurfaceWithEffect;
  item: TOGLCBodyItem;
  impact: TSprite;
  p: TPointF;
  v: single;
begin
  item.BodyType := _btPoint;
  item.pt := aWorldPos;

  for i:=0 to FScene.Layer[LAYER_BG2].SurfaceCount-1 do begin
    o := FScene.Layer[LAYER_BG2].Surface[i];
    o.CollisionBody.SetSurfaceToWordMatrix(o.GetMatrixSurfaceToWorld);
    if o.CollisionBody.CheckCollisionWith(item) then begin
      impact := TSprite.Create(texSeatImpact, False);
      o.AddChild(impact, 1);
      impact.Angle.Value := random*360;
      p := o.SceneToSurface(aWorldPos);
      impact.CenterX := p.x;
      impact.CenterY := p.y;
      impact.Opacity.Value := 200;
      v := Distance(aWorldPos, FScene.Center); // zoom is from 1.0 to 0.094
      v := EnsureRange(v / (FScene.Width*0.45), 0.0, 1.0); // the closer v is to the center, the closer it tends to zero
      v := v * (1.0 - 0.094) + 0.094;
      impact.Scale.Value := PointF(v,v);
      exit;
    end;
  end;
end;

procedure TScreenPlainMoonInside.CreateObjects;
var path: string;
  ima: TBGRABitmap;
begin
  FGameState := gsUndefined;
  ResetVariables;

  if screen_gameplainmoon.sndTrainWheel <> NIL then
    screen_gameplainmoon.sndTrainWheel.Tone.ChangeTo(0.05, 2.0);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  path := FolderSpritePlainOfSleepingMoonInside;
  texTarget := FAtlas.AddFromSVG(path+'Target.svg', ScaleW(50), -1);
  texSeat := FAtlas.AddFromSVG(path+'Seat.svg', -1, ScaleH(307));
  texSeatImpact := FAtlas.AddFromSVG(path+'SeatImpact.svg', ScaleW(31), -1);
  texLeftWallWindow := FAtlas.AddFromSVG(path+'LeftWallWindow.svg', ScaleW(639), -1);
  texWallBG := FAtlas.AddFromSVG(path+'WallBG.svg', ScaleW(58), -1);
  texDirectionnalArrow := FAtlas.AddFromSVG(SpriteUIFolder+'ArrowYellow.svg', ScaleW(21), -1);
  texRobotBody := FAtlas.AddFromSVG(path+'RobotBody.svg', ScaleW(119), -1);
  texRobotWheel := FAtlas.AddFromSVG(path+'RobotWheel.svg', ScaleW(15), -1);
  texRobotArm := FAtlas.AddFromSVG(path+'RobotArm.svg', -1, ScaleH(104));
  //texMountain := FAtlas.AddFromSVG(GetFolderSpritePlainOfSleepingMoon+'Mountain1.svg', ScaleW(745), -1);

  TAutomaticDoor.LoadTexture(FAtlas, ScaleW(52), ScaleH(64));

  // ui
  CreateGameFontNumber(FAtlas); // < must be first !
  LoadWatchTexture(FAtlas);
  LoadLaserGunTexture(FAtlas);
  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);
  LoadGameDialogTextures(FAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;

  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  texMountain := FScene.TexMan.AddFromSVG(GetFolderSpritePlainOfSleepingMoon+'Mountain1.svg', ScaleW(745), -1);

  // panel game inventory
  FGameInventory := TGameInventory.Create;
  FGameInventory.AddClock;

  // inside wagon
  CreatePerspectiveDecors;
  // seats
  FSeats := TSeats.Create;

  // camera to simulate wagon swing and shake
  FCamera := FScene.CreateCamera;
  FCamera.AssignToLayerRange(LAYER_WEATHER, LAYER_BG2);
  PostMessage(0);  // swing animation
  PostMessage(10); // shake animation
  FWagonSwingAndShake := True;

  // target moved by mouse
  FScene.Mouse.SetCursorSprite(texTarget, False, PointF(texTarget^.FrameWidth*0.5, texTarget^.FrameHeight*0.5));

  // pause panel
  FInGamePausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  FRobotCount := 20 + (screen_gameplainmoon.PLAIN_MOON_WAGON_COUNT - PlayerInfo.PlainMoon.CurrentWagonIndex)*10;
  FRobotCreated := 0;
  FRobotDestroyed := 0;

  PostMessage(50); // show 'Get ready/GO'
end;

procedure TScreenPlainMoonInside.FreeObjects;
begin
  FScene.TexMan.Delete(texMountain);

  // if player interrupts the game to return to map, we restart the map music
  if FInGamePausePanel.PlayerHaveClickedBackToMapButton{FRobotDestroyed < FRobotCount} then begin
    ScreenPlainOfSleepingMoon.FadeOutAndKillMusicAndSounds;
    Audio.ResumeMusicTitleMap;
  end
  else if screen_gameplainmoon.sndTrainWheel <> NIL then
         screen_gameplainmoon.sndTrainWheel.Tone.ChangeTo(0.5, 3.0);

  FScene.Mouse.DeleteCursorSprite;
  FScene.KillCamera(FCamera);

  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
end;

procedure TScreenPlainMoonInside.ProcessMessage(UserValue: TUserMessageValue);
var mvt, d: single;
begin
  case UserValue of
    // WAGON SWING
    0: begin
      if not FWagonSwingAndShake then exit;
      d := Random*2.0+0.5;
      mvt := Random*1.5;
      if Random > 0.5 then mvt := -mvt;
      FCamera.Angle.ChangeTo(mvt, d, idcSinusoid);
      PostMessage( 0, d+Random*2.0);
    end;
    // WAGON SHAKER
    10: begin
      if not FWagonSwingAndShake then exit;
      mvt := Random+0.5;
      FCamera.MoveTo(FScene.Center+PointF(0, mvt));
      PostMessage(11, 0.05);
    end;
    11: begin
      if not FWagonSwingAndShake then exit;
      FCamera.MoveTo(FScene.Center);
      PostMessage(10, Random*2.0+0.1);
    end;

    // GET READY/GO
    50: begin
      ShowGetReadyGo(52, 0, NIL);
    end;
    52: begin
      GameState := gsRunning;
      FGameInventory.Clock.StartTime;
    end;

    // ANIM all robots are destroyed
    100: begin
      Audio.PlayMusicSuccessShort1;
      PostMessage(102, 1.5);
    end;
    102: begin
      FDoor.Open;
      PostMessage(104, 1.0);
    end;
    104: begin
      FWagonSwingAndShake := False;
      FCamera.Scale.ChangeTo(PointF(3.0,3.0), 5.0);
      PostMessage(110, 2.0);
      PostMessage(106);
    end;
    106: begin  // camera swing
      FCamera.Angle.ChangeTo(-1.0, 0.5, idcSinusoid);
      PostMessage(107, 0.5);
    end;
    107: begin
      FCamera.Angle.ChangeTo(1.0, 0.5, idcSinusoid);
      PostMessage(106, 0.5);
    end;
    110: begin
      // the wagon is cleaned
      PlayerInfo.PlainMoon.CurrentWagonJustDone := True;
      PlayerInfo.PlainMoon.RemainingSeconds := FGameInventory.Clock.Second;
      FScene.RunScreen(ScreenPlainOfSleepingMoon);
    end;
  end;
end;

procedure TScreenPlainMoonInside.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  case FGameState of
    gsRunning: begin
      // robot creation
      if FRobotCreated < FRobotCount then begin
        FTimeAccuToCreateRobot := FTimeAccuToCreateRobot - aElapsedTime;
        if FTimeAccuToCreateRobot <= 0 then begin
          FTimeAccuToCreateRobot := Random*PlayerInfo.PlainMoon.CurrentWagonIndex*0.3+0.2;
          FSeats.CreateRobot;
          inc(FRobotCreated);
        end;
      end else if FRobotDestroyed = FRobotCreated then GameState := gsAllRobotDestroyed;

      // shoot
      if Input.Action2Pressed then begin
        if FAction2Released then begin
          PlayLaserShootSound;
          FARobotIsAlreadyDestroyedWithTheLastShoot := False;
          if not FSeats.CheckShootPosition(PointF(FScene.Mouse.Position)) then
            CheckShootOnWagonWall(PointF(FScene.Mouse.Position));
          FAction2Released := False;
        end;
      end else FAction2Released := True;

      // zoom
    {  if Input.Action1Pressed and (FCamera.Scale.State = psNO_CHANGE) then begin
        if FCamera.Scale.x.Value = 1 then FCamera.Scale.ChangeTo(PointF(3,3), 0.5)
        else
        if FCamera.Scale.x.Value = 3 then FCamera.Scale.ChangeTo(PointF(1,1), 0.5);
      end;   }
    end;
  end;//case

  // check if player pause the game
  if Input.PausePressed then
    FInGamePausePanel.ShowModal;

end;

end.

