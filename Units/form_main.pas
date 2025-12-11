unit form_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, Buttons, ExtCtrls,
  OpenGLContext, OGLCScene,
  u_common, LCLType;

type

  { TFormMain }

  TFormMain = class(TForm)
    OpenGLControl1: TOpenGLControl;
    Timer1: TTimer;
    procedure FormCloseQuery(Sender: TObject; var {%H-}CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormUTF8KeyPress(Sender: TObject; var UTF8Key: TUTF8Char);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure LoadCommonData;
    procedure FreeCommonData;
    procedure ProcessApplicationIdle(Sender: TObject; var Done: Boolean);
  public
  end;

var
  FormMain: TFormMain;

implementation
uses u_screen_title, u_screen_gameforest, BGRABitmap, BGRABitmapTypes,
  screen_logo, u_app, u_screen_map, u_screen_workshop, u_audio,
  u_screen_gamemountainpeaks, u_screen_gamevolcanoentrance,
  u_screen_gamevolcanoinner, u_resourcestring, u_screen_gamevolcanodino,
  u_screen_intro, screen_gameplainmoon, screen_gameplainmooninside,
  u_screen_gamemermaidsport, u_screen_sam, u_screen_strikeraccoon,
  u_screen_dartboard, u_screen_gamemermaidboss, u_screen_gamesnakefissureintro,
  u_screen_gamesnakefissure, u_screen_gamecastle, u_screen_msmainbridge,
  u_screen_msconstruction, u_screen_msharvesting, u_screen_msmeteorstorm,
  u_screen_finaltemple, DefaultTranslator, LCLTranslator, i18_utils;
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

procedure TFormMain.FormUTF8KeyPress(Sender: TObject; var UTF8Key: TUTF8Char);
begin
  FScene.ProcessOnUTF8KeyPress(UTF8Key);
end;

procedure TFormMain.Timer1Timer(Sender: TObject);
begin
  if (Audio <> NIL) and (FScene <> NIL) then
  Caption := Format('scene:%dx%d  FPS:%d  max texture size:%d   objects count:%d  FreeVRam:%d Kb  sounds: %d', [FScene.Width, FScene.Height, FScene.FPS, FScene.TexMan.MaxTextureWidth, FScene.SurfaceCount, FScene.Gpu.FreeVideoRamKb, Audio.PlaybackContext.SoundCount]);
end;

procedure TFormMain.LoadCommonData;
begin
  FSaveGame := TSaveGame.Create;
  if FSaveGame.FolderCreated then
    FScene.CreateLogFile(FSaveGame.SaveFolder+'scene.log', True, NIL, NIL);
  FSaveGame.Load;

  Audio := TAudioManager.Create;
  if Audio.PlaybackContext.Error then
    ShowMessage('Audio not initialized... no sound...');
  Audio.StartMusicTitleMap;

  ScreenLogo := TScreenLogo.Create;
  ScreenTitle := TScreenTitle.Create;
  ScreenIntro := TScreenIntroCinematic.Create;
  ScreenGameForest := TScreenGame1.Create;
  ScreenGameZipLine := TScreenGameZipLine.Create;
  ScreenGameVolcanoEntrance := TScreenGameVolcanoEntrance.Create;
  ScreenGameVolcanoInner := TScreenGameVolcanoInner.Create;
  ScreenGameVolcanoDino := TScreenGameVolcanoDino.Create;
  ScreenPlainOfSleepingMoon := TScreenPlainOfSleepingMoon.Create;
  ScreenPlainMoonInside := TScreenPlainMoonInside.Create;
  ScreenMermaidsPort := TScreenMermaidsPort.Create;
  ScreenMermaidsBoss := TScreenMermaidsBoss.Create;
  ScreenSnakeFissureIntro := TScreenSnakeFissureIntro.Create;
  ScreenSnakeFissure := TScreenSnakeFissure.Create;
  ScreenWolfCastle := TScreenWolfCastle.Create;
  ScreenMap := TScreenMap.Create;
  ScreenWorkShop := TScreenWorkShop.Create;
  ScreenSamHome := TScreenSamHome.Create;
  ScreenStrikeRaccoon := TScreenStrikeRaccoon.Create;
  ScreenDartboard := TScreenDartboard.Create;
  ScreenMotherShipMainBridge := TScreenMotherShipMainBridge.Create;
  ScreenMotherShipConstruction := TScreenMotherShipConstruction.Create;
  ScreenHarvestingInSpace := TScreenHarvestingInSpace.Create;
  ScreenMeteorStorm := TScreenMeteorStorm.Create;
  ScreenFinalTemple := TScreenFinalTemple.Create;
//  FScene.RunScreen(ScreenLogo);


  FSaveGame.SetCurrentPlayerIndex(0);
  FScene.RunScreen(ScreenFinalTemple);     //ScreenMap  ScreenIntro
  Timer1.Enabled := True;

end;

procedure TFormMain.FreeCommonData;
begin
  FreeAndNil(FSaveGame);
  FreeAndNil(ScreenTitle);
  FreeAndNil(ScreenIntro);
  FreeAndNil(ScreenMap);
  FreeAndNil(ScreenWorkShop);
  FreeAndNil(ScreenSamHome);
  FreeAndNil(ScreenStrikeRaccoon);
  FreeAndNil(ScreenDartboard);
  FreeAndNil(ScreenGameForest);
  FreeAndNil(ScreenGameZipLine);
  FreeAndNil(ScreenGameVolcanoEntrance);
  FreeAndNil(ScreenGameVolcanoInner);
  FreeAndNil(ScreenGameVolcanoDino);
  FreeAndNil(ScreenPlainOfSleepingMoon);
  FreeAndNil(ScreenPlainMoonInside);
  FreeAndnil(ScreenMermaidsPort);
  FreeAndNil(ScreenMermaidsBoss);
  FreeAndNil(ScreenSnakeFissureIntro);
  FreeAndNil(ScreenSnakeFissure);
  FreeAndNil(ScreenWolfCastle);
  FreeAndNil(ScreenMotherShipMainBridge);
  FreeAndNil(ScreenMotherShipConstruction);
  FreeAndNil(ScreenHarvestingInSpace);
  FreeAndNil(ScreenMeteorStorm);
  FreeAndNil(ScreenFinalTemple);
  FreeAndNil(ScreenLogo);
  FreeAndNil(Audio);
end;

procedure TFormMain.ProcessApplicationIdle(Sender: TObject; var Done: Boolean);
begin
  FScene.DoLoop;
  Done := FALSE;
end;


end.

