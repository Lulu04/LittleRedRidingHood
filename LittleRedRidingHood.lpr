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
  u_utils, u_sprite_granny, u_screen_intro, screen_gameplainmoon,
  u_postprocessing_watermirror, u_procedural_starnest, u_ProceduralPlanet,
  u_proceduralcloud, screen_gameplainmooninside, u_screen_gamemermaidsport,
  u_sprite_def2, u_screen_sam, u_sam, u_dartboard_bird, u_submarine, u_turtle,
  u_transporterwk510, u_screen_strikeraccoon, u_screen_dartboard,
  u_screen_gamemermaidboss, u_screen_gamesnakefissureintro,
  u_screen_gamesnakefissure, u_screen_gamecastle;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;

end.

