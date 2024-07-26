unit u_common;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, u_app;


const

  APP_VERSION = '0.1.0';

// Scene layers
LAYER_COUNT = 11;
   LAYER_TOP = 0;
   LAYER_GAMEUI = 1;
   LAYER_DIALOG = 2;
   LAYER_WEATHER = 3;
   LAYER_ARROW = 4;
   LAYER_PLAYER = 5;
   LAYER_WOLF = 6;
   LAYER_FXANIM = 7;
   LAYER_GROUND = 8;
   LAYER_BG1 = 9;
   LAYER_BG2 = 10;


var
  FScene: TOGLCScene;

  KeyLeft, KeyRight, KeyUp, KeyDown, KeyAction1, KeyAction2, KeyPause: byte;
  PlayerInfo: TPlayerInfo;


implementation

end.

