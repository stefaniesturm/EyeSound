% 40 different animations, all possible directions that generate a sound

% For testing
iSub = 1
iBlock = 1


%----------------------------------
% Things shared with active blocks
%----------------------------------
% Use common key mapping for all operating systems and define the escape
% key as abort key:
KbName('UnifyKeyNames');
RightArrow = KbName('RightArrow'); % to get the name you have to write, execute KbName without arguments and press the key you want to get the code for
LeftArrow = KbName('LeftArrow');
esc = KbName('ESCAPE');
keyIsDown = 0; % This may be redundant, check that if everything else is working

% WINDOWS
cd 'D:\Usuarios\stefaniesturm\iCloudDrive\Brainlab_2020\EyeSound\'
Sounds_path = 'D:\Usuarios\stefaniesturm\iCloudDrive\Brainlab_2020\EyeSound\sounds\';
Results_path = 'D:\Usuarios\stefaniesturm\iCloudDrive\Brainlab_2020\EyeSound\results\';
% Linux
% cd '/home/stefanie/Brainlab_2020/EyeSound/stimulation'
% Sounds_path = '/home/stefanie/Brainlab_2020/EyeSound/stimulation/syllables/';
% Results_path = 'home/stefanie/Brainlab_2020/EyeSound/stimulation/results/';
load EyeSound
AssertOpenGL
Screen('Preference', 'SkipSyncTests', 0);
PsychDefaultSetup(2);
screenNumber = 0;
white = [1 1 1];
black = [0 0 0];
red = [1 0 0];
window_size = [0 0 400 400]; % small window for debugging; comment out if fullscreen is wanted
textcolor = white; % color for text: white
if exist('window_size')
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black, window_size); % Open for debugging
else
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black); % Open fullscreen
end
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[xCenter, yCenter] = RectCenter(windowRect);
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
dim = 1;
[xGrid, yGrid] = meshgrid(-dim:1:dim, -dim:1:dim);
pixelScale = screenYpixels / (dim * 2 + 2);
xGrid = xGrid .* pixelScale;
yGrid = yGrid .* pixelScale;
numDots = 9;
dotPositionMatrix = [reshape(xGrid, 1, numDots); reshape(yGrid, 1, numDots)];
dotCenter = [xCenter yCenter];
dotColor = red;
dotSize = 40;

nrchannels = 1; % stereo
FS = 96000;

iContingency = ceil(iBlock/EyeSound(iSub).nBlocksPerContingency);
SoundNames = EyeSound(iSub).Contingencies(iContingency,:);% Sounds to be used in this block corresponding to the n Movement directions

[tone1, FS] = audioread(string(strcat(Sounds_path, SoundNames(1))));
[tone2, FS] = audioread(string(strcat(Sounds_path, SoundNames(2))));
[tone3, FS] = audioread(string(strcat(Sounds_path, SoundNames(3))));
[tone4, FS] = audioread(string(strcat(Sounds_path, SoundNames(4))));
[tone5, FS] = audioread(string(strcat(Sounds_path, SoundNames(5))));
[tone6, FS] = audioread(string(strcat(Sounds_path, SoundNames(6))));
[tone7, FS] = audioread(string(strcat(Sounds_path, SoundNames(7))));
[tone8, FS] = audioread(string(strcat(Sounds_path, SoundNames(8))));

tone1 = tone1';
tone2 = tone2';
tone3 = tone3';
tone4 = tone4';
tone5 = tone5';
tone6 = tone6';
tone7 = tone7';
tone8 = tone8';

device = [];
% Start the audio device:
InitializePsychSound; % Initialize the sound device
paHandle = PsychPortAudio('Open', device, [], 0, FS, nrchannels); % Open the Audio port and get a handle to refer to it in subsequent calls


%----------------------------------------------------------------------
%                       Prepare Logfiles
%----------------------------------------------------------------------

cd 'D:\Usuarios\stefaniesturm\iCloudDrive\Brainlab_2020\EyeSound\results'

% testlogfilename = [Results_path sprintf('%02d',iSub) '.txt']; % For iOS and Linux 
testlogfilename = [Results_path sprintf('%02d', iSub) 'test.txt']; % for
%Windows

exists = fopen(testlogfilename, 'r'); % checks if logfile already exists, returns -1 if does not exist

if exists ~= -1
    overwrite = input('WARNING: Logfile already exists, overwrite? 1 = yes, 2 = no');
    if overwrite == 2
        return;
    end
end

LOGFILEtest = fopen(testlogfilename, 'a+'); % This is not working, I need to fix this. Do it manually instead!

% LOGFILEtest = fopen('01.txt', 'a+')

headers={'Subject ', 'Block ', 'Trial ', 'Condition ', 'Time ', 'xMouse ', 'yMouse ', 'Sound ', 'MovDir ', 'Congruency ', 'Response '}; % Add one row of headers to the logfile
fprintf(LOGFILEtest,'%s', headers{1})
fprintf(LOGFILEtest,'%s', headers{2})
fprintf(LOGFILEtest,'%s', headers{3})
fprintf(LOGFILEtest,'%s', headers{4})
fprintf(LOGFILEtest,'%s', headers{5})
fprintf(LOGFILEtest,'%s', headers{6})
fprintf(LOGFILEtest,'%s', headers{7})
fprintf(LOGFILEtest,'%s', headers{8})
fprintf(LOGFILEtest,'%s', headers{9})
fprintf(LOGFILEtest,'%s', headers{10})
fprintf(LOGFILEtest,'%s', headers{11})

%------------------------------
% Things specific to animation
%------------------------------

% Overview over directions
% left: dir = 1, tone1, animationIDs: 4,9,20,27,36,40
% right: dir = 2, tone2, animationIDs: 1,5,14,21,32,37
% up: dir = 3, tone3, animationIDs: 12,18,26,30,34,39
% down: dir = 4, tone4, animationIDs: 2,7,11,15,23,29
% leftup: dir = 5, tone5, animationIDs: 17,25,33,38
% leftdown: dir = 6, tone6, animationIDs: 6,10,22,28
% rightup: dir = 7, tone7, animationIDs: 13,19,31,35
% rightdown: dir = 8, tone8, animationIDs: 3,8,16,24

speed = 3;
ifi = Screen('GetFlipInterval', window);
vbl=Screen('Flip', window);

pos1 = [screenXpixels*0.25 screenYpixels*0.25];
pos2 = [screenXpixels*0.50 screenYpixels*0.25];
pos3 = [screenXpixels*0.75 screenYpixels*0.25];
pos4 = [screenXpixels*0.25 screenYpixels*0.50];
pos5 = [screenXpixels*0.50 screenYpixels*0.50];
pos6 = [screenXpixels*0.75 screenYpixels*0.50];
pos7 = [screenXpixels*0.25 screenYpixels*0.75];
pos8 = [screenXpixels*0.50 screenYpixels*0.75];
pos9 = [screenXpixels*0.75 screenYpixels*0.75];

NA = 0
condition = 1
iTrial = 2

testtrials = EyeSound(iSub).Blocks(iBlock).TestTrials % This variable holds the movement directions of the test trials, the sound to be played, and whether the trial is congruent or incongruent
%%
for iTest = 1:EyeSound(iSub).nTestTrialsperBlock % Loop over the 6 test trials of a block
    fprintf(LOGFILEtest,'\n%d', iSub);
    fprintf(LOGFILEtest,'\t%d', iBlock);
    fprintf(LOGFILEtest,'\t%d', iTrial); % Make this 1 or 2 depending on whether acquisition or test (make this variable)
    fprintf(LOGFILEtest, '\t%d', condition); % Condition: atively or passively learned? Introduce this variable before
    fprintf(LOGFILEtest, '\t NA'); % No time for test trials
    fprintf(LOGFILEtest, '\t NA'); % No coordinates for test trials
    fprintf(LOGFILEtest, '\t NA'); % No coordinates for test trials

    if testtrials(1,iTest) == 1 % If the direction of movement is 1
        animation = randi(6) % There are 6 different animations that have direction 1
        switch animation
            case 1
                % --- Animation & sound ---
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation 2-1, dir: 1
                % animationID = 4
                xDot = pos2(1);
                yDot = pos2(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone1);                    
                    fprintf(LOGFILEtest, '\t tone1'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone3);
                    fprintf(LOGFILEtest, '\t tone3'); % Write sound into logfile
                end
                while xDot > pos1(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot-speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 2
                % --- Animation & sound ---
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation 3-2, dir: 1
                % animationID = 9
                xDot = pos3(1);
                yDot = pos3(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone1);
                    fprintf(LOGFILEtest, '\t tone1'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone3);
                    fprintf(LOGFILEtest, '\t tone3'); % Write sound into logfile
                end
                while xDot > pos2(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot-speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 3
                % --- Animation & sound ---
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation 5-4, dir: 1
                % animationID = 20
                xDot = pos5(1);
                yDot = pos5(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone1);
                    fprintf(LOGFILEtest, '\t tone1'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone3);
                    fprintf(LOGFILEtest, '\t tone3'); % Write sound into logfile
                end
                while xDot > pos4(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot-speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    starttime = PsychPortAudio('Start', paHandle, 1);
                end
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 4
                % --- Animation & sound ---
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation 6-5, dir: 1
                % animationID = 27
                xDot = pos6(1);
                yDot = pos6(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone1);
                    fprintf(LOGFILEtest, '\t tone1'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone3);
                    fprintf(LOGFILEtest, '\t tone3'); % Write sound into logfile
                end
                while xDot > pos5(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot-speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
                
            case 5
                % --- Animation & sound ---
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation 8-7, dir: 1
                % animationID = 36
                xDot = pos8(1);
                yDot = pos8(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone1);
                    fprintf(LOGFILEtest, '\t tone1'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone3);
                    fprintf(LOGFILEtest, '\t tone3'); % Write sound into logfile
                end
                while xDot > pos7(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot-speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 6
                % --- Animation & sound ---
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation 9-8, dir: 1
                % animationID = 40
                xDot = pos9(1);
                yDot = pos9(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone1);
                    fprintf(LOGFILEtest, '\t tone1'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone3);
                    fprintf(LOGFILEtest, '\t tone3'); % Write sound into logfile
                end
                while xDot > pos8(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot-speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
        end
    elseif testtrials(1,iTest) == 2 % If the direction of movement is 2
        animation = randi(6) % There are 6 different animations that have direction 2
        switch animation
            case 1
                % --- Animation & sound ---
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation 1-2, dir: 2
                % animationID = 1
                xDot = pos1(1);
                yDot = pos1(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone2);
                    fprintf(LOGFILEtest, '\t tone2'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone4);
                    fprintf(LOGFILEtest, '\t tone4'); % Write sound into logfile
                end
                while xDot < pos2(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot+speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 2
                % --- Animation & sound ---
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 2-3, dir: 2
                % animationID = 5
                xDot = pos2(1);
                yDot = pos2(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone2);
                    fprintf(LOGFILEtest, '\t tone2'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone4);
                    fprintf(LOGFILEtest, '\t tone4'); % Write sound into logfile
                end
                while xDot < pos3(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot+speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 3
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 4-5, dir: 2
                % animationID = 14
                xDot = pos4(1);
                yDot = pos4(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone2);
                    fprintf(LOGFILEtest, '\t tone2'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone4);
                    fprintf(LOGFILEtest, '\t tone4'); % Write sound into logfile
                end
                while xDot < pos5(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot+speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 4
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 5-6, dir: 2
                % animationID = 21
                xDot = pos5(1);
                yDot = pos5(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone2);
                    fprintf(LOGFILEtest, '\t tone2'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone4);
                    fprintf(LOGFILEtest, '\t tone4'); % Write sound into logfile
                end
                while xDot < pos6(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot+speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 5
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 7-8, dir: 2
                % animationID = 32
                xDot = pos7(1);
                yDot = pos7(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone2);
                    fprintf(LOGFILEtest, '\t tone2'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone4);
                    fprintf(LOGFILEtest, '\t tone4'); % Write sound into logfile
                end
                while xDot < pos8(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot+speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 6
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 8-9, dir: 2
                % animationID = 37
                xDot = pos8(1);
                yDot = pos8(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone2);
                    fprintf(LOGFILEtest, '\t tone2'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone4);
                    fprintf(LOGFILEtest, '\t tone4'); % Write sound into logfile
                end
                while xDot < pos9(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot+speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
        end
    elseif testtrials(1,iTest) == 3 % If the direction of movement is 3
        animation = randi(6) % There are 6 different animations that have direction 3
        switch animation
            case 1
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 4-1, dir: 3
                % animationID = 12
                xDot = pos4(1);
                yDot = pos4(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone3);
                    fprintf(LOGFILEtest, '\t tone3'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone5);
                    fprintf(LOGFILEtest, '\t tone5'); % Write sound into logfile
                    end
                while yDot > pos1(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot-speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 2
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 5-2, dir: 3
                % animationID = 18
                xDot = pos5(1);
                yDot = pos5(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone3);
                    fprintf(LOGFILEtest, '\t tone3'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone5);
                    fprintf(LOGFILEtest, '\t tone5'); % Write sound into logfile
                end
                while yDot > pos2(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot-speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 3
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 6-3, dir: 3
                % animationID = 26
                xDot = pos6(1);
                yDot = pos6(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone3);
                    fprintf(LOGFILEtest, '\t tone3'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone5);
                    fprintf(LOGFILEtest, '\t tone5'); % Write sound into logfile
                end
                while yDot > pos3(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot-speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 4
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 7-4, dir: 3
                % animationID = 30
                xDot = pos7(1);
                yDot = pos7(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone3);
                    fprintf(LOGFILEtest, '\t tone3'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone5);
                    fprintf(LOGFILEtest, '\t tone5'); % Write sound into logfile
                end
                while yDot > pos4(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot-speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 5
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 8-5, dir: 3
                % animationID = 34
                xDot = pos8(1);
                yDot = pos8(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone3);
                    fprintf(LOGFILEtest, '\t tone3'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone5);
                    fprintf(LOGFILEtest, '\t tone5'); % Write sound into logfile
                end
                while yDot > pos5(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot-speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency


                % --- Question & response ---                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 6
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 9-6, dir: 3
                % animationID = 39
                xDot = pos9(1);
                yDot = pos9(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone3);
                    fprintf(LOGFILEtest, '\t tone3'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone5);
                    fprintf(LOGFILEtest, '\t tone5'); % Write sound into logfile
                end
                while yDot > pos6(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot-speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
        end % switch

    elseif testtrials(1,iTest) == 4 % If the direction of movement is 4
        animation = randi(6) % There are 6 different animations that have direction 4 (last one where this is the case)
        switch animation
            case 1
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 1-4, dir: 4
                % animationID = 2
                xDot = pos1(1);
                yDot = pos1(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone4);
                    fprintf(LOGFILEtest, '\t tone4'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone6);
                    fprintf(LOGFILEtest, '\t tone6'); % Write sound into logfile
                end
                while yDot < pos4(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot+speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 2
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 2-5, dir: 4
                % animationID = 7
                xDot = pos2(1);
                yDot = pos2(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone4);
                    fprintf(LOGFILEtest, '\t tone4'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone6);
                    fprintf(LOGFILEtest, '\t tone6'); % Write sound into logfile
                    end
                while yDot < pos5(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot+speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 3
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 3-6, dir: 4
                % animationID = 11
                xDot = pos3(1);
                yDot = pos3(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone4);
                    fprintf(LOGFILEtest, '\t tone4'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone6);
                    fprintf(LOGFILEtest, '\t tone6'); % Write sound into logfile
                end
                while yDot < pos6(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot+speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 4
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 4-7, dir: 4
                % animationID = 15
                xDot = pos4(1);
                yDot = pos4(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone4);
                    fprintf(LOGFILEtest, '\t tone4'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone6);
                    fprintf(LOGFILEtest, '\t tone6'); % Write sound into logfile
                end
                while yDot < pos7(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot+speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);

                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 5
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 5-8, dir: 4
                % animationID = 23
                xDot = pos5(1);
                yDot = pos5(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone4);
                    fprintf(LOGFILEtest, '\t tone4'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone6);
                    fprintf(LOGFILEtest, '\t tone6'); % Write sound into logfile
                end
                while yDot < pos8(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot+speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 6
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 6-9, dir: 4
                % animationID = 29
                xDot = pos6(1);
                yDot = pos6(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone4);
                    fprintf(LOGFILEtest, '\t tone4'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone6);
                    fprintf(LOGFILEtest, '\t tone6'); % Write sound into logfile
                end
                while yDot < pos9(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot+speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
        end % switch 
    elseif testtrials(1,iTest) == 5 % If the direction of movement is 5
        animation = randi(4) % There are 4 different animations that have direction 5
        switch animation
            case 1
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 5-1, dir: 5
                % animationID = 17
                xDot = pos5(1);
                yDot = pos5(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone5);
                    fprintf(LOGFILEtest, '\t tone5'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone7);
                    fprintf(LOGFILEtest, '\t tone7'); % Write sound into logfile
                end
                while yDot > pos1(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot-speed, screenYpixels);
                    xDot=mod(xDot-speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 2
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 6-2, dir: 5
                % animationID = 25
                xDot = pos6(1);
                yDot = pos6(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone5);
                    fprintf(LOGFILEtest, '\t tone5'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone7);
                    fprintf(LOGFILEtest, '\t tone7'); % Write sound into logfile
                end
                while yDot > pos2(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot-speed, screenYpixels);
                    xDot=mod(xDot-speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 3
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 8-4, dir: 5
                % animationID = 33
                xDot = pos8(1);
                yDot = pos8(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone5);
                    fprintf(LOGFILEtest, '\t tone5'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone7);
                    fprintf(LOGFILEtest, '\t tone7'); % Write sound into logfile
                end
                while xDot > pos4(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot-speed, screenXpixels);
                    yDot=mod(yDot-speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 4
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 9-5, dir: 5
                % animationID = 38
                xDot = pos9(1);
                yDot = pos9(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone5);
                    fprintf(LOGFILEtest, '\t tone5'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone7);
                    fprintf(LOGFILEtest, '\t tone7'); % Write sound into logfile
                end
                while xDot > pos5(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot-speed, screenXpixels);
                    yDot=mod(yDot-speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
        end % switch 
    elseif testtrials(1,iTest) == 6 % If the direction of movement is 6
        animation = randi(4) % There are 4 different animations that have direction 6
        switch animation
            case 1
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 2-4, dir: 6
                % animationID = 6
                xDot = pos2(1);
                yDot = pos2(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone6);
                    fprintf(LOGFILEtest, '\t tone6'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone8);
                    fprintf(LOGFILEtest, '\t tone8'); % Write sound into logfile
                end
                while xDot > pos4(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot-speed, screenXpixels);
                    yDot=mod(yDot+speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 2
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 3-5, dir: 6
                % animationID = 10
                xDot = pos3(1);
                yDot = pos3(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone6);
                    fprintf(LOGFILEtest, '\t tone6'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone8);
                    fprintf(LOGFILEtest, '\t tone8'); % Write sound into logfile
                end
                while xDot > pos5(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot-speed, screenXpixels);
                    yDot=mod(yDot+speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 3
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 5-7, dir: 6
                % animationID = 22
                xDot = pos5(1);
                yDot = pos5(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone6);
                    fprintf(LOGFILEtest, '\t tone6'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone8);
                    fprintf(LOGFILEtest, '\t tone8'); % Write sound into logfile
                end
                while yDot < pos7(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot+speed, screenYpixels);
                    xDot=mod(xDot-speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 4
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 6-8, dir: 6
                % animationID = 28
                xDot = pos6(1);
                yDot = pos6(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone6);
                    fprintf(LOGFILEtest, '\t tone6'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone8);
                    fprintf(LOGFILEtest, '\t tone8'); % Write sound into logfile
                end
                while xDot > pos8(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot-speed, screenXpixels);
                    yDot=mod(yDot+speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
        end % switch
    elseif testtrials(1,iTest) == 7 % If the direction of movement is 7
        animation = randi(4) % There are 4 different animations that have direction 7
        switch animation
            case 1
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 4-2, dir: 7
                % animationID = 13
                xDot = pos4(1);
                yDot = pos4(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone7);
                    fprintf(LOGFILEtest, '\t tone7'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone1);
                    fprintf(LOGFILEtest, '\t tone1'); % Write sound into logfile
                end
                while yDot > pos2(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot-speed, screenYpixels);
                    xDot=mod(xDot+speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 2
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 5-3, dir: 7
                % animationID = 19
                xDot = pos5(1);
                yDot = pos5(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone7);
                    fprintf(LOGFILEtest, '\t tone7'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone1);
                    fprintf(LOGFILEtest, '\t tone1'); % Write sound into logfile
                end
                while yDot > pos3(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot-speed, screenYpixels);
                    xDot=mod(xDot+speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 3
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 7-5, dir: 7
                % animationID = 31
                xDot = pos7(1);
                yDot = pos7(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone7);
                    fprintf(LOGFILEtest, '\t tone7'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone1);
                    fprintf(LOGFILEtest, '\t tone1'); % Write sound into logfile
                end
                while yDot > pos5(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot-speed, screenYpixels);
                    xDot=mod(xDot+speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 4
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 8-6, dir: 7
                % animationID = 35
                xDot = pos8(1);
                yDot = pos8(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone7);
                    fprintf(LOGFILEtest, '\t tone7'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone1);
                    fprintf(LOGFILEtest, '\t tone1'); % Write sound into logfile
                end
                while yDot > pos6(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot-speed, screenYpixels);
                    xDot=mod(xDot+speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
        end % switch

    elseif testtrials(1,iTest) == 8 % If the direction of movement is 8
        animation = randi(4) % There are 4 different animations that have direction 8
        switch animation
            case 1
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 1-5, dir: 8
                % animationID = 3
                xDot = pos1(1);
                yDot = pos1(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone8);
                    fprintf(LOGFILEtest, '\t tone8'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone2);
                    fprintf(LOGFILEtest, '\t tone2'); % Write sound into logfile
                    end
                    while yDot < pos5(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot+speed, screenYpixels);
                    xDot=mod(xDot+speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 2
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 2-6, dir: 8
                % animationID = 8
                xDot = pos2(1);
                yDot = pos2(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone8);
                    fprintf(LOGFILEtest, '\t tone8'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone2);
                    fprintf(LOGFILEtest, '\t tone2'); % Write sound into logfile
                end
                while xDot < pos6(1)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    xDot=mod(xDot+speed, screenXpixels);
                    yDot=mod(yDot+speed, screenYpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 3
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 4-8, dir: 8
                % animationID = 16
                xDot = pos4(1);
                yDot = pos4(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone8);
                    fprintf(LOGFILEtest, '\t tone8'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone2);
                    fprintf(LOGFILEtest, '\t tone2'); % Write sound into logfile
                end
                while yDot < pos8(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot+speed, screenYpixels);
                    xDot=mod(xDot+speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
            case 4
                % --- Animation & sound --- 
                % Start trial
                Screen('TextSize', window, 40);
                DrawFormattedText(window, 'TEST', 'center', 'center',textcolor);
                Screen('Flip',window);
                WaitSecs(1);
                Screen('Flip',window);
                % Animation
                % Animation 5-9, dir: 8
                % animationID = 24
                xDot = pos5(1);
                yDot = pos5(2);
                if testtrials(3,iTest) == 1 % if trial type is congruent
                    PsychPortAudio('FillBuffer', paHandle, tone8);
                    fprintf(LOGFILEtest, '\t tone8'); % Write sound into logfile
                elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                    PsychPortAudio('FillBuffer', paHandle, tone2);
                    fprintf(LOGFILEtest, '\t tone2'); % Write sound into logfile
                end
                while yDot < pos9(2)
                    % Draw matrix
                    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                    % Make dot move at "speed"
                    yDot=mod(yDot+speed, screenYpixels);
                    xDot=mod(xDot+speed, screenXpixels);
                    % Draw dot
                    Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                    vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                end
                % Present question
                PsychPortAudio('Start', paHandle, 1);
                PsychPortAudio('Stop', paHandle, 1);
                WaitSecs(1);
                
                % --- Write into logfile ---
                fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency

                % --- Question & response ---
                Screen('TextSize', window, 20);
                DrawFormattedText(window, 'Did they match?', 'center', 'center',textcolor);
                Screen('Flip',window);
                keyIsDown = 0
                while keyIsDown == 0
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(RightArrow)
                        response = 1;
                        DrawFormattedText(window, 'Yes!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    elseif keyCode(LeftArrow)
                        response = 0;
                        DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                        Screen('Flip', window);
                        WaitSecs(1);
                        Screen('Flip', window);
                        fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                    end
                end
                WaitSecs(1);
                Screen('Flip',window);
        end % switch
    end % if-statement for movement directions (??)
end % for-loop for trials