unit u_screen_workshop;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_common_ui, u_sprite_lrcommon, u_audio, ALSound;

type

  { TScreenWorkShop }

  TScreenWorkShop = class(TScreenTemplate)
  private
    FFireSound: TALSSound;
    FAtlas: TOGLCTextureAtlas;
    BExit: TImageButton;
    texDoor, texDoorFrame: PTexture;
    FPlayerItemPanel: TInMapPanel;
    FLR: TLRFrontView;
    procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
    procedure ProcessOnUpgradeRequestEvent(Sender: TSimpleSurfaceWithEffect);
  public
    procedure CreateObjects; override;
    procedure FreeObjects; override;
    procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  end;

var ScreenWorkShop: TScreenWorkShop;


implementation
uses u_app, u_resourcestring, u_screen_map,
  u_mousepointer;

var
  texHomeBG, texFireBG,
  texCoin, texSmallCristalGray,
  texBow, texElevator, texHammer, texStormCloud,
  texZipLine,
  texDigicodeDecoder: PTexture;
  FItemHeight: integer;
  FFontText: TTexturedFont;

type

TCallbackOnUpdateRequest = procedure(Sender: TSimpleSurfaceWithEffect) of object;
{ TUpgradableItem }

TUpgradableItem = class(TUIPanel)
private
  FIcon: TSprite;
  FLabelLevel, FLabelMax, FLabelNextLevel: TUILabel;
  {BNextLevelPrice,} BUpgrade: TUIButton;
  FPriceItems: array of TUIButton;
  FText: TUITextArea;
  FItemDescriptor: TUpgradableItemDescriptor;
  FOnUpgradeRequest: TCallbackOnUpdateRequest;
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
  procedure ProcessMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  procedure UpdateLabelCurrentLevel;
  procedure UpdateLabelNextLevel;
  procedure UpdateTextExplanation;
  procedure UpdateItemNeededForNextLevel;
public
  constructor Create(aWidth, aHeight: integer; aItemDescriptor: TUpgradableItemDescriptor; texItem: PTexture);

  property OnUpgradeRequest: TCallbackOnUpdateRequest read FOnUpgradeRequest write FOnUpgradeRequest;
  property ItemDescriptor: TUpgradableItemDescriptor read FItemDescriptor;
end;

{ TPanelItems }

TPanelItems = class(TUIScrollBox)
private
  FCurrentY: single;
public
  constructor Create(aX, aY: single);
  function AddItem(aItemDescriptor: TUpgradableItemDescriptor; texItem: PTexture): TUpgradableItem;
end;


var FPanelItem: TPanelItems;

{ TPanelItems }

constructor TPanelItems.Create(aX, aY: single);
begin
  inherited Create(FScene, True, False);
  FScene.Add(Self, LAYER_GAMEUI);
  //FPanelItem.BodyShape.SetShapeRoundRect(FScene.Width, Round(BExit.Y.Value-home.BottomY), PPIScale(8), PPIScale(8), PPIScale(2));
  BodyShape.SetShapeRoundRect(FScene.Width, Round(FScene.Height-aY), PPIScale(8), PPIScale(8), PPIScale(2));
  BackGradient.CreateHorizontal([BGRA(255,0,255,10), BGRA(255,0,255,40), BGRA(255,0,255,10)],[0,0.5,1]);
  SetCoordinate(aX, aY);
  VScrollBarMode := sbmAlwaysShow;
  FCurrentY := 0;
end;

function TPanelItems.AddItem(aItemDescriptor: TUpgradableItemDescriptor; texItem: PTexture): TUpgradableItem;
begin
  Result := TUpgradableItem.Create(ClientArea.Width-PPIScale(10), FItemHeight,
                                   aItemDescriptor, texItem);
  AddChild(Result);
  Result.SetCoordinate(0, FCurrentY);
  Result.OnUpgradeRequest := @ScreenWorkShop.ProcessOnUpgradeRequestEvent;
  FCurrentY := FCurrentY + FItemHeight + PPIScale(10);
end;

{ TUpgradableItem }

procedure TUpgradableItem.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  if not FItemDescriptor.CanBePurchased then begin
    // not enough money!
    // play a sound buzzer
    //ScreenWorkShop.FPlayerItemPanel.BlinkIconCoin;
    exit;
  end;

  if not FItemDescriptor.Owned then begin
    FIcon.Tint.Alpha.Value := 0;
    BUpgrade._Label.Caption := sUpgrade;
  end;

  FItemDescriptor.BuyNextLevel;

  FOnUpgradeRequest(Self);
  FItemDescriptor.IncLevel;
  FSaveGame.Save;

  FLabelMax.Visible := not FItemDescriptor.LevelCanBeUpgraded;
  BUpgrade.Visible := FItemDescriptor.LevelCanBeUpgraded;

  FLabelLevel.Visible := True;
  UpdateLabelCurrentLevel;
  UpdateTextExplanation;
  UpdateLabelNextLevel;
  UpdateItemNeededForNextLevel;
end;

procedure TUpgradableItem.ProcessMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  FPanelItem.DoOnMouseWheel(Shift, WheelDelta, MousePos, Handled);
end;

procedure TUpgradableItem.UpdateLabelCurrentLevel;
begin
  FLabelLevel.Caption := sLevel+' '+FItemDescriptor.Level.ToString+'/'+FItemDescriptor.MaxLevel.ToString;
end;

procedure TUpgradableItem.UpdateLabelNextLevel;
var s: string;
begin
  case FItemDescriptor.ActionToOwnItem of
    atoiBuy: if FItemDescriptor.Owned then s := sNextLevel else s := sPrice;
    atoiBuild: if FItemDescriptor.Owned then s := sNextLevel else s := sManufacturing;
    else raise exception.Create('forgot to implement');
  end;

  FLabelNextLevel.Visible := FItemDescriptor.LevelCanBeUpgraded;
  if FLabelNextLevel.Visible then FLabelNextLevel.Caption := s;
end;

procedure TUpgradableItem.UpdateTextExplanation;
begin
  FText.Text.Caption := FItemDescriptor.NextLevelExplanation;
end;

procedure TUpgradableItem.UpdateItemNeededForNextLevel;
var A: ArrayOfMoneyDescriptor;
    i: integer;
    tex: PTexture;
    colorNumber, colorIconTint: TBGRAPixel;
    iconTintMode: TTintMode;
begin
  if Length(FPriceItems) <> 0 then
    for i:=0 to High(FPriceItems) do FPriceItems[i].Kill;
  FPriceItems := NIL;

  if not FItemDescriptor.LevelCanBeUpgraded then exit;

  A := FItemDescriptor.PriceForNextLevel;
  if Length(A) = 0 then exit;
  SetLength(FPriceItems, Length(A));

  for i:=0 to High(A) do begin
    case A[i].MoneyType of
      mtCoin: begin
        tex := texCoin;
        if PlayerInfo.CoinCount >= A[i].Count then colorNumber := BGRA(255,255,0)
          else colorNumber := BGRA(255,80,80);
        colorIconTint := BGRA(0,0,0,0);
        iconTintMode := tmReplaceColor;
      end;
      mtPurpleCristal: begin
        tex := texSmallCristalGray;
        if PlayerInfo.PurpleCristalCount >= A[i].Count then colorNumber := BGRA(255,255,0)
          else colorNumber := BGRA(255,20,20);
        colorIconTint := BGRA(255,0,255,150);
        iconTintMode := tmMixColor;
      end;
      else raise exception.create('forgot to implement this money type');
    end;

    FPriceItems[i] := TUIButton.Create(FScene, A[i].Count.ToString, FFontText, tex);
    AddChild(FPriceItems[i]);
    FPriceItems[i]._Label.Tint.Value := colorNumber;
    FPriceItems[i].Image.TintMode := iconTintMode;
    FPriceItems[i].Image.Tint.Value := colorIconTint;
    FPriceItems[i].BodyShape.Fill.Visible := False;
    FPriceItems[i].BodyShape.Border.Visible := False;
    FPriceItems[i].MouseInteractionEnabled := False;
    if Length(A) = 1 then FPriceItems[i].AnchorPosToSurface(FLabelNextLevel, haCenter, haCenter, 0, vaTop, vaBottom, 0)
      else if i = 0 then FPriceItems[i].AnchorPosToSurface(FLabelNextLevel, haLeft, haLeft, 0, vaTop, vaBottom, 0)
             else FPriceItems[i].AnchorPosToSurface(FPriceItems[i-1], haLeft, haRight, 0, vaTop, vaTop, 0);
    end;
end;

constructor TUpgradableItem.Create(aWidth, aHeight: integer; aItemDescriptor: TUpgradableItemDescriptor;
  texItem: PTexture);
var FCellWidth: Integer;
  s: string;
begin
  inherited Create(FScene);
  BodyShape.SetShapeRectangle(aWidth, aHeight, 0);
  BodyShape.Fill.Color := BGRA(30,20,20);
  OnMouseWheel := @ProcessMouseWheel;

  FItemDescriptor := aItemDescriptor;

  FCellWidth := Round(aWidth/7); // Text count for 3

  // icon
  FIcon := TSprite.Create(texItem, False);
  AddChild(FIcon, 0);
  FIcon.SetCenterCoordinate(FCellWidth*0.5, aHeight*0.5);
  if not FItemDescriptor.Owned then FIcon.Tint.Value := BGRA(0,0,0);

  // label current level
  FLabelLevel := TUILabel.Create(FScene, '', FFontText);
  AddChild(FLabelLevel);
  FLabelLevel.Tint.Value := BGRA(220,220,220);
  UpdateLabelCurrentLevel;
  FLabelLevel.MouseInteractionEnabled := False;
  FLabelLevel.AnchorPosToParent(haCenter, haLeft, FCellWidth+FCellWidth div 2,
                                vaCenter, vaCenter, -FFontText.Font.FontHeight div 2);
  FLabelLevel.Visible := FItemDescriptor.Owned;

  // label MAX level
  FLabelMax := TUILabel.Create(FScene, sMax, FFontText);
  AddChild(FLabelMax);
  FLabelMax.Tint.Value := BGRA(255,255,0);
  FLabelMax.MouseInteractionEnabled := False;
  FLabelMax.AnchorPosToSurface(FLabelLevel, haCenter, haCenter, 0,
                               vaTop, vaBottom, 0);
  FLabelMax.Visible := not FItemDescriptor.LevelCanBeUpgraded and FItemDescriptor.Owned;

  // label next level
  FLabelNextLevel := TUILabel.Create(FScene, sNextLevel, FFontText);
  AddChild(FLabelNextLevel);
  FLabelNextLevel.Tint.Value := BGRA(220,220,220);
  FLabelNextLevel.MouseInteractionEnabled := False;
  FLabelNextLevel.AnchorPosToParent(haCenter, haLeft, FCellWidth*2+FCellWidth div 2,
                                    vaCenter, vaCenter, -FFontText.Font.FontHeight div 2);
  FLabelNextLevel.Visible := FItemDescriptor.LevelCanBeUpgraded and FItemDescriptor.Owned;
  UpdateLabelNextLevel;

  // next level price
  UpdateItemNeededForNextLevel;

  // button upgrade
  case FItemDescriptor.ActionToOwnItem of
    atoiBuy: if FItemDescriptor.Owned then s := sUpgrade else s := sBuy;
    atoiBuild: if FItemDescriptor.Owned then s := sUpgrade else s := sBuild;
    else raise exception.Create('forgot to implement');
  end;
  BUpgrade := TUIButton.Create(FScene, s, FFontText, NIL);
  AddChild(BUpgrade);
  BUpgrade.BodyShape.SetShapeRoundRect(20, 20, PPIScale(8), PPIScale(8), PPIScale(2));
  BUpgrade._Label.Tint.Value := BGRA(255,255,0);
  BUpgrade.OnClick := @ProcessButtonClick;
  BUpgrade.AnchorPosToParent(haCenter, haLeft, FCellWidth*3+FCellWidth div 2,
                             vaCenter, vaCenter, 0);
  BUpgrade.Visible := FItemDescriptor.CanBePurchased and FItemDescriptor.LevelCanBeUpgraded;

  // text
  FText := TUITextArea.Create(FScene);
  AddChild(FText);
  FText.BodyShape.SetShapeRectangle(FCellWidth*3, ClientArea.Height, 0);
  FText.BodyShape.Fill.Visible := False;
  FText.BodyShape.Border.Visible := False;
  FText.Text.Align := taCenterCenter;
  FText.Text.TexturedFont := FFontText;
  UpdateTextExplanation;
  FText.AnchorPosToParent(haLeft, haLeft, FCellWidth*4, vaCenter, vaCenter, 0);
end;

{ TScreenWorkShop }

procedure TScreenWorkShop.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  if Sender = BExit then begin
    FScene.RunScreen(ScreenMap);
  end;
end;

procedure TScreenWorkShop.ProcessOnUpgradeRequestEvent(Sender: TSimpleSurfaceWithEffect);
var o: TUpgradableItem;
  A: ArrayOfMoneyDescriptor;
  i: integer;
begin
  o := TUpgradableItem(Sender);
  A := o.ItemDescriptor.PriceForNextLevel;
  if length(A) = 0 then exit;

  for i:=0 to High(A) do begin
    case A[i].MoneyType of
      mtCoin: FPlayerItemPanel.AddToCoinCounter(-A[i].Count);
      mtPurpleCristal: FPlayerItemPanel.AddToPurpleCristalCounter(-A[i].Count);
      else raise exception.create('forgot to implement this money type');
    end;
  end;
  ClearMessageList;
  PostMessage(0);
end;

procedure TScreenWorkShop.CreateObjects;
var pe, smoke: TParticleEmitter;
  home, o2, frameDoor: TSprite;
begin
  Audio.PauseMusicTitleMap(3.0);
  FFireSound := Audio.AddSound('fire-crackle-and-flames-001.ogg');
  FFireSound.Loop := True;
  FFireSound.FadeIn(1.0, 2.0);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;
  texHomeBG := FAtlas.AddFromSVG(SpriteBGFolder+'LRHomeInner.svg', FScene.Width, -1);
  texFireBG := FAtlas.AddFromSVG(SpriteBGFolder+'LRHomeInnerFireBG.svg', Round(FScene.Width*0.1354), -1);
  FAtlas.Add(ParticleFolder+'Flame.png');
  FAtlas.Add(ParticleFolder+'sphere_particle.png');
  FFontText := CreateGameFontText(FAtlas);

  CreateGameFontNumber(FAtlas);
  LoadCoinTexture(FAtlas);
  LoadCristalGrayTexture(FAtlas);
  LoadWatchTexture(FAtlas);

  texDoor := FAtlas.AddFromSVG(SpriteBGFolder+'LRHomeInnerDoor.svg', Round(FScene.Width*0.1585), -1);
  texDoorFrame := FAtlas.AddFromSVG(SpriteBGFolder+'LRHomeInnerDoorFrame.svg', Round(FScene.Width*0.1854), -1);
  LoadMousePointerTexture(FAtlas);

  LoadLRFaceTextures(FAtlas);
  LoadLRFrontViewTextures(FAtlas);

  FItemHeight := ScaleH(70);
  texCoin := FAtlas.AddFromSVG(SpriteUIFolder+'Coin.svg', -1, Round(FFontText.Font.FontHeight*0.8));
  texSmallCristalGray := FAtlas.AddFromSVG(SpriteUIFolder+'CristalGray.svg', -1, Round(FFontText.Font.FontHeight*0.8));

  texBow := FAtlas.AddFromSVG(SpriteUIFolder+'Bow.svg', -1, FItemHeight);
  texElevator := FAtlas.AddFromSVG(SpriteUIFolder+'ElevatorEngine.svg', -1, FItemHeight);
  texHammer := FAtlas.AddFromSVG(SpriteCommonFolder+'HammerHead.svg', -1, FItemHeight);
  texStormCloud := FAtlas.AddFromSVG(SpriteCommonFolder+'StormCloud.svg', -1, FItemHeight);
  texZipLine := FAtlas.AddFromSVG(SpriteUIFolder+'ZipLine.svg', -1, FItemHeight);
  texDigicodeDecoder := FAtlas.AddFromSVG(SpriteUIFolder+'DigicodeDecoder.svg', -1, FItemHeight);

  FAtlas.TryToPack;
  FAtlas.Build;
  {ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;}


  // home bg
  home := TSprite.Create(texHomeBG, False);
  FScene.Add(home, LAYER_BG1);
  home.SetCoordinate(0, 0);

  // fire BG
  o2 := TSprite.Create(texFireBG, False);
  home.AddChild(o2, -1);
  o2.SetCenterCoordinate(home.Width*0.46, home.Height*0.59);
  pe := TParticleEmitter.Create(FScene);
  o2.AddChild(pe, 0);
  pe.LoadFromFile(ParticleFolder+'FireWorkShop.par', FAtlas);
  pe.SetCoordinate(o2.Width*0.30, o2.Height*0.70);
  pe.SetEmitterTypeRectangle(Round(o2.Width*0.40), Round(o2.Height*0.1));
  smoke := TParticleEmitter.Create(FScene);
  o2.AddChild(smoke, 0);
  smoke.LoadFromFile(ParticleFolder+'WorkShopSmoke.par', FAtlas);
  smoke.SetCoordinate(o2.Width*0.40, o2.Height*0.70);
  smoke.SetEmitterTypeRectangle(Round(o2.Width*0.20), Round(o2.Height*0.1));

  // LR
  FLR := TLRFrontView.Create;
  home.AddChild(FLR, 0);
  FLR.SetCoordinateByFeet(home.Width*0.88, home.Height*0.985);
  FLR.HideBasket;
  FLR.SetFlipH(True);
  FLR.SetWindSpeed(0.1);

  // buttons
  BExit := TImageButton.Create(texDoor);
  home.AddChild(BExit, 0);
  BExit.OnClick := @ProcessButtonClick;
  BExit.SetCoordinate(home.Width*0.1056, home.Height*0.3006);

  // frame door
  frameDoor := TSprite.Create(texDoorFrame, False);
  home.AddChild(frameDoor, 1);
  frameDoor.SetCoordinate(home.Width*0.0997, home.Height*0.23);

  // player items panel
  FPlayerItemPanel := TInMapPanel.Create;

  // Panel Items
  FPanelItem := TPanelItems.Create(0, home.BottomY);

  with PlayerInfo.Forest do begin
    // item Bow
    FPanelItem.AddItem(Bow, texBow);
    // item Elevator
    FPanelItem.AddItem(Elevator, texElevator);
    // item Hammer
    FPanelItem.AddItem(Hammer, texHammer);
    // item StormCloud
    FPanelItem.AddItem(StormCloud, texStormCloud);
  end;

  // item ZipLine
  with PlayerInfo.MountainPeak do FPanelItem.AddItem(ZipLine, texZipLine);

  // item decoder
  if PlayerInfo.Volcano.HaveDecoderPlan or PlayerInfo.Volcano.DigicodeDecoder.Owned then
    FPanelItem.AddItem(PlayerInfo.Volcano.DigicodeDecoder, texDigicodeDecoder);

  CustomizeMousePointer;
end;

procedure TScreenWorkShop.FreeObjects;
begin
  FFireSound.FadeOutThenKill(1.0);
  Audio.ResumeMusicTitleMap(3.0);

  FreeMousePointer;
  FScene.ClearAllLayer;
  FreeAndNil(FAtlas);
end;

procedure TScreenWorkShop.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin
      FLR.MoveArmsAsWinner;
      FLR.Face.SetFaceType(lrfHappy);
      Audio.PlayVoiceWhowhooo;
      PostMessage(1, 1.5);
    end;
    1: begin
      FLR.MoveArmIdlePosition;
      FLR.Face.SetFaceType(lrfSmile);
    end;
  end;
end;

end.

