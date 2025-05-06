unit u_mousepointer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, BGRABitmap, BGRABitmapTypes;

procedure LoadMousePointerTexture(aAtlas: TAtlas);
procedure CustomizeMousePointer(aShowCursor: boolean=False);
procedure FreeMousePointer;

implementation

uses u_app, u_common;

var
  texMousePointer: PTexture;

procedure LoadMousePointerTexture(aAtlas: TAtlas);
begin
  texMousePointer := aAtlas.AddFromSVG(SpriteUIFolder+'MousePointer.svg', Round(FScene.Width/30), -1);
end;

procedure CustomizeMousePointer(aShowCursor: boolean);
begin
  FScene.Mouse.SetCursorSprite(texMousePointer, False, PointF(0,0));
  FScene.Mouse.MouseSprite.Visible := aShowCursor;
end;

procedure FreeMousePointer;
begin
  FScene.Mouse.DeleteCursorSprite;
  FScene.Mouse.SystemMouseCursorVisible := False;
end;

end.

