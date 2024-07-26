unit u_resourcestring;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

function TitleSmallPartCharSet: string;
function TitleBigPartCharSet: string;
function TitleButtonCharset: string;
function InGamePausePanelButtonCharSet: string;
function MapButtonCharset: string;
function FontNumberCharset: string;

function GameHints: TStringArray;

const SupportedLanguages: array[0..3] of string=(
        'English', 'en',
        'Français', 'fr'
      );

resourcestring

sTheNewStoryOf='the new story of';
sTheLittleRed='The Little Red';
sRidingHood='Riding Hood';
sNewGame='NEW GAME';
sContinueGame='CONTINUE GAME';
sOptions='OPTIONS';
sCredits='CREDITS';
sQuit='QUIT';

sThanks='Thank you for playing this game!';
sDevelopment='DEVELOPMENT';
sGraphics='GRAPHICS';
sMusics='MUSICS';
sSounds='SOUNDS';

SEnterYourName='ENTER YOUR NAME';
sStart='START';
sBack='BACK';
sOk='OK';
sClose='CLOSE';
sCancel='CANCEL';
sErase='ERASE';
sSpace='SPACE';

SChoosePlayer='CHOOSE PLAYER';
sDelete='DELETE';
sContinue='CONTINUE';

sMusicVolume='MUSIC VOLUME';
sSoundVolume='SOUND VOLUME';
sLanguage='LANGUAGE';
sKeyboard='KEYBOARD';
sHowToChangeKey='To change keys, click on the desired button then press the desired key';
sAction1='ACTION1';
sAction2='ACTION2';
sPAUSE='PAUSE';
sPressAKey='PRESS A KEY';

sWorkShop='Workshop';
sExit='EXIT';
sBuy='BUY';
sUpgrade='UPGRADE';
sBuild='BUILD';
sLevel='Level';
sMax='MAX';
sManufacturing='manufacturing';
sPrice='price';
sNextLevel='next level';

sLevelAchieved='Level completed';
sRemainTime='remain time';
sSmoothArrivalBonus='smooth arrival bonus';
sTotal='TOTAL';

sGamePaused='paused';
sResumeGame='RESUME GAME';
sBackToMap='BACK TO MAP';

sGetReady='GET READY';
sGo='GO';
sOutOfTime='OUT OF TIME';


// hints in the panel where player can upgrade an item (in workshop)
sBowExplanation='your bow';
sBowUpgradeHint='increase arrow speed, decrease bow reloading time';

sElevatorUpgradeHint='increase speed';
sHammerExplanation='the hammer to protect something';
sHammerUpgradeHint='increase number of uses';
sStormCloudExplanation='the lightning storm';
sStormCloudUpgradeHint='increase number of uses';

sZipLineHint='a useful zip-line to cross the mountain peaks';

sDecoderHint='a decoder to hack digicodes';    // keypads?

// hints in the panel where player choose the step of the game
sImproveEquipment='upgrade your equipment in the workshop';
sRedoALevel='you can redo a level to earn the end bonus';
sBuyEquipment='buy new equipment in the workshop';

sFirstCompleteForest='you must first complete the pine forest!';
sBuyZipLineFirst='you need to buy the zip line first!';
sFirstCompleteMountainPeaks='you must first complete the mountain peaks!';
sSorryNotYetAvailable='Sorry, this game is not yet available...';

SArcadeMode='ARCADE MODE';
SAdventureMode='ADVENTURE MODE';

// help text
SForestHelpText='UP/DOWN to move' + LineEnding +
                'ACTION1 : bow' + LineEnding +
                'ACTION2 : lightning storm';
SMountainPeakHelpText='LEFT/RIGHT to move' + LineEnding +
                      'ACTION1 : break';
SVolcanoEntranceHelpText='Use mouse and click objects on the screen';
SVolcanoInnerHelpText='LEFT/RIGHT/UP/DOWN to move';

sWolf='Wolf';

// dialogs volcano entrance
sVoiceFromTheCave='Voice from the cave';
sWolveHaveWalledUpCaveEntrance='The wolves have walled up the cave entrance... I''ve got to find a way in!';
sDamnACodedDoor='I don''t have the code to open this door...';
sIHaveToHide='I hear someone behind the door. quick! I have to hide!';
sAgain='AGAIN ?!!';
sErIHaveToGo='Er, I have to go';
sThisPlaceIsBeautiful='This place is beautiful.';
sNotWaiting='I''m not waiting for you, it''s going to be long';
sYouTakeAPlan='They look like manufacturing plans. You take one discreetly.';
sGoToWorkshopToExaminThePlan='I''ll take a look at this plan in the workshop and see what I can do with it. (cough)';
sMakeTheDecoderBefore='Now that I''ve got the plan, I need to build the decoder to open the door.';

implementation
uses OGLCScene;

function TitleSmallPartCharSet: string;
begin
  Result := AddToCharset('', sTheNewStoryOf);
end;

function TitleBigPartCharSet: string;
begin
 Result := AddToCharset('', [sTheLittleRed, sRidingHood]);
end;

function TitleButtonCharset: string;
begin
 Result := AddToCharset('', [sNewGame, sContinueGame, sOptions, sCredits, sQuit]);
end;

function InGamePausePanelButtonCharSet: string;
begin
Result := AddToCharset('', [sGamePaused, sResumeGame, sBackToMap]);
end;

function MapButtonCharset: string;
begin
  Result := AddToCharset('', [sBack, sGo, sWorkShop]);
end;

function FontNumberCharset: string;
begin
  Result := AddToCharset(' 0123456789:.x=', [sLevelAchieved, sTotal, sRemainTime, sSmoothArrivalBonus]);
end;

function GameHints: TStringArray;
begin
  Result := NIL;
  SetLength(Result, 3);
  Result[0] := sImproveEquipment;
  Result[1] := sRedoALevel;
  Result[2] := sBuyEquipment;
end;


end.

