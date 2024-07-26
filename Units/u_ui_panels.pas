unit u_ui_panels;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene, u_common;

type

{ TPanelWithBGDarkness }

TPanelWithBGDarkness = class(TUIPanel)
private
  FSceneDarkness: TMultiColorRectangle;
  procedure CreateSceneDarkness;
public
  constructor Create(aWidth, aHeight: integer); overload;
  constructor Create(aWidth: integer); overload;
  destructor Destroy; override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure Show; virtual;
  procedure Hide(aFree: boolean); virtual;
end;

{ TCenteredGameUIPanel }

TCenteredGameUIPanel = class(TPanelWithBGDarkness)
protected
  FFont: TTexturedFont;
  procedure FormatButtonMenu(aButton: TUIButton);
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect); virtual; abstract;
public
  constructor Create(aWidth, aHeight: integer; aFont: TTexturedFont);
end;

{ TNewPlayerPanel }

TNewPlayerPanel = class(TCenteredGameUIPanel)
private
  BStart, BBack, BErase: TUIButton;
  FPanelName: TUIPanel;
  FName: TUILabel;
  FCursor: TShapeOutline;
  FKeyboardButtonSize, FKeyboardButtonSpacing: integer;
  procedure FormatButtonKeyboard(aButton: TUIButton);
  procedure FormatBigButtonKeyboard(aButton: TUIButton);
protected
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect); override;
public
  constructor Create(aFont: TTexturedFont);
  procedure Update(const aElapsedTime: single); override;
  procedure Show; override;
  procedure Hide(aFree: boolean); override;
end;


{ TContinuePanel }

TContinuePanel = class(TCenteredGameUIPanel)
private
  BContinue, BBack, BDelete: TUIButton;
  FLBPlayers: TUIListBox;
protected
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect); override;
public
  constructor Create(aFont: TTexturedFont);
  procedure Show; override;
  procedure Hide(aFree: boolean); override;
  procedure UpdatePlayerList;
end;


{ TPressAKeyPanel }

TPressAKeyPanel = class(TCenteredGameUIPanel)
private
  FKey: word;
  FOnDone: TOGLCEvent;
  FClock: TFreeTextClockLabel;
  FScanKey: boolean;
protected
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect); override;
  procedure ProcessCountDownDone(Sender: TObject);
public
  constructor Create(aFont: TTexturedFont; aCallBackOnDone: TOGLCEvent);
  procedure Update(const AElapsedTime: single); override;
  procedure Show; override;
  procedure Hide(aFree: boolean); override;
  property Key: word read FKey write FKey;
end;

{ TOptionsPanel }

TOptionsPanel = class(TCenteredGameUIPanel)
private
  BClose: TUIButton;
  CursorMusic, CursorSound: TUIScrollBar;
  LabelCursorMusic, LabelCursorSound: TUILabel;
  ListBoxLanguages: TUIListBox;
  ButtonKeyUp, ButtonKeyDown, ButtonKeyLeft, ButtonKeyRight,
  ButtonKeyAction1, ButtonKeyAction2, ButtonKeyPause: TUIButton;
  LabelKeyUp, LabelKeyDown, LabelKeyLeft, LabelKeyRight,
  LabelKeyAction1, LabelKeyAction2, LabelKeyPause: TUILabel;
  FKeyboardButtonSize, FKeyboardButtonSpacing: integer;
  texArrow: PTexture;
  PanelPressAKey: TPressAKeyPanel;
  FButtonEdited: TUIButton;
  procedure ProcessCursorChange(Sender: TSimpleSurfaceWithEffect);
  procedure FormatButtonKey(aButton: TUIButton; aIsAction: boolean=False);
  procedure FormatLabelKey(aLabel: TUILabel);
  procedure UpdateLabelKeys;
  procedure UpdateLabelVolume;
  procedure ProcessPressAKeyDone;
  procedure ProcessLanguageChange(Sender: TSimpleSurfaceWithEffect);
protected
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect); override;
public
  constructor Create(aFont: TTexturedFont);
  destructor Destroy; override;
  procedure Show; override;
  procedure Hide(aFree: boolean); override;
  procedure UpdateWidget;
end;

{ TCreditsPanel }

TCreditsPanel = class(TCenteredGameUIPanel)
private
  BClose: TUIButton;
  FUITextArea: TUITextArea;
  FtexRedHeart: PTexture;
  procedure CreateHearts;
protected
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect); override;
public
  constructor Create(aFont: TTexturedFont);
  destructor Destroy; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Show; override;
  procedure Hide(aFree: boolean); override;
end;

{ TInGamePausePanel }

TInGamePausePanel = class(TUIModalPanel)
private
  BResumeGame, BBackToMap: TUIButton;
  procedure FormatButton(aButton: TUIButton);
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
public
  constructor Create(aFont: TTexturedFont);
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure ShowModal; override;
end;


var
  texTrashCan: PTexture;
procedure LoadTitleScreenIcon(aAtlas: TOGLCTextureAtlas; aFontHeight: integer);


implementation
uses u_resourcestring, u_app, u_screen_title, u_screen_map, u_audio, i18_utils;

procedure LoadTitleScreenIcon(aAtlas: TOGLCTextureAtlas; aFontHeight: integer);
begin
  texTrashCan := aAtlas.AddFromSVG(SpriteUIFolder+'TrashCan.svg', -1, Round(aFontHeight*0.7));
end;

{ TCreditsPanel }

procedure TCreditsPanel.CreateHearts;
var s: TSprite;
  i: integer;
  sc: string;
begin
    sc := 'OpacityChange 255 1.0 idcLinear'#$0A+
          'Wait 1.0'#$0A+
          'OpacityChange 0 1.0 idcLinear'#$0A+
          'Wait 1.0'#$0A+
          'Kill';
  for i:=1 to 3 do begin
    s := TSprite.Create(FtexRedHeart, False);
    FUITextArea.AddChild(s, 0);
    s.SetCoordinate(Random(FUITextArea.Width-s.Width), Random(FUITextArea.Height-s.Height));
    s.Opacity.Value := 0;
    s.AddAndPlayScenario(sc);
  end;
end;

procedure TCreditsPanel.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  Audio.PlayUIClick;
  if Sender = BClose then begin
    Hide(False);
  end;
end;

constructor TCreditsPanel.Create(aFont: TTexturedFont);
var title: TUILabel;
  t: TStringList;
  w, h, k: integer;
begin
  w := Round(FScene.Width*0.7);
  h := Round(FScene.Height*0.7);
  inherited Create(w, h, aFont);

  BClose := TUIButton.Create(FScene, sClose, aFont, NIL);
  AddChild(BClose, 0);
  FormatButtonMenu(BClose);
  BClose.AnchorPosToParent(haRight, haRight, -PPIScale(10), vaBottom, vaBottom, -PPIScale(10));

  // label title
  title := TUILabel.Create(FScene, sCredits, aFont);
  AddChild(title, 0);
  title.Tint.Value := BGRA(255,255,50);
  title.AnchorPosToParent(haLeft, haLeft, PPIScale(10), vaTop, vaTop, PPIScale(10));
  title.MouseInteractionEnabled := False;

  // load credit file
  t := TStringList.Create;
  try
    t.LoadFromFile(FScene.App.DataFolder+'credits.txt');
  except
    t.Add('credit file not found...');
  end;
  // replace tags by their translations
  k := t.IndexOf('[THANKS]');
  if k <> -1 then t.Strings[k] := sThanks;
  k := t.IndexOf('[DEV]');
  if k <> -1 then t.Strings[k] := sDevelopment;
  k := t.IndexOf('[GRAPHICS]');
  if k <> -1 then t.Strings[k] := sGraphics;
  k := t.IndexOf('[MUSICS]');
  if k <> -1 then t.Strings[k] := sMusics;
  k := t.IndexOf('[SOUNDS]');
  if k <> -1 then t.Strings[k] := sSounds;

  // text area
  w := w - PPIScale(20);
  h := h - PPIScale(10) - BClose.Height  - PPIScale(10) - title.Height - PPIScale(10);
  FUITextArea := TUITextArea.Create(FScene);
  AddChild(FUITextArea, 0);
  FUITextArea.BodyShape.SetShapeRoundRect(w, h, PPIScale(10), PPIScale(10), 2);
  FUITextArea.AnchorHPosToParent(haCenter, haCenter, 0);
  FUITextArea.AnchorVPosToSurface(title, vaTop, vaBottom, PPIScale(10));
  FUITextArea.Text.TexturedFont := aFont;
  FUITextArea.Text.Tint.Value := BGRA(220,220,220);
  FUITextArea.Text.Align := taTopLeft;
  FUITextArea.Text.Caption := t.Text;
  t.Free;

  // red heart texture
  FtexRedHeart := FScene.TexMan.AddFromSVG(SpriteUIFolder+'RedHeart.svg', PPIScale(20), PPIScale(20));
end;

destructor TCreditsPanel.Destroy;
begin
  FScene.TexMan.Delete(FtexRedHeart);
  inherited Destroy;
end;

procedure TCreditsPanel.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // create some heart
    0: begin
      CreateHearts;
      PostMessage(0, 0.3);
    end;
  end;
end;

procedure TCreditsPanel.Show;
begin
  PostMessage(0);
  inherited Show;
end;

procedure TCreditsPanel.Hide(aFree: boolean);
begin
  inherited Hide(aFree);
  ClearMessageList;
  ScreenTitle.SetMenuButtonVisible(True);
end;

{ TPanelWithBGDarkness }

procedure TPanelWithBGDarkness.CreateSceneDarkness;
begin
  FSceneDarkness := TMultiColorRectangle.Create(FScene.Width, FScene.Height);
  FSceneDarkness.SetAllColorsTo(BGRA(0,0,0));
  FScene.Add(FSceneDarkness, LAYER_GAMEUI);
  FSceneDarkness.Opacity.Value := 0;
end;

constructor TPanelWithBGDarkness.Create(aWidth, aHeight: integer);
begin
  inherited Create(FScene);

  CreateSceneDarkness;

  FScene.Add(Self, LAYER_GAMEUI);
  MouseInteractionEnabled := False;
  BodyShape.SetShapeRoundRect(aWidth, aHeight, PPIScale(8), PPIScale(8), PPIScale(3));
  BodyShape.Fill.Color := BGRA(30,15,7);
  Opacity.Value := 0;
end;

constructor TPanelWithBGDarkness.Create(aWidth: integer);
begin
  inherited Create(FScene);

  CreateSceneDarkness;

  FScene.Add(Self, LAYER_GAMEUI);
  MouseInteractionEnabled := False;
  BodyShape.SetShapeEllipse(aWidth, aWidth, PPIScale(3));
  BodyShape.Fill.Color := BGRA(30,15,7);
  Opacity.Value := 0;
end;

destructor TPanelWithBGDarkness.Destroy;
begin
  FSceneDarkness.Kill;
  inherited Destroy;
end;

procedure TPanelWithBGDarkness.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // SHOW
    10000: begin
      FSceneDarkness.Opacity.ChangeTo(100, 0.3);
      Opacity.ChangeTo(255, 0.3);
      Scale.Value := PointF(0.3,0.3);
      Scale.ChangeTo(PointF(1,1), 0.3);
      PostMessage(10001, 0.3);
    end;
    10001: begin
      MouseInteractionEnabled := True;
    end;
  end;
end;

procedure TPanelWithBGDarkness.Show;
begin
  PostMessage(10000);
end;

procedure TPanelWithBGDarkness.Hide(aFree: boolean);
begin
  MouseInteractionEnabled := False;
  FSceneDarkness.Opacity.ChangeTo(0, 0.3);
  Opacity.ChangeTo(0, 0.3);
  Scale.ChangeTo(PointF(0.3,0.3), 0.3);
  if aFree then KillDefered(0.3);
end;

{ TInGamePausePanel }

procedure TInGamePausePanel.FormatButton(aButton: TUIButton);
begin
  AddChild(aButton);
  aButton.OnClick := @ProcessButtonClick;
  aButton._Label.Tint.Value := BGRA(255,255,150);
  aButton.BodyShape.SetShapeRoundRect(20, 20, PPIScale(8), PPIScale(8), PPIScale(2));
  aButton.BodyShape.Fill.Color := BGRA(0,0,0);
  aButton.BodyShape.Fill.CenterColor := BGRA(30,30,30);
end;

procedure TInGamePausePanel.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  Audio.PlayUIClick;
  if Sender = BResumeGame then begin
    Hide;
  end else
  if Sender = BBackToMap then begin
    Hide;
    FScene.RunScreen(ScreenMap);
  end;
  Audio.GlobalVolume := 1.0;
end;

constructor TInGamePausePanel.Create(aFont: TTexturedFont);
var VMargin, maxWidth: integer;
  title: TUILabel;
begin
  inherited Create(FScene);
  BodyShape.SetShapeRoundRect(20, 20, PPIScale(8), PPIScale(8), PPIScale(2));

  VMargin := aFont.Font.FontHeight div 2;
  maxWidth := 0;

  BResumeGame := TUIButton.Create(FScene, sResumeGame, aFont, NIL);
  FormatButton(BResumeGame);
  if maxWidth < BResumeGame.Width then maxWidth := BResumeGame.Width;
  BResumeGame.AnchorPosToParent(haCenter, haCenter, 0, vaCenter, vaCenter, 0);

  title := TUILabel.Create(FScene, sGamePaused, aFont);
  AddChild(title);
  title.Tint.Value := BGRA(220,220,220);
  title.Blink(-1, 0.5, 0.5);
  title.AnchorPosToSurface(BResumeGame, haCenter, haCenter, 0, vaBottom, vaTop, -VMargin);

  BBackToMap := TUIButton.Create(FScene, sBackToMap, aFont, NIL);
  FormatButton(BBackToMap);
  BBackToMap.AnchorPosToSurface(BResumeGame, haCenter, haCenter, 0, vaTop, vaBottom, VMargin);
  if maxWidth < BBackToMap.Width then maxWidth := BBackToMap.Width;

  BodyShape.ResizeCurrentShape(Round(maxWidth*1.5), VMargin*4+aFont.Font.FontHeight*4, True);
  CenterOnScene;
end;

procedure TInGamePausePanel.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // wait player release PAUSE key
    0: begin
      if FScene.KeyState[KeyPause] then PostMessage(0)
      else begin
        FScene.KeyPressed[KeyPause]; // reset key state in buffer
        PostMessage(1);
      end;
    end;
    // check if player press PAUSE key
    1: begin
      if FScene.KeyPressed[KeyPause] then begin
        Audio.GlobalVolume := 1.0;
        Hide;
      end else PostMessage(1);
    end;
  end;
end;

procedure TInGamePausePanel.ShowModal;
begin
  inherited ShowModal;
  ClearMessageList;
  PostMessage(0, 1.0);
  Audio.GlobalVolume := 0.5;
end;

{ TPressAKeyPanel }

procedure TPressAKeyPanel.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  Audio.PlayUIClick;
end;

procedure TPressAKeyPanel.ProcessCountDownDone(Sender: TObject);
begin
  Hide(False);
  FOnDone();
end;

constructor TPressAKeyPanel.Create(aFont: TTexturedFont; aCallBackOnDone: TOGLCEvent);
var t: TFreeText;
  h: integer;
begin
  h := aFont.Font.FontHeight;
  inherited Create(Round(FScene.Width*0.6), h*4, aFont);
  FOnDone := aCallBackOnDone;

  // title
  t := TFreeText.Create(FScene);
  AddChild(t);
  t.TexturedFont := aFont;
  t.Caption := sPressAKey;
  t.Tint.Value := BGRA(255,255,0);
  t.CenterX := Width*0.5;
  t.Y.Value := h;

  // count down
  FClock := TFreeTextClockLabel.Create(FScene, True);
  AddChild(FClock);
  FClock.TexturedFont := aFont;
  FClock.Countdown := True;
  FClock.ShowFractionalPart := False;
  FClock.Time := 5.0;
  FClock.Tint.Value := BGRA(255,255,255);
  FClock.CenterX := Width*0.5;
  FClock.Y.Value := t.BottomY;
  FClock.OnCountdownDone := @ProcessCountDownDone;
end;

procedure TPressAKeyPanel.Update(const AElapsedTime: single);
begin
  inherited Update(AElapsedTime);

  if not FScanKey then exit;

  if FScene.UserPressAKey then begin
    FKey := FScene.LastKeyDown;
    Hide(False);
    FOnDone();
  end;
end;

procedure TPressAKeyPanel.Show;
begin
  inherited Show;
  FClock.Time := 5.0;
  FClock.Run;
  FScanKey := True;
end;

procedure TPressAKeyPanel.Hide(aFree: boolean);
begin
  inherited Hide(aFree);
  FClock.Pause;
  FScanKey := False;
end;

{ TOptionsPanel }

procedure TOptionsPanel.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  Audio.PlayUIClick;
  FButtonEdited := TUIButton(Sender);
  if Sender = BClose then begin
    FSaveGame.Save;
    Hide(False);
  end else
  if Sender = ButtonKeyUp then begin
    MouseInteractionEnabled := False;
    PanelPressAKey.Key := FSaveGame.KeyUp;
    PanelPressAKey.Show;
  end else
  if Sender = ButtonKeyDown then begin
    MouseInteractionEnabled := False;
    PanelPressAKey.Key := FSaveGame.KeyDown;
    PanelPressAKey.Show;
  end else
  if Sender = ButtonKeyLeft then begin
    MouseInteractionEnabled := False;
    PanelPressAKey.Key := FSaveGame.KeyLeft;
    PanelPressAKey.Show;
  end else
  if Sender = ButtonKeyRight then begin
    MouseInteractionEnabled := False;
    PanelPressAKey.Key := FSaveGame.KeyRight;
    PanelPressAKey.Show;
  end else
  if Sender = ButtonKeyAction1 then begin
    MouseInteractionEnabled := False;
    PanelPressAKey.Key := FSaveGame.KeyAction1;
    PanelPressAKey.Show;
  end else
  if Sender = ButtonKeyAction2 then begin
    MouseInteractionEnabled := False;
    PanelPressAKey.Key := FSaveGame.KeyAction2;
    PanelPressAKey.Show;
  end else
  if Sender = ButtonKeyPause then begin
    MouseInteractionEnabled := False;
    PanelPressAKey.Key := FSaveGame.KeyPause;
    PanelPressAKey.Show;
  end;
end;

procedure TOptionsPanel.ProcessCursorChange(Sender: TSimpleSurfaceWithEffect);
begin
  if Sender = CursorMusic then begin
    Audio.MusicVolume := CursorMusic.Position*0.01;
  end;

  if Sender = CursorSound then begin
    Audio.SoundVolume := CursorSound.Position*0.01;
    Audio.PlayUIClick;
  end;

  UpdateLabelVolume;
end;

procedure TOptionsPanel.FormatButtonKey(aButton: TUIButton; aIsAction: boolean);
var w: Integer;
begin
  if aIsAction then w := FKeyboardButtonSize*2
    else w := FKeyboardButtonSize;
  aButton.AutoSize := False;
  aButton.BodyShape.SetShapeRoundRect(w, FKeyboardButtonSize, PPIScale(8), PPIScale(8), 2);
  aButton.OnClick := @ProcessButtonClick;
  aButton.BodyShape.Fill.Color := BGRA(64,128,255);
  aButton.BodyShape.Border.Color := BGRA(32,64,128);
  aButton.Image.Tint.Value := BGRA(255,255,0);
end;

procedure TOptionsPanel.FormatLabelKey(aLabel: TUILabel);
begin
  aLabel.MouseInteractionEnabled := False;
  aLabel.Tint.Value := BGRA(255,255,0);
end;

procedure TOptionsPanel.UpdateLabelKeys;
begin
  LabelKeyUp.Caption := FScene.KeyToString[KeyUp];
  LabelKeyDown.Caption := FScene.KeyToString[KeyDown];
  LabelKeyLeft.Caption := FScene.KeyToString[KeyLeft];
  LabelKeyRight.Caption := FScene.KeyToString[KeyRight];
  LabelKeyAction1.Caption := FScene.KeyToString[KeyAction1];
  LabelKeyAction2.Caption := FScene.KeyToString[KeyAction2];
  LabelKeyPause.Caption := FScene.KeyToString[KeyPause];
end;

procedure TOptionsPanel.UpdateLabelVolume;
begin
  LabelCursorMusic.Caption := CursorMusic.Position.ToString+'%';
  LabelCursorSound.Caption := CursorSound.Position.ToString+'%';
end;

procedure TOptionsPanel.ProcessPressAKeyDone;
begin
  if FButtonEdited = ButtonKeyUp then begin
    FSaveGame.KeyUp := PanelPressAKey.Key;
  end else
  if FButtonEdited = ButtonKeyDown then begin
    FSaveGame.KeyDown := PanelPressAKey.Key;
  end else
  if FButtonEdited = ButtonKeyLeft then begin
    FSaveGame.KeyLeft := PanelPressAKey.Key;
  end else
  if FButtonEdited = ButtonKeyRight then begin
    FSaveGame.KeyRight := PanelPressAKey.Key;
  end else
  if FButtonEdited = ButtonKeyAction1 then begin
    FSaveGame.KeyAction1 := PanelPressAKey.Key;
  end else
  if FButtonEdited = ButtonKeyAction2 then begin
    FSaveGame.KeyAction2 := PanelPressAKey.Key;
  end else
  if FButtonEdited = ButtonKeyPause then begin
    FSaveGame.KeyPause := PanelPressAKey.Key;
  end;
  UpdateLabelKeys;
  MouseInteractionEnabled := True;
end;

procedure TOptionsPanel.ProcessLanguageChange(Sender: TSimpleSurfaceWithEffect);
begin
  FSaveGame.Language := AppLang.IndexToLanguageIdentifier(ListBoxLanguages.FirstSelectedIndex);
  FSaveGame.Save;
  FScene.RunScreen(ScreenTitle);
end;

constructor TOptionsPanel.Create(aFont: TTexturedFont);
var title, lab: TUILabel;
  i, h: integer;
begin
  inherited Create(Round(FScene.Width*0.7), Round(FScene.Height*0.7), aFont);

  BClose := TUIButton.Create(FScene, sClose, aFont, NIL);
  AddChild(BClose, 0);
  FormatButtonMenu(BClose);
  BClose.AnchorPosToParent(haRight, haRight, -ScaleW(10), vaBottom, vaBottom, -ScaleW(10));

  // label title
  title := TUILabel.Create(FScene, sOptions, aFont);
  AddChild(title, 0);
  title.Tint.Value := BGRA(255,255,50);
  title.AnchorPosToParent(haLeft, haLeft, ScaleW(10), vaTop, vaTop, ScaleW(10));
  title.MouseInteractionEnabled := False;

  // label music volume
  lab := TUILabel.Create(FScene, sMusicVolume, aFont);
  AddChild(lab, 0);
  lab.Tint.Value := BGRA(220,220,220);
  lab.AnchorPosToSurface(title, haLeft, haLeft, 0, vaTop, vaBottom, title.Height);
  lab.MouseInteractionEnabled := False;

  h := lab.Height;

  // cursor music volume
  CursorMusic := TUIScrollBar.Create(FScene, uioHorizontal);
  AddChild(CursorMusic, 0);
  CursorMusic.OnChange := @ProcessCursorChange;
  CursorMusic.BodyShape.SetShapeRoundRect(Width div 2-PPIScale(10)*2, lab.Height, PPIScale(8), PPIScale(8), PPIScale(2));
  CursorMusic.SetParams(80, 0, 125, 25);
  CursorMusic.AnchorHPosToParent(haLeft, haLeft, PPIScale(10));
  CursorMusic.AnchorVPosToSurface(lab, vatop, vaBottom, 0);
  LabelCursorMusic := TUILabel.Create(FScene, '', aFont);
  AddChild(LabelCursorMusic, 0);
  FormatLabelKey(LabelCursorMusic);
  LabelCursorMusic.AnchorPosToSurface(CursorMusic, haRight, haRight, 0, vaBottom, vaTop, 0);
  LabelCursorMusic.MouseInteractionEnabled := False;

  h := h + CursorMusic.Height;

  // label sound volume
  lab := TUILabel.Create(FScene, sSoundVolume, aFont);
  AddChild(lab, 0);
  lab.Tint.Value := BGRA(220,220,220);
  lab.AnchorPosToSurface(CursorMusic, haLeft, haLeft, 0, vaTop, vaBottom, lab.Height);
  lab.MouseInteractionEnabled := False;

  h := h + lab.Height;

  // cursor sound volume
  CursorSound := TUIScrollBar.Create(FScene, uioHorizontal);
  AddChild(CursorSound, 0);
  CursorSound.OnChange := @ProcessCursorChange;
  CursorSound.BodyShape.SetShapeRoundRect(Width div 2-PPIScale(10)*2, title.Height, PPIScale(8), PPIScale(8), PPIScale(2));
  CursorSound.SetParams(100, 0, 125, 25);
  CursorSound.AnchorHPosToParent(haLeft, haLeft, PPIScale(10));
  CursorSound.AnchorVPosToSurface(lab, vatop, vaBottom, 0);
  LabelCursorSound := TUILabel.Create(FScene, '', aFont);
  AddChild(LabelCursorSound, 0);
  FormatLabelKey(LabelCursorSound);
  LabelCursorSound.AnchorPosToSurface(CursorSound, haRight, haRight, 0, vaBottom, vaTop, 0);
  LabelCursorSound.MouseInteractionEnabled := False;

  h := h + CursorSound.Height;

  // label languages
  lab := TUILabel.Create(FScene, sLanguage, aFont);
  AddChild(lab, 0);
  lab.Tint.Value := BGRA(220,220,220);
  lab.AnchorHPosToParent(haLeft, haCenter, 0);
  lab.AnchorVPosToSurface(title, vaTop, vaBottom, title.Height);
  lab.MouseInteractionEnabled := False;

  // ListBoxLanguages
  ListBoxLanguages := TUIListBox.Create(FScene, aFont);
  AddChild(ListBoxLanguages, 0);
  ListBoxLanguages.BodyShape.SetShapeRoundRect(Width div 2-PPIScale(10)*2, h, PPIScale(8), PPIScale(8), PPIScale(2));
  ListBoxLanguages.AnchorPosToSurface(lab, haLeft, haLeft, 0, vaTop, vaBottom, 0);
  for i:=0 to Length(SupportedLanguages) div 2-1 do
    ListBoxLanguages.Add(SupportedLanguages[i*2]);
  ListBoxLanguages.FirstSelectedIndex := AppLang.LanguageIdentifierToIndex(FSaveGame.Language);
  ListBoxLanguages.OnSelectionChange := @ProcessLanguageChange;

  // label keyboard
  title := TUILabel.Create(FScene, sKeyboard, aFont);
  AddChild(title, 0);
  title.Tint.Value := BGRA(220,220,220);
  title.AnchorPosToSurface(CursorSound, haLeft, haLeft, 0, vaTop, vaBottom, title.Height);
  title.MouseInteractionEnabled := False;
  // label change key explanation
  lab := TUILabel.Create(FScene, sHowToChangeKey, aFont);
  AddChild(lab, 0);
  lab.Tint.Value := BGRA(180,180,180);
  lab.AnchorPosToSurface(title, haLeft, haLeft, 0, vaTop, vaBottom, 0);
  lab.MouseInteractionEnabled := False;

  FKeyboardButtonSize := Round(Width*0.07);
  FKeyboardButtonSpacing := FKeyboardButtonSize;
  texArrow := FScene.TexMan.AddFromSVG(SpriteCommonFolder+'LRArrow.svg', ScaleW(Round(FKeyboardButtonSize*0.8)), -1);

  // button key up
  ButtonKeyUp := TUIButton.Create(FScene, '', NIL, texArrow);
  AddChild(ButtonKeyUp, 0);
  FormatButtonKey(ButtonKeyUp);
  ButtonKeyUp.Image.Angle.Value := 270;
  ButtonKeyUp.AnchorHPosToParent(haLeft, haLeft, FKeyboardButtonSpacing*3);
  ButtonKeyUp.AnchorVPosToSurface(lab, vaTop, vaBottom, FKeyboardButtonSpacing);
  LabelKeyUp := TUILabel.Create(FScene, '', aFont);
  AddChild(LabelKeyUp, 0);
  FormatLabelKey(LabelKeyUp);
  LabelKeyUp.AnchorPosToSurface(ButtonKeyUp, haCenter, haCenter, 0, vaTop, vaBottom, 0);
  LabelKeyUp.MouseInteractionEnabled := False;

  // button key left
  ButtonKeyLeft := TUIButton.Create(FScene, '', NIL, texArrow);
  AddChild(ButtonKeyLeft, 0);
  FormatButtonKey(ButtonKeyLeft);
  ButtonKeyLeft.Image.Angle.Value := 180;
  ButtonKeyLeft.AnchorHPosToSurface(ButtonKeyUp, haRight, haLeft, -FKeyboardButtonSize);
  ButtonKeyLeft.AnchorVPosToSurface(ButtonKeyUp, vaTop, vaBottom, FKeyboardButtonSize div 2);
  LabelKeyLeft := TUILabel.Create(FScene, '', aFont);
  AddChild(LabelKeyLeft, 0);
  FormatLabelKey(LabelKeyLeft);
  LabelKeyLeft.AnchorPosToSurface(ButtonKeyLeft, haCenter, haCenter, 0, vaTop, vaBottom, 0);
  LabelKeyLeft.MouseInteractionEnabled := False;

  // button key right
  ButtonKeyRight := TUIButton.Create(FScene, '', NIL, texArrow);
  AddChild(ButtonKeyRight, 0);
  FormatButtonKey(ButtonKeyRight);
  ButtonKeyRight.Image.Angle.Value := 0;
  ButtonKeyRight.AnchorHPosToSurface(ButtonKeyUp, haLeft, haRight, FKeyboardButtonSize);
  ButtonKeyRight.AnchorVPosToSurface(ButtonKeyLeft, vaTop, vaTop, 0);
  LabelKeyRight := TUILabel.Create(FScene, '', aFont);
  AddChild(LabelKeyRight, 0);
  FormatLabelKey(LabelKeyRight);
  LabelKeyRight.AnchorPosToSurface(ButtonKeyRight, haCenter, haCenter, 0, vaTop, vaBottom, 0);
  LabelKeyRight.MouseInteractionEnabled := False;

  // button key down
  ButtonKeyDown := TUIButton.Create(FScene, '', NIL, texArrow);
  AddChild(ButtonKeyDown, 0);
  FormatButtonKey(ButtonKeyDown);
  ButtonKeyDown.Image.Angle.Value := 90;
  ButtonKeyDown.AnchorHPosToSurface(ButtonKeyUp, haLeft, haLeft, 0);
  ButtonKeyDown.AnchorVPosToSurface(ButtonKeyRight, vaTop, vaBottom, FKeyboardButtonSize div 2);
  LabelKeyDown := TUILabel.Create(FScene, '', aFont);
  AddChild(LabelKeyDown, 0);
  FormatLabelKey(LabelKeyDown);
  LabelKeyDown.AnchorPosToSurface(ButtonKeyDown, haCenter, haCenter, 0, vaTop, vaBottom, 0);
  LabelKeyDown.MouseInteractionEnabled := False;

  // button Action1
  ButtonKeyAction1 := TUIButton.Create(FScene, sAction1, aFont, NIL);
  AddChild(ButtonKeyAction1, 0);
  FormatButtonKey(ButtonKeyAction1, True);
  ButtonKeyAction1.AnchorHPosToSurface(ButtonKeyRight, haLeft, haRight, FKeyboardButtonSpacing*2);
  ButtonKeyAction1.AnchorVPosToSurface(ButtonKeyUp, vaTop, vaTop, 0);
  LabelKeyAction1 := TUILabel.Create(FScene, '', aFont);
  AddChild(LabelKeyAction1, 0);
  FormatLabelKey(LabelKeyAction1);
  LabelKeyAction1.AnchorPosToSurface(ButtonKeyAction1, haCenter, haCenter, 0, vaTop, vaBottom, 0);
  LabelKeyAction1.MouseInteractionEnabled := False;

  // button Action2
  ButtonKeyAction2 := TUIButton.Create(FScene, sAction2, aFont, NIL);
  AddChild(ButtonKeyAction2, 0);
  FormatButtonKey(ButtonKeyAction2, True);
  ButtonKeyAction2.AnchorPosToSurface(ButtonKeyAction1, haLeft, haRight, FKeyboardButtonSpacing, vaTop, vaTop, 0);
  LabelKeyAction2 := TUILabel.Create(FScene, '', aFont);
  AddChild(LabelKeyAction2, 0);
  FormatLabelKey(LabelKeyAction2);
  LabelKeyAction2.AnchorPosToSurface(ButtonKeyAction2, haCenter, haCenter, 0, vaTop, vaBottom, 0);
  LabelKeyAction2.MouseInteractionEnabled := False;

  // button Pause
  ButtonKeyPause := TUIButton.Create(FScene, sPause, aFont, NIL);
  AddChild(ButtonKeyPause, 0);
  FormatButtonKey(ButtonKeyPause, True);
  ButtonKeyPause.AnchorPosToSurface(ButtonKeyAction1, haLeft, haLeft, 0, vaTop, vaBottom, FKeyboardButtonSpacing);
  LabelKeyPause := TUILabel.Create(FScene, '', aFont);
  AddChild(LabelKeyPause, 0);
  FormatLabelKey(LabelKeyPause);
  LabelKeyPause.AnchorPosToSurface(ButtonKeyPause, haCenter, haCenter, 0, vaTop, vaBottom, 0);
  LabelKeyPause.MouseInteractionEnabled := False;

  PanelPressAKey := TPressAKeyPanel.Create(aFont, @ProcessPressAKeyDone);
end;

destructor TOptionsPanel.Destroy;
begin
  FScene.TexMan.Delete(texArrow);
  inherited Destroy;
end;

procedure TOptionsPanel.Show;
begin
  inherited Show;
  CursorMusic.Position := Trunc(FSaveGame.MusicVolume*100);
  CursorSound.Position := Trunc(FSaveGame.SoundVolume*100);
  UpdateWidget;
end;

procedure TOptionsPanel.Hide(aFree: boolean);
begin
  inherited Hide(aFree);
  ScreenTitle.SetMenuButtonVisible(True);
end;

procedure TOptionsPanel.UpdateWidget;
begin
  UpdateLabelKeys;
  UpdateLabelVolume;
end;

{ TContinuePanel }

procedure TContinuePanel.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  Audio.PlayUIClick;
  if Sender = BContinue then begin
    if FLBPlayers.SelectedCount = 0 then exit;
    FSaveGame.SetCurrentPlayerIndex(FLBPlayers.FirstSelectedIndex);
    FScene.RunScreen(ScreenMap);
  end
  else
  if Sender = BBack then begin
    Hide(False);
  end
  else
  if Sender = BDelete then begin
    if FLBPlayers.SelectedCount = 0 then exit;
    FSaveGame.DeletePlayer(FLBPlayers.FirstSelectedIndex);
    FLBPlayers.Delete(FLBPlayers.FirstSelectedIndex);
  end;
end;

constructor TContinuePanel.Create(aFont: TTexturedFont);
var title: TUILabel;
begin
  inherited Create(Round(FScene.Width*0.7), Round(FScene.Height*0.5), aFont);

  BDelete := TUIButton.Create(FScene, sDelete, aFont, texTrashCan);
  AddChild(BDelete, 0);
  FormatButtonMenu(BDelete);
  BDelete.AnchorPosToParent(haRight, haRight, -ScaleW(10), vaTop, vaTop, ScaleW(10));

  // label title
  title := TUILabel.Create(FScene, SChoosePlayer, aFont);
  AddChild(title, 0);
  title.Tint.Value := BGRA(255,255,50);
  title.AnchorHPosToParent(haLeft, haLeft, ScaleW(10));
  title.AnchorVPosToSurface(BDelete, vaBottom, vaBottom, 0);

  // player list
  FLBPlayers := TUIListBox.Create(FScene, aFont);
  AddChild(FLBPlayers, 0);
  FLBPlayers.BodyShape.SetShapeRoundRect(Width-ScaleW(10)*2, Round(Height-BDelete.Height*2-ScaleW(10)*3), PPIScale(8), PPIScale(8), 2);
  //FLBPlayers.ItemColor;
  FLBPlayers.AnchorHPosToParent(haCenter, haCenter, 0);
  FLBPlayers.AnchorVPosToSurface(BDelete, vaTop, vaBottom, 0);

  BContinue := TUIButton.Create(FScene, sContinue, aFont, NIL);
  AddChild(BContinue, 0);
  FormatButtonMenu(BContinue);
  BContinue.AnchorPosToSurface(FLBPlayers, haRight, haRight, 0, vaTop, vaBottom, ScaleW(10));

  BBack := TUIButton.Create(FScene, sBack, aFont, NIL);
  AddChild(BBack, 0);
  FormatButtonMenu(BBack);
  BBack.AnchorPosToSurface(FLBPlayers, haLeft, haLeft, 0, vaTop, vaBottom, ScaleW(10));
end;

procedure TContinuePanel.Show;
begin
  inherited Show;
  UpdatePlayerList;
end;

procedure TContinuePanel.Hide(aFree: boolean);
begin
  inherited Hide(aFree);
  ScreenTitle.SetMenuButtonVisible(True);
end;

procedure TContinuePanel.UpdatePlayerList;
begin
  FLBPlayers.Clear;
  FLBPlayers.Append(FSaveGame.GetPlayersInfo);
end;

{ TCenteredGameUIPanel }

procedure TCenteredGameUIPanel.FormatButtonMenu(aButton: TUIButton);
begin
  aButton.AutoSize := False;
  aButton.BodyShape.SetShapeRoundRect(Round(Width*0.28), Round(FFont.Font.FontHeight*1.5), PPIScale(8), PPIScale(8), 2);
  aButton.BodyShape.Fill.Color := BGRA(255,128,64);
  aButton.BodyShape.Border.Color := BGRA(128,64,32);
  aButton.OnClick := @ProcessButtonClick;
end;

constructor TCenteredGameUIPanel.Create(aWidth, aHeight: integer; aFont: TTexturedFont);
begin
  inherited Create(aWidth, aHeight);
  FFont := aFont;
  CenterOnScene;
end;

{ TNewPlayerPanel }

procedure TNewPlayerPanel.FormatButtonKeyboard(aButton: TUIButton);
begin
  aButton.AutoSize := False;
  aButton.BodyShape.SetShapeRoundRect(FKeyboardButtonSize, FKeyboardButtonSize,
                                      PPIScale(8), PPIScale(8), 2);
  aButton.BodyShape.Fill.Color := BGRA(128,255,64);
  aButton.BodyShape.Border.Color := BGRA(64,128,32);
  aButton.OnClick := @ProcessButtonClick;
end;

procedure TNewPlayerPanel.FormatBigButtonKeyboard(aButton: TUIButton);
begin
  aButton.AutoSize := False;
  aButton.BodyShape.SetShapeRoundRect(FKeyboardButtonSize*2+FKeyboardButtonSpacing, FKeyboardButtonSize,
                                      PPIScale(8), PPIScale(8), 2);
  aButton.BodyShape.Fill.Color := BGRA(64,128,255);
  aButton.BodyShape.Border.Color := BGRA(32,64,128);
  aButton._Label.Tint.Value := BGRA(255,255,255);
  aButton.OnClick := @ProcessButtonClick;
end;

procedure TNewPlayerPanel.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  Audio.PlayUIClick;
  if Sender = BStart then begin
    if Length(Trim(FName.Caption)) = 0 then exit;
    ScreenTitle.CreateNewPlayer(FName.Caption);
    Hide(False);
  end
  else
  if Sender = BBack then begin
    Hide(False);
  end
  else
  if Sender = BErase then begin
    if Length(FName.Caption) = 0 then exit;
    FName.Caption := Copy(FName.Caption, 1, Length(FName.Caption)-1);
  end
  else begin
    //keyboard
    FName.Caption := FName.Caption + SIMPLELATIN_CHARSET[Sender.Tag1];
  end;
end;

constructor TNewPlayerPanel.Create(aFont: TTexturedFont);
const KEY_PER_LINE = 11;
var xx, yy, delta: single;
  i: Integer;
  title: TUILabel;
  b: TUIButton;
  arrow: TSprite;
begin
  inherited Create(Round(FScene.Width*0.7), Round(FScene.Height*0.7), aFont);

  BStart := TUIButton.Create(FScene, sStart, aFont, NIL);
  AddChild(BStart, 0);
  FormatButtonMenu(BStart);
  BStart.AnchorPosToParent(haRight, haRight, -PPIScale(10), vaBottom, vaBottom, -PPIScale(10));

  BBack := TUIButton.Create(FScene, sBack, aFont, NIL);
  AddChild(BBack, 0);
  FormatButtonMenu(BBack);
  BBack.AnchorPosToParent(haLeft, haLeft, PPIScale(10), vaBottom, vaBottom, -PPIScale(10));

  // keyboard buttons
  xx := PPIScale(10);
  yy := PPIScale(10);
  delta := (Width-PPIScale(10)) / KEY_PER_LINE;
  FKeyboardButtonSize := Round(delta)-PPIScale(10);
  FKeyboardButtonSpacing := PPIScale(10);
  i := 1;
  while i < 62 do begin
    b := TUIButton.Create(FScene, SIMPLELATIN_CHARSET[i+1], aFont, NIL);
    AddChild(b, 0);
    b.Tag1 := i+1;
    FormatButtonKeyboard(b);
    b.SetCoordinate(xx, yy);
    xx := xx + delta;
    inc(i);
    if i mod KEY_PER_LINE = 0 then begin
      xx := PPIScale(10);
      yy := yy + delta;
    end;
  end;
  // SPACE
  b := TUIButton.Create(FScene, sSpace, aFont, NIL);
  AddChild(b, 0);
  b.Tag1 := 1;
  FormatBigButtonKeyboard(b);
  b.SetCoordinate(xx, yy);
  xx := xx + delta*2;

  // ERASE
  BErase := TUIButton.Create(FScene, '', aFont, NIL);
  AddChild(BErase, 0);
  FormatBigButtonKeyboard(BErase);
  BErase.SetCoordinate(xx, yy);
  arrow := TSprite.Create(FScene.TexMan.AddFromSVG(SpriteCommonFolder+'LRArrow.svg', ScaleW(FKeyboardButtonSize*2), -1), True);
  BErase.AddChild(arrow);
  arrow.Tint.Value := BGRA(180,180,200);
  arrow.FlipH := True;
  arrow.CenterOnParent;

  // label enter your name
  title := TUILabel.Create(FScene, SEnterYourName, aFont);
  AddChild(title, 0);
  title.Tint.Value := BGRA(255,255,50);
  title.SetCoordinate(PPIScale(10), yy+delta);
  //title.AnchorToParent(haLeft, haLeft, PPIScale(10), vaNone, vaTop, PPIScale(10));

  // panel Name
  FPanelName := TUIPanel.Create(FScene);
  AddChild(FPanelName, 0);
  FPanelName.AnchorPosToSurface(title, haLeft, haLeft, 0, vaTop, vaBottom, 0);
  FPanelName.BodyShape.SetShapeRectangle(Width-PPIScale(10)*2, Round(aFont.Font.FontHeight*1.5), 2);
  FPanelName.BodyShape.Fill.Color := BGRA(0,0,0);
  FPanelName.BodyShape.Border.Color := BGRA(0,0,0);
  // label name
  FName := TUILabel.Create(FScene, '', aFont);
  FPanelName.AddChild(FName, 0);
  FName.SetCoordinate(PPIScale(10), aFont.Font.FontHeight*0.25);
  FName.Tint.Value := BGRA(255,255,255);
  //Cursor shape
  FCursor := TShapeOutline.Create(FScene);
  FPanelName.AddChild(FCursor, 1);
  FCursor.SetShapeRectangle(0, aFont.Font.FontHeight*0.25, ScaleW(2), aFont.Font.FontHeight);
  FCursor.LineWidth := 1;
  FCursor.LineColor := BGRA(255,255,255);
  FCursor.Blink(-1, 0.4, 0.4);
end;

procedure TNewPlayerPanel.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  FCursor.X.Value := FName.RightX;
end;

procedure TNewPlayerPanel.Show;
begin
  FName.Caption := '';
  inherited Show;
end;

procedure TNewPlayerPanel.Hide(aFree: boolean);
begin
  inherited Hide(aFree);
  ScreenTitle.SetMenuButtonVisible(True);
end;


end.

