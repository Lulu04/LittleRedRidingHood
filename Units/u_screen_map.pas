unit u_screen_map;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene, ALSound,
  u_common, u_common_ui, u_gamescreentemplate, u_utils;

{ WHEN ADDING A NEW GAME: do the following:
    - update procedure TScreenMap.ShowLastGameStepPanel;
    - update function TScreenMap.CheckIfASubGameWasCompleted
    - add the new TImageButton in procedure TScreenMap.CreateObjects;
    - update procedure TScreenMap.UnableMouseInteractionOnMapObjects(aValue: boolean);
    - update procedure TScreenMap.SetLRIconPositionOnGameToPlay
    - add the new cheat codes (if any) in procedure TScreenMap.CreateObjects and handle them in TScreenMap.Update()
}

type

// add new game here
TGameOnMap = (gomUnknow, gomPineForest, gomZipLine, gomVolcano);

{ TScreenMap }

TScreenMap = class(TGameScreenTemplate)
private
  FsndSeaWave: TALSSound;
  FIconLR: TSprite;
  BWorkShop, BPineForest, BMountainPeaks, BVolcano: TImageButton;
  FTargetButtonForFireworkAnim: TImageButton;
  BMainMenu: TUIButton;
  FFireworkCount: integer;
  FInMapPanel: TInMapPanel;
  FCheatCodeManager: TCheatCodeManager;

  function CreateImageButton(tex: PTexture): TImageButton;
  function CreateButton(const aCaption: string; tex: PTexture): TUIButton;
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
  procedure ShowLastGameStepPanel;
  function CheckIfASubGameWasCompleted: boolean;
  procedure SetLRIconPositionOnGameToPlay;
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
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
  u_screen_gamevolcanodino, BGRAPath, Forms, Math;

type

{ TPanelChooseGameStep }

TPanelChooseGameStep = class(TCenteredGameUIPanel)
private class var FHintIndex: integer;
private
  FLine: TShapeOutline;
  FSteps: array of TImageButton;
  FImage: TUIImage;
  BStart, BBack, BHelpKeys: TUIButton;
  FTargetScreen: TScreenTemplate;
  FMessageToSend: TUserMessageValue;
  FGameDescriptor: TGameDescriptor;
  FLRIcon: TSprite;
  FSelectedStepIndex: integer;
  FHint: TUITextArea;
  FPreviousHintText: string;
  FKeyboardToButton: TButtonsClickableByKeyboard;
  procedure SetHint(AValue: string);
  procedure SetLRIconPosition;
protected
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect); override;
public
  constructor Create(aTexIcon, aLRIcon: PTexture; aGame: TGameDescriptor; aMessageToRunScreen: TUserMessageValue);
  procedure RemoveStartButton;
  property Hint: string write SetHint;
end;

var FFontText: TTexturedFont;
  texLRIcon, texMapStep, texMapStepChecked, texHelpKeys,
  texMapCastleFW, texMapCastleOutline,
  texMap1FW, texMap1Outline, texLRHome, texPineForest,
  texZipLinePeaks, texZipLinePeaksCableToVolcano,
  texVolcanoMountain,
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
  end else
  if Sender is TImageButton then begin
    Audio.PlayUIClick;
    o := TImageButton(Sender);
    FSelectedStepIndex := o.Tag1;
    SetLRIconPosition;
  end else
  if Sender = BHelpKeys then begin
    Audio.PlayUIClick;
    BHelpKeys.Tag2 := not BHelpKeys.Tag2;
    if BHelpKeys.Tag2 then begin
      FPreviousHintText := FHint.Text.Caption;
      FHint.Text.Caption := FGameDescriptor.HelpText;
    end else FHint.Text.Caption := FPreviousHintText;
  end;
end;

constructor TPanelChooseGameStep.Create(aTexIcon, aLRIcon: PTexture; aGame: TGameDescriptor;
  aMessageToRunScreen: TUserMessageValue);
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

  // keyboard to button
  FKeyboardToButton := TButtonsClickableByKeyboard.Create(Self, FAtlas);
  A := NIL;
  for i:=0 to High(FSteps) do
    if FSteps[i].MouseInteractionEnabled then begin
      SetLength(A, Length(A)+1);
      A[High(A)] := TUIButton(FSteps[i]);
    end;
 { A := NIL;
  SetLength(A, Length(FSteps));
  for i:=0 to High(A) do A[i] := TUIButton(FSteps[i]);  }
  FKeyboardToButton.AddLineOfButtons(A);
  FKeyboardToButton.AddLineOfButtons([BBack, BStart]);
  FKeyboardToButton.Select(BStart);

  // hint
  FHint := TUITextArea.Create(FScene);
  AddChild(FHint, 0);
  FHint.BodyShape.SetShapeRectangle(Round(Width/2), Round(Height/2), 0);
  FHint.BodyShape.Fill.Visible := False;
  FHint.BodyShape.Border.Visible := False;
  FHint.Text.Caption := GameHints[FHintIndex];
  inc(FHintIndex);
  if FHintIndex > High(GameHints) then FHintIndex := 0;
  FHint.Text.Align := taTopCenter;
  FHint.Text.TexturedFont := FFontText;
  FHint.SetCoordinate(Width/2-PPIScale(10), PPIScale(10));

  // button help key
  BHelpKeys := TUIButton.Create(FScene, '', NIL, texHelpKeys);
  AddChild(BHelpKeys, 0);
  BHelpKeys.AnchorPosToSurface(FHint, haRight, haLeft, 0, vaTop, vaTop, 0);
  BHelpKeys.OnClick := @ProcessButtonClick;
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

procedure TScreenMap.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
var pineForestDone, mountainPicDone: boolean;
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
  end;

  if Sender = BPineForest then begin
    UnableMouseInteractionOnMapObjects(False);
    FPanelChooseGameStep := TPanelChooseGameStep.Create(texPineForest, texLRIcon, PlayerInfo.Forest, 100);
    _ShowPanelChooseGameStep;
    LastGameClicked := gomPineForest;
    exit;
  end;

  if s = '' then
    if not pineForestDone then s := sFirstCompleteForest
      else if not PlayerInfo.MountainPeak.ZipLine.Owned then s := sBuyZipLineFirst;

  if Sender = BMountainPeaks then begin
    UnableMouseInteractionOnMapObjects(False);
    FPanelChooseGameStep := TPanelChooseGameStep.Create(texZipLinePeaks, texLRIcon, PlayerInfo.MountainPeak, 110);
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
      FPanelChooseGameStep := TPanelChooseGameStep.Create(texVolcanoMountain, texLRIcon, PlayerInfo.Volcano, 120);
      _ShowPanelChooseGameStep;
      LastGameClicked := gomVolcano;
      exit;
    end;
  end;

end;

procedure TScreenMap.ShowLastGameStepPanel;
begin
  case LastGameClicked of
    gomPineForest: ProcessButtonClick(BPineForest);
    gomZipLine: ProcessButtonClick(BMountainPeaks);
    gomVolcano: ProcessButtonClick(BVolcano);
  end;
end;

function TScreenMap.CheckIfASubGameWasCompleted: boolean;
begin
  FTargetButtonForFireworkAnim := NIL;
  if PlayerInfo.Forest.FirstTimeTerminated then FTargetButtonForFireworkAnim := BPineForest
  else
  if PlayerInfo.MountainPeak.FirstTimeTerminated then FTargetButtonForFireworkAnim := BMountainPeaks
  else
  if PlayerInfo.Volcano.FirstTimeTerminated then FTargetButtonForFireworkAnim := BVolcano;

  Result := FTargetButtonForFireworkAnim <> NIL;
  if Result then begin
    PostMessage(0);
    UnableMouseInteractionOnMapObjects(False);
  end;
end;

procedure TScreenMap.SetLRIconPositionOnGameToPlay;
begin
  if PlayerInfo.MountainPeak.IsTerminated then FIconLR.SetCenterCoordinate(BVolcano.CenterX, BVolcano.CenterY)
  else
  if PlayerInfo.Forest.IsTerminated then FIconLR.SetCenterCoordinate(BMountainPeaks.CenterX, BMountainPeaks.CenterY)
  else FIconLR.SetCenterCoordinate(BPineForest.CenterX, BPineForest.CenterY);
end;

procedure TScreenMap.CreateObjects;
var o, o1: TSprite;
  pe: TParticleEmitter;
  sea: TMultiColorRectangle;
  ima: TBGRABitmap;
  s: String;
  d, waveCount, i: Integer;
begin
FScene.LogDebug('TScreenMap.CreateObjects BEGIN');

//  LastGameClicked := gomUnknow;
  FPanelChooseGameStep := NIL;

  FFireworkCount := 0;
  FsndSeaWave := Audio.AddSound('sea-and-seagull.ogg');
  FsndSeaWave.Loop := True;
  FsndSeaWave.FadeIn(0.8, 3.0);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;
  AdditionnalScale := 1.0;

  texLRIcon := FAtlas.AddFromSVG(SpriteBGFolder+'LR.svg', ScaleW(33), -1);
  texMapStep := FAtlas.AddFromSVG(SpriteMapFolder+'MapStep.svg', ScaleW(21), -1);
  texMapStepChecked := FAtlas.AddFromSVG(SpriteMapFolder+'MapStepChecked.svg', ScaleW(34), -1);
  texHelpKeys := FAtlas.AddFromSVG(SpriteMapFolder+'HelpKeys.svg', PPIScale(32), -1);
  AddBlueArrowToAtlas(FAtlas);

  // games map
  texMap1FW := FAtlas.AddFromSVG(SpriteMapFolder+'Map1FW.svg', ScaleW(651), -1);
  texMap1Outline := FAtlas.AddFromSVG(SpriteMapFolder+'Map1Outline.svg', ScaleW(651), -1);
  texLRHome := FAtlas.AddFromSVG(SpriteBGFolder+'LRHome.svg', ScaleW(87), -1);
  FAtlas.Add(ParticleFolder+'sphere_particle.png');
  texPineForest := FAtlas.AddFromSVG(SpriteMapFolder+'PineForest.svg', ScaleW(167), -1);
  texVolcanoMountain := FAtlas.AddFromSVG(SpriteMapFolder+'VolcanoMountain.svg', ScaleW(123), -1);
  texZipLinePeaks := FAtlas.AddFromSVG(SpriteMapFolder+'ZipLinePeaks.svg', ScaleW(119), -1);
  texZipLinePeaksCableToVolcano := FAtlas.AddFromSVG(SpriteMapFolder+'ZipLinePeaksCableToVolcano.svg', ScaleW(93), -1);

  // castle island
  texMapCastleFW := FAtlas.AddFromSVG(SpriteMapFolder+'MapCastleFW.svg', ScaleW(170), -1);
  texMapCastleOutline := FAtlas.AddFromSVG(SpriteMapFolder+'MapCastleOutline.svg', ScaleW(170), -1);
  texCastle := FAtlas.AddFromSVG(SpriteBGFolder+'WolfCastle.svg', ScaleW(121), -1);

  FFontText := CreateGameFontText(FAtlas);

  CreateGameFontNumber(FAtlas);
  LoadCoinTexture(FAtlas);
  LoadCristalGrayTexture(FAtlas);

  LoadMousePointerTexture(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;
  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  // sea
  sea := TMultiColorRectangle.Create(FScene.Width, FScene.Height);
  sea.SetAllColorsTo(BGRA(4,83,177));
 // sky.SetBottomColors(BGRA(13,31,178)); //(BGRA(65,209,99)); //(BGRA(8,242,130));
  FScene.Add(sea, LAYER_BG2);

  // LR island
  o := TSprite.Create(texMap1FW, False);
  FScene.Add(o, LAYER_GROUND);
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
  FScene.Add(o, LAYER_GROUND);
  o.SetCoordinate(ScaleW(752), ScaleH(168));

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



  // button workshop
  BWorkShop := CreateImageButton(texLRHome);
  BWorkShop.SetCoordinate(ScaleW(121), ScaleH(488));
  pe := TParticleEmitter.Create(FScene);
  BWorkShop.AddChild(pe, 1);
  pe.LoadFromFile(ParticleFolder+'LRHomeSmoke.par', FAtlas);
  pe.SetCoordinate(BWorkShop.Width*0.25, BWorkShop.Height*0.001);
  pe.SetEmitterTypePoint;

  // button pine forest
  BPineForest := CreateImageButton(texPineForest);
  BPineForest.SetCoordinate(ScaleW(60), ScaleH(50));

  // button volcano mountain
  BVolcano := CreateImageButton(texVolcanoMountain);
  BVolcano.SetCoordinate(ScaleW(357), ScaleH(163));
  pe := TParticleEmitter.Create(FScene);
  BVolcano.AddChild(pe, 1);
  pe.LoadFromFile(ParticleFolder+'VolcanoMountainSmoke.par', FAtlas);
  pe.SetCoordinate(BVolcano.Width*0.3518, BVolcano.Height*0.0729);
  pe.SetEmitterTypeLine(PointF(BVolcano.Width*0.5279, BVolcano.Height*0.0729));
  pe.FParticleParam.Size := 0.22;

  // button mountain peaks
  BMountainPeaks := CreateImageButton(texZipLinePeaks);
  BMountainPeaks.SetCoordinate(ScaleW(230), ScaleH(94));
  o := TSprite.Create(texZipLinePeaksCableToVolcano, False);
  BMountainPeaks.AddChild(o, 0);
  o.SetCoordinate(BMountainPeaks.Width*0.75, BMountainPeaks.Height*0.55);

  // Wolf castle
  o := TSprite.Create(texCastle, False);
  FScene.Add(o, LAYER_GROUND);
  o.SetCoordinate(ScaleW(783), ScaleH(186));

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

  CustomizeMousePointer;

FScene.LogDebug('TScreenMap.CreateObjects END');
end;

procedure TScreenMap.FreeObjects;
begin
FScene.LogDebug('TScreenMap.FreeObjects BEGIN');
  FsndSeaWave.FadeOutThenKill(3.0);
  FsndSeaWave := NIL;
  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
FScene.LogDebug('TScreenMap.FreeObjects END');
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
    100: FScene.RunScreen(ScreenGameForest);
    110: FScene.RunScreen(ScreenGameZipLine);
    120: begin
      // check if the last step was clicked, if yes start screen volcano dino
      if PlayerInfo.Volcano.StepPlayed = PlayerInfo.Volcano.StepCount then
        FScene.RunScreen(ScreenGameVolcanoDino)
      else
        FScene.RunScreen(ScreenGameVolcanoInner);
    end;
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
  BPineForest.MouseInteractionEnabled := aValue;
  BMountainPeaks.MouseInteractionEnabled := aValue;
  BVolcano.MouseInteractionEnabled := aValue;
  BMainMenu.MouseInteractionEnabled := aValue;
end;

end.

