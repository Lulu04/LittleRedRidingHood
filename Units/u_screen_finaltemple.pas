unit u_screen_finaltemple;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, ALSound,
  BGRABitmap, BGRABitmapTypes, BGRAPath,
  u_common, u_common_ui, u_audio, u_gamescreentemplate,
  u_ui_panels, u_sprite_lrcommon,
  u_procedural_topdownsunray, u_leveltemple;

type


{ TScreenFinalTemple }

TScreenFinalTemple = class(TGameScreenTemplate)
private type TGameState=(gsUndefined, gsRunning);
var FGameState: TGameState;
  procedure SetGameState(AValue: TGameState);
private
  FPausePanel: TInGamePausePanel;

  FTopDownSunRayRenderer: TTopDownSunRayRenderer;
  FSunRay: TTopDownSunRay;

  FDecorTemple: TLevelTemple;

  procedure ResetVariables;
  procedure CreateLevel;
public
  //procedure DefineSubTextures(aAtlas: TAtlas); override;
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property GameState: TGameState read FGameState write SetGameState;
end;

var ScreenFinalTemple: TScreenFinalTemple;

implementation
uses Forms, Graphics, u_app, u_mousepointer, u_screen_map, u_utils,
  u_resourcestring, u_sprite_lr4dir, u_sprite_wolf, u_postprocessing_watermirror,
  u_sprite_def, u_robotw7;

var
  texGround: PTexture;
  FAtlas: TAtlas;
  FFontText: TTexturedFont;
  FCamera: TOGLCCamera;
  FFather: TWolfFather;
  FLR: TLR4Direction;
  FPostProcessingWaterMirror: TPostProcessingWaterMirror;
  FCamera1, FCamera2: TOGLCCamera;

{ TScreenFinalTemple }

procedure TScreenFinalTemple.SetGameState(AValue: TGameState);
begin
  if FGameState = AValue then exit;
  FGameState := AValue;
end;

procedure TScreenFinalTemple.ResetVariables;
begin

end;

procedure TScreenFinalTemple.CreateLevel;
var bg: TQuad4Color;
begin
  // fog bg     LAYER_BG3
  bg := TQuad4Color.Create(FScene);
  FScene.Add(bg, LAYER_BG3);
  bg.SetSize(FScene.Width, ScaleH(462));
  bg.SetAllColorsTo(BGRA(4,156,240)); //115,118,90)); //231,236,180));


  // sun ray   LAYER_BG1
  FTopDownSunRayRenderer := TTopDownSunRayRenderer.Create(FScene, True);
  FSunRay := TTopDownSunRay.Create(FScene, FTopDownSunRayRenderer);
  FScene.Add(FSunRay, LAYER_BG1);
  FSunRay.SetSize(FScene.Width, ScaleH(462));
  FSunRay.RayColor := BGRA(255,255,150, 64);
  FSunRay.StartStrength:= 1.0;
  FSunRay.EndStrength := 1.0;
  FSunRay.BlendMode := FX_BLEND_ADD;
  FSunRay.Y.Value := 0;

  // water mirror effect
  FPostProcessingWaterMirror := TPostProcessingWaterMirror.Create(FScene, True);
  FPostProcessingWaterMirror.SetParams(BGRA(0,200,255,100), ScaleH(460), 1.0, 1.3);
  FScene.PostProcessing.EnableFXOnLayerRange([ppCustomRenderer], LAYER_PLAYER, LAYER_BG3);
  FScene.PostProcessing.UseCustomRendererOnLayerRange(FPostProcessingWaterMirror, LAYER_PLAYER, LAYER_BG3);
  FScene.PostProcessing.StartEngine;

  FDecorTemple := TLevelTemple.Create(FScene);
  FDecorTemple.BuildLevel(0);

  FCamera1 := Fscene.CreateCamera;
  FCamera1.AssignToLayers([LAYER_PLAYER, LAYER_GROUND]);
//FCamera1.MoveTo(PointF(FScene.Width*2, FScene.Height*0.5));
//  FCamera1.MoveTo(PointF(FDecorTemple.WorldArea.Right*3, FScene.Height*0.5), 25);
  //FCamera1.MoveTo(PointF(20000, FScene.Height*0.5), 45);

  FCamera2 := Fscene.CreateCamera;
  FCamera2.AssignToLayer(LAYER_BG2);
//FCamera2.MoveTo(PointF(FScene.Width*2, FScene.Height*0.5));
//  FCamera2.MoveTo(PointF(FDecorTemple.WorldArea.Right*3, FScene.Height*0.5), 30);
  //FCamera2.MoveTo(PointF(20000, FScene.Height*0.5), 50);

  FLR := TLR4Direction.Create(LAYER_PLAYER);
  FLR.X.Value := ScaleW(0);
  FLR.BodyBottomY := ScaleH(460);
  FLR.SetWindSpeed(0.3);
  FLR.IdleRight;

  // constrained bounds for the camera
  FCamera1.AutoFollow.ComputeBoundsFromWorldArea(FDecorTemple.WorldArea);
  //FCamera1.AutoFollow.ApplyBounds:= False;

  FCamera1.AutoFollow.SetTargetSurface(FLR, True);
end;

procedure TScreenFinalTemple.CreateObjects;
var path: string;
  ima: TBGRABitmap;
begin

  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 2;

  AdditionnalScale := 1.0;
  LoadLR4DirTextures(FAtlas, False);
  LoadFatherTextures(FAtlas);
  TLevelTemple.LoadTexture(FAtlas);

  texGround := FAtlas.AddFromSVG(SpriteCommonFolder+'Ground1.svg', ScaleW(178), -1);

  // ui
  CreateGameFontNumber(FAtlas); // < must be first !
  // font for button in pause panel
  FFontText := CreateGameFontText(FAtlas);
  LoadGameDialogTextures(FAtlas);
  // load arrow for button panels
  AddBlueArrowToAtlas(FAtlas);
  LoadMousePointerTexture(FAtlas);

  FAtlas.TryToPack;
  FAtlas.Build;
  ima := FAtlas.GetPackedImage;
  ima.SaveToFile(Application.Location+'Atlas.png');
  ima.Free;

  GameState := gsUndefined;
  Audio.PauseMusicTitleMap(3.0);

  CreateLevel;

  // pause panel
  FPausePanel := TInGamePausePanel.Create(FFontText, FAtlas);

  CustomizeMousePointer(False);
  //SetGameInstructions(PlayerInfo.Final.HelpText);
end;

procedure TScreenFinalTemple.FreeObjects;
begin
  FScene.KillCamera(FCamera1);
  FScene.KillCamera(FCamera2);
  FreeAndNil(FDecorTemple);
  FreeAndNil(FTopDownSunRayRenderer);
  FreeAndNil(FPostProcessingWaterMirror);
  FScene.PostProcessing.DisableAllFXOnAllLayers;

  if FScene.RequestedScreen = ScreenMap then
    Audio.ResumeMusicTitleMap;

  FreeMousePointer;
  FScene.ClearAllLayer;
  FAtlas.Free;
  FAtlas := NIL;
  ResetSceneCallbacks;
  ChallengeMode := False;
end;

procedure TScreenFinalTemple.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
end;

procedure TScreenFinalTemple.Update(const aElapsedTime: single);
var flagPlayerIdle: boolean;
begin
  inherited Update(aElapsedTime);

  flagPlayerIdle := True;
  if Input.LeftPressed and flagPlayerIdle then begin
    FLR.State := lr4sLeftWalking;
    flagPlayerIdle := False;
  end;

  if Input.RightPressed and flagPlayerIdle then begin
    FLR.State := lr4sRightWalking;
    flagPlayerIdle := False;
  end;

  if flagPlayerIdle then FLR.SetIdlePosition;

  // check if player pause the game
  if Input.PausePressed then
    FPausePanel.ShowModal;
end;

end.

