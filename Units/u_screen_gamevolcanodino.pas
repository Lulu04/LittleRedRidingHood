unit u_screen_gamevolcanodino;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common, u_common_ui, u_audio,
  u_ui_panels, u_sprite_lr4dir, u_sprite_lrcommon;

type

{ TScreenGameVolcanoDino }

TScreenGameVolcanoDino = class(TScreenTemplate)
private type TGameState=(gsUndefined=0, gsIdle,
                         gsLRLost,
                         gsDecodingDigicode);
var FGameState: TGameState;
private

  FInGamePausePanel: TInGamePausePanel;

  FDifficulty: integer;
  //procedure ProcessCallbackPickUpSomethingWhenBendDown(aPickUpToTheRight: boolean);
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;

  property Difficulty: integer write FDifficulty;
end;

var ScreenGameVolcanoDino: TScreenGameVolcanoDino;

implementation

uses Forms, u_sprite_wolf, u_app, LCLType;

type
TPillar = class(TSprite)

end;

var FAtlas: TOGLCTextureAtlas;
    texPillar1, texPillar2, texFloor, texCeiling: PTexture;
    FFontText: TTexturedFont;
    FLR: TLR4Direction;
    FPillars: array[0..5] of TSprite;


{ TScreenGameVolcanoDino }

procedure TScreenGameVolcanoDino.CreateObjects;
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
  path := SpriteGameVolcanoDinoFolder;
  texPillar1 := FAtlas.AddFromSVG(path+'Pillar1.svg', -1, FScene.Height div 2); //ScaleH(714));
  texPillar2 := FAtlas.AddFromSVG(path+'Pillar2.svg', -1, FScene.Height div 2); //ScaleH(714));
  texFloor := FAtlas.AddFromSVG(path+'Floor.svg', ScaleH(310), -1);
  texCeiling := FAtlas.AddFromSVG(path+'Ceiling.svg', ScaleH(310), -1);



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

procedure TScreenGameVolcanoDino.FreeObjects;
begin
  FScene.ClearAllLayer;
  FreeAndNil(FAtlas);
end;

procedure TScreenGameVolcanoDino.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue);
end;

procedure TScreenGameVolcanoDino.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
end;

end.

