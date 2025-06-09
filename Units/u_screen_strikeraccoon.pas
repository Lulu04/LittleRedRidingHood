unit u_screen_strikeraccoon;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_gamescreentemplate, u_common, u_common_ui, u_sprite_lrcommon, u_audio, ALSound;

type


  { TScreenStrikeRaccoon }

  TScreenStrikeRaccoon = class(TGameScreenTemplate)
  private type TGameState = (gsUndefined, gsRunning, gsEndOfTime);
  var FState: TGameState;
    procedure SetState(AValue: TGameState);
  private
    FAtlas: TOGLCTextureAtlas;
    FAction1Released: boolean;
    FsndMusic: TALSSound;
    procedure ShowFinalScore;
  public
    //procedure DefineSubTextures(aAtlas: TAtlas); override;
    procedure CreateObjects; override;
    procedure FreeObjects; override;
    procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
    procedure Update(const aElapsedTime: single); override;
    property GameState: TGameState read FState write SetState;
  end;

var ScreenStrikeRaccoon: TScreenStrikeRaccoon;

implementation

uses Forms, Graphics, u_ui_panels, u_utils, u_app, u_mousepointer, u_screen_sam,
  u_resourcestring;

type

TRaccoon = class(TSpriteContainer)
private
  FRaccoon1: TDeformationGrid;
  FRaccoon2, FRaccoon3: TSprite;
  FIsVisible, FEnableAnim: boolean;
  FTimeVisible, FDeformationSpeed: single;
public
  constructor Create(aCenterX, aBottomY: single);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Appear;
  procedure Disapear;
  procedure Strike;
  property IsVisible: boolean read FIsVisible;
  property TimeVisible: single read FTimeVisible write FTimeVisible;
end;

TBarrel = class(TSprite)  // LAYER_GROUND for barrel, LAYER_ARROW for hammer
private
  FRaccoons: array[0..4] of TRaccoon;
  FTarget, FHammer1, FHammer2: TSprite;
  FTargetIndex, FStrikeCount: integer;
  FCanStrike: boolean;
  function GetDifficultyLevel: integer; // 0 easy, 1, 2 hard
  procedure SetDifficultyLevel;
  procedure SetHammer2Coordinates;
private
  FRunning: boolean;
  FTimeForNextRaccoon: single;
  function ComputeTimeForNextRaccoon: single;
  function GetEmptySlotCount: integer;
  function GetIndexOfEmptySlot: integer;
public
  constructor Create;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;
  procedure StartGame;
  procedure StopGame;
  procedure SetTargetUp;
  procedure SetTargetLeft;
  procedure SetTargetMiddle;
  procedure SetTargetRight;
  procedure SetTargetDown;
  procedure Strike;
end;


TLabelGain = class(TSprite)
  constructor Create(aGain: integer);
end;

TGameInventory = class(TInGameInventoryPanel)
  Clock: TUIClock;
  Score: TUIRaccoonCounter;
  constructor Create;
  procedure IncScore(aSuccessLevel: integer);
end;

var
  texRaccoon1, texRaccoon2, texRaccoon3,
  texTarget, texBarrel, texHammer1, texHammer2, texBoard,
  texGain1, texGain2: PTexture;
  FFontText: TTexturedFont;
  FBarrel: TBarrel;
  FPausePanel: TInGamePausePanel;
  FCurrentSuccessLevel: integer;
  FGameinventory: TGameInventory;
  FGainCoordinate: TPointF;

{ TLabelGain }

constructor TLabelGain.Create(aGain: integer);
begin
  if aGain = 1 then inherited Create(texGain1, False)
    else inherited Create(texGain2, False);
  FScene.Add(Self, LAYER_DIALOG);
  SetCenterCoordinate(FGainCoordinate);
  MoveYRelative(-ScaleH(60), 0.5, idcSinusoid);
  Opacity.ChangeTo(0, 0.5, idcStartSlowEndFast);
  KillDefered(0.5);
end;

{ TGameInventory }

constructor TGameInventory.Create;
begin
  inherited Create;

  Clock := TUIClock.Create;
  AddItem(Clock);

  Score := TUIRaccoonCounter.Create;
  AddItem(Score);
  Score.Count := 0;
end;

procedure TGameInventory.IncScore(aSuccessLevel: integer);
var c: integer;
begin
  if aSuccessLevel = 8 then c := 2
    else c := 1;
  Score.Count := Score.Count + c;
  TLabelGain.Create(c);
end;

{ TBarrel }

function TBarrel.GetDifficultyLevel: integer;
begin
  if FStrikeCount < 15 then Result := 0
  else if FStrikeCount < 25 then Result := 1
  else Result := 2;
end;

procedure TBarrel.SetDifficultyLevel;
var keepTime: single;
  i: integer;
begin
  case GetDifficultyLevel of
    0: keepTime := 2.5;
    1: keepTime := 2.0;
    2: keepTime := 1.8;
  end;

  for i:=0 to High(FRaccoons) do
    FRaccoons[i].TimeVisible := keepTime;
end;

procedure TBarrel.SetHammer2Coordinates;
begin
  case FTargetIndex of
    0: FHammer2.SetCoordinate(ScaleW(422), ScaleH(209));
    1: FHammer2.SetCoordinate(ScaleW(246), ScaleH(330));
    2: FHammer2.SetCoordinate(ScaleW(422), ScaleH(330));
    3: FHammer2.SetCoordinate(ScaleW(621), ScaleH(330));
    4: FHammer2.SetCoordinate(ScaleW(422), ScaleH(456));
  end;
end;

function TBarrel.ComputeTimeForNextRaccoon: single;
begin
  case GetDifficultyLevel of
    0: Result := 1.5;
    1: Result := 1.0;
    2: Result := 0.5;
  end;
end;

function TBarrel.GetEmptySlotCount: integer;
var i: integer;
begin
  Result := 0;
  for i:=0 to High(FRaccoons) do
    if not FRaccoons[i].IsVisible then inc(Result);
end;

function TBarrel.GetIndexOfEmptySlot: integer;
var i: integer;
begin
  if GetEmptySlotCount = 1 then
    for i:=0 to High(FRaccoons) do
      if not FRaccoons[i].IsVisible then exit(i);

  repeat
    i := Random(5);
  until not FRaccoons[i].IsVisible;
  Result := i;
end;

constructor TBarrel.Create;   // LAYER_GROUND
begin
  inherited Create(texBarrel, False);
  FScene.Add(Self, LAYER_GROUND);
  CenterX := FScene.Width*0.5;
  BottomY := FScene.Height;

  //    0
  // 1  2  3
  //    4
  FRaccoons[0] := TRaccoon.Create(ScaleW(344), ScaleH(111));
  AddChild(FRaccoons[0], 1);
  FRaccoons[1] := TRaccoon.Create(ScaleW(159), ScaleH(208));
  AddChild(FRaccoons[1], 2);
  FRaccoons[2] := TRaccoon.Create(ScaleW(344), ScaleH(208));
  AddChild(FRaccoons[2], 2);
  FRaccoons[3] := TRaccoon.Create(ScaleW(532), ScaleH(208));
  AddChild(FRaccoons[3], 2);
  FRaccoons[4] := TRaccoon.Create(ScaleW(344), ScaleH(333));
  AddChild(FRaccoons[4], 3);

  FTarget := TSprite.Create(texTarget, False);
  AddChild(FTarget, 0);
  SetTargetMiddle;

  FHammer1 := TSprite.Create(texHammer1, False);
  FScene.Add(FHammer1, LAYER_ARROW);
  FHammer1.SetCoordinate(ScaleW(813), ScaleH(307));

  FHammer2 := TSprite.Create(texHammer2, False);
  FScene.Add(FHammer2, LAYER_ARROW);
  FHammer2.Visible := False;

  FStrikeCount := 0;
  SetDifficultyLevel;
  FCanStrike := True;
end;

procedure TBarrel.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // hammer Strike anim
    0: begin
      FHammer1.Visible := False;
      FHammer2.Visible := True;
      SetHammer2Coordinates;
      if FRaccoons[FTargetIndex].IsVisible then begin
        FGainCoordinate := FHammer2.GetXY + PointF(ScaleW(92), ScaleH(72));
        FRaccoons[FTargetIndex].Strike;
        inc(FStrikeCount);
        SetDifficultyLevel;
        FGameinventory.IncScore(FCurrentSuccessLevel);
        if FCurrentSuccessLevel < 8 then inc(FCurrentSuccessLevel);
      end else FCurrentSuccessLevel := 0;
      PostMessage(2, 0.1);
    end;
    2: begin
      FHammer2.Scale.Value := PointF(1.1, 0.8);
      PostMessage(5, 0.1);
    end;
    5: begin
      FHammer2.Scale.Value := PointF(1, 1);
      FHammer1.Visible := True;
      FHammer2.Visible := False;
      FCanStrike := True;
    end;
  end;
end;

procedure TBarrel.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if not FRunning then exit;

  FTimeForNextRaccoon := FTimeForNextRaccoon - aElapsedTime;
  if (FTimeForNextRaccoon <= 0) and (GetEmptySlotCount <> 0) then begin
    FTimeForNextRaccoon := ComputeTimeForNextRaccoon;
    FRaccoons[GetIndexOfEmptySlot].Appear;
  end;
end;

procedure TBarrel.StartGame;
begin
  FRunning := True;
end;

procedure TBarrel.StopGame;
var i: integer;
begin
  FRunning := False;
  for i:=0 to High(FRaccoons) do
    FRaccoons[i].Disapear;
end;

procedure TBarrel.SetTargetUp;
begin
  FTarget.SetCoordinate(ScaleW(251), ScaleH(11));
  FTargetIndex := 0;
end;

procedure TBarrel.SetTargetLeft;
begin
  FTarget.SetCoordinate(ScaleW(69), ScaleH(105));
  FTargetIndex := 1;
end;

procedure TBarrel.SetTargetMiddle;
begin
  FTarget.SetCoordinate(ScaleW(251), ScaleH(105));
  FTargetIndex := 2;
end;

procedure TBarrel.SetTargetRight;
begin
  FTarget.SetCoordinate(ScaleW(441), ScaleH(105));
  FTargetIndex := 3;
end;

procedure TBarrel.SetTargetDown;
begin
  FTarget.SetCoordinate(ScaleW(251), ScaleH(228));
  FTargetIndex := 4;
end;

procedure TBarrel.Strike;
begin
  if not FCanStrike then exit;
  FCanStrike := False;
  PostMessage(0);
  Audio.PlayThenKillSound('thuds-on-window.ogg', 0.8);
end;

{ TRaccoon }

constructor TRaccoon.Create(aCenterX, aBottomY: single);
begin
  inherited Create(FScene);
  CenterX := aCenterX;
  Y.Value := aBottomY;

  FRaccoon1 := TDeformationGrid.Create(texRaccoon1, False);
  AddChild(FRaccoon1, 0);
  FRaccoon1.SetCoordinate(-FRaccoon1.Width*0.5, -FRaccoon1.Height);
  FRaccoon1.SetGrid(10, 2);
  FDeformationSpeed := FRaccoon1.Height*10;
  FRaccoon1.DeformationSpeed.Value := PointF(0, FDeformationSpeed);
  FRaccoon1.ApplyDeformation(dtWindingDown);
  FRaccoon1.Visible := False;

  FRaccoon2 := TSprite.Create(texRaccoon2, False);
  AddChild(FRaccoon2, 0);
  FRaccoon2.SetCoordinate(-FRaccoon2.Width*0.5, -FRaccoon2.Height);
  FRaccoon2.Visible := False;

  FRaccoon3 := TSprite.Create(texRaccoon3, False);
  AddChild(FRaccoon3, 0);
  FRaccoon3.SetCoordinate(-FRaccoon3.Width*0.5, -FRaccoon3.Height);
  FRaccoon3.Visible := False;

  FTimeVisible := 2.5;
end;

procedure TRaccoon.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // RACCOON APPEAR ANIMATION
    0: begin  // raccoon1 appear
      Audio.PlayThenKillSound('RaccoonAppear.ogg', 0.8, 0.0, 1.0, Audio.FXReverbShort, 0.5);
      FRaccoon1.Visible := True;
      FRaccoon2.Visible := False;
      FRaccoon3.Visible := False;
      FRaccoon1.DeformationSpeed.y.Value := -FDeformationSpeed;
      PostMessage(5, 0.25);
      PostMessage(50, FTimeVisible);
      FEnableAnim := True;
    end;
    5: begin // raccoon2
      if not FEnableAnim then exit;
      FRaccoon1.Visible := False;
      FRaccoon2.Visible := True;
      FRaccoon3.Visible := False;
      PostMessage(10, 1.0); //0.75+Random*2);
    end;
    10: begin  // raccoon3
      if not FEnableAnim then exit;
      FRaccoon1.Visible := False;
      FRaccoon2.Visible := False;
      FRaccoon3.Visible := True;
      PostMessage(5, 0.25);
    end;

    // RACCOON DISAPEAR ANIM
    50: begin
      FEnableAnim := False;
      FRaccoon1.Visible := True;
      FRaccoon1.DeformationSpeed.y.Value := FDeformationSpeed;
      FRaccoon2.Visible := False;
      FRaccoon3.Visible := False;
      PostMessage(52, 0.3);
    end;
    52: begin
      FRaccoon1.Visible := False;
      FIsVisible := False;
      FCurrentSuccessLevel := 0;
    end;
  end;
end;

procedure TRaccoon.Appear;
begin
  if FIsVisible then exit;
  FIsVisible := True;
  PostMessage(0);
end;

procedure TRaccoon.Disapear;
begin
  if not FIsVisible then exit;
  ClearMessageList;
  PostMessage(50);
end;

procedure TRaccoon.Strike;
const semitone=1/12;
var p: single;
begin
  ClearMessageList;
  p := 1.0 + semitone*FCurrentSuccessLevel;
  Audio.PlayThenKillSound('metal-hit.ogg', 1.0, 0.0, p);
  FRaccoon1.Visible := False;
  FRaccoon1.DeformationSpeed.Value := PointF(0, FDeformationSpeed);
  FRaccoon2.Visible := False;
  FRaccoon3.Visible := False;
  FIsVisible := False;
end;

{ TScreenStrikeRaccoon }

procedure TScreenStrikeRaccoon.SetState(AValue: TGameState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  case AValue of
    gsEndOfTime: PostMessage(100);
  end;
end;

procedure TScreenStrikeRaccoon.ShowFinalScore;
var fd: TFontDescriptor;
  o: TSprite;
begin
  fd.Create('Arial', FScene.Height div 8, [fsBold], BGRA(255,200,64), BGRA(0,0,0), PPIScale(4));
  o := TSprite.Create(FScene, fd, sScore+' '+FGameinventory.Score.Count.ToString);
  FScene.Add(o, LAYER_DIALOG);
  o.CenterOnScene;
end;

procedure TScreenStrikeRaccoon.CreateObjects;
var ima: TBGRABitmap;
  path: string;
  bg: TQuad4Color;
  o: TSprite;
  fd: TFontDescriptor;
begin
  FsndMusic := Audio.AddMusic('fast-banjo-tune-with-acoustic-guitar.ogg', True);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  path := FolderSpriteStrikeRaccoon;
  texRaccoon1 := FAtlas.AddFromSVG(path+'Raccoon1.svg', ScaleW(119), -1);
  texRaccoon2 := FAtlas.AddFromSVG(path+'Raccoon2.svg', ScaleW(158), -1);
  texRaccoon3 := FAtlas.AddFromSVG(path+'Raccoon3.svg', ScaleW(137), -1);
  texTarget := FAtlas.AddFromSVG(path+'Target.svg', ScaleW(180), -1);
  texBarrel := FAtlas.AddFromSVG(path+'Barrel.svg', ScaleW(664), -1);
  texHammer1 := FAtlas.AddFromSVG(path+'Hammer1.svg', -1, ScaleH(381));
  texHammer2 := FAtlas.AddFromSVG(path+'Hammer2.svg', ScaleW(201), -1);
  texBoard := FAtlas.AddFromSVG(path+'Board.svg', FScene.Width, -1);
  fd.Create('Arial', FScene.Height div 12, [fsBold], BGRA(255,200,64), BGRA(0,0,0), PPIScale(4));
  texGain1 := FAtlas.AddString('+1', fd, NIL);
  texGain2 := FAtlas.AddString('+2', fd, NIL);

  // ui
  CreateGameFontNumber(FAtlas); // < must be first !
  LoadWatchTexture(FAtlas);
  LoadIconHammerRaccoon(FAtlas);
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

  // bg
  bg := TQuad4Color.Create(FScene);
  FScene.Add(bg, LAYER_BG3);
  bg.SetSize(FScene.Width, FScene.Height);
  bg.SetAllColorsTo(BGRA(74,40,16));

  bg := TQuad4Color.Create(FScene);
  FScene.Add(bg, LAYER_BG3);
  bg.SetSize(ScaleW(137), ScaleH(391));
  bg.SetCoordinate(ScaleW(74), ScaleH(183));
  bg.SetAllColorsTo(BGRA(104,71,28));

  bg := TQuad4Color.Create(FScene);
  FScene.Add(bg, LAYER_BG3);
  bg.SetSize(ScaleW(137), ScaleH(391));
  bg.SetCoordinate(ScaleW(795), ScaleH(183));
  bg.SetAllColorsTo(BGRA(104,71,28));

  o := TSprite.Create(texBoard, False);
  FScene.Add(o, LAYER_BG3);
  o.Tint.Value := BGRA(0,0,0,80);
  o := TSprite.Create(texBoard, False);
  FScene.Add(o, LAYER_BG3);
  o.FlipH := True;
  o.SetCoordinate(0, ScaleH(265));
  o.Tint.Value := BGRA(0,0,0,80);
  o := TSprite.Create(texBoard, False);
  FScene.Add(o, LAYER_BG3);
  o.FlipV := True;
  o.SetCoordinate(0, ScaleH(513));
  o.Tint.Value := BGRA(0,0,0,80);
  // barrel
  FBarrel := TBarrel.Create;

  // game inventory
  FGameinventory := TGameInventory.Create;
  FGameinventory.Clock.Second := 60;

  // pause panel
  FPausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  FAction1Released := True;
  FCurrentSuccessLevel := 0;

  CustomizeMousePointer(False);
  // show game instructions
  PostMessage(0);
end;

procedure TScreenStrikeRaccoon.FreeObjects;
begin
  if FsndMusic <> NIL then FsndMusic.FadeOutThenKill(2.0);
  FsndMusic := NIL;

  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
end;

procedure TScreenStrikeRaccoon.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // show instructions
    0: begin
      ShowGameInstructions(sStrikeRaccoonInstructions);
      PostMessage(10);
    end;
    10: ShowGetReadyGo(15); // Show Get Ready, Go!
    15: begin
      GameState := gsRunning;
      FsndMusic.Play(True);
      FBarrel.StartGame;
      FGameinventory.Clock.StartTime;
    end;

    // ANIM END OF TIME
    100: begin
      FGameinventory.Clock.PauseTime;
      FBarrel.StopGame;
      ShowFinalScore;
      PostMessage(105, 2.0);
    end;
    105: begin
      if FGameinventory.Score.Count > 0 then begin
        u_screen_sam.FPlayerPlaySamsGame := True;
        u_screen_sam.FPlayerSamsGameScore := FGameinventory.Score.Count;
      end;
      FScene.RunScreen(ScreenSamHome);
    end;
  end;
end;

procedure TScreenStrikeRaccoon.Update(const aElapsedTime: single);
var flagPlayerIdle: boolean;
begin
  inherited Update(aElapsedTime);
  case GameState of
    gsRunning: begin
      flagPlayerIdle := True;

      // shoot
      if Input.Action1Pressed then begin
        if FAction1Released then begin
          FBarrel.Strike;
          FAction1Released := False;
        end;
      end else FAction1Released := True;

      if Input.RightPressed and flagPlayerIdle then begin
        FBarrel.SetTargetRight;
        flagPlayerIdle := False;
      end;

      if Input.LeftPressed and flagPlayerIdle then begin
        FBarrel.SetTargetLeft;
        flagPlayerIdle := False;
      end;

      if Input.UpPressed and flagPlayerIdle then begin
        FBarrel.SetTargetUp;
        flagPlayerIdle := False;
      end;

      if Input.DownPressed and flagPlayerIdle then begin
        FBarrel.SetTargetDown;
        flagPlayerIdle := False;
      end;

      if flagPlayerIdle then begin
        FBarrel.SetTargetMiddle;
      end;

      // check time
      if FGameinventory.Clock.Second = 0 then
        GameState := gsEndOfTime;

      // check if player pause the game
      if Input.PausePressed then
        FPausePanel.ShowModal;
    end;
  end;

end;

end.

