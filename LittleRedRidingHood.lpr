program LittleRedRidingHood;

{$mode objfpc}{$H+}
{$DEFINE ProgrammePrincipal}


uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazopenglcontext, OGLCScene,
  u_common,
  form_main, u_screen_title, u_app, u_sprite_lrcommon, u_sprite_wolf,
u_screen_gameforest,
u_sprite_gameforest, screen_logo, u_common_ui, u_gamebackground,
u_resourcestring, u_screen_map, u_ui_panels, u_audio, u_screen_workshop,
u_mousepointer, u_screen_gamemountainpeaks, u_screen_gamevolcanoentrance,
u_sprite_lr4dir, u_screen_gamevolcano;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;

end.

