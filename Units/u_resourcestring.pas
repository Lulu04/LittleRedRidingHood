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

sThanks='Thank you for playing this game!'+LineEnding+LineEnding+
        'Participated in some way:';
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

sElevatorExplanation='a simple system for getting on and off';
sElevatorUpgradeHint='increase speed';
sHammerExplanation='the hammer to protect something';
sHammerUpgradeHint='increase number of uses';
sStormCloudExplanation='the lightning storm';
sStormCloudUpgradeHint='increase number of uses';

sZipLineHint='a useful zip-line to cross the mountain peaks';

sDecoderExplanation='a decoder to hack digicodes';
sDorsalThrusterExplanation='a dorsal thruster to fly in the air';

sLaserGunExplanation='a laser gun effective only against machines';

sPocketSubmarineExplanation='a submarine that can shrink to fit in a pocket';

// hints in the panel where player choose the step of the game
sImproveEquipment='upgrade your equipment in the workshop';
sRedoALevel='you can redo a level to earn the end bonus';
sIfYouHaveEnoughMoney='if you have enough money, maybe you''ll meet someone in the forest?';
sBuyEquipment='buy new equipment in the workshop';

sFirstCompleteForest='you must first complete the pine forest!';
sBuyZipLineFirst='you need to buy the zip line first!';
sFirstCompleteMountainPeaks='you must first complete the mountain peaks!';
sFirstCompleteVolcano='you must first complete Volcano!';
sFirstCompletePlainMoon='you must first complete Plain of the Sleeping Moon!';
sSorryNotYetAvailable='Sorry, this game is not yet available...';

SArcadeMode='ARCADE MODE';
SAdventureMode='ADVENTURE MODE';

// help text
SForestHelpText='Burst the balloons to prevent the wolves from climbing up.' + LineEnding +
                'Keep up the rhythm until the timer runs out.' + LineEnding +
                '↑↓ to move' + LineEnding +
                'ACTION1 : bow' + LineEnding +
                'ACTION2 : lightning storm';
SMountainPeakHelpText='Avoid rocks, collect bonuses.' + LineEnding +
                      'Brake at the end to earn the extra bonus.' + LineEnding +
                      '←→ : move' + LineEnding +
                      'ACTION1 : break';
SVolcanoEntranceHelpText='Use mouse and click objects on the screen';
sDontBeSpotted='Don''t be spotted!';
SVolcanoInnerHelpText='←→↑↓ to move' + LineEnding +
                      'ACTION1 : jump' + LineEnding +
                      'ACTION2 : use object';
SVolcanoDinoHelpText= '←→↑↓ to move' + LineEnding +
                      'ACTION1 : jump' + LineEnding +
                      'ACTION2 : use object';
sDinoRaceInstructions='Win the race against Dino !'+ LineEnding+
                      'Don''t forget to collect gas cans to refill the tank' + LineEnding +
                      '↑↓ : move up and down' + LineEnding +
                      'ACTION1 : speed up';
SPlainMoonHelpText='Blow up the robots as fast as you can' + LineEnding +
                   'Outside: ←→↑↓ to move, ACTION1 to jump, ACTION2 to fire' + LineEnding +
                   'Inside: use the mouse to target the robots, ACTION2 to fire';

sWolf='Wolf';
sAIvoice='AI voice';

// place names on the map and hints
sWorkShopHint='home, sweet home';
sPinForest='The pins forest';
sPinForestHint='beware the wolf!';
sMountainPeaks='Mountain peaks';
sMountainPeaksHint='if you''re afraid of heights, don''t go!';
sVolcano='Volcano';
sVolcanoHint='lava, it''s hot...';
sPlainOfSleepingMoon='The plain of the sleeping moon';
sPlainOfSleepingMoonHint='it is said that on full moon nights you can hear the train whistle...';
sMermaidsPort='The Mermaids port';
sMermaidsPortHint='don''t forget your swimsuit!';

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

// dialogs pine forest
sSomethingTellMeYouNeedMyHelp='Something tells me you need my help.';
sWhoAreYou='Who are you?';
SMyNameIsAmara='My name is Amara, and I''ve lived here for a very long time. Where are you going?';
sINeedToGetThroughThisForest='I need to get through this forest and the wolves want to stop me...';
sThenYouWillHaveToEquipBetter='Then you''ll have to equip yourself better than that: your bow won''t be enough!';
sProposeHammer='I''ve got just the thing for you: I''m offering you a rather special '+
               'hammer that will protect your elevator. If a wolf comes near it, '+
               'it''ll get a blow on the head! I''ll sell it to you for %d pieces. How about it?';
sSoHaveYouThoughtAboutHammer='So have you thought about it? Are you buying the hammer?';
sBuyTheHammer='Buy the hammer for %d coins?';
sSometimeItMissesTheMark='Sometimes it misses the mark, but overall it works pretty well. See you soon!';
sAsYouWishButIThink='As you wish, but I think we''ll see you soon hihihi!';

sWellDoneYouAreMakingGood='Well done, you''re making good progress!';
sIHaveGotSomethingElseThatMightHelp='I''ve got something else that might help: the lightning storm. '+
                                    'You''ll see, it''s much more effective than the hammer.';
sSoWhyDidYouSellMeTheHammer='So why did you sell me the hammer in the first place?';
sBusinessIsBusiness='Business is Business. Hihihi...';
sIAmSeriousTheLightning='I''m serious, the lightning storm is super effective, '+
                        'I guarantee it! What''s more, I''ll sell it to you for '+
                        'only %d coins. What do you think?';
sSoHaveYouThoughtAboutStormCloud='So have you thought about it? Are you buying the Storm Cloud?';
sBuyTheStormCloud='Buy the Storm Cloud for %d coins?';
sItsAGreatDeal='It''s a great deal!';
sBecauseYouHaveBoughtItems='Because you''ve bought items from me, you''re entitled to a free bonus: '+
                           'I''m giving you the power to teleport anywhere on the map simply by clicking '+
                           'on the place you want to go. Isn''t that nice?!';
sUhIAlreadyDid='Uh... I already did...';
sWellTmOff='Well, I''m off. Good luck in your adventures!';


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
sNowWeAreBuddyForLife='Now we''re buddies for life!';
sThankYouDino='Thank you, Dino. I''m glad to know you. I hope we''ll meet again.';
sIdLoveToYouCan='I''d love to! You can come and see me whenever you like.';
sMyFriendIWinTheRace='My friend, I won the race, and you... you won a hug!';
sHug='HUG !';
sNoComment='...no comment...';
sWouldYouLikeToTryAgain='Would you like to try again ?';

// dialogs Plain of the sleeping moon
sDriverVoice='Driver voice';
sWeHaveReachedFullSpeed='We''ve reached full speed. We''ll arrive in less than ten minutes.';
sAllRightWeWillBeOnTime='All right, we''ll be on time.';
sATrain='A train!?';
sIDontKnowWhereItsGoing='I don''t know where it''s going, but I have a feeling '+
                        'it''s going to bring me closer to Granny. No time to lose!';
sThereSomeoneOnMyTrain='There''s someone on my train!';
sYouWhatAreYouDoingOnMyTrain='You! What are you doing on my train?';
sIveComeForMyGrandMother='I''ve come for my grandmother, you''ve kidnapped her!... Where is she? Answer me!';
sRelaxIDontEvenKnown='Relax, I don''t even know what you''re talking about.';
sYouLying='You''re lying! I''m sure you know where she is!';
sOkOkYouLookSmart='Ok, ok... You look smart, I''ll give you a challenge.';
sTakeThis='Take this.';
sItsALaserGun='It''s a laser pistol, harmless against humans and wolves but highly effective against robots.';
sWhy='Why?';
sShhIfYouManage='Shhh... If you manage to blow up my robots hiding in the carriages before the journey''s over, I''ll help you.';
sYouWontBeAbleChangeCarriages='You won''t be able to change carriages until all the robots occupying them have been destroyed.';
sButWhatAboutYourRobots='What about your robots? Don''t you mind losing them?';
sOhDontWorryICanHave='Oh, don''t worry, I can have as many as I want!';
sSoAreYouIn='So, are you in?';
sIHaveNoChoice='I have no choice... I accept, but you have to help me afterwards, ok?';
sIAlwaysKeepMyWord='I always keep my word.';
sComeOnItsTime='Come on, it''s time to get started.';
sYouveGotExactly='You''ve got exactly %d seconds and there are %d carriages: '+
                        'if you succeed, join me on the locomotive. If you fail, '+
                        'you''ll be ejected from the train... Good luck!';
sIThinkIveBrokenANail='I think I''ve broken a nail...';
sHeyIDidIt='Hey! I did it!';
sIKnewYouCouldDoIt='I knew you could do it, congratulations!';
sLetsLookAtTheLandscape='Let''s look at the landscape for a moment, shall we?';
sAreYouGoingToHelpMeNow='Are you going to help me now?';
sYesAsIToldYouIAlways='Yes, as I told you, I always keep my word.';
sYourGrandmotherWasInvited='Your grandmother was invited by my parents.';
sInvitedYouTiedHer='Invited?! You tied her up and took her by force!';
sMyFatherWasInHurry='My father was in a hurry, and when he''s in a hurry, he ignores politeness...';
sWeirdWayOfInvitingPeople='Weird way of inviting people over... What''s the hurry? What''s going on?';
sIDontKnowAboutThatIDont='I don''t know about that. I don''t deal with my parents'' business.';
sIfYouWantToJoinYour='If you want to join your grandmother, you''ll have to go to the castle.';
sButHurryItsReallyUrgent='But hurry, it''s really urgent, I''ve rarely seen my parents so worried.';
sWillTheyLeaveTheCastle='Will they leave the castle?';
sYesThatsWhatIVaguelyHeard='Yes, that''s what I vaguely heard.';
sOkDoYouKnownWhereICanFindABoat='Ok... Do you know where I can find a boat?';
sNoIdeaYouAreSmart='No idea! You''re smart, you''ll find a way on your own.';
sWeArriveAtMermaidsPort='We arrive at Mermaids Port. No one must see you. '+
                        'As soon as the train stops, jump off and find a way to get to the island. Good luck!';
sThankYouForYourHelp='Thank you for your help.';


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
  SetLength(Result, 4);
  Result[0] := sImproveEquipment;
  Result[1] := sRedoALevel;
  Result[2] := sIfYouHaveEnoughMoney;
  Result[3] := sBuyEquipment;
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

