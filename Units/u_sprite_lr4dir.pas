unit u_sprite_lr4dir;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes,
  u_sprite_lrcommon;

type

{ TLRFrontViewFace }

TLRFrontViewFace = class(TLRBaseFace)
private
  Hair: TDeformationGrid;
  MouthNotHappy, MouthOpen, MouthSmile, MouthWorry,
  WhiteBG: TSprite;
public
  procedure SetFaceType(AValue: TLRFaceType); override;
  constructor Create;
  procedure SetFlipH(AValue: boolean);
  procedure SetFlipV(AValue: boolean);
  procedure SetWindSpeed(AValue: single);
end;


TLRFrontView = class(TWalkingCharacter) //(TBaseComplexContainer)
private type TLRFrontViewState = (fvsIdle, fvsWalking,
                                  fvsStartAnimWinner, fvsEndAnimWinner);
private
  FDress: TLRDress;
  FHood, FLeftCloak: TDeformationGrid;
  FLeftArm, FRightArm, FLeftLeg, FRightLeg: TSprite;
  FLeftShoe, FRightShoe: TSpriteWithElasticCorner;
  FState: TLRFrontViewState;
  FYLegIdlePosition, FTimeMultiplicator: single;
  FWinJumpCount: integer;
  procedure SetDeformationOnHood;
  procedure SetDeformationOnLeftCloak;
  procedure SetState(AValue: TLRFrontViewState);
public
  Face: TLRFrontViewFace;
  constructor Create;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure SetFlipH(AValue: boolean);
  procedure SetFlipV(AValue: boolean);
  procedure SetWindSpeed(AValue: single);
  procedure SetIdlePosition(aImmediat: boolean);
  property State: TLRFrontViewState read FState write SetState;
  property TimeMultiplicator: single read FTimeMultiplicator write FTimeMultiplicator;
end;


{ TLRRightViewFace }

TLRRightViewFace = class(TLRBaseFace)
private
  Hair: TDeformationGrid;
  {MouthNotHappy, MouthOpen,}
  MouthSmile, MouthWorry, MouthNotHappy, RightEar, WhiteBG: TSprite;
public
  constructor Create;
  procedure SetFaceType(AValue: TLRFaceType); override;
  procedure SetFlipH(AValue: boolean);
  procedure SetFlipV(AValue: boolean);
  procedure SetWindSpeed(AValue: single);
end;

TCallbackDoOnJumpMove = procedure(aDuration: single; aJumpStep: integer) of object;
TCallbackPickUpSomethingWhenBendDown = procedure(aPickUpToTheRight: boolean) of object;

TLRRightView = class(TWalkingCharacter) //(TBaseComplexContainer)
private type TLRRightViewState = (rvsIdle, rvsWalking, rvsJumping, rvsBendDown, rvsBendUp);
private
  FCallbackDoOnJumpMove: TCallbackDoOnJumpMove;
  FCallbackPickUpSomethingWhenBendDown: TCallbackPickUpSomethingWhenBendDown;
  FDress: TLRDress;
  FHood, FLeftCloak: TDeformationGrid;
  FLeftArm, FRightArm, FLeftLeg, FRightLeg: TSprite;
  FState: TLRRightViewState;
  FTimeMultiplicator: single;
  FIsJumping: boolean;
  FYDressOriginPosition: TPointF;
  function GetIsOrientedToRight: boolean;
  procedure SetDeformationOnHood;
  procedure SetDeformationOnLeftCloak;
  procedure SetState(AValue: TLRRightViewState);
public
  Face: TLRRightViewFace;
  constructor Create;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure SetFlipH(AValue: boolean);
  procedure SetFlipV(AValue: boolean);
  procedure SetWindSpeed(AValue: single);
  procedure SetIdlePosition(aImmediat: boolean);
  property State: TLRRightViewState read FState write SetState;
  property TimeMultiplicator: single read FTimeMultiplicator write FTimeMultiplicator;
  property CallbackDoOnJumpMove: TCallbackDoOnJumpMove read FCallbackDoOnJumpMove write FCallbackDoOnJumpMove;
  property IsOrientedToRight: boolean read GetIsOrientedToRight;
  property IsJumping: boolean read FIsJumping;
  property CallbackPickUpSomethingWhenBendDown: TCallbackPickUpSomethingWhenBendDown read FCallbackPickUpSomethingWhenBendDown write FCallbackPickUpSomethingWhenBendDown;
end;


//

TCallBackLadderMove = procedure(aMoveDelta, aMoveDuration: single) of object;
{ TLRBackView }

TLRBackView = class(TWalkingCharacter) //(TBaseComplexContainer)
private type TLRBackViewState = (bvsIdle, bvsWalking,
                                 bvsIdleOnLadder, bvsLadderUp, bvsLadderDown);
private
  FCallbackDoOnLadderMove: TCallBackLadderMove;
  FDress: TLRDress;
  FHood: TDeformationGrid;
  FLeftArm, FRightArm, FLeftLeg, FRightLeg, FLeftShoe, FRightShoe: TSprite;
  FState: TLRBackViewState;
  FTimeMultiplicator: single;
  FYLegOriginPosition, FYShoeOriginPosition: single;
  FLeftArmOriginPosition, FRightArmOriginPosition : TPointF;
  FLeftArmLadderUpPosition, FLeftArmLadderDownPosition,
  FRightArmLadderUpPosition, FRightArmLadderDownPosition: TPointF;
  FYDeltaMoveOnLadder: single;
  FOnLadderStepAnim: integer;
  FCanMoveOnLadder: boolean;
  procedure SetDeformationOnHood;
  procedure SetState(AValue: TLRBackViewState);
public
  constructor Create;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure SetFlipH(AValue: boolean);
  procedure SetFlipV(AValue: boolean);
  procedure SetWindSpeed(AValue: single);
  procedure SetIdlePosition(aImmediat: boolean);
  property State: TLRBackViewState read FState write SetState;
  property TimeMultiplicator: single read FTimeMultiplicator write FTimeMultiplicator;
  property CallbackDoOnLadderMove: TCallBackLadderMove read FCallbackDoOnLadderMove write FCallbackDoOnLadderMove;
  property CanMoveOnLadder: boolean read FCanMoveOnLadder;
  end;


TLR4State = (lr4sUndefined=0,
             lr4sRightIdle, lr4sRightWalking,
             lr4sLeftIdle, lr4sLeftWalking,
             lr4sUpIdle, lr4sUpWalking,
             lr4sDownIdle, lr4sDownWalking,
             lr4sOnLadderIdle, lr4sOnLadderUp, lr4sOnLadderDown,
             lr4sJumping,  // only in right/left view
             lr4sBendDown, lr4sBendUp, // only in right/left view
             lr4sStartAnimWinner, lr4sEndAnimWinner,
             lr4sLoser);


const COEFF_SPEED_WALKING = 0.1; // used as pixel/sec = FScene.Width*COEFF_SPEED_WALKING
      BASE_TIME_MOVE = 0.4;
      BASE_TIME_BEND = 1.0;
  type
{ TLR4Direction }

TLR4Direction = class(TCharacterWithDialogPanel)
private
  FCallbackPickUpSomethingWhenBendDown: TCallbackPickUpSomethingWhenBendDown;
  FState: TLR4State;
  FLRFront: TLRFrontView;
  FLRRight: TLRRightView;
  FLRBack: TLRBackView;
  FTimeMultiplicator: single;
  FJumpToTheRight, FBendDownToTheRight: boolean;
  procedure SetCallbackPickUpSomethingWhenBendDown(AValue: TCallbackPickUpSomethingWhenBendDown);
  procedure SetState(AValue: TLR4State);
  procedure SetTimeMultiplicator(AValue: single);
  procedure ProcessCallbackDoOnLadderMove(aMoveDelta, aMoveDuration: single);
  procedure ProcessCallbackDoOnJumpMove(aMoveDuration: single; aJumpStep: integer);
public
  constructor Create;
  procedure SetIdlePosition;
public // utils to control character during cinematics
  procedure SetWindSpeed(AValue: single);
  procedure SetFaceType(AValue: TLRFaceType);
  procedure IdleLeft;
  procedure IdleRight;
  procedure IdleUp;
  procedure IdleDown;
  procedure WalkHorizontallyTo(aX: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
  // aY is relative to the feets of LR
  procedure WalkVerticallyTo(aY: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single=0);
public
  property State: TLR4State read FState write SetState;
  property TimeMultiplicator: single read FTimeMultiplicator write SetTimeMultiplicator;
  property CallbackPickUpSomethingWhenBendDown: TCallbackPickUpSomethingWhenBendDown read FCallbackPickUpSomethingWhenBendDown write SetCallbackPickUpSomethingWhenBendDown;
end;



procedure LoadLR4DirTextures(aAtlas: TOGLCTextureAtlas);

implementation

uses u_app, u_common;


var
// textures common for front and right view
  texLRFaceBGWhite,
  texLREye,
  texLRHairLock,
  texLRFaceMouthWorry: PTexture;
// textures for face front view
  texLRfFace,
  texLRfFaceHair,
  texLRfFaceMouthHurt,
  texLRfFaceMouthOpen,
  texLRfFaceMouthSmile: PTexture;
// textures for face right view
  texLRrFace,
  texLRrFaceHair,
  texLRrEar,
  texLRrFaceMouthSmile,
  texLRrFaceMouthNotHappy: PTexture;
// textures for body front view
  texLRfHood, texLRfLeftCloak, texLRfDress, texLRfLeftArm, texLRfRightArm,
  texLRfLeftLeg, texLRfRightLeg, texLRfLeftShoe, texLRfRightShoe: PTexture;
// textures for body right view
  texLRrHood, texLRrLeftCloak, texLRrDress, texLRrLeftArm, texLRrRightArm, texLRrLeg: PTexture;
// textures for body back view
  texLRbHood, texLRbDress, texLRbLeftArm, texLRbRightArm, texLRbLeg, texLRbShoe: PTexture;


procedure LoadLR4DirTextures(aAtlas: TOGLCTextureAtlas);
var path: string;
begin
  // character marks
  LoadCharacterMarkTextures(aAtlas);
  // common face
  path := SpriteLR4DirFolder;
  texLRFaceBGWhite := aAtlas.AddFromSVG(path+'FaceWhiteBG.svg', ScaleW(45), -1);
  texLREye := aAtlas.AddFromSVG(path+'Eye.svg', ScaleW(11), -1);
  texLRHairLock := aAtlas.AddFromSVG(path+'HairLock.svg', ScaleW(7), -1);
  texLRFaceMouthWorry := aAtlas.AddFromSVG(path+'MouthWorry.svg', ScaleW(22), -1);
  // face front view
  path := SpriteLR4DirFrontFolder;
  texLRfFace := aAtlas.AddMultiFrameImageFromSVG([path+'fFaceEyeOpen.svg',
                                                  path+'fFaceEyeClose.svg',
                                                  path+'fFaceBroken.svg'], ScaleW(57), -1, 1, 3, 1);
  texLRfFaceHair := aAtlas.AddFromSVG(path+'fHair.svg', ScaleW(58), -1);
  texLRfFaceMouthHurt := aAtlas.AddFromSVG(path+'fMouthNotHappy.svg', ScaleW(26), -1);
  texLRfFaceMouthOpen := aAtlas.AddFromSVG(path+'fMouthHappy.svg', ScaleW(27), -1);
  texLRfFaceMouthSmile := aAtlas.AddFromSVG(path+'fMouthSmile.svg', ScaleW(33), -1);
  // face right view
  path := SpriteLR4DirRightFolder;
  texLRrFace := aAtlas.AddMultiFrameImageFromSVG([path+'rFaceEyeOpen.svg',
                                                  path+'rFaceEyeClose.svg'], ScaleW(52), -1, 1, 3, 1);
  texLRrFaceHair := aAtlas.AddFromSVG(path+'rHair.svg', ScaleW(57), -1);
  texLRrEar := aAtlas.AddFromSVG(path+'rEar.svg', -1, ScaleH(8));
  texLRrFaceMouthSmile := aAtlas.AddFromSVG(path+'rMouthSmile.svg', ScaleW(29), -1);
  texLRrFaceMouthNotHappy := aAtlas.AddFromSVG(path+'rMouthNotHappy.svg', ScaleW(21), -1);
  // body front view
  path := SpriteLR4DirFrontFolder;
  texLRfHood := aAtlas.AddFromSVG(path+'fHood.svg', ScaleW(84), -1);
  texLRfLeftCloak := aAtlas.AddFromSVG(path+'fLeftCloak.svg', ScaleW(37), -1);
  texLRfDress := aAtlas.AddFromSVG(path+'fDress.svg', ScaleW(63), -1);
  texLRfLeftArm := aAtlas.AddFromSVG(path+'fLeftArm.svg', ScaleW(23), -1);
  texLRfRightArm := aAtlas.AddFromSVG(path+'fRightArm.svg', ScaleW(23), -1);
  texLRfLeftLeg := aAtlas.AddFromSVG(path+'fLeftLeg.svg', -1, ScaleH(18));
  texLRfRightLeg := aAtlas.AddFromSVG(path+'fRightLeg.svg', -1, ScaleH(18));
  texLRfLeftShoe := aAtlas.AddFromSVG(path+'fLeftShoe.svg', ScaleW(17), -1);
  texLRfRightShoe := aAtlas.AddFromSVG(path+'fRightShoe.svg', ScaleW(17), -1);
  // textures for body right view
  path := SpriteLR4DirRightFolder;
  texLRrHood := aAtlas.AddFromSVG(path+'rHood.svg', -1, ScaleH(142));
  texLRrLeftCloak := aAtlas.AddFromSVG(path+'rLeftCloak.svg', ScaleW(47), -1);
  texLRrDress := aAtlas.AddFromSVG(path+'rDress.svg', ScaleW(48), -1);
  texLRrLeftArm := aAtlas.AddFromSVG(path+'rLeftArm.svg', ScaleW(32), -1);
  texLRrRightArm := aAtlas.AddFromSVG(path+'rRightArm.svg', ScaleW(28), -1);
  texLRrLeg := aAtlas.AddFromSVG(path+'rLeg.svg', -1, ScaleH(26));
  // textures for body back view
  path := SpriteLR4DirBackFolder;
  texLRbHood := aAtlas.AddFromSVG(path+'bHood.svg', -1, ScaleH(143));
  texLRbDress := aAtlas.AddFromSVG(path+'bDress.svg', ScaleW(63), -1);
  texLRbLeftArm := aAtlas.AddFromSVG(path+'bLeftArm.svg', ScaleW(30), -1);
  texLRbRightArm := aAtlas.AddFromSVG(path+'bRightArm.svg', ScaleW(28), -1);
  texLRbLeg := aAtlas.AddFromSVG(path+'bLeg.svg', -1, ScaleH(17));
  texLRbShoe := aAtlas.AddFromSVG(path+'bShoe.svg', ScaleW(13), -1);
end;

{ TLR4Direction }

procedure TLR4Direction.SetState(AValue: TLR4State);
var flag: boolean;
begin
  if FState = AValue then Exit;
  if FLRRight.IsJumping then exit;

  if (AValue in [lr4sOnLadderUp, lr4sOnLadderDown]) and not FLRBack.CanMoveOnLadder then exit;

  if AValue in [lr4sJumping, lr4sBendDown, lr4sBendUp] then begin
    // no jump or bend down/up if not on side view
    if not (FState in [lr4sLeftIdle, lr4sLeftWalking, lr4sRightIdle, lr4sRightWalking, lr4sBendDown]) then exit;
    FJumpToTheRight := FState in [lr4sRightIdle, lr4sRightWalking];
    FBendDownToTheRight := FJumpToTheRight;
  end;

  FState := AValue;

  FLRFront.Visible := FState in [lr4sDownIdle, lr4sDownWalking, lr4sStartAnimWinner, lr4sEndAnimWinner];
  FLRFront.Freeze := not FLRFront.Visible;


  flag := FState in [lr4sLeftIdle, lr4sLeftWalking];
  if AValue = lr4sJumping then flag := not FJumpToTheRight
  else
  if AValue in [lr4sBendDown, lr4sBendUp] then flag := not FBendDownToTheRight;

  FLRRight.Visible := flag or (FState in [lr4sRightIdle, lr4sRightWalking, lr4sJumping, lr4sBendDown, lr4sBendUp]);
  if FLRRight.Visible then FLRRight.SetFlipH(flag);
  FLRRight.Freeze := not FLRRight.Visible;

  FLRBack.Visible := (FState in [lr4sUpIdle, lr4sUpWalking, lr4sOnLadderUp, lr4sOnLadderDown, lr4sOnLadderIdle]);
  FLRBack.Freeze := not FLRBack.Visible;

if not FLRFront.Visible and not FLRRight.Visible and not FLRBack.Visible
then raise exception.create('nothing to see!');

  if FLRFront.Visible then begin
    DeltaYToTop := FLRFront.DeltaYToTop;
    DeltaYToBottom := FLRFront.DeltaYToBottom;
    BodyWidth := FLRFront.BodyWidth;
    BodyHeight := FLRFront.BodyHeight;
  end else
  if FLRRight.Visible then begin
    DeltaYToTop := FLRRight.DeltaYToTop;
    DeltaYToBottom := FLRRight.DeltaYToBottom;
    BodyWidth := FLRRight.BodyWidth;
    BodyHeight := FLRRight.BodyHeight;
  end else begin
    DeltaYToTop := FLRBack.DeltaYToTop;
    DeltaYToBottom := FLRBack.DeltaYToBottom;
    BodyWidth := FLRBack.BodyWidth;
    BodyHeight := FLRBack.BodyHeight;
  end;

  case FState of
    lr4sRightIdle, lr4sLeftIdle: begin
      Speed.Value := PointF(0, 0);
      FLRRight.State := rvsIdle;
    end;
    lr4sDownIdle: begin
      Speed.Value := PointF(0, 0);
      FLRFront.State := fvsIdle;
    end;
    lr4sUpIdle: begin
      Speed.Value := PointF(0, 0);
      FLRBack.State := bvsIdle;
    end;
    lr4sOnLadderIdle: begin
      Speed.Value := PointF(0, 0);
      FLRBack.State := bvsIdleOnLadder;
    end;
    lr4sRightWalking: begin
      FLRRight.State := rvsWalking;
      if Speed.X.Value < 0 then Speed.X.Value := FScene.Width*COEFF_SPEED_WALKING
        else Speed.X.ChangeTo(FScene.Width*COEFF_SPEED_WALKING*(1-FTimeMultiplicator), 0.2, idcSinusoid);
      Speed.Y.Value := 0;
    end;
    lr4sLeftWalking: begin
      FLRRight.State := rvsWalking;
      if Speed.X.Value > 0 then Speed.X.Value := -FScene.Width*COEFF_SPEED_WALKING
        else Speed.X.ChangeTo(-FScene.Width*COEFF_SPEED_WALKING*(1-FTimeMultiplicator), 0.2, idcSinusoid);
      Speed.Y.Value := 0;
    end;
    lr4sUpWalking: begin
      FLRBack.State := bvsWalking;
      if Speed.Y.Value > 0 then Speed.Y.Value := -FScene.Width*COEFF_SPEED_WALKING
        else Speed.Y.ChangeTo(-FScene.Width*COEFF_SPEED_WALKING*(1-FTimeMultiplicator), 0.2, idcSinusoid);
      Speed.X.Value := 0;
    end;
    lr4sDownWalking: begin
      FLRFront.State := fvsWalking;
      if Speed.Y.Value < 0 then Speed.Y.Value := FScene.Width*COEFF_SPEED_WALKING
        else Speed.Y.ChangeTo(FScene.Width*COEFF_SPEED_WALKING*(1-FTimeMultiplicator), 0.2, idcSinusoid);
      Speed.X.Value := 0;
    end;
    lr4sOnLadderUp: begin
      FLRBack.State := bvsLadderUp;
      Speed.Value := PointF(0,0);
    end;
    lr4sOnLadderDown: begin
      FLRBack.State := bvsLadderDown;
      Speed.Value := PointF(0,0);
    end;
    lr4sJumping: begin
      FLRRight.State := rvsJumping;
      Speed.Value := PointF(0,0);
    end;
    lr4sBendDown: begin
      FLRRight.State := rvsBendDown;
      Speed.Value := PointF(0,0);
    end;
    lr4sBendUp: begin
      FLRRight.State := rvsBendUp;
      Speed.Value := PointF(0,0);
    end;
    lr4sStartAnimWinner: begin
      FLRFront.State := fvsStartAnimWinner;
    end;
  end;//case
end;

procedure TLR4Direction.SetCallbackPickUpSomethingWhenBendDown(AValue: TCallbackPickUpSomethingWhenBendDown);
begin
  FCallbackPickUpSomethingWhenBendDown := AValue;
  FLRRight.CallbackPickUpSomethingWhenBendDown := AValue;
end;

procedure TLR4Direction.SetTimeMultiplicator(AValue: single);
begin
  if FTimeMultiplicator = AValue then Exit;
  FTimeMultiplicator := AValue;
  FLRFront.TimeMultiplicator := FTimeMultiplicator;
  FLRRight.TimeMultiplicator := FTimeMultiplicator;
  FLRBack.TimeMultiplicator := FTimeMultiplicator;
end;

procedure TLR4Direction.ProcessCallbackDoOnLadderMove(aMoveDelta, aMoveDuration: single);
begin
  case FState of
    lr4sOnLadderUp: begin
      MoveYRelative(-aMoveDelta, aMoveDuration, idcStartSlowEndFast);
    end;
    lr4sOnLadderDown: begin
      MoveYRelative(aMoveDelta, aMoveDuration, idcStartSlowEndFast);
    end;
  end;
end;

procedure TLR4Direction.ProcessCallbackDoOnJumpMove(aMoveDuration: single; aJumpStep: integer);
var v, deltaX: single;
begin
  if FJumpToTheRight then v := 1 else v := -1;
  deltaX := FScene.Width*0.08;
  case aJumpStep of
    0: begin  // up
      Y.ChangeTo(Y.Value - FScene.Height*0.1, aMoveDuration, idcStartFastEndSlow);
      X.ChangeTo(X.Value + deltaX*v, aMoveDuration, idcLinear);
    end;
    1: begin  // down
      Y.ChangeTo(Y.Value + FScene.Height*0.1, aMoveDuration, idcStartSlowEndFast);// idcStartFastEndSlow);
      X.ChangeTo(X.Value + deltaX*v, aMoveDuration, idcLinear);
    end;
    2: begin
      if FJumpToTheRight then FState := lr4sRightIdle
        else FState := lr4sLeftIdle;
    end;
  end;
end;

constructor TLR4Direction.Create;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_PLAYER);

  FLRFront := TLRFrontView.Create;
  AddChild(FLRFront);

  FLRRight := TLRRightView.Create;
  AddChild(FLRRight);
  FLRRight.CallbackDoOnJumpMove := @ProcessCallbackDoOnJumpMove;

  FLRBack := TLRBackView.Create;
  AddChild(FLRBack);
  FLRBack.CallbackDoOnLadderMove := @ProcessCallbackDoOnLadderMove;

  State := lr4sDownIdle;
  DialogTextColor := BGRA(255,220,220);
  DialogAuthorName := PlayerInfo.Name;
end;

procedure TLR4Direction.SetIdlePosition;
begin
  Speed.Value := PointF(0, 0);
  case FState of
    lr4sRightWalking: State := lr4sRightIdle;
    lr4sLeftWalking: State := lr4sLeftIdle;
    lr4sDownWalking: State := lr4sDownIdle;
    lr4sUpWalking: State := lr4sUpIdle;
    lr4sOnLadderUp, lr4sOnLadderDown: State := lr4sOnLadderIdle;
  end;
end;

procedure TLR4Direction.SetWindSpeed(AValue: single);
begin
  FLRFront.SetWindSpeed(AValue);
  FLRRight.SetWindSpeed(AValue);
  FLRBack.SetWindSpeed(AValue);
end;

procedure TLR4Direction.SetFaceType(AValue: TLRFaceType);
begin
  FLRFront.Face.SetFaceType(AValue);
  FLRRight.Face.SetFaceType(AValue);
end;

procedure TLR4Direction.IdleLeft;
begin
  State := lr4sLeftIdle;
end;

procedure TLR4Direction.IdleRight;
begin
  State := lr4sRightIdle;
end;

procedure TLR4Direction.IdleUp;
begin
 State := lr4sUpIdle;
end;

procedure TLR4Direction.IdleDown;
begin
  State := lr4sDownIdle;
end;

procedure TLR4Direction.WalkHorizontallyTo(aX: single; aTargetScreen: TScreenTemplate;
  aMessageValueWhenFinish: TUserMessageValue; aDelay: single);
begin
  if X.Value < aX then begin
    State := lr4sRightWalking;
    CheckHorizontalMoveToX(aX, aTargetScreen, aMessageValueWhenFinish, aDelay);
  end else if X.Value > aX then begin
    State := lr4sLeftWalking;
    CheckHorizontalMoveToX(aX, aTargetScreen, aMessageValueWhenFinish, aDelay);
  end else aTargetScreen.PostMessage(aMessageValueWhenFinish, aDelay);
end;

procedure TLR4Direction.WalkVerticallyTo(aY: single; aTargetScreen: TScreenTemplate; aMessageValueWhenFinish: TUserMessageValue; aDelay: single);
begin
  if Y.Value+DeltaYToBottom < aY then begin
    State := lr4sDownWalking;
    CheckVerticalMoveToY(aY, aTargetScreen, aMessageValueWhenFinish, aDelay);
  end else if Y.Value+DeltaYToBottom > aY then begin
    State := lr4sUpWalking;
    CheckVerticalMoveToY(aY, aTargetScreen, aMessageValueWhenFinish, aDelay);
  end else aTargetScreen.PostMessage(aMessageValueWhenFinish, aDelay);
end;

{ TLRBackView }

procedure TLRBackView.SetDeformationOnHood;
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

procedure TLRBackView.SetState(AValue: TLRBackViewState);
begin
  if FState = AValue then Exit;

  if (AValue in [bvsLadderUp, bvsLadderDown]) and not FCanMoveOnLadder then exit;

  FState := AValue;
  if FState in [bvsIdle, bvsWalking] then FOnLadderStepAnim := 0;

  case FState of
    bvsIdle: begin
      SetIdlePosition(False);
    end;
    bvsWalking: begin
      SetIdlePosition(True);
      PostMessage(100);
    end;
    bvsIdleOnLadder: begin
      // do nothing
    end;
    bvsLadderUp: begin
      case FOnLadderStepAnim of
        1: PostMessage(202);
        2: PostMessage(201);
        else PostMessage(200);
      end;
    end;
    bvsLadderDown: begin
      case FOnLadderStepAnim of
        1: PostMessage(202);
        2: PostMessage(201);
        else PostMessage(200);
      end;
    end;
  end;// case
end;

constructor TLRBackView.Create;
begin
  inherited Create(FScene);

  FDress := TLRDress.Create(texLRbDress);
  AddChild(FDress, 0);
  FDress.X.Value := -FDress.Width*0.5;
  FDress.BottomY := 0;
  FDress.Pivot := PointF(0.5, 1.0);

  FHood := TDeformationGrid.Create(texLRbHood, False);
  FDress.AddChild(FHood, 1);
  FHood.CenterX := FDress.Width*0.48;
  FHood.BottomY := FDress.Height*0.87;
  SetDeformationOnHood;
  FHood.Pivot := PointF(0.5, 0.5);
  FHood.ApplySymmetryWhenFlip := True;

  FLeftArm := TSprite.Create(texLRbLeftArm, False);
  FDress.AddChild(FLeftArm, 0);
  FLeftArm.CenterX := FDress.Width*0.115;
  FLeftArm.Y.Value := FDress.Height*0.05;
  FLeftArm.Pivot := PointF(0.9, 0.05);
  FLeftArm.ApplySymmetryWhenFlip := True;
  FLeftArmOriginPosition := FLeftArm.GetXY;

  FRightArm := TSprite.Create(texLRbRightArm, False);
  FDress.AddChild(FRightArm, 0);
  FRightArm.CenterX := FDress.Width*0.86;
  FRightArm.Y.Value := FDress.Height*0.05;
  FRightArm.Pivot := PointF(0.1, 0.05);
  FRightArm.ApplySymmetryWhenFlip := True;
  FRightArmOriginPosition := FRightArm.GetXY;

  FLeftArmLadderUpPosition := FLeftArmOriginPosition + PointF(-FLeftArm.Width*0.14, FLeftArm.Height*0.2);
  FRightArmLadderDownPosition := FRightArmOriginPosition + PointF(-FRightArm.Width*0.2, FRightArm.Height*0.8);

  FLeftArmLadderDownPosition := FLeftArmOriginPosition + PointF(FLeftArm.Width*0.14, FLeftArm.Height*0.8);
  FRightArmLadderUpPosition := FRightArmOriginPosition + PointF(FRightArm.Width*0.2, FRightArm.Height*0.2);

  FYDeltaMoveOnLadder := FLeftArmLadderDownPosition.y - FLeftArmLadderUpPosition.y;

  FLeftLeg := CreateChildSprite(texLRbLeg, -1);
  FLeftLeg.X.Value := -FLeftLeg.Width*1.38;
  FLeftLeg.Y.Value := -FLeftLeg.Height*0.4;
  FLeftLeg.Pivot := PointF(0.5, 0);

  FRightLeg := CreateChildSprite(texLRbLeg, -1);
  FRightLeg.X.Value := FRightLeg.Width*0.11;
  FRightLeg.Y.Value := -FRightLeg.Height*0.42;
  FRightLeg.Pivot := PointF(0.5, 0);

  FYLegOriginPosition := FRightLeg.Y.Value;

  FLeftShoe := TSprite.Create(texLRbShoe, False);
  FLeftLeg.AddChild(FLeftShoe, -1);
  FLeftShoe.CenterX := FLeftLeg.Width*0.5;
  FLeftShoe.Y.Value := FLeftLeg.Height*0.95;
  FLeftShoe.ApplySymmetryWhenFlip := True;

  FRightShoe := TSprite.Create(texLRbShoe, False);
  FRightLeg.AddChild(FRightShoe, -1);
  FRightShoe.CenterX := FRightLeg.Width*0.5;
  FRightShoe.Y.Value := FRightLeg.Height*0.95;
  FRightShoe.ApplySymmetryWhenFlip := True;
  FYShoeOriginPosition := FRightShoe.Y.Value;

  DeltaYToTop := FDress.Height + FHood.Height*0.23;
  DeltaYToBottom := Trunc(FLeftLeg.Height*0.63 + FLeftShoe.Height);
  BodyWidth := FDress.Width;
  BodyHeight := Trunc(DeltaYToBottom + DeltaYToTop);

  FTimeMultiplicator := 1.0;
  FCanMoveOnLadder := True;
end;

procedure TLRBackView.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // WALKING
    100: begin
      if FState <> bvsWalking then exit;
      FLeftLeg.Y.Value := FYLegOriginPosition;
      FLeftShoe.Y.Value := FYShoeOriginPosition;
      FRightLeg.Y.Value := FYLegOriginPosition-FRightLeg.Height*0.40;
      FRightShoe.Y.Value := FYShoeOriginPosition-FRightShoe.Height*0.6;
      FLeftArm.Angle.Value := 10;
      FRightArm.Angle.Value := 10;
      FDress.Angle.Value := -1;
      FHood.Angle.Value := 1;
      PostMessage(102);
    end;
    101: begin
      if FState <> bvsWalking then exit;
      d := BASE_TIME_MOVE*FTimeMultiplicator;
      FLeftLeg.Y.ChangeTo(FYLegOriginPosition, d, idcSinusoid);
      FLeftShoe.Y.ChangeTo(FYShoeOriginPosition, d, idcSinusoid);
      FRightLeg.Y.ChangeTo(FYLegOriginPosition-FRightLeg.Height*0.30, d, idcSinusoid);
      FRightShoe.Y.ChangeTo(FYShoeOriginPosition-FRightShoe.Height*0.6, d, idcSinusoid);
      FLeftArm.Angle.ChangeTo(10, d, idcSinusoid);
      FRightArm.Angle.ChangeTo(10, d, idcSinusoid);
      FDress.Angle.ChangeTo(-1, d, idcSinusoid);
      FHood.Angle.ChangeTo(1, d, idcSinusoid);
      PostMessage(102, d);
    end;
    102: begin
      if FState <> bvsWalking then exit;
      d := BASE_TIME_MOVE*FTimeMultiplicator;
      FLeftLeg.Y.ChangeTo(FYLegOriginPosition-FRightLeg.Height*0.30, d, idcSinusoid);
      FLeftShoe.Y.ChangeTo(FYShoeOriginPosition-FRightShoe.Height*0.6, d, idcSinusoid);
      FRightLeg.Y.ChangeTo(FYLegOriginPosition, d, idcSinusoid);
      FRightShoe.Y.ChangeTo(FYShoeOriginPosition, d, idcSinusoid);
      FLeftArm.Angle.ChangeTo(-10, d, idcSinusoid);
      FRightArm.Angle.ChangeTo(-10, d, idcSinusoid);
      FDress.Angle.ChangeTo(1, d, idcSinusoid);
      FHood.Angle.ChangeTo(-1, d, idcSinusoid);
      PostMessage(101, d);
    end;

    // LADDER UP/DOWN
    200: begin
      if not (FState in [bvsLadderUp, bvsLadderDown]) then exit;
      FLeftArm.Angle.Value := 100;
      FLeftArm.MoveTo(FLeftArmLadderUpPosition, 0);
      FRightArm.Angle.Value := -110;
      FRightArm.MoveTo(FRightArmLadderDownPosition, 0);
      PostMessage(201);
    end;
    201: begin
      if not (FState in [bvsLadderUp, bvsLadderDown]) then exit;
      d := BASE_TIME_MOVE*FTimeMultiplicator;
      FLeftArm.MoveTo(FLeftArmLadderDownPosition, d, idcStartSlowEndFast);
      FRightArm.MoveTo(FRightArmLadderUpPosition, d, idcStartSlowEndFast);
      FLeftLeg.Y.ChangeTo(FYLegOriginPosition, d, idcStartSlowEndFast);
      FLeftShoe.Y.ChangeTo(FYShoeOriginPosition, d, idcStartSlowEndFast);
      FRightLeg.Y.ChangeTo(FYLegOriginPosition-FRightLeg.Height*0.40, d, idcStartSlowEndFast);
      FRightShoe.Y.ChangeTo(FYShoeOriginPosition-FRightShoe.Height*0.6, d, idcStartSlowEndFast);
      FCallbackDoOnLadderMove(FYDeltaMoveOnLadder, d);
      PostMessage(202, d);
      FOnLadderStepAnim := 1;
      FCanMoveOnLadder := False;
      PostMessage(203, d);
    end;
    202: begin
      if not (FState in [bvsLadderUp, bvsLadderDown]) then exit;
      d := BASE_TIME_MOVE*FTimeMultiplicator;
      FLeftArm.MoveTo(FLeftArmLadderUpPosition, d, idcStartSlowEndFast);
      FRightArm.MoveTo(FRightArmLadderDownPosition, d, idcStartSlowEndFast);
      FLeftLeg.Y.ChangeTo(FYLegOriginPosition-FRightLeg.Height*0.40, d, idcStartSlowEndFast);
      FLeftShoe.Y.ChangeTo(FYShoeOriginPosition-FRightShoe.Height*0.6, d, idcStartSlowEndFast);
      FRightLeg.Y.ChangeTo(FYLegOriginPosition, d, idcStartSlowEndFast);
      FRightShoe.Y.ChangeTo(FYShoeOriginPosition, d, idcStartSlowEndFast);
      FCallbackDoOnLadderMove(FYDeltaMoveOnLadder, d);
      PostMessage(201, d);
      FOnLadderStepAnim := 2;
      FCanMoveOnLadder := False;
      PostMessage(203, d);
    end;
    203: begin
      FCanMoveOnLadder := True;
    end;
  end;//case
end;

procedure TLRBackView.SetFlipH(AValue: boolean);
begin
  FDress.FlipH := AValue;
  FHood.FlipH := AValue;
  FLeftArm.FlipH := AValue;
  FRightArm.FlipH := AValue;
  FLeftLeg.FlipH := AValue;
  FRightLeg.FlipH := AValue;
  FLeftShoe.FlipH := AValue;
  FRightShoe.FlipH := AValue;
end;

procedure TLRBackView.SetFlipV(AValue: boolean);
begin
  FDress.FlipV := AValue;
  FHood.FlipV := AValue;
  FLeftArm.FlipV := AValue;
  FRightArm.FlipV := AValue;
  FLeftLeg.FlipV := AValue;
  FRightLeg.FlipV := AValue;
  FLeftShoe.FlipV := AValue;
  FRightShoe.FlipV := AValue;
end;

procedure TLRBackView.SetWindSpeed(AValue: single);
begin
  FDress.SetWindSpeed(AValue);
  FHood.Amplitude.Value := PointF(0.3*AValue, 0.2*AValue);
end;

procedure TLRBackView.SetIdlePosition(aImmediat: boolean);
var d: single;
begin
  if aImmediat then d := 0 else d := 0.5;
  FDress.Angle.ChangeTo(0, d, idcSinusoid);
  FHood.Angle.ChangeTo(0, d, idcSinusoid);
  FLeftArm.Angle.ChangeTo(0, d, idcSinusoid);
  FLeftArm.MoveTo(FLeftArmOriginPosition, d, idcSinusoid);
  FRightArm.Angle.ChangeTo(0, d, idcSinusoid);
  FRightArm.MoveTo(FRightArmOriginPosition, d, idcSinusoid);
  FLeftLeg.Y.ChangeTo(FYLegOriginPosition, d, idcSinusoid);
  FRightLeg.Y.ChangeTo(FYLegOriginPosition, d, idcSinusoid);
  FLeftShoe.Y.ChangeTo(FYShoeOriginPosition, d, idcSinusoid);
  FRightShoe.Y.ChangeTo(FYShoeOriginPosition, d, idcSinusoid);
end;

{ TLRRightViewFace }

constructor TLRRightViewFace.Create;
begin
  inherited Create(texLRrFace);

  // white background behind the face
  WhiteBG := CreateChildSprite(texLRFaceBGWhite, -2);
  WhiteBG.SetCenterCoordinate(Width*0.51, Height*0.5);

  // left eye
  LeftEye := CreateChildPolar(texLREye, -1);
  LeftEye.Polar.Center.Value := PointF(Width*0.77, Height*0.50);

  // right eye
  RightEye := CreateChildPolar(texLREye, -1);
  RightEye.Polar.Center.Value := PointF(Width*0.35, Height*0.54);

  EyeMaxDistance := LeftEye.Width*0.30;

  // hair lock
  HairLock := CreateChildSprite(texLRHairLock, -1);
  HairLock.SetCoordinate(Width*0.85, Height*0.56);
  HairLock.Pivot := PointF(0.5, 0);

  // hair
  Hair := CreateChildDeformationGrid(texLRrFaceHair, 0);
  Hair.SetCenterCoordinate(Width*0.50, Height*0.40);
  SetDeformationOnHair(Hair);

  RightEar := CreateChildSprite(texLRrEar, 1);
  RightEar.X.Value := -RightEar.Width*0.3;
  RightEar.CenterY := Height*0.58;

  // mouth smile
  MouthSmile := CreateChildSprite(texLRrFaceMouthSmile, 0);
  MouthSmile.SetCenterCoordinate(Width*0.55, Height*0.85);

  // mouth worry
  MouthWorry := CreateChildSprite(texLRFaceMouthWorry, 0);
  MouthWorry.SetCenterCoordinate(Width*0.55, Height*0.85);

  MouthNotHappy := CreateChildSprite(texLRrFaceMouthNotHappy, 0);
  MouthNotHappy.SetCenterCoordinate(Width*0.45, Height*0.85);

  FaceType := lrfSmile;
  PostMessage(0);
  PostMessage(100);
  PostMessage(200);
  PostMessage(300);
end;

procedure TLRRightViewFace.SetFaceType(AValue: TLRFaceType);
begin
  inherited SetFaceType(AValue);
  MouthSmile.Visible := AValue = lrfSmile;
 // MouthOpen.Visible := AValue = lrfHappy;
  MouthNotHappy.Visible := AValue in [lrfNotHappy, lrfVomit];
  MouthWorry.Visible := AValue = lrfWorry;
end;

procedure TLRRightViewFace.SetFlipH(AValue: boolean);
begin
  FlipH := AValue;
  LeftEye.FlipH := AValue;
  RightEye.FlipH := AValue;
  Hair.FlipH := AValue;
  MouthSmile.FlipH := AValue;
  MouthWorry.FlipH := AValue;
  HairLock.FlipH := AValue;
  RightEar.FlipH := AValue;
  WhiteBG.FlipH := AValue;
end;

procedure TLRRightViewFace.SetFlipV(AValue: boolean);
begin
  FlipV := AValue;
  LeftEye.FlipV := AValue;
  RightEye.FlipV := AValue;
  Hair.FlipV := AValue;
  MouthSmile.FlipV := AValue;
  MouthWorry.FlipV := AValue;
  HairLock.FlipV := AValue;
  RightEar.FlipV := AValue;
  WhiteBG.FlipV := AValue;
end;

procedure TLRRightViewFace.SetWindSpeed(AValue: single);
begin
  SetWindSpeedOnHair(Hair, AValue);
end;

{ TLRRightView }

procedure TLRRightView.SetDeformationOnHood;
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

function TLRRightView.GetIsOrientedToRight: boolean;
begin
  Result := not FDress.FlipH;
end;

procedure TLRRightView.SetDeformationOnLeftCloak;
begin
  FLeftCloak.SetGrid(5, 5);
  FLeftCloak.ApplyDeformation(dtWaveH);
  FLeftCloak.Amplitude.Value := PointF(0.3, 0.2);
  FLeftCloak.DeformationSpeed.Value := PointF(5,5);
  FLeftCloak.SetDeformationAmountOnRow(0, 0);
  FLeftCloak.SetDeformationAmountOnRow(1, 0.1);
  FLeftCloak.SetDeformationAmountOnRow(2, 0.2);
  FLeftCloak.SetDeformationAmountOnRow(3, 0.4);
  FLeftCloak.SetDeformationAmountOnRow(4, 0.6);
  FLeftCloak.SetDeformationAmountOnRow(5, 1.0);
end;

procedure TLRRightView.SetState(AValue: TLRRightViewState);
begin
  if FState = AValue then Exit;
  if (AValue = rvsJumping) and FIsJumping then exit;
  FState := AValue;
  case FState of
    rvsIdle: begin
      SetIdlePosition(False);
    end;
    rvsWalking: begin
      ClearMessageList;
      PostMessage(100);
    end;
    rvsJumping: begin
      FIsJumping := True;
      PostMessage(200);
    end;
    rvsBendDown: begin
      PostMessage(300);
    end;
    rvsBendUp: begin
      PostMessage(400);
    end;
  end;
end;

constructor TLRRightView.Create;
begin
  inherited Create(FScene);

  FDress := TLRDress.Create(texLRrDress);
  AddChild(FDress, 0);
  FDress.X.Value := -FDress.Width*0.5;
  FDress.BottomY := 0;
  FDress.Pivot := PointF(0.5, 1.0);

  FYDressOriginPosition := FDress.GetXY;

  FHood := TDeformationGrid.Create(texLRrHood, False); //CreateChildDeformationGrid(texLRrHood, 1);
  FDress.AddChild(FHood, 1);
  FHood.CenterX := FDress.Width*0.40;
  FHood.BottomY := FDress.Height*0.9;
  FHood.Pivot := PointF(0.5, 0.5); //1.08);
  FHood.ApplySymmetryWhenFlip := True;
  SetDeformationOnHood;

  FLeftCloak := TDeformationGrid.Create(texLRrLeftCloak, False); //CreateChildDeformationGrid(texLRrLeftCloak, -1);
  FDress.AddChild(FLeftCloak, -2);
  FLeftCloak.X.Value := FDress.Width*0.30;
  FLeftCloak.Y.Value := FDress.Height*0.1;
  FLeftCloak.Pivot := PointF(0.4, 0);
  FLeftCloak.ApplySymmetryWhenFlip := True;
  SetDeformationOnLeftCloak;

  Face := TLRRightViewFace.Create;
  FHood.AddChild(Face, 0);
  Face.CenterX := FHood.Width*0.57;
  Face.CenterY := FHood.Height*0.42;
  Face.OriginCenterCoor := Face.Center;
  //Face.ApplySymmetryWhenFlip := True;

  FRightArm := TSprite.Create(texLRrRightArm, False);
  FDress.AddChild(FRightArm, 0);
  FRightArm.SetCoordinate(FDress.Width*0.05, FDress.Height*0.15);
  FRightArm.Pivot := PointF(0.2, 0.1);
  FRightArm.ApplySymmetryWhenFlip := True;

  FLeftArm := TSprite.Create(texLRrLeftArm, False);
  FDress.AddChild(FLeftArm, -1);
  FLeftArm.SetCoordinate(FDress.Width*0.5, FDress.Height*0.10);
  FLeftArm.Pivot := PointF(0.2, 0.1);
  FLeftArm.ApplySymmetryWhenFlip := True;

  FRightLeg := CreateChildSprite(texLRrLeg, -1);
  FRightLeg.SetCoordinate(-FRightLeg.Width*0.8, -FRightLeg.Height*0.25);
  FRightLeg.Pivot := PointF(0.3,0.05);

  FLeftLeg := CreateChildSprite(texLRrLeg, -1);
  FLeftLeg.SetCoordinate(0, -FLeftLeg.Height*0.25);
  FLeftLeg.Pivot := PointF(0.3,0.05);

  DeltaYToTop := FDress.Height + Face.Height*1.1;
  DeltaYToBottom := Trunc(FLeftLeg.Height*0.75);
  BodyWidth := FDress.Width;
  BodyHeight := Trunc(DeltaYToBottom + DeltaYToTop);

  FTimeMultiplicator := 1.0;
end;

procedure TLRRightView.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // WALKING
    100: begin
      if FState <> rvsWalking then exit;
      FLeftLeg.Angle.Value := -25;
      FRightLeg.Angle.Value := 22;
      FLeftArm.Angle.Value := 20;
      FRightArm.Angle.Value := -20;
      FDress.Angle.Value := 1;
      FHood.Angle.Value := 1;
      FLeftCloak.Angle.Value := 1;
      PostMessage(102);
    end;
    101: begin
      if FState <> rvsWalking then exit;
      d := BASE_TIME_MOVE*FTimeMultiplicator;
      FLeftLeg.Angle.ChangeTo(-25, d, idcSinusoid);
      FRightLeg.Angle.ChangeTo(22, d, idcSinusoid);
      FLeftArm.Angle.ChangeTo(20, d, idcSinusoid);
      FRightArm.Angle.ChangeTo(-20, d, idcSinusoid);
      FDress.Angle.ChangeTo(1, d, idcSinusoid);
      FHood.Angle.ChangeTo(1, d, idcSinusoid);
      FLeftCloak.Angle.ChangeTo(1, d, idcSinusoid);
      PostMessage(102, d);
    end;
    102: begin
      if FState <> rvsWalking then exit;
      d := BASE_TIME_MOVE*FTimeMultiplicator;
      FLeftLeg.Angle.ChangeTo(25, d, idcSinusoid);
      FRightLeg.Angle.ChangeTo(-20, d, idcSinusoid);
      FLeftArm.Angle.ChangeTo(-15, d, idcSinusoid);
      FRightArm.Angle.ChangeTo(15, d, idcSinusoid);
      FDress.Angle.ChangeTo(-1, d, idcSinusoid);
      FHood.Angle.ChangeTo(-1, d, idcSinusoid);
      FLeftCloak.Angle.ChangeTo(-1, d, idcSinusoid);
      PostMessage(101, d);
    end;

    // JUMP ANIM
    200: begin
      // start position
      FLeftLeg.Angle.Value := 40;
      FRightLeg.Angle.Value := 40;
      FDress.Angle.Value := -3;
      FHood.Angle.Value := -3;
      FLeftArm.Angle.Value := 20;
      FRightArm.Angle.Value := 20;

      // in air
      d := 1.0*FTimeMultiplicator*0.5;
      FLeftLeg.Angle.ChangeTo(-40, d, idcLinear);
      FRightLeg.Angle.ChangeTo(-40, d, idcLinear);
      FDress.Angle.ChangeTo(10, d, idcLinear);
      FHood.Angle.ChangeTo(6, d, idcLinear);
      FLeftArm.Angle.ChangeTo(-40, d, idcLinear);
      FRightArm.Angle.ChangeTo(-40, d, idcLinear);

      FCallbackDoOnJumpMove(d, 0);
      PostMessage(201, d);
    end;
    201: begin
      d := 1.0*FTimeMultiplicator*0.5;
      FLeftLeg.Angle.ChangeTo(0, d, idcStartSlowEndFast);
      FRightLeg.Angle.ChangeTo(0, d, idcStartSlowEndFast);
      FDress.Angle.ChangeTo(0, d, idcStartSlowEndFast);
      FHood.Angle.ChangeTo(0, d, idcStartSlowEndFast);
      FLeftArm.Angle.ChangeTo(0, d, idcStartSlowEndFast);
      FRightArm.Angle.ChangeTo(0, d, idcStartSlowEndFast);
      FCallbackDoOnJumpMove(d, 1);
      PostMessage(202, d);
    end;
    202: begin
      FIsJumping := False;
      SetIdlePosition(True);
      FCallbackDoOnJumpMove(0, 2);
      State := rvsIdle;
    end;

    // BEND DOWN
    300: begin
      if State <> rvsBendDown then exit;
      d := BASE_TIME_BEND*FTimeMultiplicator;
      FDress.Angle.ChangeTo(45, d, idcSinusoid);
      FDress.MoveTo(FYDressOriginPosition + PointF(-FDress.Width*0.1, FDress.Height*0.1), d, idcSinusoid);
      FHood.Angle.ChangeTo(3, d, idcSinusoid);
      FRightArm.Angle.ChangeTo(15, d, idcSinusoid);
      FLeftArm.Angle.ChangeTo(-20, d, idcSinusoid);
      PostMessage(301, d);
    end;
    301: begin
      if State <> rvsBendDown then exit;
      if FCallbackPickUpSomethingWhenBendDown <> NIL then
        FCallbackPickUpSomethingWhenBendDown(IsOrientedToRight);
    end;

    // BEND UP
    400: begin
      if State <> rvsBendUp then exit;
      d := BASE_TIME_BEND*FTimeMultiplicator;
      FDress.Angle.ChangeTo(0, d, idcSinusoid);
      FDress.MoveTo(FYDressOriginPosition, d, idcSinusoid);
      FHood.Angle.ChangeTo(0, d, idcSinusoid);
      FRightArm.Angle.ChangeTo(0, d, idcSinusoid);
      FLeftArm.Angle.ChangeTo(0, d, idcSinusoid);
      PostMessage(401, d);
    end;
    401: begin
      SetIdlePosition(True);
      State := rvsIdle;
    end;
  end;//case
end;

procedure TLRRightView.SetFlipH(AValue: boolean);
begin
  Face.FlipH := AValue;
  Face.SetFlipH(AValue);
  FDress.FlipH := AValue;
  FHood.FlipH := AValue;
  FLeftCloak.FlipH := AValue;
  FLeftArm.FlipH := AValue;
  FRightArm.FlipH := AValue;
  FLeftLeg.FlipH := AValue;
  FRightLeg.FlipH := AValue;
end;

procedure TLRRightView.SetFlipV(AValue: boolean);
begin
  Face.FlipV := AValue;
  Face.SetFlipV(AValue);
  FDress.FlipV := AValue;
  FHood.FlipV := AValue;
  FLeftCloak.FlipV := AValue;
  FLeftArm.FlipV := AValue;
  FRightArm.FlipV := AValue;
  FLeftLeg.FlipV := AValue;
  FRightLeg.FlipV := AValue;
end;

procedure TLRRightView.SetWindSpeed(AValue: single);
begin
  Face.SetWindSpeed(AValue);
  FDress.SetWindSpeed(AValue);
  FHood.Amplitude.Value := PointF(0.3*AValue, 0.2*AValue);
  FLeftCloak.Amplitude.Value := PointF(0.3*AValue, 0.2*AValue);
end;

procedure TLRRightView.SetIdlePosition(aImmediat: boolean);
var d: single;
begin
  if aImmediat then d := 0 else d := 0.5;
  FDress.Angle.ChangeTo(0, d, idcSinusoid);
  FLeftArm.Angle.ChangeTo(0, d, idcSinusoid);
  FRightArm.Angle.ChangeTo(0, d, idcSinusoid);
  FLeftLeg.Angle.ChangeTo(0, d, idcSinusoid);
  FRightLeg.Angle.ChangeTo(0, d, idcSinusoid);
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

procedure TLRFrontView.SetDeformationOnLeftCloak;
begin
  FLeftCloak.SetGrid(5, 5);
  FLeftCloak.ApplyDeformation(dtWaveH);
  FLeftCloak.Amplitude.Value := PointF(0.3, 0.2);
  FLeftCloak.DeformationSpeed.Value := PointF(5,5);
  FLeftCloak.SetDeformationAmountOnRow(0, 0);
  FLeftCloak.SetDeformationAmountOnRow(1, 0.1);
  FLeftCloak.SetDeformationAmountOnRow(2, 0.2);
  FLeftCloak.SetDeformationAmountOnRow(3, 0.4);
  FLeftCloak.SetDeformationAmountOnRow(4, 0.6);
  FLeftCloak.SetDeformationAmountOnRow(5, 1.0);
end;

procedure TLRFrontView.SetState(AValue: TLRFrontViewState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  case FState of
    fvsIdle: begin
      SetIdlePosition(False);
    end;
    fvsWalking: begin
      PostMessage(100);
    end;
    fvsStartAnimWinner: begin
      SetIdlePosition(True);
      PostMessage(200);
    end;
  end;
end;

constructor TLRFrontView.Create;
begin
  inherited Create(FScene);

  FDress := TLRDress.Create(texLRfDress);
  AddChild(FDress, 0);
  FDress.X.Value := -FDress.Width*0.5;
  FDress.BottomY := 0;
  FDress.Pivot := PointF(0.5, 1.0);

  FHood := CreateChildDeformationGrid(texLRfHood, 1);
  FHood.X.Value := -FHood.Width*0.52;
  FHood.BottomY := -FHood.Height*0.06;
  FHood.Pivot := PointF(0.5, 1.0);
  SetDeformationOnHood;

  FLeftCloak := CreateChildDeformationGrid(texLRfLeftCloak, 1);
  FLeftCloak.X.Value := FLeftCloak.Width*0.06;
  FLeftCloak.BottomY := -FLeftCloak.Height*0.24;
  FLeftCloak.Pivot := PointF(0.1, 1.0);
  SetDeformationOnLeftCloak;

  Face := TLRFrontViewFace.Create;
  FHood.AddChild(Face, 0);
  Face.CenterX := FHood.Width*0.52;
  Face.CenterY := FHood.Height*0.43;
  Face.OriginCenterCoor := Face.Center;

  FRightArm := TSprite.Create(texLRfRightArm, False);
  FDress.AddChild(FRightArm, 1);
  FRightArm.SetCoordinate(FDress.Width*0.12, FDress.Height*0.23);
  FRightArm.Pivot := PointF(0.2, 0.1);
  FRightArm.ApplySymmetryWhenFlip := True;

  FLeftArm := TSprite.Create(texLRfLeftArm, False);
  FDress.AddChild(FLeftArm, 1);
  FLeftArm.SetCoordinate(FDress.Width*0.53, FDress.Height*0.21);
  FLeftArm.Pivot := PointF(0.8, 0.1);
  FLeftArm.ApplySymmetryWhenFlip := True;

  FRightLeg := CreateChildSprite(texLRfRightLeg, -1);
  FRightLeg.SetCoordinate(-FRightLeg.Width, -FRightLeg.Height*0.25);

  FLeftLeg := CreateChildSprite(texLRfLeftLeg, -1);
  FLeftLeg.SetCoordinate(FLeftLeg.Width*0.05, -FLeftLeg.Height*0.25);

  FYLegIdlePosition := FLeftLeg.Y.Value;

  FLeftShoe := TSpriteWithElasticCorner.Create(texLRfLeftShoe, False);
  FLeftLeg.AddChild(FLeftShoe, 0);
  FLeftShoe.CenterX := FLeftLeg.Width*0.5;
  FLeftShoe.Y.Value := FLeftLeg.Height*0.8;
  FLeftShoe.ApplySymmetryWhenFlip := True;

  FRightShoe := TSpriteWithElasticCorner.Create(texLRfRightShoe, False);
  FRightLeg.AddChild(FRightShoe, 0);
  FRightShoe.CenterX := FRightLeg.Width*0.5;
  FRightShoe.Y.Value := FRightLeg.Height*0.8;
  FRightShoe.ApplySymmetryWhenFlip := True;

  DeltaYToTop := FDress.Height + Face.Height*1.2;
  DeltaYToBottom := Trunc(FLeftLeg.Height*0.75 + FLeftShoe.Height*0.54);
  BodyWidth := Trunc(FDress.Width*0.8);
  BodyHeight := Trunc(DeltaYToBottom + DeltaYToTop);

  FTimeMultiplicator := 1.0;
end;

procedure TLRFrontView.ProcessMessage(UserValue: TUserMessageValue);
var d: single;
begin
  case UserValue of
    // WALKING
    100: begin
      if FState <> fvsWalking then exit;
      FLeftLeg.Y.Value := FYLegIdlePosition-FLeftLeg.Height*0.3;

      FLeftShoe.CornerOffset.BottomLeft.x.Value := FLeftShoe.Width*0.2;
      FLeftShoe.CornerOffset.BottomRight.x.Value := -FLeftShoe.Width*0.2;

      FRightLeg.Y.Value := FYLegIdlePosition;
      FRightShoe.CornerOffset.BottomLeft.x.Value := 0;
      FRightShoe.CornerOffset.BottomRight.x.Value := 0;

      FLeftArm.Angle.Value := 20;
      FRightArm.Angle.Value := 20;
      FDress.Angle.Value := 0.5;
      FHood.Angle.Value := 1;
      FLeftCloak.Angle.Value := 1;
      PostMessage(102);
    end;
    101: begin
      if FState <> fvsWalking then exit;
      d := BASE_TIME_MOVE*FTimeMultiplicator;
      FLeftLeg.Y.ChangeTo(FYLegIdlePosition-FLeftLeg.Height*0.3, d, idcSinusoid);

      FLeftShoe.CornerOffset.BottomLeft.x.ChangeTo(FLeftShoe.Width*0.2, d, idcSinusoid);
      FLeftShoe.CornerOffset.BottomRight.x.ChangeTo(-FLeftShoe.Width*0.2, d, idcSinusoid);

      FRightLeg.Y.ChangeTo(FYLegIdlePosition, d, idcSinusoid);
      FRightShoe.CornerOffset.BottomLeft.x.ChangeTo(0, d, idcSinusoid);
      FRightShoe.CornerOffset.BottomRight.x.ChangeTo(0, d, idcSinusoid);

      FLeftArm.Angle.ChangeTo(20, d, idcSinusoid);
      FRightArm.Angle.ChangeTo(20, d, idcSinusoid);
      FDress.Angle.ChangeTo(0.5, d, idcSinusoid);
      FHood.Angle.ChangeTo(1, d, idcSinusoid);
      FLeftCloak.Angle.ChangeTo(1, d, idcSinusoid);
      PostMessage(102, d);
    end;
    102: begin
      if FState <> fvsWalking then exit;
      d := BASE_TIME_MOVE*FTimeMultiplicator;
      FLeftLeg.Y.ChangeTo(FYLegIdlePosition, d, idcSinusoid);
      FLeftShoe.CornerOffset.BottomLeft.x.ChangeTo(0, d, idcSinusoid);
      FLeftShoe.CornerOffset.BottomRight.x.ChangeTo(0, d, idcSinusoid);
      FRightLeg.Y.ChangeTo(FYLegIdlePosition-FLeftLeg.Height*0.3, d, idcSinusoid);
      FRightShoe.CornerOffset.BottomLeft.x.ChangeTo(FLeftShoe.Width*0.2, d, idcSinusoid);
      FRightShoe.CornerOffset.BottomRight.x.ChangeTo(-FLeftShoe.Width*0.2, d, idcSinusoid);
      FLeftArm.Angle.ChangeTo(-20, d, idcSinusoid);
      FRightArm.Angle.ChangeTo(-20, d, idcSinusoid);
      FDress.Angle.ChangeTo(-0.5, d, idcSinusoid);
      FHood.Angle.ChangeTo(-1, d, idcSinusoid);
      FLeftCloak.Angle.ChangeTo(-1, d, idcSinusoid);
      PostMessage(101, d);
    end;

    // WINNER
    200: begin
      if FState <> fvsStartAnimWinner then exit;
      FRightArm.Angle.Value := 150;
      FLeftArm.Angle.Value := -150;
      FLeftLeg.Pivot := PointF(0.5, 0.1);
      FRightLeg.Pivot := PointF(0.5, 0.1);
      FLeftLeg.Angle.Value := -20;
      FRightLeg.Angle.Value := 20;
      Face.SetFaceType(lrfHappy);
      FWinJumpCount := 0;
      PostMessage(201);
    end;
    201: begin
      Y.ChangeTo(Y.Value-FLeftLeg.Height*0.3, 0.2, idcStartFastEndSlow);
      FRightArm.Angle.ChangeTo(150, 0.2, idcStartFastEndSlow);
      FLeftArm.Angle.ChangeTo(-150, 0.2, idcStartFastEndSlow);
      PostMessage(202, 0.2);
    end;
    202: begin
      Y.ChangeTo(Y.Value+FLeftLeg.Height*0.3, 0.2, idcStartSlowEndFast);
      FRightArm.Angle.ChangeTo(140, 0.2, idcStartFastEndSlow);
      FLeftArm.Angle.ChangeTo(-140, 0.2, idcStartFastEndSlow);
      inc(FWinJumpCount);
      if FWinJumpCount < 4 then PostMessage(201, 0.2)
        else State := fvsEndAnimWinner;
    end;
  end;//case
end;

procedure TLRFrontView.SetFlipH(AValue: boolean);
begin
  Face.SetFlipH(AValue);
  FDress.FlipH := AValue;
  FHood.FlipH := AValue;
  FLeftCloak.FlipH := AValue;
  FLeftShoe.FlipH := AValue;
  FRightShoe.FlipH := AValue;
  FLeftArm.FlipH := AValue;
  FRightArm.FlipH := AValue;
  FLeftLeg.FlipH := AValue;
  FRightLeg.FlipH := AValue;
end;

procedure TLRFrontView.SetFlipV(AValue: boolean);
begin
  Face.SetFlipV(AValue);
  FDress.FlipV := AValue;
  FHood.FlipV := AValue;
  FLeftCloak.FlipV := AValue;
  FLeftShoe.FlipV := AValue;
  FRightShoe.FlipV := AValue;
  FLeftArm.FlipV := AValue;
  FRightArm.FlipV := AValue;
  FLeftLeg.FlipV := AValue;
  FRightLeg.FlipV := AValue;
end;

procedure TLRFrontView.SetWindSpeed(AValue: single);
begin
  Face.SetWindSpeed(AValue);
  FDress.SetWindSpeed(AValue);
  FHood.Amplitude.Value := PointF(0.3*AValue, 0.2*AValue);
  FLeftCloak.Amplitude.Value := PointF(0.3*AValue, 0.2*AValue);
end;

procedure TLRFrontView.SetIdlePosition(aImmediat: boolean);
var v: single;
begin
  if aImmediat then v := 0 else v := 0.5;
  FDress.Angle.ChangeTo(0, v, idcSinusoid);
  FHood.Angle.ChangeTo(0, v, idcSinusoid);
  FLeftCloak.Angle.ChangeTo(0, v, idcSinusoid);
  FLeftArm.Angle.ChangeTo(0, v, idcSinusoid);
  FRightArm.Angle.ChangeTo(0, v, idcSinusoid);
  FLeftLeg.Y.ChangeTo(FYLegIdlePosition, v, idcSinusoid);
  FLeftLeg.Angle.ChangeTo(0, v, idcSinusoid);
  FRightLeg.Y.ChangeTo(FYLegIdlePosition, v, idcSinusoid);
  FRightLeg.Angle.ChangeTo(0, v, idcSinusoid);
  FLeftShoe.Angle.ChangeTo(0, v, idcSinusoid);
  FRightShoe.Angle.ChangeTo(0, v, idcSinusoid);
  FLeftShoe.CornerOffset.BottomLeft.ChangeTo(PointF(0,0), v, idcSinusoid);
  FLeftShoe.CornerOffset.BottomRight.ChangeTo(PointF(0,0), v, idcSinusoid);
  FRightShoe.CornerOffset.BottomLeft.ChangeTo(PointF(0,0), v, idcSinusoid);
  FRightShoe.CornerOffset.BottomRight.ChangeTo(PointF(0,0), v, idcSinusoid);
end;

{ TLRFrontViewFace }

procedure TLRFrontViewFace.SetFaceType(AValue: TLRFaceType);
begin
  inherited SetFaceType(AValue);
  MouthSmile.Visible := AValue = lrfSmile;
  MouthOpen.Visible := AValue = lrfHappy;
  MouthNotHappy.Visible := AValue in [lrfNotHappy, lrfVomit];
  MouthWorry.Visible := AValue = lrfWorry;
end;

constructor TLRFrontViewFace.Create;
begin
  inherited Create(texLRfFace);

  // white background behind the face
  WhiteBG := CreateChildSprite(texLRFaceBGWhite, -2);
  WhiteBG.SetCenterCoordinate(Width*0.55, Height*0.5);

  // left eye
  LeftEye := CreateChildPolar(texLREye, -1);
  LeftEye.Polar.Center.Value := PointF(Width*0.76, Height*0.53);

  // right eye
  RightEye := CreateChildPolar(texLREye, -1);
  RightEye.Polar.Center.Value := PointF(Width*0.33, Height*0.53);

  EyeMaxDistance := LeftEye.Width*0.15;

  // hair lock
  HairLock := CreateChildSprite(texLRHairLock, -1);
  HairLock.SetCoordinate(Width*0.87, Height*0.58);
  HairLock.Pivot := PointF(0.5, 0);

  // hair
  Hair := CreateChildDeformationGrid(texLRfFaceHair, 0);
  Hair.SetCenterCoordinate(Width*0.55, Height*0.40);
  SetDeformationOnHair(Hair);

  // mouth hurt
  MouthNotHappy := CreateChildSprite(texLRfFaceMouthHurt, 0);
  MouthNotHappy.SetCenterCoordinate(Width*0.5, Height*0.90);

  // mouth open
  MouthOpen := CreateChildSprite(texLRfFaceMouthOpen, 0);
  MouthOpen.SetCenterCoordinate(Width*0.55, Height*0.88);

  // mouth smile
  MouthSmile := CreateChildSprite(texLRfFaceMouthSmile, 0);
  MouthSmile.SetCenterCoordinate(Width*0.55, Height*0.85);

  // mouth worry
  MouthWorry := CreateChildSprite(texLRFaceMouthWorry, 0);
  MouthWorry.SetCenterCoordinate(Width*0.55, Height*0.85);

  FaceType := lrfSmile;
  PostMessage(0);
  PostMessage(100);
  PostMessage(210);
  PostMessage(300);
end;

procedure TLRFrontViewFace.SetFlipH(AValue: boolean);
begin
  FlipH := AValue;
  LeftEye.FlipH := AValue;
  RightEye.FlipH := AValue;
  Hair.FlipH := AValue;
  HairLock.FlipH := AValue;
  MouthNotHappy.FlipH := AValue;
  MouthOpen.FlipH := AValue;
  MouthSmile.FlipH := AValue;
  MouthWorry.FlipH := AValue;
  WhiteBG.FlipH := AValue;
end;

procedure TLRFrontViewFace.SetFlipV(AValue: boolean);
begin
  FlipV := AValue;
  LeftEye.FlipV := AValue;
  RightEye.FlipV := AValue;
  Hair.FlipV := AValue;
  HairLock.FlipV := AValue;
  MouthNotHappy.FlipV := AValue;
  MouthOpen.FlipV := AValue;
  MouthSmile.FlipV := AValue;
  MouthWorry.FlipV := AValue;
  WhiteBG.FlipV := AValue;
end;

procedure TLRFrontViewFace.SetWindSpeed(AValue: single);
begin
  SetWindSpeedOnHair(Hair, AValue);
end;

end.

