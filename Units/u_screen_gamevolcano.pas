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

uses Forms, u_sprite_wolf, u_app;


var FAtlas: TOGLCTextureAtlas;
    FFontText: TTexturedFont;

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
end;

end.

