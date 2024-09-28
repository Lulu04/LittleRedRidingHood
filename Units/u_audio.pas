unit u_audio;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ctypes,
  OGLCScene, ALSound;

type

// duplicate types from ALSound

{ TSound }

TALSSound = ALSound.TALSSound;

{ TAudioManager }

TAudioManager = class
private
  FPlayback: TALSPlaybackContext;
  FGlobalVolume: single;
  function GetMusicVolume: single;
  function GetSoundVolume: single;
  procedure SetGlobalVolume(AValue: single);
  procedure SetMusicVolume(AValue: single);
  procedure SetSoundVolume(AValue: single);
  procedure UpdateVolumeOnSounds;
  procedure UpdateVolumeOnMusic;
private // effets that can be applyed to sounds/musics
  FReverbShort, FReverbLong: TALSEffect;
  procedure CreateEffects;
  procedure DestroyEffects;
private // persistent sounds
  FMusicTitleAndMap,
  FsndUIClick,
  FsndBlipIncrementScore: TALSSound;
public
  constructor Create;
  destructor Destroy; override;

  procedure PlayUIClick;
  procedure PlayUIClickStart;
  procedure PlayBlipIncrementScore;
  procedure PlayMusicSuccess1;
  procedure PlayMusicSuccessShort1;
  procedure PlayMusicLose1;
  procedure PlayMusicCheatCodeEntered;

  // music for title and map screens
  procedure StartMusicTitleMap;
  procedure PauseMusicTitleMap(aFadeDuration: single=3.0);
  procedure ResumeMusicTitleMap(aFadeDuration: single=1.0);
  procedure FadeOutThenKillMusicTitleMap;

  function AddMusic(const aFilenameWithoutPath: string; aLooped: boolean): TALSSound;
  function AddSound(const aFilenameWithoutPath: string): TALSSound; overload;
  function AddSound(const aFilenameWithoutPath: string; aVolume: single; aLooped: boolean): TALSSound; overload;

  // one time sounds
  procedure PlayVoiceWhowhooo;
  procedure PlayThenKillSound(const aFilenameWithoutPath: string; aVolume: single; aPan: single=0.0; aPitch: single=1.0); overload;
  procedure PlayThenKillSound(const aFilenameWithoutPath: string; aVolume: single; aPan: single; aPitch: single;
                              const aEffect: TALSEffect; aDryWet: single); overload;

  property PlaybackContext: TALSPlaybackContext read FPlayback;
  // to control musics volume
  property MusicVolume: single read GetMusicVolume write SetMusicVolume;
  // to control sounds fx volume
  property SoundVolume: single read GetSoundVolume write SetSoundVolume;
  // to control the volume globally (i.e. when the game is paused)
  property GlobalVolume: single read FGlobalVolume write SetGlobalVolume;

  property FXReverbShort: TALSEffect read FReverbShort;
  property FXReverbLong: TALSEffect read FReverbLong;

  procedure SetListenerPosition(aX, aY: single);
  procedure ResetPositionListener;
end;

var Audio: TAudioManager;

implementation
uses u_common, u_app, Math;

var AudioLogFile: TLog = NIL;

procedure ProcessLogMessageFromALSoft({%H-}aUserPtr: pointer; aLevel: char; aMessage: PChar; {%H-}aMessageLength: cint);
begin
  if AudioLogFile <> NIL then
    case aLevel of
      'I': AudioLogFile.Info(StrPas(aMessage));
      'W': AudioLogFile.Warning(StrPas(aMessage));
      'E': AudioLogFile.Error(StrPas(aMessage));
      else AudioLogFile.Warning(StrPas(aMessage));
    end;
end;

{ TAudioManager }

procedure TAudioManager.SetMusicVolume(AValue: single);
begin
  AValue := EnsureRange(Avalue, 0, 1);
  if FSaveGame.MusicVolume = AValue then exit;
  FSaveGame.MusicVolume := AValue;
  UpdateVolumeOnMusic;
end;

function TAudioManager.GetMusicVolume: single;
begin
  Result := FSaveGame.MusicVolume;
end;

function TAudioManager.GetSoundVolume: single;
begin
  Result := FSaveGame.SoundVolume;
end;

procedure TAudioManager.SetGlobalVolume(AValue: single);
begin
  AValue := EnsureRange(Avalue, 0, 1);
  if FGlobalVolume = AValue then Exit;
  FGlobalVolume := AValue;
  UpdateVolumeOnSounds;
  UpdateVolumeOnMusic;
end;

procedure TAudioManager.SetSoundVolume(AValue: single);
begin
  AValue := EnsureRange(Avalue, 0, 1);
  if FSaveGame.SoundVolume = AValue then exit;
  FSaveGame.SoundVolume := AValue;
  UpdateVolumeOnSounds;
end;

procedure TAudioManager.UpdateVolumeOnSounds;
var i: integer;
begin
  for i:=0 to FPlayback.SoundCount-1 do
   if FPlayback.Sounds[i] is TALSSingleStaticBufferSound  then
     TALSSingleStaticBufferSound(FPlayback.Sounds[i]).GlobalVolume := FSaveGame.SoundVolume * FGlobalVolume;
end;

procedure TAudioManager.UpdateVolumeOnMusic;
var i: integer;
begin
  for i:=0 to FPlayback.SoundCount-1 do
   if FPlayback.Sounds[i] is TALSStreamBufferSound  then
     TALSStreamBufferSound(FPlayback.Sounds[i]).GlobalVolume := FSaveGame.MusicVolume * FGlobalVolume;
end;

procedure TAudioManager.CreateEffects;
begin
  FReverbShort := FPlayback.CreateEffect(AL_EFFECT_EAXREVERB, EFX_REVERB_PRESET_ROOM);
  FReverbShort.ApplyDistanceAttenuation := True;

  FReverbLong := FPlayback.CreateEffect(AL_EFFECT_EAXREVERB, EFX_REVERB_PRESET_CONCERTHALL);
  FReverbLong.ApplyDistanceAttenuation := True;
end;

procedure TAudioManager.DestroyEffects;
begin
  FPlayback.DeleteEffect(FReverbShort);
  FPlayback.DeleteEffect(FReverbLong);
end;

constructor TAudioManager.Create;
var attribs: TALSContextAttributes;
begin
  if FSaveGame.FolderCreated then begin
    AudioLogFile := OGLCScene.TLog.Create(FSaveGame.SaveFolder+'alsound.log',NIL, NIL);
    AudioLogFile.DeleteLogFile;
    ALSManager.SetOpenALSoftLogCallback(@ProcessLogMessageFromALSoft, NIL);
  end else AudioLogFile := NIL;

  ALSManager.SetLibrariesSubFolder(FScene.App.ALSoundLibrariesSubFolder);
  ALSManager.LoadLibraries;
  ALSManager.VolumeMode := ALS_VOLUME_MODE_SQUARED;
  attribs.InitDefault;
  attribs.OutputMode := ALC_STEREO_HRTF;
  FPlayback := ALSManager.CreatePlaybackContext(-1, attribs); //ALSManager.CreateDefaultPlaybackContext;
  FGlobalVolume := 1.0;

  CreateEffects;
end;

destructor TAudioManager.Destroy;
begin
  DestroyEffects;
  FreeAndNil(FPlayback);
  FreeAndNil(AudioLogFile);
  inherited Destroy;
end;

procedure TAudioManager.PlayUIClick;
begin
  if FsndUIClick = NIL then begin
    FsndUIClick := AddSound('sfx-ui-button-click.ogg'); //'UI_metalClick.ogg');
    FsndUIClick.ApplyEffect(FXReverbShort);
    FsndUIClick.SetEffectDryWetVolume(FXReverbShort, 0.5);
  end;
  FsndUIClick.Pitch.Value := 1.0;
  FsndUIClick.Play(False);
end;

procedure TAudioManager.PlayUIClickStart;
begin
  PlayUIClick;
  FsndUIClick.Pitch.Value := 1.6;
end;

procedure TAudioManager.PlayBlipIncrementScore;
begin
  if FsndBlipIncrementScore = NIL then begin
    FsndBlipIncrementScore := AddSound('BlipIncrementScore.ogg');
    FsndBlipIncrementScore.Volume.Value := 0.6;
  end;
  FsndBlipIncrementScore.Play(True);
end;

procedure TAudioManager.PlayMusicSuccess1;
begin
  with AddMusic('Success1.ogg', False) do begin
    ApplyEffect(FXReverbShort);
    PlayThenKill(True);
  end;
end;

procedure TAudioManager.PlayMusicSuccessShort1;
begin
  with AddMusic('SuccessShort1.ogg', False) do
    PlayThenKill(True);
end;

procedure TAudioManager.PlayMusicLose1;
begin
  with AddMusic('Lose1.ogg', False) do
    PlayThenKill(True);
end;

procedure TAudioManager.PlayMusicCheatCodeEntered;
begin
  with AddMusic('SuccessShort2.ogg', False) do begin
    GlobalVolume := 0.8;
    ApplyEffect(FXReverbShort);
    SetEffectDryWetVolume(FXReverbShort, 0.5);
    PlayThenKill(True);
  end;
end;

procedure TAudioManager.StartMusicTitleMap;
begin
  if FMusicTitleAndMap = NIL then
    FMusicTitleAndMap := AddMusic('OnTheIslands.ogg', True);
  FMusicTitleAndMap.Loop := True;
  FMusicTitleAndMap.Play(True);
end;

procedure TAudioManager.PauseMusicTitleMap(aFadeDuration: single);
begin
  FMusicTitleAndMap.FadeOutThenPause(aFadeDuration);
end;

procedure TAudioManager.ResumeMusicTitleMap(aFadeDuration: single);
begin
  FMusicTitleAndMap.FadeIn(1.0, aFadeDuration);
end;

procedure TAudioManager.FadeOutThenKillMusicTitleMap;
begin
  FMusicTitleAndMap.FadeOutThenKill(1.0);
end;

function TAudioManager.AddMusic(const aFilenameWithoutPath: string; aLooped: boolean): TALSSound;
begin
  Result := FPlayback.AddStream(MusicsFolder + aFilenameWithoutPath);
  Result.Loop := aLooped;
  Result.GlobalVolume := FSaveGame.MusicVolume * FGlobalVolume;
end;

function TAudioManager.AddSound(const aFilenameWithoutPath: string): TALSSound;
begin
  Result := FPlayback.AddSound(SoundsFolder + aFilenameWithoutPath);
  Result.GlobalVolume := FSaveGame.SoundVolume * FGlobalVolume;
end;

function TAudioManager.AddSound(const aFilenameWithoutPath: string; aVolume: single; aLooped: boolean): TALSSound;
begin
  Result := AddSound(aFilenameWithoutPath);
  Result.Volume.Value := aVolume;
  Result.Loop := aLooped;
end;

procedure TAudioManager.PlayVoiceWhowhooo;
begin
  with Audio.AddSound('little-girl-saying-woo-hoo.mp3') do begin
    Pitch.Value := 1.5;
    PlayThenKill(True);
  end;
end;

procedure TAudioManager.PlayThenKillSound(const aFilenameWithoutPath: string; aVolume: single;
    aPan: single; aPitch: single);
begin
  with Audio.AddSound(aFilenameWithoutPath) do begin
    Volume.Value := aVolume;
    Pan.Value := aPan;
    Pitch.Value := aPitch;
    PlayThenKill(True);
  end;
end;

procedure TAudioManager.PlayThenKillSound(const aFilenameWithoutPath: string;
  aVolume: single; aPan: single; aPitch: single; const aEffect: TALSEffect; aDryWet: single);
begin
  with Audio.AddSound(aFilenameWithoutPath) do begin
    Volume.Value := aVolume;
    Pan.Value := aPan;
    Pitch.Value := aPitch;
    PlayThenKill(True);
    ApplyEffect(aEffect);
    SetEffectDryWetVolume(aEffect, aDryWet);
  end;
end;

procedure TAudioManager.SetListenerPosition(aX, aY: single);
begin
  PlaybackContext.SetListenerPosition(aX, aY, 0.0);
end;

procedure TAudioManager.ResetPositionListener;
begin
  PlaybackContext.SetListenerPosition(0.0, 0.0, 0.0);
end;

end.

