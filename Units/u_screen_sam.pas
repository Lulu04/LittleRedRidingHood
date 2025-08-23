unit u_screen_sam;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_gamescreentemplate, u_common, u_common_ui, u_sprite_lrcommon, u_audio, ALSound;

type

  { TScreenSamHome }

  TScreenSamHome = class(TGameScreenTemplate)
  private
    BExit, BGame1, BGameDartboard: TImageButton;
    procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
    procedure ProcessClickOnScene({%H-}Button: TMouseButton; {%H-}Shift: TShiftState; X, Y: Integer);
  public
    procedure DefineSubTextures(aAtlas: TAtlas); override;
    procedure CreateObjects; override;
    procedure FreeObjects; override;
    procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  end;

var ScreenSamHome: TScreenSamHome;
  FPlayerPlaySamsGame: boolean=False;
  FPlayerSamsGameScore: integer;

implementation
uses u_app, u_resourcestring, u_screen_map, u_mousepointer, u_sprite_def2,
  u_sam, u_screen_strikeraccoon, u_ui_panels, u_screen_dartboard, u_utils, Math;

type

TTradeItem = class(TUIPanel)
private
  FIconWanted, FIconToGive: TSprite;
  FLabelWantedCount, FLabelToGiveCount: TUILabel;
  BTrade: TUIButton;
  FWantedMoney, FToGiveMonney: TMoneyType;
  FWantedAmount, FToGiveAmount: integer;
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
  procedure ProcessMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
public
  constructor Create(aWidth, aHeight: integer; aWantedMoney,
                     aToGiveMoney: TMoneyType; texItemWanted, texItemToGive: PTexture;
                     aWantedAmount, aToGiveAmount: integer);
  procedure UpdatePossibleTransaction;
end;

TPanelItems = class(TUIScrollBox)
private
  FCurrentY: single;
public
  constructor Create(aX, aY: single);
  function AddItem(aWantedMoney, aToGiveMoney: TMoneyType; aWantedAmount, aToGiveAmount: integer): TTradeItem;

  procedure UpdatePossibleTransactions;
end;



TPanelChoosePrize = class(TUIModalPanel)
private
  BCoin, BPurpleCristal: TUIButton;
  FKeyboardToButtons: TButtonsClickableByKeyboard;
  procedure FormatButton(aButton: TUIButton);
  function GetCoinGain: integer;
  function GetPurpleCristalGain: integer;
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
public
  constructor Create;
end;


TGameInventory = class(TInGameInventoryPanel)
  CoinCounter: TUICoinCounter;
  PurpleCristalCounter: TUIPurpleCristalCounter;
  constructor Create;
  procedure Exchange(aWantedMoney, aToGiveMonney: TMoneyType; aWantedAmount,
    aToGiveAmount: integer);
end;

TSeagull = class(TSeagullBase)
private
  procedure ComputeY;
public
  constructor Create(aParent: TUIImage; aSpeedX: single);
  procedure Update(const aElapsedTime: single); override;
end;

var texSamHomeInner, texDoor, texBarrel, texDartboard,
  //texCoin, texSmallCristalGray,
  texCoinBig, texSmallCristalGrayBig,
  texLRIcon: PTexture;
  FFontText: TTexturedFont;
  FAtlas: TOGLCTextureAtlas;
  FSam: TSam;
  FGameinventory: TGameInventory;
  FPanelItems: TPanelItems;
  FItemHeight: integer;
  FsndMusic: TALSSound;

{ TTradeItem }

procedure TTradeItem.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  FGameinventory.Exchange(FWantedMoney, FToGiveMonney, FWantedAmount, FToGiveAmount);
  FPanelItems.UpdatePossibleTransactions;
end;

procedure TTradeItem.ProcessMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  FPanelItems.DoOnMouseWheel(Shift, WheelDelta, MousePos, Handled);
end;

constructor TTradeItem.Create(aWidth, aHeight: integer; aWantedMoney,
  aToGiveMoney: TMoneyType; texItemWanted, texItemToGive: PTexture;
  aWantedAmount, aToGiveAmount: integer);
begin
  inherited Create(FScene);
  BodyShape.SetShapeRectangle(aWidth, aHeight, 0);
  BodyShape.Fill.Color := BGRA(30,20,20);
  OnMouseWheel := @ProcessMouseWheel;

  FWantedMoney := aWantedMoney;
  FToGiveMonney := aToGiveMoney;
  FWantedAmount := aWantedAmount;
  FToGiveAmount := aToGiveAmount;

  //
  FLabelWantedCount := TUILabel.Create(FScene, sSamGiveYou+' '+ aWantedAmount.ToString+' x ', FFontText);
  AddChild(FLabelWantedCount, 0);
  FLabelWantedCount.Tint.Value := BGRA(220,220,220);
  FLabelWantedCount.X.Value := PPIScale(60);
  FLabelWantedCount.CenterY := Height*0.5;

  FIconWanted := TSprite.Create(texItemWanted, False);
  AddChild(FIconWanted, 0);
  FIconWanted.SetSize(-1, aHeight-PPIScale(20));
  FIconWanted.X.Value := FLabelWantedCount.RightX + PPIScale(5);
  FIconWanted.CenterY := Height*0.5;
  if aWantedMoney = mtPurpleCristal then FIconWanted.Tint.Value := BGRA(255,0,255,150);

  FLabelToGiveCount := TUILabel.Create(FScene, sFor+'  '+ aToGiveAmount.ToString+' x ', FFontText);
  AddChild(FLabelToGiveCount, 0);
  FLabelToGiveCount.Tint.Value := BGRA(220,220,220);
  FLabelToGiveCount.X.Value := FIconWanted.RightX + PPIScale(15);
  FLabelToGiveCount.CenterY := Height*0.5;

  FIconToGive := TSprite.Create(texItemToGive, False);
  AddChild(FIconToGive, 0);
  FIconToGive.SetSize(-1, aHeight-PPIScale(20));
  FIconToGive.X.Value := FLabelToGiveCount.RightX + PPIScale(5);
  FIconToGive.CenterY := Height*0.5;
  if aToGiveMoney = mtPurpleCristal then FIconToGive.Tint.Value := BGRA(255,0,255,150);

  // button trade
  BTrade := TUIButton.Create(FScene, sExchange, FFontText, NIL);
  AddChild(BTrade, 0);
  BTrade.BodyShape.SetShapeRoundRect(20, 20, PPIScale(8), PPIScale(8), PPIScale(2));
  BTrade._Label.Tint.Value := BGRA(255,255,0);
  BTrade.OnClick := @ProcessButtonClick;
  BTrade.X.Value := Width*0.5; // FIconToGive.RightX + PPIScale(5);
  BTrade.CenterY := Height*0.5;

end;

procedure TTradeItem.UpdatePossibleTransaction;
var owned: integer;
begin
  case FToGiveMonney of
    mtCoin: owned := PlayerInfo.CoinCount;
    mtPurpleCristal: owned := PlayerInfo.PurpleCristalCount;
    else raise exception.create('forgot to implement!');
  end;

  if owned < FToGiveAmount then begin
    BTrade.BodyShape.Fill.Color := BGRA(255,20,20);
    BTrade.MouseInteractionEnabled := False;
  end else begin
    BTrade.BodyShape.Fill.Color := BGRA(30,30,30);
    BTrade.MouseInteractionEnabled := True;
  end;
end;

{ TPanelItems }

constructor TPanelItems.Create(aX, aY: single);
begin
  inherited Create(FScene, True, False);
  FScene.Add(Self, LAYER_GAMEUI);
  BodyShape.SetShapeRoundRect(FScene.Width, Round(FScene.Height-aY), PPIScale(8), PPIScale(8), PPIScale(2));
  BackGradient.CreateHorizontal([BGRA(255,0,255,10), BGRA(255,0,255,40), BGRA(255,0,255,10)],[0, 0.5, 1]);
  SetCoordinate(aX, aY);
  VScrollBarMode := sbmAlwaysShow;
  FCurrentY := 0;
end;

function TPanelItems.AddItem(aWantedMoney, aToGiveMoney: TMoneyType;
  aWantedAmount, aToGiveAmount: integer): TTradeItem;
var texWanted, texToGive: PTexture;
begin
  case aWantedMoney of
    mtCoin: texWanted := texCoinBig;
    mtPurpleCristal: texWanted := texSmallCristalGrayBig;
    else raise exception.create('forgot to implement!');
  end;

  case aToGiveMoney of
    mtCoin: texToGive := texCoinBig;
    mtPurpleCristal: texToGive := texSmallCristalGrayBig;
    else raise exception.create('forgot to implement!');
  end;

  Result := TTradeItem.Create(ClientArea.Width-PPIScale(10), FItemHeight,
                              aWantedMoney, aToGiveMoney,
                              texWanted, texToGive,
                              aWantedAmount, aToGiveAmount);
  AddChild(Result);
  Result.SetCoordinate(0, FCurrentY);
  FCurrentY := FCurrentY + FItemHeight + PPIScale(10);
end;

procedure TPanelItems.UpdatePossibleTransactions;
var i: integer;
begin
  for i:=0 to ChildCount-1 do
    if Childs[i] is TTradeItem then
      TTradeItem(Childs[i]).UpdatePossibleTransaction;
end;

{ TGameInventory }

constructor TGameInventory.Create;
var o: TSprite;
begin
  inherited Create;

  if PlayerInfo.Forest.IsTerminated then begin
    PurpleCristalCounter := TUIPurpleCristalCounter.Create;
    AddItem(PurpleCristalCounter);
    PurpleCristalCounter.Count := PlayerInfo.PurpleCristalCount;
  end;

  CoinCounter := TUICoinCounter.Create;
  AddItem(CoinCounter);
  CoinCounter.Count := PlayerInfo.CoinCount;

  // LR icon
  o := TSprite.Create(texLRIcon, False);
  FScene.Add(o, LAYER_GAMEUI);
  o.SetCoordinate(PPIScale(20), ScaleH(297));

  ResizeAndPlace;
  SetCoordinate(o.RightX+PPIScale(5), o.Y.Value);
  o.SetSize(-1, Height);
end;

procedure TGameInventory.Exchange(aWantedMoney, aToGiveMonney: TMoneyType;
    aWantedAmount, aToGiveAmount: integer);
begin
  Audio.PlayBlipIncrementScore;

  // add
  case aWantedMoney of
    mtCoin: begin
      CoinCounter.Count := CoinCounter.Count + aWantedAmount;
      PlayerInfo.CoinCount := CoinCounter.Count;
    end;
    mtPurpleCristal: begin
      PurpleCristalCounter.Count := PurpleCristalCounter.Count + aWantedAmount;
      PlayerInfo.PurpleCristalCount := PurpleCristalCounter.Count;
    end
  else raise exception.create('forgot to implement');
  end;

  // substract
  case aToGiveMonney of
    mtCoin: begin
      CoinCounter.Count := CoinCounter.Count - aToGiveAmount;
      PlayerInfo.CoinCount := CoinCounter.Count;
    end;
    mtPurpleCristal: begin
      PurpleCristalCounter.Count := PurpleCristalCounter.Count - aToGiveAmount;
      PlayerInfo.PurpleCristalCount := PurpleCristalCounter.Count;
    end;
    else raise exception.create('forgot to implement');
  end;

  FSaveGame.Save;
end;

{ TPanelChoosePrize }

procedure TPanelChoosePrize.FormatButton(aButton: TUIButton);
begin
  AddChild(aButton);
  aButton.OnClick := @ProcessButtonClick;
  aButton._Label.Tint.Value := BGRA(255,255,150);
  aButton.BodyShape.SetShapeRoundRect(20, 20, PPIScale(8), PPIScale(8), PPIScale(2));
  aButton.BodyShape.Fill.Color := BGRA(0,0,0);
  aButton.BodyShape.Fill.CenterColor := BGRA(30,30,30);
end;

function TPanelChoosePrize.GetCoinGain: integer;
begin
  Result := Ceil(FPlayerSamsGameScore / 10 * 80);
end;

function TPanelChoosePrize.GetPurpleCristalGain: integer;
begin
  Result := Ceil(FPlayerSamsGameScore / 10 * 2);
end;

procedure TPanelChoosePrize.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
var g: integer;
begin
  Audio.PlayVoiceWhowhooo;

  if Sender = BCoin then begin
    g := GetCoinGain;
    FGameinventory.CoinCounter.Count := FGameinventory.CoinCounter.Count + g;
    PlayerInfo.CoinCount := PlayerInfo.CoinCount + g;
    FSaveGame.Save;
  end;

  if Sender = BPurpleCristal then begin
    g := GetPurpleCristalGain;
    FGameinventory.PurpleCristalCounter.Count := FGameinventory.PurpleCristalCounter.Count + g;
    PlayerInfo.PurpleCristalCount := PlayerInfo.PurpleCristalCount + g;
    FSaveGame.Save;
  end;

  Hide(True);
end;

constructor TPanelChoosePrize.Create;
var lab, lab1: TUILabel;
  VMargin, maxWidth, maxHeight: integer;
begin
  inherited Create(FScene);
  BodyShape.SetShapeRoundRect(20, 20, PPIScale(8), PPIScale(8), PPIScale(2));

  VMargin := FFontText.Font.FontHeight div 2;
  maxWidth := 0;
  maxHeight := 0;

  // your score
  lab := TUILabel.Create(FScene, Format(sYourScore,[FPlayerSamsGameScore]), FFontText);
  AddChild(lab);
  lab.Tint.Value := BGRA(220,220,220);
  lab.AnchorPosToParent(haCenter, haCenter, 0, vaTop, vaTop, VMargin);
  if maxWidth < lab.Width then maxWidth := lab.Width;
  maxHeight := maxHeight + VMargin + lab.Height;

  // select your prize
  lab1 := TUILabel.Create(FScene, sSelectYourPrize, FFontText);
  AddChild(lab1);
  lab1.Tint.Value := BGRA(220,220,220);
  lab1.AnchorHPosToParent(haCenter, haCenter, 0);
  lab1.AnchorVPosToSurface(lab, vaTop, vaBottom, VMargin);
  if maxWidth < lab1.Width then maxWidth := lab1.Width;
  maxHeight := maxHeight + VMargin + lab1.Height;

  FKeyboardToButtons := TButtonsClickableByKeyboard.Create(Self, FAtlas);

  // button coin
  BCoin := TUIButton.Create(FScene, 'x '+GetCoinGain.ToString, FFontText, texCoin);
  FormatButton(BCoin);
  BCoin.AnchorHPosToParent(haCenter, haCenter, 0);
  BCoin.AnchorVPosToSurface(lab1, vaTop, vaBottom, VMargin);
  BCoin.OnClick := @ProcessButtonClick;
  if maxWidth < BCoin.Width then maxWidth := BCoin.Width;
  maxHeight := maxHeight + VMargin + BCoin.Height;
  FKeyboardToButtons.AddLineOfButtons([BCoin]);
  FKeyboardToButtons.Select(BCoin);

  // button purple cristal
  if PlayerInfo.Forest.IsTerminated then begin
    BPurpleCristal := TUIButton.Create(FScene, 'x '+GetPurpleCristalGain.ToString, FFontText, texCristalGray);
    FormatButton(BPurpleCristal);
    BPurpleCristal.AnchorHPosToParent(haCenter, haCenter, 0);
    BPurpleCristal.AnchorVPosToSurface(BCoin, vaTop, vaBottom, VMargin);
    BPurpleCristal.OnClick := @ProcessButtonClick;
    BPurpleCristal.Image.Tint.Value := GetPurpleCristalTint;
    if maxWidth < BPurpleCristal.Width then maxWidth := BPurpleCristal.Width;
    maxHeight := maxHeight + VMargin + BPurpleCristal.Height;
    FKeyboardToButtons.AddLineOfButtons([BPurpleCristal]);
  end;

  BodyShape.ResizeCurrentShape(Round(maxWidth*1.5), VMargin+maxHeight, True);
  CenterOnScene;

end;

{ TSeagull }

procedure TSeagull.ComputeY;
begin
  Y.Value := ScaleH(25)+(ScaleW(110)-ScaleH(25))*Random;
end;

constructor TSeagull.Create(aParent: TUIImage; aSpeedX: single);
begin
  inherited Create(-1);
  aParent.AddChild(Self, 0);

  if aSpeedX > 0 then begin
    X.Value := ScaleW(-50);
    FlipH := True;
  end else X.Value := ScaleW(211);
  ComputeY;
  Speed.Value := PointF(aSpeedX, 0.0);
end;

procedure TSeagull.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if (Speed.X.Value < 0) and (X.Value < ScaleW(-50)) then begin
    FlipH := True;
    Speed.X.Value := Abs(Speed.X.Value);
    ComputeY;
  end;

  if (Speed.X.Value > 0) and (X.Value > ScaleW(211)) then begin
    FlipH := False;
    Speed.X.Value := -Abs(Speed.X.Value);
    ComputeY;
  end;
end;

{ TScreenSamHome }

procedure TScreenSamHome.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  Audio.PlayUIClick;
  if Sender = BExit then begin
    FPlayerPlaySamsGame := False;
    FScene.RunScreen(ScreenMap);
  end;

  if Sender = BGame1 then
    FScene.RunScreen(ScreenStrikeRaccoon);

  if Sender = BGameDartboard then
    FScene.RunScreen(ScreenDartboard);
end;

procedure TScreenSamHome.ProcessClickOnScene(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // check if player have clicked on Sam
  if InRange(X, FSam.X.Value, FSam.RightX) and
     InRange(Y, FSam.Y.Value, FSam.BottomY) then PostMessage(200);
end;

procedure TScreenSamHome.DefineSubTextures(aAtlas: TAtlas);
begin
  texSamHomeInner := aAtlas.AddFromSVG(FolderSpriteSam+'SamHomeInner.svg', FScene.Width, -1);
  texBarrel := aAtlas.AddFromSVG(FolderSpriteSam+'Game1Barrel.svg', -1, ScaleH(136));
  texDartboard := aAtlas.AddFromSVG(FolderSpriteDartboard+'Dartboard.svg', ScaleW(105), -1);
  texDoor := aAtlas.AddFromSVG(FolderSpriteSam+'SamDoor.svg', ScaleW(170), -1);
  TSam.LoadTexture(aAtlas);
  texLRIcon := aAtlas.AddFromSVG(SpriteBGFolder+'LR.svg', -1, ScaleH(65));

  AdditionnalScale := 0.25;
  TSeagullBase.LoadTexture(aAtlas);
  AdditionnalScale := 1.0;

  FFontText := CreateGameFontText(aAtlas);

  CreateGameFontNumber(aAtlas);
  LoadCoinTexture(aAtlas);
  LoadCristalGrayTexture(aAtlas);
  LoadWatchTexture(aAtlas);
  LoadGameDialogTextures(aAtlas);
  LoadMousePointerTexture(aAtlas);

  FItemHeight := ScaleH(70); // height of one row in the panel
  // we avoid the overlapp with the icon texture that are smallest
  texCoinBig := aAtlas.RetrieveTextureByFileName('BigCoin');
  if texCoinBig = NIL then begin
    texCoinBig := aAtlas.AddFromSVG(SpriteUIFolder+'Coin.svg', -1, FItemHeight-PPIScale(20));
    texCoinBig^.Filename := 'BigCoin';
  end;
  texSmallCristalGrayBig := aAtlas.RetrieveTextureByFileName('BigCristalGray');
  if texSmallCristalGrayBig = NIL then begin
    texSmallCristalGrayBig := aAtlas.AddFromSVG(SpriteUIFolder+'CristalGray.svg', -1, FItemHeight-PPIScale(20));
    texSmallCristalGrayBig^.Filename := 'BigCristalGray';
  end;
end;

procedure TScreenSamHome.CreateObjects;
var home: TSprite;
begin
  if not FPlayerPlaySamsGame then
    Audio.PauseMusicTitleMap(3.0);
  FsndMusic := Audio.AddMusic('Hoedown_Hustle.ogg', True);
  FsndMusic.FadeIn(1.0, 2.0);

  CheckAtlas(FAtlas, 'samhome.atlas');

  // home bg
  home := TSprite.Create(texSamHomeInner, False);
  FScene.Add(home, LAYER_BG1);
  home.SetCoordinate(0, 0);

  // sam
  FSam := TSam.Create(LAYER_WOLF);
  FSam.SetCoordinate(ScaleW(863), ScaleH(170));

  // button exit
  BExit := TImageButton.Create(texDoor);
  home.AddChild(BExit, -1);
  BExit.OnClick := @ProcessButtonClick;
  BExit.SetCoordinate(ScaleW(56), ScaleH(81));
  TSeagull.Create(BExit.Image, -FScene.Width*0.03);
  with TSeagull.Create(BExit.Image, FScene.Width*0.02) do
    Scale.Value := PointF(0.8, 0.8);
  with TSeagull.Create(BExit.Image, FScene.Width*0.025) do
      Scale.Value := PointF(0.9, 0.9);
  with TSeagull.Create(BExit.Image, FScene.Width*0.01) do
    Scale.Value := PointF(0.7, 0.7);

  // button game 1
  BGame1 := TImageButton.Create(texBarrel);
  home.AddChild(BGame1, 0);
  BGame1.OnClick := @ProcessButtonClick;
  BGame1.SetCoordinate(ScaleW(426), ScaleH(160));

  // button dartrboard
  BGameDartboard := TImageButton.Create(texDartboard);
  home.AddChild(BGameDartboard, 0);
  BGameDartboard.OnClick := @ProcessButtonClick;
  BGameDartboard.SetCoordinate(ScaleW(571), ScaleH(37));

  // inventory
  FGameinventory := TGameInventory.Create;

  // items to exchange
  FPanelItems := TPanelItems.Create(0, FGameinventory.BottomY+PPIScale(3));
  if PlayerInfo.Forest.IsTerminated then begin
    FPanelItems.AddItem(mtPurpleCristal, mtCoin, 1, 100);
    FPanelItems.AddItem(mtCoin, mtPurpleCristal, 80, 1);
  end;
  FPanelItems.UpdatePossibleTransactions;

  FScene.Mouse.OnClickOnScene := @ProcessClickOnScene;

  CustomizeMousePointer(True);

  if FPlayerPlaySamsGame then begin
    PostMessage(300);
    FPlayerPlaySamsGame := False;
  end else PostMessage(100, 1.0); // dialogs Sam

end;

procedure TScreenSamHome.FreeObjects;
begin
  if FsndMusic <> NIL then FsndMusic.FadeOutThenKill(2.0);
  FsndMusic := NIL;
  if FScene.RequestedScreen = ScreenMap then
    Audio.ResumeMusicTitleMap(3.0);

  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
end;

procedure TScreenSamHome.ProcessMessage(UserValue: TUserMessageValue);
  procedure ShowSamMessage(const s: string; UserValue: TUserMessageValue; WaitForPlayerClick: boolean=False);
  var xx: single;
    panel: TInfoPanel;
  begin
    if not WaitForPlayerClick
      then panel := TInfoPanel.Create('SAM', s, FFontText, 4.0, LAYER_DIALOG)
      else panel := TInfoPanel.Create('SAM', s, FFontText, Self, UserValue, 0, LAYER_DIALOG);
    with panel do begin
      xx := FSam.CenterX;
      xx := Min(xx, FScene.Width-Width*0.5);
      CenterX := xx;
      Y.Value := PPIScale(25);
    end;
    if not WaitForPlayerClick then PostMessage(UserValue, 4.0);
  end;
begin
  case UserValue of
    // dialogs Sam
    100: ShowSamMessage(sWelcomeToSam, 105);

    // EXPLANATIONS
    200: ShowSamMessage(sHereYouCanExchange,205, True);
    205: ShowSamMessage(sYouCanAlsoWinItems, 210, True);
    210: ShowSamMessage(sTheHigherYourScore, 215, True);
    215: ShowSamMessage(sHaveFun, 220, True);

    // BACK FROM A MINI GAME -> player choose the gain
    300: begin
      with TPanelChoosePrize.Create do
        ShowModal;
    end;
  end;
end;


end.

