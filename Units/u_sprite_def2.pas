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

implementation

uses u_common, u_app, u_resourcestring, LazUTF8;

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

end.

