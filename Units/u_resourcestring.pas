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
sLoading='LOADING...';

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
sBackToSam='BACK TO SAM';
sInstructions='HOW TO PLAY';

sGetReady='GET READY';
sGo='GO';
sOutOfTime='OUT OF TIME';

sConnected='CONNECTED';

sTurn='Turn %d/%d';

sYes='Yes';
sNo='No';

//sLetsGo='Let''s go!';
sFatherOfWolfs='Father of wolfs';
sMotherOfWolfs='Mother of wolfs';


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

sCraneRemoteControlExplanation='a crane remote control';
sPocketSubmarineExplanation='a yellow submarine!';

sFirstCompleteForest='you must first complete the pine forest!';
sBuyZipLineFirst='you need to buy the zip line first!';
sFirstCompleteMountainPeaks='you must first complete the mountain peaks!';
sFirstCompleteVolcano='you must first complete the Volcano!';
sFirstCompletePlainMoon='you must first complete the Plain of the Sleeping Moon!';
sFirstCompleteMermaidsPort='you must first complete the Mermaids Port!';
sFirstCompleteSnakeFissure='you must first complete the Snake Fissure!';
sFirstCompleteWolfCastle='you must first complete the Wolf Castle!';
sSorryNotYetAvailable='Sorry, this game is not yet available...';

//SArcadeMode='ARCADE MODE';
//SAdventureMode='ADVENTURE MODE';

// help text and step info
sForestStepInfo1='upgrade your equipment in the workshop';
sForestStepInfo2='you can redo a level to earn the end bonus';
sForestStepInfo3='buy new equipment in the workshop';
SForestHelpText='Burst the balloons to prevent the wolves from climbing up.' + LineEnding +
                'Keep up the rhythm until the timer runs out.' + LineEnding +
                '↑↓ to move' + LineEnding +
                'ACTION1 : bow' + LineEnding +
                'ACTION2 : lightning storm';

SMountainPeakStepInfo1='Hang in there!';
SMountainPeakStepInfo5='The last one! Keep going!';
SMountainPeakHelpText='Finish the course before time runs out.' + LineEnding +
                      'Avoid rocks, collect bonuses.' + LineEnding +
                      'Brake at the end to earn the extra bonus.';
SMountainPeakHelpKeys='←→ : move' + LineEnding +
                      'ACTION1 : break';

SVolcanoEntranceHelpText='Use mouse and click objects on the screen';
sVolcanoStepInfo1='What is that?';
sDontBeSpotted='Don''t be spotted!';
sVolcanoStepInfo2='The Awakening of Volcano';
sVolcanoStepInfo3='Who is Dino?';
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

sPlainMoonStepInfo1='The encounter';
SPlainMoonHelpText='Destroy the robots as fast as you can';
SPlainMoonHelpKeys='Outside: ←→↑↓ to move, ACTION1 to jump, ACTION2 to fire' + LineEnding +
                   'Inside: use the mouse to target the robots, ACTION2 to fire';

sMermaidsPortHelpText='Crosses the factories to reach the sea.';
sMermaidsPortHelpKeys='←→↑↓ to move' + LineEnding +
                      'ACTION1 : jump' + LineEnding +
                      'ACTION2 : use object';
sMermaidsPortHelpText2='When you jump on a container, the remote control'+ LineEnding +
                       'automatically connects to it'+ LineEnding +
                       'Hold down ACTION2 and use ←→↑↓ to move it.';
sMermaidBossInstructions='Finds the right strategy to beat Marcus at his game'+ LineEnding +
                         '←→↑↓ to move' + LineEnding +
                         'ACTION1 : to shoot' + LineEnding +
                         'ACTION2 : defensive position';

sSnakeFissureStepInfo1='A way to cross the sea';
sSnakeFissureInstructions='Use the submarine capabilities to cross the fissure' + LineEnding +
                          'Avoids contact with mines, they are fatals!' + LineEnding +
                          'Warning: each action consumes blue crystals!' + LineEnding +
                          '←→↑↓ : move the submarine' + LineEnding +
                          'MOUSE to press the buttons on dashboard';

sInSpaceStepinfo1='First briefing in space';
sInSpaceStepinfo2='A docking bay and a mining ship';
sInSpaceStepinfo3='Arrival at the asteroid belt';
sInSpaceStepinfo4='A probe to analyse the gate';
sInSpaceStepinfo5='Shield construction';
sInSpaceStepinfo6='Ore for a combat ship';
sInSpaceStepinfo7='Construction of the combat ship';
sInSpaceStepinfo8='A new problem...';
sInSpaceStepinfo9='Battle against the meteor storm';
sInSpaceStepinfo10='A strange coincidence';
sInSpaceStepinfo11='Ore for the Gigatron and Radiation Annihilator';
sInSpaceStepinfo12='Construction of the Gigatron and Radiation Annihilator';
sInSpaceStepinfo13='The big jump!';

sConstructionExplanation='Use the mouse to click the item asked by Marcus' + LineEnding +
                         'Hurry, or the fusion of the elements will fail!';

sStrikeRaccoonInstructions='←→↑↓ to target'+ LineEnding +
                           'ACTION1 : to strike';
sDartboardInstructions='←→ to move'+ LineEnding +
                       'ACTION1 : to fly';

sWolf='Wolf';
sAIvoice='AI voice';

// place names on the map and hints
sWorkShopHint='home, sweet home';
sSamsHut='Sam''s hut';
sSamsHutHint='item exchange and fun games';
sPinForest='The pins forest';
sPinForestHint='beware the wolf!';
sMountainPeaks='Mountain peaks';
sMountainPeaksHint='if you''re afraid of heights, don''t go!';
sVolcano='Volcano';
sVolcanoHint='lava, it''s hot...';
sPlainOfSleepingMoon='The plain of the sleeping moon';
sPlainOfSleepingMoonHint='it is said that on full moon nights you can hear the train whistle...';
sMermaidsPort='The Mermaids port';
sMermaidsPortHint='factories as far as the eye can see!';
sSnakeFissure='The Snake Fissure';
sSnakeFissureHint='don''t forget your swimsuit and buoy!';
sWolfCastle='The Wolf Castle';
sWolfCastleHint='will you dare to throw yourself into the wolf''s den?';
sInSpace='Into the depths of space...';

// challenge
sChallenge='CHALLENGE !';
sChallengeMode='Challenge mode';
sGameMode='Game mode';
sNoChallengeHere='no challenge here';
sYouveAlreadyWonThisChallenge='you''ve already won this challenge';
sFirstCompleteTheGameMode='first, complete the game mode';
sYouveWon='You''ve won!';
sForestChallengeHelpText='will you win this challenge?';
sFirstUpgradeToTheMaxTheBowElevator='to access the challenge, you must first, upgrade to the max the bow, the elevator, the hammer and the lightning storm';
sMountainPeaksChallengeHelpText='complete the course with the smooth arrival bonus';
sVolcanoChallengeHelpText='win the race versus Dino';
sPlainOfSleepingMoonChallengeHelpText='destroy the robots and get to the locomotive in time';

// dialogs intro
sGranny='Granny';
sSmellGood='Mmm... that smells good!';
sItsAlmostReady='It''s almost ready, we''re going to have a great meal.';
sWhenGrandFatherWasHere='When your grandpa was still around, we often had barbecues; he loved that!';
sYesIRememberWell='Yes, I remember well, he always took his guitar and played music for us.';
sAndYouWereSinging='And you sang at the top of your lungs! Hahaha!';
sHaHaHa='Hahahaha!';
sItsAlreadybeenFiveYears='It''s already been 5 years since he left us...';
sYesTimePasses='Yes... Time flies. I miss him...';
sIMissHimToo='I miss him too...';
sWouldYouLikeToPickSomeFlowers='Would you mind picking a few flowers to decorate the table?';
sWillGoRightNow='I''ll go right now, Granny!';
sILoveCommingToSee='I love coming to see Granny...';
sIPromiseToTakeGoodCare='I promise to take good care of her when she gets older!';
sAhhhh='Ahhhhh!';
sGrannyAsk='Granny??';
sHey='Hey!!';

// dialogs Sam
sWelcomeToSam='Welcome to Sam''s!'+LineEnding+'Click on me for explanations';
sHereYouCanExchange='Here you can exchange your coins for certain items.';
sYouCanAlsoWinItems='You can also win coins or items by playing the games.';
sTheHigherYourScore='The higher your score, the more articles you earn!';
sHaveFun='Have fun!';
sScore='SCORE';
sYourScore='Your score: %d';
sSelectYourPrize='Select your prize';
sSamGiveYou='Sam gives you';
sExchange='EXCHANGE';
sFor='for'; // exchange

{
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
}

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
sRomeo1='My dear Julia, I hope you''re doing well. This SD card is the key to unlocking the big armored door in the basement. It will help you get out of here in case the volcano becomes too unstable. I''m not allowed to give it to you, so I''ve hidden it in a way that you can easily find it. I don''t want anything to happen to you; you mean a lot to me, you''re the love of my life!';
sJulia1='My dear Romeo, thank you a thousand times! I made a copy of the SD card and I''m using it to reply to you. Ever since I read your message, I''ve been doing great. I care about you a lot too, and I can''t wait for us to be together again. I really hope that happens soon!';
sRomeo2='Oh my love, I''m so happy you replied! I can''t wait for us to be together again either, but I have to be careful, the boss is watching me closely. He says I''m daydreaming... It''s because I can''t stop thinking about you!';
sJulia2='Romeo, my darling, be careful. I''m only thinking about you too. At the lab, my boss also says I''m daydreaming... Yesterday he asked me to serve him coffee, and instead, I poured the contents of the test tube with the dinosaur droppings into his cup!';
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

// dialogs Mermaids Port
sMarcusTransport='MARCUS TRANSPORT';
sStartSequence='Start sequence';
sItsTooDangerousIHaveToFind='It''s too dangerous. I have to find another way to cross.';
sSoundsLikeARemote='Sounds like a remote control. I should be able to control something with it.';
sINeedAKeyToOpenThisGate='I need a key to open this gate...';
sIHearVoices='I hear voices...';
sSomeoneHere='Someone''s here!';
sWhosThereShow='Who''s there? Show yourselves!';
sYouDontTellAnyone='You?! Uh... don''t tell anyone you saw us, okay?';
sErAllRightIWont='Er... All right. And you, don''t tell anyone you saw me, okay?';
sOkay='Okay...';
sWhyAreYouHiding='Why are you hiding?';
sTheCompanyWeWork='The company we work for prohibits romantic relationships between employees.';
sIfTheyFoundOutWed='If they found out, we''d be fired and have a hard time finding another job.';
sForbiddingPeopleToLove='Forbidding people to love each other... It''s a funny rule...';
sPerhapsThatWillChange='Perhaps that will change with time...';
sIHopeForYou='I hope for you.';
sWellGottaGo='Well... Gotta go. Bye!';
sBye='Bye';
sWouldYouLikeToSeeMarcus='Would you like to see Marcus'' meeting again?';
sMySisterWasRight='My sister was right, you''re very efficient!';
sImMarcus='I''m Marcus, Penelope''s brother, the one you met on the train. '+
                        'I know you''re looking for your grandmother.';
sIHaveToGetToTheIsland='I have to get to the island. Your sister told me I''d find a way '+
                        'to cross the sea over here.';
sOfCourseThereIsBut='Of course there is, but you have to earn it...';
sAreYouInTheHabit='Are you in the habit of asking before you give?';
sItsMoreFunThisWay='It''s more fun this way!';
sIKnowAGame='I know a game I love. If you beat me, I''ll give you a way to cross the sea.';
sPfffThatsNotFairplay='Pfff! That''s not fairplay, you''re certainly already trained, I''m not!';
sComeOnImSureWith='Come on... I''m sure with a little perseverance you''ll get there.';
sSeeTheseEggShaped='See these egg-shaped things? They''re robots that can be controlled from the inside.';
sRedIsForYou='Red is for you, black is for me. Whoever shoots the other first wins.';
sErIDontWantToEndMyLife='Er... I don''t want to end my life in a tin can!';
sDontBeAfraidYoureSafe='Don''t be afraid, you''re safe inside. Don''t move please.';
sCongratOnceAgain='Congratulations! Once again you''ve shown that you''re up to the task!';
sItWasFunny='It was funny!';
sIllHelpYouToo='I''ll help you too, you deserve it. Please follow me.';
sTakeThisTunnel='Take this tunnel, it will lead you to the seaside. '+
                'There you''ll find a vehicle to take you to the island.';

sFinally='Finally!';
sGoodLuckSeeYouSoon='Good luck, see you soon.';
sPfffHeCouldHave='Pfff, he could have dropped me off on the island!';

// dialogs Snake Fissure
sASubmarineIWasnt='A submarine? I wasn''t expecting that...';
sOkLetsGo='Ok... Let''s go!';
sHereTheresANoteOnThe='There''s a note on the dashboard. It says:'+LineEnding+
                '"This submarine will take you to the island. It runs with blue crystals, '+
                'but its reserve is small. If you try to cross directly, you''ll break down '+
                'in the middle of the sea. The only way is to go through the Snake''s Fissure: '+
                'there you''ll find crystals to refill your tank. '+
                'Don''t worry, there''s no snake - it''s the shape that gives it its name. '+
                'Good luck!"'+LineEnding+
                'Signed Marcus.';
sWellHowToStartIt='Well... How to start it?';
sHereThereIsAButton='Here! there''s a button marked Start';
sCool='Cool!';
sLetsTryDivingNow='Let''s try diving now...';
sOups='Oups...';
sNoTreePoint='No...';
sOutOfCristals='OUT OF CRISTAL!';

// dialogs Wolf Castle
sImFinallyOnTheIsland='I''m finally on the island!';
sLetsGoToTheCastle='Let''s go to the castle...';
sGrannyQuestion='Granny?';
sFinallyIFoundYou='I finally found you!';
sIKnewYouWouldMakeIt='%s, I knew you''d make it! I never stopped believing in you.';
sAreYouOkTheyDidnt='Are you okay?  They didn''t hurt you, did they?';
sNotAtAllEveryone='Not at all. Everyone here''s taken great care of me.';
sComeOnLetsGoMeetThem='Come on, let''s go, they''re waiting for us.';
sTheresNothingToFear='We are safe, I promise you.';
sWelcomePlayerTAmFather='Welcome %s. I am the Father of Wolves.';
sHelloPlayerMother='Hello %s. I am the Mother of Wolves. Behind me are our daughter Penelope, '+
                'and our son Marcus whom you''ve already met.';
sHiButImNotSure='Hi, but, um... I''m not really sure what''s going on here...';
sYoureOwedSomeExplanations='You''re owed some explanations...';
sTheSituationIsDire='The situation is dire... Something is disturbing the balance of the universe. '+
                'We don''t fully understand the consequences yet, but life on Earth is being deeply '+
                'affected: climate change, natural disasters, rising aggression between nations, '+
                'greed for power and wealth...';
sYouOnlyNeedToTurnOn='You only need to turn on the TV to see that all of this is, sadly, real.';
sOurResearchShows='Our research shows that these disruptions will soon spiral out of control.';
sAnAncientManuscript='An ancient manuscript we''ve had for a long time explains that the only way '+
                'to understand what''s happening is to travel to the center of the universe. '+
                'There, we may encounter the Original Force that creates worlds. If this entity '+
                'truly exists, it can help us to find a solution.';
sTheBookAlsoSays='The manuscript also says only a pure soul can make the journey. That''s why we chose you.';
sMeWhyNotOneOfYou='Me? Why not one of you?';
sWeRunFactories='We run factories.';
sWeMakeMoney='We make money.';
sWeLikeBeeingInCharge='We like being in charge!';
sAsYouCanSeeWere='As you can see, we''re too entangled in the world''s affairs to be considered innocent.';
sWeKidnappedYour='We kidnapped your grandmother so you would come here. '+
                'We figured you wouldn''t believe us otherwise.';
sYouMeanThisWas='You mean... this was all planned?';
sInAWayYes='In a way, yes. Your innocence alone wasn''t enough. You needed proper training '+
                'to have any chance of succeeding in your mission.';
sThanksToUsYouLearned='Thanks to us, you learned how to shoot a bow and a laser pistol!';
sYouOvercameYourFear='You overcame your fear of heights with the zipline.';
sYouLearnedToMove='You learned to move unnoticed.';
sAndYouShowedCourage='And you showed courage in every challenge!';
sSoLetMeGetThisStraight='So, let me get this straight. You kidnapped my grandmother, '+
                'except it wasn''t really a kidnapping. And by trying to save her, I went through '+
                'all these crazy events… which just so happened to train me… all so I can go meet '+
                'some unknown creature at the center of the universe, that might not even exist?! '+
                'And you expect me to believe all this?';
sYouHaveToYoure='You have to. You''re our only hope. If we do nothing, the world is doomed...';
sThereIsntMuchTime='There isn''t much time left. It''s a long journey.';
sPlayerIveBeenTreated='%s, I''ve been treated well. We can trust them.';
sWellIveComeThisFar='Well, I''ve come this far...';
sOkIllDoItIllGo='Okay. I''ll do it. I''ll go meet this creature. But... on one condition!';
sWhatCondition='What condition?';
sIllGoIfYouLiftTheBan='I''ll go if you lift the ban on romantic relationships '+
                'between employees in your company!';
sWhatQuestionExclamation='What?!';
sBanningPeople='Banning people from loving each other… It''s ridiculous! And why? For productivity?';
sThatsANobleRequest='That''s a noble request. It clearly shows how different you are from us.';
sYourRequestIsGranted='Your request is granted.';
sW7Question='W7?';
sYesSirQuestion='Yes, sir?';
sYouHeardThatUpdate='You heard that? Update the employee policy, remove that rule, and notify everyone.';
sDoneSir='Done, sir.';
sTheyCertainlyDidntWaste='They certainly didn''t waste any time...';
sPlayerAnythingElse='%s, anything else?';
sNoThankYou='No. Thank you.';
sThenLetsSummonTheTransporter='Then let''s summon the transporter and begin the journey.';
sTransporterIsOnItsWay='Transporter WK510 is on its way. Landing in just a few seconds.';

// briefing 1: departure to the asteroid belt
sHereWeAreInOrbit='Here we are, in orbit around our beautiful planet.';
sItsBreathtaking='It''s breathtaking!';
sTheOldBookSpeaksOfAPortal='The old manuscript speaks of a port, one that can open the way to intergalactic travel.';
sAccordingToOurResearch='According to our research, it should be just beyond the asteroid belt.';
sPSetACourse='Penelope, set a course for the coordinates please.';
sOnIt='On it!';
sWaitFatherYouKnown='Wait, Father! You know we can''t make it through that zone. '+
                    'This ship is way too big. One step inside and we''ll be shredded to pieces!';
sAndThatsOnlyProblem='And that''s only the first problem . Problem number two: we''re not even '+
                    'remotely equipped for intergalactic travel. Even if we find the portal, '+
                    'we don''t have the right drive system, and the radiation would fry us in seconds...';
sYoureBothRight='You''re both right. Two huge problems... but both can be solved, '+
                    'thanks to that asteroid belt.';
sSolvedHow='Solved? How exactly?';
sThoseRocksAreLoaded='Those rocks are loaded with all kinds of rare ores. '+
                    'If we can mine them, we''ll have the resources to upgrade the ship.';
sAndHowAreWeSupposed='And how are we supposed to mine anything without a mining vessel?';
sPCarryingaWhole='Penelope''s carrying a whole army of little robots onboard. '+
                 'We could salvage a few and turn them into a mining ship.';
sWedStillNeedADocking='We''d still need a docking bay so the mining vessel can take off and land.';
sExactlyHereThePlan='Exactly. Here''s the plan: Penelope, gather the materials we need. '+
                 '%s and Marcus, you handle building the docking bay first, then the mining ship.';
sWeWillRegroupFor='We''ll regroup for a debrief when we''re near the asteroid belt.';
sGotItComeOnM='Got it. Come on, Marcus, let''s get to work!';

// construction of the docking bay
sConsDockBay='Construction of the docking bay, step %d of %d';
sConsMiningShip='Construction of the mining ship, step %d of %d';
sOkLetsFocusAndGetBack='Okay... let''s focus and get back to it!';
sGreatLetsAssembleBay='Great! Let''s install the docking bay.';
sNowLetsMoveOnToThe='Now let''s move on to the construction of the mining ship.';
sThereWeGoWeHaveAll='There we go, we have all the parts of the mining ship. '+
                    'Let''s assemble them and then test it out!';


// briefing 2: a probe near the gate
sTheDockingBayAndThe='The docking bay and the ship are fully operational.';
sExcellentExclamation='Perfect!';
sWereApproachingThe='We''re approaching the asteroid belt.';
sThatsItWeCantGoAny='That''s it... we can''t go any further than this.';
sUnderstoodWellDeploy='Alright. We''ll deploy a research probe as close as possible '+
                      'to the intergalactic gate.';
sPYourJobWillBe='Penelope, your job will be to gather the probe''s data as soon as it''s in position '+
                'and with W7''s help, you''ll attempt to uncover its secrets.';
sWeNeedNewTechToBuid='We need new technologies to build an interstellar jump drive '+
                      'and a radiation shield strong enough to protect us.';
sIllDoMyBest='I''ll do my best.';
sMYouWillOverseeThe='Marcus, you''ll oversee the construction unit. Prepare the raw material '+
                    'stockpiles for the tech Penelope discovers, and handle the incoming ore.';
sYesFather='Yes father.';
sAndFinallyIfYoureUp='And finally, %s if you''re up for it, you''ll pilot the mining vessel.';
sAwesomeImIn='Awesome! I''m in!';
sItsGoingToBeDangerous='It''s going to be dangerous.';
sDontWorryGIllBe='Don''t worry, Granny. I''ll be extra careful.';
sYourFirstObjective='Your first objective is to navigate through the asteroid belt '+
                    'and deploy the probe as close to the gate as you can.';
sOnceThatDoneYoull='Once that''s done, you''ll collect whatever ore Penelope or Marcus request.';
sGotIt='Got it.';
sAnyQuestions='Any questions?';
sNoQuestionThen='No questions? Then... everyone to your stations!';
sITrustYouChildren='I trust you, children.';


// dialogs step4: deploy the probe near the gate
sWeHaveAttachedThe='We have attached the search probe to your ship. I am sending you the coordinates of the portal.';
sDoneTheBlueSymbol='Done. The blue symbol on your radar shows its direction.'+LineEnding+
                   'The asteroids are too numerous to be displayed, '+
                   'they would prevent you from seeing the other objects.';
sTheAsteroidsAreTooNumerous='The asteroids are too numerous to be displayed, '+
                            'they would prevent you from seeing the other objects.';
sImCancelingTheDropTooFar='I''m canceling the drop, you''re too far from the gate...';
sImCancelingTheDropOutside='I''m canceling the drop. The probe must be dropped outside the gate.';
sTheProbeHasJustSent='The probe has just sent its first data, good job %s!';
sApparentlyTheGateIsEquipped='Apparently, the portal is equipped with a protective shield against '+
                            'meteorite impacts. To adapt this technology to the mother ship, I need '+
                            '3T of neodymium, 1T of gold and 2T of praseodymium. '+
                            'I send you the coordinates of the asteroids that contain them.';
sWellDoneYouCanReturn='Well done! You can return to the mother ship now.';
sIllBeAbleToDrawUp='I''ll be able to draw up a manufacturing plan for the shield.';
sToEnterTheDockCircleAround='To enter the docking bay, circle around the mothership from behind, '+
                            'align your ship with the center of the bay, and move forward at low speed.';

// dialogs step5: constructing the shield
sThisFirstMissionIntoSpace='This first mission into space is a success!';
sPHasDrawnUpThePlans='Penelope has drawn up the plans for a protective shield. We can build it.';
sConsShield='Construction of the shield, step %d of %d';
sWeGotAllTheComponentForTheShield='We''ve got all the components for the shield. Let''s install and test it!';
sPStillNeedsOre='Penelope still needs ore. Apparently, another mission awaits you. I''m preparing for your takeoff!';

// dialogs step6: harvesting ore for a combat ship
sGreatWeHaveANiceShield='Great, we''ve got ourselves a nice shield now!';
sILikeItsColor='I like its color.';
sMeTooHeeHee='Me too! Heehee!';
sSorryToInterruptGirls='Sorry to interrupt, girls. A meteor storm is closing in, and I''m afraid our new shield won''t be enough to handle what''s coming...';
sWouldACombatShip='Would a combat ship capable of blasting the largest incoming meteors before they reach the mothership be useful?';
sIBelieveSoButCanYou='I believe so. But... can you build one in such a short time?';
sWeAlreadyHaveTheMeansTo='We already have the means to construct a ship, and we know laser tech. Yes, it''s doable.';
sInThatCaseGiveMeTheList='In that case, give me the list of ores you need ASAP.';
sW7JustSCompiledIt='W7 just compiled it. Sending it to you now.';
sThePlanToBuildTheCombatShip='The plan to build the combat ship is already underway. '+
                             'We will be able to finish it as soon as you bring us the ore.';

// dialogs step7: construction of the combat ship
sLetsGetStartedOnBuilding='Let''s get started on building the combat ship!';
sConsCombatShip='Construction of the combat ship, step %d of %d';
sWeHaveAllPartsOfCombatShip='We have all the parts of the combat ship. Let''s assemble them and test it out!';

// dialogs step8: briefing about the meteor storm
sFatherWeHaveACombatShipReady='Father, we have a combat ship ready for launch.';
sYouveDoneWell='You''ve done well. With this ship and the shield, we have a chance of getting through this.';
sTheMeteorStormWillHit='The meteor storm will hit us in a few minutes.';
sVeryWellItsTimeToAct='Very well. It''s time to act.';
sPTakeControlOfTheShip='Penelope, take control of the ship and go for it! We''re going to cross '+
                       'the asteroid belt at the same time as the meteor storm. '+
                       'Avoid collisions as much as possible.';
sItsRiskyButILikeIt='It''s risky, but I like it. Let''s go for it!';
sPlayerYoullPilotTheCombat='%s, you''ll pilot the combat ship. Destroy everything you see and clear a path through all those rocks.';
sDontForgetEachImpact='Don''t forget: each impact will reduce the shield''s energy. '+
                      'If it is completely discharged, one more impact and it''s over...';
sMWithWAssistPlayer='Marcus, with W7, assist %s with takeoff, then go to the reactor room '+
                    'and send as much energy as possible to the engines and shield.';
sLadiesWellNeedYourHelp='Ladies, we''ll need your help as well.';
sYesQuestion='Yes?';
sINeedYouToSweepThroughTheShip='I need you to sweep through the ship and shut down every non-essential '+
                               'system. It''ll save power for the shield and buy us more time.';
sConsiderItDone='Consider it done.';
sFinallySomeExercice='Finally, some exercise!';
sIncomingMeteorActivatingShield='Incoming meteor. Activating shield.';
sNoMoreTimeToWaste='No more time to waste! Everyone to your stations!';
sDanger='DANGER';

// dialogs step9: the battle against the meteor storm
sAlrightKidsForward='Alright kids, forward!';
sEngagingThrusters='Engaging thrusters! %s, I''m counting on you to clear the way.';
sOkImGoingInFirst='Ok. I''m going in first.';
sSomeExplanation='Some explanations: when meteorites explode, they emit particles. Your ship is equipped '+
                 'with a system to attract them. When the particle gauge is full, '+
                 'your weaponry upgrade by one level.';
sWeaponryLevel='Weaponry level %d/5';
sLargeMeteorApproaching='Large meteors approaching!';
sKeepItUp='Keep it up!';
sWeCanDoIt='We can do it!';
sMWAreInstalling='Marcus and W7 are installing the system to draw the particles to the mothership!';
sJustALittleLonger='Just a little longer, they''re almost done.';
sIfItWorkWellHave='If it works, we''ll have enough energy to recharge the shield.';
sSystemInstalled='System installed, let''s see if it runs...';
sTheShieldIsRecharging='The particles are powering the mothership! The shield is recharging! Fantastic!!';
sPTakeFormation='%s, don''t shoot anymore and take formation above us, inside the shield.';
sUnderstood='Understood.';
sInPosition='In position.';
sAlrightMyWayNow='Alright... my way now. FULL THRUST!!';
sGodILoveThis='God, I love this!';
sWeHaveMadeItThrough='We''ve made it through the asteroid belt! Well done, everyone!';
sEveryoneGetSomeRest='Rest for everyone! Tomorrow morning, meet me on the main deck for a new briefing.';

// dialogs step10: about harvesting and construction of the Gigatron and Radiation Anihilator
sTheNextMorning='The next morning...';
sIHopeEveryone='I hope everyone''s well rested. It''s time to continue our journey.';
sNowThatWeveMadeIt='Now that we''ve made it past the asteroid belt, all that remains is to build a '+
                   'drive capable of intergalactic jumps, and a shielding system against radiation. '+
                   'Once that''s done, we''ll finally be able to cross the portal.';
sSirMayI='Sir, may I?';
sOfCourseWWhatIsIt='Of course, W7. What is it?';
sDuringYourRest='During your rest, I analyzed the latest data from the probe.';
sItSeemsThePortal='It seems the portal''s technology relies on materials that normally cannot be found '+
                  'in this region of space. The most powerful telescopes on record detected them by '+
                  'spectroscopy, in a distant galaxy called GN-z11, thirteen point four billion '+
                  'light-years away.';
sThenItsHopeless='Then it''s hopeless! We''ll never be able to build what we need...';
sISaidNormally='I said normally because now... they are here.';
sWhatDoYouMean='What do you mean, W7?';
sTheMeteorsFrom='The meteors from the storm we just crossed: they contain it. We can salvage fragments '+
                'from the scattered debris.';
sWhatButThatsGreat='What?! That''s great!';
sItsAStrangeCoincidence='It''s a strange coincidence, don''t you think?';
sYesMaamItsVeryStrange='Yes, ma''am, it''s very strange: there was almost zero chance that this storm '+
                       'would hit the place where we were, and especially at that exact moment.';
sIsThereAnExplanation='Is there an explanation for this?';
sIveTurnedTheEvents='I''ve turned the events around in every possible way. No rational conclusion.'+
                    'The idea that comes to mind is that these meteors were sent...';
sWhatQuestion='What?';
sSentVeryLikely='...sent very likely with the intention of helping us.';
sPfffSoundsLike='Pfft… Sounds like someone needs a serious software update.';
sIRanAFullDiag='I ran a full diagnostic. All systems are optimal.';
sW7IsRightLook='W7 is right. Look closely: these meteors brought us exactly what we were missing.';
sItIsIndeedStrange='It is indeed strange. But for now, we have no way of digging deeper into this mystery.';
sOurFocusMustRemain='Our focus must remain on gathering the ore we need for the propulsor and the '+
                    'radiation shielding, then on their construction.';
sIveGotNamesForThem='I''ve got names for them! The propulsor will be called Gigatron. '+
                    'And the shielding system: Radiation Annihilator.';
sApprovedEveryone='Approved! Everyone, to your stations!';

// dialogs step11: harvesting for the Gigatron and Annihilator
sWeveLocatedTheAsteroids='We''ve located the asteroids we''re interested in. I''m sending you their coordinates.';
sWowThatsALongList='Wow! That''s a long list!';
sYesWeHaveTwo='Yes, we have two constructions to do.';
sOkLetsGo2='Ok, let''s go.';
sGreatNowAllWeHaveToDo='Great! Now all we have to do is build the devices.';
sPJustToldMeThatYou='Penelope just told me that you''ve finished mining the asteroids. '+
                    'I''m waiting for you in the construction unit.';

// dialogs step12: constructing the Gigatron and Annihilator
sWeHaveNewOres='We have new ores: they are the ones brought by the meteors.';
sAsYouCanSeeTheyAre='As you can see, they are either raw or refined and then ground into powder. '+
                    'The liquid version is obtained by dissolving them with various acids.';
sEverythingIsReadyLetsGet='Everything is ready, let''s get started.';
sConsGigatron='Construction of the Gigatron, step %d of %d';
sWeHaveAllPartForGigatron='We have all the parts for the Gigatron. Let''s install it on the ship.';
sLetContinueWithAnnihilator='Let''s continue with the Radiation Annihilator.';
sConsAnnihilator='Construction of the Radiation Annihilator, step %d of %d';
sWereDoneLetsInstall='We''re done! Let''s install the Radiation Annihilator.';

// dialogs step13: le grand saut
sEverythingIsReadyForTheBigJump='Everything''s ready for the big jump. What lies ahead is the unknown. '+
                                'No human, no wolf has ever crossed this portal.';
sOkButHumanOrWolf='Okay, but... human or wolf, nobody really knows how it works...';
sSomethingTellsMeIts='Something tells me it''s not as complicated as it seems.';
sAndYouAChild='And you, a child, just a human, pretend you know?';
sNoThatNotWhat='No! That''s not what I said!';
sHumansAreAllTheSame='Humans are all the same. You think your dreams and your feelings will get '+
                     'you anywhere in this world...';
sAndICouldSayTheSame='And I could say the same about you wolves. No feelings, just a thirst to dominate. '+
                     'You don''t care about the damage, or the suffering you cause, '+
                     'so long as your power stays intact.';
sThatsWhatIDid='That''s what I did...';
sThatExactlyWhatIve='That''s exactly what I''ve done my whole life... I built an empire made of companies, '+
                    'factories, endless exploitation...';
sButNowImOld='But now I''m old. And looking back... that empire doesn''t mean much anymore. '+
             'What truly matters to me is my family. This people I love.';
sDad='Dad!?';
sAndIThinkThatMayBe='And I think that maybe those who aren''t interested in owning so many things '+
                    'are satisfied every day with this feeling...';
sWeDontNeedMuch='We don''t need much: some food, some water, a roof over our heads.';
sINowKnowThat='I now know that happiness is not found in the concerns of a financial empire, '+
              'but rather in the simple things of everyday life and harmonious relationships.';
sIFeelThatWayToo='I feel that way too, for a long time.';
sThankYouForBeingSoHonest='Thank you for being so honest, sir. You''ve learned from your life, '+
                          'that''s what matters. I''m sorry for what I said.';
sNoDontBeSorry='No, don''t be sorry. You were right.';
sWeDontLiveInAFairyTale='We don''t live in a fairy tale. There will always be predators, '+
                        'thirsty to own the world. I was one of them...';
sWeMustLiveAccording='We must live according to our nature. In fact, I''d say we can''t do otherwise.';
sThatsRightButInTheEnd='That''s right. But in the end, what''s important is that we''ve '+
                       'learned something from our life.';
sAndIfWeHaventLearned='And if we haven''t learned anything… does that mean we''ve missed something?';
sYesThatsExactlyWhatMy='Yes definitely. That''s exactly what my grandfather used to say, back when he was still alive.';
sAtNightHeWould='At night, he would often gaze at the stars. And after a while, he''d say: '+
                'There''s something greater than what we can see with our eyes.';
sSirIApologizeForDisturbing='Sir, I apologize for disturbing you, but... The portal has been activated.';
sWhyAreWeMoving='Why are we moving? The thrusters are shut down!';
sNotTheGigatron='Not the Gigatron. It seems to be interacting with the portal.';
sTheGigatronIsFully='The Gigatron is fully activated.';
sButWhoActivatedIt='But who activated it? Nobody touched it!';
sIDontKnowTheProbe='I don''t know. The probe is detecting communication signals between the portal and the Gigatron.';
sEveryoneToLookLike='Everyone to your posts! Looks like we''re making the big jump despite ourselves...';
sDetectionOfStrong='Detection of strong radiation coming from the portal.';
sRadiation='RADIATION';
sOkImActivatingTheRadiation='Okay, I''m activating the Radiation Annihilator!';
sRadiationNeutralized='Radiation neutralized.';
sTheGateActivity='The gate''s activity is intensifying.';
sGigatronOverload='The Gigatron is overloading.';
sSirIThinkWereInHyperspace='Sir, I think we''re in hyperspace.';
sWowItWorks='Wow! It works!';
sThatsIncredible='That''s incredible!';
sTheRadiationsHasStopped='The radiation have stopped. I''m deactivating the Annihilator.';
sThatNightNoOneWentToBed='That night, no one went to bed despite the late hour. Everyone stayed up '+
                         'to watch the spectacle unfolding before their eyes.';
sTheyWereAwareThat='They were aware that what they were experiencing had never been experienced before. '+
                   'There was no longer any reason for quarrels. Faced with this immensity, '+
                   'a feeling of humility and peace settled in their hearts.';


sInstructionLittleShip='←→ to rotate' + LineEnding +
                       '↑ to accelerate' + LineEnding +
                       '↓ to decelerate';
sInstructionMiningShipOre='ACTION1 to extract ore';
sInstructionMiningShipProbe='ACTION2 to launch the probe';

sInstructionMeteorStorm='←→↑↓ to move' + LineEnding +
                        'ACTION1 : fire';


sToBeContinued='to be continued...';





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

