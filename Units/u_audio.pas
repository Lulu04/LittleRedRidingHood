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
  FReverb1, FReverbLong: TALSEffect;
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
  procedure PlayBlipIncrementScore;
  procedure PlayMusicSuccess1;
  procedure PlayMusicLose1;

  // music for title and map screens
  procedure StartMusicTitleMap;
  procedure PauseMusicTitleMap(aFadeDuration: single=3.0);
  procedure ResumeMusicTitleMap(aFadeDuration: single=1.0);

  function AddMusic(const aFilenameWithoutPath: string; aLooped: boolean): TALSSound;
  function AddSound(const aFilenameWithoutPath: string): TALSSound;

  // one time sounds
  procedure PlayVoiceWhowhooo;

  property PlaybackContext: TALSPlaybackContext read FPlayback;
  // to control musics volume
  property MusicVolume: single read GetMusicVolume write SetMusicVolume;
  // to control sounds fx volume
  property SoundVolume: single read GetSoundVolume write SetSoundVolume;
  // to control the volume globally (i.e. when the game is paused)
  property GlobalVolume: single read FGlobalVolume write SetGlobalVolume;

  property Reverb1: TALSEffect read FReverb1;
  property ReverbLong: TALSEffect read FReverbLong;

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
  FReverb1 := FPlayback.CreateEffect(AL_EFFECT_EAXREVERB, EFX_REVERB_PRESET_ROOM);
  FReverbLong := FPlayback.CreateEffect(AL_EFFECT_EAXREVERB, EFX_REVERB_PRESET_CONCERTHALL);
end;

procedure TAudioManager.DestroyEffects;
begin
  FPlayback.DeleteEffect(FReverb1);
  FPlayback.DeleteEffect(FReverbLong);
end;

constructor TAudioManager.Create;
begin
  if FSaveGame.FolderCreated then begin
    AudioLogFile := OGLCScene.TLog.Create(FSaveGame.SaveFolder+'alsound.log',NIL, NIL);
    AudioLogFile.DeleteLogFile;
    ALSManager.SetOpenALSoftLogCallback(@ProcessLogMessageFromALSoft, NIL);
  end else AudioLogFile := NIL;

  ALSManager.SetLibrariesSubFolder(FScene.App.ALSoundLibrariesSubFolder);
  ALSManager.LoadLibraries;
  ALSManager.VolumeMode := ALS_VOLUME_MODE_SQUARED;
  FPlayback := ALSManager.CreateDefaultPlaybackContext;
  FGlobalVolume := 1.0;

  CreateEffects;
end;

destructor TAudioManager.Destroy;
begin
  DestroyEffects;
  FPlayback.Free;
  if AudioLogFile <> NIL then FreeAndNil(AudioLogFile);
  inherited Destroy;
end;

procedure TAudioManager.PlayUIClick;
begin
  if FsndUIClick = NIL then begin
    FsndUIClick := AddSound('UI_metalClick.ogg');
    FsndUIClick.ApplyEffect(FReverb1);
  end;
  FsndUIClick.Play(False);
end;

procedure TAudioManager.PlayBlipIncrementScore;
begin
  if FsndBlipIncrementScore = NIL then begin
    FsndBlipIncrementScore := AddSound('BlipIncrementScore.ogg');
    FsndBlipIncrementScore.Volume.Value := 0.5;
  end;
  FsndBlipIncrementScore.Play(True);
end;

procedure TAudioManager.PlayMusicSuccess1;
begin
  with AddMusic('Success1.ogg', False) do
    PlayThenKill(True);
end;

procedure TAudioManager.PlayMusicLose1;
begin
  with AddMusic('Lose1.ogg', False) do
    PlayThenKill(True);
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

procedure TAudioManager.PlayVoiceWhowhooo;
begin
  with Audio.AddSound('little-girl-saying-woo-hoo.mp3') do begin
    Pitch.Value := 1.5;
    PlayThenKill(True);
  end;
end;

end.

