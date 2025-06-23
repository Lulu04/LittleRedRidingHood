unit u_eggs_boss;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes,
  u_sprite_lrcommon;

type

TEggShoot = class(TSprite)
  OwnerIsLR, FCheckCollision: boolean;
  constructor Create(aTex: PTexture);
  procedure Update(const aElapsedTime: single); override;
end;

{ TCommonEggs }    // LAYER_ARROW

TEggState = (eggsUndefined, eggsIdleFly);
TCommonEggs = class(TSprite)
  class var texEggRed, texBGRed, texEggBlack, texBGBlack, texRedShoot, texBlackShoot: PTexture;
private
  FBG: TSprite;
  FState: TEggState;
  FOwnerIsLR, FShootSide, FApplyBounds: boolean;
  FTimeBeforeNextShoot: single;
  FAcceleration, FFriction: single;
  FBounds: TRect;
  FDriver: TCharacterWithDialogPanel;
  procedure SetState(AValue: TEggState);
  procedure DoShoot(aTex: PTexture);
protected
  procedure SetFlipH(AValue: boolean); override;
  procedure SetFlipV(AValue: boolean); override;
public
  class procedure LoadTexture(aAtlas: TAtlas);
  constructor Create(aTexEgg, aTexBG: Ptexture);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
public
  procedure SetDriverAsChild(aCharacter: TCharacterWithDialogPanel);
  procedure Defend(AValue: boolean);
  procedure MoveRight;
  procedure MoveLeft;
  procedure MoveUp;
  procedure MoveDown;

  property State: TEggState read FState write SetState;
  property ApplyBounds: boolean read FApplyBounds write FApplyBounds;
end;

{ TRedEgg }

TRedEgg = class(TCommonEggs)
public
  constructor Create;
  procedure Shoot;
end;

{ TBlackEgg }

TBlackEgg = class(TCommonEggs)
public
  constructor Create;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Shoot;
  procedure StartBossSequence;
end;

implementation

uses u_app, u_common, u_audio, u_screen_gamemermaidboss, Math;

{ TEggShoot }

constructor TEggShoot.Create(aTex: PTexture);
begin
  inherited Create(aTex, False);
  if not FlipH then Angle.AddConstant(360*2)
    else Angle.AddConstant(-360*2);
  CollisionBody.AddCircle(PointF(Width*0.5, Height*0.5), Width*0.5);
  FCheckCollision := True;
end;

procedure TEggShoot.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if not FCheckCollision then exit;

  CollisionBody.SetSurfaceToWordMatrix(GetMatrixSurfaceToWorld);
  if OwnerIsLR then begin
    // check collision with Marcus egg
    FBlackEgg.CollisionBody.SetSurfaceToWordMatrix(FBlackEgg.GetMatrixSurfaceToWorld);
    if CollisionBody.CheckCollisionWith(FBlackEgg) then begin
      if not FBlackEgg.FlipH then begin
        // Marcus is in defense mode -> bullet bounce
        Audio.PlayThenKillSound('metal-hit.ogg', 0.7, 0.5, 1.0);
        Speed.X.Value := -Speed.X.Value;
        if CenterY > FBlackEgg.CenterY then Speed.Y.Value := -Speed.X.Value
          else Speed.Y.Value := Speed.X.Value;
        FCheckCollision := False;
      end else begin
        // inflicts damage to Marcus
        Kill;
        FMarcusProgressBar.Percent := FMarcusProgressBar.Percent - 0.01;
      end;
    end else if X.Value > FScene.Width then Kill;
  end else begin
    // check collision with LR egg
    FRedEgg.CollisionBody.SetSurfaceToWordMatrix(FBlackEgg.GetMatrixSurfaceToWorld);
    if CollisionBody.CheckCollisionWith(FRedEgg) then begin
      if FRedEgg.FlipH then begin
        // LR is in defense mode -> bullet bounce
        Audio.PlayThenKillSound('metal-hit.ogg', 0.7, 0.5, 1.0);
        Speed.X.Value := -Speed.X.Value;
        if CenterY > FRedEgg.CenterY then Speed.Y.Value := -Speed.X.Value
          else Speed.Y.Value := Speed.X.Value;
        FCheckCollision := False;
      end else begin
        // inflicts damage to LR
        Kill;
        FLRLifeProgressBar.Percent := FMarcusProgressBar.Percent - 0.01;
      end;
    end else if X.Value < -Width then Kill;
  end;
end;

{ TCommonEggs }

procedure TCommonEggs.SetState(AValue: TEggState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  case AValue of
    eggsIdleFly: begin
      Angle.ChangeTo(0, 0.5, idcSinusoid);
      PostMessage(0);
    end;
  end;
end;

procedure TCommonEggs.DoShoot(aTex: PTexture);
var o: TEggShoot;
  panValue: single;
begin
  if FTimeBeforeNextShoot > 0 then exit;
  FTimeBeforeNextShoot := 1/8;

  o := TEggShoot.Create(aTex);
  FScene.Add(o, LAYER_ARROW);

  o.OwnerIsLR := FOwnerIsLR;
  if FOwnerIsLR then begin
    panValue := -0.5;
    o.OwnerIsLR := True;
  end else begin
    panValue := 0.5;
    o.OwnerIsLR := False;
  end;
  Audio.PlayThenKillSound('shotgun-shoot-only.ogg', 0.8, panValue);

  FShootSide := not FShootSide;
  o.Speed.x.Value := FScene.Width*2;
  if not FlipH then begin
    if not FShootSide then o.X.Value := X.Value + ScaleW(133)
      else o.X.Value := X.Value + ScaleW(67);
  end else begin
    if not FShootSide then o.X.Value := X.Value - ScaleW(10)
      else o.X.Value := X.Value + ScaleW(56);
    o.Speed.x.Value := -o.Speed.x.Value;
  end;
  o.Y.Value := Y.Value + ScaleH(80);
end;

procedure TCommonEggs.SetFlipH(AValue: boolean);
begin
  inherited SetFlipH(AValue);
  FBG.FlipH := AValue;
  if FDriver <> NIL then FDriver.FlipH := AValue;
end;

procedure TCommonEggs.SetFlipV(AValue: boolean);
begin
  inherited SetFlipV(AValue);
  FBG.FlipV := AValue;
end;

class procedure TCommonEggs.LoadTexture(aAtlas: TAtlas);
var path: string;
begin
  path := FolderSpriteGameMermaidsPort;
  texEggRed := aAtlas.AddFromSVG(path+'EggRed.svg', ScaleW(151), -1);
  texBGRed := aAtlas.AddFromSVG(path+'EggRedBG.svg', ScaleW(47), -1);
  texEggBlack := aAtlas.AddFromSVG(path+'EggBlack.svg', ScaleW(151), -1);
  texBGBlack := aAtlas.AddFromSVG(path+'EggBlackBG.svg', ScaleW(47), -1);
  texRedShoot := aAtlas.AddFromSVG(path+'EggRedShoot.svg', ScaleW(28), -1);
  texBlackShoot := aAtlas.AddFromSVG(path+'EggBlackShoot.svg', ScaleW(28), -1);
end;

constructor TCommonEggs.Create(aTexEgg, aTexBG: Ptexture);
begin
  inherited Create(aTexEgg, False);
  FScene.Add(Self, LAYER_ARROW);

  FOwnerIsLR := aTexEgg = texEggRed;

  FBG := CreateSpriteChild(aTexBG, False, -2);
  FBG.ApplySymmetryWhenFlip := True;
  FBG.SetCoordinate(ScaleW(68), ScaleH(17));

  FAcceleration := PPIScale(48*2);
  FFriction := PPIScale(48);
  if FOwnerIsLR then
    FBounds := Rect(0, 0, Round(FScene.Width*0.4), FScene.Height-Height)
  else
    FBounds := Rect(Round(FScene.Width*0.6), 0, FScene.Width-Width, FScene.Height-Height);

  // Collision body
  CollisionBody.AddPolygon([PointF(ScaleW(54), ScaleH(0)),
      PointF(ScaleW(39), ScaleH(4)), PointF(ScaleW(24), ScaleH(18)),
      PointF(ScaleW(10), ScaleH(46)), PointF(ScaleW(1), ScaleH(81)),
      PointF(ScaleW(0), ScaleH(115)), PointF(ScaleW(3), ScaleH(126)),
      PointF(ScaleW(21), ScaleH(142)), PointF(ScaleW(43), ScaleH(151)),
      PointF(ScaleW(64), ScaleH(154)), PointF(ScaleW(87), ScaleH(153)),
      PointF(ScaleW(109), ScaleH(143)), PointF(ScaleW(125), ScaleH(124)),
      PointF(ScaleW(129), ScaleH(110)), PointF(ScaleW(128), ScaleH(87)),
      PointF(ScaleW(124), ScaleH(57)), PointF(ScaleW(118), ScaleH(41)),
      PointF(ScaleW(108), ScaleH(22)), PointF(ScaleW(94), ScaleH(8)),
      PointF(ScaleW(77), ScaleH(0))]);
end;

procedure TCommonEggs.Update(const aElapsedTime: single);
var v: single;
begin
  inherited Update(aElapsedTime);

  if FTimeBeforeNextShoot > 0 then
    FTimeBeforeNextShoot := FTimeBeforeNextShoot - aElapsedTime;

  // apply friction
  v := Speed.X.Value;
  if v > 0 then v := Max(v - FFriction, 0)
    else if v < 0 then v := Min(v + FFriction, 0);
  Speed.X.Value := v;
  v := Speed.Y.Value;
  if v > 0 then v := Max(v - FFriction, 0)
    else if v < 0 then v := Min(v + FFriction, 0);
  Speed.Y.Value := v;

  // apply bounds
  if FApplyBounds then begin
    if X.Value < FBounds.Left then X.Value := FBounds.Left
      else if X.Value > FBounds.Right then X.Value := FBounds.Right;
    if Y.Value < FBounds.Top then Y.Value := FBounds.Top
      else if Y.Value > FBounds.Bottom then Y.Value := FBounds.Bottom;
  end;
end;

procedure TCommonEggs.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // FLY IDLE
    0: begin
      if State <> eggsIdleFly then exit;
      if Speed.Y.Value = 0 then
        Y.ChangeTo(Y.Value+ScaleH(10), 1.0, idcSinusoid);
      PostMessage(5, 1.0);
    end;
    5: begin
      if State <> eggsIdleFly then exit;
      if Speed.Y.Value = 0 then
        Y.ChangeTo(Y.Value-ScaleH(10), 1.0, idcSinusoid);
      PostMessage(0, 1.0);
    end;
  end;
end;

procedure TCommonEggs.SetDriverAsChild(aCharacter: TCharacterWithDialogPanel);
begin
  FDriver := aCharacter;
  FDriver.SetChildOf(Self, -1);
  FDriver.ApplySymmetryWhenFlip := True;
end;

procedure TCommonEggs.Defend(AValue: boolean);
begin
  if FOwnerIsLR then FlipH := AValue
    else FlipH := not AValue;
end;

procedure TCommonEggs.MoveRight;
begin
  if X.Value < FBounds.Right then Speed.X.Value := Speed.X.Value + FAcceleration;
end;

procedure TCommonEggs.MoveLeft;
begin
  if X.Value > FBounds.Left then Speed.X.Value := Speed.X.Value - FAcceleration;
end;

procedure TCommonEggs.MoveUp;
begin
  if Y.Value > FBounds.Top then Speed.Y.Value := Speed.Y.Value - FAcceleration;
end;

procedure TCommonEggs.MoveDown;
begin
  if Y.Value < FBounds.Bottom then Speed.Y.Value := Speed.Y.Value + FAcceleration;
end;

{ TRedEgg }

constructor TRedEgg.Create;
begin
  inherited Create(texEggRed, texBGRed);
end;

procedure TRedEgg.Shoot;
begin
  DoShoot(texRedShoot);
end;

{ TBlackEgg }

constructor TBlackEgg.Create;
begin
  inherited Create(texEggBlack, texBGBlack);
end;

procedure TBlackEgg.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
  case UserValue of
    // BOSS SEQUENCE
    100: begin

    end;
  end;
end;

procedure TBlackEgg.Shoot;
begin
  DoShoot(texBlackShoot);
end;

procedure TBlackEgg.StartBossSequence;
begin
  PostMessage(100);
end;

end.

