unit u_screen_gamemermaidsport;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon, u_sprite_def;

type

{ TScreenMermaidsPort }

TScreenMermaidsPort = class(TGameScreenTemplate)
private type TGameState=(gsUndefined,
                         gsRunning);
var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FInGamePausePanel: TInGamePausePanel;
  procedure ResetVariables;
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenMermaidsPort: TScreenMermaidsPort;

implementation

uses Forms, u_screen_map, u_app, u_utils, Math;

var
  FAtlas: TAtlas;
  FFontText: TTexturedFont;


{ TScreenMermaidsPort }

procedure TScreenMermaidsPort.SetGameState(AValue: TGameState);
begin

end;

procedure TScreenMermaidsPort.ResetVariables;
begin

end;

procedure TScreenMermaidsPort.CreateObjects;
var path: string;
  ima: TBGRABitmap;
begin
  FGameState := gsUndefined;
  ResetVariables;

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  path := FolderSpritePlainOfSleepingMoonInside;

  // ui
  CreateGameFontNumber(FAtlas); // < must be first !
  LoadWatchTexture(FAtlas);
  LoadLaserGunTexture(FAtlas);
  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);
  LoadGameDialogTextures(FAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;

  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  // pause panel
  FInGamePausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

end;

procedure TScreenMermaidsPort.FreeObjects;
begin
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
end;

procedure TScreenMermaidsPort.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
end;

procedure TScreenMermaidsPort.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);

  // check if player pause the game
  if Input.PausePressed then
    FInGamePausePanel.ShowModal;
end;

end.

