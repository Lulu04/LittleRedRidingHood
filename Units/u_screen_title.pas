unit u_screen_title;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_sprite_lrcommon, u_sprite_wolf, u_ui_panels, ALSound;

type

{ TScreenTitle }

TScreenTitle = class(TScreenTemplate)
private
  FAtlas: TOGLCTextureAtlas;
  FFontTitleSmallPart,
  FFontTitleBigPart,
  FFontButton,
  FFontText: TTexturedFont;
  FCastle: TSprite;
  FTitle1, FTitle2, FTitle3: TFreeText;
  BNewPlayer, BContinue, BOptions, BCredits, BQuit: TUIButton;
  NewPlayerPanel: TNewPlayerPanel;
  ContinuePanel: TContinuePanel;
  OptionsPanel: TOptionsPanel;
  CreditsPanel: TCreditsPanel;
  procedure ProcessButtonClick(aUISurface: TSimpleSurfaceWithEffect);
public
  procedure SetMenuButtonVisible(aValue: boolean);
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure CreateNewPlayer(const aName: string);
end;

var ScreenTitle: TScreenTitle;

implementation
uses Forms, u_sprite_gameforest, u_app, form_main, u_gamebackground,
  u_resourcestring, u_screen_map, u_mousepointer, u_common_ui, u_audio;

{ TScreenTitle }

procedure TScreenTitle.SetMenuButtonVisible(aValue: boolean);
begin
  BNewPlayer.Visible := aValue;
  BNewPlayer.MouseInteractionEnabled := aValue;
  BContinue.Visible := aValue;
  BContinue.MouseInteractionEnabled := aValue;
  BOptions.Visible := aValue;
  BOptions.MouseInteractionEnabled := aValue;
  BCredits.Visible := aValue;
  BCredits.MouseInteractionEnabled := aValue;
  BQuit.Visible := aValue;
  BQuit.MouseInteractionEnabled := aValue;
end;

procedure TScreenTitle.ProcessButtonClick(aUISurface: TSimpleSurfaceWithEffect);
begin
  Audio.PlayUIClick;
  if aUISurface = BNewPlayer then begin
    SetMenuButtonVisible(False);
    NewPlayerPanel.Show;
  end else
  if aUISurface = BContinue then begin
    SetMenuButtonVisible(False);
    ContinuePanel.Show;
  end else
  if aUISurface = BOptions then begin
    SetMenuButtonVisible(False);
    OptionsPanel.Show;
  end else
  if aUISurface = BCredits then begin
    SetMenuButtonVisible(False);
    CreditsPanel.Show;
  end  else
  if aUISurface = BQuit then begin
    BQuit.MouseInteractionEnabled := False;
    PostMessage(300);
  end;
end;

procedure TScreenTitle.CreateNewPlayer(const aName: string);
begin
  FSaveGame.CreateNewPlayer(aName);
  FScene.RunScreen(ScreenMap);
end;

procedure TScreenTitle.CreateObjects;
var o: TLRFrontView;
  w: TWolf;
  ima: TBGRABitmap;
  g: TGround1;
  fd: TFontDescriptor;
  sky: TMultiColorRectangle;
  i, xx: integer;
  yy: single;
  t: PTexture;
  fontName: string;
begin
  {$if defined(Windows)}
  fontName := 'Comic Sans MS';
  {$else}
  fontName := 'Comic Sans MS'; //'Arial';
  {$endif}
  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  AdditionnalScale := 2.2;

  LoadLRFaceTextures(FAtlas);
  LoadLRFrontViewTextures(FAtlas);

//LoadTexturesForForestGame(FAtlas);
  LoadWolfTextures(FAtlas);
  AdditionnalScale := 1;
  LoadBaseBallonTexture(FAtlas);
  LoadCloudsTexture(FAtlas);
  LoadGround1Texture(FAtlas);
  texPine := FAtlas.AddFromSVG(SpriteBGFolder+'TreePine.svg', ScaleW(100), -1);

  fd.Create(fontName, Round(FScene.Height/13), [], BGRA(255,128,64), BGRA(0,0,0), ScaleH(3));
  FFontTitleSmallPart := FAtlas.AddTexturedFont(fd, TitleSmallPartCharSet);

  fd.Create(fontName, Round(FScene.Height/7), [], BGRA(255,50,10), BGRA(0,0,0), ScaleH(5));
  FFontTitleBigPart := FAtlas.AddTexturedFont(fd, TitleBigPartCharSet);

  FFontText := CreateGameFontText(FAtlas);
  FFontButton := CreateGameFontButton(FAtlas, TitleButtonCharset);
  LoadTitleScreenIcon(FAtlas, FFontButton.Font.FontHeight);

  LoadMousePointerTexture(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;
  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  // sky
  sky := TMultiColorRectangle.Create(FScene.Width, FScene.Height);
  sky.SetTopColors(BGRA(110,142,255));
  sky.SetBottomColors(BGRA(13,31,178)); //(BGRA(65,209,99)); //(BGRA(8,242,130));
  FScene.Add(sky, LAYER_BG2);

  // clouds
  for i:=0 to 15 do TCloud.Create(Random*FScene.Width, Random*FScene.Height*0.2, 0.6, -1);
  for i:=0 to 8 do TCloud.Create(Random*FScene.Width, Random*FScene.Height*0.2, 0.4, -1);
  //for i:=0 to 4 do TCloud.Create(Random*FScene.Width, Random*FScene.Height*0.2, 0, -1);
  TCloud.Create(0, 0, 0, -1);
  TCloud.Create(FScene.Width*0.3, FScene.Height*0.15, 0, -1);
  TCloud.Create(FScene.Width*0.75, FScene.Height*0.25, 0, -1);
  TCloud.Create(FScene.Width*0.5, FScene.Height*0.05, 0, -1);
  TCloud.Create(FScene.Width*1, FScene.Height*0.1, 0, -1);

  // title
  FTitle1 := TFreeText.Create(FScene);
  FScene.Add(FTitle1, LAYER_GAMEUI);
  FTitle1.TexturedFont := FFontTitleSmallPart;
  FTitle1.Caption := sTheNewStoryOf;
  FTitle1.SetCoordinate(FScene.Width/15, FScene.Height/10);
  yy := FTitle1.Y.Value + FFontTitleSmallPart.Font.FontHeight;

  FTitle2 := TFreeText.Create(FScene);
  FScene.Add(FTitle2, LAYER_GAMEUI);
  FTitle2.TexturedFont := FFontTitleBigPart;
  FTitle2.Caption := sTheLittleRed;
  FTitle2.SetCoordinate(FScene.Width*3/15, yy);
  yy := FTitle2.Y.Value + FFontTitleBigPart.Font.FontHeight;

  FTitle3 := TFreeText.Create(FScene);
  FScene.Add(FTitle3, LAYER_GAMEUI);
  FTitle3.TexturedFont := FFontTitleBigPart;
  FTitle3.Caption := sRidingHood;
  FTitle3.SetCoordinate(FScene.Width*0.95-FTitle3.Width, yy);

  // buttons
  BNewPlayer := TUIButton.Create(FScene, sNewGame, FFontButton, NIL);
  FScene.Add(BNewPlayer, LAYER_GAMEUI);
  BNewPlayer.BodyShape.SetShapeRoundRect(20, 20, PPIScale(8), PPIScale(8), 4);
  BNewPlayer._Label.Tint.Value := BGRA(255,255,150);
  BNewPlayer.OnClick := @ProcessButtonClick;
  BNewPlayer.CenterX := FScene.Width*0.5;

  BContinue := TUIButton.Create(FScene, sContinueGame, FFontButton, NIL);
  FScene.Add(BContinue, LAYER_GAMEUI);
  BContinue.BodyShape.SetShapeRoundRect(20, 20, PPIScale(8), PPIScale(8), 4);
  BContinue._Label.Tint.Value := BGRA(255,255,150);
  BContinue.OnClick := @ProcessButtonClick;
  BContinue.CenterX := FScene.Width*0.5;

  BOptions := TUIButton.Create(FScene, sOptions, FFontButton, NIL);
  FScene.Add(BOptions, LAYER_GAMEUI);
  BOptions.BodyShape.SetShapeRoundRect(20, 20, PPIScale(8), PPIScale(8), 4);
  BOptions._Label.Tint.Value := BGRA(255,255,150);
  BOptions.OnClick := @ProcessButtonClick;
  BOptions.CenterX := FScene.Width*0.5;

  BCredits := TUIButton.Create(FScene, sCredits, FFontButton, NIL);
  FScene.Add(BCredits, LAYER_GAMEUI);
  BCredits.BodyShape.SetShapeRoundRect(20, 20, PPIScale(8), PPIScale(8), 4);
  BCredits._Label.Tint.Value := BGRA(255,255,150);
  BCredits.OnClick := @ProcessButtonClick;
  BCredits.CenterX := FScene.Width*0.5;

  BQuit := TUIButton.Create(FScene, sQuit, FFontButton, NIL);
  FScene.Add(BQuit, LAYER_GAMEUI);
  BQuit.BodyShape.SetShapeRoundRect(20, 20, PPIScale(8), PPIScale(8), 4);
  BQuit._Label.Tint.Value := BGRA(255,255,150);
  BQuit.OnClick := @ProcessButtonClick;
  BQuit.CenterX := FScene.Width*0.5;

  BQuit.BottomY := FScene.Height - BQuit.Height*0.5; // margin+delta*3;
  BCredits.BottomY := BQuit.Y.Value - BQuit.Height*0.5;
  BOptions.BottomY := BCredits.Y.Value - BCredits.Height*0.5;
  BContinue.BottomY := BOptions.Y.Value - BOptions.Height*0.5;
  BNewPlayer.BottomY := BContinue.Y.Value - BContinue.Height*0.5;

  // panel new player
  NewPlayerPanel := TNewPlayerPanel.Create(FFontText);
  // panel continue game
  ContinuePanel := TContinuePanel.Create(FFontText);
  // panel options
  OptionsPanel := TOptionsPanel.Create(FFontText);
  // panel credits
  CreditsPanel := TCreditsPanel.Create(FFontText);

  // ground at the bottom of the screen
  xx := -5;
  while xx < FScene.Width do begin
    g := TGround1.Create;
    g.SetCoordinate(xx, FScene.Height-g.Height*0.75);
    xx := xx + g.Width;
  end;

  // castle
  t := FScene.TexMan.AddFromSVG(SpriteBGFolder+'WolfCastle.svg', Round(FScene.Width*2/3), -1);
  FCastle := TSprite.Create(t, True);
  FScene.Add(FCastle, LAYER_BG1);
  FCastle.RightX := FScene.Width*0.99;
  //FCastle.CenterX := FScene.Width*0.5;
  FCastle.BottomY := g.Y.Value;

  // pines forest
  yy := FScene.Height-g.Height*0.75;
  TPine.Create(FScene.Width*0.98, yy, 0.2);
  TPine.Create(FScene.Width*0.95, yy, 0.3);
  TPine.Create(FScene.Width*0.83, yy, 0.35);
  TPine.Create(FScene.Width*0.9, yy, 0);
  TPine.Create(FScene.Width*0.8, yy, 0.05);

  o := TLRFrontView.Create;
  FScene.Add(o, LAYER_PLAYER);
  o.SetCoordinateByFeet(FScene.Width*0.15, FScene.Height*0.98);
  o.Face.FaceType := lrfSmile;

  w := TWolf.Create(False);
  w.SetCoordinate(FScene.Width*0.85, FScene.Height-w.DeltaYToBottom-g.Height*0.45);
  w.Head.SetMouthClose;
  w.TimeMultiplicator:=1.0;
  w.State := wsIdle;
 // w.FlipH:=true;
  //w.PostMessage(1000, 6);
 // w.Head.SetMouthTongue;
 // w.Head.SetMouthHurt;

 // w.Abdomen.Angle.ChangeTo(-10, 5);

  CustomizeMousePointer;
end;

procedure TScreenTitle.FreeObjects;
begin
  FreeMousePointer;
  FScene.ClearAllLayer;
  FreeAndNil(FAtlas);
end;

procedure TScreenTitle.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue); // keep this line please
  case UserValue of
    // QUIT
    300: begin
      FScene.ColorFadeIn(BGRA(0,0,0), 0.3);
      PostMessage(301, 0.3);
    end;
    301: begin
      FormMain.Close;
    end;
  end;
end;


end.

