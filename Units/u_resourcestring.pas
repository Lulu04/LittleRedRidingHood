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

function CorruptString(const s: string): string;

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

sYes='Yes';
sNo='No';


// hints in the panel where player can upgrade an item (in workshop)
sBowExplanation='your bow';
sBowUpgradeHint='increase arrow speed, decrease bow reloading time';

sElevatorUpgradeHint='increase speed';
sHammerExplanation='the hammer to protect something';
sHammerUpgradeHint='increase number of uses';
sStormCloudExplanation='the lightning storm';
sStormCloudUpgradeHint='increase number of uses';

sZipLineHint='a useful zip-line to cross the mountain peaks';

sDecoderHint='a decoder to hack digicodes';
sDorsalThrusterHint='a dorsal thruster to fly in the air';

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
SForestHelpText='Burst the balloons to prevent the wolves from climbing up.' + LineEnding +
                'Keep up the rhythm until the timer runs out.' + LineEnding +
                'UP/DOWN to move' + LineEnding +
                'ACTION1 : bow' + LineEnding +
                'ACTION2 : lightning storm';
SMountainPeakHelpText='Avoid rocks, collect bonuses.' + LineEnding +
                      'Brake at the end to earn the extra bonus.' + LineEnding +
                      'LEFT/RIGHT : move' + LineEnding +
                      'ACTION1 : break';
SVolcanoEntranceHelpText='Use mouse and click objects on the screen';
sDontBeSpotted='Don''t be spotted!';
SVolcanoInnerHelpText='LEFT/RIGHT/UP/DOWN to move' + LineEnding +
                      'ACTION1 : jump' + LineEnding +
                      'ACTION2 : use object';
SVolcanoDinoHelpText= 'LEFT/RIGHT/UP/DOWN to move' + LineEnding +
                      'ACTION1 : jump' + LineEnding +
                      'ACTION2 : use object';
sDinoRaceInstructions='Win the race against Dino !'+ LineEnding+
                      'Don''t forget to collect gas cans to refill the tank' + LineEnding +
                      'UP/DOWN : move up and down' + LineEnding +
                      'ACTION1 : speed up';

sWolf='Wolf';
sAIvoice='AI voice';

// dialogs intro
sGranny='Granny';
sSmellGood='Mmm... that smells good!';
sItsAlmostReady='It''s almost ready, we''re going to have a great meal.';
sWhenGrandFatherWasHere='When your grandpa was still around, we often had barbecues; he loved that!';
sYesIRememberWell='Yes, I remember well, he always took his guitar and played music for us.';
sAndYouWereSinging='And you sang at the top of your lungs! Hahaha!';
sHaHaHa='Hahahaha!';
sItsAlreadybeenFiveYears='It’s already been 5 years since he left us...';
sYesTimePasses='Yes... Time flies. I miss him...';
sIMissHimToo='I miss him too...';
sWouldYouLikeToPickSomeFlowers='Would you mind picking a few flowers to decorate the table?';
sWillGoRightNow='I''ll go right now, Granny!';
sILoveCommingToSee='I love coming to see Granny...';
sIPromiseToTakeGoodCare='I promise to take good care of her when she gets older!';
sAhhhh='Ahhhhh!';
sGrannyAsk='Granny??';
sHey='Hey!!';

// dialogs volcano entrance
sWolfInTheCave='Wolf in the cave';
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

// dialogs volcano inner
sWowAMachineThatBuildsRobots='Wow! A machine that builds robots!';
sAndTheyUseVolcanoLavaAsRawMaterial='And they use the volcano''s lava as a raw material...';
sWolvesAreDefinitelyResourceFul='Wolves are definitely resourceful!';
sIWonderWhatAllTheseRobotsAreFor='I wonder what all these robots are for... Knowing wolves, certainly not to help mankind...';
sIHaveGotToFindAWayToStopThisMachine='I''ve got to find a way to stop this machine!';
sThisCrateIsLockedINeedAKeyToOpenIt='This crate is locked, I need a key to open it.';
sAnSDCardIWillTakeIt='an SD card... I''ll take it, it might come in handy.';
sADorsalPropulsorINeedIt='A dorsal propulsor! No way I''m leaving this here!';
sBeforeILeaveIHaveToSearchAllCratesInTheArea='Before I leave, I have to search all the crates in the area.';
sIWonderWhatTheDigicodeIsFor='I wonder what the digicode is for...';
sLetTryHackingItAndSeeWhatHappens='Let''s try hacking it and see what happens.';
sSystemIntrusionAlert='SYSTEM INTRUSION ALERT!';
sSystemMalfunctionDueToHacking='MALFUNCTION DUE TO HACKING';
sAICorrupted='AI corrupted';
sMachineIsNotInRightAxis='Problem detected: machine is not in its axis';
sRapidReturnToTheAxis='Remedy: rapid return to the axis';
sNewAttempt='New attempt';
sProblemSolved='Problem solved';
sSlowerRobotProduction='New problem detected: slower robot production';
sPossibleCauseLackOfLava='Possible cause: lack of lava';
RemedyPumpAtMaxi='Remedy: pump acceleration at maximum level';
sProblemSolvedButEvacuate='Problem solved, however it is advisable to evacuate urgently';
sDeploymentOfEmergencyExit='Deployment of emergency exit';
sIBetterLeaveThisPlaceQuickly='What a mess!'+LineEnding+'I''d better leave this place quickly...';
sFunnyRunAway='Run away, quickly!'+LineEnding+'And don''t forget to pack warm socks';
sFunnyAtTheCanteen='Spinach in the canteen this lunchtime';
sSpinachIsGoodForYourHealth='Spinach are good for your health';
sToMuchLavaIsBadForYourHealth='Too much lava is not good for your health';

// dialogs volcano dino
sThisComputerHaveSDCardReader='This computer has an SD card reader, so I''ll be able to read the contents of the one I''ve found.';
sConversation='conversation';
sRomeo1='My dear Julia, I hope you’re doing well. This SD card is the key to unlocking the big armored door in the basement. It will help you get out of here in case the volcano becomes too unstable. I’m not allowed to give it to you, so I’ve hidden it in a way that you can easily find it. I don’t want anything to happen to you; you mean a lot to me, you’re the love of my life!';
sJulia1='My dear Romeo, thank you a thousand times! I made a copy of the SD card and I’m using it to reply to you. Ever since I read your message, I’ve been doing great. I care about you a lot too, and I can’t wait for us to be together again. I really hope that happens soon!';
sRomeo2='Oh my love, I’m so happy you replied! I can’t wait for us to be together again either, but I have to be careful, the boss is watching me closely. He says I’m daydreaming... It’s because I can’t stop thinking about you!';
sJulia2='Romeo, my darling, be careful. I’m only thinking about you too. At the lab, my boss also says I’m daydreaming... Yesterday he asked me to serve him coffee, and instead, I poured the contents of the test tube with the dinosaur droppings into his cup!';
sOpenArmouredDoor='Open armoured door';
sFail='FAIL';
sOpenCage='Open cage';
sFailToOpenDoorTryToOpenCage='Failed to open the door. I''ll open the cage, so I''ll still have opened something...';
SDinoWantHug='Oh, a friend! You freed me from this cage, I''m going to jump into your arms and give you a hug!';
sJumpInMyArmGiveMeHug='Jump in my arms ?! A hug ?!';
sYesItsEasyIJumpInYourArms='Yees! Now you are my friend and I want to give you a big hug!';
sItsHugIsTooHeavyForMe='His hug might be too weighing for me... I think it''s time to try the dorsal thruster!';
sGreatNowICanPass='Great! Now I can pass!';
sWantToRaceWithMe='Me too! Want to race with me? The first to arrive gives the other a hug, right?';
sWouldYouLikeToSeeDinoReleaseSceneAgain='Would you like to see Dino''s release scene again?';
sYouWin='YOU WIN';
sYouLose='YOU LOST';
sOutOfGas='OUT OF GAS';
sMyFriendYouWinTheRace='My friend, you won the race, and me... I won a hug!';
sMyFriendIWinTheRace='My friend, I won the race, and you... you won a hug!';
sHug='HUG !';
sNoComment='...no comment...';
sWouldYouLikeToTryAgain='Would you like to try again ?';

implementation
uses OGLCScene, LazUTF8;

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

function CorruptString(const s: string): string;
var count, chunkLen, i, j: integer;
const corruptChar: array[0..3] of char=('%','$','#','*');
begin
  chunkLen := 10;
  if chunkLen > UTF8Length(s) then chunkLen := UTF8Length(s);

  count := UTF8Length(s) div chunkLen;
  if count = 0 then count := 1;

  j := random(chunkLen)+1;
  Result := '';
  for i:=1 to UTF8Length(s) do begin
    if i mod chunkLen = 0 then  j := random(chunkLen)+1 + i;

    Result := Result + UTF8Copy(s, i, 1);
    if i = j then Result := Result + corruptChar[random(4)];
  end;
end;


end.

