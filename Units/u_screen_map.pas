unit u_screen_map;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene, ALSound,
  u_common, u_common_ui;

{ WHEN ADDING A NEW GAME: update the following:
    - procedure ShowLastGameStepPanel;
    - function TScreenMap.CheckIfASubGameWasCompleted
    - add the new TImageButton in procedure CreateObjects;
    - procedure TScreenMap.UnableMouseInteractionOnMapObjects(aValue: boolean);
}

type

// add new game here
TGameOnMap = (gomUnknow, gomPineForest, gomZipLine, gomVolcano);

{ TScreenMap }

TScreenMap = class(TScreenTemplate)
private
  FsndSeaWave: TALSSound;
  FAtlas: TOGLCTextureAtlas;
  FIconLR: TSprite;
  BWorkShop, BPineForest, BMountainPeaks, BVolcano: TImageButton;
  FTargetButtonForFireworkAnim: TImageButton;
  BMainMenu: TUIButton;
  FFireworkCount: integer;

  function CreateImageButton(tex: PTexture): TImageButton;
  function CreateButton(const aCaption: string; tex: PTexture): TUIButton;
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
  procedure ShowLastGameStepPanel;
  function CheckIfASubGameWasCompleted: boolean;
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;

  // enable disable button on the map
  procedure UnableMouseInteractionOnMapObjects(aValue: boolean);
end;

var ScreenMap: TScreenMap;
    LastGameClicked: TGameOnMap=gomUnknow;

implementation
uses u_app, u_resourcestring, u_screen_title, u_screen_gameforest,
  u_screen_workshop, u_mousepointer, u_screen_gamemountainpeaks, u_ui_panels,
  u_screen_gamevolcanoentrance, u_audio, BGRAPath, Forms, Math;

type

{ TPanelChooseGameStep }

TPanelChooseGameStep = class(TCenteredGameUIPanel)
private
  FLine: TShapeOutline;
  FSteps: array of TImageButton;
  FImage: TUIImage;
  BStart, BBack: TUIButton;
  FScreenToRun: TScreenTemplate;
  FGameDescriptor: TGameDescriptor;
  FLRIcon: TSprite;
  FSelectedStepIndex: integer;
  FHint: TUITextArea;
  procedure SetHint(AValue: string);
  procedure SetLRIconPosition;
protected
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect); override;
public
  constructor Create(aTexIcon, aLRIcon: PTexture; aGame: TGameDescriptor; aScreen: TScreenTemplate);
  procedure RemoveStartButton;
  property Hint: string write SetHint;
end;

var FFontText: TTexturedFont;
  texLRIcon, texMapStep, texMapStepChecked,
  texMapCastleFW, texMapCastleOutline,
  texMap1BG, texMap1FW, texMap1Outline, texLRHome, texPineForest,
  texZipLinePeaks, texZipLinePeaksCableToVolcano,
  texVolcanoMountain,
  texCastle: PTexture;
  FPanelChooseGameStep: TPanelChooseGameStep=NIL;



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
  Audio.PlayUIClick;
  if Sender = BStart then begin
    MouseInteractionEnabled := False;
    FGameDescriptor.StepPlayed := FSelectedStepIndex;
    FScene.RunScreen(FScreenToRun);
  end else
  if Sender = BBack then begin
    Hide(True);
    ScreenMap.UnableMouseInteractionOnMapObjects(True);
  end else
  if Sender is TImageButton then begin
    o := TImageButton(Sender);
    FSelectedStepIndex := o.Tag1;
    SetLRIconPosition;
  end;
end;

constructor TPanelChooseGameStep.Create(aTexIcon, aLRIcon: PTexture; aGame: TGameDescriptor;
  aScreen: TScreenTemplate);
var i, w: integer;
begin
  inherited Create(Round(FScene.Width*0.6), Round(FScene.Height*0.3), FFontText);
  CenterOnScene;

  FGameDescriptor := aGame;
  FScreenToRun := aScreen;

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
  BStart.AnchorPosToParent(haRight, haRight, -PPIScale(10), vaBottom, vaBottom, -PPIScale(10));

  BBack := TUIButton.Create(FScene, sBack, FFont, NIL);
  AddChild(BBack, 0);
  FormatButtonMenu(BBack);
  BBack.AnchorPosToParent(haLeft, haLeft, PPIScale(10), vaBottom, vaBottom, -PPIScale(10));

  // hint
  FHint := TUITextArea.Create(FScene);
  AddChild(FHint, 0);
  FHint.BodyShape.SetShapeRectangle(Round(Width/2), Round(Height/2), 0);
  FHint.BodyShape.Fill.Visible := False;
  FHint.BodyShape.Border.Visible := False;
  FHint.Text.Caption := sImproveEquipment;
  FHint.Text.Align := taTopCenter;
  FHint.Text.TexturedFont := FFontText;
  FHint.SetCoordinate(Width/2-PPIScale(10), PPIScale(10));
end;

procedure TPanelChooseGameStep.RemoveStartButton;
begin
  BStart.Kill;
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
    FPanelChooseGameStep := TPanelChooseGameStep.Create(texPineForest, texLRIcon, PlayerInfo.Forest, ScreenGameForest);
    _ShowPanelChooseGameStep;
    LastGameClicked := gomPineForest;
    exit;
  end;

  if s = '' then
    if not pineForestDone then s := sFirstCompleteForest
      else if not PlayerInfo.MountainPeak.ZipLine.Owned then s := sBuyZipLineFirst;

  if Sender = BMountainPeaks then begin
    UnableMouseInteractionOnMapObjects(False);
    FPanelChooseGameStep := TPanelChooseGameStep.Create(texZipLinePeaks, texLRIcon, PlayerInfo.MountainPeak, ScreenGameZipLine);
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
      { #todo : reprendre ici lorsque le jeu Volcano sera fait }
      FPanelChooseGameStep := TPanelChooseGameStep.Create(texVolcanoMountain, texLRIcon, PlayerInfo.Volcano, ScreenGameVolcanoEntrance);
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

procedure TScreenMap.CreateObjects;
var o, o1: TSprite;
  pe: TParticleEmitter;
  sea: TMultiColorRectangle;
  ima: TBGRABitmap;
begin
FScene.LogInfo('Entering TScreenMap.CreateObjects');

  FFireworkCount := 0;
  FsndSeaWave := Audio.AddSound('sea-and-seagull.ogg');
  FsndSeaWave.Loop := True;
  FsndSeaWave.FadeIn(0.8, 3.0);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  texLRIcon := FAtlas.AddFromSVG(SpriteBGFolder+'LR.svg', ScaleW(33), -1);
  texMapStep := FAtlas.AddFromSVG(SpriteMapFolder+'MapStep.svg', ScaleW(21), -1);
  texMapStepChecked := FAtlas.AddFromSVG(SpriteMapFolder+'MapStepChecked.svg', ScaleW(34), -1);
  // MAP 1
  texMap1FW := FAtlas.AddFromSVG(SpriteMapFolder+'Map1FW.svg', ScaleW(718), -1);
  texMap1BG := FAtlas.AddFromSVG(SpriteMapFolder+'Map1BG.svg', ScaleW(772), -1);
  texMap1Outline := FAtlas.AddFromSVG(SpriteMapFolder+'Map1OutLine.svg', ScaleW(718), -1);
  texLRHome := FAtlas.AddFromSVG(SpriteBGFolder+'LRHome.svg', ScaleW(87), -1);
  FAtlas.Add(ParticleFolder+'sphere_particle.png');
  texPineForest := FAtlas.AddFromSVG(SpriteMapFolder+'PineForest.svg', ScaleW(167), -1);
  texVolcanoMountain := FAtlas.AddFromSVG(SpriteMapFolder+'VolcanoMountain.svg', ScaleW(123), -1);
  texZipLinePeaks := FAtlas.AddFromSVG(SpriteMapFolder+'ZipLinePeaks.svg', ScaleW(119), -1);
  texZipLinePeaksCableToVolcano := FAtlas.AddFromSVG(SpriteMapFolder+'ZipLinePeaksCableToVolcano.svg', ScaleW(93), -1);

  // MAP 2
  texMapCastleFW := FAtlas.AddFromSVG(SpriteMapFolder+'MapCastleFW.svg', ScaleW(287), -1);
  texMapCastleOutline := FAtlas.AddFromSVG(SpriteMapFolder+'MapCastleOutline.svg', ScaleW(287), -1);
  texCastle := FAtlas.AddFromSVG(SpriteBGFolder+'WolfCastle.svg', Round(FScene.Width/5), -1);

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

  // Map 1 BG
  o := TSprite.Create(texMap1FW, False);
  FScene.Add(o, LAYER_GROUND);
  o.SetCoordinate(ScaleW(28), ScaleH(24));

  o1 := TSprite.Create(texMap1FW, False);   // texMap1BG
  o.AddChild(o1, -3);
  o1.CenterOnParent;
  o1.Opacity.Value := 100;
  o1.TintMode := tmReplaceColor;
  o1.Scale.Value := PointF(1.1, 1.1);
  o1.Tint.Value := BGRA(107,161,209);

  o1 := TSprite.Create(texMap1Outline, False);         //texMap1Outline
  o.AddChild(o1, -2);
  o1.CenterOnParent;
  o1.AddAndPlayScenario('Scale 1.1'#10+
                        'Opacity 0'#10+
                        'ScaleChange 0.8 5.0 idcSinusoid'#10+
                        'OpacityChange 100 5.0 idcLinear'#10+
                        'Wait 5.0'#10+
                        'Loop');

  o1 := TSprite.Create(texMap1Outline, False);
  o.AddChild(o1, -1);
  o1.CenterOnParent;
  o1.Opacity.Value := 0;
  o1.AddAndPlayScenario('Wait 2.5'#10+
                        'Label HERE'#10+
                        'Scale 1.1'#10+
                        'Opacity 0'#10+
                        'ScaleChange 0.8 5.0 idcSinusoid'#10+
                        'OpacityChange 100 5.0 idcLinear'#10+
                        'Wait 5.0'#10+
                        'Goto HERE');


  // map castle
  o := TSprite.Create(texMapCastleFW, False);
  FScene.Add(o, LAYER_GROUND);
  o.SetCoordinate(ScaleW(727), ScaleH(71));

  o1 := TSprite.Create(texMapCastleFW, False);   // texMap1BG
  o.AddChild(o1, -3);
  o1.CenterOnParent;
  o1.Opacity.Value := 100;
  o1.TintMode := tmReplaceColor;
  o1.Tint.Value := BGRA(107,161,209);
  o1.Scale.Value := PointF(1.1, 1.1);

  o1 := TSprite.Create(texMapCastleOutline, False);
  o.AddChild(o1, -2);
  o1.CenterOnParent;
  o1.AddAndPlayScenario('Scale 1.1'#10+
                        'Opacity 0'#10+
                        'ScaleChange 1.0 5.0 idcSinusoid'#10+
                        'OpacityChange 100 5.0 idcLinear'#10+
                        'Wait 5.0'#10+
                        'Loop');

  o1 := TSprite.Create(texMapCastleOutline, False);
  o.AddChild(o1, -1);
  o1.CenterOnParent;
  o1.Opacity.Value := 0;
  o1.AddAndPlayScenario('Wait 2.5'#10+
                        'Label HERE'#10+
                        'Scale 1.1'#10+
                        'Opacity 0'#10+
                        'ScaleChange 1.0 5.0 idcSinusoid'#10+
                        'OpacityChange 100 5.0 idcLinear'#10+
                        'Wait 5.0'#10+
                        'Goto HERE');


  // button workshop
  BWorkShop := CreateImageButton(texLRHome);
  BWorkShop.SetCoordinate(ScaleW(90), ScaleH(488));
  pe := TParticleEmitter.Create(FScene);
  BWorkShop.AddChild(pe, 1);
  pe.LoadFromFile(ParticleFolder+'LRHomeSmoke.par', FAtlas);
  pe.SetCoordinate(BWorkShop.Width*0.25, BWorkShop.Height*0.001);
  pe.SetEmitterTypePoint;

  // button pine forest
  BPineForest := CreateImageButton(texPineForest);
  BPineForest.SetCoordinate(ScaleW(38), ScaleH(21));

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
  o.SetCenterCoordinate(FScene.Width*0.85, FScene.Height*0.3);
FScene.LogInfo('Wolf castle created', 1);

  // icon LR
  FIconLR := TSprite.Create(texLRIcon, False);
  FScene.Add(FIconLR, LAYER_PLAYER);
  FIconLR.CenterX := BWorkShop.CenterX;
  FIconLR.BottomY := BWorkShop.BottomY;
  FIconLR.Blink(-1, 0.3, 0.3);
  if PlayerInfo.MountainPeak.IsTerminated then FIconLR.SetCenterCoordinate(BVolcano.CenterX, BVolcano.CenterY)
  else
  if PlayerInfo.Forest.IsTerminated then FIconLR.SetCenterCoordinate(BMountainPeaks.CenterX, BMountainPeaks.CenterY)
  else FIconLR.SetCenterCoordinate(BPineForest.CenterX, BPineForest.CenterY);
FScene.LogInfo('FIconLR created', 1);

  // buttons
  BMainMenu := CreateButton(sBack, NIL);
  BMainMenu.X.Value := ScaleW(10);
  BMainMenu.BottomY := FScene.Height-ScaleH(10);

FScene.LogInfo('BMainMenu created', 1);

  // player items panel
  TInMapPanel.Create; // not necessary to keep the instance

FScene.LogInfo('TInMapPanel created', 1);

  // check if a sub-game was completed, if yes an animation with firework start
  // else the last game panel is opened
  if not CheckIfASubGameWasCompleted then
    if LastGameClicked <> gomUnknow then ShowLastGameStepPanel;

  CustomizeMousePointer;

FScene.LogInfo('end of TScreenMap.CreateObjects');
end;

procedure TScreenMap.FreeObjects;
begin
  FsndSeaWave.FadeOutThenKill(3.0);
  FsndSeaWave := NIL;
  FreeMousePointer;
  FScene.ClearAllLayer;
  FreeAndNil(FAtlas);
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
      ApplyEffect(Audio.Reverb1);
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

