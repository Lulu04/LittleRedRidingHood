unit u_lr4_usable_object;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes,
  u_sprite_lr4dir, u_sprite_def;

type


{ TUsableObjectSprite }
// describe an object that blink when LR is near and can be actionned by her
TUsableObjectSprite = class(TSprite)
private
  FLR: TLR4Direction;
  FEnabled: boolean;
  FWidthThresholdCoef: single;
  sceBlink: TIDScenario;
  procedure SetEnabled(AValue: boolean);
protected
  procedure StartBlinkScenario; virtual;
  procedure StopBlinkScenario; virtual;
public
  // object is disabled  if aLR4DirInstance = NIL
  constructor Create(aLR4DirInstance: TLR4Direction; aTexture: PTexture; Owner: boolean=False);
  procedure Update(const aElapsedTime: single); override;
  // enable/disable LR interaction on this object
  property Enabled: boolean read FEnabled write SetEnabled;
  // the width proportion to detect if LR can interact with the object
  property WidthThresholdCoef: single read FWidthThresholdCoef write FWidthThresholdCoef;
end;


TObjectInCrateID = (oicIDNone, oicIDKey, oicIDSDCard, oicIDPropulsor);

{ TUsableCrateThatContainObject }

TUsableCrateThatContainObject = class(TUsableObjectSprite)
private class var texCrate, texLockedSymbol: PTexture;
  class var FAtlas: TOGLCTextureAtlas;
private
  FContentID: TObjectInCrateID;
  FIsLocked: boolean;
  sceLockedSymbolBlink: TIDScenario;
  FLockedSymbol: TSprite;
  FPEMagic: TParticleEmitter;
protected
  procedure StartBlinkScenario; override;
  procedure StopBlinkScenario; override;
public
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas);
  constructor Create(aX, aBottomY: single; aLayerIndex: integer; aIsLocked: boolean; aLR4DirInstance: TLR4Direction);
  procedure RemoveLock;
  property IsLocked: boolean read FIsLocked write FIsLocked;
  property ContentID: TObjectInCrateID read FContentID write FContentID;
end;

{ TUsableComputer }

TUsableComputer = class(TUsableObjectSprite)
private class var texBody: PTexture;
private type TComputerState = (csUndefined, csIdle, csCountingRobot, csRedFlash);
procedure SetState(AValue: TComputerState);
private
  FScreen: TUITextArea;
  FState: TComputerState;
  FRobotConstructor: TLittleRobotConstructor;
  FRobotCount: integer;
  procedure IncRobotCount;
  property State: TComputerState read FState write SetState;
public
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas);
  constructor Create(aX, aBottomY: single; aLayerIndex: integer; aFont: TTexturedFont; aLR4DirInstance: TLR4Direction);
  procedure Update(const aElapsedTime: single); override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure SetText(const aText: string);
  procedure SetScreenColor(aColor: TBGRAPixel);
  procedure SetFontColor(aColor: TBGRAPixel);

  procedure Idle;
  procedure StartCountingRobot(aCurrentRobotCount: integer; aRobotConstructor: TLittleRobotConstructor);
  procedure StartScreenFlashRed;
end;


implementation
uses u_common_ui, u_app, u_common;

{ TUsableCrateThatContainObject }

procedure TUsableCrateThatContainObject.StartBlinkScenario;
begin
  if not ScenarioIsPlaying(sceBlink) then begin
    PlayScenario(sceBlink, True);
    if FLockedSymbol <> NIL then
      FLockedSymbol.PlayScenario(sceLockedSymbolBlink, True);
  end;
end;

procedure TUsableCrateThatContainObject.StopBlinkScenario;
begin
  StopAllScenario;
  Tint.Alpha.ChangeTo(0, 0.7);
  if FLockedSymbol <> NIL then begin
    FLockedSymbol.StopAllScenario;
    FLockedSymbol.Tint.Alpha.ChangeTo(0, 0.7);
  end;
end;

class procedure TUsableCrateThatContainObject.LoadTexture(aAtlas: TOGLCTextureAtlas);
begin
  FAtlas := aAtlas;
  texCrate := aAtlas.AddFromSVG(SpriteGameVolcanoInnerFolder+'CrateEmpty.svg', ScaleW(65), -1);
  texLockedSymbol := aAtlas.AddFromSVG(SpriteGameVolcanoInnerFolder+'CrateLockedSymbol.svg', ScaleW(15), -1);
end;

constructor TUsableCrateThatContainObject.Create(aX, aBottomY: single;
  aLayerIndex: integer; aIsLocked: boolean; aLR4DirInstance: TLR4Direction);
begin
  inherited Create(aLR4DirInstance, texCrate, False);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  SetCoordinate(aX, aBottomY-texCrate^.FrameHeight);

  if aIsLocked then begin
    FLockedSymbol := TSprite.Create(texLockedSymbol, False);
    AddChild(FLockedSymbol, 0);
    FLockedSymbol.CenterOnParent;
    sceLockedSymbolBlink := FLockedSymbol.AddScenario(ScenarioYellowBlink);

    FPEMagic := TParticleEmitter.Create(FScene);
    AddChild(FPEMagic, 1);
    FPEMagic.LoadFromFile(ParticleFolder+'MagicOnCrate.par', FAtlas);
    FPEMagic.CenterX := Width*0.5;
    FPEMagic.Y.Value := 0; //-Height*0.5;
    FPEMagic.Opacity.Value := 128;
  end;

  FIsLocked := aIsLocked;
end;

procedure TUsableCrateThatContainObject.RemoveLock;
begin
  FLockedSymbol.KillDefered(1.0);
  FLockedSymbol.Opacity.ChangeTo(0, 1.0);
  FLockedSymbol := NIL;
  FPEMagic.Opacity.ChangeTo(0, 1.0);
  FPEMagic.KillDefered(1.0);
end;

{ TUsableComputer }

procedure TUsableComputer.SetState(AValue: TComputerState);
begin
  if FState = AValue then Exit;
  FState := AValue;

  case AValue of
    csIdle: begin
      SetScreenColor(BGRA(153,219,254));
      SetFontColor(BGRA(0,0,0));
      SetText('WinWolf 3.1');
    end;
    csCountingRobot:;
    csRedFlash: PostMessage(0);
  end;
end;

procedure TUsableComputer.IncRobotCount;
begin
  inc(FRobotCount);
  SetText('WinWolf 3.1'+LineEnding+FRobotCount.ToString);
end;

class procedure TUsableComputer.LoadTexture(aAtlas: TOGLCTextureAtlas);
begin
  texBody := aAtlas.RetrieveTextureByFileName('ComputerBody.svg');
  if texBody = NIL then
    texBody := aAtlas.AddFromSVG(SpriteGameVolcanoInnerFolder+'ComputerBody.svg', ScaleW(148), -1);
end;

constructor TUsableComputer.Create(aX, aBottomY: single; aLayerIndex: integer;
  aFont: TTexturedFont; aLR4DirInstance: TLR4Direction);
begin
  inherited Create(aLR4DirInstance, texBody, False);
  if aLayerIndex <> -1 then FScene.Add(Self, aLayerIndex);
  X.Value := aX;
  BottomY := aBottomY;
  WidthThresholdCoef := 0.5;

  FScreen := TUITextArea.Create(FScene);
  FScreen.BodyShape.SetShapeRoundRect(Round(Width*0.899), Round(Height*1.29), PPIScale(10), PPIScale(10), 1.0);
  FScreen.BodyShape.Border.Width := 4.0;
  FScreen.BodyShape.Border.Color := BGRA(0,75,128);
  FScreen.Text.TexturedFont := aFont;
  FScreen.Text.Align := taCenterCenter;
  State := csIdle;
  AddChild(FScreen, 0);
  FScreen.X.Value := 0;
  FScreen.BottomY := 0;
end;

procedure TUsableComputer.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  // check if a robot is constructed
  if (FState = csCountingRobot) and (FRobotConstructor <> NIL) then
    if FRobotConstructor.RobotConstructed then
      IncRobotCount;
end;

procedure TUsableComputer.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // screen flash red (alert)
    0: begin
      if FState <> csRedFlash then exit;
      FScreen.BodyShape.Fill.Color := BGRA(255,50,25);
      PostMessage(1, 0.5);
    end;
    1: begin
      if FState <> csRedFlash then exit;
      FScreen.BodyShape.Fill.Color := BGRA(128,25,12);
      PostMessage(0, 0.5);
    end;
  end;
end;

procedure TUsableComputer.SetText(const aText: string);
begin
  FScreen.Text.Caption := aText;
end;

procedure TUsableComputer.SetScreenColor(aColor: TBGRAPixel);
begin
  FScreen.BodyShape.Fill.Color := aColor;
end;

procedure TUsableComputer.SetFontColor(aColor: TBGRAPixel);
begin
  FScreen.Text.Tint.Value := aColor;
end;

procedure TUsableComputer.Idle;
begin
   State := csIdle;
end;

procedure TUsableComputer.StartCountingRobot(aCurrentRobotCount: integer;
  aRobotConstructor: TLittleRobotConstructor);
begin
  FState := csCountingRobot;
  FRobotConstructor := aRobotConstructor;
  FRobotCount := aCurrentRobotCount-1;
  IncRobotCount;
end;

procedure TUsableComputer.StartScreenFlashRed;
begin
  State := csRedFlash;
end;

{ TUsableObjectSprite }

procedure TUsableObjectSprite.SetEnabled(AValue: boolean);
begin
  if FEnabled = AValue then Exit;
  FEnabled := AValue;
  if not AValue then StopBlinkScenario;
end;

procedure TUsableObjectSprite.StartBlinkScenario;
begin
  if not ScenarioIsPlaying(sceBlink) then begin
    PlayScenario(sceBlink, True);
  end;
end;

procedure TUsableObjectSprite.StopBlinkScenario;
begin
  StopAllScenario;
  Tint.Alpha.ChangeTo(0, 0.7);
end;

constructor TUsableObjectSprite.Create(aLR4DirInstance: TLR4Direction; aTexture: PTexture; Owner: boolean);
begin
  inherited Create(aTexture, Owner);
  sceBlink := AddScenario(ScenarioYellowBlink);
  FLR := aLR4DirInstance;
  FEnabled := aLR4DirInstance <> NIL;
  FWidthThresholdCoef := 1.5;
end;

procedure TUsableObjectSprite.Update(const aElapsedTime: single);
var d: Single;
begin
  inherited Update(aElapsedTime);

  // check if LR is near the crate
  if not FEnabled then exit;

  d := Distance(Center, FLR.GetXY);
  if (d < Width*FWidthThresholdCoef) and (d < FLR.DistanceToObjectToHandle) then begin
    StartBlinkScenario;
    FLR.ObjectToHandle := Self;
    FLR.DistanceToObjectToHandle := d;
  end else begin
    StopBlinkScenario;
  end;
end;

end.

