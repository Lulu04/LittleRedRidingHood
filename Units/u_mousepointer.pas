unit u_mousepointer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

procedure LoadMousePointerTexture(aAtlas: TOGLCTextureAtlas);
procedure CustomizeMousePointer;
procedure FreeMousePointer;

implementation

uses u_app, u_common;

var
  texMousePointer: PTexture;

procedure LoadMousePointerTexture(aAtlas: TOGLCTextureAtlas);
begin
  texMousePointer := aAtlas.AddFromSVG(SpriteUIFolder+'MousePointer.svg', Round(FScene.Width/30), -1);
end;

procedure CustomizeMousePointer;
begin
  exit;
  FScene.Mouse.SetCursorSprite(texMousePointer, False);
end;

procedure FreeMousePointer;
begin
  exit;
  FScene.Mouse.DeleteCursorSprite;
  FScene.Mouse.SystemMouseCursorVisible := False;
end;

end.

