unit u_sprite_lrcommon;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls,
  OGLCScene, BGRABitmap, BGRABitmapTypes,
  u_common;

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
  function GetBodyRect: TRectF;

  function CheckCollisionWith(aX, aY: single): boolean; overload;
  function CheckCollisionWithLine(aPt1, aPt2: TPointF): boolean;
  function CheckCollisionWith(aRectF: TRectF): boolean; overload;
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
  FMessageReceiver: TObject;
  FMessageValueWhenFinish: TUserMessageValue;
  FDelay: single;
  FTimeMultiplicator: single;
protected
  procedure SetTimeMultiplicator(AValue: single); virtual;
public
  procedure Update(const aElapsedTime: single); override;
  procedure PostMessageToTargetObject(aTarget: TObject; aMessageValue: TUserMessageValue; aDelay: single);
  procedure CheckHorizontalMoveToX(aX: single; aMessageReceiver: TObject; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
  procedure CheckVerticalMoveToY(aY: single; aMessageReceiver: TObject; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
  procedure CheckMoveTo(aX, aY: single; aMessageReceiver: TObject; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
  property TimeMultiplicator: single read FTimeMultiplicator write SetTimeMultiplicator;
end;

{ TCharacterWithMark }

TCharacterWithMark = class(TWalkingCharacter)
private
  FExclamationMark, FQuestionMark: TSprite;
  FMarkOffset: TPointF;
public
  destructor Destroy; override;
  procedure ShowExclamationMark;
  procedure ShowQuestionMark;
  procedure HideMark;
  property MarkOffset: TPointF read FMarkOffset write FMarkOffset;
end;


{ TInfoPanel }

TInfoPanel = class(TUITextArea)
private
  FOldProcessSceneClick: TOGLCMouseEvent;
  FTargetScreen: TScreenTemplate;
  FMessageValueWhenFinish: TUserMessageValue;
  FDelay: Single;
  FPanelCanBeClosedByKey: boolean;
  FStepKeyCheck: integer;
  procedure PostMessageAndClosePanel;
  procedure ProcessSceneClick({%H-}Button: TMouseButton; {%H-}Shift: TShiftState; {%H-}aX, {%H-}aY: Integer);
  procedure Init(aBlinkCursorIsVisible: boolean);
  procedure CreateLabelAuthor(const aAuthor: string; aTexturedFont: TTexturedFont);
public
  procedure Update(const aElapsedTime: single); override;
  constructor Create(const aAuthor, aText: string; aTexturedFont: TTexturedFont;
             aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0;
             aLayerIndex: integer=LAYER_DIALOG);
  constructor Create(const aAuthor, aText: string; aTexturedFont: TTexturedFont; aLifeTime: single=4.0;
                     aLayerIndex: integer=LAYER_DIALOG);
end;


{ TCharacterWithDialogPanel }

TCharacterWithDialogPanel = class(TCharacterWithMark)
private
  FDialogAuthorName: string;
  FDialogTextColor: TBGRAPixel;
  FPanel: TInfoPanel; //TUITextArea;
  procedure PlacePanelOnView(aCameraInUse: TOGLCCamera);
public
  // the dialog is shifted according to aCameraInUse.LookAt
  procedure ShowDialog(const aText: string; aTexturedFont: TTexturedFont;
             aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0;
             aCameraInUse: TOGLCCamera=NIL);
  procedure ShowDialog(const aText: string; aTexturedFont: TTexturedFont; aLifeTime: single=4.0; aCameraInUse: TOGLCCamera=NIL);
  property DialogTextColor: TBGRAPixel read FDialogTextColor write FDialogTextColor;
  property DialogAuthorName: string read FDialogAuthorName write FDialogAuthorName;

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
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  procedure SetFaceType(AValue: TLRFaceType); override;
  constructor Create;
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
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  Face: TLRFace;
  RightArm, LeftArm, RightLeg, LeftLeg: TSprite;
  constructor Create;
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
uses u_app, u_utils, Math;

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

procedure TInfoPanel.PostMessageAndClosePanel;
begin
  if FScene.Mouse.OnClickOnScene = @ProcessSceneClick then
    FScene.Mouse.OnClickOnScene := FOldProcessSceneClick;

  FTargetScreen.PostMessage(FMessageValueWhenFinish, FDelay);
  Kill;
end;

procedure TInfoPanel.ProcessSceneClick(Button: TMouseButton; Shift: TShiftState; aX, aY: Integer);
begin
  PostMessageAndClosePanel;
end;

procedure TInfoPanel.Init(aBlinkCursorIsVisible: boolean);
var h: integer;
begin
  MouseInteractionEnabled := False;
  ChildClippingEnabled := False;
  Text.Align := taCenterCenter;
  //Text.Tint.Value := FDialogTextColor;
  if aBlinkCursorIsVisible then h := texGameDialogDownArrow^.FrameHeight
    else h := 0;

  BodyShape.ResizeCurrentShape(Text.DrawingSize.cx+PPIScale(10)*2, Text.DrawingSize.cy+PPIScale(10*2)+h, True);
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
  o.Tint.Value := BGRAWhite;
end;

procedure TInfoPanel.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  // check if user press an action key
  if FPanelCanBeClosedByKey then begin
    case FStepKeyCheck of
      0: begin // wait user release the two action keys
        if Input.Action1Pressed or Input.Action2Pressed then exit;
        FStepKeyCheck := 1;
      end;
      1: begin // wait user press at least one action key
        if Input.Action1Pressed or Input.Action2Pressed then FStepKeyCheck := 2;
      end;
      2: begin // wait user release the two action keys
        if Input.Action1Pressed or Input.Action2Pressed then exit;
        PostMessageAndClosePanel;
        FPanelCanBeClosedByKey := False;
      end;
    end;
  end;
end;

constructor TInfoPanel.Create(const aAuthor, aText: string; aTexturedFont: TTexturedFont; aTargetScreen: TScreenTemplate;
  aMessageValueWhenFinish: TUserMessageValue; aDelay: single; aLayerIndex: integer);
var o: TSprite;
    w: integer;
begin
  inherited Create(FScene);
  VScrollBarMode := sbmNeverShow;
  HScrollBarMode := sbmNeverShow;
  FScene.Add(Self, aLayerIndex);
  if Length(aText) >= 200 then w := Round(FScene.Width*0.5)
  else if Length(aText) >= 100 then w := Round(FScene.Width*0.4)
  else w := Round(FScene.Width*0.3);
  BodyShape.SetShapeRoundRect(w, 50, PPIScale(8), PPIScale(8), PPIScale(3));
  Text.TexturedFont := aTexturedFont;
  Text.Caption := aText;
  Init(True);

  o := TSprite.Create(texGameDialogDownArrow, False);
  AddChild(o, 0);
  o.Blink(-1, 0.4, 0.4);
  o.RightX := Width - o.Width*0.5;
  o.BottomY := Height - o.Height*0.5;

  //Author label
  CreateLabelAuthor(aAuthor, aTexturedFont);

  FOldProcessSceneClick := FScene.Mouse.OnClickOnScene;
  FScene.Mouse.OnClickOnScene := @ProcessSceneClick;

  FPanelCanBeClosedByKey := True;
  FStepKeyCheck := 0;

  FTargetScreen := aTargetScreen;
  FMessageValueWhenFinish := aMessageValueWhenFinish;
  FDelay := aDelay;
end;

constructor TInfoPanel.Create(const aAuthor, aText: string; aTexturedFont: TTexturedFont; aLifeTime: single;
  aLayerIndex: integer);
begin
  Inherited Create(FScene);
  FScene.Add(Self, aLayerIndex);
  BodyShape.SetShapeRoundRect(Round(FScene.Width*0.3), 50, PPIScale(8), PPIScale(8), PPIScale(3));
  Text.TexturedFont := aTexturedFont;
  Text.Align := taCenterCenter;
  Text.Caption := aText;
  Init(False);

  CreateLabelAuthor(aAuthor, aTexturedFont);

  KillDefered(aLifeTime);
  FPanelCanBeClosedByKey := False;
end;

{ TCharacterWithDialogPanel }

procedure TCharacterWithDialogPanel.PlacePanelOnView(aCameraInUse: TOGLCCamera);
var p: TPointF;
    w, h: single;
    rView, rPanel: TRectF;
begin
  rView := GetViewRect(aCameraInUse);

  w := FPanel.Width;
  h := FPanel. Height;
  p := PointF(X.Value-w*0.5, GetYTop - h - PPIScale(20));

  p.x := EnsureRange(p.x, rView.Left, rView.Right-w);
  p.y := EnsureRange(p.y, rView.Top, rView.Bottom-h);

  // message panel overlapps the character body ?
  rPanel := RectF(p.x, p.y, p.x+w, p.y+h);
  if FScene.Collision.RectFRectF(GetBodyRect, rPanel) then begin
    // the panel overlapps the character -> we shift it to the left or to the right
    if p.x > rView.Left+rView.Width*0.5 then p.x := GetBodyRect.Left-w
      else p.x := GetBodyRect.Right;
  end;
  //FPanel.SetCoordinate(p);
  FPanel.SetCoordinate(Trunc(p.x), Trunc(p.y)); // truncate to avoid artifact on characters
end;

procedure TCharacterWithDialogPanel.ShowDialog(const aText: string; aTexturedFont: TTexturedFont;
  aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single;
  aCameraInUse: TOGLCCamera);
begin
  //if FPanel <> NIL then FPanel.Kill;
  FPanel := TInfoPanel.Create(FDialogAuthorName, aText, aTexturedFont,
                              aTargetScreen, aMessageValueWhenFinish, aDelay);
  PlacePanelOnView(aCameraInUse);
end;

procedure TCharacterWithDialogPanel.ShowDialog(const aText: string;
  aTexturedFont: TTexturedFont; aLifeTime: single; aCameraInUse: TOGLCCamera);
begin
  if FPanel <> NIL then FPanel.Kill;
  FPanel := TInfoPanel.Create(FDialogAuthorName, aText, aTexturedFont, aLifeTime);
  PlacePanelOnView(aCameraInUse);
end;

{ TCharacterWithMark }

destructor TCharacterWithMark.Destroy;
begin
  HideMark;
  inherited Destroy;
end;

procedure TCharacterWithMark.ShowExclamationMark;
begin
  HideMark;

  FExclamationMark := TSprite.Create(texExclamationMark, False);
  //FScene.Add(FExclamationMark, LAYER_DIALOG);
  //FExclamationMark.BindToSprite(Self, -FExclamationMark.Width*0.5, DeltaYToTop);
  AddChild(FExclamationMark, 100);
  FExclamationMark.X.Value := Trunc(-FExclamationMark.Width*0.5 + FMarkOffset.x);
  FExclamationMark.Y.Value := Trunc(-DeltaYToTop - FExclamationMark.Height + FMarkOffset.y);
end;

procedure TCharacterWithMark.ShowQuestionMark;
begin
  HideMark;

  FQuestionMark := TSprite.Create(texQuestionMark, False);
  //FScene.Add(FQuestionMark, LAYER_DIALOG);
  //FQuestionMark.BindToSprite(Self, -FQuestionMark.Width*0.5, DeltaYToTop);
  AddChild(FQuestionMark, 100);
  FQuestionMark.X.Value := -FQuestionMark.Width*0.5 + FMarkOffset.x;
  FQuestionMark.Y.Value := -DeltaYToTop - FQuestionMark.Height + FMarkOffset.y;
end;

procedure TCharacterWithMark.HideMark;
begin
  if FExclamationMark <> NIL then FExclamationMark.Kill;
  if FQuestionMark <> NIL then FQuestionMark.Kill;
  FQuestionMark := NIL;
  FExclamationMark := NIL;
end;

{ TWalkingCharacter }

procedure TWalkingCharacter.PostMessageToTargetObject(aTarget: TObject;
  aMessageValue: TUserMessageValue; aDelay: single);
begin
  if aTarget is TScreenTemplate then
    TScreenTemplate(aTarget).PostMessage(aMessageValue, aDelay)
  else TSimpleSurfaceWithEffect(aTarget).PostMessage(aMessageValue, aDelay);
end;

procedure TWalkingCharacter.SetTimeMultiplicator(AValue: single);
begin
  FTimeMultiplicator := AValue;
end;

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
  if (FMovingDirection <> mdNone) and (Speed.X.Value = 0) and (Speed.Y.Value = 0) then begin
    FMovingDirection := mdNone;
    PostMessageToTargetObject(FMessageReceiver, FMessageValueWhenFinish, FDelay);
  end;
end;

procedure TWalkingCharacter.CheckHorizontalMoveToX(aX: single; aMessageReceiver: TObject;
  aMessageValueWhenFinish: TUserMessageValue; aDelay: single);
begin
  if X.Value = aX then begin
    FMovingDirection := mdNone;
    PostMessageToTargetObject(aMessageReceiver, aMessageValueWhenFinish, aDelay);
    Speed.X.Value := 0;
    exit;
  end;
  if X.Value > aX then FMovingDirection := mdLeft
    else FMovingDirection := mdRight;

  FTargetPoint.x := aX;
  FMessageReceiver := aMessageReceiver;
  FMessageValueWhenFinish := aMessageValueWhenFinish;
  FDelay := aDelay;
end;

procedure TWalkingCharacter.CheckVerticalMoveToY(aY: single; aMessageReceiver: TObject;
  aMessageValueWhenFinish: TUserMessageValue; aDelay: single);
begin
  aY := aY - FDeltaYToBottom;
  if Y.Value = aY then begin
    FMovingDirection := mdNone;
    PostMessageToTargetObject(aMessageReceiver, aMessageValueWhenFinish, aDelay);
    Speed.Y.Value := 0;
    exit;
  end;
  if Y.Value > aY then FMovingDirection := mdUp
    else FMovingDirection := mdDown;

  FTargetPoint.y := aY;
  FMessageReceiver := aMessageReceiver;
  FMessageValueWhenFinish := aMessageValueWhenFinish;
  FDelay := aDelay;
end;

procedure TWalkingCharacter.CheckMoveTo(aX, aY: single; aMessageReceiver: TObject;
  aMessageValueWhenFinish: TUserMessageValue; aDelay: single);
begin
  if (X.Value = aX) and (Y.Value = aY) then begin
    FMovingDirection := mdNone;
    PostMessageToTargetObject(aMessageReceiver, aMessageValueWhenFinish, aDelay);
    Speed.Value := PointF(0, 0);
    exit;
  end;
  if X.Value = aX then begin
    CheckVerticalMoveToY(aY, aMessageReceiver, aMessageValueWhenFinish, aDelay);
    exit;
  end;
  if Y.Value = aY then begin
    CheckHorizontalMoveToX(aX, aMessageReceiver, aMessageValueWhenFinish, aDelay);
    exit;
  end;

  if X.Value > aX then
    if Y.Value > aY then FMovingDirection := mdLeftUp else FMovingDirection := mdLeftDown;

  if X.Value < aX then
    if Y.Value > aY then FMovingDirection := mdRightUp else FMovingDirection := mdRightDown;

  FTargetPoint := PointF(aX, aY);
  FMessageReceiver := aMessageReceiver;
  FMessageValueWhenFinish := aMessageValueWhenFinish;
  FDelay := aDelay;
end;

{ TBaseComplexContainer }

function TBaseComplexContainer.GetBodyRect: TRectF;
begin
  Result.Left := X.Value - FBodyWidth*0.5;
  Result.Top := GetYTop;
  Result.Right := Result.Left + FBodyWidth;
  Result.Bottom := GetYBottom;
end;

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

function TBaseComplexContainer.CheckCollisionWith(aX, aY: single): boolean;
var r: TRectF;
begin
  r.Left := X.Value - BodyWidth * 0.5;
  r.Top := GetYTop;
  r.Width := BodyWidth;
  r.Height := BodyHeight;
  Result := FScene.Collision.PointRectF(PointF(aX,aY), r);
end;

function TBaseComplexContainer.CheckCollisionWithLine(aPt1, aPt2: TPointF): boolean;
var r: TRectF;
begin
  r.Left := X.Value - BodyWidth * 0.5;
  r.Top := GetYTop;
  r.Width := BodyWidth;
  r.Height := BodyHeight;
  Result := FScene.Collision.LineRectF(aPt1, aPt2, r);
end;

function TBaseComplexContainer.CheckCollisionWith(aRectF: TRectF): boolean;
var xx, yy, w, h: single;
begin
  w := BodyWidth;
  h := BodyHeight;
  xx := X.Value - w*0.5;
  yy := GetYTop;
  Result := FScene.Collision.RectFRectF(aRectF, RectF(xx, yy, xx+w, yy+h));
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
  inherited SetFlipH(AValue);
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
  inherited SetFlipV(AValue);
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
  Frame := 1;

  // white background behind the face
  WhiteBG := CreateChildSprite(texLRFaceBGWhite, -2);
  WhiteBG.SetCenterCoordinate(Width*0.55, Height*0.5);

  // left eye
  LeftEye := CreateChildPolar(texLRFaceEye, -1);
  LeftEye.Polar.Center.Value := PointF(Width*0.30, Height*0.54);
  LeftEye.Update(0.1);

  // right eye
  RightEye := CreateChildPolar(texLRFaceEye, -1);
  RightEye.Polar.Center.Value := PointF(Width*0.77, Height*0.50);
  RightEye.Update(0.1);

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
  inherited SetFlipH(AValue);
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
  inherited SetFlipV(AValue);
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

