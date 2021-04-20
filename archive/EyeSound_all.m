function EyeSound_all(iSub, StartLevel)

% iSub is subject number, StartLevel is for restarting at an advanced level
% if something fails; if you start from the beginning, make that 1

% -------------------------------------------------------------------------
%                                  SETUP
% -------------------------------------------------------------------------

% cd 'D:\Usuarios\stefaniesturm\iCloudDrive\Brainlab_2020\EyeSound\'
% Sounds_path = 'D:\Usuarios\stefaniesturm\iCloudDrive\Brainlab_2020\EyeSound\sounds\';
% Results_path = 'D:\Usuarios\stefaniesturm\iCloudDrive\Brainlab_2020\EyeSound\results\';

% Linux:
cd '/home/stefanie/GitHub/EyeSound/'
Sounds_path = '/home/stefanie/GitHub/EyeSound/sounds/';
Results_path = '/home/stefanie/GitHub/EyeSound/results/'

% Load matrix with info on stimuli
load('EyeSound_NEW.mat') % Load the matrix that contains info about stimuli

% Counterbalance order of active and passive conditions
if EyeSound_NEW(iSub).Counterbalancing == 1 % Active first
    levels = [0 1 2 1 2 1 2 1 2 1 2 1 2 1 2]; % 0 means training, 1 is active and 2 is passive
elseif EyeSound_NEW(iSub).Counterbalancing == 2; % Passive first
    levels = [0 2 1 2 1 2 1 2 1 2 1 2 1 2 1]; % 0 means training, 1 is active and 2 is passive
end

nBlocks = 6; % In active and passive levels, each level has 6 blocks
nTrains = 3; % The training level has 3 blocks
nLevels = length(levels); % The experiment has 20 levels, 10 of which are active and passive respectively, plus a training level = 21

AcquisitionDur = 20; % 20sec for acquisition trials, less for debugging
ttCounter = 0; % This counter counts the blocks in a continuous way instead of restarting from 1 every time we change the level. This is important because to index the test trial matrix, we need this number
columnX = [] % initialise this variable so it exists
columny = [] % initialise this variable so it exists
row = 0 % initialise this variable so it exists

% -------------------------------------------------------------------------
%                          SETUP FOR VISUAL STIMULI
% -------------------------------------------------------------------------

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

% These are some variables used to play sounds
laststop = 0
dir = -1;
olddir = -1;
prevstop = -1;
currentMouse = [-1 -1];
tone = 0;

% This is needed for the animations
speed = 3; % This is how fast animation moves!!!
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

% -------------------------------------------------------------------------
%                     RESPONSE DEVICE SETTINGS
% -------------------------------------------------------------------------

% To get the names of keys, execute KbName without arguments and press the
% key you want to get the code for

% Use common key mapping for all operating systems and define the escape
% key as abort key:
KbName('UnifyKeyNames');
% Counterbalance response keys
if EyeSound_NEW(iSub).Counterbalancing == 1;
    YesKey = KbName('RightArrow');
    NoKey = KbName('LeftArrow');
elseif EyeSound_NEW(iSub).Counterbalancing == 2;
    NoKey = KbName('RightArrow');
    YesKey = KbName('LeftArrow');
end
esc = KbName('ESCAPE');
keyIsDown = 0; % This may be redundant, check that if everything else is working

% -------------------------------------------------------------------------
%                            PREPARE LOGFILES
% -------------------------------------------------------------------------

cd(Results_path);

% Acquisition logfile (movement coordinates)
explorelogfilename = [Results_path sprintf('%02d',iSub) 'explore_active.txt'];
exists = fopen(explorelogfilename, 'r'); % checks if logfile already exists, returns -1 if does not exist

LOGFILEexplore = fopen(explorelogfilename, 'a+'); % append information, don't overwrite
headers={'Subject ', 'Contingency ', 'Block ', 'Time ', 'xMouse ', 'yMouse ', 'Sound '}; % Add one row of headers to the logfile
fprintf(LOGFILEexplore,'%s', headers{1})
fprintf(LOGFILEexplore,'%s', headers{2})
fprintf(LOGFILEexplore,'%s', headers{3})
fprintf(LOGFILEexplore,'%s', headers{4})
fprintf(LOGFILEexplore,'%s', headers{5})
fprintf(LOGFILEexplore,'%s', headers{6})
fprintf(LOGFILEexplore,'%s', headers{7})

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
headers={'Subject ', 'Level ', 'Block ', 'Trial ', 'Condition ', 'Sound ', 'AnimationID', 'MovDir ', 'Congruency ', 'Response '}; % Add one row of headers to the logfile
fprintf(LOGFILEtest,'%s', headers{1});
fprintf(LOGFILEtest,'%s', headers{2});
fprintf(LOGFILEtest,'%s', headers{3});
fprintf(LOGFILEtest,'%s', headers{4});
fprintf(LOGFILEtest,'%s', headers{5});
fprintf(LOGFILEtest,'%s', headers{6});
fprintf(LOGFILEtest,'%s', headers{7});
fprintf(LOGFILEtest,'%s', headers{8});
fprintf(LOGFILEtest,'%s', headers{9});
fprintf(LOGFILEtest,'%s', headers{9});

% -------------------------------------------------------------------------
%                          PREPARE AUDIO DEVICE
% -------------------------------------------------------------------------

% Start the audio device:
nrchannels = 1;
FS = 96000;
device = [];
InitializePsychSound; % Initialize the sound device
paHandle = PsychPortAudio('Open', device, [], 0, FS, nrchannels);

%%
% -------------------------------------------------------------------------
%                              INSTRUCTIONS
% -------------------------------------------------------------------------

Screen('TextSize', window, 20); % set text size
Screen('TextFont', window, 'Helvetica');
DrawFormattedText(window, '(Press space key to continue.)', 'center', 'center',white);
Screen('Flip',window);
KbStrokeWait;
DrawFormattedText(window, 'Welcome to EyeSounds!', 'center', 'center',white);
Screen('Flip',window);
KbStrokeWait;
DrawFormattedText(window, 'This experiment consists of \n explore trials and test trials.', 'center', 'center',white);
Screen('Flip',window);
KbStrokeWait;
DrawFormattedText(window, 'During explore trials, move \n the cursor to explore the sounds.', 'center', 'center',white);
Screen('Flip',window);
KbStrokeWait;
DrawFormattedText(window, 'During test trials, observe \n the stimuli and answer "yes" or "no".', 'center', 'center',white);
Screen('Flip',window);
KbStrokeWait;
% Counterbalance instructions for keyboard responses
if EyeSound_NEW(iSub).Counterbalancing == 1;
    DrawFormattedText(window, 'Press left arrow for "no" \n and right arrow for "yes"!', 'center', 'center', white);
elseif EyeSound_NEW(iSub).Counterbalancing == 2;
    DrawFormattedText(window, 'Press left arrow for "yes" \n and right arrow for "no"!', 'center', 'center', white);
end
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'For this pilot, you will play 2 levels.', 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'In level 1, you will get 6 chances to explore the sounds.', 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'After each round of exploration, you have to answer 6 test questions.', 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'After that, the level is over and you will move to level 2.', 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'In level 2, the sounds will be all new and you have to start from 0 again to learn them.', 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'Now, we will do a training round or two. What you are doing now does not count yet.', 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;
DrawFormattedText(window, 'Ready?', 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;
%%
% -------------------------------------------------------------------------
%                               START EXPERIMENT
% -------------------------------------------------------------------------

% Open for debugging
% [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black, window_size);

% Experiment loop (1 training level, 7 active and 7 passive levels)
for iLevel = StartLevel:length(levels)
    
    if levels(iLevel) == 0; % Training level
        nTests = 3;
    elseif levels(iLevel) == 1; % Active level
        nTests = 6;
    elseif levels(iLevel) == 2; % Passive level
        nTests = 6;
    end
    
    % Load sounds to be used in this block corresponding to the movement directions
    SoundNames = EyeSound_NEW(iSub).Contingencies(iLevel,:);
    % Read files
    [tone1, FS] = audioread(string(strcat(Sounds_path, SoundNames(1))));
    [tone2, FS] = audioread(string(strcat(Sounds_path, SoundNames(2))));
    [tone3, FS] = audioread(string(strcat(Sounds_path, SoundNames(3))));
    [tone4, FS] = audioread(string(strcat(Sounds_path, SoundNames(4))));
    [tone5, FS] = audioread(string(strcat(Sounds_path, SoundNames(5))));
    [tone6, FS] = audioread(string(strcat(Sounds_path, SoundNames(6))));
    [tone7, FS] = audioread(string(strcat(Sounds_path, SoundNames(7))));
    [tone8, FS] = audioread(string(strcat(Sounds_path, SoundNames(8))));
    % Transpose tones
    tone1 = tone1';
    tone2 = tone2';
    tone3 = tone3';
    tone4 = tone4';
    tone5 = tone5';
    tone6 = tone6';
    tone7 = tone7';
    tone8 = tone8';
    
    % Information for logfiles
    if levels(iLevel) == 0; % Training level
        condition = 0;
    elseif levels(iLevel) == 1; % Active level
        condition = 1;
    elseif levels(iLevel) == 2; % Passive level
        condition = 2;
    end
    
    % Each level has 6 blocks
    for iBlock = 1:nBlocks
        ttCounter = ttCounter+1 % We count here the blocks without restarting at new level
        % Test trial codes change per block
        testtrials = EyeSound_NEW(iSub).Blocks(ttCounter).TestTrials
        
        % ACQUISITRION TRIAL (can be training, passive or active)
        
        % Instructions
        Screen('TextSize', window, 40);
        if levels(iLevel) == 1; % Active level
            DrawFormattedText(window, 'EXPLORAR', 'center', 'center',white);
        elseif levels(iLevel) == 2; % Passive level
            DrawFormattedText(window, 'OBSERVAR', 'center', 'center',white);
        elseif levels(iLevel) == 0; % Training
            DrawFormattedText(window, 'PRACTICAR', 'center', 'center',white);
        end
        Screen('Flip',window);
        WaitSecs(1);
        Screen('Flip',window);
        
        if levels(iLevel) == 2;
            % IMPORT COORDINATES FROM ACTIVE LEVEL PREVIOUS TO THIS ONE
            opts = delimitedTextImportOptions("NumVariables", 7);
            % Specify range and delimiter
            opts.DataLines = [2, Inf];
            opts.Delimiter = "\t";
            % Specify column names and types
            opts.VariableNames = ["Var1", "VarName2", "VarName3", "Var4", "VarName5", "VarName6", "Var7"];
            opts.SelectedVariableNames = ["VarName2", "VarName3", "VarName5", "VarName6"];
            opts.VariableTypes = ["string", "double", "double", "string", "double", "double", "string"];
            opts = setvaropts(opts, [1, 4, 7], "WhitespaceRule", "preserve");
            opts = setvaropts(opts, [1, 4, 7], "EmptyFieldRule", "auto");
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            % Setup rules for import
            opts.MissingRule = "omitrow";
            % Import the data
            coordinates_filename = [Results_path sprintf('%02d',iSub) 'explore_active.txt'];
            coordinates = readtable(coordinates_filename, opts);
            % Convert to output type
            coordinates = table2array(coordinates);
            % Clear temporary variables
            clear opts
            row = 0
            ind1 = coordinates(:,1) == iLevel-1; % Make a logical index that selects coordinates from the current contingency
            coordinates_block = coordinates(ind1,:); % Select appropriate coordinates
            ind2 = coordinates_block(:,2) == iBlock % Logical index for block
            coordinates_block = coordinates_block(ind2,:) % Select coordinates for this specific block
            columnX = coordinates_block(:,3) % This column contains the X values
            columnY = coordinates_block(:,4) % This column contains the Y values
        end
        
        % Start the animation
        
        conditional = 1 % Set conditional for acquisition start to TRUE
        t0 = GetSecs; % Start counting time
        
        while conditional == 1
            if levels(iLevel) == 2
                conditional = row+1 < length(columnX)
            else
                conditional = (GetSecs-t0 < AcquisitionDur)
            end
            % Draw the matrix of dots to the screen
            Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
            if levels(iLevel) == 2; % passive
                % Define the position of the cursor using the logfiles
                row = row+1;
                xMouse = columnX(row);
                yMouse = columnY(row);
            else % active or training
                [xMouse, yMouse, buttons] = GetMouse(window);
            end
            % Draw the cursor as a white dot
            Screen('DrawDots', window, [xMouse yMouse], 20, white, [], 2);
            HideCursor;
            
            % Make the squares size relative to the gap size
            squareSize = gap/10
            
            % Define responsive areas relative to center of screen
            square1 = ((centerX-gap)-squareSize <= xMouse && xMouse <= (centerX-gap)+squareSize) && ((centerY-gap)-squareSize <= yMouse && yMouse <= (centerY-gap)+squareSize)
            square2 = ((centerX)-squareSize <= xMouse && xMouse <= (centerX)+squareSize) && ((centerY-gap)-squareSize <= yMouse && yMouse <= (centerY-gap)+squareSize)
            square3 = ((centerX+gap)-squareSize <= xMouse && xMouse <= (centerX+gap)+squareSize) && ((centerY-gap)-squareSize <= yMouse && yMouse <= (centerY-gap)+squareSize)
            square4 = ((centerX-gap)-squareSize <= xMouse && xMouse <= (centerX-gap)+squareSize) && ((centerY)-squareSize <= yMouse && yMouse <= (centerY)+squareSize)
            square5 = ((centerX)-squareSize <= xMouse && xMouse <= (centerX)+squareSize) && ((centerY)-squareSize <= yMouse && yMouse <= (centerY)+squareSize)
            square6 = ((centerX+gap)-squareSize <= xMouse && xMouse <= (centerX+gap)+squareSize) && ((centerY)-squareSize <= yMouse && yMouse <= (centerY)+squareSize)
            square7 = ((centerX-gap)-squareSize <= xMouse && xMouse <= (centerX-gap)+squareSize) && ((centerY+gap)-squareSize <= yMouse && yMouse <= (centerY+gap)+squareSize)
            square8 = ((centerX)-squareSize <= xMouse && xMouse <= (centerX)+squareSize) && ((centerY+gap)-squareSize <= yMouse && yMouse <= (centerY+gap)+squareSize)
            square9 = ((centerX+gap)-squareSize <= xMouse && xMouse <= (centerX+gap)+squareSize) && ((centerY+gap)-squareSize <= yMouse && yMouse <= (centerY+gap)+squareSize)
            
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
                fprintf(LOGFILEexplore,'\n%d', iSub);
                fprintf(LOGFILEexplore,'\t%d', iLevel);
                fprintf(LOGFILEexplore,'\t%d', iBlock);
                fprintf(LOGFILEexplore,'\t%d', GetSecs-t0);
                fprintf(LOGFILEexplore, '\t%d', xMouse);
                fprintf(LOGFILEexplore, '\t%d', yMouse);
                fprintf(LOGFILEexplore, '\t%d', tone);
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
                    WaitSecs(0.5); % Freeze cursor to reduce number of sounds played during acquisition
                    tone = dir;
                end
            end
            if levels(iLevel) == 2 % Animate
                vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
            else
                Screen('Flip', window); % Use mouse coordinates
            end
            
        end % Acquisition trial
        
        % End exploring
        WaitSecs(0.1);
        Screen('TextSize', window, 20);
        DrawFormattedText(window, '¡Se acabó el tiempo!', 'center', 'center',white);
        Screen('Flip',window);
        WaitSecs(1);
        prevstop = -1;
        laststop = -1;
        dir = -1;
        
        % Test trials (always the same, but only 3 during training block)
        for iTest = 1:nTests % Only 3 for training, otherwise 6
            fprintf(LOGFILEtest,'\n%d', iSub);
            fprintf(LOGFILEtest,'\t%d', iLevel);
            fprintf(LOGFILEtest,'\t%d', iBlock);
            fprintf(LOGFILEtest,'\t%d', iTest);
            fprintf(LOGFILEtest, '\t%d', condition); % Condition: actively or passively learned?
            sound = ['tone' sprintf('%d',testtrials(2,iTest))]
            fprintf(LOGFILEtest, '\t%d', sound); % Write sound into logfile
            PsychPortAudio('FillBuffer', paHandle, eval(sound));
            Screen('TextSize', window, 40);
            DrawFormattedText(window, 'TEST', 'center', 'center',white);
            Screen('Flip',window);
            WaitSecs(0.5);
            Screen('Flip',window);
            
            if testtrials(1,iTest) == 1 % If the direction of movement is 1
                animation = randi(6) % There are 6 different animations that have direction 1
                switch animation
                    case 1
                        % Animation 2-1, dir: 1
                        animationID = 4
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos2(1);
                        yDot = pos2(2);
                        while xDot > pos1(1)
                            % Draw matrix
                            Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                            % Make dot move at "speed"
                            % xDot = xDot - speed
                            xDot = xDot-speed;
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
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 2
                        % Animation 3-2, dir: 1
                        animationID = 9
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos3(1);
                        yDot = pos3(2);
                        while xDot > pos2(1)
                            % Draw matrix
                            Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                            % Make dot move at "speed"
                            xDot = xDot - speed
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
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 3
                        % Animation 5-4, dir: 1
                        animationID = 20
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos5(1);
                        yDot = pos5(2);
                        while xDot > pos4(1)
                            % Draw matrix
                            Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                            % Make dot move at "speed"
                            xDot = xDot - speed
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
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 4
                        % Animation 6-5, dir: 1
                        animationID = 27
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos6(1);
                        yDot = pos6(2);
                        while xDot > pos5(1)
                            % Draw matrix
                            Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                            % Make dot move at "speed"
                            xDot = xDot - speed
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
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 5
                        % Animation 8-7, dir: 1
                        animationID = 36
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos8(1);
                        yDot = pos8(2);
                        while xDot > pos7(1)
                            % Draw matrix
                            Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                            % Make dot move at "speed"
                            xDot = xDot - speed
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
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 6
                        % Animation 9-8, dir: 1
                        animationID = 40
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos9(1);
                        yDot = pos9(2);
                        while xDot > pos8(1)
                            % Draw matrix
                            Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                            % Make dot move at "speed"
                            xDot = xDot - speed
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
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
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
                        % Animation 1-2, dir: 2
                        animationID = 1
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos1(1);
                        yDot = pos1(2);
                        while xDot < pos2(1)
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 2
                        % Animation 2-3, dir: 2
                        animationID = 5
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos2(1);
                        yDot = pos2(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 3
                        % Animation 4-5, dir: 2
                        animationID = 14
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos4(1);
                        yDot = pos4(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 4
                        % Animation 5-6, dir: 2
                        animationID = 21
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos5(1);
                        yDot = pos5(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 5
                        % Animation 7-8, dir: 2
                        animationID = 32
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos7(1);
                        yDot = pos7(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 6
                        % Animation 8-9, dir: 2
                        animationID = 37
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos8(1);
                        yDot = pos8(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
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
                        % Animation 4-1, dir: 3
                        animationID = 12
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos4(1);
                        yDot = pos4(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 2
                        % Animation 5-2, dir: 3
                        animationID = 18
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos5(1);
                        yDot = pos5(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 3
                        % Animation 6-3, dir: 3
                        animationID = 26
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos6(1);
                        yDot = pos6(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 4
                        % Animation 7-4, dir: 3
                        animationID = 30
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos7(1);
                        yDot = pos7(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 5
                        % Animation 8-5, dir: 3
                        animationID = 34
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos8(1);
                        yDot = pos8(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 6
                        % Animation 9-6, dir: 3
                        animationID = 39
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos9(1);
                        yDot = pos9(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
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
                        % Animation 1-4, dir: 4
                        animationID = 2
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos1(1);
                        yDot = pos1(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 2
                        % Animation 2-5, dir: 4
                        animationID = 7
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos2(1);
                        yDot = pos2(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 3
                        % Animation 3-6, dir: 4
                        animationID = 11
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos3(1);
                        yDot = pos3(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 4
                        % Animation 4-7, dir: 4
                        animationID = 15
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos4(1);
                        yDot = pos4(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 5
                        % Animation 5-8, dir: 4
                        animationID = 23
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos5(1);
                        yDot = pos5(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 6
                        % Animation 6-9, dir: 4
                        animationID = 29
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos6(1);
                        yDot = pos6(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
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
                        % Animation 5-1, dir: 5
                        animationID = 17
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos5(1);
                        yDot = pos5(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 2
                        % Animation 6-2, dir: 5
                        animationID = 25
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos6(1);
                        yDot = pos6(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 3
                        % Animation 8-4, dir: 5
                        animationID = 33
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos8(1);
                        yDot = pos8(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 4
                        % Animation 9-5, dir: 5
                        animationID = 38
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos9(1);
                        yDot = pos9(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
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
                        % Animation 2-4, dir: 6
                        animationID = 6
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos2(1);
                        yDot = pos2(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 2
                        % Animation 3-5, dir: 6
                        animationID = 10
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos3(1);
                        yDot = pos3(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 3
                        % Animation 5-7, dir: 6
                        animationID = 22
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos5(1);
                        yDot = pos5(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 4
                        % Animation 6-8, dir: 6
                        animationID = 28
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos6(1);
                        yDot = pos6(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
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
                        % Animation 4-2, dir: 7
                        animationID = 13
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos4(1);
                        yDot = pos4(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 2
                        % Animation 5-3, dir: 7
                        animationID = 19
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos5(1);
                        yDot = pos5(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 3
                        % Animation 7-5, dir: 7
                        animationID = 31
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos7(1);
                        yDot = pos7(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 4
                        % Animation 8-6, dir: 7
                        animationID = 35
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos8(1);
                        yDot = pos8(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
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
                        % Animation 1-5, dir: 8
                        animationID = 3
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos1(1);
                        yDot = pos1(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 2
                        % Animation 2-6, dir: 8
                        animationID = 8
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos2(1);
                        yDot = pos2(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 3
                        % Animation 4-8, dir: 8
                        animationID = 16
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos4(1);
                        yDot = pos4(2);
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
                        
                        % --- Write into logfile ---
                        fprintf(LOGFILEtest, '\t%d', testtrials(1,iTest)); % Movement direction
                        fprintf(LOGFILEtest, '\t%d', testtrials(3,iTest)); % Congruency
                        
                        % --- Question & response ---
                        Screen('TextSize', window, 20);
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0;
                        while keyIsDown == 0
                            [keyIsDown, secs, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                    case 4
                        % Animation 5-9, dir: 8
                        animationID = 24
                        fprintf(LOGFILEtest, '\t%d', animationID);
                        xDot = pos5(1);
                        yDot = pos5(2);
                        while yDot < pos9(2)
                            % Draw matrix
                            Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
                            % Make dot move at "speed"
                            yDot = yDot + speed;
                            xDot = xDot + speed;
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
                        DrawFormattedText(window, '?', 'center', 'center',white);
                        Screen('Flip',window);
                        keyIsDown = 0;
                        while keyIsDown == 0
                            [keyIsDown, ~, keyCode] = KbCheck;
                            if keyCode(YesKey)
                                response = 1;
                                DrawFormattedText(window, 'Si', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            elseif keyCode(NoKey)
                                response = 0;
                                DrawFormattedText(window, 'No', 'center', 'center', white);
                                Screen('Flip', window);
                                WaitSecs(1);
                                Screen('Flip', window);
                                fprintf(LOGFILEtest, '\t%d', response); % Write response into logfile
                            end
                        end
                        WaitSecs(1);
                        Screen('Flip',window);
                end % very long switch
            end % if-statement for movement directions
        end % for-loop for trials
    end % blocks
end % levels

%%
% -------------------------------------------------------------------------
%                           CLOSE AND CLEAN UP
% -------------------------------------------------------------------------

sca; % Close window
fclose(LOGFILEtest);
fclose(LOGFILEexplore);
PsychPortAudio('Close'); % Close the audio device
end % function