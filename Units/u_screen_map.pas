unit u_screen_map;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene, ALSound,
  u_common, u_common_ui, u_gamescreentemplate, u_utils,
  u_proceduralcloud;

{ WHEN ADDING A NEW GAME: do the following:
    - update procedure TScreenMap.ShowLastGameStepPanel;
    - update function TScreenMap.CheckIfASubGameWasCompleted
    - add the new TImageButton in procedure TScreenMap.CreateObjects;
    - update procedure TScreenMap.UnableMouseInteractionOnMapObjects(aValue: boolean);
    - update procedure TScreenMap.SetLRIconPositionOnGameToPlay
    - add the new cheat codes (if any) in procedure TScreenMap.CreateObjects and handle them in TScreenMap.Update()
    - update procedure ProcessButtonMouseEnter and Leave
    }

type

// add new game here
TGameOnMap = (gomUnknow, gomPineForest, gomZipLine, gomVolcano,
              gomPlainOfSleepingMoon, gomMermaidPort, gomSnakeFissure, gomWolfCastle);

{ TScreenMap }

TScreenMap = class(TGameScreenTemplate)
private
  FsndSeaWave: TALSSound;
  FIconLR: TSprite;
  BWorkShop, BSamHome, BPineForest, BMountainPeaks, BVolcano, BPlainMoon, BMermaidPort,
  BSnakeFissure, BCastle: TImageButton;
  FLabelPlaceOnTheMap: TUILabel;
  FPlaceHint: TUITextArea;
  FFontPlaceName: TTexturedFont;
  FTargetButtonForFireworkAnim: TImageButton;
  BMainMenu: TUIButton;
  FFireworkCount: integer;
  FInMapPanel: TInMapPanel;
  FCheatCodeManager: TCheatCodeManager;
  FCloudsRenderer: TOGLCCloudsRenderer;

  function CreateImageButton(tex: PTexture): TImageButton;
  function CreateButton(const aCaption: string; tex: PTexture): TUIButton;
  procedure ProcessButtonMouseEnter(Sender: TSimpleSurfaceWithEffect);
  procedure ProcessButtonMouseLeave(Sender: TSimpleSurfaceWithEffect);
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
  procedure ShowLastGameStepPanel;
  function CheckIfASubGameWasCompleted: boolean;
  procedure SetLRIconPositionOnGameToPlay;
public
  procedure DefineSubTextures(aAtlas: TAtlas); override;
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  // enable disable button on the map
  procedure UnableMouseInteractionOnMapObjects(aValue: boolean);
end;

var ScreenMap: TScreenMap;
    LastGameClicked: TGameOnMap=gomUnknow;

implementation
uses u_app, u_resourcestring, u_screen_title, u_screen_gameforest,
  u_screen_workshop, u_mousepointer, u_screen_gamemountainpeaks, u_ui_panels,
  u_screen_gamevolcanoentrance, u_audio, u_screen_gamevolcanoinner,
  u_screen_gamevolcanodino, screen_gameplainmoon, u_screen_gamemermaidsport,
  u_screen_sam, u_sprite_def2, u_screen_gamemermaidboss,
  u_screen_gamesnakefissure, u_screen_gamesnakefissureintro,
  u_screen_gamecastle, BGRAPath, Forms, Math;

const
  CLOUDS_PRESET =
          'Color|r,255,g,255,b,255,a,255|Fragmentation|2.6000|Transformation|0.0900|Relief|'+
          'false|Density|0.0100|TranslationSpeed|-0.0050|ThresholdTop|0.0601|ThresholdBotto'+
          'm|0.2701|ThresholdRight|0.0501|ThresholdLeft|0.0751';
type

{ TPanelChooseGameStep }

TPanelChooseGameStep = class(TCenteredGameUIPanel)
private class var FHintIndex: integer;
private
  FLine: TShapeOutline;
  FSteps: array of TImageButton;
  FImage: TUIImage;
  BStart, BBack, BChallenge: TUIButton;
  FTargetScreen: TScreenTemplate;
  FMessageToSend: TUserMessageValue;
  FGameDescriptor: TGameDescriptor;
  FLRIcon: TSprite;
  FSelectedStepIndex: integer;
  FHint: TUITextArea;
  FKeyboardToButton: TButtonsClickableByKeyboard;
  procedure SetHint(AValue: string);
  procedure SetLRIconPosition;
  procedure ShowGameSteps(AValue: boolean);
protected
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect); override;
public
  // if aHint is empty, a default hint is displayed
  constructor Create(aTexIcon, aLRIcon: PTexture;
                     aGame: TGameDescriptor; aMessageToRunScreen: TUserMessageValue;
                     const aHint: string);
  procedure RemoveStartButton;
  property Hint: string write SetHint;
end;

var FFontText: TTexturedFont;
  texLRIcon, texMapStep, texMapStepChecked,
  texMapCastleFW, texMapCastleOutline,
  texMap1FW, texMap1Outline, texLRHome, texSamHome, texPineForest,
  texZipLinePeaks, texZipLinePeaksCableToVolcano,
  texVolcanoMountain, texPlainOfSleepingMoon, texFactory, texSnakeFissure,
  texCastle: PTexture;
  FPanelChooseGameStep: TPanelChooseGameStep=NIL;
  FAtlas: TOGLCTextureAtlas;

{ TPanelChooseGameStep }

procedure TPanelChooseGameStep.SetLRIconPosition;
var i: integer;
begin
  i := EnsureRange(FSelectedStepIndex - 1, Low(FSteps), High(FSteps));
  FLRIcon.CenterX := FSteps[i].CenterX;
  FLRIcon.BottomY := FSteps[i].CenterY;
end;

procedure TPanelChooseGameStep.ShowGameSteps(AValue: boolean);
var i: integer;
begin
  FLine.Visible := AValue and (FGameDescriptor.StepCount > 1);
  for i:=0 to High(FSteps) do
    FSteps[i].Visible := AValue;
  if AValue then begin
    FLRIcon.Blink(-1, 0.4, 0.4);
  end else begin
    FLRIcon.StopBlink;
    FLRIcon.Visible := False;
  end;
end;

procedure TPanelChooseGameStep.SetHint(AValue: string);
begin
  FHint.Text.Caption := AValue;
end;

procedure TPanelChooseGameStep.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
var o: TImageButton;
begin
  if Sender = BStart then begin
    Audio.PlayUIClickStart;
    MouseInteractionEnabled := False;
    FGameDescriptor.StepPlayed := FSelectedStepIndex;
    FTargetScreen.PostMessage(FMessageToSend, 0);
  end else
  if Sender = BBack then begin
    Audio.PlayUIClick;
    Hide(True);
    FPanelChooseGameStep := NIL;
    ScreenMap.UnableMouseInteractionOnMapObjects(True);
    ChallengeMode := False;
  end else
  if Sender is TImageButton then begin
    Audio.PlayUIClick;
    o := TImageButton(Sender);
    FSelectedStepIndex := o.Tag1;
    SetLRIconPosition;
  end else
  if Sender = BChallenge then begin
    Audio.PlayUIClick;
    ChallengeMode := not ChallengeMode;
    if not ChallengeMode then begin
      BChallenge.Caption := sGameMode;
      FHint.Text.Caption := FGameDescriptor.HelpText;
      ShowGameSteps(True);
    end else begin
      BChallenge.Caption := sChallengeMode;
      FHint.Text.Caption := FGameDescriptor.ChallengeHelpText;
      ShowGameSteps(False);
    end;

  end;
end;

constructor TPanelChooseGameStep.Create(aTexIcon, aLRIcon: PTexture;
  aGame: TGameDescriptor; aMessageToRunScreen: TUserMessageValue;
  const aHint: string);
var i, w: integer;
  A: TUIButtonArray;
begin
  inherited Create(Round(FScene.Width*0.6), Round(FScene.Height*0.3), FFontText);
  CenterOnScene;

  FGameDescriptor := aGame;
  FTargetScreen := ScreenMap;
  FMessageToSend := aMessageToRunScreen;

  // icon
  w := Round(Height*0.7);
  FImage := TUIImage.Create(FScene, aTexIcon, w, w);
  AddChild(FImage, 0);
  FImage.SetCoordinate(0, 0);

  // line
  FLine := TShapeOutline.Create(FScene);
  AddChild(FLine, 1);
  FLine.SetShapeLine(PointF(Width*0.1, Height*0.60), PointF(Width*0.9, Height*0.60));
  FLine.LineWidth := ScaleH(4);
  FLine.LineColor := BGRA(88,65,45);
  FLine.Visible := FGameDescriptor.StepCount > 1;

  // steps
  FSteps := NIL;
  SetLength(FSteps, aGame.StepCount);
  for i:=0 to High(FSteps) do begin
    if (i+1) < aGame.CurrentStep then FSteps[i] := TImageButton.Create(texMapStepChecked)
      else FSteps[i] := TImageButton.Create(texMapStep);    //texMapStep
    AddChild(FSteps[i], 2);
    if i+1 > aGame.CurrentStep then FSteps[i].MouseInteractionEnabled := False
      else FSteps[i].OnClick := @ProcessButtonClick;
    FSteps[i].CenterX := FLine.X.Value + i*FLine.Width/(aGame.StepCount-1);
    FSteps[i].CenterY := FLine.Y.Value;
    FSteps[i].Tag1 := i + 1;
  end;
  FSelectedStepIndex := Min(aGame.StepCount, aGame.CurrentStep);

  // LR icon
  FLRIcon := TSprite.Create(aLRIcon, False);
  AddChild(FLRIcon, 3);
  FLRIcon.Blink(-1, 0.4, 0.4);
  SetLRIconPosition;

  // buttons
  BStart := TUIButton.Create(FScene, sStart, FFont, NIL);
  AddChild(BStart, 0);
  FormatButtonMenu(BStart);
  BStart.AnchorPosToParent(haLeft, haCenter, ScaleW(32), vaBottom, vaBottom, -PPIScale(10));

  BBack := TUIButton.Create(FScene, sBack, FFont, NIL);
  AddChild(BBack, 0);
  FormatButtonMenu(BBack);
  BBack.AnchorPosToParent(haRight, haCenter, -ScaleW(32), vaBottom, vaBottom, -PPIScale(10));


  // hint
  FHint := TUITextArea.Create(FScene);
  AddChild(FHint, 0);
  FHint.BodyShape.SetShapeRectangle(Round(Width/2), Round(Height/2), 0);
  FHint.BodyShape.Fill.Visible := False;
  FHint.BodyShape.Border.Visible := False;
  if aHint = '' then begin
    FHint.Text.Caption := GameHints[FHintIndex];
    inc(FHintIndex);
    if FHintIndex > High(GameHints) then FHintIndex := 0;
  end else FHint.Text.Caption := aHint;
  FHint.Text.Align := taTopCenter;
  FHint.Text.TexturedFont := FFontText;
  FHint.SetCoordinate(Width/2-PPIScale(10), PPIScale(10));

  // button challenge
  BChallenge := TUIButton.Create(FScene, sGameMode, FFont, NIL);
  AddChild(BChallenge, 0);
  FormatButtonMenu(BChallenge);
  BChallenge.AnchorPosToSurface(FHint, haRight, haLeft, 0, vaTop, vaTop, 0);

  // keyboard to button
  A := NIL;
  for i:=0 to High(FSteps) do
    if FSteps[i].MouseInteractionEnabled then begin
      SetLength(A, Length(A)+1);
      A[High(A)] := TUIButton(FSteps[i]);
    end;
  FKeyboardToButton := TButtonsClickableByKeyboard.Create(Self, FAtlas);
  FKeyboardToButton.AddLineOfButtons([BChallenge]);
  FKeyboardToButton.AddLineOfButtons(A);
  FKeyboardToButton.AddLineOfButtons([BBack, BStart]);
  FKeyboardToButton.Select(BStart);
end;

procedure TPanelChooseGameStep.RemoveStartButton;
begin
  BStart.Kill;
  //FKeyboardToButton.RemoveButton(BStart);
  FKeyboardToButton.RemoveAllButtons;
  FKeyboardToButton.AddLineOfButtons([BBack]);
  FKeyboardToButton.Select(BBack);
end;

{ TScreenMap }

function TScreenMap.CreateImageButton(tex: PTexture): TImageButton;
begin
  Result := TImageButton.Create(tex);
  FScene.Add(Result, LAYER_GROUND);
  Result.OnClick := @ProcessButtonClick;
  Result.OnMouseEnter := @ProcessButtonMouseEnter;
  Result.OnMouseLeave := @ProcessButtonMouseLeave;
end;

function TScreenMap.CreateButton(const aCaption: string; tex: PTexture): TUIButton;
begin
  Result := TUIButton.Create(FScene, aCaption, FFontText, tex);
  FScene.Add(Result, LAYER_GAMEUI);
  Result.OnClick := @ProcessButtonClick;
  Result.AutoSize := False;
  Result.BodyShape.SetShapeRoundRect(Round(FScene.Width*0.25), FFontText.Font.FontHeight*2, PPIScale(8), PPIScale(8), PPIScale(2));
  Result.BodyShape.Fill.Color := BGRA(255,128,64);
  Result.BodyShape.Border.Color := BGRA(128,64,32);
end;

procedure TScreenMap.ProcessButtonMouseEnter(Sender: TSimpleSurfaceWithEffect);
var old, s, hint: string;
begin
  old := FLabelPlaceOnTheMap.Caption;
  s := '';
  hint := '';
  if Sender = BWorkShop then begin
    s := sWorkShop;
    hint := sWorkShopHint;
  end else if Sender = BSamHome then begin
    s := sSamsHut;
    hint := sSamsHutHint;
  end else if Sender = BPineForest then begin
    s := sPinForest;
    hint := sPinForestHint;
  end else if Sender = BMountainPeaks then begin
    s := sMountainPeaks;
    hint := sMountainPeaksHint;
  end else if Sender = BVolcano then begin
    s := sVolcano;
    hint := sVolcanoHint;
  end else if Sender = BPlainMoon then begin
    s := sPlainOfSleepingMoon;
    hint := sPlainOfSleepingMoonHint;
  end else if Sender = BMermaidPort then begin
    s := sMermaidsPort;
    hint := sMermaidsPortHint;
  end else if Sender = BSnakeFissure then begin
    s := sSnakeFissure;
    hint := sSnakeFissureHint;
  end else if Sender = BCastle then begin
    s := sWolfCastle;
    hint := sWolfCastleHint;
  end;
  FLabelPlaceOnTheMap.Caption := s;
  FLabelPlaceOnTheMap.CenterX := ScaleW(687);
  FLabelPlaceOnTheMap.ScaledBottomY := FScene.Height-ScaleH(50);
  FPlaceHint.Text.Caption := hint;
  if old <> s then begin
    FLabelPlaceOnTheMap.Opacity.Value := 0;
    FPlaceHint.Opacity.Value := 0;
  end;
  FLabelPlaceOnTheMap.Opacity.ChangeTo(180, 0.75);
  FPlaceHint.Opacity.ChangeTo(180, 0.75);
end;

procedure TScreenMap.ProcessButtonMouseLeave(Sender: TSimpleSurfaceWithEffect);
begin
  FLabelPlaceOnTheMap.Opacity.ChangeTo(0, 0.75);
  FPlaceHint.Opacity.ChangeTo(0, 0.75);
end;

procedure TScreenMap.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
var pineForestDone, mountainPicDone, volcanoDone: boolean;
  s: string;
  procedure _ShowPanelChooseGameStep;
  begin
    if s <> '' then begin
      FPanelChooseGameStep.RemoveStartButton;
      FPanelChooseGameStep.Hint := s;
    end;
    FPanelChooseGameStep.Show;
  end;

begin
  Audio.PlayUIClick;
  s := '';

  pineForestDone := PlayerInfo.Forest.IsTerminated;
  mountainPicDone := PlayerInfo.MountainPeak.IsTerminated;
  volcanoDone := PlayerInfo.Volcano.IsTerminated;


  if Sender = BMainMenu then begin
    UnableMouseInteractionOnMapObjects(False);
    FScene.RunScreen(ScreenTitle);
    LastGameClicked := gomUnknow;
    exit;
  end else
  if Sender = BWorkShop then begin
    UnableMouseInteractionOnMapObjects(False);
    FScene.RunScreen(ScreenWorkShop);
    LastGameClicked := gomUnknow;
    exit;
  end else
  if Sender = BSamHome then begin
    UnableMouseInteractionOnMapObjects(False);
    FScene.RunScreen(ScreenSamHome);
    LastGameClicked := gomUnknow;
    exit;
  end;

  if Sender = BPineForest then begin
    UnableMouseInteractionOnMapObjects(False);
    FPanelChooseGameStep := TPanelChooseGameStep.Create(texPineForest, texLRIcon, PlayerInfo.Forest, 100, '');
    _ShowPanelChooseGameStep;
    LastGameClicked := gomPineForest;
    exit;
  end;

  if s = '' then
    if not pineForestDone then s := sFirstCompleteForest
      else if not PlayerInfo.MountainPeak.ZipLine.Owned then s := sBuyZipLineFirst;

  if Sender = BMountainPeaks then begin
    UnableMouseInteractionOnMapObjects(False);
    FPanelChooseGameStep := TPanelChooseGameStep.Create(texZipLinePeaks, texLRIcon, PlayerInfo.MountainPeak, 110, ' ');
    _ShowPanelChooseGameStep;
    LastGameClicked := gomZipLine;
    exit;
  end;

  if s = '' then
    if not mountainPicDone then s := sFirstCompleteMountainPeaks;

  if Sender = BVolcano then begin
    UnableMouseInteractionOnMapObjects(False);
    // check which screen to start
    if (s = '') and not PlayerInfo.Volcano.VolcanoEntranceIsDone then begin
      FScene.RunScreen(ScreenGameVolcanoEntrance);
      LastGameClicked := gomUnknow;
    end else begin
      FPanelChooseGameStep := TPanelChooseGameStep.Create(texVolcanoMountain, texLRIcon, PlayerInfo.Volcano, 120, ' ');
      _ShowPanelChooseGameStep;
      LastGameClicked := gomVolcano;
      exit;
    end;
  end;

  if s = '' then
    if not volcanoDone then s := sFirstCompleteVolcano;

  if Sender = BPlainMoon then begin
    UnableMouseInteractionOnMapObjects(False);
    FPanelChooseGameStep := TPanelChooseGameStep.Create(texPlainOfSleepingMoon, texLRIcon, PlayerInfo.PlainMoon, 130, ' ');
    _ShowPanelChooseGameStep;
    LastGameClicked := gomPlainOfSleepingMoon;
    exit;
  end;

  if s = '' then
    if not PlayerInfo.PlainMoon.IsTerminated then s := sFirstCompletePlainMoon;

  if Sender = BMermaidPort then begin
    UnableMouseInteractionOnMapObjects(False);
    FPanelChooseGameStep := TPanelChooseGameStep.Create(texFactory, texLRIcon, PlayerInfo.MermaidsPort, 140, ' ');
    _ShowPanelChooseGameStep;
    LastGameClicked := gomMermaidPort;
    exit;
  end;

  if s = '' then
    if not PlayerInfo.MermaidsPort.IsTerminated then s := sFirstCompleteMermaidsPort;

  if Sender = BSnakeFissure then begin
    UnableMouseInteractionOnMapObjects(False);
    FPanelChooseGameStep := TPanelChooseGameStep.Create(texSnakeFissure, texLRIcon, PlayerInfo.SnakeFissure, 150, ' ');
    _ShowPanelChooseGameStep;
    LastGameClicked := gomSnakeFissure;
    exit;
  end;

  if s = '' then
    if not PlayerInfo.SnakeFissure.IsTerminated then s := sFirstCompleteSnakeFissure;

  if Sender = BCastle then begin
    UnableMouseInteractionOnMapObjects(False);
    FPanelChooseGameStep := TPanelChooseGameStep.Create(texCastle, texLRIcon, PlayerInfo.WolfCastle, 160, sLetsGo);
    _ShowPanelChooseGameStep;
    LastGameClicked := gomWolfCastle;
    exit;
  end;
end;

procedure TScreenMap.ShowLastGameStepPanel;
begin
  case LastGameClicked of
    gomPineForest: ProcessButtonClick(BPineForest);
    gomZipLine: ProcessButtonClick(BMountainPeaks);
    gomVolcano: ProcessButtonClick(BVolcano);
    gomPlainOfSleepingMoon: ProcessButtonClick(BPlainMoon);
    gomMermaidport: ProcessButtonClick(BMermaidPort);
    gomSnakeFissure: ProcessButtonClick(BSnakeFissure);
    gomWolfCastle: ProcessButtonClick(BCastle);
  end;
end;

function TScreenMap.CheckIfASubGameWasCompleted: boolean;
begin
  FTargetButtonForFireworkAnim := NIL;
  if PlayerInfo.Forest.FirstTimeTerminated then FTargetButtonForFireworkAnim := BPineForest
  else
  if PlayerInfo.MountainPeak.FirstTimeTerminated then FTargetButtonForFireworkAnim := BMountainPeaks
  else
  if PlayerInfo.Volcano.FirstTimeTerminated then FTargetButtonForFireworkAnim := BVolcano
  else
  if PlayerInfo.PlainMoon.FirstTimeTerminated then FTargetButtonForFireworkAnim := BPlainMoon
  else
  if PlayerInfo.MermaidsPort.FirstTimeTerminated then FTargetButtonForFireworkAnim := BMermaidport
  else
  if PlayerInfo.SnakeFissure.FirstTimeTerminated then FTargetButtonForFireworkAnim := BSnakeFissure
  else
  if PlayerInfo.WolfCastle.FirstTimeTerminated then FTargetButtonForFireworkAnim := BCastle;

  Result := FTargetButtonForFireworkAnim <> NIL;
  if Result then begin
    PostMessage(0);
    UnableMouseInteractionOnMapObjects(False);
  end;
end;

procedure TScreenMap.SetLRIconPositionOnGameToPlay;
begin
  if PlayerInfo.SnakeFissure.IsTerminated then FIconLR.SetCenterCoordinate(BCastle.CenterX, BCastle.CenterY)
  else
  if PlayerInfo.MermaidsPort.IsTerminated then FIconLR.SetCenterCoordinate(BSnakeFissure.CenterX, BSnakeFissure.CenterY)
  else
  if PlayerInfo.PlainMoon.IsTerminated then FIconLR.SetCenterCoordinate(BMermaidPort.CenterX, BMermaidPort.CenterY)
  else
  if PlayerInfo.Volcano.IsTerminated then FIconLR.SetCenterCoordinate(BPlainMoon.CenterX, BPlainMoon.CenterY)
  else
  if PlayerInfo.MountainPeak.IsTerminated then FIconLR.SetCenterCoordinate(BVolcano.CenterX, BVolcano.CenterY)
  else
  if PlayerInfo.Forest.IsTerminated then FIconLR.SetCenterCoordinate(BMountainPeaks.CenterX, BMountainPeaks.CenterY)
  else FIconLR.SetCenterCoordinate(BPineForest.CenterX, BPineForest.CenterY);
end;

procedure TScreenMap.DefineSubTextures(aAtlas: TAtlas);
var fd: TFontDescriptor;
begin
  AdditionnalScale := 1.0;

  texLRIcon := aAtlas.AddFromSVG(SpriteBGFolder+'LR.svg', ScaleW(33), -1);
  texMapStep := aAtlas.AddFromSVG(SpriteMapFolder+'MapStep.svg', ScaleW(21), -1);
  texMapStepChecked := aAtlas.AddFromSVG(SpriteMapFolder+'MapStepChecked.svg', ScaleW(34), -1);
  AddBlueArrowToAtlas(aAtlas);

  // games map
  texMap1FW := aAtlas.AddFromSVG(SpriteMapFolder+'Map1FW.svg', ScaleW(651), -1);
  texMap1Outline := aAtlas.AddFromSVG(SpriteMapFolder+'Map1Outline.svg', ScaleW(651), -1);
  texLRHome := aAtlas.AddFromSVG(SpriteBGFolder+'LRHome.svg', ScaleW(87), -1);
  AddSphereParticleToAtlas(aAtlas);
  texSamHome := aAtlas.AddFromSVG(FolderSpriteSam+'SamHome.svg', ScaleW(83), -1);
  texPineForest := aAtlas.AddFromSVG(SpriteMapFolder+'PineForest.svg', ScaleW(167), -1);
  texVolcanoMountain := aAtlas.AddFromSVG(SpriteMapFolder+'VolcanoMountain.svg', ScaleW(124), -1);
  texZipLinePeaks := aAtlas.AddFromSVG(SpriteMapFolder+'ZipLinePeaks.svg', ScaleW(100), -1);
  texZipLinePeaksCableToVolcano := aAtlas.AddFromSVG(SpriteMapFolder+'ZipLinePeaksCableToVolcano.svg', ScaleW(137), -1);
  texPlainOfSleepingMoon := aAtlas.AddFromSVG(SpriteMapFolder+'MapPlainOfSleepingMoon.svg', ScaleW(211), -1);
  texFactory := aAtlas.AddFromSVG(SpriteMapFolder+'MapFactory.svg', ScaleW(159), -1);
  texSnakeFissure := aAtlas.AddFromSVG(SpriteMapFolder+'SnakeFissure.svg', ScaleW(107), -1);

  // castle island
  texMapCastleFW := aAtlas.AddFromSVG(SpriteMapFolder+'MapCastleFW.svg', ScaleW(170), -1);
  texMapCastleOutline := aAtlas.AddFromSVG(SpriteMapFolder+'MapCastleOutline.svg', ScaleW(170), -1);
  texCastle := aAtlas.AddFromSVG(SpriteBGFolder+'WolfCastle.svg', ScaleW(121), -1);

  AdditionnalScale := 0.25;
  TSeagullBase.LoadTexture(aAtlas);
 { texSeagullBody := aAtlas.AddFromSVG(SpriteMapFolder+'SeagullBody.svg', ScaleW(59), -1);
  texSeagullWing := aAtlas.AddFromSVG(SpriteMapFolder+'SeagullWing.svg', ScaleW(23), -1);  }
  AdditionnalScale := 1.0;

  FFontText := CreateGameFontText(aAtlas);
  fd.Create('Arial', Round(FScene.Height/17.5), [], BGRA(0,0,0));
  FFontPlaceName := aAtlas.AddTexturedFont(fd, FSaveGame.LanguageCharSet);

  CreateGameFontNumber(aAtlas);
  LoadCoinTexture(aAtlas);
  LoadCristalGrayTexture(aAtlas);

  LoadMousePointerTexture(aAtlas);
end;

procedure TScreenMap.CreateObjects;
var o, o1: TSprite;
  pe: TParticleEmitter;
  sea: TQuad4Color;
  s: String;
  d, waveCount, i: Integer;
  clouds: TOGLCSpriteClouds;
begin
//  LastGameClicked := gomUnknow;
  FPanelChooseGameStep := NIL;

  FFireworkCount := 0;
  FsndSeaWave := Audio.AddSound('sea-and-seagull.ogg');
  FsndSeaWave.Loop := True;
  FsndSeaWave.FadeIn(0.8, 3.0);

  CheckAtlas(FAtlas, 'map.atlas');

  // clouds
  FCloudsRenderer := TOGLCCloudsRenderer.Create(FScene, True);
  clouds := TOGLCSpriteClouds.Create(FScene, FCloudsRenderer);
  FScene.Add(clouds, LAYER_WEATHER);
  clouds.SetSize(FScene.Width, Round(FScene.Height*0.8));
  clouds.SetCoordinate(0, 0);
  clouds.LoadParamsFromString(CLOUDS_PRESET);
 // clouds.Opacity.Value := 150;
  //clouds.BlendMode := FX_BLEND_ADD;

  // sea
  sea := TQuad4Color.Create(FScene);
  sea.SetSize(FScene.Width, FScene.Height);
  sea.SetAllColorsTo(BGRA(4,83,177));
  FScene.Add(sea, LAYER_BG3);

  // big island
  o := TSprite.Create(texMap1FW, False);
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(36), ScaleH(31));

  o1 := TSprite.Create(texMap1FW, False);   // blue BG
  o.AddChild(o1, -3);
  o1.CenterOnParent;
  o1.Opacity.Value := 100;
  o1.TintMode := tmReplaceColor;
  o1.Tint.Value := BGRA(107,161,209);
  o1.Scale.Value := PointF(1.05, 1.04);

  // creates wave around the island
  s := '';
  d := 5;
  waveCount := 2;
  for i:=1 to waveCount do begin
    o1 := TSprite.Create(texMap1Outline, False);         //texMap1Outline
    o.AddChild(o1, -2);
    o1.CenterOnParent;
    if i = 1 then s := ''
      else s := 'Wait '+ FormatFloatWithDot('0.000', d/waveCount*(i-1));
    o1.AddAndPlayScenario(s+#10+
                          'Label HERE'#10+
                          'Scale 1.04'#10+
                          'Opacity 0'#10+
                          'ScaleChange 1.0 '+FormatFloatWithDot('0.000', d)+' idcSinusoid'#10+
                          'OpacityChange 100 '+FormatFloatWithDot('0.000', d)+' idcStartFastEndSlow'#10+
                          'Wait '+FormatFloatWithDot('0.000', d)+#10+
                          'Goto HERE');
  end;


  // castle island
  o := TSprite.Create(texMapCastleFW, False);
  FScene.Add(o, LAYER_BG2);
  o.SetCoordinate(ScaleW(827), ScaleH(168));

  o1 := TSprite.Create(texMapCastleFW, False);
  o.AddChild(o1, -3);
  o1.CenterOnParent;
  o1.Opacity.Value := 100;
  o1.TintMode := tmReplaceColor;
  o1.Tint.Value := BGRA(107,161,209);
  o1.Scale.Value := PointF(1.1, 1.1);

  // creates wave around the castle island
  s := '';
  d := 5;
  waveCount := 2;
  for i:=1 to waveCount do begin
    o1 := TSprite.Create(texMapCastleOutline, False);
    o.AddChild(o1, -2);
    o1.CenterOnParent;
    if i = 1 then s := ''
      else s := 'Wait '+ FormatFloatWithDot('0.000', d/waveCount*(i-1));
    o1.AddAndPlayScenario(s+#10+
                          'Label HERE'#10+
                          'Scale 1.1'#10+
                          'Opacity 0'#10+
                          'ScaleChange 1.0 '+FormatFloatWithDot('0.000', d)+' idcSinusoid'#10+
                          'OpacityChange 100 '+FormatFloatWithDot('0.000', d)+' idcStartFastEndSlow'#10+
                          'Wait '+FormatFloatWithDot('0.000', d)+#10+
                          'Goto HERE');
  end;

  // seagulls
  for i:=0 to 7 do
    TSeagullFlyInRectangle.Create(LAYER_FXANIM);

  // button workshop
  BWorkShop := CreateImageButton(texLRHome);
  BWorkShop.SetCoordinate(ScaleW(121), ScaleH(488));
  pe := TParticleEmitter.Create(FScene);
  BWorkShop.AddChild(pe, 1);
  pe.LoadFromFile(ParticleFolder+'LRHomeSmoke.par', FAtlas);
  pe.SetCoordinate(BWorkShop.Width*0.25, BWorkShop.Height*0.001);
  pe.SetEmitterTypePoint;

  // button sam home
  BSamHome := CreateImageButton(texSamHome);
  BSamHome.SetCoordinate(ScaleW(110), ScaleH(235));

  // button pine forest
  BPineForest := CreateImageButton(texPineForest);
  BPineForest.SetCoordinate(ScaleW(45), ScaleH(47));

  // button mountain peaks
  BMountainPeaks := CreateImageButton(texZipLinePeaks);
  BMountainPeaks.SetCoordinate(ScaleW(233), ScaleH(102));

  // button volcano mountain
  BVolcano := CreateImageButton(texVolcanoMountain);
  BVolcano.SetCoordinate(ScaleW(352), ScaleH(269));
  pe := TParticleEmitter.Create(FScene);
  BVolcano.AddChild(pe, 1);
  pe.LoadFromFile(ParticleFolder+'VolcanoMountainSmoke.par', FAtlas);
  pe.SetCoordinate(BVolcano.Width*0.3518, BVolcano.Height*0.0729);
  pe.SetEmitterTypeLine(PointF(BVolcano.Width*0.5279, BVolcano.Height*0.0729));
  pe.FParticleParam.Size := 0.22;

  // cable between Mountain Peaks and Volcano
  o := TSprite.Create(texZipLinePeaksCableToVolcano, False);
  FScene.Add(o, LAYER_GROUND);
  o.SetCoordinate(ScaleW(272), ScaleH(262));

  // button plain of the sleeping moon
  BPlainMoon := CreateImageButton(texPlainOfSleepingMoon);
  BPlainMoon.SetCoordinate(ScaleW(291), ScaleH(439));

  // button factory
  BMermaidPort := CreateImageButton(texFactory);
  BMermaidPort.SetCoordinate(ScaleW(516), ScaleH(184));

  // button snake fissure
  BSnakeFissure := CreateImageButton(texSnakeFissure);
  BSnakeFissure.SetCoordinate(ScaleW(714), ScaleH(234));
  with TQuad4Color.Create(FScene) do begin
    SetChildOf(BSnakeFissure, 1);
    SetSize(BSnakeFissure.Width, BSnakeFissure.Height);
    SetAllColorsTo(BGRA(4,83,177));
    Opacity.Value := 100;
  end;

  // Wolf castle
  BCastle := CreateImageButton(texCastle);
  BCastle.SetCoordinate(ScaleW(859), ScaleH(186));

  // icon LR
  FIconLR := TSprite.Create(texLRIcon, False);
  FScene.Add(FIconLR, LAYER_PLAYER);
  FIconLR.CenterX := BWorkShop.CenterX;
  FIconLR.BottomY := BWorkShop.BottomY;
  FIconLR.Blink(-1, 0.3, 0.3);
  SetLRIconPositionOnGameToPlay;

  // buttons
  BMainMenu := CreateButton(sBack, NIL);
  BMainMenu.X.Value := ScaleW(10);
  BMainMenu.BottomY := FScene.Height-ScaleH(10);

  // label place on map
  FLabelPlaceOnTheMap := TUILabel.Create(FScene, '', FFontPlaceName);
  FScene.Add(FLabelPlaceOnTheMap, LAYER_GAMEUI);
  FLabelPlaceOnTheMap.Opacity.Value := 0;
  //FLabelPlaceOnTheMap.Scale.Value := PointF(2,2);
  FLabelPlaceOnTheMap.Tint.Value := BGRA(200,200,200);

  FPlaceHint:= TUITextArea.Create(FScene);
  FPlaceHint.BodyShape.SetShapeRectangle(Round(FScene.Width*0.6), Round(FScene.Height*0.1), 0);
  FPlaceHint.BodyShape.Fill.Visible := False;
  FScene.Add(FPlaceHint, LAYER_GAMEUI);
  FPlaceHint.Text.Caption := '';
  FPlaceHint.Text.Align := taTopCenter;
  FPlaceHint.Text.TexturedFont := FFontText;
  FPlaceHint.Opacity.Value := 0;
  FPlaceHint.Text.Tint.Value := BGRA(200,200,200);
  FPlaceHint.AnchorPosToSurface(FLabelPlaceOnTheMap, haCenter, haCenter, 0, vaTop, vaBottom, 0);// ScaleH(10));

  // player items panel
  FInMapPanel := TInMapPanel.Create;

  // check if a sub-game was completed, if yes an animation with firework start
  // else the last game panel is opened
  if not CheckIfASubGameWasCompleted then
    if LastGameClicked <> gomUnknow then ShowLastGameStepPanel;

  // cheat code list
  FCheatCodeManager.InitDefault;
  if not PlayerInfo.Forest.IsTerminated then
    FCheatCodeManager.AddCheatCodeToList(PinForestCheatCode);
  if not PlayerInfo.MountainPeak.IsTerminated then
    FCheatCodeManager.AddCheatCodeToList(MountainPeaksCheatCode);

  CustomizeMousePointer(True);
end;

procedure TScreenMap.FreeObjects;
begin
  FCloudsRenderer.Free;
  FCloudsRenderer := NIL;
  FsndSeaWave.FadeOutThenKill(3.0);
  FsndSeaWave := NIL;
  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
end;

procedure TScreenMap.ProcessMessage(UserValue: TUserMessageValue);
var xx, yy: single;
  procedure GetButtonCoor;
  begin
    xx := FTargetButtonForFireworkAnim.CenterX;
    yy := FTargetButtonForFireworkAnim.CenterY;
  end;
  procedure CreateFirework(const aFilename: string);
  var pe: TParticleEmitter;
  begin
    pe := TParticleEmitter.Create(FScene);
    FScene.Add(pe, LAYER_WEATHER);
    pe.LoadFromFile(ParticleFolder+aFilename, FAtlas);
    pe.SetCoordinate(xx, yy);
    pe.Shoot;
    pe.KillDefered(7);
    with Audio.AddSound('Fireworks.ogg') do begin
      ApplyEffect(Audio.FXReverbShort);
      PlayThenKill(True);
    end;
  end;

begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // ANIM FIREWORKS ON COMPLETED SUB GAME
    0: begin
      PostMessage(5, 0.5);
      PostMessage(6, 1);
      PostMessage(7, 1.6);
      PostMessage(8, 2.2);
      inc(FFireworkCount);
      if FFireworkCount < 4 then PostMessage(0, 0.5)
        else PostMessage(1, 2.5);
    end;
    1: begin
      UnableMouseInteractionOnMapObjects(True);
    end;
    5: begin
      GetButtonCoor;
      CreateFirework('FireWork01.par');
    end;
    6: begin
      GetButtonCoor;
      xx := xx-FTargetButtonForFireworkAnim.Image.Width*0.25;
      CreateFirework('FireWork06.par');
    end;
    7: begin
      GetButtonCoor;
      xx := xx+FTargetButtonForFireworkAnim.Width*0.25;
      CreateFirework('FireWork08.par');
    end;
    8: begin
      GetButtonCoor;
      //xx := xx-FTargetButtonForFireworkAnim.Width*0.1;
      //yy := yy+FTargetButtonForFireworkAnim.Height*0.1;
      CreateFirework('FireWork02.par');
    end;

    // message received from the panel where player choose the game step to play
    100: begin
      if not ChallengeMode then FScene.RunScreen(ScreenGameForest)
      else begin
        // check if player have the prerequisite to play the challenge
        with PlayerInfo.Forest do
          if IsTerminated and Bow.LevelIsMaximized and Elevator.LevelIsMaximized and
             Hammer.LevelIsMaximized and StormCloud.LevelIsMaximized then
             FScene.RunScreen(ScreenGameForest)
          else FPanelChooseGameStep.MouseInteractionEnabled := True;
      end;
    end;
    110: FScene.RunScreen(ScreenGameZipLine);
    120: begin
      // check if the last step was clicked, if yes start screen volcano dino
      if PlayerInfo.Volcano.StepPlayed = PlayerInfo.Volcano.StepCount then
        FScene.RunScreen(ScreenGameVolcanoDino)
      else
        FScene.RunScreen(ScreenGameVolcanoInner);
    end;
    130: FScene.RunScreen(ScreenPlainOfSleepingMoon);
    140: begin
      case PlayerInfo.MermaidsPort.StepPlayed of
        3: FScene.RunScreen(ScreenMermaidsBoss);
        else FScene.RunScreen(ScreenMermaidsPort);
      end;
    end;
    150: begin
      case PlayerInfo.SnakeFissure.StepPlayed of
        1: FScene.RunScreen(ScreenSnakeFissureIntro);
        else FScene.RunScreen(ScreenSnakeFissure);
      end;
    end;
    160: FScene.RunScreen(ScreenWolfCastle);
  end;
end;

procedure TScreenMap.Update(const aElapsedTime: single);
var s: string;
  flagCheatCodeApplyed: boolean;
begin
  inherited Update(aElapsedTime);

  // check if player enter cheat codes
  FCheatCodeManager.Update;
  s := FCheatCodeManager.CheatCodeEntered;
  if s <> '' then begin
    flagCheatCodeApplyed := False;

    with PlayerInfo do
      if (s = PinForestCheatCode) and not Forest.IsTerminated then begin
        Forest.ApplyCheatCode;
        flagCheatCodeApplyed := True;
      end;

    with PlayerInfo do
      if (s = MountainPeaksCheatCode) and Forest.IsTerminated and not MountainPeak.IsTerminated then begin
        MountainPeak.ApplyCheatCode;
        flagCheatCodeApplyed := True;
      end;

    if flagCheatCodeApplyed then begin
      if FPanelChooseGameStep <> NIL then FPanelChooseGameStep.Hide(True);
      FPanelChooseGameStep := NIL;
      Audio.PlayMusicCheatCodeEntered;
      FInMapPanel.CoinCounter.Count := PlayerInfo.CoinCount;
      if FInMapPanel.PurpleCristalCounter <> NIL then
        FInMapPanel.PurpleCristalCounter.Count := PlayerInfo.PurpleCristalCount;
      CheckIfASubGameWasCompleted;
      FSaveGame.Save;
      SetLRIconPositionOnGameToPlay;
    end;
  end;
end;

procedure TScreenMap.UnableMouseInteractionOnMapObjects(aValue: boolean);
begin
  BWorkShop.MouseInteractionEnabled := aValue;
  BSamHome.MouseInteractionEnabled := aValue;
  BPineForest.MouseInteractionEnabled := aValue;
  BMountainPeaks.MouseInteractionEnabled := aValue;
  BVolcano.MouseInteractionEnabled := aValue;
  BPlainMoon.MouseInteractionEnabled := aValue;
  BMermaidPort.MouseInteractionEnabled := aValue;
  BSnakeFissure.MouseInteractionEnabled := aValue;
  BCastle.MouseInteractionEnabled := aValue;
  BMainMenu.MouseInteractionEnabled := aValue;
end;

end.

