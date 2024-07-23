unit u_sprite_lrcommon;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

type

{ TBaseComplexSprite }

TBaseComplexSprite = class(TSprite)
  function CreateChildSprite(aTex: PTexture; aZOrder: integer): TSprite;
  function CreateChildPolar(aTex: PTexture; aZOrder: integer): TPolarSprite;
  function CreateChildDeformationGrid(aTex: PTexture; aZOrder: integer): TDeformationGrid;
end;

{ TBaseComplexContainer }

TBaseComplexContainer = class(TSpriteContainer)
private
  FDeltaYToBottom, FDeltaYToTop: single;
  FBodyWidth, FBodyHeight: integer;
public
  function CreateChildSprite(aTex: PTexture; aZOrder: integer): TSprite;
  function CreateChildPolar(aTex: PTexture; aZOrder: integer): TPolarSprite;
  function CreateChildDeformationGrid(aTex: PTexture; aZOrder: integer): TDeformationGrid;
public
  function GetYTop: single;
  function GetYBottom: single;
  function CheckCollisionWith(aX, aY, aWidth, aHeight: single): boolean;
  // init in descendent classes
  property DeltaYToTop: single read FDeltaYToTop write FDeltaYToTop;
  property DeltaYToBottom: single read FDeltaYToBottom write FDeltaYToBottom;
  property BodyWidth: integer read FBodyWidth write FBodyWidth;
  property BodyHeight: integer read FBodyHeight write FBodyHeight;
end;

{ TWalkingCharacter }

TWalkingCharacter = class(TBaseComplexContainer)
private type TMovingDirection = (mdNone=0, mdLeft, mdRight, mdUp, mdDown,
                                 mdLeftDown, mdLeftUp, mdRightDown, mdRightUp);
private
  FMovingDirection: TMovingDirection;
  FTargetPoint: TPointF;
  FTargetScreen: TScreenTemplate;
  FMessageValueWhenFinish: TUserMessageValue;
  FDelay: single;
public
  procedure Update(const aElapsedTime: single); override;
  procedure CheckHorizontalMoveToX(aX: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
  procedure CheckVerticalMoveToY(aY: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
  procedure CheckMoveTo(aX, aY: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
end;

{ TCharacterWithMark }

TCharacterWithMark = class(TWalkingCharacter)
private
  FExclamationMark, FQuestionMark: TSprite;
public
  destructor Destroy; override;
  procedure ShowExclamationMark;
  procedure ShowQuestionMark;
  procedure HideMark;
end;


{ TCharacterWithDialogPanel }

TCharacterWithDialogPanel = class(TCharacterWithMark)
private
  FDialogAuthorName: string;
  FPanel: TUITextArea;
  FDialogTextColor: TBGRAPixel;
  FDialogOldProcessSceneClick: TOGLCMouseEvent;
  FDialogTargetScreen: TScreenTemplate;
  FDialogMessageValueWhenFinish: TUserMessageValue;
  FDialogDelay: Single;
  procedure ProcessSceneClick({%H-}Button: TMouseButton; {%H-}Shift: TShiftState; {%H-}aX, {%H-}aY: Integer);
  procedure Init;
  procedure CreateLabelAuthor(aTexturedFont: TTexturedFont);
public
  procedure ShowDialog(const aText: string; aTexturedFont: TTexturedFont;
             aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
  procedure ShowDialog(const aText: string; aTexturedFont: TTexturedFont; aLifeTime: single=4.0);
  property DialogTextColor: TBGRAPixel read FDialogTextColor write FDialogTextColor;
  property DialogAuthorName: string read FDialogAuthorName write FDialogAuthorName;
end;


{ TInfoPanel }

TInfoPanel = class(TUITextArea)
private
  FOldProcessSceneClick: TOGLCMouseEvent;
  FTargetScreen: TScreenTemplate;
  FMessageValueWhenFinish: TUserMessageValue;
  FDelay: Single;
  procedure ProcessSceneClick({%H-}Button: TMouseButton; {%H-}Shift: TShiftState; {%H-}aX, {%H-}aY: Integer);
  procedure Init;
  procedure CreateLabelAuthor(const aAuthor: string; aTexturedFont: TTexturedFont);
public
  constructor Create(const aAuthor, aText: string; aTexturedFont: TTexturedFont;
             aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
  constructor Create(const aAuthor, aText: string; aTexturedFont: TTexturedFont; aLifeTime: single=4.0);
end;


TLRFaceType = (lrfSmile, lrfHappy, lrfNotHappy, lrfWorry, lrfBroken, lrfVomit);

{ TLRBaseFace }

TLRBaseFace = class(TBaseComplexSprite)
private
  FOriginCenterCoor: TPointF;
  FFaceType: TLRFaceType;
  FEyeMaxDistance: single;
  function EyeCanBlink: boolean;
public
  LeftEye, RightEye: TPolarSprite;
  HairLock: TSprite;
  procedure SetFaceType(AValue: TLRFaceType); virtual;
  procedure SetDeformationOnHair(aHair: TDeformationGrid);
  procedure SetWindSpeedOnHair(aHair: TDeformationGrid; aValue: single);
public
  constructor Create(aTexture: PTexture);
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  property OriginCenterCoor: TPointF write FOriginCenterCoor;
  property FaceType: TLRFaceType read FFaceType write SetFaceType;
  property EyeMaxDistance: single read FEyeMaxDistance write FEyeMaxDistance;
end;

{ TLRFace }

TLRFace = class(TLRBaseFace)
private
  Hair: TDeformationGrid;
  MouthNotHappy, MouthOpen, MouthSmile,
  WhiteBG: TSprite;
public
  procedure SetFaceType(AValue: TLRFaceType); override;
  constructor Create;
  procedure SetFlipH(AValue: boolean);
  procedure SetFlipV(AValue: boolean);
end;


{ TLRDress }

TLRDress = class(TDeformationGrid)
private
  procedure SetDeformation;
public
  constructor Create(aDressTexture: PTexture);
  procedure SetWindSpeed(AValue: single);
end;

{ TLRFrontView }

TLRFrontView = class(TBaseComplexContainer)
private
  FHood: TDeformationGrid;
  FDress: TLRDress;
  FBasket: TSprite;
  procedure SetDeformationOnHood;
public
  Face: TLRFace;
  RightArm, LeftArm, RightLeg, LeftLeg: TSprite;
  constructor Create;
  procedure SetFlipH(AValue: boolean);
  procedure SetFlipV(AValue: boolean);
  procedure HideBasket;
  procedure SetWindSpeed(AValue: single);
  procedure MoveArmsAsWinner;
  procedure MoveArmIdlePosition;
  procedure SetCoordinateByFeet(aCenterX, aY: single);
end;

procedure LoadLRFaceTextures(aAtlas: TOGLCTextureAtlas);
procedure LoadLRFrontViewTextures(aAtlas: TOGLCTextureAtlas);

procedure LoadCharacterMarkTextures(aAtlas: TOGLCTextureAtlas);
procedure LoadGameDialogTextures(aAtlas: TOGLCTextureAtlas);

implementation
uses u_app, u_common;

var
  // texture for dialog
  texGameDialogDownArrow: PTexture;
  // textures for character marks
  texExclamationMark, texQuestionMark: PTexture;
  // textures for Little Red Face
    texLRFace,
  //  texLRFaceBroken,
    texLRFaceBGWhite,
    texLRFaceEye,
    texLRFaceHairLock,
    texLRFaceHair,
    texLRFaceMouthHurt,
    texLRFaceMouthOpen,
    texLRFaceMouthSmile: PTexture;

    texLRFrontViewHood,
    texLRFrontViewDress,
    texLRFrontViewLeftArm, texLRFrontViewRightArm,
    texLRFrontViewLeftLeg, texLRFrontViewRightLeg,
    texLRFrontViewBasket: PTexture;

procedure LoadLRFaceTextures(aAtlas: TOGLCTextureAtlas);
begin
  texLRFace := aAtlas.AddMultiFrameImageFromSVG([SpriteFolder+'LittleRedFaceEyeOpen.svg',
                                                 SpriteFolder+'LittleRedFaceEyeClose.svg',
                                                 SpriteFolder+'LittleRedFaceBroken.svg'], ScaleW(57), -1, 1, 3, 1);
  texLRFaceBGWhite := aAtlas.AddFromSVG(SpriteFolder+'LittleRedFaceBGWhite.svg', ScaleW(44), -1);
  texLRFaceEye := aAtlas.AddFromSVG(SpriteFolder+'LittleRedFaceEye.svg', ScaleW(11), -1);
  texLRFaceHair := aAtlas.AddFromSVG(SpriteFolder+'LittleRedHair.svg', ScaleW(57), -1);
  texLRFaceHairLock := aAtlas.AddFromSVG(SpriteFolder+'LittleRedFaceHairLock.svg', ScaleW(6), ScaleH(14));
  texLRFaceMouthHurt := aAtlas.AddFromSVG(SpriteFolder+'LittleRedFaceMouthHurt.svg', ScaleW(26), -1);
  texLRFaceMouthOpen :=aAtlas.AddFromSVG(SpriteFolder+'LittleRedFaceMouthOpen.svg', ScaleW(27), -1);
  texLRFaceMouthSmile := aAtlas.AddFromSVG(SpriteFolder+'LittleRedFaceMouthSmile.svg', ScaleW(33), -1);
end;

procedure LoadLRFrontViewTextures(aAtlas: TOGLCTextureAtlas);
var path: string;
begin
  path := SpriteLRPortraitFolder;
  texLRFrontViewHood := aAtlas.AddFromSVG(path+'Hood.svg', ScaleW(87), -1);
  texLRFrontViewDress := aAtlas.AddFromSVG(path+'Dress.svg', ScaleW(62), -1);
  texLRFrontViewLeftArm := aAtlas.AddFromSVG(path+'LeftArm.svg', ScaleW(23), -1);
  texLRFrontViewRightArm := aAtlas.AddFromSVG(path+'RightArm.svg', ScaleW(22), -1);
  texLRFrontViewLeftLeg := aAtlas.AddFromSVG(path+'LeftLeg.svg', ScaleW(20), -1);
  texLRFrontViewRightLeg := aAtlas.AddFromSVG(path+'RightLeg.svg', ScaleW(20), -1);
  texLRFrontViewBasket := aAtlas.AddFromSVG(path+'Basket.svg', ScaleW(26), -1);
end;

procedure LoadCharacterMarkTextures(aAtlas: TOGLCTextureAtlas);
var path: string;
begin
  path := SpriteCommonFolder;
  texExclamationMark := aAtlas.AddFromSVG(path+'MarkExclamation.svg', ScaleW(10), -1);
  texQuestionMark := aAtlas.AddFromSVG(path+'MarkQuestion.svg', ScaleW(21), -1);
end;

procedure LoadGameDialogTextures(aAtlas: TOGLCTextureAtlas);
begin
  texGameDialogDownArrow := aAtlas.AddFromSVG(SpriteUIFolder+'GameDialogDownArrow.svg', ScaleW(16), -1);
end;

{ TInfoPanel }

procedure TInfoPanel.ProcessSceneClick(Button: TMouseButton; Shift: TShiftState; aX, aY: Integer);
begin
  FScene.Mouse.OnClickOnScene := FOldProcessSceneClick;
  FTargetScreen.PostMessage(FMessageValueWhenFinish, FDelay);
  Kill;
end;

procedure TInfoPanel.Init;
begin
  MouseInteractionEnabled := False;
  ChildClippingEnabled := False;
  Text.Align := taCenterCenter;
  //Text.Tint.Value := FDialogTextColor;
  BodyShape.ResizeCurrentShape(Text.DrawingSize.cx+PPIScale(10)*2, Text.DrawingSize.cy+PPIScale(10*2), True);
  CenterOnScene;
end;

procedure TInfoPanel.CreateLabelAuthor(const aAuthor: string; aTexturedFont: TTexturedFont);
var o: TFreeText;
begin
  o := TFreeText.Create(FScene);
  AddChild(o, 0);
  o.TexturedFont := aTexturedFont;
  o.Caption := aAuthor;
  o.X.Value := PPIScale(5);
  o.BottomY := 0;
end;

constructor TInfoPanel.Create(const aAuthor, aText: string; aTexturedFont: TTexturedFont; aTargetScreen: TScreenTemplate;
  aMessageValueWhenFinish: TUserMessageValue; aDelay: single);
var o: TSprite;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_DIALOG);
  BodyShape.SetShapeRoundRect(Round(FScene.Width*0.3), 50, PPIScale(8), PPIScale(8), PPIScale(3));
  Text.TexturedFont := aTexturedFont;
  Text.Caption := aText;
  Init;

  o := TSprite.Create(texGameDialogDownArrow, False);
  AddChild(o, 0);
  o.Blink(-1, 0.4, 0.4);
  o.RightX := Width - o.Width*0.5;
  o.BottomY := Height - o.Height*0.5;

  //Author label
  CreateLabelAuthor(aAuthor, aTexturedFont);

  FOldProcessSceneClick := FScene.Mouse.OnClickOnScene;
  FScene.Mouse.OnClickOnScene := @ProcessSceneClick;

  FTargetScreen := aTargetScreen;
  FMessageValueWhenFinish := aMessageValueWhenFinish;
  FDelay := aDelay;
end;

constructor TInfoPanel.Create(const aAuthor, aText: string; aTexturedFont: TTexturedFont; aLifeTime: single);
begin
  Inherited Create(FScene);
  FScene.Add(Self, LAYER_DIALOG);
  BodyShape.SetShapeRoundRect(Round(FScene.Width*0.3), 50, PPIScale(8), PPIScale(8), PPIScale(3));
  Text.TexturedFont := aTexturedFont;
  Text.Align := taCenterCenter;
  Text.Caption := aText;
  Init;

  CreateLabelAuthor(aAuthor, aTexturedFont);

  KillDefered(aLifeTime);
end;

{ TCharacterWithDialogPanel }

procedure TCharacterWithDialogPanel.ProcessSceneClick(Button: TMouseButton; Shift: TShiftState; aX, aY: Integer);
begin
  FScene.Mouse.OnClickOnScene := FDialogOldProcessSceneClick;
  FDialogTargetScreen.PostMessage(FDialogMessageValueWhenFinish, FDialogDelay);
  if FPanel <> NIL then FPanel.Kill;
  FPanel := NIL;
end;

procedure TCharacterWithDialogPanel.Init;
var p: TPointF;
    w, h: single;
begin
  FPanel.MouseInteractionEnabled := False;
  FPanel.ChildClippingEnabled := False;
  FPanel.Text.Align := taCenterCenter;
  FPanel.Text.Tint.Value := FDialogTextColor;
  FPanel.BodyShape.ResizeCurrentShape(FPanel.Text.DrawingSize.cx+PPIScale(10)*2, FPanel.Text.DrawingSize.cy+PPIScale(10*2), True);
  w := FPanel.Width * 0.5;
  h := FPanel. Height * 0.5;

  p := PointF(X.Value, GetYTop - h*2);
  if p.x - w < 0 then p.x := w else
  if p.x + w > FScene.Width then p.x := FScene.Width - w else
  if p.y - h < 0 then p.y := h else
  if p.y + h > FScene.Height then p.y := FScene.Height - w;
  FPanel.SetCenterCoordinate(p);
end;

procedure TCharacterWithDialogPanel.CreateLabelAuthor(aTexturedFont: TTexturedFont);
var o: TFreeText;
begin
  o := TFreeText.Create(FScene);
  FPanel.AddChild(o, 0);
  o.TexturedFont := aTexturedFont;
  o.Caption := FDialogAuthorName;
  o.X.Value := PPIScale(5);
  o.BottomY := 0;
end;

procedure TCharacterWithDialogPanel.ShowDialog(const aText: string; aTexturedFont: TTexturedFont;
  aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single);
var o: TSprite;
begin
  if FPanel <> NIL then FPanel.Kill;
  FPanel := TUITextArea.Create(FScene);
  FScene.Add(FPanel, LAYER_DIALOG);
  FPanel.BodyShape.SetShapeRoundRect(Round(FScene.Width*0.3), 50, PPIScale(8), PPIScale(8), PPIScale(3));
  FPanel.Text.TexturedFont := aTexturedFont;
  FPanel.Text.Caption := aText;
  Init;
  CreateLabelAuthor(aTexturedFont);

  o := TSprite.Create(texGameDialogDownArrow, False);
  FPanel.AddChild(o, 0);
  o.Blink(-1, 0.4, 0.4);
  o.RightX := FPanel.Width - o.Width*0.5;
  o.BottomY := FPanel.Height - o.Height*0.5;

  FDialogOldProcessSceneClick := FScene.Mouse.OnClickOnScene;
  FScene.Mouse.OnClickOnScene := @ProcessSceneClick;

  FDialogTargetScreen := aTargetScreen;
  FDialogMessageValueWhenFinish := aMessageValueWhenFinish;
  FDialogDelay := aDelay;
end;

procedure TCharacterWithDialogPanel.ShowDialog(const aText: string;
  aTexturedFont: TTexturedFont; aLifeTime: single);
begin
  if FPanel <> NIL then FPanel.Kill;
  FPanel := TUITextArea.Create(FScene);
  FScene.Add(FPanel, LAYER_DIALOG);
  FPanel.BodyShape.SetShapeRoundRect(Round(FScene.Width*0.3), 50, PPIScale(8), PPIScale(8), PPIScale(3));
  FPanel.Text.TexturedFont := aTexturedFont;
  FPanel.Text.Align := taCenterCenter;
  FPanel.Text.Caption := aText;
  Init;
  CreateLabelAuthor(aTexturedFont);

  FPanel.KillDefered(aLifeTime);
  FPanel := NIL;
end;

{ TCharacterWithMark }

destructor TCharacterWithMark.Destroy;
begin
  HideMark;
  inherited Destroy;
end;

procedure TCharacterWithMark.ShowExclamationMark;
begin
  if FExclamationMark <> NIL then exit;
  if FQuestionMark <> NIL then FQuestionMark.Kill;
  FQuestionMark := NIL;

  FExclamationMark := TSprite.Create(texExclamationMark, False);
  //FScene.Add(FExclamationMark, LAYER_DIALOG);
  //FExclamationMark.BindToSprite(Self, -FExclamationMark.Width*0.5, DeltaYToTop);
  AddChild(FExclamationMark, 0);

  FExclamationMark.X.Value := -FExclamationMark.Width*0.5;
  FExclamationMark.Y.Value := -DeltaYToTop - FExclamationMark.Height;
end;

procedure TCharacterWithMark.ShowQuestionMark;
begin
  if FQuestionMark <> NIL then exit;
  if FExclamationMark <> NIL then FExclamationMark.Kill;
  FExclamationMark := NIL;

  FQuestionMark := TSprite.Create(texQuestionMark, False);
  //FScene.Add(FQuestionMark, LAYER_DIALOG);
  //FQuestionMark.BindToSprite(Self, -FQuestionMark.Width*0.5, DeltaYToTop);
  AddChild(FQuestionMark, 0);
  FQuestionMark.X.Value := -FQuestionMark.Width*0.5;
  FQuestionMark.Y.Value := -DeltaYToTop - FQuestionMark.Height;
end;

procedure TCharacterWithMark.HideMark;
begin
  if FExclamationMark <> NIL then FExclamationMark.Kill;
  if FQuestionMark <> NIL then FQuestionMark.Kill;
  FQuestionMark := NIL;
  FExclamationMark := NIL;
end;

{ TWalkingCharacter }

procedure TWalkingCharacter.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if FMovingDirection in [mdLeft, mdLeftDown, mdLeftUp] then begin
    if X.Value <= FTargetPoint.x then begin
      X.Value := FTargetPoint.x;
      Speed.X.Value := 0;
    end;
  end;
  if FMovingDirection in [mdRight, mdRightDown, mdRightUp] then begin
    if X.Value >= FTargetPoint.x then begin
       X.Value := FTargetPoint.x;
       Speed.X.Value := 0;
    end;
  end;
  if FMovingDirection in [mdUp, mdLeftUp, mdRightUp] then begin
    if Y.Value <= FTargetPoint.y then begin
       Y.Value := FTargetPoint.y;
       Speed.Y.Value := 0;
    end;
  end;
  if FMovingDirection in [mdDown, mdLeftDown, mdRightDown] then begin
    if Y.Value >= FTargetPoint.y then begin
       Y.Value := FTargetPoint.y;
       Speed.Y.Value := 0;
    end;
  end;

  // end of move ?
  if (Speed.X.Value = 0) and (Speed.Y.Value = 0) and (FMovingDirection <> mdNone) then begin
    FMovingDirection := mdNone;
    FTargetScreen.PostMessage(FMessageValueWhenFinish, FDelay);
  end;
end;

procedure TWalkingCharacter.CheckHorizontalMoveToX(aX: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single);
begin
  if X.Value = aX then begin
    FMovingDirection := mdNone;
    PostMessage(aMessageValueWhenFinish, aDelay);
    Speed.X.Value := 0;
    exit;
  end;
  if X.Value > aX then FMovingDirection := mdLeft
    else FMovingDirection := mdRight;

  FTargetPoint.x := aX;
  FTargetScreen := aTargetScreen;
  FMessageValueWhenFinish := aMessageValueWhenFinish;
  FDelay := aDelay;
end;

procedure TWalkingCharacter.CheckVerticalMoveToY(aY: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single);
begin
  aY := aY - FDeltaYToBottom;
  if Y.Value = aY then begin
    FMovingDirection := mdNone;
    PostMessage(aMessageValueWhenFinish, aDelay);
    Speed.Y.Value := 0;
    exit;
  end;
  if Y.Value > aY then FMovingDirection := mdUp
    else FMovingDirection := mdDown;

  FTargetPoint.y := aY;
  FTargetScreen := aTargetScreen;
  FMessageValueWhenFinish := aMessageValueWhenFinish;
  FDelay := aDelay;
end;

procedure TWalkingCharacter.CheckMoveTo(aX, aY: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single);
begin
  if (X.Value = aX) and (Y.Value = aY) then begin
    FMovingDirection := mdNone;
    PostMessage(aMessageValueWhenFinish, aDelay);
    Speed.Value := PointF(0, 0);
    exit;
  end;
  if X.Value = aX then begin
    CheckVerticalMoveToY(aY, aTargetScreen, aMessageValueWhenFinish, aDelay);
    exit;
  end;
  if Y.Value = aY then begin
    CheckHorizontalMoveToX(aX, aTargetScreen, aMessageValueWhenFinish, aDelay);
    exit;
  end;

  if X.Value > aX then
    if Y.Value > aY then FMovingDirection := mdLeftUp else FMovingDirection := mdLeftDown;

  if X.Value < aX then
    if Y.Value > aY then FMovingDirection := mdRightUp else FMovingDirection := mdRightDown;

  FTargetPoint := PointF(aX, aY);
  FTargetScreen := aTargetScreen;
  FMessageValueWhenFinish := aMessageValueWhenFinish;
  FDelay := aDelay;
end;

{ TBaseComplexContainer }

function TBaseComplexContainer.CreateChildSprite(aTex: PTexture; aZOrder: integer): TSprite;
begin
  Result := TSprite.Create(aTex, False);
  AddChild(Result, aZOrder);
  Result.ApplySymmetryWhenFlip := True;
end;

function TBaseComplexContainer.CreateChildPolar(aTex: PTexture; aZOrder: integer): TPolarSprite;
begin
  Result := TPolarSprite.Create(aTex, False);
  AddChild(Result, aZOrder);
  Result.ApplySymmetryWhenFlip := True;
end;

function TBaseComplexContainer.CreateChildDeformationGrid(aTex: PTexture; aZOrder: integer): TDeformationGrid;
begin
  Result := TDeformationGrid.Create(aTex, False);
  AddChild(Result, aZOrder);
  Result.ApplySymmetryWhenFlip := True;
end;

function TBaseComplexContainer.GetYTop: single;
begin
  Result := Y.Value - FDeltaYToTop;
end;

function TBaseComplexContainer.GetYBottom: single;
begin
  Result := Y.Value + FDeltaYToBottom;
end;

function TBaseComplexContainer.CheckCollisionWith(aX, aY, aWidth, aHeight: single): boolean;
var xx, yy, w, h: single;
begin
  xx := X.Value;
  yy := Y.Value;
  w := BodyWidth * 0.5;
  h := BodyHeight * 0.5;
  Result := not((aX > xx+w) or (aX+aWidth < xx-w) or (aY > yy+h) or (aY+aHeight < yy-h));
end;

{ TBaseComplexSprite }

function TBaseComplexSprite.CreateChildSprite(aTex: PTexture; aZOrder: integer): TSprite;
begin
  Result := TSprite.Create(aTex, False);
  AddChild(Result, aZOrder);
  Result.ApplySymmetryWhenFlip := True;
end;

function TBaseComplexSprite.CreateChildPolar(aTex: PTexture; aZOrder: integer): TPolarSprite;
begin
  Result := TPolarSprite.Create(aTex, False);
  AddChild(Result, aZOrder);
  Result.ApplySymmetryWhenFlip := True;
end;

function TBaseComplexSprite.CreateChildDeformationGrid(aTex: PTexture; aZOrder: integer): TDeformationGrid;
begin
  Result := TDeformationGrid.Create(aTex, False);
  AddChild(Result, aZOrder);
  Result.ApplySymmetryWhenFlip := True;
end;

{ TLRBaseFace }

function TLRBaseFace.EyeCanBlink: boolean;
begin
  Result := FFaceType <> lrfBroken;
end;

procedure TLRBaseFace.SetFaceType(AValue: TLRFaceType);
begin
  if (FFaceType = lrfVomit) then Tint.Alpha.ChangeTo(0, 0.5);

  FFaceType := AValue;
  case AValue of
    lrfSmile, lrfHappy, lrfNotHappy, lrfVomit: if Frame = 3 then Frame := 1;
    lrfBroken: Frame := 3;
  end;

  if AValue = lrfVomit then Tint.ChangeTo(BGRA(0,255,0,100), 0.5);
end;

procedure TLRBaseFace.SetDeformationOnHair(aHair: TDeformationGrid);
begin
  aHair.SetGrid(5, 5);
  aHair.ApplyDeformation(dtWaveH);
  aHair.DeformationSpeed.Value := PointF(1.5,1.6);
  aHair.Amplitude.Value := PointF(0.3,0.2);
  aHair.SetDeformationAmountOnRow(0, 0.4);
  aHair.SetDeformationAmountOnRow(1, 0.6);
  aHair.SetDeformationAmountOnRow(1, 0.8);

  aHair.SetTimeMultiplicatorOnRow(5, 1.5);
//aHair.ShowGrid:=true;
end;

procedure TLRBaseFace.SetWindSpeedOnHair(aHair: TDeformationGrid; aValue: single);
begin
  aHair.Amplitude.Value := PointF(0.3*aValue,0.2*aValue);
end;

constructor TLRBaseFace.Create(aTexture: PTexture);
begin
  inherited Create(aTexture, False);
  ApplySymmetryWhenFlip := True;
end;

procedure TLRBaseFace.ProcessMessage(UserValue: TUserMessageValue);
const _DELTA=0.03;
var v: single;
begin
  case UserValue of
    //Face moving
    0: begin
      v := random+1;
      MoveCenterTo(FOriginCenterCoor+PointF(random*Width*_DELTA-Width*_DELTA*0.5,
                                            random*Height*_DELTA-Height*_DELTA*0.5), v, idcSinusoid);
      PostMessage(0, v+1*random);
    end;

    // eye blink
    100: begin
      if EyeCanBlink then Frame := 2;
      PostMessage(101, 0.1);
    end;
    101: begin
      if EyeCanBlink then Frame := 1;
      PostMessage(100, 1+random+random*2);
    end;

    // eye move idle for portrait and LR4direction right-left view
    200: begin
      LeftEye.Polar.Angle.ChangeTo(0, 1, idcSinusoid);
      LeftEye.Polar.Distance.ChangeTo(FEyeMaxDistance, 1, idcSinusoid);
      RightEye.Polar.Angle.ChangeTo(0, 1, idcSinusoid);
      RightEye.Polar.Distance.ChangeTo(FEyeMaxDistance, 1, idcSinusoid);
      PostMessage(201, 3);
    end;
    201: begin
      LeftEye.Polar.Angle.ChangeTo(45, 2, idcSinusoid);
      RightEye.Polar.Angle.ChangeTo(45, 2, idcSinusoid);
      PostMessage(200, 4);
    end;

    // eye move idle for LR4direction front view
    210: begin
      v := random(360);
      LeftEye.Polar.Angle.ChangeTo(v, 2, idcSinusoid);
      RightEye.Polar.Angle.ChangeTo(v, 2, idcSinusoid);
      LeftEye.Polar.Distance.ChangeTo(FEyeMaxDistance, 3, idcSinusoid);
      RightEye.Polar.Distance.ChangeTo(FEyeMaxDistance, 3, idcSinusoid);
      PostMessage(211, 4+Random(4));
    end;
    211: begin
      LeftEye.Polar.Distance.ChangeTo(0, 3, idcSinusoid);
      RightEye.Polar.Distance.ChangeTo(0, 3, idcSinusoid);
      PostMessage(210, 4+Random(4));
    end;

    // lock hair swing
    300: begin
      v := random(50)*0.01+0.5;
      HairLock.Angle.ChangeTo(v*10, v, idcSinusoid);
      PostMessage(301, v);
    end;
    301: begin
      v := random(50)*0.01+0.5;
      HairLock.Angle.ChangeTo(-v*10, v, idcSinusoid);
      PostMessage(300, v);
    end;
  end;
end;

{ TLRFrontView }

procedure TLRFrontView.SetDeformationOnHood;
begin
  FHood.SetGrid(5, 5);
  FHood.ApplyDeformation(dtWaveH);
  FHood.Amplitude.Value := PointF(0.3, 0.2);
  FHood.DeformationSpeed.Value := PointF(5,5);
  FHood.SetDeformationAmountOnRow(0, 0.4);
  FHood.SetDeformationAmountOnRow(1, 0.4);
  FHood.SetDeformationAmountOnRow(2, 0.2);
  FHood.SetDeformationAmountOnRow(3, 0);
  FHood.SetDeformationAmountOnRow(4, 0.5);
  FHood.SetDeformationAmountOnRow(5, 1.0);
end;

constructor TLRFrontView.Create;
begin
  inherited Create(FScene);

  FDress := TLRDress.Create(texLRFrontViewDress);
  AddChild(FDress, 0);
  FDress.X.Value := -FDress.Width*0.5;
  FDress.BottomY := 0;
  FDress.Pivot := PointF(0.5, 1.0);

  FHood := CreateChildDeformationGrid(texLRFrontViewHood, 1);
  FHood.X.Value := -FHood.Width*0.55;
  FHood.BottomY := -FHood.Height*0.07;
  SetDeformationOnHood;

  Face := TLRFace.Create;
  FHood.AddChild(Face, 0);
  Face.CenterX := FHood.Width*0.52;
  Face.CenterY := FHood.Height*0.43;
  Face.OriginCenterCoor := Face.Center;

  RightArm := TSprite.Create(texLRFrontViewRightArm, False);
  FDress.AddChild(RightArm, 1);
  RightArm.SetCoordinate(FDress.Width*0.1, FDress.Height*0.25);
  RightArm.Pivot := PointF(0.2, 0.1);
  RightArm.ApplySymmetryWhenFlip := True;

  LeftArm := TSprite.Create(texLRFrontViewLeftArm, False);
  FDress.AddChild(LeftArm, 1);
  LeftArm.SetCoordinate(FDress.Width*0.5, FDress.Height*0.25);
  LeftArm.Pivot := PointF(0.8, 0.1);
  LeftArm.ApplySymmetryWhenFlip := True;

  RightLeg := CreateChildSprite(texLRFrontViewRightLeg, -1);
  RightLeg.SetCoordinate(-RightLeg.Width, -RightLeg.Height*0.25);

  LeftLeg := CreateChildSprite(texLRFrontViewLeftLeg, -1);
  LeftLeg.SetCoordinate(0, -LeftLeg.Height*0.25);

  FBasket := TSprite.Create(texLRFrontViewBasket, False);
  FDress.AddChild(FBasket, 0);
  FBasket.SetCoordinate(FDress.Width*0.25, FDress.Height*0.6);
  FBasket.ApplySymmetryWhenFlip := True;
end;

procedure TLRFrontView.SetFlipH(AValue: boolean);
begin
  FHood.FlipH := AValue;
  Face.SetFlipH(AValue);
  FDress.FlipH := AValue;
  RightArm.FlipH := AValue;
  LeftArm.FlipH := AValue;
  RightLeg.FlipH := AValue;
  LeftLeg.FlipH := AValue;
  FBasket.FlipH := AValue;
end;

procedure TLRFrontView.SetFlipV(AValue: boolean);
begin
  FHood.FlipV := AValue;
  Face.SetFlipV(AValue);
  FDress.FlipV := AValue;
  RightArm.FlipV := AValue;
  LeftArm.FlipV := AValue;
  RightLeg.FlipV := AValue;
  LeftLeg.FlipV := AValue;
  FBasket.FlipV := AValue;
end;

procedure TLRFrontView.HideBasket;
begin
  FBasket.Visible := False;
end;

procedure TLRFrontView.SetWindSpeed(AValue: single);
begin
  FDress.SetWindSpeed(AValue);
  FHood.Amplitude.Value := PointF(0.3*AValue, 0.2*AValue);
end;

procedure TLRFrontView.MoveArmsAsWinner;
begin
  RightArm.Angle.Value := 140;
  LeftArm.Angle.Value := -140;
end;

procedure TLRFrontView.MoveArmIdlePosition;
begin
  RightArm.Angle.Value := 0;
  LeftArm.Angle.Value := 0;
end;

procedure TLRFrontView.SetCoordinateByFeet(aCenterX, aY: single);
begin
  CenterX := aCenterX;
  Y.Value := aY - RightLeg.Height*0.75;
end;

{ TLRDress }

procedure TLRDress.SetDeformation;
const _cellCount = 3;
var i: integer;
begin
  SetGrid(_cellCount, _cellCount);
  ApplyDeformation(dtWaveH);
  Amplitude.Value := PointF(0.3, 0.2);
  DeformationSpeed.Value := PointF(5,5);
  for i:=0 to _cellCount do
    SetDeformationAmountOnRow(i, i*(1/_cellCount));
end;

constructor TLRDress.Create(aDressTexture: PTexture);
begin
  inherited Create(aDressTexture, False);
  SetDeformation;
  ApplySymmetryWhenFlip := True;
end;

procedure TLRDress.SetWindSpeed(AValue: single);
begin
  Amplitude.Value := PointF(AValue*0.3, 0.2);
end;

{ TLRFace }

procedure TLRFace.SetFaceType(AValue: TLRFaceType);
begin
  inherited SetFaceType(AValue);
  MouthSmile.Visible := AValue = lrfSmile;
  MouthOpen.Visible := AValue = lrfHappy;
  MouthNotHappy.Visible := AValue = lrfNotHappy;
end;

constructor TLRFace.Create;
begin
  inherited Create(texLRFace);

  // white background behind the face
  WhiteBG := CreateChildSprite(texLRFaceBGWhite, -2);
  WhiteBG.SetCenterCoordinate(Width*0.55, Height*0.5);

  // left eye
  LeftEye := CreateChildPolar(texLRFaceEye, -1);
  LeftEye.Polar.Center.Value := PointF(Width*0.30, Height*0.54);

  // right eye
  RightEye := CreateChildPolar(texLRFaceEye, -1);
  RightEye.Polar.Center.Value := PointF(Width*0.77, Height*0.50);

  FEyeMaxDistance := LeftEye.Width*0.30;

  // hair lock
  HairLock := CreateChildSprite(texLRFaceHairLock, -1);
  HairLock.SetCoordinate(Width*0.87, Height*0.6);
  HairLock.Pivot := PointF(0.5, 0);

  // hair
  Hair := CreateChildDeformationGrid(texLRFaceHair, 0);
  Hair.SetCenterCoordinate(Width*0.55, Height*0.40);
  SetDeformationOnHair(Hair);

  // mouth hurt
  MouthNotHappy := CreateChildSprite(texLRFaceMouthHurt, 0);
  MouthNotHappy.SetCenterCoordinate(Width*0.5, Height*0.90);

  // mouth open
  MouthOpen := CreateChildSprite(texLRFaceMouthOpen, 0);
  MouthOpen.SetCenterCoordinate(Width*0.55, Height*0.88);

  // mouth smile
  MouthSmile := CreateChildSprite(texLRFaceMouthSmile, 0);
  MouthSmile.SetCenterCoordinate(Width*0.55, Height*0.85);

  FaceType := lrfSmile;
  PostMessage(0);
  PostMessage(100);
  PostMessage(200);
  PostMessage(300);
end;

procedure TLRFace.SetFlipH(AValue: boolean);
begin
  FlipH := AValue;
  LeftEye.FlipH := AValue;
  RightEye.FlipH := AValue;
  Hair.FlipH := AValue;
  HairLock.FlipH := AValue;
  MouthNotHappy.FlipH := AValue;
  MouthOpen.FlipH := AValue;
  MouthSmile.FlipH := AValue;
  WhiteBG.FlipH := AValue;
end;

procedure TLRFace.SetFlipV(AValue: boolean);
begin
  FlipV := AValue;
  LeftEye.FlipV := AValue;
  RightEye.FlipV := AValue;
  Hair.FlipV := AValue;
  HairLock.FlipV := AValue;
  MouthNotHappy.FlipV := AValue;
  MouthOpen.FlipV := AValue;
  MouthSmile.FlipV := AValue;
  WhiteBG.FlipV := AValue;
end;

end.

