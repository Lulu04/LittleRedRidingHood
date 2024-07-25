unit u_common_ui;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

type

{ TImageButton }
// IMAGE BUTTON clickable by the player. When the mouse is over, the image pulse with white color
TImageButton = class(TUIButton)
private const
  sceMOUSE_ENTER='TintChange 255 255 255 200 0.5 0 Linear'#10+
                 'Wait 0.5'#10+
                 'TintChange 255 255 255 50 0.5 0 Linear'#10+
                 'Wait 0.5'#10+
                 'Loop';
private
  FsceIDMouseEnter: TIDScenario;
  procedure DoAnimMouseEnter(Sender: TSimpleSurfaceWithEffect);
  procedure DoAnimMouseLeave(Sender: TSimpleSurfaceWithEffect);
public
  constructor Create(aTexture: PTexture);
  property sceIDMouseEnter: TIDScenario read FsceIDMouseEnter;
end;


TUIItem = class(TSpriteContainer)
private
  FTotalWidth, FTotalHeight: integer;
public
  property TotalWidth: integer read FTotalWidth;
  property TotalHeight: integer read FTotalHeight;
end;

{ TUIItemCounter }

TUIItemCounter = class(TUIItem)
private
  FCount, FMaxValue: integer;
  procedure SetCount(AValue: integer);
  procedure UpdateNumberCaption;
public
  Icon: TSprite;
  Number: TFreeText;
  constructor Create(aTexIcon: PTexture; aFont: TTexturedFont; aMaxDigit: integer);
  property Count: integer read FCount write SetCount;
  property MaxValue: integer read FMaxValue;
end;


{ TUICoinCounter }

TUICoinCounter = class(TUIItemCounter)
  constructor Create;
end;

{ TUIPurpleCristalCounter }

TUIPurpleCristalCounter = class(TUIItemCounter)
  constructor Create;
end;


{ TUIClock }

TUIClock = class(TUIItem)
private
  FIconWatchBody, FIconWatchHand: TSprite;
  FClock: TFreeTextClockLabel;
  FClockBlinkThreshold: integer;
  FCanBlink: boolean;
  function GetSecond: integer;
  procedure SetSecond(AValue: integer);
public
  constructor Create(aModeCountDown: boolean=True);
  procedure Update(const aElapsedTime: single); override;
  // use only in count down mode
  procedure BlinkClockWhenLessThan(aValue: integer=10);
  procedure StartTime;
  procedure PauseTime;
  property Second: integer read GetSecond write SetSecond;
end;

{ TBaseInGamePanel }

TBaseInGamePanel = class(TUIPanel)
private
  FTotalWidth, FTotalHeight, FMarginBetweenItem: integer;
  FLastItem: TUIItem;
protected
  procedure AddItem(aItem: TUIItem); virtual;
  procedure ResizeAndPlaceAtTopRight;
public
  constructor Create;
  property TotalWidth: integer read FTotalWidth;
end;

{ TBaseInGamePanelWithCoinAndClock }

TBaseInGamePanelWithCoinAndClock = class(TBaseInGamePanel)
private
  FCoinCounter: TUICoinCounter;
  FClock: TUIClock;
  function GetCoinCount: integer;
  function GetSecond: integer;
  procedure SetSecond(AValue: integer);
protected
  procedure AddItem(aItem: TUIItem); override;
public
  constructor Create;

  procedure AddToCoin(aDelta: integer);
  procedure BlinkClockWhenLessThan(aValue: integer=10);
  procedure StartTime;
  procedure PauseTime;
  property Second: integer read GetSecond write SetSecond;
  property CoinCount: integer read GetCoinCount;
end;

{ TInMapPanel }

TInMapPanel = class(TBaseInGamePanel)
private
  FCoinCounter: TUICoinCounter;
  FPurpleCristalCounter: TUIPurpleCristalCounter;
  FDeltaToAdd, FDeltaToSubstract: integer;
  FCoinCountIsChanging: boolean;
public
  constructor Create;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure BlinkIconCoin;
  procedure AddToCoinCounter(aDelta: integer);
  procedure AddToPurpleCristalCounter(aDelta: integer);
end;


{ TBasePanelEndGameScore }

TBasePanelEndGameScore = class(TUIPanel)
private
  FLabelsEqual: array of TUILabel;
  FIndexLabelEqual, FMaxWidth: integer;
  FDone: boolean;
  FGain: integer;
  FGainLabel: TFreeText;
  procedure SetGain(aValue: integer);
protected
  HMargin, VMargin: integer;
  function CreateLabelEqual: TUILabel;
  procedure CreateLineTotalGain(const aCaption: string);
  procedure CompareLineWidth(aLineWidth: integer);
  procedure StartCounting;
public
  procedure AddGainToInGamePanel(aValue: integer); virtual; abstract;
  constructor Create(aEqualLabelCount: integer);
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;

  property Gain: integer read FGain write SetGain;
  property Done: boolean read FDone;
end;


var
  UIFontNumber: TTexturedFont;
  texCoin,
  texCristalGray,
  texWatchBody, texWatchHand: PTexture;
  FontNumberCapLine: integer;

// FONTS used by the game
function CreateGameFontText(aAtlas: TOGLCTextureAtlas): TTexturedFont;
function CreateGameFontButton(aAtlas: TOGLCTextureAtlas; const aCharSet: string): TTexturedFont;
procedure CreateGameFontNumber(aAtlas: TOGLCTextureAtlas);
// call AFTER CreateGameFontNumber ! Return the height for the icon in game panel
function IconHeight: integer;

procedure LoadCoinTexture(aAtlas: TOGLCTextureAtlas);
procedure LoadCristalGrayTexture(aAtlas: TOGLCTextureAtlas);
procedure LoadWatchTexture(aAtlas: TOGLCTextureAtlas);

implementation
uses u_app, u_common, u_resourcestring, Math, Graphics, LCLType;


function CreateGameFontText(aAtlas: TOGLCTextureAtlas): TTexturedFont;
var fd: TFontDescriptor;
begin
  fd.Create('Arial', Round(FScene.Height/35), [], BGRA(0,0,0));
  Result := aAtlas.AddTexturedFont(fd, SIMPLELATIN_CHARSET+LATIN1_SUPP_CHARSET+'%-+_/=!?:,.''()#&');
end;

function CreateGameFontButton(aAtlas: TOGLCTextureAtlas; const aCharSet: string): TTexturedFont;
var fd: TFontDescriptor;
begin
  fd.Create('Arial', Round(FScene.Height/20), [], BGRA(0,0,0));
  Result := aAtlas.AddTexturedFont(fd, aCharSet);
end;

procedure CreateGameFontNumber(aAtlas: TOGLCTextureAtlas);
var fd: TFontDescriptor;
begin
  fd.Create('Arial', Round(FScene.Height/20), [fsBold], BGRA(20,20,20));
  FontNumberCapLine := fd.FontPixelMetric.CapLine;
  UIFontNumber := aAtlas.AddTexturedFont(fd, FontNumberCharset);
  UIFontNumber.CharSpacingCoeff.Value := 0.95;
end;

function IconHeight: integer;
begin
  Result := Round(UIFontNumber.Font.FontHeight*0.8);
end;

procedure LoadCoinTexture(aAtlas: TOGLCTextureAtlas);
begin
  texCoin := aAtlas.AddFromSVG(SpriteUIFolder+'Coin.svg', -1, IconHeight);
end;

procedure LoadCristalGrayTexture(aAtlas: TOGLCTextureAtlas);
begin
  texCristalGray := aAtlas.AddFromSVG(SpriteUIFolder+'CristalGray.svg', -1, IconHeight);
end;

procedure LoadWatchTexture(aAtlas: TOGLCTextureAtlas);
begin
  texWatchBody := aAtlas.AddFromSVG(SpriteUIFolder+'WatchBody.svg', -1, IconHeight);
  texWatchHand := aAtlas.AddFromSVG(SpriteUIFolder+'WatchHand.svg', -1, Round(IconHeight*0.304));
end;

{ TUIPurpleCristalCounter }

constructor TUIPurpleCristalCounter.Create;
begin
  inherited Create(texCristalGray, UIFontNumber, 2);
  Icon.TintMode := tmMixColor;
  Icon.Tint.Value := BGRA(255,0,255,150);
end;

{ TBaseInGamePanelWithCoinAndClock }

function TBaseInGamePanelWithCoinAndClock.GetSecond: integer;
begin
  Result := FClock.Second;
end;

function TBaseInGamePanelWithCoinAndClock.GetCoinCount: integer;
begin
  Result := FCoinCounter.Count;
end;

procedure TBaseInGamePanelWithCoinAndClock.SetSecond(AValue: integer);
begin
  FClock.Second := AValue;
end;

procedure TBaseInGamePanelWithCoinAndClock.AddItem(aItem: TUIItem);
begin
  inherited AddItem(aItem);

  if (FCoinCounter <> NIL) and (FClock <> NIL) and (aItem <> FClock) then begin
    aItem.SetCoordinate(FClock.GetXY);
    FClock.SetCoordinate(aItem.X.Value+aItem.TotalWidth + FMarginBetweenItem, 0);
  end;
end;

constructor TBaseInGamePanelWithCoinAndClock.Create;
begin
  inherited Create;

  FCoinCounter := TUICoinCounter.Create;
  AddItem(FCoinCounter);
  FCoinCounter.Count := PlayerInfo.CoinCount;

  FClock := TUIClock.Create;
  AddItem(FClock);
end;

procedure TBaseInGamePanelWithCoinAndClock.AddToCoin(aDelta: integer);
begin
  FCoinCounter.Count := FCoinCounter.Count + aDelta;
end;

procedure TBaseInGamePanelWithCoinAndClock.BlinkClockWhenLessThan(aValue: integer);
begin
  FClock.BlinkClockWhenLessThan(aValue);
end;

procedure TBaseInGamePanelWithCoinAndClock.StartTime;
begin
  FClock.StartTime;
end;

procedure TBaseInGamePanelWithCoinAndClock.PauseTime;
begin
  FClock.PauseTime;
end;

{ TBaseInGamePanel }

procedure TBaseInGamePanel.AddItem(aItem: TUIItem);
begin
  AddChild(aItem, 0);
  if FLastItem = NIL then begin
    aItem.SetCoordinate(FMarginBetweenItem*0.5, 0);
    FTotalWidth := FTotalWidth + aItem.TotalWidth + Round(FMarginBetweenItem*1.5);
  end else begin
    aItem.SetCoordinate(FLastItem.X.Value+FLastItem.TotalWidth + FMarginBetweenItem, 0);
    FTotalWidth := FTotalWidth + aItem.TotalWidth + FMarginBetweenItem;
  end;
  FLastItem := aItem;

  if FTotalHeight < aItem.TotalHeight then FTotalHeight := aItem.TotalHeight;
end;

procedure TBaseInGamePanel.ResizeAndPlaceAtTopRight;
begin
  FTotalWidth := FTotalWidth - Round(FMarginBetweenItem*0.5);
  BodyShape.ResizeCurrentShape(FTotalWidth, Round(FTotalHeight*1.1), False);

  SetCoordinate(FScene.Width-FTotalWidth, 0);
end;

constructor TBaseInGamePanel.Create;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_GAMEUI);
  BodyShape.SetShapeRoundRect(200, 50, PPIScale(8), PPIScale(8), PPIScale(3));
  BodyShape.Fill.Color := BGRA(30,30,30,120);
  MouseInteractionEnabled := False; // mouse pooling is not necessary
  ChildClippingEnabled := False;    // clipping is not necessary

  FMarginBetweenItem := UIFontNumber.GetCharWidth('9');
end;

{ TBasePanelEndGameScore }

function TBasePanelEndGameScore.CreateLabelEqual: TUILabel;
begin
  Result := TUILabel.Create(FScene, '=', UIFontNumber);
  AddChild(Result);
  Result.MouseInteractionEnabled := False;
  Result.CenterX := Width*0.75;
  Result.ChildsUseParentOpacity := True;
  Result.Opacity.Value := 0;
  Result.Tint.Value := BGRA(220,220,220);

  FLabelsEqual[FIndexLabelEqual] := Result;
  if FIndexLabelEqual = 0 then Result.Y.Value := VMargin
    else Result.Y.Value := FLabelsEqual[FIndexLabelEqual-1].BottomY + VMargin;
  inc(FIndexLabelEqual);
end;

procedure TBasePanelEndGameScore.CreateLineTotalGain(const aCaption: string);
var t: TFreeText;
  equal: TUILabel;
  w: Integer;
begin
  equal := CreateLabelEqual;
  t := TFreeText.Create(FScene);
  t.Tint.Value := BGRA(220,220,220);
  equal.AddChild(t);
  t.TexturedFont := UIFontNumber;
  t.Caption := aCaption;
  t.SetCoordinate(-HMargin-t.Width, 0);
  w := HMargin+t.Width;
  FGainLabel := TFreeText.Create(FScene);
  FGainLabel.Tint.Value := BGRA(255,255,150);
  equal.AddChild(FGainLabel);
  FGainLabel.TexturedFont := UIFontNumber;
  FGainLabel.Caption := Gain.ToString;
  FGainLabel.RightX := HMargin*6;
  FGainLabel.Y.Value := 0;
  w := w + Round(FGainLabel.RightX);
  CompareLineWidth(w);
end;

procedure TBasePanelEndGameScore.CompareLineWidth(aLineWidth: integer);
begin
  if FMaxWidth < aLineWidth then FMaxWidth := aLineWidth;
end;

procedure TBasePanelEndGameScore.SetGain(aValue: integer);
begin
  FGain := aValue;
end;

procedure TBasePanelEndGameScore.StartCounting;
var v: integer;
begin
  // resize the panel according to the largest line
  v := Length(FLabelsEqual);
  BodyShape.ResizeCurrentShape(Round(FMaxWidth*1.2),
     VMargin*(v+1)+UIFontNumber.Font.FontHeight*v, False);
  // reposition the label '='
  for v:=0 to ChildCount-1 do
    if Childs[v] is TUILabel then Childs[v].CenterX := Width*0.75;

  CenterOnScene;

  if FGain > 0 then begin
    PlayerInfo.CoinCount := PlayerInfo.CoinCount + FGain;
    FSaveGame.Save;
  end;

  FIndexLabelEqual := 0;
  if Length(FLabelsEqual) > 0 then PostMessage(0, 0.75)
    else FDone := True;
end;

constructor TBasePanelEndGameScore.Create(aEqualLabelCount: integer);
begin
  inherited Create(FScene);
  VMargin := UIFontNumber.Font.FontHeight div 2;
  HMargin := UIFontNumber.GetCharWidth('9');
  FScene.Add(Self, LAYER_GAMEUI);
  BodyShape.SetShapeRoundRect(Round(FScene.Width*0.4),
                              VMargin*(aEqualLabelCount+1)+UIFontNumber.Font.FontHeight*aEqualLabelCount,
                              PPIScale(8), PPIScale(8), PPIScale(3));
  BodyShape.Fill.Color := BGRA(30,30,30,120);
  MouseInteractionEnabled := False; // mouse pooling is not necessary
  ChildClippingEnabled := False;    // clipping is not necessary
  CenterOnScene;

  FLabelsEqual := NIL;
  SetLength(FLabelsEqual, aEqualLabelCount);
end;

procedure TBasePanelEndGameScore.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // LINES APPEARS ONE BY ONE
    0: begin
      FLabelsEqual[FIndexLabelEqual].Opacity.Value := 255;
      // jouer un son pofff
      inc(FIndexLabelEqual);
      if FIndexLabelEqual < Length(FLabelsEqual) then PostMessage(0, 0.25)
        else begin
          PostMessage(3); // impatients players can interrupt counting from now
          PostMessage(10, 0.75)
        end;
    end;

    // COUNTING CAN BE INTERRUPT OR IS DONE
    3: begin
      FDone := True;
    end;

    // DO COUNTING
    10: begin
      if FGain >= 100 then begin
        Dec(FGain, 100);
        AddGainToInGamePanel(100);
      end;
      if FGain >= 10 then begin
        Dec(FGain, 10);
        AddGainToInGamePanel(10);
      end;
      if FGain >= 1 then begin
        Dec(FGain);
        AddGainToInGamePanel(1);
      end;

      FGainLabel.Caption := FGain.ToString;
      FGainLabel.RightX := HMargin*6;

      if FGain > 0 then PostMessage(10, 0.1)
        else PostMessage(3);
    end;
  end;
end;

{ TImageButton }

procedure TImageButton.DoAnimMouseEnter(Sender: TSimpleSurfaceWithEffect);
begin
  Image.PlayScenario(FsceIDMouseEnter);
end;

procedure TImageButton.DoAnimMouseLeave(Sender: TSimpleSurfaceWithEffect);
begin
  Image.StopScenario(FsceIDMouseEnter);
  Image.Tint.Alpha.ChangeTo(0, 0.5);
end;

constructor TImageButton.Create(aTexture: PTexture);
begin
  inherited Create(FScene, '', NIL, aTexture);
  AutoSize := False;
  BodyShape.SetShapeRectangle(aTexture^.FrameWidth, aTexture^.FrameHeight, 0);
  BodyShape.Fill.Visible := False;
  BodyShape.Border.Visible := False;
  ChildClippingEnabled := False;
  OnAnimMouseEnter := @DoAnimMouseEnter;
  OnAnimMouseLeave := @DoAnimMouseLeave;
  FsceIDMouseEnter := Image.AddScenario(sceMOUSE_ENTER);
end;

{ TInMapPanel }

constructor TInMapPanel.Create;
begin
  inherited Create;

  FCoinCounter := TUICoinCounter.Create;
  AddItem(FCoinCounter);
  FCoinCounter.Count := PlayerInfo.CoinCount;

  if PlayerInfo.Forest.IsTerminated then begin
    FPurpleCristalCounter := TUIPurpleCristalCounter.Create;
    AddItem(FPurpleCristalCounter);
    FPurpleCristalCounter.Count := PlayerInfo.PurpleCristalCount;
  end;

  ResizeAndPlaceAtTopRight;
end;

procedure TInMapPanel.ProcessMessage(UserValue: TUserMessageValue);
  procedure CheckDeltaToAdd(aAmount: integer);
  begin
    if FDeltaToAdd >= aAmount then begin
      FCoinCounter.Count := FCoinCounter.Count + aAmount;
      FDeltaToAdd := FDeltaToAdd - aAmount;
    end;
  end;
  procedure CheckDeltaToSubstract(aAmount: integer);
  begin
    if FDeltaToSubstract >= aAmount then begin
      FCoinCounter.Count := FCoinCounter.Count - aAmount;
      FDeltaToSubstract := FDeltaToSubstract - aAmount;
    end;
  end;

begin
  case UserValue of
    // add/substract to coin counter
    0: begin
      if FDeltaToAdd > 0 then begin
        CheckDeltaToAdd(1000);
        CheckDeltaToAdd(100);
        CheckDeltaToAdd(10);
        CheckDeltaToAdd(1);
      end;

      if FDeltaToSubstract > 0 then begin
        CheckDeltaToSubstract(1000);
        CheckDeltaToSubstract(100);
        CheckDeltaToSubstract(10);
        CheckDeltaToSubstract(1);
      end;
      if (FDeltaToAdd = 0) and (FDeltaToSubstract = 0) then begin
        FCoinCountIsChanging := False;
        exit;
      end else PostMessage(0, 0.1);
    end;
  end;
end;

procedure TInMapPanel.BlinkIconCoin;
begin
  FCoinCounter.Icon.Blink(3, 0.2, 0.2);
  FCoinCounter.Number.Blink(3, 0.2, 0.2);
end;

procedure TInMapPanel.AddToCoinCounter(aDelta: integer);
begin
  if aDelta < 0 then FDeltaToSubstract := FDeltaToSubstract + Abs(aDelta)
  else if aDelta > 0 then FDeltaToAdd := FDeltaToAdd + aDelta
  else exit;
  if not FCoinCountIsChanging then begin
    FCoinCountIsChanging := True;
    PostMessage(0);
  end;
end;

procedure TInMapPanel.AddToPurpleCristalCounter(aDelta: integer);
begin
  if FPurpleCristalCounter <> NIL then
    FPurpleCristalCounter.Count := FPurpleCristalCounter.Count + aDelta;
end;

{ TUIClock }

function TUIClock.GetSecond: integer;
begin
  Result := Ceil(FClock.Time);
end;

procedure TUIClock.SetSecond(AValue: integer);
begin
  FClock.Time := AValue;
end;

constructor TUIClock.Create(aModeCountDown: boolean=True);
begin
  inherited Create(FScene);

  FIconWatchBody := TSprite.Create(texWatchBody, False);
  AddChild(FIconWatchBody, 2);
  FIconWatchBody.SetCoordinate(0, FontNumberCapLine);

  FIconWatchHand := TSprite.Create(texWatchHand, False);
  FIconWatchBody.AddChild(FIconWatchHand, 0);
  FIconWatchHand.CenterX := FIconWatchBody.Width*0.5;
  FIconWatchHand.BottomY := FIconWatchBody.Height*0.58;
  FIconWatchHand.Pivot := PointF(0.5, 1);

  FClock := TFreeTextClockLabel.Create(FScene, True);
  FClock.Countdown := aModeCountDown;
  FClock.ShowFractionalPart := False;
  FClock.TexturedFont := UIFontNumber;
  FClock.Tint.Value := BGRA(255,255,150);
  FClock.Caption:='999';
  AddChild(FClock, 2);
  FClock.SetCoordinate(FIconWatchBody.X.Value+FIconWatchBody.Width*1.1, 0);

  FTotalWidth := Round(FClock.RightX);
  FTotalHeight := Max(FIconWatchBody.Height, UIFontNumber.Font.FontHeight);
end;

procedure TUIClock.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if FCanBlink and (Ceil(FClock.Time) <= FClockBlinkThreshold) then begin
    FClock.Blink(-1, 0.4, 0.4);
    FCanBlink := False;
  end;
end;

procedure TUIClock.BlinkClockWhenLessThan(aValue: integer);
begin
  FClockBlinkThreshold := aValue;
  FCanBlink := True;
end;

procedure TUIClock.StartTime;
begin
  FClock.Run;
  FIconWatchHand.Angle.AddConstant(360);
end;

procedure TUIClock.PauseTime;
begin
  FClock.Pause;
  FIconWatchHand.Angle.AddConstant(0);
end;

{ TUICoinCounter }

constructor TUICoinCounter.Create;
begin
  inherited Create(texCoin, UIFontNumber, 6);
end;

{ TUIItemCounter }

procedure TUIItemCounter.SetCount(AValue: integer);
begin
  if AValue < 0 then AValue := 0
  else if AValue <= FMaxValue then FCount := AValue
    else FCount := FMaxValue;
  UpdateNumberCaption;
end;

procedure TUIItemCounter.UpdateNumberCaption;
begin
  Number.Caption := 'x'+IntToStr(FCount);
end;

constructor TUIItemCounter.Create(aTexIcon: PTexture; aFont: TTexturedFont; aMaxDigit: integer);
begin
  inherited Create(FScene);

  Icon := TSprite.Create(aTexIcon, False);
  AddChild(Icon, 0);
  Icon.SetCoordinate(0, FontNumberCapLine); // aFont.Font.FontHeight-aTexIcon^.FrameHeight);

  FMaxValue := Trunc(Power(10, aMaxDigit))-1;

  Number := TFreeText.Create(FScene);
  AddChild(Number, 0);
  Number.TexturedFont := aFont;
  Number.Tint.Value := BGRA(255,255,150);
  Count := Round(IntPower(10, aMaxDigit-1)); // necessary to compute FTotalWidth
  Number.SetCoordinate(Icon.Width*1.1, 0);

  FTotalWidth := Round(Number.RightX);
  FTotalHeight := Max(Icon.Height, aFont.Font.FontHeight);
end;



end.

