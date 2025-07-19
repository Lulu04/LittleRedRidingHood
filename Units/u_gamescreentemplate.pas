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
  FGameInstructions: string;
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
  procedure ShowGameInstructions;
  procedure SetGameInstructions(const aText: string);

  // ask a question to the player. The panel is freed when it is closed.
  // NOTE: the aAtlas must have the blue arrow  (call AddBlueArrowToAtlas())
  procedure DialogQuestion(const aText, aYes, aNo: string; aFont: TTexturedFont;
                           aTargetScreen: TScreenTemplate; aYesUserValue, aNoUserValue: TUserMessageValue;
                           aAtlas: TOGLCTextureAtlas);

  procedure ShowGetReadyGo(aMessageValueWhenDone: TUserMessageValue; aDelay: single=0; aCameraInUse: TOGLCCamera=NIL);

  // this function create a sprite on LAYER_TOP with a text and center it on the scene
  function SpriteMessage(const aText: string): TSprite;

public // loading particle texture in atlas
  procedure AddSphereParticleToAtlas(aAtlas: TOGLCTextureAtlas);
  procedure AddCrossParticleToAtlas(aAtlas: TOGLCTextureAtlas);
  procedure AddFlameParticleToAtlas(aAtlas: TOGLCTextureAtlas);
  procedure AddRainDropParticleToAtlas(aAtlas: TOGLCTextureAtlas);
  procedure AddDustParticleToAtlas(aAtlas: TOGLCTextureAtlas);
  procedure AddBubbleParticleToAtlas(aAtlas: TOGLCTextureAtlas);
  procedure AddBubbleLessTransparentParticleToAtlas(aAtlas: TOGLCTextureAtlas);
  procedure AddCloud128x128ParticleToAtlas(aAtlas: TOGLCTextureAtlas);

  // the arrow used to click a button with the keyboard
  procedure AddBlueArrowToAtlas(aAtlas: TOGLCTextureAtlas);

public // trophy
  procedure PlaySequenceWinTrophy(const aTexTrophyFilename: string; aAtlas: TAtlas;
                                  aMessageValueWhenDone: TUserMessageValue; aDelay: single);

public // atlas creation or loading
  procedure DefineSubTextures(aAtlas: TAtlas); virtual; abstract;
  procedure CheckAtlas(var aAtlas: TAtlas; const aFilenameWithoutPath: string);
  function GetLoadingMessageSprite: TSprite; override;

  // Reset all scene callback to NIL. Use in FreeObjects.
  procedure ResetSceneCallbacks;
end;


implementation

uses Forms, Graphics, u_app, u_utils, u_resourcestring, u_audio,
  u_sprite_lrcommon;

type

{ TWinTrophySequence }

TWinTrophySequence = class(TUIModalPanel) //(TSpriteContainer)
private
  FTargetScreen: TGameScreenTemplate;
  FMess: TUserMessageValue;
  FDelay: single;
  FTrophy: TSprite;
public
  constructor Create(const aTexTrophyFilename: string; aAtlas: TAtlas;
    aTargetScreen: TGameScreenTemplate; aMessageValue: TUserMessageValue;
  aDelay: single);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
end;

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

{ TWinTrophySequence }

constructor TWinTrophySequence.Create(const aTexTrophyFilename: string; aAtlas: TAtlas;
  aTargetScreen: TGameScreenTemplate; aMessageValue: TUserMessageValue;
  aDelay: single);
var pe: TParticleEmitter;
  lab: TSprite;
  fd: TFontDescriptor;
  tex: PTexture;
begin
  inherited Create(FScene);
  //FScene.Add(Self, LAYER_TOP);
  BodyShape.SetShapeRectangle(FScene.Width, FScene.Height, 0);
  BodyShape.Fill.Visible := False;
  BodyShape.Border.Visible := False;
  ChildClippingEnabled := False;
  MouseInteractionEnabled := False;

  FTargetScreen := aTargetScreen;
  FMess := aMessageValue;
  FDelay := aDelay;

  fd.Create('Arial', FScene.Height div 5, [fsBold], BGRA(255,255,50), BGRA(0,0,0), PPIScale(4));
  fd.ComputeMaxHeightFor(sYouveWon, Rect(0,0,FScene.Width, FScene.Height div 5));
  lab := TSprite.Create(FScene, fd, sYouveWon);
  AddChild(lab, 0);
  lab.CenterX := FScene.Width*0.5;
  lab.Y.Value := FScene.Height div 5;

  tex := FScene.TexMan.AddFromSVG(FolderSpriteTrophy+aTexTrophyFilename, -1, FScene.Height div 5*3);
  FTrophy := TSprite.Create(tex, True);
  AddChild(FTrophy, 0);
  FTrophy.CenterX := FScene.Width*0.5;
  FTrophy.Y.Value := lab.BottomY;
  FTrophy.Scale.Value := PointF(0.1, 0.1);
  pe := TParticleEmitter.Create(FScene);
  pe.LoadFromFile(ParticleFolder+'MagicOnTrophy.par', aAtlas);
  pe.SetEmitterTypeRectangle(FTrophy.Width, FTrophy.Height);
  FTrophy.AddChild(pe, 1);
  pe.Scale.Value := PointF(2, 2);
  pe.ParticlesToEmit.Value := 15;

  Audio.PlayMusicTrophy;
  PostMessage(0);
end;

procedure TWinTrophySequence.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    0: begin
      FTrophy.Scale.ChangeTo(PointF(1,1), 3.0, idcDrop);
      FTrophy.Angle.ChangeTo(360*2, 3.0, idcStartFastEndSlow);
      PostMessage(10, 10.0);
    end;
    10: begin
      FTargetScreen.PostMessage(FMess, FDelay);
      Hide(True);
    end;
  end;
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
  FGameInstructions := aText;
  with TDisplayGameHelp.Create(aText) do ShowModal;
end;

procedure TGameScreenTemplate.ShowGameInstructions;
begin
  ShowGameInstructions(FGameInstructions);
end;

procedure TGameScreenTemplate.SetGameInstructions(const aText: string);
begin
  FGameInstructions := aText;
end;

procedure TGameScreenTemplate.DialogQuestion(const aText, aYes, aNo: string; aFont: TTexturedFont;
  aTargetScreen: TScreenTemplate; aYesUserValue, aNoUserValue: TUserMessageValue; aAtlas: TOGLCTextureAtlas);
begin
  with TDialogQuestion.Create(aText, aYes, aNo, aFont, aTargetScreen, aYesUserValue, aNoUserValue, aAtlas) do
    ShowModal;
end;

procedure TGameScreenTemplate.ShowGetReadyGo(aMessageValueWhenDone: TUserMessageValue;
   aDelay: single; aCameraInUse: TOGLCCamera);
begin
  with TGetReadyGo.Create(Self, aMessageValueWhenDone, aDelay) do
    SetCenterCoordinate(GetCenterView(aCameraInUse));
end;

function TGameScreenTemplate.SpriteMessage(const aText: string): TSprite;
var fd: TFontDescriptor;
begin
  fd.Create('Arial', Round(FScene.Height*0.1), [], BGRA(255,255,0), BGRA(0,0,0), PPIScale(3));
  Result := TSprite.Create(FScene, fd, aText);
  FScene.Add(Result, LAYER_TOP);
  Result.CenterOnScene;
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

procedure TGameScreenTemplate.AddBubbleParticleToAtlas(aAtlas: TOGLCTextureAtlas);
begin
  if aAtlas.RetrieveTextureByFileName('bubble_particle.svg') <> NIL then exit;
  aAtlas.AddFromSVG(ParticleFolder+'bubble_particle.svg', PPIScale(32), -1);
end;

procedure TGameScreenTemplate.AddBubbleLessTransparentParticleToAtlas(aAtlas: TOGLCTextureAtlas);
begin
  if aAtlas.RetrieveTextureByFileName('bubble_particle_less_transparent.svg') <> NIL then exit;
  aAtlas.AddFromSVG(ParticleFolder+'bubble_particle_less_transparent.svg', PPIScale(32), -1);
end;

procedure TGameScreenTemplate.AddCloud128x128ParticleToAtlas(aAtlas: TOGLCTextureAtlas);
begin
  if aAtlas.RetrieveTextureByFileName('Cloud128x128.png') <> NIL then exit;
  aAtlas.AddScaledPPI(ParticleFolder+'Cloud128x128.png');
end;

procedure TGameScreenTemplate.AddBlueArrowToAtlas(aAtlas: TOGLCTextureAtlas);
begin
  if not aAtlas.LoadedFromFile then
    with aAtlas.AddFromSVG(SpriteUIFolder+'RightBlueArrow.svg', ScaleW(32), -1)^ do
     FileName := '_UItexKeyboardToButton_';
end;

procedure TGameScreenTemplate.PlaySequenceWinTrophy(
  const aTexTrophyFilename: string; aAtlas: TAtlas;  aMessageValueWhenDone: TUserMessageValue;
  aDelay: single);
begin
  with TWinTrophySequence.Create(aTexTrophyFilename, aAtlas, Self, aMessageValueWhenDone, aDelay) do
    ShowModal;
end;

procedure TGameScreenTemplate.CheckAtlas(var aAtlas: TAtlas; const aFilenameWithoutPath: string);
var f, atlasVersion: string;
  ima: TBGRABitmap;
begin
  aAtlas := FScene.CreateAtlas;
  aAtlas.Spacing := 2;

  // check if the atlas file exists
  f := FSaveGame.SaveFolder + aFilenameWithoutPath;
  if FileExists(f) then begin
    // read the version in the atlas file
    atlasVersion := TAtlas.GetAtlasFileVersion(f);
    // if atlas and app version are equal, we can reuse it
    if atlasVersion = APP_VERSION then
      aAtlas.LoadFromFile(f);
  end;

  DefineSubTextures(aAtlas);

  if not aAtlas.LoadedFromFile then begin
    aAtlas.TryToPack;
    aAtlas.Build;
    ima := aAtlas.GetPackedImage;
    ima.SaveToFile(Application.Location+'Atlas.png');
    ima.Free;
    aAtlas.SaveToFile(f, APP_VERSION);
  end;
end;

function TGameScreenTemplate.GetLoadingMessageSprite: TSprite;
var fd: TFontDescriptor;
  tex: PTexture;
  o: TSprite;
  ima, ima1: TBGRABitmap;
begin
  ima := LoadBitmapFromSVG(SpriteUIFolder+'WorkSign.svg', ScaleW(183), -1);
  ima1 := ima.FilterGrayscale;
  ima.Free;
  tex := FScene.TexMan.Add(ima1);
  ima1.Free;
  Result := TSprite.Create(tex, True);
  Result.ParentScene := FScene;

  fd.Create('Arial', Round(FScene.Height*0.03), [], BGRA(255,255,200));
  o := TSprite.Create(FScene, fd, sLoading, NIL);
  Result.AddChild(o, 0);
  o.CenterX := Result.Width*0.5;
  o.Y.Value := Result.Height;
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
    FScene.Layer[i].PostProcessing.DisableAll;
    FScene.Layer[i].PostProcessing.UseCustomRenderer(NIL);
  end;

  TCharacterWithDialogPanel.DialogIsChildOfCharacter := False;
end;

end.

