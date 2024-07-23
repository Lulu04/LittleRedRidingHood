unit screen_logo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene,
  u_common;

type

{ TScreenLogo }

TScreenLogo = class(TScreenTemplate)
private
  FAtlas: TOGLCTextureAtlas;
  FTexHearth, FTexPeopleInPeace, FTexLogoBody, FTexLogoRightArm, FTexLogoLeftArm, FTexLogoHead: PTexture;
  FStep: integer;
  FHearth, FHearthText, FBody, FRightArm, FLeftArm, FHead: TSprite;
  FGlow: TOGLCGlow;
  procedure ProcessClickOnScene({%H-}Button: TMouseButton; {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
  procedure InterruptLogo;
public
  procedure CreateObjects; override;
  procedure FreeObjects; override;
  procedure ProcessMessage({%H-}UserValue: TUserMessageValue); override;
  procedure Update(const aElapsedTime: single); override;
end;

var ScreenLogo: TScreenLogo = NIL;

implementation

uses u_screen_title;

{ TScreenLogo }

procedure TScreenLogo.ProcessClickOnScene(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  InterruptLogo;
end;

procedure TScreenLogo.InterruptLogo;
begin
  case FStep of
    0: begin
      ClearMessageList;
      PostMessage(1);
    end;
    2: begin
      ClearMessageList;
      PostMessage(10);
    end;
    3: begin
      ClearMessageList;
      PostMessage(10);
    end;
  end;
end;

procedure TScreenLogo.CreateObjects;
var fd: TFontDescriptor;
  path: string;
  h: integer;
begin
  FAtlas := FScene.CreateAtlas;
  FAtlas.Spacing := 1;

  path := FScene.App.DataFolder+'Logo'+DirectorySeparator;
  FTexHearth := FAtlas.AddFromSVG(path+'World.svg', -1, Round(FScene.Height*0.5));

  fd.Create('Arial', Round(FScene.Height/15), [], BGRA(255,255,200), BGRA(0,0,0,0), 0, BGRA(255,128,64), 0, 0, 10);
  FTexPeopleInPeace := FAtlas.AddString('Peoples at peace', fd, NIL);

  h := Round(FScene.Height*0.35);
  FTexLogoBody := FAtlas.AddFromSVG(path+'LogoBody.svg', -1, h);
  FTexLogoHead := FAtlas.AddFromSVG(path+'LogoHead.svg', -1, Round(h*0.4072));
  FTexLogoRightArm := FAtlas.AddFromSVG(path+'LogoRightArm.svg', -1, Round(h*0.4253));
  FTexLogoLeftArm := FAtlas.AddFromSVG(path+'LogoLeftArm.svg', -1, Round(h*0.4253));

  FAtlas.TryToPack;
  FAtlas.Build;

  FHearth := TSprite.Create(FTexHearth, False);
  FScene.Add(FHearth);
  FHearth.CenterX := FScene.Width*0.5;
  FHearth.Y.Value := FScene.Height*0.1;
  FHearth.Opacity.Value := 0;

  FHearthText := TSprite.Create(FTexPeopleInPeace, False);
  FScene.Add(FHearthText);
  FHearthText.CenterX := FScene.Width*0.5;
  FHearthText.Y.Value := FHearth.BottomY + FScene.ScaleDesignToScene(50);
  FHearthText.Opacity.Value := 0;

  FGlow := TOGLCGlow.Create(FScene, FHearth.Width*0.5, BGRA(255,128,64));
  FHearth.AddChild(FGlow, -1);
  FGlow.CenterOnParent;
  FGlow.Opacity.Value := 0;

  FBody := TSprite.Create(FTexLogoBody, False);
  FScene.Add(FBody);
  FBody.CenterX := FScene.Width*0.5;
  FBody.CenterY := FScene.Height*0.5;
  FBody.Opacity.Value := 0;

  FHead  := TSprite.Create(FTexLogoHead, False);
  FBody.AddChild(FHead, 1);
  FHead.X.Value := FBody.Width*0.3369;
  FHead.BottomY := FBody.Height*0.02;
  FHead.Opacity.Value := 0;

  FLeftArm  := TSprite.Create(FTexLogoLeftArm, False);
  FBody.AddChild(FLeftArm, 1);
  FLeftArm.X.Value := FBody.Width*0.685;
  FLeftArm.Y.Value := FBody.Height*0.3212;
  FLeftArm.Pivot := PointF(0.67,0.14); // PointF(0.6843,0.1276);
  FLeftArm.Opacity.Value := 0;

  FRightArm  := TSprite.Create(FTexLogoRightArm, False);
  FBody.AddChild(FRightArm, 1);
  FRightArm.X.Value := FBody.Width*0.1978;
  FRightArm.Y.Value := FBody.Height*0.3212;
  FRightArm.Pivot := PointF(0.33,0.14); // PointF(0.3157,0.1276);
  FRightArm.Opacity.Value := 0;

  FScene.Mouse.OnClickOnScene := @ProcessClickOnScene;
  FStep := -1;
  PostMessage(0);
end;

procedure TScreenLogo.FreeObjects;
begin
  FScene.ClearAllLayer;
  FreeAndNil(FAtlas);
end;

procedure TScreenLogo.ProcessMessage(UserValue: TUserMessageValue);
begin
  inherited ProcessMessage(UserValue); // keep this line please
  case UserValue of
    0: begin     // people appears
      FStep := 0;
      FHearth.Opacity.ChangeTo(255, 1.0);
      FHearthText.Opacity.ChangeTo(255, 1.0);
      FGlow.Opacity.ChangeTo(255, 1.0);
      PostMessage(1, 4);
    end;
    1: begin    // people disappears
      FStep := 1;
      FScene.Layer[0].Opacity.ChangeTo(0, 1.0);
      PostMessage(2, 1.0);
    end;
    2: begin   // puppet appears
      FStep := 2;
      FHearth.Opacity.Value := 0;
      FHearthText.Opacity.Value := 0;
      FGlow.Opacity.Value := 0;

      FBody.Opacity.Value := 255;
      FRightArm.Opacity.Value := 255;
      FLeftArm.Opacity.Value := 255;
      FHead.Opacity.Value := 255;
      FScene.Layer[0].Opacity.ChangeTo(255, 1.0);
      PostMessage(3, 2);
    end;
    3: begin   // puppet pranam
      FStep := 3;
      FRightArm.Angle.ChangeTo(-115, 1.5, idcSinusoid);
      FLeftArm.Angle.ChangeTo(115, 1.5, idcSinusoid);
      FHead.MoveRelative(0, FHead.Height*0.35, 1.5, idcSinusoid);
      PostMessage(4, 2);
    end;
    4: begin   // puppet end pranam
      FRightArm.Angle.ChangeTo(-70, 1.5, idcSinusoid);
      FLeftArm.Angle.ChangeTo(70, 1.5, idcSinusoid);
      FHead.MoveRelative(0, -FHead.Height*0.35, 1.5, idcSinusoid);
      PostMessage(10, 3);
    end;
    10: begin  // puppet disappears
      FScene.RunScreen(ScreenTitle);
    end;
  end;
end;

procedure TScreenLogo.Update(const aElapsedTime: single);
begin
  inherited Update(aElapsedTime);
  if FScene.UserPressAKey then InterruptLogo;
end;


end.

