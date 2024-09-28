unit u_common;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, u_app;


const

  APP_VERSION = '0.2.0';

// Scene layers
LAYER_COUNT = 12;
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
   LAYER_BG3 = 11;


var
  FScene: TOGLCScene;

  PlayerInfo: TPlayerInfo;


implementation

end.

