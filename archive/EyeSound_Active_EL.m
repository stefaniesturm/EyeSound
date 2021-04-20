function EyeSound_Active_EL(iSub,StartContingency,StartBlock)

% This script runs: up to 10 contingencies, with 6 exploration rounds each, and 6 test trials per exploration round, and stores
% information into two different logfiles for the two types of trials ("explore" and "test")
% It needs the matrix "EyeSound" to be stored in the same folder as the
% script itself, the sound files in a subfolder called "sounds", and an
% empty subfolder called "results" where it will store the logfiles
% Written by Stefanie, January 2021

% This script uses the EyeTracker

% if experiment is interrupted, can restart at whichever Condition/Block by
% adding the input arguments when calling the script.
if ~exist(StartContingency)
    StartContingency = 1;
end
if ~exist(StartBlock)
    StartBlock = 1;
end

%----------------------------------------------------------------------
%                       Set paths
%----------------------------------------------------------------------

cd 'D:\Usuarios\stefaniesturm\iCloudDrive\Brainlab_2020\EyeSound\'
Sounds_path = 'D:\Usuarios\stefaniesturm\iCloudDrive\Brainlab_2020\EyeSound\sounds\';
Results_path = 'D:\Usuarios\stefaniesturm\iCloudDrive\Brainlab_2020\EyeSound\results\';
load EyeSound % Load the matrix that contains info about stimuli

%----------------------------------------------------------------------
%                       Adjustable experiment parameters
%----------------------------------------------------------------------

condition = 1; % Active condition
nBlocks = 6; % Within one block, contingencies don't change. Each block has one exploration and 6 test trials.
nContingencies = 10; % The total number of active contingencies in the experiment will be 10
AcquisitionDur = 30; % 30sec for acquisition trials, less for debugging

%----------------------------------------------------------------------
%                   Visual stimulus preparation
%----------------------------------------------------------------------

AssertOpenGL
Screen('Preference', 'SkipSyncTests', 0);
PsychDefaultSetup(2);
screenNumber=max(Screen('Screens'));

% Appearances
white = [1 1 1];
black = [0 0 0];
red = [1 0 0];
window_size = [0 0 400 400]; % small window for debugging; comment out if fullscreen is wanted
textcolor = white; % color for text: white

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

%----------------------------------------------------------------------
%                       Setup for animations
%----------------------------------------------------------------------

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

% Formerly they were defined relative to the axis, which made them into a rectangle occasionally
% pos1 = [screenXpixels*0.25 screenYpixels*0.25];
% pos2 = [screenXpixels*0.50 screenYpixels*0.25];
% pos3 = [screenXpixels*0.75 screenYpixels*0.25];
% pos4 = [screenXpixels*0.25 screenYpixels*0.50];
% pos5 = [screenXpixels*0.50 screenYpixels*0.50];
% pos6 = [screenXpixels*0.75 screenYpixels*0.50];
% pos7 = [screenXpixels*0.25 screenYpixels*0.75];
% pos8 = [screenXpixels*0.50 screenYpixels*0.75];
% pos9 = [screenXpixels*0.75 screenYpixels*0.75];

%----------------------------------------------------------------------
%                       Keyboard information
%----------------------------------------------------------------------

% Use common key mapping for all operating systems and define the escape
% key as abort key:
KbName('UnifyKeyNames');
RightArrow = KbName('RightArrow'); % to get the name you have to write, execute KbName without arguments and press the key you want to get the code for
LeftArrow = KbName('LeftArrow');
esc = KbName('ESCAPE');
keyIsDown = 0; % This may be redundant, check that if everything else is working

%----------------------------------------------------------------------
%                       Prepare Logfile
%----------------------------------------------------------------------

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
headers={'Time ', 'xEye ', 'yEye ', 'Sound '}; % Add one row of headers to the logfile
fprintf(LOGFILEexplore,'%s', headers{1})
fprintf(LOGFILEexplore,'%s', headers{2})
fprintf(LOGFILEexplore,'%s', headers{3})
fprintf(LOGFILEexplore,'%s', headers{4})

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
fprintf(LOGFILEtest,'%s', headers{1})
fprintf(LOGFILEtest,'%s', headers{2})
fprintf(LOGFILEtest,'%s', headers{3})
fprintf(LOGFILEtest,'%s', headers{4})
fprintf(LOGFILEtest,'%s', headers{5})
fprintf(LOGFILEtest,'%s', headers{6})
fprintf(LOGFILEtest,'%s', headers{7})
fprintf(LOGFILEtest,'%s', headers{8})

%----------------------------------------------------------------------
%                       Start eyetracker
%----------------------------------------------------------------------

% Initialise EyeLink
el=EyelinkInitDefaults(window);
% sw_version = 0; % Maybe we need to tell EyeLink the version
% Disable key output to Matlab window:
ListenChar(2);
[v vs]=Eyelink('GetTrackerVersion');
fprintf('Running experiment on a ''%s'' tracker.\n', vs );
% Make sure that we get gaze data from the Eyelink
Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
% Open file to record data to
edfFile='demo.edf';
Eyelink('Openfile', edfFile);
% Calibrate the eye tracker
EyelinkDoTrackerSetup(el);
% Do a final check of calibration using driftcorrection
EyelinkDoDriftCorrection(el);
% Start recording eye position
Eyelink('StartRecording');
% Record a few samples before we actually start displaying
WaitSecs(0.1);
% Mark zero-plot time in data file
Eyelink('Message', 'SYNCTIME');
stopkey=KbName('ESCAPE');
eye_used = -1;

%----------------------------------------------------------------------
%                       Start blocks loop
%----------------------------------------------------------------------

for iContingency = StartContingency:nContingencies
    Screen('TextSize', window, 40);
    DrawFormattedText(window, 'NEW SOUNDS', 'center', 'center',textcolor);
    Screen('Flip',window);
    WaitSecs(1);
    Screen('Flip',window);
for iBlock = StartBlock:nBlocks
    
testtrials = EyeSound(iSub).Blocks(iBlock).TestTrials % This variable holds the movement directions of the test trials, the sound to be played, and whether the trial is congruent or incongruent

%----------------------------------------------------------------------
%                       Prepare sound stimuli
%----------------------------------------------------------------------
nrchannels = 1; % stereo
FS = 96000;

%iContingency = ceil(iBlock/EyeSound(iSub).nBlocksPerContingency);
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


;%% Acquisition trial start %%

% Instructions
Screen('TextSize', window, 40);
DrawFormattedText(window, 'EXPLORE', 'center', 'center',textcolor);
Screen('Flip',window);
WaitSecs(1);
Screen('Flip',window);

% Explore the dots and make sounds
t0 = GetSecs;
AcquisitionLog = []; % to be used for replaying, columns = xEye yEye, DotTime, Sound, SounTime, lines = events.

% Start the animation
while GetSecs-t0 < AcquisitionDur
    % Check recording status, stop display if error
    error=Eyelink('CheckRecording');
    if(error~=0)
        break;
    end
    % Check for keyboard press
    [keyIsDown, secs, keyCode] = KbCheck;
    % If escape key was pressed, stop display
    if keyCode(stopkey)
        break;
    end
    % Draw the matrix of dots to the screen
    Screen('DrawDots', window, dotPositionMatrix, dotSize, dotColor, dotCenter, 0);
    
    % Check for presence of a new sample update
        if Eyelink( 'NewFloatSampleAvailable') > 0
            % Get the sample in the form of an event structure
            evt = Eyelink( 'NewestFloatSample');
            if eye_used ~= -1 % Do we know which eye to use yet?
                % If we do, get current gaze position from sample
                xEye = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
                yEye = evt.gy(eye_used+1);
                % Do we have valid data and is the pupil visible?
                if xEye~=el.MISSING_DATA && yEye~=el.MISSING_DATA && evt.pa(eye_used+1)>0
                    % Draw the cursor as a white dot
                    Screen('DrawDots', window, [xEye yEye], 20, white, [], 2);
                    HideCursor;
    
    % Define responsive areas relative to center of screen

        % Make the squares size relative to the gap size
        squareSize = gap/10

        square1 = ((centerX-gap)-squareSize <= xEye && xEye <= (centerX-gap)+squareSize) && ((centerY-gap)-squareSize <= yEye && yEye <= (centerY-gap)+squareSize)
        square2 = ((centerX)-squareSize <= xEye && xEye <= (centerX)+squareSize) && ((centerY-gap)-squareSize <= yEye && yEye <= (centerY-gap)+squareSize)
        square3 = ((centerX+gap)-squareSize <= xEye && xEye <= (centerX+gap)+squareSize) && ((centerY-gap)-squareSize <= yEye && yEye <= (centerY-gap)+squareSize)
        square4 = ((centerX-gap)-squareSize <= xEye && xEye <= (centerX-gap)+squareSize) && ((centerY)-squareSize <= yEye && yEye <= (centerY)+squareSize)
        square5 = ((centerX)-squareSize <= xEye && xEye <= (centerX)+squareSize) && ((centerY)-squareSize <= yEye && yEye <= (centerY)+squareSize)
        square6 = ((centerX+gap)-squareSize <= xEye && xEye <= (centerX+gap)+squareSize) && ((centerY)-squareSize <= yEye && yEye <= (centerY)+squareSize)
        square7 = ((centerX-gap)-squareSize <= xEye && xEye <= (centerX-gap)+squareSize) && ((centerY+gap)-squareSize <= yEye && yEye <= (centerY+gap)+squareSize)
        square8 = ((centerX)-squareSize <= xEye && xEye <= (centerX)+squareSize) && ((centerY+gap)-squareSize <= yEye && yEye <= (centerY+gap)+squareSize)
        square9 = ((centerX+gap)-squareSize <= xEye && xEye <= (centerX+gap)+squareSize) && ((centerY+gap)-squareSize <= yEye && yEye <= (centerY+gap)+squareSize)

        
        % Define the responsive areas
        % square1 = (screenXpixels*0.20 <= xEye && xEye <= screenXpixels*0.30) && (screenYpixels*0.20 <= yEye && yEye <= screenYpixels*0.30);
        % square2 = (screenXpixels*0.45 <= xEye && xEye <= screenXpixels*0.55) && (screenYpixels*0.20 <= yEye && yEye <= screenYpixels*0.30);
        % square3 = (screenXpixels*0.70 <= xEye && xEye <= screenXpixels*0.80) && (screenYpixels*0.20 <= yEye && yEye <= screenYpixels*0.30);
        % square4 = (screenXpixels*0.20 <= xEye && xEye <= screenXpixels*0.30) && (screenYpixels*0.45 <= yEye && yEye <= screenYpixels*0.55);
        % square5 = (screenXpixels*0.45 <= xEye && xEye <= screenXpixels*0.55) && (screenYpixels*0.45 <= yEye && yEye <= screenYpixels*0.55);
        % square6 = (screenXpixels*0.70 <= xEye && xEye <= screenXpixels*0.80) && (screenYpixels*0.45 <= yEye && yEye <= screenYpixels*0.55);
        % square7 = (screenXpixels*0.20 <= xEye && xEye <= screenXpixels*0.30) && (screenYpixels*0.70 <= yEye && yEye <= screenYpixels*0.80);
        % square8 = (screenXpixels*0.45 <= xEye && xEye <= screenXpixels*0.55) && (screenYpixels*0.70 <= yEye && yEye <= screenYpixels*0.80);
        % square9 = (screenXpixels*0.70 <= xEye && xEye <= screenXpixels*0.80) && (screenYpixels*0.70 <= yEye && yEye <= screenYpixels*0.80);

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
    
    still = isequal(currentMouse, [xEye yEye]);
    
    if still == 0;
        fprintf(LOGFILEexplore,'\n%d',GetSecs-t0);
        fprintf(LOGFILEexplore, '\t%d', xEye);
        fprintf(LOGFILEexplore, '\t%d', yEye);
        fprintf(LOGFILEexplore, '\t%d', tone);
        currentMouse = [xEye yEye];
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
    else
                    % if data is invalid (e.g. during a blink), clear display
                    Screen('FillRect', window, el.backgroundcolour);
                    Screen('DrawText', window, message, 200, height-el.msgfontsize-20, el.msgfontcolour);
                    Screen('Flip',  el.window, [], 1); % don't erase
                end
            else % If we don't, first find eye that's being tracked
                eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
                if eye_used == el.BINOCULAR; % if both eyes are tracked
                    eye_used = el.LEFT_EYE; % use left eye
                end
            end
        end % if sample available
end % explore loop

% End exploring
WaitSecs(0.1);
Screen('TextSize', window, 20);
DrawFormattedText(window, 'Your time is up!', 'center', 'center',textcolor);
Screen('Flip',window);
WaitSecs(1);

%% Test trials loop

for iTest = 1:EyeSound(iSub).nTestTrialsperBlock % Loop over the 6 test trials of a block
    fprintf(LOGFILEtest,'\n%d', iSub);
    fprintf(LOGFILEtest,'\t%d', iBlock);
    fprintf(LOGFILEtest,'\t%d', iTrial); % Make this 1 or 2 depending on whether acquisition or test (make this variable)
    fprintf(LOGFILEtest, '\t%d', condition); % Condition: actively or passively learned? Introduce this variable before
    
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
                    xDot = xDot - speed
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
                    xDot = xDot - speed
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
                    xDot = xDot - speed
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
                    xDot = xDot - speed
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
                    xDot = xDot - speed
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
                    xDot = xDot - speed
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
                    xDot = xDot + speed
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
end % for-loop for blocks
end % for-loop for contingencies

%% Close and cleanup
sca; % Close window
fclose(LOGFILEexplore);
fclose(LOGFILEtest);
PsychPortAudio('Close'); % Close the audio device

end