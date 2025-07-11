unit u_sprite_def2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  ALSound, OGLCScene, BGRABitmap, BGRABitmapTypes,
  u_audio, u_ui_panels, u_sprite_def;

type

// only one button to start sequence

TPanelUsingControlPanel0 = class(TBasePanelUsingSomething)
private class var texCancel: PTexture;
private
  FSequenceStarted, FIsCancelled: boolean;
  FKeyboardToButtons: TButtonsClickableByKeyboard;
  procedure SetAnimCallBackOn(aButton: TUIButton);
  procedure ProcessAnimButtonMouseEnter(Sender: TSimpleSurfaceWithEffect);
  procedure ProcessAnimButtonMouseLeave(Sender: TSimpleSurfaceWithEffect);
  procedure ProcessAnimButtonClick(Sender: TSimpleSurfaceWithEffect);
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
public
  BCancel, BStart: TUIButton;
  class procedure LoadTextures(aAtlas: TAtlas);
  constructor Create(const aButtonCaption: string; aFont: TTexturedFont; aAtlas: TAtlas);
  procedure Show; override;
  property SequenceStarted: boolean read FSequenceStarted;
  property IsCancelled: boolean read FIsCancelled;
end;


{ TSeagullBase }

TSeagullBase = class(TSprite)
private class var texSeagullBody, texSeagullWing: PTexture;
private
  FLeftWing, FRightWing: TSprite;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  class procedure LoadTexture(aAtlas: TAtlas);
  constructor Create(aLayerIndex: integer);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

{ TSeagullFlyInRectangle }

TSeagullFlyInRectangle = class(TSeagullBase)
  FTimeAccu, FThresholdX, FThresholdY: single;
  constructor Create(aLayerIndex: integer);
  procedure Update(const aElapsedTime: single); override;
  function ComputeHSpeed: single; virtual;
  function ComputeVSpeed: single; virtual;
  procedure ComputeTimeToChangeY; virtual;
  procedure ComputeLeftThresholdX; virtual;
  procedure ComputeRightThresholdX; virtual;
  procedure ComputeUpThresholdY; virtual;
  procedure ComputeDownThresholdY; virtual;
end;


{ TMarcusHelicopter }

TMarcusHelicopter = class(TSprite)
private class var texBody, texMainPropeller, texQueuePropeller: PTexture;
private
  FMainPropeller, FQueuePropeller: TSprite;
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  class procedure LoadTexture(aAtlas: TAtlas);
  constructor Create(aLayerIndex: integer);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

{ TCircularGauge }
// a circular gauge with an arrow.
// The arrow is vertical and move from -135° (0%) to 135° (100%)
TCircularGauge = class(TSprite)
private
  FArrow: TSprite;
  FBlinkCount: integer;
  FWantedAngle: integer;
  function GetPercent: single;
  procedure SetPercent(AValue: single);
public
  constructor Create(aTexBody, aTexArrow: PTexture);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure BlinkRed;
  procedure AddDelta(aDelta: single);
  property Percent: single read GetPercent write SetPercent;
end;

{ TLed }

TLed = class(TSprite)
private
  FBlinkColor: TBGRAPixel;
  FBlinking, FPlaySound: boolean;
public
  constructor Create(aTexBlack: PTexture);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure StartToBlink(aColor: TBGRAPixel; aPlayBeep: boolean);
  procedure StopToBlink;
end;

{ TWave1 }

TWave1 = class(TDeformationGrid)
private
  FTime: single;
public
  constructor Create(aTexture: PTexture; aX, aY: single; aLayerIndex: integer=-1);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;



implementation

uses u_common, u_app, u_resourcestring, LazUTF8, Math;

{ TPanelUsingControlPanel0 }

procedure TPanelUsingControlPanel0.SetAnimCallBackOn(aButton: TUIButton);
begin
  aButton.OnAnimMouseEnter := @ProcessAnimButtonMouseEnter;
  aButton.OnAnimMouseLeave := @ProcessAnimButtonMouseLeave;
  aButton.OnAnimClick := @ProcessAnimButtonClick;
end;

procedure TPanelUsingControlPanel0.ProcessAnimButtonMouseEnter(Sender: TSimpleSurfaceWithEffect);
begin
  Sender.Scale.Value := PointF(1.1, 1.1);
end;

procedure TPanelUsingControlPanel0.ProcessAnimButtonMouseLeave(Sender: TSimpleSurfaceWithEffect);
begin
  Sender.Scale.Value := PointF(1.0, 1.0);
end;

procedure TPanelUsingControlPanel0.ProcessAnimButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  TUIButton(Sender).Tint.Value := BGRA(255,255,255);
  TUIButton(Sender).Tint.Alpha.ChangeTo(0, 0.25);
end;

procedure TPanelUsingControlPanel0.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin
  if Sender = BCancel then
    FIsCancelled := True;

  if Sender = BStart then
    FSequenceStarted := True;
end;

class procedure TPanelUsingControlPanel0.LoadTextures(aAtlas: TAtlas);
begin
  texCancel := aAtlas.RetrieveTextureByFileName('Cancel.svg');
  if texCancel = NIL then
    texCancel := aAtlas.AddFromSVG(SpriteUIFolder+'Cancel.svg', ScaleW(22), -1);
end;

constructor TPanelUsingControlPanel0.Create(const aButtonCaption: string;
  aFont: TTexturedFont; aAtlas: TAtlas);
var w, h: integer;
begin
  w := ScaleW(373);
  h := ScaleH(214);
  inherited CreateAsRect(w, h);
  BodyShape.Fill.Color := BGRA(77,124,192);
  CenterOnScene;

  // cancel button
  BCancel := TUIButton.Create(FScene, '', NIL, texCancel);
  AddChild(BCancel, 0);
  SetAnimCallBackOn(BCancel);
  BCancel.OnClick := @ProcessButtonClick;
  BCancel.AnchorPosToParent(haRight, haRight, PPIScale(3), vaTop, vaTop, PPIScale(3));

  // start button
  BStart := TUIButton.Create(FScene, aButtonCaption, aFont, NIL);
  AddChild(BStart, 0);
  SetAnimCallBackOn(BStart);
  BStart.OnClick := @ProcessButtonClick;
  BStart._Label.Tint.Value := BGRA(200,200,200);
  BStart.AnchorPosToParent(haCenter, haCenter, 0, vaCenter, vaCenter, 0);

  FKeyboardToButtons := TButtonsClickableByKeyboard.Create(Self, aAtlas);
  FKeyboardToButtons.AddLineOfButtons([BCancel]);
  FKeyboardToButtons.AddLineOfButtons([BStart]);
  FKeyboardToButtons.Select(BStart);
end;

procedure TPanelUsingControlPanel0.Show;
begin
  inherited Show;
  FScene.Mouse.MouseSprite.Visible := True;
  FSequenceStarted := False;
  FIsCancelled := False;
end;

{ TSeagullBase }

procedure TSeagullBase.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FLeftWing.FlipH := AValue;
  FRightWing.FlipH := AValue;
end;

procedure TSeagullBase.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FLeftWing.FlipV := AValue;
  FRightWing.FlipV := AValue;
end;

class procedure TSeagullBase.LoadTexture(aAtlas: TAtlas);
begin
  texSeagullBody := aAtlas.AddFromSVG(SpriteMapFolder+'SeagullBody.svg', ScaleW(59), -1);
  texSeagullWing := aAtlas.AddFromSVG(SpriteMapFolder+'SeagullWing.svg', ScaleW(23), -1);
end;

constructor TSeagullBase.Create(aLayerIndex: integer);
begin
  inherited Create(texSeagullBody, False);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);

  FLeftWing := CreateSpriteChild(texSeagullWing, False, 1);
  FLeftWing.SetCoordinate(Width*0.6, -FLeftWing.Height*0.5);
  FLeftWing.Pivot := PointF(0.0, 1.0);
  FLeftWing.ApplySymmetryWhenFlip := True;

  FRightWing :=  CreateSpriteChild(texSeagullWing, False, -1);
  FRightWing.SetCoordinate(Width*0.46, -FRightWing.Height*0.8);
  FRightWing.Pivot := PointF(0.0, 1.0);
  FRightWing.ApplySymmetryWhenFlip := True;

  PostMessage(0); // anim wings
end;

procedure TSeagullBase.ProcessMessage(UserValue: TUserMessageValue);
const d = 0.25;
begin
  case UserValue of
    0: begin
      FLeftWing.Angle.ChangeTo(63, d, idcDrop);
      FRightWing.Angle.ChangeTo(67, d, idcDrop);
      PostMessage(2, d);
    end;
    2: begin
      FLeftWing.Angle.ChangeTo(0, d, idcSinusoid);
      FRightWing.Angle.ChangeTo(0, d, idcSinusoid);
      PostMessage(0, d);
    end;
  end;
end;

{ TSeagullFlyInRectangle }

constructor TSeagullFlyInRectangle.Create(aLayerIndex: integer);
var v: single;
begin
  inherited Create(aLayerIndex);

  SetCoordinate(ScaleW(166)+Random*ScaleW(370), ScaleH(130)+Random*ScaleH(450));
  Speed.Value := PointF(ComputeHSpeed, ComputeVSpeed);
  if Random>0.5 then Speed.x.Value := -Speed.x.Value;
  if Random>0.5 then Speed.y.Value := -Speed.y.Value;
  FlipH := Speed.X.Value > 0;
  if Speed.X.Value > 0 then ComputeRightThresholdX
    else ComputeLeftThresholdX;
  ComputeTimeToChangeY;

  v := 1.0+Random*0.25-0.125;
  Scale.Value := PointF(v, v);

  Update(Random);
  Update(Random);
  Update(Random);
end;

procedure TSeagullFlyInRectangle.Update(const aElapsedTime: single);
var v: single;
begin
  inherited Update(aElapsedTime);

  if (Speed.X.Value < 0) and (X.Value < FThresholdX) then begin
    Speed.X.Value := ComputeHSpeed;
    ComputeRightThresholdX;
    FlipH := True;
  end;

  if (Speed.X.Value > 0) and (X.Value > FThresholdX) then begin
    Speed.X.Value := -ComputeHSpeed;
    ComputeLeftThresholdX;
    FlipH := False;
  end;

  FTimeAccu := FTimeAccu - aElapsedTime;
  if FTimeAccu <= 0 then begin
    ComputeTimeToChangeY;
    //Speed.Y.Value := EnsureRange(Speed.Y.Value+Random*0.5-0.25, -PPIScale(5), PPIScale(5));
    v := ComputeVSpeed;
    if Sign(Speed.Y.Value) = Sign(v) then v := -v;
    Speed.Y.ChangeTo(v, FTimeAccu*0.5, idcSinusoid);
  end;

  if (Y.Value <= FThresholdY) and (Speed.Y.Value < 0) then
    Speed.Y.Value := Random*3;       //ComputeVSpeed

  if (Y.Value >= FThresholdY) and (Speed.Y.Value > 0) then
    Speed.Y.Value := -Random*3;

  if not FlipH then Angle.Value := -Speed.Y.Value*3
    else Angle.Value := Speed.Y.Value*3;
  Angle.Value := EnsureRange(Angle.Value, -35, 35);
end;

function TSeagullFlyInRectangle.ComputeHSpeed: single;
begin
  Result := FScene.Width*0.01+Random*FScene.Width*0.008;
end;

function TSeagullFlyInRectangle.ComputeVSpeed: single;
begin
  Result := Random * PPIScale(20) - PPIScale(10);
end;

procedure TSeagullFlyInRectangle.ComputeTimeToChangeY;
begin
  FTimeAccu := 3 + Random*3;
end;

procedure TSeagullFlyInRectangle.ComputeLeftThresholdX;
begin
  FThresholdX := ScaleW(90) + Random*ScaleW(190);
end;

procedure TSeagullFlyInRectangle.ComputeRightThresholdX;
begin
  FThresholdX := ScaleW(360) + Random*ScaleW(240);
end;

procedure TSeagullFlyInRectangle.ComputeUpThresholdY;
begin
  FThresholdY := ScaleH(70);
end;

procedure TSeagullFlyInRectangle.ComputeDownThresholdY;
begin
  FThresholdY := ScaleH(580);
end;

{ TMarcusHelicopter }

procedure TMarcusHelicopter.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FMainPropeller.FlipH := AValue;
  FQueuePropeller.FlipH := AValue;
end;

procedure TMarcusHelicopter.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FMainPropeller.FlipV := AValue;
  FQueuePropeller.FlipV := AValue;
end;

class procedure TMarcusHelicopter.LoadTexture(aAtlas: TAtlas);
begin
  texBody := aAtlas.AddFromSVG(FolderSpriteGameMermaidsPort+'HelicoBody.svg', ScaleW(518), -1);
  texMainPropeller := aAtlas.AddFromSVG(FolderSpriteGameMermaidsPort+'HelicoMainPropeller.svg', ScaleW(283), -1);
  texQueuePropeller := aAtlas.AddFromSVG(FolderSpriteGameMermaidsPort+'HelicoQueuePropeller.svg', ScaleW(79), -1);
end;

constructor TMarcusHelicopter.Create(aLayerIndex: integer);
begin
  inherited Create(texBody, False);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);

  FMainPropeller := CreateSpriteChild(texMainPropeller, False, -1);
  FMainPropeller.SetCoordinate(Width*0.04, Height*0.13);
 // FMainPropeller.ApplySymmetryWhenFlip := True;

  FQueuePropeller := CreateSpriteChild(texQueuePropeller, False, 0);
  FQueuePropeller.SetCoordinate(Width*0.8, Height*0.28);
  FQueuePropeller.ApplySymmetryWhenFlip := True;
  FQueuePropeller.Angle.AddConstant(360*3);
  PostMessage(0); // propeller anim
end;

procedure TMarcusHelicopter.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // propeller anim
    0: begin
     FMainPropeller.FlipH := not FMainPropeller.FlipH;
 //    if FMainPropeller.FlipH then FMainPropeller.X.Value := Width-Width*0.04
 //      else FMainPropeller.X.Value := Width*0.04;
     PostMessage(0, 0.03);
    end;
  end;
end;

{ TCircularGauge }

function TCircularGauge.GetPercent: single;
begin
  Result := (FWantedAngle + 135) / 270;
end;

procedure TCircularGauge.SetPercent(AValue: single);
begin
  AValue := EnsureRange(AValue, 0, 1);
  FWantedAngle := Round(AValue * 270 - 135);
  //FArrow.Angle.Value := FWantedAngle;
end;

constructor TCircularGauge.Create(aTexBody, aTexArrow: PTexture);
begin
  inherited Create(aTexBody, False);

  FArrow := TSprite.Create(aTexArrow, False);
  AddChild(FArrow, 0);
  FArrow.CenterX := Width*0.5;
  FArrow.BottomY := Height*0.5;
  FArrow.Pivot := PointF(0.5, 1.0);

  PostMessage(100);
end;

procedure TCircularGauge.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // red blink anim
    0: begin
     if FBlinkCount <= 0 then exit;
     dec(FBlinkCount);
     Tint.Value := BGRA(255,50,50,200);
     PostMessage(5, 0.2);
    end;
    5: begin
     Tint.Alpha.Value := 0;
     PostMessage(0, 0.2);
    end;

    // arrow moves
    100: begin
       if FWantedAngle-FArrow.Angle.Value > 2 then FArrow.Angle.Value := FArrow.Angle.Value+2
       else
       if FWantedAngle-FArrow.Angle.Value < -2 then FArrow.Angle.Value := FArrow.Angle.Value-2
       else FArrow.Angle.Value := FWantedAngle;
       PostMessage(100, 0.02);
    end;
  end;
end;

procedure TCircularGauge.BlinkRed;
begin
  if FBlinkCount > 0 then exit;
  FBlinkCount := 4;
  PostMessage(0);
end;

procedure TCircularGauge.AddDelta(aDelta: single);
begin
  Percent := Percent + aDelta;
end;

{ TLed }

constructor TLed.Create(aTexBlack: PTexture);
begin
  inherited Create(aTexBlack, False);
end;

procedure TLed.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin
      if not FBlinking then exit;
      Tint.Value := FBlinkColor;
      if FPlaySound then
        Audio.PlayThenKillSound('button-beep_Short.ogg', 0.6, 0.0, 0.8);
      PostMessage(5, 0.4);
    end;
    5: begin
      Tint.Alpha.Value := 0;
      PostMessage(0, 0.4);
    end;
  end;
end;

procedure TLed.StartToBlink(aColor: TBGRAPixel; aPlayBeep: boolean);
begin
  if FBlinking then exit;
  FBlinkColor := aColor;
  FBlinking := True;
  FPlaySound := aPlayBeep;
  PostMessage(0);
end;

procedure TLed.StopToBlink;
begin
  FBlinking := False;
  Tint.Alpha.Value := 0;
end;

{ TWave1 }

constructor TWave1.Create(aTexture: PTexture; aX, aY: single; aLayerIndex: integer);
const SCALEMIN = 0.15;
      SCALEMAX = 1.2;
var sc: single;
begin
  inherited Create(aTexture, False);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);

  SetCoordinate(aX, aY);
  SetGrid(2, 4);
  ApplyDeformation(dtSnakeV);
  FTime := Random*0.5 + 1.0;
  SetTimeMultiplicatorOnRow(0, FTime);
  SetTimeMultiplicatorOnRow(1, FTime);
  SetTimeMultiplicatorOnRow(2, FTime);
  FTime := FTime * 2;

  // scale max=1.2 scale min=0.5
  sc := (aY - ScaleH(474))/ScaleH(296) * (SCALEMAX - SCALEMIN) + SCALEMIN;
  Scale.Value := PointF(sc, sc);
  Update(Random);
  Update(Random);
  Update(Random);
  PostMessage(0);
  PostMessage(10);
end;

procedure TWave1.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin
      X.ChangeTo(X.Value-ScaledWidth*0.2, FTime, Random(4)+1);
      Y.ChangeTo(Y.Value+ScaledHeight*0.8, FTime, Random(4)+1);
      PostMessage(5, FTime);
    end;
    5: begin
      X.ChangeTo(X.Value+ScaledWidth*0.2, FTime, Random(4)+1);
      Y.ChangeTo(Y.Value-ScaledHeight*0.8, FTime, Random(4)+1);
      PostMessage(0, FTime);
    end;
    10: begin
      Tint.Value := BGRA(255,255,255);//,Random(100)+150);
      PostMessage(15, 1.0);
    end;
    15: begin
      Tint.alpha.Value := 0;
      PostMessage(10, Random);
    end;
  end;
end;

end.

