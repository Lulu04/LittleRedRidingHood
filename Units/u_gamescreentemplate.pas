unit u_gamescreentemplate;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene, ALSound,
  u_common, u_ui_panels, u_weather_effects, u_gamebackground;

type

{ TGameScreenTemplate }

TGameScreenTemplate = class(TScreenTemplate)
private
  FFogRightToLeft: TFogRightToLeft;
  FRain: TRain;
  FtexGrassLarge: PTexture;

public // Weather
  procedure CreateFogRightToLeft(aAtlas: TOGLCTextureAtlas; aFillScreen: boolean;
                                 aCrossDuration: single=50.0; aOpacity: single=20);
  procedure StartRain(aAtlas: TOGLCTextureAtlas);

  property FogRightToLeft: TFogRightToLeft read FFogRightToLeft;
  property Rain: TRain read FRain;

public // Background object creation
  procedure AddGrassLargeTextureToAtlas(aAtlas: TOGLCTextureAtlas);
  procedure CreateGrassLarge(aX, aY: single; aLayerindex: integer);

public // modal panels
  // create a modal panel with game instructions. the panel is freed when it is closed.
  procedure ShowGameInstructions(const aText: string);

  // ask a question to the player. The panel is freed when it is closed.
  // NOTE: the aAtlas must have the blue arrow  (call AddBlueArrowToAtlas())
  procedure DialogQuestion(const aText, aYes, aNo: string; aFont: TTexturedFont;
                           aTargetScreen: TScreenTemplate; aYesUserValue, aNoUserValue: TUserMessageValue;
                           aAtlas: TOGLCTextureAtlas);

  procedure ShowGetReadyGo(aMessageValueWhenDone: TUserMessageValue; aDelay: single=0; aCameraInUse: TOGLCCamera=NIL);

public // loading particle texture in atlas
  procedure AddSphereParticleToAtlas(aAtlas: TOGLCTextureAtlas);
  procedure AddCrossParticleToAtlas(aAtlas: TOGLCTextureAtlas);
  procedure AddFlameParticleToAtlas(aAtlas: TOGLCTextureAtlas);
  procedure AddRainDropParticleToAtlas(aAtlas: TOGLCTextureAtlas);
  procedure AddDustParticleToAtlas(aAtlas: TOGLCTextureAtlas);
  procedure AddCloud128x128ParticleToAtlas(aAtlas: TOGLCTextureAtlas);

  // the arrow used to click a button with the keyboard
  procedure AddBlueArrowToAtlas(aAtlas: TOGLCTextureAtlas);

  // Reset all scene callback to NIL. Use in FreeObjects.
  procedure ResetSceneCallbacks;
end;


implementation

uses u_app, u_utils, u_resourcestring;

type

{ TGetReadyGo }

TGetReadyGo = class(TSpriteContainer)
private
  FTargetScreen: TGameScreenTemplate;
  FMess: TUserMessageValue;
  FDelay: single;
  FMess1, FMess2: TSprite;
public
  constructor Create(aTargetScreen: TGameScreenTemplate; aMessageValue: TUserMessageValue; aDelay: single);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

{ TGetReadyGo }

constructor TGetReadyGo.Create(aTargetScreen: TGameScreenTemplate;
  aMessageValue: TUserMessageValue; aDelay: single);
var fd: TFontDescriptor;
begin
  inherited Create(FScene);
  FScene.Add(Self, LAYER_GAMEUI);

  FTargetScreen := aTargetScreen;
  FMess := aMessageValue;
  FDelay := aDelay;

  fd.Create('Arial', Round(FScene.Height*0.1), [], BGRA(255,255,0), BGRA(0,0,0), PPIScale(3));
  FMess1 := TSprite.Create(FScene, fd, sGetReady);
  AddChild(FMess1, 0);
  FMess1.CenterOnParent;

  FMess2 := TSprite.Create(FScene, fd, sGo);
  AddChild(FMess2, 0);
  FMess2.CenterOnParent;
  FMess2.Visible := False;

  PostMessage(0);
end;

procedure TGetReadyGo.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin
      FMess1.KillDefered(2);
      PostMessage(1, 2.5);
    end;
    1: begin
      FMess2.Visible := True;
      FTargetScreen.PostMessage(FMess, FDelay);
      PostMessage(2, 1.0);
    end;
    2: begin
      Kill;
    end;
  end;
end;

{ TGameScreenTemplate }

procedure TGameScreenTemplate.CreateFogRightToLeft(aAtlas: TOGLCTextureAtlas; aFillScreen: boolean;
  aCrossDuration: single; aOpacity: single);
begin
  FFogRightToLeft := TFogRightToLeft.Create(aAtlas, aFillScreen, aCrossDuration, aOpacity);
end;

procedure TGameScreenTemplate.StartRain(aAtlas: TOGLCTextureAtlas);
begin
  FRain := TRain.Create(aAtlas);
end;

procedure TGameScreenTemplate.AddGrassLargeTextureToAtlas(aAtlas: TOGLCTextureAtlas);
begin
  FtexGrassLarge := aAtlas.RetrieveTextureByFileName('GrassLarge.svg');
  if FtexGrassLarge = NIL then
    FtexGrassLarge := aAtlas.AddFromSVG(SpriteBGFolder+'GrassLarge.svg', ScaleW(213), -1);
end;

procedure TGameScreenTemplate.CreateGrassLarge(aX, aY: single; aLayerindex: integer);
begin
  TGrassLarge.Create(FtexGrassLarge, aX, aY, aLayerindex);
end;

procedure TGameScreenTemplate.ShowGameInstructions(const aText: string);
begin
  with TDisplayGameHelp.Create(aText) do ShowModal;
end;

procedure TGameScreenTemplate.DialogQuestion(const aText, aYes, aNo: string; aFont: TTexturedFont;
  aTargetScreen: TScreenTemplate; aYesUserValue, aNoUserValue: TUserMessageValue; aAtlas: TOGLCTextureAtlas);
begin
  with TDialogQuestion.Create(aText, aYes, aNo, aFont, aTargetScreen, aYesUserValue, aNoUserValue, aAtlas) do
    ShowModal;
end;

procedure TGameScreenTemplate.ShowGetReadyGo(
  aMessageValueWhenDone: TUserMessageValue; aDelay: single; aCameraInUse: TOGLCCamera);
begin
  with TGetReadyGo.Create(Self, aMessageValueWhenDone, aDelay) do
    SetCenterCoordinate(GetCenterView(aCameraInUse));
end;

procedure TGameScreenTemplate.AddSphereParticleToAtlas(aAtlas: TOGLCTextureAtlas);
begin
  if aAtlas.RetrieveTextureByFileName('sphere_particle.png') <> NIL then exit;
  if aAtlas.RetrieveTextureByFileName('sphere_particle.svg') <> NIL then exit;
  with aAtlas.AddFromSVG(ParticleFolder+'sphere_particle.svg', PPIScale(32), -1)^ do
   FileName := 'sphere_particle.png';
end;

procedure TGameScreenTemplate.AddCrossParticleToAtlas(aAtlas: TOGLCTextureAtlas);
begin
  if aAtlas.RetrieveTextureByFileName('Cross.png') <> NIL then exit;
  if aAtlas.RetrieveTextureByFileName('Cross.svg') <> NIL then exit;
  with aAtlas.AddFromSVG(ParticleFolder+'Cross.svg', PPIScale(32), -1)^ do
   FileName := 'Cross.png';
end;

procedure TGameScreenTemplate.AddFlameParticleToAtlas(aAtlas: TOGLCTextureAtlas);
begin
  if aAtlas.RetrieveTextureByFileName('Flame.png') <> NIL then exit;
  if aAtlas.RetrieveTextureByFileName('Flame.svg') <> NIL then exit;
  with aAtlas.AddFromSVG(ParticleFolder+'Flame.svg', PPIScale(32), -1)^ do
   FileName := 'Flame.png';
end;

procedure TGameScreenTemplate.AddRainDropParticleToAtlas(aAtlas: TOGLCTextureAtlas);
begin
  if aAtlas.RetrieveTextureByFileName('RainDrop.png') <> NIL then exit;
  if aAtlas.RetrieveTextureByFileName('RainDrop.svg') <> NIL then exit;
  with aAtlas.AddFromSVG(ParticleFolder+'RainDrop.svg', PPIScale(32), -1)^ do
   FileName := 'RainDrop.png';
end;

procedure TGameScreenTemplate.AddDustParticleToAtlas(aAtlas: TOGLCTextureAtlas);
begin
  if aAtlas.RetrieveTextureByFileName('Dust.png') <> NIL then exit;
  aAtlas.AddScaledPPI(ParticleFolder+'Dust.png');
end;

procedure TGameScreenTemplate.AddCloud128x128ParticleToAtlas(aAtlas: TOGLCTextureAtlas);
begin
  if aAtlas.RetrieveTextureByFileName('Cloud128x128.png') <> NIL then exit;
  aAtlas.AddScaledPPI(ParticleFolder+'Cloud128x128.png');
end;

procedure TGameScreenTemplate.AddBlueArrowToAtlas(aAtlas: TOGLCTextureAtlas);
begin
  with aAtlas.AddFromSVG(SpriteUIFolder+'RightBlueArrow.svg', ScaleW(32), -1)^ do
   FileName := '_UItexKeyboardToButton_';
end;

procedure TGameScreenTemplate.ResetSceneCallbacks;
var i: integer;
begin
  FScene.Mouse.OnClickOnScene := NIL;
  FScene.OnBeforePaint := NIL;
  FScene.OnAfterPaint := NIL;
  for i:=0 to FScene.LayerCount-1 do begin
    FScene.Layer[i].OnBeforePaint := NIL;
    FScene.Layer[i].OnAfterPaint := NIL;
    FScene.Layer[i].OnBeforeUpdate := NIL;
    FScene.Layer[i].OnAfterUpdate := NIL;
    FScene.Layer[i].OnSortCompare := NIL;
  end;
end;

end.

