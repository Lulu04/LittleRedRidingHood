program LittleRedRidingHood;

{$mode objfpc}{$H+}


uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazopenglcontext, OGLCScene, u_common, form_main, u_screen_title,
  u_app, u_sprite_lrcommon, u_sprite_wolf, u_screen_gameforest,
  u_sprite_gameforest, screen_logo, u_common_ui, u_gamebackground,
  u_resourcestring, u_screen_map, u_ui_panels, u_audio, u_screen_workshop,
  u_mousepointer, u_screen_gamemountainpeaks, u_screen_gamevolcanoentrance,
  u_sprite_lr4dir, u_screen_gamevolcanoinner, u_screen_gamevolcanodino,
  u_sprite_def, u_gamescreentemplate, u_weather_effects, u_lr4_usable_object,
  u_utils, u_sprite_granny, u_screen_intro;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;

end.

