unit u_screen_gamevolcano;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_common_ui, u_audio,
  u_ui_panels, u_sprite_lr4dir, u_sprite_lrcommon;

type

{ TScreenGameVolcano }

TScreenGameVolcano = class(TScreenTemplate)
private type TGameState=(gsUndefined=0, gsIdle,
                         gsLRLost,
                         gsDecodingDigicode);
var FGameState: TGameState;
private

  FInGamePausePanel: TInGamePausePanel;

  FDifficulty: integer;
  procedure ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
  //procedure ProcessCallbackPickUpSomethingWhenBendDown(aPickUpToTheRight: boolean);
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property Difficulty: integer write FDifficulty;
end;

var ScreenGameVolcano: TScreenGameVolcano;

implementation

uses Forms, u_sprite_wolf, u_app, LCLType;


var FAtlas: TOGLCTextureAtlas;
    FFontText: TTexturedFont;
    FLR: TLR4Direction;
{ TScreenGameVolcano }

procedure TScreenGameVolcano.ProcessButtonClick(Sender: TSimpleSurfaceWithEffect);
begin

end;

procedure TScreenGameVolcano.CreateObjects;
var path: string;
  ima: TBGRABitmap;
  o: TSprite;
begin

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 1;

  LoadLR4DirTextures(FAtlas);
  LoadWolfTextures(FAtlas);
  //FAtlas.Add(ParticleFolder+'sphere_particle.png');

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

  // LR 4 direction
  FLR := TLR4Direction.Create;
  FLR.SetCoordinate(FScene.Width*0.5, FScene.Height*0.8);
  FLR.SetWindSpeed(0.5);
  FLR.SetFaceType(lrfSmile);
  FLR.IdleRight;
//  FLR.CallbackPickUpSomethingWhenBendDown := @ProcessCallbackPickUpSomethingWhenBendDown;

end;

procedure TScreenGameVolcano.FreeObjects;
begin
  FScene.ClearAllLayer;
  FreeAndNil(FAtlas);
end;

procedure TScreenGameVolcano.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
end;

procedure TScreenGameVolcano.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  if FScene.KeyState[KeyAction1] then FLR.State := lr4sJumping
  else
  if FScene.KeyState[VK_LEFT] then begin
    FLR.State := lr4sLeftWalking;
  end else
  if FScene.KeyState[VK_RIGHT] then FLR.State := lr4sRightWalking
  else
  if FScene.KeyState[VK_UP] and not FScene.KeyState[VK_SHIFT] then FLR.State := lr4sUpWalking
  else
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

