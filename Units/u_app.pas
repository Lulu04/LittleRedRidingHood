unit u_app;

{$mode ObjFPC}{$H+}
{$modeswitch AdvancedRecords}

interface

uses
  Classes, SysUtils, OGLCScene;

  function MusicsFolder: string;
  function SoundsFolder: string;
  function ParticleFolder: string;
  function SpriteFolder: string;
  function SpriteLRPortraitFolder: string;
  function SpriteLR4DirFolder: string;
  function SpriteLR4DirRightFolder: string;
  function SpriteLR4DirFrontFolder: string;
  function SpriteLR4DirBackFolder: string;
  function SpriteCommonFolder: string;
  function SpriteUIFolder: string;
  function SpriteBGFolder: string;
  function SpriteMapFolder: string;
  function SpriteGameMountainPeaksFolder: string;
  function SpriteGameVolcanoEntranceFolder: string;
  function LanguageFolder: string;

  function ALSoundLibrariesSubFolder: string;

  function PPIScale(AValue: integer): integer;
  function ScaleW(AValue: integer): integer;
  function ScaleH(AValue: integer): integer;

var
  AdditionnalScale: single=1.0;

type

// type of money used to buy/build/upgrade item in the inventory
TMoneyType = (mtCoin, mtPurpleCristal);
TMoneyDescriptor = record
  MoneyType: TMoneyType;
  Count: integer;
end;
ArrayOfMoneyDescriptor = array of TMoneyDescriptor;

TActionToOwnItem = (atoiBuy, atoiBuild);

{ TUpgradableItemDescriptor }

TUpgradableItemDescriptor = class
private
  FLevel, FMaxLevel: byte;
  FActionToOwnItem: TActionToOwnItem;
public
  constructor Create(aMaxItemLevel: byte; aActionToOwnThisItem: TActionToOwnItem);
  // return True if player have the resources required to buy/build/upgrade the item
  function CanBePurchased: boolean;
  // Substract all resources from the player inventory
  procedure BuyNextLevel;
  function Owned: boolean; virtual;
  function NextLevelExplanation: string; virtual; abstract;
  function PriceForNextLevel: ArrayOfMoneyDescriptor; virtual; abstract;
  function LevelCanBeUpgraded: boolean;
  // Increment the level of the item
  procedure IncLevel;

  property Level: byte read FLevel write FLevel;
  property MaxLevel: byte read FMaxLevel;
  property ActionToOwnItem: TActionToOwnItem read FActionToOwnItem;
end;

{ TGameDescriptor }

TGameDescriptor = class
private
  FCurrentStep, FStepCount, FStepPlayed: integer;
  FIsTerminated, FFirstTimeTerminated: boolean;
  function GetFirstTimeTerminated: boolean;
  function GetHelpText: string; virtual; abstract;
protected
  procedure SaveCommonProperties(var aProp: TProperties);
  procedure LoadCommonProperties(const aProp: TProperties);
public
  constructor Create(aStepCount: integer);

  function SaveToString: string; virtual; abstract;
  procedure LoadFromString(const s: string); virtual; abstract;

  procedure IncCurrentStep;
  property CurrentStep: integer read FCurrentStep;
  property StepCount: integer read FStepCount;
  // become True when player win all step in this sub-game
  property IsTerminated: boolean read FIsTerminated;
  property FirstTimeTerminated: boolean read GetFirstTimeTerminated;

  property StepPlayed: integer read FStepPlayed write FStepPlayed;
  // a short text that describe the keys used to play the game
  property HelpText: string read GetHelpText;
end;

// FOREST GAME DESCRIPTOR
type

{ TForestBow }

TForestBow = class(TUpgradableItemDescriptor)
  function Owned: boolean; override;
  function NextLevelExplanation: string; override;
  function PriceForNextLevel: ArrayOfMoneyDescriptor; override;
  function ArrowRearmTimeMultiplicator: single;
  function ArrowSpeed: single;
end;

{ TForestElevator }

TForestElevator = class(TUpgradableItemDescriptor)
  function Owned: boolean; override;
  function NextLevelExplanation: string; override;
  function PriceForNextLevel: ArrayOfMoneyDescriptor; override;
  function Speed: single;
end;

{ TForestHammer }

TForestHammer = class(TUpgradableItemDescriptor)
  function NextLevelExplanation: string; override;
  function PriceForNextLevel: ArrayOfMoneyDescriptor; override;
  function UsesCount: integer;
end;

{ TForestStormCloud }

TForestStormCloud = class(TUpgradableItemDescriptor)
  function NextLevelExplanation: string; override;
  function PriceForNextLevel: ArrayOfMoneyDescriptor; override;
  function UsesCount: integer;
  function TargetCount: integer;
end;

{ TForestDescriptor }

TForestDescriptor = class(TGameDescriptor)
private const
  BowMaxLevel = 6;
  ElevatorMaxLevel = 5;
  HammerMaxLevel = 5;       // [0..5]   0 is not available  buyable in workshop
  StormCloudMaxLevel = 3;   // [0..3]   0 is not available  buyable in workshop
  ForestStepCount = 10;
private
  FBow: TForestBow;
  FElevator: TForestElevator;
  FHammer: TForestHammer;
  FStormCloud: TForestStormCloud;
  function GetHelpText: string; override;
public
  constructor Create;
  destructor Destroy; override;
  function SaveToString: string; override;
  procedure LoadFromString(const s: string); override;
  property Bow: TForestBow read FBow;
  property Elevator: TForestElevator read FElevator;
  property Hammer: TForestHammer read FHammer;
  property StormCloud: TForestStormCloud read FStormCloud;

end;

// MOUNTAIN PEAK GAME DESCRIPTOR
type

{ TMountainPeakZipLine }

TMountainPeakZipLine = class(TUpgradableItemDescriptor)
  function NextLevelExplanation: string; override;
  function PriceForNextLevel: ArrayOfMoneyDescriptor; override;
end;

{ TMountainPeakDescriptor }

TMountainPeakDescriptor = class(TGameDescriptor)
private
  FZipLine: TMountainPeakZipLine;         // [0..1]
  function GetHelpText: string; override;
public const
  ZipLineMaxLevel = 1;
  MountainPeaksStepCount = 10;
public
  constructor Create;
  destructor Destroy; override;
  function SaveToString: string; override;
  procedure LoadFromString(const s: string); override;
  property ZipLine: TMountainPeakZipLine read FZipLine;
end;


{ TDigicodeDecoder }

TDigicodeDecoder = class(TUpgradableItemDescriptor)
  function NextLevelExplanation: string; override;
  function PriceForNextLevel: ArrayOfMoneyDescriptor; override;
end;

{ TVolcanoDescriptor }

TVolcanoDescriptor = class(TGameDescriptor)
private
  FHaveDecoderPlan: boolean;
  FVolcanoEntranceIsDone: boolean;
  FDigicodeDecoder: TDigicodeDecoder;
  function GetHelpText: string; override;
private const
  VolcanoStepCount = 10;
  DigicodeDecoderMaxLevel = 1;
public
  constructor Create;
  destructor Destroy; override;
  function SaveToString: string; override;
  procedure LoadFromString(const s: string); override;
public // special volcano item
  property DigicodeDecoder: TDigicodeDecoder read FDigicodeDecoder;
  property HaveDecoderPlan: boolean read FHaveDecoderPlan write FHaveDecoderPlan;
  property VolcanoEntranceIsDone: boolean read FVolcanoEntranceIsDone write FVolcanoEntranceIsDone;
end;


{ TPlayerInfo }

TPlayerInfo = class
private
  FName: string;
  FCoinCount: integer;
  FPurpleCristalCount: integer;
  FForest: TForestDescriptor;
  FMountainPeak: TMountainPeakDescriptor;
  FVolcano: TVolcanoDescriptor;
public
  constructor Create;
  destructor Destroy; override;

  function SaveToString: string;
  procedure LoadFromString(const s: string);

  property Name: string read FName write FName;
  property CoinCount: integer read FCoinCount write FCoinCount;
  property PurpleCristalCount: integer read FPurpleCristalCount write FPurpleCristalCount;
  property Forest: TForestDescriptor read FForest;
  property MountainPeak: TMountainPeakDescriptor read FMountainPeak;
  property Volcano: TVolcanoDescriptor read FVolcano;
end;

{ TSaveGame }

TSaveGame = class(TOGLCSaveDirectory)
private
  FKeyAction1, FKeyAction2, FKeyDown, FKeyLeft, FKeyUp, FKeyRight: byte;
  FKeyPause: byte;
  FLanguage: string;
  FPlayers: array of TPlayerInfo;
  FCurrentPlayerIndex: integer;
  FMusicVolume, FSoundVolume: single;
  procedure SavePlayersTo(t: TStringList);
  procedure LoadPlayersFrom(t: TStringList);
  procedure SetKeyAction1(AValue: byte);
  procedure SetKeyAction2(AValue: byte);
  procedure SetKeyDown(AValue: byte);
  procedure SetKeyLeft(AValue: byte);
  procedure SetKeyPause(AValue: byte);
  procedure SetKeyUp(AValue: byte);
  procedure SetKeyRight(AValue: byte);
  procedure SetLanguage(AValue: string);
  procedure SetMusicVolume(AValue: single);
  procedure SetSoundVolume(AValue: single);
public
  constructor Create;
  destructor Destroy; override;
  procedure Save;
  procedure Load;
  procedure CreateNewPlayer(const aPlayerName: string);
  procedure DeletePlayer(aIndex: integer);
  // return an array of string 'player_name  level-sublevel'
  function GetPlayersInfo: TStringArray;

  procedure SetCurrentPlayerIndex(aIndex: integer);
  function CurrentPlayer: TPlayerInfo;

  // languages
  property Language: string read FLanguage write SetLanguage;
  // audio
  property MusicVolume: single read FMusicVolume write SetMusicVolume;
  property SoundVolume: single read FSoundVolume write SetSoundVolume;

  // keyboard
  property KeyLeft: byte read FKeyLeft write SetKeyLeft;
  property KeyRight: byte read FKeyRight write SetKeyRight;
  property KeyUp: byte read FKeyUp write SetKeyUp;
  property KeyDown: byte read FKeyDown write SetKeyDown;
  property KeyAction1: byte read FKeyAction1 write SetKeyAction1;
  property KeyAction2: byte read FKeyAction2 write SetKeyAction2;
  property KeyPause: byte read FKeyPause write SetKeyPause;
end;

var
  FSaveGame: TSaveGame;

implementation
uses Forms, u_common, u_resourcestring, LCLType, i18_utils;

function PPIScale(AValue: integer): integer;
begin
  Result := FScene.ScaleDesignToScene(AValue);
  //Result := Round(FScene.ScaleDesignToScene(AValue)*0.8);
end;

function ScaleW(AValue: integer): integer;
begin
  Result := Round(FScene.Width*AValue/1024*AdditionnalScale);
end;

function ScaleH(AValue: integer): integer;
begin
  Result := Round(FScene.Height*AValue/768*AdditionnalScale);
end;


function MusicsFolder: string;
begin
  Result := FScene.App.DataFolder+'Musics'+DirectorySeparator;
end;

function SoundsFolder: string;
begin
  Result := FScene.App.DataFolder+'Sounds'+DirectorySeparator;
end;

function ParticleFolder: string;
begin
  Result := FScene.App.DataFolder+'Particles'+DirectorySeparator;
end;

function SpriteFolder: string;
begin
  Result := FScene.App.DataFolder+'Sprites'+DirectorySeparator;
end;

function SpriteLRPortraitFolder: string;
begin
  Result := SpriteFolder+'LRPortrait'+DirectorySeparator;
end;

function SpriteLR4DirFolder: string;
begin
  Result := SpriteFolder+'LR4Direction'+DirectorySeparator;
end;

function SpriteLR4DirRightFolder: string;
begin
  Result := SpriteLR4DirFolder+'RightView'+DirectorySeparator;
end;

function SpriteLR4DirFrontFolder: string;
begin
  Result := SpriteLR4DirFolder+'FrontView'+DirectorySeparator;
end;

function SpriteLR4DirBackFolder: string;
begin
  Result := SpriteLR4DirFolder+'BackView'+DirectorySeparator;
end;

function SpriteCommonFolder: string;
begin
  Result := SpriteFolder+'Common'+DirectorySeparator;
end;

function SpriteUIFolder: string;
begin
  Result := SpriteFolder+'UI'+DirectorySeparator;
end;

function SpriteBGFolder: string;
begin
  Result := SpriteFolder+'BG'+DirectorySeparator;
end;

function SpriteGameMountainPeaksFolder: string;
begin
  Result := SpriteFolder+'GameMountainPeaks'+DirectorySeparator;
end;

function SpriteGameVolcanoEntranceFolder: string;
begin
  Result := SpriteFolder+'VolcanoEntrance'+DirectorySeparator;
end;

function LanguageFolder: string;
begin
  Result := FScene.App.DataFolder+'Languages'+DirectorySeparator;
end;

function SpriteMapFolder: string;
begin
  Result := SpriteFolder+'Map'+DirectorySeparator;
end;

function ALSoundLibrariesSubFolder: string;
begin
  Result := FScene.App.ALSoundLibrariesSubFolder;
end;

{ TDigicodeDecoder }

function TDigicodeDecoder.NextLevelExplanation: string;
begin
  Result := sDecoderHint;
end;

function TDigicodeDecoder.PriceForNextLevel: ArrayOfMoneyDescriptor;
begin
  Result := NIL;
  SetLength(Result, 2);
  Result[0].MoneyType := mtCoin;
  Result[1].MoneyType := mtPurpleCristal;
  case Level of
    0: begin
      Result[0].Count := 3500;
      Result[1].Count := 45;
    end
    else begin
      Result[0].Count := 0;
      Result[1].Count := 0;
    end;
  end;
end;

{ TMountainPeakZipLine }

function TMountainPeakZipLine.NextLevelExplanation: string;
begin
  Result := sZipLineHint;
end;

function TMountainPeakZipLine.PriceForNextLevel: ArrayOfMoneyDescriptor;
begin
  Result := NIL;
  SetLength(Result, 1);
  Result[0].MoneyType := mtCoin;
  case Level of
    0: Result[0].Count := 1000;
    1: Result[0].Count := 300;
    else Result[0].Count := 0;
  end;
end;

{ TForestStormCloud }

function TForestStormCloud.NextLevelExplanation: string;
begin
  case Level of
    //0: Result := sStormCloudHint
    0, 3: Result := sStormCloudExplanation;
    else Result := sStormCloudUpgradeHint;
  end;
end;

function TForestStormCloud.PriceForNextLevel: ArrayOfMoneyDescriptor;
begin
  Result := NIL;
  SetLength(Result, 1);
  Result[0].MoneyType := mtCoin;
  case Level of
    0: Result[0].Count := 400;
    1: Result[0].Count := 450;
    2: Result[0].Count := 500;
    else Result[0].Count := 0;
  end;
end;

function TForestStormCloud.UsesCount: integer;
begin
  case Level of
    1: Result := 2;
    2: Result := 3;
    3: Result := 4;
    else Result := 0;
  end;
end;

function TForestStormCloud.TargetCount: integer;
begin
  case Level of
    1: Result := 4;
    2: Result := 7;
    3: Result := 9;
    else Result := 0;
  end;
end;

{ TForestHammer }

function TForestHammer.NextLevelExplanation: string;
begin
  case Level of
    0, 5: Result := sHammerExplanation;
    else Result := sHammerUpgradeHint;
  end;
end;

function TForestHammer.PriceForNextLevel: ArrayOfMoneyDescriptor;
begin
  Result := NIL;
  SetLength(Result, 1);
  Result[0].MoneyType := mtCoin;
  case Level of
    0: Result[0].Count := 300;
    1: Result[0].Count := 350;
    2: Result[0].Count := 400;
    3: Result[0].Count := 450;
    4: Result[0].Count := 500;
    else Result[0].Count := 0;
  end;
end;

function TForestHammer.UsesCount: integer;
begin
  case Level of
    1: Result := 2;
    2: Result := 4;
    3: Result := 6;
    4: Result := 8;
    5: Result := 10;
    else Result := 0;
  end;
end;

{ TForestElevator }

function TForestElevator.Owned: boolean;
begin
  Result := True;
end;

function TForestElevator.NextLevelExplanation: string;
begin
  case Level of
    5: Result := '';
    else Result := sElevatorUpgradeHint;
  end;
end;

function TForestElevator.PriceForNextLevel: ArrayOfMoneyDescriptor;
begin
  Result:= NIL;
  SetLength(Result, 1);
  Result[0].MoneyType := mtCoin;
  case Level of
    1: Result[0].Count := 100;
    2: Result[0].Count := 250;
    3: Result[0].Count := 300;
    4: Result[0].Count := 350;
    else Result[0].Count := 0;
  end;
end;

function TForestElevator.Speed: single;
begin
  case Level of
    1: Result := FScene.Height/10;
    2: Result := 1.5*FScene.Height/10;
    3: Result := 2*FScene.Height/10;
    4: Result := 2.5*FScene.Height/10;
    5: Result := 3*FScene.Height/10;
    else Result := FScene.Height/10;
  end;
end;

{ TForestBow }

function TForestBow.Owned: boolean;
begin
  Result := True;
end;

function TForestBow.NextLevelExplanation: string;
begin
  case Level of
    6: Result := sBowExplanation;
    else Result := sBowUpgradeHint;
  end;
end;

function TForestBow.PriceForNextLevel: ArrayOfMoneyDescriptor;
begin
  Result := NIL;
  SetLength(Result, 1);
  Result[0].MoneyType := mtCoin;
  case Level of
    1: Result[0].Count := 100;
    2: Result[0].Count := 150;
    3: Result[0].Count := 200;
    4: Result[0].Count := 400;
    5: Result[0].Count := 600;
    else Result[0].Count := 0;
  end;
end;

function TForestBow.ArrowRearmTimeMultiplicator: single;
begin
  case Level of
    1: Result := 0.8;
    2: Result := 0.725;
    3: Result := 0.65;
    4: Result := 0.475;
    5: Result := 0.3;
    6: Result := 0.225;
    else Result := 1.0;
  end;
end;

function TForestBow.ArrowSpeed: single;
begin
  case Level of
    1: Result := 1.1*FScene.Width/3;
    2: Result := 1.5*FScene.Width/3;
    3: Result := 2*FScene.Width/3;
    4: Result := 2.5*FScene.Width/3;
    5: Result := 3*FScene.Width/3;
    6: Result := 3.5*FScene.Width/3;
    else Result := FScene.Width/3;
  end;
end;

{ TUpgradableItemDescriptor }

constructor TUpgradableItemDescriptor.Create(aMaxItemLevel: byte; aActionToOwnThisItem: TActionToOwnItem);
begin
  FMaxLevel := aMaxItemLevel;
  FActionToOwnItem := aActionToOwnThisItem;
end;

function TUpgradableItemDescriptor.CanBePurchased: boolean;
var A: ArrayOfMoneyDescriptor;
  i: integer;
begin
  A := PriceForNextLevel;
  Result := True;
  for i:=0 to High(A) do begin
    case A[i].MoneyType of
      mtCoin: Result := Result and (PlayerInfo.CoinCount >= A[i].Count);
      mtPurpleCristal: Result := Result and (PlayerInfo.PurpleCristalCount >= A[i].Count);
      else raise exception.create('forgot to implement this money type');
    end;
  end;
end;

procedure TUpgradableItemDescriptor.BuyNextLevel;
var A: ArrayOfMoneyDescriptor;
  i: integer;
begin
  A := PriceForNextLevel;
  for i:=0 to High(A) do begin
    case A[i].MoneyType of
      mtCoin: PlayerInfo.CoinCount := PlayerInfo.CoinCount - A[i].Count;
      mtPurpleCristal: PlayerInfo.PurpleCristalCount := PlayerInfo.PurpleCristalCount - A[i].Count;
      else raise exception.create('forgot to implement this money type');
    end;
  end;
end;

function TUpgradableItemDescriptor.Owned: boolean;
begin
  Result := Level > 0;
end;

function TUpgradableItemDescriptor.LevelCanBeUpgraded: boolean;
begin
  Result := Level < MaxLevel;
end;

procedure TUpgradableItemDescriptor.IncLevel;
begin
  inc(FLevel);
end;

{ TVolcanoDescriptor }

function TVolcanoDescriptor.GetHelpText: string;
begin
  if not FVolcanoEntranceIsDone then Result := SVolcanoEntranceHelpText
    else Result := SVolcanoInnerHelpText;
end;

constructor TVolcanoDescriptor.Create;
begin
  inherited Create(VolcanoStepCount);
  FDigicodeDecoder := TDigicodeDecoder.Create(DigicodeDecoderMaxLevel, atoiBuild);
end;

destructor TVolcanoDescriptor.Destroy;
begin
  FreeAndNil(FDigicodeDecoder);
  inherited Destroy;
end;

function TVolcanoDescriptor.SaveToString: string;
var prop: TProperties;
begin
  prop.Init('!');
  SaveCommonProperties(prop);
  prop.Add('HaveDecoderPlan', FHaveDecoderPlan);
  prop.Add('DigicodeDecoderLevel', FDigicodeDecoder.Level);
  prop.Add('VolcanoEntranceIsDone', FVolcanoEntranceIsDone);
  Result := prop.PackedProperty;
end;

procedure TVolcanoDescriptor.LoadFromString(const s: string);
var prop: TProperties;
  vi: byte;
begin
  prop.Split(s, '!');
  LoadCommonProperties(prop);
  prop.BooleanValueOf('HaveDecoderPlan', FHaveDecoderPlan, False);
  vi := 0;
  prop.ByteValueOf('DigicodeDecoderLevel', vi, 0);
  FDigicodeDecoder.Level := vi;
  prop.BooleanValueOf('VolcanoEntranceIsDone', FVolcanoEntranceIsDone, False);
end;

{ TMountainPeakDescriptor }

function TMountainPeakDescriptor.GetHelpText: string;
begin
  Result := SMountainPeakHelpText;
end;

constructor TMountainPeakDescriptor.Create;
begin
  inherited Create(MountainPeaksStepCount);
  FZipLine := TMountainPeakZipLine.Create(ZipLineMaxLevel, atoiBuy);
end;

destructor TMountainPeakDescriptor.Destroy;
begin
  FreeAndNil(FZipLine);
  inherited Destroy;
end;

function TMountainPeakDescriptor.SaveToString: string;
var prop: TProperties;
begin
  prop.Init('!');
  SaveCommonProperties(prop);
  prop.Add('ZipLineLevel', ZipLine.Level);
  Result := prop.PackedProperty;
end;

procedure TMountainPeakDescriptor.LoadFromString(const s: string);
var prop: TProperties;
  vb: byte;
begin
  prop.Split(s, '!');
  LoadCommonProperties(prop);
  vb := 0;
  prop.ByteValueOf('ZipLineLevel', vb, 0); FZipLine.Level := vb;
end;

{ TForestDescriptor }

function TForestDescriptor.GetHelpText: string;
begin
  Result := SForestHelpText;
end;

constructor TForestDescriptor.Create;
begin
  inherited Create(ForestStepCount);
  FBow := TForestBow.Create(BowMaxLevel, atoiBuy);
  FBow.Level := 1;
  FElevator := TForestElevator.Create(ElevatorMaxLevel, atoiBuy);
  FElevator.Level := 1;
  FHammer := TForestHammer.Create(HammerMaxLevel, atoiBuy);
  FStormCloud := TForestStormCloud.Create(StormCloudMaxLevel, atoiBuy);
end;

destructor TForestDescriptor.Destroy;
begin
  FreeAndNil(FBow);
  FreeAndNil(FElevator);
  FreeAndNil(FHammer);
  FreeAndNil(FStormCloud);
  inherited Destroy;
end;

function TForestDescriptor.SaveToString: string;
var prop: TProperties;
begin
  prop.Init('!');
  SaveCommonProperties(prop);
  prop.Add('ElevatorLevel', FElevator.Level);
  prop.Add('BowLevel', FBow.Level);
  prop.Add('HammerLevel', FHammer.Level);
  prop.Add('StormCloudLevel', FStormCloud.Level);
  Result := prop.PackedProperty;
end;

procedure TForestDescriptor.LoadFromString(const s: string);
var prop: TProperties;
  vb: byte;
begin
  prop.Split(s, '!');
  LoadCommonProperties(prop);
  vb := 0;
  prop.ByteValueOf('ElevatorLevel', vb, 1); FElevator.Level := vb;
  prop.ByteValueOf('BowLevel', vb, 1); FBow.Level := vb;
  prop.ByteValueOf('HammerLevel', vb, 0); FHammer.Level := vb;
  prop.ByteValueOf('StormCloudLevel', vb, 0); FStormCloud.Level := vb;
end;

{ TGameDescriptor }

function TGameDescriptor.GetFirstTimeTerminated: boolean;
begin
  Result := FFirstTimeTerminated;
  FFirstTimeTerminated := False;
end;

procedure TGameDescriptor.SaveCommonProperties(var aProp: TProperties);
begin
  aProp.Add('CurrentStep', CurrentStep);
  aProp.Add('IsTerminated', IsTerminated);
end;

procedure TGameDescriptor.LoadCommonProperties(const aProp: TProperties);
begin
  aProp.IntegerValueOf('CurrentStep', FCurrentStep, 1);
  aProp.BooleanValueOf('IsTerminated', FIsTerminated, False);
end;

constructor TGameDescriptor.Create(aStepCount: integer);
begin
  FCurrentStep := 1;
  FStepCount := aStepCount;
end;

procedure TGameDescriptor.IncCurrentStep;
begin
  if FIsTerminated then exit;
  if StepPlayed <> FCurrentStep then exit;
  //if FCurrentStep < FStepCount then inc(FCurrentStep);

  inc(FCurrentStep);
  if FCurrentStep = FStepCount+1 then FIsTerminated := True;
  FFirstTimeTerminated := FIsTerminated;
end;

{ TPlayerInfo }

constructor TPlayerInfo.Create;
begin
  FForest := TForestDescriptor.Create;
  FMountainPeak := TMountainPeakDescriptor.Create;
  FVolcano := TVolcanoDescriptor.Create;
end;

destructor TPlayerInfo.Destroy;
begin
  FreeAndNil(FForest);
  FreeAndNil(FMountainPeak);
  FreeAndNil(FVolcano);
  inherited Destroy;
end;

function TPlayerInfo.SaveToString: string;
var prop: TProperties;
begin
  prop.Init('#');
  prop.Add('Name', Name);
  prop.Add('CoinCount', FCoinCount);
  prop.Add('PurpleCristalCount', FPurpleCristalCount);
  prop.Add('Forest', Forest.SaveToString);
  prop.Add('MountainPeak', MountainPeak.SaveToString);
  prop.Add('Volcano', Volcano.SaveToString);
  Result := prop.PackedProperty;
end;

procedure TPlayerInfo.LoadFromString(const s: string);
var prop: TProperties;
  st: string;
begin
  prop.Split(s, '#');
  prop.StringValueOf('Name', FName, 'Player');
  prop.IntegerValueOf('CoinCount', FCoinCount, 0);
  prop.IntegerValueOf('PurpleCristalCount', FPurpleCristalCount, 0);
  st := '';
  prop.StringValueOf('Forest', st, '');
  Forest.LoadFromString(st);
  prop.StringValueOf('MountainPeak', st, '');
  MountainPeak.LoadFromString(st);
  prop.StringValueOf('Volcano', st, '');
  Volcano.LoadFromString(st);

end;

{ TSaveGame }

procedure TSaveGame.SavePlayersTo(t: TStringList);
var prop: TProperties;
  i: integer;
begin
  prop.Init('|');
  prop.Add('Count', Length(FPlayers));
  for i:=0 to High(FPlayers) do
    prop.Add('Player'+i.ToString, FPlayers[i].SaveToString);

  t.Add('[PLAYERS]');
  t.Add(prop.PackedProperty);
end;

procedure TSaveGame.LoadPlayersFrom(t: TStringList);
var prop: TProperties;
  i, c: integer;
  s: string;
  o: TPlayerInfo;
begin
  FPlayers := NIL;
  if not prop.SplitFrom(t, '[PLAYERS]', '|') then exit;

  c := 0;
  prop.IntegerValueOf('Count', c, c);
  if c = 0 then exit;
  SetLength(FPlayers, c);
  for i:=0 to c-1 do begin
    o := TPlayerInfo.Create;
    FPlayers[i] := o;
    s  := '';
    if prop.StringValueOf('Player'+i.ToString, s, 'Player'+(i+1).ToString) then
      o.LoadFromString(s);
  end;
end;

procedure TSaveGame.SetKeyAction1(AValue: byte);
begin
  if FKeyAction1 = AValue then Exit;
  FKeyAction1 := AValue;
  Save;
  u_common.KeyAction1 := AVAlue;
end;

procedure TSaveGame.SetKeyAction2(AValue: byte);
begin
  if FKeyAction2 = AValue then Exit;
  FKeyAction2 := AValue;
  Save;
  u_common.KeyAction2 := AVAlue;
end;

procedure TSaveGame.SetKeyDown(AValue: byte);
begin
  if FKeyDown = AValue then Exit;
  FKeyDown := AValue;
  Save;
  u_common.KeyDown := AVAlue;
end;

procedure TSaveGame.SetKeyLeft(AValue: byte);
begin
  if FKeyLeft = AValue then Exit;
  FKeyLeft := AValue;
  Save;
  u_common.KeyLeft := AVAlue;
end;

procedure TSaveGame.SetKeyPause(AValue: byte);
begin
  if FKeyPause = AValue then Exit;
  FKeyPause := AValue;
  Save;
  u_common.KeyPause := AValue;
end;

procedure TSaveGame.SetKeyUp(AValue: byte);
begin
  if FKeyUp = AValue then Exit;
  FKeyUp := AValue;
  Save;
  u_common.KeyUp := AVAlue;
end;

procedure TSaveGame.SetKeyRight(AValue: byte);
begin
  if FKeyRight = AValue then Exit;
  FKeyRight := AValue;
  Save;
  u_common.KeyRight := AVAlue;
end;

procedure TSaveGame.SetLanguage(AValue: string);
begin
  FLanguage := AValue;
  AppLang.UseLanguage(FLanguage, LanguageFolder);
end;

procedure TSaveGame.SetMusicVolume(AValue: single);
begin
  if FMusicVolume = AValue then Exit;
  FMusicVolume := AValue;
end;

procedure TSaveGame.SetSoundVolume(AValue: single);
begin
  if FSoundVolume = AValue then Exit;
  FSoundVolume := AValue;
end;

constructor TSaveGame.Create;
begin
  inherited CreateFolder('LuluGame');
  FLanguage := 'en';
end;

destructor TSaveGame.Destroy;
var i: integer;
begin
  for i:=0 to High(FPlayers) do
    FPlayers[i].Free;
  inherited Destroy;
end;

procedure TSaveGame.Save;
var t: TStringList;
  prop: TProperties;
begin
  t := TStringList.Create;
  try
    // players
    SavePlayersTo(t);
    // language
    prop.Init('|');
    prop.Add('USE', FLanguage);
    t.Add('[LANGUAGE]');
    t.Add(prop.PackedProperty);
    // audio pref
    prop.Init('|');
    prop.Add('MusicVolume', FMusicVolume);
    prop.Add('SoundVolume', FSoundVolume);
    t.Add('[AUDIO]');
    t.Add(prop.PackedProperty);
    // keyboard pref
    prop.Init('|');
    prop.Add('KeyLeft', FKeyLeft);
    prop.Add('KeyRight', FKeyRight);
    prop.Add('KeyUp', FKeyUp);
    prop.Add('KeyDown', FKeyDown);
    prop.Add('KeyAction1', FKeyAction1);
    prop.Add('KeyAction2', FKeyAction2);
    prop.Add('KeyPause', FKeyPause);
    t.Add('[KEYBOARD]');
    t.Add(prop.PackedProperty);
    try
      t.SaveToFile(SaveFolder+'LittleRedRidingHood.sav');
    except
    end;
  finally
    t.Free;
  end;
end;

procedure TSaveGame.Load;
var t: TStringList;
  prop: TProperties;
  s: string;
begin
  FScene.LogInfo('Loading saved game');
  t := TStringList.Create;
  try
    try
      if FileExists(SaveFolder+'LittleRedRidingHood.sav') then
        t.LoadFromFile(SaveFolder+'LittleRedRidingHood.sav');

      LoadPlayersFrom(t);

      prop.SplitFrom(t, '[LANGUAGE]', '|');
      s := '';
      prop.StringValueOf('USE', s, 'en');
      Language := s;

      prop.SplitFrom(t, '[AUDIO]', '|');
      prop.SingleValueOf('MusicVolume', FMusicVolume, 0.5);
      prop.SingleValueOf('SoundVolume', FSoundVolume, 1.0);

      prop.SplitFrom(t, '[KEYBOARD]', '|');
      prop.ByteValueOf('KeyLeft', FKeyLeft, VK_LEFT);
      prop.ByteValueOf('KeyRight', FKeyRight, VK_RIGHT);
      prop.ByteValueOf('KeyUp', FKeyUp, VK_UP);
      prop.ByteValueOf('KeyDown', FKeyDown, VK_DOWN);
      prop.ByteValueOf('KeyAction1', FKeyAction1, VK_LCONTROL);
      prop.ByteValueOf('KeyAction2', FKeyAction2, VK_LSHIFT);
      prop.ByteValueOf('KeyPause', FKeyPause, VK_ESCAPE);

      u_common.KeyLeft := FKeyLeft; u_common.KeyRight := FKeyRight; u_common.KeyUp := FKeyUp;
      u_common.KeyDown := FKeyDown; u_common.KeyAction1 := FKeyAction1; u_common.KeyAction2 := FKeyAction2;
      u_common.KeyPause := FKeyPause;
    except
      on E: Exception do begin
        FScene.LogError('raise exception "'+E.Message+'"', 1);
      end;
    end;
  finally
    t.Free;
  end;
end;

procedure TSaveGame.CreateNewPlayer(const aPlayerName: string);
var i: SizeInt;
  newp: TPlayerInfo;
begin
  newp := TPlayerInfo.Create;
  newp.Name := aPlayerName;

  i := Length(FPlayers);
  SetLength(FPlayers, i+1);
  FPlayers[i] := newp;

  FCurrentPlayerIndex := i;
  Save;
  u_common.PlayerInfo := newp;
end;

procedure TSaveGame.DeletePlayer(aIndex: integer);
begin
  FPlayers[aIndex].Free;
  Delete(FPlayers, aIndex, 1);
  Save;
end;

function TSaveGame.GetPlayersInfo: TStringArray;
var i: integer;
begin
  Result := NIL;
  if Length(FPlayers) = 0 then exit;
  SetLength(Result, Length(FPlayers));
  for i:=0 to High(FPlayers) do
    Result[i] := FPlayers[i].Name;
end;

procedure TSaveGame.SetCurrentPlayerIndex(aIndex: integer);
begin
  FCurrentPlayerIndex := aIndex;
  u_common.PlayerInfo := CurrentPlayer;
end;

function TSaveGame.CurrentPlayer: TPlayerInfo;
begin
  if Length(FPlayers) > 0 then Result := FPlayers[FCurrentPlayerIndex]
    else Result := NIL;
end;

end.

