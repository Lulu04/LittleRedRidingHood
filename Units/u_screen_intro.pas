unit u_screen_intro;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_sprite_lr4dir, u_sprite_lrcommon,
  u_sprite_wolf, u_sprite_granny;

type

TGameState = (gsUndefined, gsStarted);

{ TScreenIntroCinematic }

TScreenIntroCinematic = class(TGameScreenTemplate)
private
  FGameState: TGameState;
  FCamera: TOGLCCamera;
  FCameraFollowLR: boolean;
  FLR: TLR4Direction;
  FGranny: TGranny;
  FBBQ, FGrannyKidnapped: TSprite;
  FWolfRight, FWolfLeft: TWolf;
  texBBQ, texStool, texTable, texFence, texBigPeakMontainGray, texSmallPeakMontainGray,
  texHome, texOak, texGrassLarge, texFlower, texGrannyKidnapped: PTexture;
  FAtlas: TOGLCTextureAtlas;
  FFontText: TTexturedFont;
  FPEHomeSmoke, FPEBBQSmoke: TParticleEmitter;
  FsndTranquille: TALSSound;

  procedure SetGameState(AValue: TGameState);
  procedure CreateLevel;
  function CharacterBottomY: single;
  procedure PrepareGrannyKidnapped;
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  procedure MoveCameraTo(const p: TPointF; aDuration: single);
  procedure ZoomCameraTo(const z: TPointF; aDuration: single);

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenIntro: TScreenIntroCinematic;

implementation

uses Forms,u_app, u_gamebackground, u_resourcestring, u_screen_map, Math;

// sort the surfaces by Y value
function SortSprite(Item1, Item2: Pointer): Integer;
var o1, o2: TSimpleSurfaceWithEffect;
  y1, y2: integer;
begin
  o1 := TSimpleSurfaceWithEffect(Item1);
  o2 := TSimpleSurfaceWithEffect(Item2);

  if o1 is TBaseComplexContainer then
    with TBaseComplexContainer(o1) do y1 := Trunc(Y.Value + DeltaYToBottom)
  else y1 := Trunc(o1.BottomY);
  if o2 is TBaseComplexContainer then
    with TBaseComplexContainer(o2) do y2 := Trunc(Y.Value + DeltaYToBottom)
  else y2 := Trunc(o2.BottomY);

  if y1 > y2 then Result := 1
  else if y1 < y2 then Result := -1
  else Result := 0;
end;

type

{ TCloud }

TCloud = class(TSprite)
  constructor Create(aX, aY: single; aAtlas: TAtlas);
  procedure Update(const aElapsedTime: single); override;
end;

var
  FViewArea: TRectF;

{ TCloud }

constructor TCloud.Create(aX, aY: single; aAtlas: TAtlas);
begin
  inherited Create(aAtlas.RetrieveTextureByFileName('Cloud128x128.png'), False);
  FScene.Add(Self, LAYER_BG3);
  SetCoordinate(aX, aY);
  Scale.Value := PointF(2, 2);
  Speed.X.Value := -PPIScale(50)*(0.1+0.1*Random);
end;

procedure TCloud.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if X.Value < -Width then X.Value := FViewArea.Right;
end;

{ TScreenIntroCinematic }

procedure TScreenIntroCinematic.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then Exit;
  FGameState := AValue;
end;

procedure TScreenIntroCinematic.CreateLevel;
var rec: TMultiColorRectangle;
  o: TSprite;
  g: TGrassLarge;
  xx, yy: single;
  i: integer;
begin
  FViewArea.Left := FScene.Width*0.5;
  FViewArea.Top := FScene.Height*0.5;
  FViewArea.Right := ScaleW(1855);
  FViewArea.Bottom := ScaleH(768);

  // blue sky
  rec := TMultiColorRectangle.Create(Round(FViewArea.Right), ScaleH(422));
  FScene.Add(rec, LAYER_BG3);
  rec.SetTopColors(BGRA(157,226,252));
  rec.SetBottomColors(BGRA(58,134,255));
  // green ground
  rec := TMultiColorRectangle.Create(Round(FViewArea.Right), ScaleH(346));
  FScene.Add(rec, LAYER_BG3);
  rec.SetCoordinate(0, ScaleH(423));
  rec.SetTopColors(BGRA(2,126,0));
  rec.SetBottomColors(BGRA(62,249,79));
  // peak montain gray
  FScene.AddSprite(texSmallPeakMontainGray, False, LAYER_BG3, ScaleW(736), ScaleH(219));
  FScene.AddSprite(texBigPeakMontainGray, False, LAYER_BG3, ScaleW(632), ScaleH(135));
  FScene.AddSprite(texBigPeakMontainGray, False, LAYER_BG3, ScaleW(794), ScaleH(116));
  FScene.AddSprite(texBigPeakMontainGray, False, LAYER_BG3, ScaleW(900), ScaleH(99));
  FScene.AddSprite(texSmallPeakMontainGray, False, LAYER_BG3, ScaleW(865), ScaleH(249));
  FScene.AddSprite(texSmallPeakMontainGray, False, LAYER_BG3, ScaleW(1103), ScaleH(219));
  FScene.AddSprite(texBigPeakMontainGray, False, LAYER_BG3, ScaleW(999), ScaleH(135));
  FScene.AddSprite(texBigPeakMontainGray, False, LAYER_BG3, ScaleW(1162), ScaleH(116));
  FScene.AddSprite(texBigPeakMontainGray, False, LAYER_BG3, ScaleW(1265), ScaleH(98));
  FScene.AddSprite(texSmallPeakMontainGray, False, LAYER_BG3, ScaleW(1231), ScaleH(248));
  FScene.AddSprite(texSmallPeakMontainGray, False, LAYER_BG3, ScaleW(1365), ScaleH(257));
  FScene.AddSprite(texBigPeakMontainGray, False, LAYER_BG3, ScaleW(1441), ScaleH(131));
  FScene.AddSprite(texBigPeakMontainGray, False, LAYER_BG3, ScaleW(1609), ScaleH(101));
  FScene.AddSprite(texSmallPeakMontainGray, False, LAYER_BG3, ScaleW(1549), ScaleH(259));
  FScene.AddSprite(texBigPeakMontainGray, False, LAYER_BG3, ScaleW(1667), ScaleH(135));
  FScene.AddSprite(texSmallPeakMontainGray, False, LAYER_BG3, ScaleW(1771), ScaleH(243));

  // fence
  xx := 280;
  for i:=1 to 15 do begin
    o := TTiledSprite.Create(texFence, False);
    FScene.Add(o, LAYER_GROUND);
    o.SetCoordinate(xx, ScaleH(391));
    xx := xx + o.Width;
  end;
  // oaks
  FScene.AddSprite(texOak, False, LAYER_GROUND, ScaleW(360), ScaleH(83));
  with FScene.AddSprite(texOak, False, LAYER_GROUND, ScaleW(553), ScaleH(147)) do FlipH := True;
  FScene.AddSprite(texOak, False, LAYER_GROUND, ScaleW(1161), ScaleH(73));
  // home
  o := TSprite.Create(texHome, False);
  FScene.Add(o, LAYER_GROUND);
  o.SetCoordinate(ScaleW(0), ScaleH(242));
  // home smoke
  FPEHomeSmoke := TParticleEmitter.Create(FScene);
  FScene.Add(FPEHomeSmoke, LAYER_FXANIM);
  FPEHomeSmoke.LoadFromFile(ParticleFolder+'WorkShopSmokeForIntro.par', FAtlas);
  FPEHomeSmoke.SetCoordinate(o.X.Value+o.Width*0.19, o.Y.Value);
  FPEHomeSmoke.SetEmitterTypeLine(PointF(o.X.Value+o.Width*0.35, o.Y.Value));
  // stool behind table
  o := TSprite.Create(texStool, False);
  FScene.Add(o, LAYER_GROUND);
  o.SetCoordinate(ScaleW(343), ScaleH(523));
  // table
  o := TSprite.Create(texTable, False);
  FScene.Add(o, LAYER_GROUND);
  o.SetCoordinate(ScaleW(257), ScaleH(499));
  // stool forward table
  o := TSprite.Create(texStool, False);
  FScene.Add(o, LAYER_GROUND);
  o.SetCoordinate(ScaleW(292), ScaleH(558));
  // BBQ
  FBBQ := TSprite.Create(texBBQ, False);
  FScene.Add(FBBQ, LAYER_GROUND);
  FBBQ.SetCoordinate(ScaleW(524), ScaleH(564));
  // BBQ smoke
  FPEBBQSmoke := TParticleEmitter.Create(FScene);
  FScene.Add(FPEBBQSmoke, LAYER_GROUND);
  FPEBBQSmoke.LoadFromFile(ParticleFolder+'BBQSmokeForIntro.par', FAtlas);
  FPEBBQSmoke.SetCoordinate(FBBQ.X.Value+FBBQ.Width*0.2, FBBQ.Y.Value);
  FPEBBQSmoke.SetEmitterTypeLine(PointF(FBBQ.RightX-FBBQ.Width*0.2, FBBQ.Y.Value));
  // grass
  yy := ScaleH(508);
  repeat
    xx :=-ScaleW(10)-Random*texGrassLarge^.FrameWidth*0.25;
    repeat
      g := TGrassLarge.Create(texGrassLarge, xx, yy, LAYER_GROUND);
      g.Amplitude.X.Value := 0.4;
      g.DeformationSpeed.Value := PointF(1.2, 0);
      xx := xx + texGrassLarge^.FrameWidth - Random*texGrassLarge^.FrameWidth*0.25;
    until xx > FViewArea.Right+texGrassLarge^.FrameWidth*0.25;
    yy := yy + texGrassLarge^.FrameHeight*0.6;
  until yy > FViewArea.Bottom;
  // flowers
  TFlower.Create(texFlower, ScaleW(1646), ScaleH(567), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(1681), ScaleH(578), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(1642), ScaleH(601), LAYER_GROUND);
  TFlower.Create(texFlower, ScaleW(1671), ScaleH(612), LAYER_GROUND);

  // clouds
  TCloud.Create(ScaleW(0), ScaleH(16), FAtlas);
  TCloud.Create(ScaleW(228), ScaleH(-34), FAtlas);
  TCloud.Create(ScaleW(395), ScaleH(47), FAtlas);
  TCloud.Create(ScaleW(480), ScaleH(-40), FAtlas);
  TCloud.Create(ScaleW(733), ScaleH(20), FAtlas);
  TCloud.Create(ScaleW(1000), ScaleH(-19), FAtlas);
  TCloud.Create(ScaleW(1187), ScaleH(31), FAtlas);

  FViewArea.Right := FViewArea.Right - FScene.Width*0.5;
  FViewArea.Bottom := FViewArea.Bottom - FScene.Height*0.5;
end;

function TScreenIntroCinematic.CharacterBottomY: single;
begin
  Result := ScaleH(635);
end;

procedure TScreenIntroCinematic.PrepareGrannyKidnapped;
begin
  FWolfLeft := TWolf.Create(False, LAYER_GROUND);
  FWolfLeft.SetCoordinate(ScaleW(183), CharacterBottomY-FWolfLeft.DeltaYToBottom);
  FWolfLeft.TimeMultiplicator := 0.3;

  FWolfRight := TWolf.Create(False, -1);
  FWolfLeft.AddChild(FWolfRight, 0);
  FWolfRight.SetCoordinate(ScaleW(441)-ScaleW(183), 0);
  FWolfRight.TimeMultiplicator := FWolfLeft.TimeMultiplicator;

  FGrannyKidnapped := TSprite.Create(texGrannyKidnapped, False);
  FWolfLeft.AddChild(FGrannyKidnapped, -1);
  FGrannyKidnapped.SetCoordinate(0, -FGrannyKidnapped.Height*0.8);
end;

procedure TScreenIntroCinematic.CreateObjects;
var path: string;
  ima: TBGRABitmap;
begin
  FGameState := gsUndefined;
  Audio.PauseMusicTitleMap(3.0);
  FsndTranquille := Audio.AddMusic('Tranquille.ogg', True);
  FsndTranquille.FadeIn(1.0, 1.0);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 1;

  LoadLR4DirTextures(FAtlas, False);
  LoadGranMaTextures(FAtlas);
  LoadWolfTextures(FAtlas);

  path := SpriteIntroductionFolder;
  texBBQ := FAtlas.AddFromSVG(path+'BBQ.svg', ScaleW(69), -1);
  texStool := FAtlas.AddFromSVG(path+'Stool.svg', ScaleW(58), -1);
  texTable := FAtlas.AddFromSVG(path+'Table.svg', ScaleW(181), -1);
  texFence := FAtlas.AddFromSVG(path+'Fence.svg', ScaleW(113), -1);

  texHome := FAtlas.AddFromSVG(SpriteBGFolder+'LRHome.svg', ScaleW(335), -1);
  texBigPeakMontainGray := FAtlas.AddFromSVG(SpriteBGFolder+'PeakMontainGrayBig.svg', ScaleW(143), -1);
  texSmallPeakMontainGray := FAtlas.AddFromSVG(SpriteBGFolder+'PeakMontainGraySmall.svg', ScaleW(119), -1);
  texOak := FAtlas.AddFromSVG(SpriteBGFolder+'TreeOak.svg', ScaleW(343), -1);
  texGrassLarge := FAtlas.AddFromSVG(SpriteBGFolder+'GrassLarge.svg', ScaleW(212), -1);
  texFlower := FAtlas.AddFromSVG(SpriteBGFolder+'Flower1.svg', ScaleW(31), -1);
  texGrannyKidnapped := FAtlas.AddFromSVG(SpriteGranMaFolder+'PositionKidnapped.svg', ScaleW(250), -1);

  AddGrassLargeTextureToAtlas(FAtlas);
  AddCloud128x128ParticleToAtlas(FAtlas);
  AddSphereParticleToAtlas(FAtlas);

  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);
  LoadGameDialogTextures(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;
  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  // LR 4 direction
  FLR := TLR4Direction.Create;
  FLR.SetCoordinate(ScaleW(658), CharacterBottomY-FLR.DeltaYToBottom);
  FLR.SetWindSpeed(0.5);
  FLR.SetFaceType(lrfSmile);
  FLR.IdleRight;
  FLR.FlipH := True;
  FLR.TimeMultiplicator := 0.8;
  FScene.MoveSurfaceToLayer(FLR, LAYER_GROUND);

  // Granny
  FGranny := TGranny.Create(LAYER_GROUND);
  FGranny.SetCoordinate(ScaleW(478), CharacterBottomY-FGranny.DeltaYToBottom);
  FGranny.SetCookingAnim;

  // cameras
  FCamera := FScene.CreateCamera;
  FCamera.AssignToLayer([LAYER_DIALOG, LAYER_WEATHER, LAYER_ARROW, LAYER_PLAYER,
   LAYER_WOLF, LAYER_FXANIM, LAYER_GROUND, LAYER_BG1, LAYER_BG2, LAYER_BG3]);

  CreateLevel;
  // sort the layer LAYER_GROUND to have the right ZOrder according BottomY coordinate of the surfaces.
  FScene.Layer[LAYER_GROUND].OnSortCompare := @SortSprite;

  // center view on the BBQ
  FCameraFollowLR := False;
  MoveCameraTo(PointF(FBBQ.CenterX, FScene.Height*0.5), 0.0);
  // start the cinematic
  PostMessage(0);
end;

procedure TScreenIntroCinematic.FreeObjects;
begin
  Audio.ResumeMusicTitleMap;
  if FsndTranquille <> NIL then FsndTranquille.FadeOutThenKill(1.0);
  FsndTranquille := NIL;

  FScene.KillCamera(FCamera);
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
end;

procedure TScreenIntroCinematic.ProcessMessage(UserValue: TUserMessageValue);
var r: TRectF;
begin
  case UserValue of
    // intro cinematic
    0: PostMessage(2, 3.0);
    2: FLR.ShowDialog(sSmellGood, FFontText, Self, 4, 0, FCamera);
    4: FGranny.ShowDialog(sItsAlmostReady, FFontText, Self, 6, 0, FCamera);
    6: PostMessage(8, 3.0);
    8: FGranny.ShowDialog(sWhenGrandFatherWasHere, FFontText, Self, 10, 0, FCamera);
    10: FLR.ShowDialog(sYesIRememberWell, FFontText, Self, 12, 0, FCamera);
    12: FGranny.ShowDialog(sAndYouWereSinging, FFontText, Self, 14, 0, FCamera);
    14: FLR.ShowDialog(sHaHaHa, FFontText, Self, 16, 0, FCamera);
    16: PostMessage(18, 3.0);
    18: FLR.ShowDialog(sItsAlreadybeenFiveYears, FFontText, Self, 20, 0, FCamera);
    20: FGranny.ShowDialog(sYesTimePasses, FFontText, Self, 21, 0, FCamera);
    21: FLR.ShowDialog(sIMissHimToo, FFontText, Self, 23, 0, FCamera);
    23: PostMessage(24, 3.0);
    24: FGranny.ShowDialog(sWouldYouLikeToPickSomeFlowers, FFontText, Self, 25, 0, FCamera);
    25: begin
      MoveCameraTo(PointF(FLR.X.Value, FScene.Height*0.5), 3.0);
      FLR.ShowDialog(sWillGoRightNow, FFontText, Self, 26, 0, FCamera);
    end;
    26: begin
      FCameraFollowLR := True;
      FLR.IdleRight;
      FLR.WalkHorizontallyTo(ScaleW(1600), Self, 28);
    end;
    28: begin
      FLR.IdleRight;
      PostMessage(30, 1.5);
    end;
    30: FLR.ShowDialog(sILoveCommingToSee, FFontText, Self, 32, 0, FCamera);
    32: FLR.ShowDialog(sIPromiseToTakeGoodCare, FFontText, Self, 34, 0, FCamera);
    34: begin
      FLR.State := lr4sBendDown;
      FsndTranquille.FadeOutThenKill(5.0);
      FsndTranquille := NIL;
      PostMessage(36, 1.0);
    end;
    36: begin
      r := FCamera.GetViewRect;
      with TInfoPanel.Create(sGranny, sAhhhh, FFontText, Self, 38) do
        SetCoordinate(r.Left+PPIScale(20), FScene.Height*0.5);
      PrepareGrannyKidnapped;
      FGranny.Visible := False;
    end;
    38: begin
      FLR.ShowQuestionMark;
      FLR.SetFaceType(lrfWorry);
      PostMessage(40, 0.5);
    end;
    40: begin
      FLR.TimeMultiplicator := 0.5;
      FLR.State := lr4sBendUp;
      PostMessage(42, 0.5);
    end;
    42: begin
      FLR.IdleLeft;
      FLR.HideMark;
      PostMessage(44, 0.2);
    end;
    44: FLR.ShowDialog(sGrannyAsk, FFontText, Self, 46, 0, FCamera);
    46: begin
      FCameraFollowLR := False;
      MoveCameraTo(PointF(FBBQ.CenterX, FScene.Height*0.5), 3.0);
      FLR.WalkHorizontallyTo(ScaleW(965), Self, 48);
    end;
    48: begin
      FLR.IdleLeft;
      FLR.ShowExclamationMark;
      //FCameraFollowLR := False;
      //MoveCameraTo(FBBQ.CenterX, FScene.Height*0.5),
      PostMessage(50,0.2);
    end;
    50: begin
      FWolfLeft.WalkHorizontallyTo(ScaleW(-406), Self, 9999);
      FWolfRight.WalkHorizontallyTo(ScaleW(-406), Self, 9999);
      FWolfRight.Speed.Value := PointF(0, 0);
      PostMessage(52, 1.5);
    end;
    52: begin
      FLR.HideMark;
      FLR.ShowDialog(sHey, FFontText, 1.0, FCamera);
      FLR.WalkHorizontallyTo(ScaleW(-406), Self, 54);
      //PostMessage(54, 2.0);
    end;
    54: FScene.RunScreen(ScreenMap);
  end;
end;

procedure TScreenIntroCinematic.Update(const aElapsedTime: single);
var p: TPointF;
begin
  inherited Update(aElapsedTime);

  // camera follow LR in the bounds of FViewArea
  if FCameraFollowLR then begin
    p.x := EnsureRange(FLR.X.Value, FViewArea.Left, FViewArea.Right);
    p.y := FScene.Height*0.5;
    MoveCameraTo(p, 0.0);
    // audio listener position follow LR position
    Audio.SetListenerPosition(FLR.X.Value, FLR.Y.Value)
  end;
end;

procedure TScreenIntroCinematic.MoveCameraTo(const p: TPointF; aDuration: single);
begin
  FCamera.MoveTo(p, aDuration, idcSinusoid);
end;

procedure TScreenIntroCinematic.ZoomCameraTo(const z: TPointF; aDuration: single);
begin
  FCamera.Scale.ChangeTo(z, aDuration, idcSinusoid);
end;

end.

