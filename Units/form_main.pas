unit form_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, Buttons, ExtCtrls, StdCtrls,
  OpenGLContext, OGLCScene,
  u_common;

type

  { TFormMain }

  TFormMain = class(TForm)
    Memo1: TMemo;
    OpenGLControl1: TOpenGLControl;
    Panel1: TPanel;
    Timer1: TTimer;
    procedure FormCloseQuery(Sender: TObject; var {%H-}CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure LoadCommonData;
    procedure FreeCommonData;
    procedure ProcessApplicationIdle(Sender: TObject; var Done: Boolean);
    procedure ProcessLogCallback(const s: string);
  public
  end;

var
  FormMain: TFormMain;

implementation
uses u_screen_title, u_screen_gameforest, BGRABitmap, BGRABitmapTypes,
  screen_logo, u_app, u_screen_map, u_screen_workshop, u_audio,
  u_screen_gamemountainpeaks, u_screen_gamevolcanoentrance,
  u_screen_gamevolcanoinner, u_resourcestring, u_screen_gamevolcanodino,
  DefaultTranslator, LCLTranslator, i18_utils;
{$R *.lfm}

{ TFormMain }

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FScene := TOGLCScene.Create(OpenGLControl1, 4/3);
  FScene.DesignPPI := 96;
  FScene.LayerCount := LAYER_COUNT;
  FScene.ScreenFadeTime := 0.5;

  FScene.OnLoadCommonData := @LoadCommonData;
  FScene.OnFreeCommonData := @FreeCommonData;

  Application.OnIdle := @ProcessApplicationIdle;

  AppLang.RegisterLanguagesSupportedByApp(SupportedLanguages);
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FScene.Free;
  FScene := NIL;
end;

procedure TFormMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  Timer1.Enabled := FALSE;
end;

procedure TFormMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  FScene.ProcessOnKeyDown(Key, Shift);
end;

procedure TFormMain.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  FScene.ProcessOnKeyUp(Key, Shift);
end;

procedure TFormMain.Timer1Timer(Sender: TObject);
begin
  Caption := Format('scene %dx%d %d FPS %d max texture size  %d objects', [FScene.Width, FScene.Height, FScene.FPS, FScene.TexMan.MaxTextureWidth, FScene.SurfaceCount]);
end;

procedure TFormMain.LoadCommonData;
begin
  FSaveGame := TSaveGame.Create;
  FSaveGame.Load;
  if FSaveGame.FolderCreated then FScene.CreateLogFile(FSaveGame.SaveFolder+'scene.log', True, @ProcessLogCallback, NIL);

  Audio := TAudioManager.Create;
  if Audio.PlaybackContext.Error then
    ShowMessage('Audio not initialized... no sound...');
  Audio.StartMusicTitleMap;

  ScreenLogo := TScreenLogo.Create;
  ScreenTitle := TScreenTitle.Create;
  ScreenGameForest := TScreenGame1.Create;
  ScreenGameZipLine := TScreenGameZipLine.Create;
  ScreenGameVolcanoEntrance := TScreenGameVolcanoEntrance.Create;
  ScreenGameVolcanoInner := TScreenGameVolcanoInner.Create;
  ScreenGameVolcanoDino := TScreenGameVolcanoDino.Create;
  ScreenMap := TScreenMap.Create;
  ScreenWorkShop := TScreenWorkShop.Create;
//  FScene.RunScreen(ScreenLogo);

FSaveGame.SetCurrentPlayerIndex(0);
FScene.RunScreen(ScreenMap); // ScreenLogo ScreenTitle  ScreenGameForest ScreenMap  ScreenGameZipLine
end;

procedure TFormMain.FreeCommonData;
begin
  FreeAndNil(FSaveGame);
  FreeAndNil(ScreenTitle);
  FreeAndNil(ScreenMap);
  FreeAndNil(ScreenWorkShop);
  FreeAndNil(ScreenGameForest);
  FreeAndNil(ScreenGameZipLine);
  FreeAndNil(ScreenGameVolcanoEntrance);
  FreeAndNil(ScreenGameVolcanoInner);
  FreeAndNil(ScreenGameVolcanoDino);
  FreeAndNil(ScreenLogo);
  FreeAndNil(Audio);
end;

procedure TFormMain.ProcessApplicationIdle(Sender: TObject; var Done: Boolean);
begin
  FScene.DoLoop;
  Done := FALSE;
end;

procedure TFormMain.ProcessLogCallback(const s: string);
begin
  Memo1.Lines.Add(s);
end;


end.

