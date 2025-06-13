unit u_screen_dartboard;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_gamescreentemplate, u_common, u_common_ui, u_sprite_lrcommon, u_audio, ALSound;

type


  { TScreenDartboard }

  TScreenDartboard = class(TGameScreenTemplate)
  private type TGameState = (gsUndefined, gsWaitToTakeOff, gsRunning, gsEndOfTurn, gsEndOfGame);
  var FState: TGameState;
    procedure SetState(AValue: TGameState);
  private
    FAction1Released: boolean;
    FsndMusic: TALSSound;
    FDartBoard: TSprite;
    FThresholdIndex,
    FTurnIndex: integer;
    procedure CreateDecors;
    procedure ResetVariablePerTurn;
    procedure ShowFinalScore;
    function ComputeTurnGain: integer;
  public
    //procedure DefineSubTextures(aAtlas: TAtlas); override;
    procedure CreateObjects; override;
    procedure FreeObjects; override;
    procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
    procedure Update(const aElapsedTime: single); override;
    property GameState: TGameState read FState write SetState;
  end;

var ScreenDartboard: TScreenDartboard;

implementation
uses Forms, Graphics, u_ui_panels, u_utils, u_app, u_mousepointer, u_screen_sam,
  u_resourcestring, u_dartboard_bird, Math;

const FLY_DURATION = 10.0;
      CAMERA_ZOOM = 3.0;
      TURN_COUNT = 4;

      HoopThreshold: array[0..6] of single=(
         1.4, 1.6, 1.8,
         2.0 , 2.2 , 2.4,
         MaxSingle);

type

TSamHappy = class(TSprite)
  constructor Create;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure Show;
end;

TLabelGain = class(TSprite)
  constructor Create(aGain: integer; aDuration: single=0.5);
end;

{ THoop }

THoop = class(TSprite)
  class var FFlag: boolean;
  constructor Create;
  procedure Update(const aElapsedTime: single); override;
end;

TUIBird = class(TUIItemCounter)
  constructor Create;
end;

TGameInventory = class(TInGameInventoryPanel)
  Score: TUIBird;
  constructor Create;
end;

TStartBoard = class(TSprite)  // LAYER_PLAYER
  constructor Create;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure StartAnimTakeOff;
  procedure Fall;
end;

var
  texPeakBig, texPeakSmall, texFence,
  texDartboard, texHouse, texStartBoard, texHoop,
  texIconBird, texGain0, texGain5, texGain10, texGain20, texGain30,
  texSam: PTexture;
  FAtlas: TAtlas;
  FFontText: TTexturedFont;
  FPausePanel: TInGamePausePanel;
  FGameinventory: TGameInventory;
  FStartBoard: TStartBoard;
  FBird: TDartboardBird;
  FCamera: TOGLCCamera;
  FSamHappy: TSamHappy;

{ TSamHappy }

constructor TSamHappy.Create;
begin
  inherited Create(texSam, False);
  FScene.Add(Self, LAYER_ARROW);
  Scale.Value := PointF(2,2);
  ScaledX := FScene.Width;
  ScaledY := ScaleH(280);
end;

procedure TSamHappy.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // sam appear then disapear
    0: begin
      MoveXRelative(ScaleW(-297), 1, idcSinusoid);
      PostMessage(5, 2.0);
    end;
    5: MoveXRelative(ScaleW(297), 1, idcSinusoid);
  end;
end;

procedure TSamHappy.Show;
begin
  PostMessage(0);
end;

{ TLabelGain }

constructor TLabelGain.Create(aGain: integer; aDuration: single);
begin
  case aGain of
    0: inherited Create(texGain0, False);
    5: inherited Create(texGain5, False);
    10: inherited Create(texGain10, False);
    20: inherited Create(texGain20, False);
    30: inherited Create(texGain30, False);
    else raise exception.create('bad gain '+aGain.ToString);
  end;
  FScene.Add(Self, LAYER_DIALOG);
  SetCenterCoordinate(FBird.Center-PointF(0, PPIScale(10)));
  MoveYRelative(-ScaleH(60), aDuration, idcSinusoid);
  Opacity.ChangeTo(0, aDuration, idcStartSlowEndFast);
  KillDefered(aDuration);
  FGameInventory.Score.Count := FGameInventory.Score.Count + aGain;
end;

{ THoop }

constructor THoop.Create;
var delta: TPointF;
begin
  inherited Create(texHoop, False);
  FScene.Insert(0, Self, LAYER_WOLF);
  delta.x := (Random * 0.2 - 0.1) * FScene.Width;
  delta.y := (Random * 0.1 - 0.05) * FScene.Height;
  SetCenterCoordinate(FScene.Center + delta);
  Scale.Value := PointF(0.4, 0.4);
  Scale.ChangeTo(PointF(1.0, 1.0), 2.0);
  KillDefered(2.0);
  FFlag := not FFlag;
  if FFlag then Angle.AddConstant(180)
    else Angle.AddConstant(-180);
end;

procedure THoop.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  // check if bird
  if InRange(Scale.x.Value, 0.8, 0.95) then begin
    if Distance(FBird.Center, Center) <= texHoop^.FrameWidth*0.5 then begin
      Audio.PlayBlipIncrementScore;
      TLabelGain.Create(5);
      Kill;
    end;
  end;
end;

{ TStartBoard }

constructor TStartBoard.Create;
begin
  inherited Create(texStartBoard, False);
  FScene.Add(Self, LAYER_PLAYER);
  SetCoordinate(ScaleW(605), ScaleH(613));

  FBird := TDartboardBird.Create(-1);
  AddChild(FBird, 0);
  FBird.IdleGround;
  FBird.CenterX := Width*0.5;
  FBird.BottomY := Height*0.4;
end;

procedure TStartBoard.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // anim wait to take off
    0: begin
      if ScreenDartboard.GameState <> gsWaitToTakeOff then exit;
      X.ChangeTo(ScaleW(286), 0.6);
      PostMessage(5, 0.6);
    end;
    5: begin
      if ScreenDartboard.GameState <> gsWaitToTakeOff then exit;
      X.ChangeTo(ScaleW(605), 0.6);
      PostMessage(0, 0.6);
    end;
  end;
end;

procedure TStartBoard.StartAnimTakeOff;
begin
  PostMessage(0);
end;

procedure TStartBoard.Fall;
begin
  Y.ChangeTo(FScene.Height, 0.5, idcDrop);
  KillDefered(0.5);
end;

{ TGameInventory }

constructor TGameInventory.Create;
begin
  inherited Create;
  Score := TUIBird.Create;
  AddItem(Score);
  Score.Count := 0;
end;

{ TUIBird }

constructor TUIBird.Create;
begin
  inherited Create(texIconBird, UIFontNumber, 3);
end;

{ TScreenDartboard }

procedure TScreenDartboard.SetState(AValue: TGameState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  case AValue of
    gsWaitToTakeOff: FStartBoard.StartAnimTakeOff; //PostMessage(100);
    gsEndOfTurn: PostMessage(200);
  end;
end;

procedure TScreenDartboard.CreateDecors;
var bg, bg1: TGradientRectangle;
  o: TSprite;
begin
  // bg
  bg := TGradientRectangle.Create(FScene);
  FScene.Add(bg, LAYER_BG3);
  bg.Gradient.CreateVertical([BGRA(157,226,252), BGRA(58,134,255)], [0.0, 1.0]);
  bg.SetSize(FScene.Width, ScaleH(423));

  bg1 := TGradientRectangle.Create(FScene);
  FScene.Add(bg1, LAYER_BG3);
  bg1.Gradient.CreateVertical([BGRA(27,112,22), BGRA(19,127,12), BGRA(100,163,95)], [0.0, 0.5, 1.0]);
  bg1.SetSize(FScene.Width, FScene.Height-bg.Height);
  bg1.Y.Value := bg.BottomY;

  // peak mountain
  o := FScene.AddSprite(texPeakBig, False, LAYER_BG3);
  o.SetSize(ScaleW(142), ScaleH(343));
  o.SetCoordinate(ScaleW(-2), ScaleH(114));
  o.FlipH := True;

  o := FScene.AddSprite(texPeakSmall, False, LAYER_BG3);
  o.SetSize(ScaleW(228), ScaleH(392));
  o.SetCoordinate(ScaleW(90), ScaleH(69));

  o := FScene.AddSprite(texPeakBig, False, LAYER_BG3);
  o.SetSize(ScaleW(216), ScaleH(499));
  o.SetCoordinate(ScaleW(695), ScaleH(-50));

  o := FScene.AddSprite(texPeakSmall, False, LAYER_BG3);
  o.SetSize(ScaleW(228), ScaleH(409));
  o.SetCoordinate(ScaleW(827), ScaleH(56));
  o.FlipH := True;

  // fence
  o := FScene.AddSprite(texFence, False, LAYER_BG1);
  o.SetCoordinate(ScaleW(-6), ScaleH(368));
  o := FScene.AddSprite(texFence, False, LAYER_BG1);
  o.SetCoordinate(ScaleW(795), ScaleH(368));

  // house
  o := FScene.AddSprite(texHouse, False, LAYER_BG1);
  o.SetCoordinate(ScaleW(154), ScaleH(55));
  // dartboard    texture is ScaleW(86*2)
  FDartBoard := FScene.AddSprite(texDartboard, False, LAYER_BG1);
  FDartBoard.SetSize(ScaleW(86), ScaleH(86));
  FDartBoard.CenterOnScene;

  // sam happy
  FSamHappy := TSamHappy.Create;
end;

procedure TScreenDartboard.ResetVariablePerTurn;
begin
  FThresholdIndex := 0;
  FCamera.Scale.Value := PointF(1, 1);
  if FBird <> NIL then FBird.Kill;

  // create start board and bird
  FStartBoard := TStartBoard.Create;

  with SpriteMessage(Format(sTurn,[FTurnIndex+1, TURN_COUNT])) do begin
    CenterY := FScene.Height*0.3;
    KillDefered(2.0);
  end;
  PostMessage(50, 0.5);
end;

procedure TScreenDartboard.ShowFinalScore;
var fd: TFontDescriptor;
  o: TSprite;
begin
  fd.Create('Arial', FScene.Height div 8, [fsBold], BGRA(255,200,64), BGRA(0,0,0), PPIScale(4));
  o := TSprite.Create(FScene, fd, sScore+' '+FGameinventory.Score.Count.ToString);
  FScene.Add(o, LAYER_DIALOG);
  o.CenterOnScene;
end;

function TScreenDartboard.ComputeTurnGain: integer;
var p: TPointF;
  d, radius: Single;
begin
  // retrieve the radius of the zoomed dartboard
  p := FDartBoard.SurfaceToScene(PointF(0,FDartBoard.Height*0.5));
  radius := (FScene.Center - p).x;

  d := Distance(FBird.ImpactPosition, FScene.Center);
  if d > radius then Result := 0
  else if d < radius*0.191 then begin     //0.194
    Result := 20;
    FSamHappy.Show;
    Audio.PlayMusicSuccessShort1;
  end else if d < radius*0.598 then Result := 10
  else Result := 5;
end;

procedure TScreenDartboard.CreateObjects;
var ima: TBGRABitmap;
  path: String;
  fd: TFontDescriptor;
begin
  GameState := gsUndefined;
  FsndMusic := Audio.AddMusic('fast-banjo-tune-with-acoustic-guitar.ogg', True);
  FsndMusic.Volume.Value := 0.8;

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  path := FolderSpriteDartboard;
  texDartboard := FAtlas.AddFromSVG(path+'Dartboard.svg', ScaleW(86*2), -1);
  texHouse := FAtlas.AddFromSVG(path+'House.svg', ScaleW(715), -1);
  texStartBoard := FAtlas.AddFromSVG(path+'StartBoard.svg', ScaleW(123), -1);
  texHoop := FAtlas.AddFromSVG(path+'Hoop.svg', ScaleW(141), -1);
  fd.Create('Arial', FScene.Height div 12, [fsBold], BGRA(255,200,64), BGRA(0,0,0), PPIScale(4));
  texGain0 := FAtlas.AddString('0', fd, NIL);
  texGain5 := FAtlas.AddString('+5', fd, NIL);
  texGain10 := FAtlas.AddString('+10', fd, NIL);
  texGain20 := FAtlas.AddString('+20', fd, NIL);
  texGain30 := FAtlas.AddString('+30', fd, NIL);
  texSam := FAtlas.AddFromSVG(path+'SamHappy.svg', ScaleW(195), -1);

  texPeakBig  := FAtlas.AddFromSVG(SpriteBGFolder+'PeakMontainGrayBig.svg', ScaleW(200), -1);
  texPeakSmall := FAtlas.AddFromSVG(SpriteBGFolder+'PeakMontainGraySmall.svg', ScaleW(200), -1);
  texFence := FAtlas.AddFromSVG(SpriteIntroductionFolder+'Fence.svg', ScaleW(220), -1);
  TDartboardBird.LoadTexture(FAtlas);

  // ui
  CreateGameFontNumber(FAtlas); // < must be first !
  texIconBird := FAtlas.AddFromSVG(path+'IconBird.svg', -1, IconHeight);
  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);
  LoadGameDialogTextures(FAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(FAtlas);
  LoadMousePointerTexture(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;

  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  CreateDecors;

  // camera
  FCamera := FScene.CreateCamera;
  FCamera.AssignToLayerRange(LAYER_FXANIM, LAYER_BG3);

  // inventory
  FGameinventory := TGameInventory.Create;
  // pause panel
  FPausePanel := TInGamePausePanel.Create(FFontText, FAtlas);
  FPausePanel.SetBackCaptionAndBackScreen(sBackToSam, ScreenSamHome);

  FAction1Released := True;

  CustomizeMousePointer(False);

  FTurnIndex := 0;
  ResetVariablePerTurn;
  FsndMusic.Play;

  // show game instructions
  PostMessage(0);
end;

procedure TScreenDartboard.FreeObjects;
begin
  if FsndMusic <> NIL then FsndMusic.FadeOutThenKill(2.0);
  FsndMusic := NIL;

  FScene.KillCamera(FCamera);
  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
end;

procedure TScreenDartboard.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // show instructions
    0: ShowGameInstructions(sDartboardInstructions);


    // start turn
    50: GameState := gsWaitToTakeOff;


    // END OF TURN
    200: begin
      Audio.PlayThenKillSound('stick-hitting-a-dreadlock-small-thud.ogg', 1.0);
      FBird.Arrival;
      TLabelGain.Create(ComputeTurnGain, 2.0);
      PostMessage(205, 3.0);
    end;
    205: begin
      inc(FTurnIndex);
      if FTurnIndex = TURN_COUNT then PostMessage(300)
        else ResetVariablePerTurn;
    end;

    // end of game
    300: begin
      ShowFinalScore;
      PostMessage(305, 2.0);
    end;
    305: begin
      if FGameinventory.Score.Count > 0 then begin
        u_screen_sam.FPlayerPlaySamsGame := True;
        u_screen_sam.FPlayerSamsGameScore := FGameinventory.Score.Count;
      end;
      FScene.RunScreen(ScreenSamHome);
    end;

  end;
end;

procedure TScreenDartboard.Update(const aElapsedTime: single);
var flagPlayerIdle: boolean;
  d: Single;
begin
  inherited Update(aElapsedTime);
  case GameState of
    gsWaitToTakeOff: begin
      if Input.Action1Pressed{FScene.KeyPressed[Input.KeyAction1]} then begin
        FBird.MoveToLayer(LAYER_PLAYER);
        FBird.StartFly;
        GameState := gsRunning;
        FStartBoard.Fall;
        FStartBoard := NIL;
        FCamera.Scale.ChangeTo(PointF(CAMERA_ZOOM, CAMERA_ZOOM), FLY_DURATION);
      end;
    end;

    gsRunning: begin
      flagPlayerIdle := True;

      // wing flap
      if Input.Action1Pressed then begin
        if FAction1Released then begin
          FBird.WingFlap;
          FAction1Released := False;
        end;
      end else FAction1Released := True;

      if Input.RightPressed and flagPlayerIdle then begin
        FBird.GoRight;
        flagPlayerIdle := False;
      end;

      if Input.LeftPressed and flagPlayerIdle then begin
        FBird.GoLeft;
        flagPlayerIdle := False;
      end;

      if flagPlayerIdle then begin
      end;

      // create hoop
      if FCamera.Scale.x.Value >= HoopThreshold[FThresholdIndex] then begin
        THoop.Create;
        inc(FThresholdIndex);
      end;

      // update bird shadow position
      d := CAMERA_ZOOM - FCamera.Scale.x.Value;
      if d < 1.0 then begin
        FBird.AdjustShadowPosition(d);
        if d = 0 then GameState := gsEndOfTurn;
      end else FBird.Shadow.Visible := False;

    end;// gsRunning
  end;//case
  // check if player pause the game
  if Input.PausePressed then
    FPausePanel.ShowModal;
end;

end.

