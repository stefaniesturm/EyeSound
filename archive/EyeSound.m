
% EyeSound script that includes training block, and alternating active and
% passive C-blocks

function EyeSound(iSub, StartLevel)

% If experiment is interrupted, you can restart at any level (between 1 and
% 20), otherwise omit StartLevel argument

if ~exist(StartLevel)
    StartLevel = 1;
end

%%

%%% SET PATHS %%%

cd 'D:\Usuarios\stefaniesturm\iCloudDrive\Brainlab_2020\EyeSound\'
Sounds_path = 'D:\Usuarios\stefaniesturm\iCloudDrive\Brainlab_2020\EyeSound\sounds\';
Results_path = 'D:\Usuarios\stefaniesturm\iCloudDrive\Brainlab_2020\EyeSound\results\';
load('EyeSound_NEW.mat') % Load the matrix that contains info about stimuli

%%% ADJUST EXPERIMENT PARAMETERS

condition = 1; % Active condition
nBlocks = 6; % Within one block, contingencies don't change. Each block has one exploration and 6 test trials.
nLevels = 20 % The experiment has 20 levels, 10 of which are active and passive respectively
AcquisitionDur = 30; % 30sec for acquisition trials, less for debugging
nTrainings = 1;

%%% SETUP FOR VISUAL STIMULI

AssertOpenGL
Screen('Preference', 'SkipSyncTests', 0);
PsychDefaultSetup(2);
screenNumber=max(Screen('Screens'));

% Appearances
white = [1 1 1];
black = [0 0 0];
red = [1 0 0];
window_size = [0 0 400 400]; % small window for debugging; comment out if fullscreen is wanted

% Open an on screen window and color it black
if exist('window_size')
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black, window_size); % Open for debugging
else
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black); % Open fullscreen
end

% Prepare the matrix
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
laststop = 0
dir = -1;
olddir = -1;
prevstop = -1;
currentMouse = [-1 -1];
tone = 0;

%%% SETUP FOR ANIMATIONS

speed = 3; % This is how fast animation moves
ifi = Screen('GetFlipInterval', window); % You need this for the animations
vbl=Screen('Flip', window); % You need this for the animations

% Below we define the positions in which the dots can start/end during animations (the centers of the dots) relative to the center of the screen

centerX = screenXpixels/2
centerY = screenYpixels/2
gap = screenYpixels/4 % the distance between the dots is a quarter of the length of the y-axis

pos1 = [centerX-gap centerY-gap]
pos2 = [centerX centerY-gap]
pos3 = [centerX+gap centerY-gap]
pos4 = [centerX-gap centerY]
pos5 = [centerX centerY]
pos6 = [centerX+gap centerY]
pos7 = [centerX-gap centerY+gap]
pos8 = [centerX centerY+gap]
pos9 = [centerX+gap centerY+gap]

%%% RESPONSE DEVICE SETTINGS

% Use common key mapping for all operating systems and define the escape
% key as abort key:
KbName('UnifyKeyNames');
RightArrow = KbName('RightArrow'); % to get the name you have to write, execute KbName without arguments and press the key you want to get the code for
LeftArrow = KbName('LeftArrow');
esc = KbName('ESCAPE');
keyIsDown = 0; % This may be redundant, check that if everything else is working

%%% PREPARE LOGFILES

cd(Results_path);

% Acquisition logfile (movement coordinates)
explorelogfilename = [Results_path sprintf('%02d',iSub) 'explore_active.txt'];
exists = fopen(explorelogfilename, 'r'); % checks if logfile already exists, returns -1 if does not exist

if exists ~= -1
    overwrite = input('WARNING: Logfile already exists, overwrite? 1 = yes, 2 = no');
    if overwrite == 2
        return;
    end
end

LOGFILEexplore = fopen(explorelogfilename, 'a+'); % append information, don't overwrite
headers={'Time ', 'xMouse ', 'yMouse ', 'Sound '}; % Add one row of headers to the logfile





% Test logfile (responses)
testlogfilename = [Results_path sprintf('%02d', iSub) 'test_active.txt'];
exists = fopen(testlogfilename, 'r'); % checks if logfile already exists, returns -1 if does not exist

if exists ~= -1
    overwrite = input('WARNING: Logfile already exists, overwrite? 1 = yes, 2 = no');
    if overwrite == 2
        return;
    end
end

LOGFILEtest = fopen(testlogfilename, 'a+'); % This is not working, I need to fix this. Do it manually instead!
headers={'Subject ', 'Block ', 'Trial ', 'Condition ', 'Sound ', 'MovDir ', 'Congruency ', 'Response '}; % Add one row of headers to the logfile









%%

%%% EXPERIMENT START

% Instructions

Screen('TextSize', window, 20); % set text size
Screen('TextFont', window, 'Helvetica');
DrawFormattedText(window, '(Press space key to continue.)', 'center', 'center',textcolor);
Screen('Flip',window);
KbStrokeWait;
DrawFormattedText(window, 'Welcome to EyeSounds!', 'center', 'center',textcolor);
Screen('Flip',window);
KbStrokeWait;
DrawFormattedText(window, 'This experiment consists of \n explore trials and test trials.', 'center', 'center',textcolor);
Screen('Flip',window);
KbStrokeWait;
DrawFormattedText(window, 'During explore trials, move \n the cursor to explore the sounds.', 'center', 'center',textcolor);
Screen('Flip',window);
KbStrokeWait;
DrawFormattedText(window, 'During test trials, observe \n the stimuli and answer "yes" or "no".', 'center', 'center',textcolor);
Screen('Flip',window);
KbStrokeWait;
DrawFormattedText(window, 'Press left arrow for "no" \n and right arrow for "yes"!', 'center', 'center', textcolor);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'For this pilot, you will play 2 levels.', 'center', 'center', textcolor);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'In level 1, you will get 6 chances to explore the sounds.', 'center', 'center', textcolor);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'After each round of exploration, you have to answer 6 test questions.', 'center', 'center', textcolor);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'After that, the level is over and you will move to level 2.', 'center', 'center', textcolor);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'In level 2, the sounds will be all new and you have to start from 0 again to learn them.', 'center', 'center', textcolor);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'Now, we will do a training round or two. What you are doing now does not count yet.', 'center', 'center', textcolor);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'Ready?', 'center', 'center', textcolor);
Screen('Flip', window);
KbStrokeWait;

% Training

for iTrain = 1:nTrainings
    % Run training block
    testtrials = EyeSound(iSub).Blocks(iTrain).TestTrials
    SoundNames = EyeSound(iSub).Contingencies(iTrain,:);% Sounds to be used in this block corresponding to the n Movement directions
    
    % Load sounds
    nrchannels = 1;
    device = [];
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
    
    % Start the audio device:
    InitializePsychSound; % Initialize the sound device
    paHandle = PsychPortAudio('Open', device, [], 0, FS, nrchannels);
    
    % Start acquisition training
    Screen('TextSize', window, 40);
    DrawFormattedText(window, 'TRAINING', 'center', 'center',textcolor);
    Screen('Flip',window);
    WaitSecs(1);
    Screen('Flip',window);
    
    % Explore the dots and make sounds
    t0 = GetSecs;
    AcquisitionLog = []; % to be used for replaying, columns = xMouse yMouse, DotTime, Sound, SounTime, lines = events.
    
    % Start the animation
    while GetSecs-t0 < AcquisitionDur
        
        % Draw the matrix of dots to the screen
        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
        
        % Get the current position of the mouse
        [xMouse, yMouse, buttons] = GetMouse(window);
        
        % Draw the cursor as a white dot
        Screen('DrawDots', window, [xMouse yMouse], 20, white, [], 2);
        HideCursor;
        
        % Define responsive areas relative to center of screen
        
        % Make the squares size relative to the gap size
        squareSize = gap/10
        
        square1 = ((centerX-gap)-squareSize <= xMouse && xMouse <= (centerX-gap)+squareSize) && ((centerY-gap)-squareSize <= yMouse && yMouse <= (centerY-gap)+squareSize)
        square2 = ((centerX)-squareSize <= xMouse && xMouse <= (centerX)+squareSize) && ((centerY-gap)-squareSize <= yMouse && yMouse <= (centerY-gap)+squareSize)
        square3 = ((centerX+gap)-squareSize <= xMouse && xMouse <= (centerX+gap)+squareSize) && ((centerY-gap)-squareSize <= yMouse && yMouse <= (centerY-gap)+squareSize)
        square4 = ((centerX-gap)-squareSize <= xMouse && xMouse <= (centerX-gap)+squareSize) && ((centerY)-squareSize <= yMouse && yMouse <= (centerY)+squareSize)
        square5 = ((centerX)-squareSize <= xMouse && xMouse <= (centerX)+squareSize) && ((centerY)-squareSize <= yMouse && yMouse <= (centerY)+squareSize)
        square6 = ((centerX+gap)-squareSize <= xMouse && xMouse <= (centerX+gap)+squareSize) && ((centerY)-squareSize <= yMouse && yMouse <= (centerY)+squareSize)
        square7 = ((centerX-gap)-squareSize <= xMouse && xMouse <= (centerX-gap)+squareSize) && ((centerY+gap)-squareSize <= yMouse && yMouse <= (centerY+gap)+squareSize)
        square8 = ((centerX)-squareSize <= xMouse && xMouse <= (centerX)+squareSize) && ((centerY+gap)-squareSize <= yMouse && yMouse <= (centerY+gap)+squareSize)
        square9 = ((centerX+gap)-squareSize <= xMouse && xMouse <= (centerX+gap)+squareSize) && ((centerY+gap)-squareSize <= yMouse && yMouse <= (centerY+gap)+squareSize)
        
        
        % Define the responsive areas
        % square1 = (screenXpixels*0.20 <= xMouse && xMouse <= screenXpixels*0.30) && (screenYpixels*0.20 <= yMouse && yMouse <= screenYpixels*0.30);
        % square2 = (screenXpixels*0.45 <= xMouse && xMouse <= screenXpixels*0.55) && (screenYpixels*0.20 <= yMouse && yMouse <= screenYpixels*0.30);
        % square3 = (screenXpixels*0.70 <= xMouse && xMouse <= screenXpixels*0.80) && (screenYpixels*0.20 <= yMouse && yMouse <= screenYpixels*0.30);
        % square4 = (screenXpixels*0.20 <= xMouse && xMouse <= screenXpixels*0.30) && (screenYpixels*0.45 <= yMouse && yMouse <= screenYpixels*0.55);
        % square5 = (screenXpixels*0.45 <= xMouse && xMouse <= screenXpixels*0.55) && (screenYpixels*0.45 <= yMouse && yMouse <= screenYpixels*0.55);
        % square6 = (screenXpixels*0.70 <= xMouse && xMouse <= screenXpixels*0.80) && (screenYpixels*0.45 <= yMouse && yMouse <= screenYpixels*0.55);
        % square7 = (screenXpixels*0.20 <= xMouse && xMouse <= screenXpixels*0.30) && (screenYpixels*0.70 <= yMouse && yMouse <= screenYpixels*0.80);
        % square8 = (screenXpixels*0.45 <= xMouse && xMouse <= screenXpixels*0.55) && (screenYpixels*0.70 <= yMouse && yMouse <= screenYpixels*0.80);
        % square9 = (screenXpixels*0.70 <= xMouse && xMouse <= screenXpixels*0.80) && (screenYpixels*0.70 <= yMouse && yMouse <= screenYpixels*0.80);
        
        %---SQUARE_1---%
        if square1 == true && laststop == 2;
            dir = 1;
            laststop = 1;
        elseif square1 == true && laststop == 4;
            dir = 3;
            laststop = 1;
        elseif square1 == true && laststop == 5;
            dir = 5;
            laststop = 1;
        elseif square1 == true;
            laststop = 1;
        end
        
        %---SQUARE_2---%
        if square2 == true && laststop == 1;
            dir = 2;
            laststop = 2;
        elseif square2 == true && laststop == 3;
            dir = 1;
            laststop = 2;
        elseif square2 == true && laststop == 4;
            dir = 7;
            laststop = 2;
        elseif square2 == true && laststop == 5;
            dir = 3;
            laststop = 2;
        elseif square2 == true && laststop == 6;
            dir = 5;
            laststop = 2;
        elseif square2 == true;
            laststop = 2;
        end
        
        %---SQUARE_3---%
        if square3 == true && laststop == 2;
            dir = 2;
            laststop = 3;
        elseif square3 == true && laststop == 5;
            dir = 7;
            laststop = 3;
        elseif square3 == true && laststop == 6;
            dir = 3;
            laststop = 3;
        elseif square3 == true;
            laststop = 3;
        end
        
        %---SQUARE_4---%
        if square4 == true && laststop == 1;
            dir = 4;
            laststop = 4;
        elseif square4 == true && laststop == 2;
            dir = 6;
            laststop = 4;
        elseif square4 == true && laststop == 5;
            dir = 1;
            laststop = 4;
        elseif square4 == true && laststop == 7;
            dir = 3;
            laststop = 4;
        elseif square4 == true && laststop == 8;
            dir = 5;
            laststop = 4;
        elseif square4 == true;
            laststop = 4;
        end
        
        %---SQUARE_5---%
        if square5 == true && laststop == 1;
            dir = 8;
            laststop = 5;
        elseif square5 == true && laststop == 2;
            dir = 4;
            laststop = 5;
        elseif square5 == true && laststop == 3;
            dir = 6;
            laststop = 5;
        elseif square5 == true && laststop == 4;
            dir = 2;
            laststop = 5;
        elseif square5 == true && laststop == 6;
            dir = 1;
            laststop = 5;
        elseif square5 == true && laststop == 7;
            dir = 7;
            laststop = 5;
        elseif square5 == true && laststop == 8;
            dir = 3;
            laststop = 5;
        elseif square5 == true && laststop == 9;
            dir = 5;
            laststop = 5;
        elseif square5 == true;
            laststop = 5;
        end
        
        %---SQUARE_6---%
        if square6 == true && laststop == 2;
            dir = 8;
            laststop = 6;
        elseif square6 == true && laststop == 3;
            dir = 4;
            laststop = 6;
        elseif square6 == true && laststop == 5;
            dir = 2;
            laststop = 6;
        elseif square6 == true && laststop == 8;
            dir = 7;
            laststop = 6;
        elseif square6 == true && laststop == 9;
            dir = 3;
            laststop = 6;
        elseif square6 == true;
            laststop = 6;
        end
        
        %---SQUARE_7---%
        if square7 == true && laststop == 4;
            dir = 4;
            laststop = 7;
        elseif square7 == true && laststop == 5;
            dir = 6;
            laststop = 7;
        elseif square7 == true && laststop == 8;
            dir = 1;
            laststop = 7;
        elseif square7 == true;
            laststop = 7;
        end
        
        %---SQUARE_8---%
        if square8 == true && laststop == 4;
            dir = 8;
            laststop = 8;
        elseif square8 == true && laststop == 5;
            dir = 4;
            laststop = 8;
        elseif square8 == true && laststop == 6;
            dir = 6;
            laststop = 8;
        elseif square8 == true && laststop == 7;
            dir = 2;
            laststop = 8;
        elseif square8 == true && laststop == 9;
            dir = 1;
            laststop = 8;
        elseif square8 == true;
            laststop = 8;
        end
        
        %---SQUARE_9---%
        if square9 == true && laststop == 5;
            dir = 8;
            laststop = 9;
        elseif square9 == true && laststop == 6;
            dir = 4;
            laststop = 9;
        elseif square9 == true && laststop == 8;
            dir = 2;
            laststop = 9;
        elseif square9 == true;
            laststop = 9;
        end
        
        still = isequal(currentMouse, [xMouse yMouse]);
        
        if still == 0;
            
            
            
            
            currentMouse = [xMouse yMouse];
            tone = 0
        end
        
        if laststop ~= prevstop
            prevstop = laststop;
            PsychPortAudio('Stop', paHandle);
            switch (dir)
                case 1
                    PsychPortAudio('FillBuffer', paHandle, tone1);
                case 2
                    PsychPortAudio('FillBuffer', paHandle, tone2);
                case 3
                    PsychPortAudio('FillBuffer', paHandle, tone3);
                case 4
                    PsychPortAudio('FillBuffer', paHandle, tone4);
                case 5
                    PsychPortAudio('FillBuffer', paHandle, tone5);
                case 6
                    PsychPortAudio('FillBuffer', paHandle, tone6);
                case 7
                    PsychPortAudio('FillBuffer', paHandle, tone7);
                case 8
                    PsychPortAudio('FillBuffer', paHandle, tone8);
            end
            if dir ~= -1
                PsychPortAudio('Start', paHandle, 1); %change to 0 for infinite reps
                tone = dir
            end
        end
        Screen('Flip', window);
    end
    
    % End exploring
    WaitSecs(0.1);
    Screen('TextSize', window, 20);
    DrawFormattedText(window, 'Your time is up!', 'center', 'center',textcolor);
    Screen('Flip',window);
    WaitSecs(1);
    
    %% Test trials loop
    
    for iTest = 1:EyeSound(iSub).nTestTrialsperBlock % Loop over the 6 test trials of a block
        
        
        
        
        
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone3);
                        
                    end
                    while xDot > pos1(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone3);
                        
                    end
                    while xDot > pos2(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone3);
                        
                    end
                    while xDot > pos4(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                        starttime = PsychPortAudio('Start', paHandle, 1);
                    end
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone3);
                        
                    end
                    while xDot > pos5(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone3);
                        
                    end
                    while xDot > pos7(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone3);
                        
                    end
                    while xDot > pos8(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone4);
                        
                    end
                    while xDot < pos2(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone4);
                        
                    end
                    while xDot < pos3(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone4);
                        
                    end
                    while xDot < pos5(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone4);
                        
                    end
                    while xDot < pos6(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone4);
                        
                    end
                    while xDot < pos8(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone4);
                        
                    end
                    while xDot < pos9(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone5);
                        
                    end
                    while yDot > pos1(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone5);
                        
                    end
                    while yDot > pos2(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone5);
                        
                    end
                    while yDot > pos3(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone5);
                        
                    end
                    while yDot > pos4(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone5);
                        
                    end
                    while yDot > pos5(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone5);
                        
                    end
                    while yDot > pos6(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone6);
                        
                    end
                    while yDot < pos4(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone6);
                        
                    end
                    while yDot < pos5(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone6);
                        
                    end
                    while yDot < pos6(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone6);
                        
                    end
                    while yDot < pos7(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone6);
                        
                    end
                    while yDot < pos8(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone6);
                        
                    end
                    while yDot < pos9(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone7);
                        
                    end
                    while yDot > pos1(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed
                        xDot = xDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone7);
                        
                    end
                    while yDot > pos2(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed
                        xDot = xDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone7);
                        
                    end
                    while xDot > pos4(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed
                        yDot = yDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone7);
                        
                    end
                    while xDot > pos5(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed
                        yDot = yDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone8);
                        
                    end
                    while xDot > pos4(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed
                        yDot = yDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone8);
                        
                    end
                    while xDot > pos5(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed
                        yDot = yDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone8);
                        
                    end
                    while yDot < pos7(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed
                        xDot = xDot - speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone8);
                        
                    end
                    while xDot > pos8(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed
                        yDot = yDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone1);
                        
                    end
                    while yDot > pos2(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed
                        xDot = xDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone1);
                        
                    end
                    while yDot > pos3(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed
                        xDot = xDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone1);
                        
                    end
                    while yDot > pos5(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed
                        xDot = xDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone1);
                        
                    end
                    while yDot > pos6(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed
                        xDot = xDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone2);
                        
                    end
                    while yDot < pos5(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed
                        xDot = xDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone2);
                        
                    end
                    while xDot < pos6(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed
                        yDot = yDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone2);
                        
                    end
                    while yDot < pos8(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed
                        xDot = xDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
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
                        
                    elseif testtrials(3,iTest) == 0 % if trial type is incongruent
                        PsychPortAudio('FillBuffer', paHandle, tone2);
                        
                    end
                    while yDot < pos9(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed
                        xDot = xDot + speed
                        % Draw dot
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                    % Present question
                    PsychPortAudio('Start', paHandle, 1);
                    PsychPortAudio('Stop', paHandle, 1);
                    WaitSecs(1);
                    
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
                            
                        elseif keyCode(LeftArrow)
                            response = 0;
                            DrawFormattedText(window, 'No!', 'center', 'center', textcolor);
                            Screen('Flip', window);
                            WaitSecs(1);
                            Screen('Flip', window);
                            
                        end
                    end
                    WaitSecs(1);
                    Screen('Flip',window);
            end % switch
        end % if-statement for movement directions (??)
    end % for-loop for trials
end % for-loop for training


%%

%%% MAIN EXPERIMENT

% if counterbalancing == 1
% 
% conditionArray = [1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2] % Start with active
% 
% for iContingency = startContingency:length(conditionArray)
%     if conditionArray(iContingency) == 1
%         % Run active block
%     elseif conditionArray(iContingency) == 2
%         % Run passive block
%         
%         % elseif counterbalancing == 2
%         
%         % conditionArray = [2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2 1] % Start with
%         % passive
%         
%     end