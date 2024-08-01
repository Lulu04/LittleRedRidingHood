unit u_screen_gamevolcanoinner;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_common_ui, u_audio,
  u_ui_panels, u_sprite_lr4dir, u_sprite_lrcommon;

type

{ TScreenGameVolcanoInner }

TScreenGameVolcanoInner = class(TScreenTemplate)
private type TGameState=(gsUndefined=0, gsIdle,
                         gsLRLost,
                         gsDecodingDigicode);
var FGameState: TGameState;
private

  FInGamePausePanel: TInGamePausePanel;

  FDifficulty: integer;
  procedure CreateCavePillars;
  procedure CreateLevel;
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
  //procedure ProcessCallbackPickUpSomethingWhenBendDown(aPickUpToTheRight: boolean);
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property Difficulty: integer write FDifficulty;
end;

var ScreenGameVolcanoInner: TScreenGameVolcanoInner;

implementation

uses Forms, u_sprite_wolf, u_app, LCLType;


var FAtlas: TOGLCTextureAtlas;
    texPillar1, texPillar2, texBGGround,
    texGroundLarge, texGroundMedium, texGroundLeft, texGroundRight: PTexture;
    FFontText: TTexturedFont;
    FLR: TLR4Direction;
    FPillars: array[0..5] of TSprite;

{ TScreenGameVolcanoInner }

procedure TScreenGameVolcanoInner.CreateCavePillars;
var
  xx: Integer;
  o: TSprite;
begin
  FPillars[0] := TSprite.Create(texPillar1, False);
  FScene.Add(FPillars[0], LAYER_BG1);
  FPillars[0].Scale.Value := PointF(1.0, 1.5);
  FPillars[0].ScaledX := 0;
  FPillars[0].ScaledY := 0;
  //FPillars[0].SetCoordinate(0, (FScene.Height-FPillars[0].Height)*0.5);

  FPillars[1] := TSprite.Create(texPillar2, False);
  FScene.Add(FPillars[1], LAYER_BG1);
  FPillars[1].Scale.Value := PointF(1.0, 1.5);
  FPillars[1].ScaledX := ScaleW(529);
  FPillars[1].ScaledY := 0;
  //FPillars[1].SetCoordinate(ScaleW(529), (FScene.Height-FPillars[1].Height)*0.5);

  FPillars[2] := TSprite.Create(texPillar1, False);
  FScene.Insert(0, FPillars[2], LAYER_BG1);
  FPillars[2].Scale.Value := PointF(1.0, 0.8);
  //FPillars[2].TintMode := tmMixColor;
  FPillars[2].Tint.Value := BGRA(0,0,0,80);
  FPillars[2].SetCoordinate(ScaleW(248), (FScene.Height-FPillars[2].Height)*0.5);

  FPillars[3] := TSprite.Create(texPillar2, False);
  FScene.Insert(0, FPillars[3], LAYER_BG1);
  FPillars[3].Scale.Value := PointF(1.0, 0.8);
  //FPillars[3].TintMode := tmMixColor;
  FPillars[3].Tint.Value := BGRA(0,0,0,80);
  FPillars[3].SetCoordinate(ScaleW(807), (FScene.Height-FPillars[3].Height)*0.5);

  FPillars[4] := TSprite.Create(texPillar1, False);
  FScene.Insert(0, FPillars[4], LAYER_BG1);
  FPillars[4].Scale.Value := PointF(1.0, 0.6);
  //FPillars[4].TintMode := tmMixColor;
  FPillars[4].Tint.Value := BGRA(0,0,0,150);
  FPillars[4].SetCoordinate(ScaleW(392), (FScene.Height-FPillars[4].Height)*0.5);

  FPillars[5] := TSprite.Create(texPillar2, False);
  FScene.Insert(0, FPillars[5], LAYER_BG1);
  FPillars[5].Scale.Value := PointF(1.0, 0.6);
  //FPillars[5].TintMode := tmMixColor;
  FPillars[5].Tint.Value := BGRA(0,0,0,150);
  FPillars[5].SetCoordinate(ScaleW(701), (FScene.Height-FPillars[5].Height)*0.5);

  xx := -texBGGround^.FrameWidth;
  while xx < FScene.Width+texBGGround^.FrameWidth do begin
    o := TSprite.Create(texBGGround, False);
    FScene.Add(o, LAYER_BG2);
    o.SetCoordinate(xx, 0);
    o.Tag1 := 1;

    o := TSprite.Create(texBGGround, False);
    FScene.Add(o, LAYER_BG2);
    o.SetCoordinate(xx, FScene.Height-o.Height);
    o.Tag1 := 1;
    o.FlipV := True;

    xx := xx + texBGGround^.FrameWidth-2;
  end;

end;

procedure TScreenGameVolcanoInner.CreateLevel;
begin

end;

procedure TScreenGameVolcanoInner.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin

end;

procedure TScreenGameVolcanoInner.CreateObjects;
var path: string;
  ima: TBGRABitmap;
  o: TSprite;
begin
  Audio.PauseMusicTitleMap(3.0);

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 1;

  AdditionnalScale := 0.8;

  LoadLR4DirTextures(FAtlas);
  LoadWolfTextures(FAtlas);
  //FAtlas.Add(ParticleFolder+'sphere_particle.png');

  AdditionnalScale := 1.0;
  path := SpriteGameVolcanoInnerFolder;
  texPillar1 := FAtlas.AddFromSVG(path+'Pillar1.svg', -1, FScene.Height div 2); //ScaleH(714));
  texPillar2 := FAtlas.AddFromSVG(path+'Pillar2.svg', -1, FScene.Height div 2); //ScaleH(714));
  texBGGround := FAtlas.AddFromSVG(path+'BGGround.svg', ScaleH(310), -1);
  texGroundLarge := FAtlas.AddFromSVG(path+'GroundLarge.svg', ScaleH(167), -1);
  texGroundMedium := FAtlas.AddFromSVG(path+'GroundMedium.svg', ScaleH(83), -1);
  texGroundLeft := FAtlas.AddFromSVG(path+'GroundLeft.svg', ScaleH(22), -1);
  texGroundRight := FAtlas.AddFromSVG(path+'GroundRight.svg', ScaleH(25), -1);



  CreateGameFontNumber(FAtlas);
  LoadCoinTexture(FAtlas);
  LoadWatchTexture(FAtlas);
  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);
  LoadGameDialogTextures(FAtlas);

  path := SpriteGameVolcanoEntranceFolder;

  //TPanelDecodingDigicode.LoadTextures(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;
  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  // cave pillars
  CreateCavePillars;

  // ground level
  CreateLevel;

  // LR 4 direction
  FLR := TLR4Direction.Create;
  FLR.SetCoordinate(FScene.Width*0.5, FScene.Height*0.8);
  FLR.SetWindSpeed(0.5);
  FLR.SetFaceType(lrfSmile);
  FLR.IdleRight;
//  FLR.CallbackPickUpSomethingWhenBendDown := @ProcessCallbackPickUpSomethingWhenBendDown;

  // show how to play
  with TDisplayGameHelp.Create(PlayerInfo.Volcano.HelpText, FFontText) do ShowModal;
end;

procedure TScreenGameVolcanoInner.FreeObjects;
begin
  FScene.ClearAllLayer;
  FreeAndNil(FAtlas);
end;

procedure TScreenGameVolcanoInner.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
end;

procedure TScreenGameVolcanoInner.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if FScene.KeyState[KeyAction1] then FLR.State := lr4sJumping
  else
  if FScene.KeyState[VK_LEFT] then begin
    FLR.State := lr4sLeftWalking;
  end else
  if FScene.KeyState[VK_RIGHT] then begin
    FLR.State := lr4sRightWalking;
  end else
  if FScene.KeyState[VK_UP] and not FScene.KeyState[VK_SHIFT] then begin
    FLR.State := lr4sUpWalking
  end else
  if FScene.KeyState[VK_DOWN] and not FScene.KeyState[VK_SHIFT] then FLR.State := lr4sDownWalking
  else
  if FScene.KeyState[VK_P] then FLR.State := lr4sOnLadderUp
  else
  if FScene.KeyState[VK_O] then
    FLR.State := lr4sOnLadderDown
  else
  if FScene.KeyState[KeyAction2] then FLR.State := lr4sBendDown
  else FLR.SetIdlePosition;

end;

end.

