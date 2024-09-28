unit u_utils;

{$mode ObjFPC}{$H+}
{$modeswitch AdvancedRecords}

interface

uses
  Classes, SysUtils,
  BGRABitmap, BGRABitmapTypes,
  OGLCScene;

function GetViewRect(aCameraInUse: TOGLCCamera): TRectF;
function GetCenterView(aCameraInUse: TOGLCCamera): TPointF;

type

{ TInput }

TInput = record
  KeyLeft, KeyRight, KeyUp, KeyDown, KeyAction1, KeyAction2, KeyPause: byte;
  function RightPressed: boolean; inline;
  function LeftPressed: boolean; inline;
  function UpPressed: boolean; inline;
  function DownPressed: boolean; inline;
  function Action1Pressed: boolean; inline;
  function Action2Pressed: boolean; inline;
  function PausePressed: boolean; inline;
  function AButtonIsPressed: boolean; inline;
end;
var
  Input: TInput;


type

{ TCheatCodeManager }

TCheatCodeManager = record
private
  FCharBuffer, FEnteredCheatCode: string;
  FCheatCodeList: TStringArray;
  function GetCheatCodeEntered: string;
public
  procedure InitDefault;
  procedure SetCheatCodeList(const aList: TStringArray);
  procedure AddCheatCodeToList(const aCheatCode: string);
  procedure Update;
  // this property is reseted to an empty string after read it.
  property CheatCodeEntered: string read GetCheatCodeEntered;
end;

implementation
uses u_common;

{ TCheatCodeManager }

function TCheatCodeManager.GetCheatCodeEntered: string;
begin
  Result := FEnteredCheatCode;
  FEnteredCheatCode := '';
end;

procedure TCheatCodeManager.InitDefault;
begin
  FCharBuffer := '';
  FCheatCodeList := NIL;
  FEnteredCheatCode := '';
end;

procedure TCheatCodeManager.SetCheatCodeList(const aList: TStringArray);
begin
  FCheatCodeList := Copy(aList, 0, Length(aList));
end;

procedure TCheatCodeManager.AddCheatCodeToList(const aCheatCode: string);
begin
  SetLength(FCheatCodeList, Length(FCheatCodeList)+1);
  FCheatCodeList[High(FCheatCodeList)] := aCheatCode;
end;

procedure TCheatCodeManager.Update;
var i: integer;
  s: string;
begin
  if Length(FCheatCodeList) = 0 then exit;

  s := FScene.LastUTF8CharEntered;
  if s <> '' then begin
    FCharBuffer := FCharBuffer + s;
    if Length(FCharBuffer) > 50 then Delete(FCharBuffer, 1, 1);

    for i:=0 to High(FCheatCodeList) do
      if Pos(FCheatCodeList[i], FCharBuffer) <> 0 then begin
        FCharBuffer := '';
        FEnteredCheatCode := FCheatCodeList[i];
        Delete(FCheatCodeList, i, 1); // delete the cheat code from the list to avoid multiple time
        exit;
      end;
  end;

end;

function TInput.RightPressed: boolean;
begin
  Result := FScene.KeyState[KeyRight];
end;

function TInput.LeftPressed: boolean;
begin
  Result := FScene.KeyState[KeyLeft];
end;

function TInput.UpPressed: boolean;
begin
  Result := FScene.KeyState[KeyUp];
end;

function TInput.DownPressed: boolean;
begin
  Result := FScene.KeyState[KeyDown];
end;

function TInput.Action1Pressed: boolean;
begin
  Result := FScene.KeyState[KeyAction1];
end;

function TInput.Action2Pressed: boolean;
begin
  Result := FScene.KeyState[KeyAction2];
end;

function TInput.PausePressed: boolean;
begin
  Result := FScene.KeyState[KeyPause];
end;

function TInput.AButtonIsPressed: boolean;
begin
  Result := FScene.UserPressAKey;
end;

function GetViewRect(aCameraInUse: TOGLCCamera): TRectF;
begin
  if aCameraInUse <> NIL then Result := aCameraInUse.GetViewRect
    else Result := RectF(0, 0, FScene.Width, FScene.Height);
end;

function GetCenterView(aCameraInUse: TOGLCCamera): TPointF;
var r: TRectF;
begin
  r := GetViewRect(aCameraInUse);
  Result.X := r.Left + r.Width * 0.5;
  Result.y := r.Top + r.Height * 0.5;
end;

end.

