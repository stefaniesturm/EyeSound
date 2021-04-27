function EyeSound_free

% -------------------------------------------------------------------------
%                           ENVIRONMENT SETUP
% -------------------------------------------------------------------------

location = 1; % 1 for home, 2 for lab

if location == 2
    % In the lab
    cd 'C:\USER\Stefanie\EyeSound\';
    home_path = 'C:\USER\Stefanie\EyeSound\';
    Sounds_path = 'C:\USER\Stefanie\EyeSound\sounds\';
    Results_path = 'C:\USER\Stefanie\EyeSound\results\';
    headphones = 1; % In the lab, this should be 1, at home, it should be 0
    dummymode = 0;
elseif location == 1
    % At home
    cd '/home/stefanie/GitHub/EyeSound/';
    home_path = '/home/stefanie/GitHub/EyeSound/';
    Sounds_path = '/home/stefanie/GitHub/EyeSound/sounds/';
    Results_path = '/home/stefanie/GitHub/EyeSound/results/';
    Screen('Preference', 'SkipSyncTests', 1);
    headphones = 0; % In the lab, this should be 1, at home, it should be 0
    dummymode = 1;
end

% Load matrix with info on stimuli
load('EyeSound_data.mat'); % Load the matrix that contains info about stimuli
iSub = 1
iContingency = 1
iBlock = 1
contingencies(iContingency) = 1;

% -------------------------------------------------------------------------
%                          SETUP FOR VISUAL STIMULI
% -------------------------------------------------------------------------
PsychDefaultSetup(2);
screenNumber=max(Screen('Screens'));

% Appearances
white = [1 1 1];
black = [0 0 0];
red = [1 0 0];
window_size = [0 0 400 400]; % small window for debugging; comment out if fullscreen is wanted

% Open an on screen window and color it black
% try
if exist('window_size')
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black, window_size); % Open for debugging
else
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black); % Open fullscreen
    HideCursor;
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
dotRed = red;
dotBig = 180;
dotBlack = black;
dotSmall = 30;

% Initialise variables necessary for playing sounds based on movements
% (it's very complicated)
lastStop = 0;
moveDirection = -1;
previousStop = -1;
currentMouse = [-1 -1];
soundPlayed = 0; % Sound identity (Factor)

% This is needed for the animations
speed = 8; % This is how fast animation moves. In the lab, if the speed is 8, the duration of the animations will be 0.5 seconds
ifi = Screen('GetFlipInterval', window); % You need this for the animations
vbl=Screen('Flip', window); % You need this for the animations

% Below we define the positions in which the dots can start/end during animations (the centers of the dots) relative to the center of the screen
centerX = screenXpixels/2;
centerY = screenYpixels/2;
gap = screenYpixels/4; % the distance between the dots is a quarter of the length of the y-axis

pos1 = [centerX-gap centerY-gap];
pos2 = [centerX centerY-gap];
pos3 = [centerX+gap centerY-gap];
pos4 = [centerX-gap centerY];
pos5 = [centerX centerY];
pos6 = [centerX+gap centerY];
pos7 = [centerX-gap centerY+gap];
pos8 = [centerX centerY+gap];
pos9 = [centerX+gap centerY+gap];

%----------------------------------------------------------------------
%                       Start eyetracker
%----------------------------------------------------------------------
if dummymode == 0
    
    % Added this recently, not sure we need it
    if (Eyelink('Initialize') ~= 0)
        return;
        fprintf('Problem initializing eyelink\n');
    end;
    
    % Send some info about the experiment window to eyelink
    el=EyelinkInitDefaults(window);
    
    % Initialization of the connection with the Eyelink Gazetracker.
    % exit program if this fails.
    if ~EyelinkInit(dummymode)
        fprintf('Eyelink Init aborted.\n');
        cleanup;  % cleanup function
        return;
    end
    
    % the following code is used to check the version of the eye tracker
    % and version of the host software
    sw_version = 0;
    
    [v vs]=Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.', vs );
    
    % open edf file to record data to
    edfFile= 'free_train.edf';
    i = Eyelink('Openfile', edfFile);
    if i~=0
        fprintf('Cannot create EDF file ''%s'' ', edfFile);
        Eyelink( 'Shutdown');
        Screen('CloseAll');
        return;
    end
    % Calibrate the eye tracker
    % setup the proper calibration foreground and background colors
    el.backgroundcolour = black;
    el.calibrationtargetcolour = red;
    el.targetbeep = 0;
    el.feedbackbeep = 0;
    
    % you must call this function to apply the changes from above
    EyelinkUpdateDefaults(el);
    
    % Calibrate the eye tracker
    EyelinkDoTrackerSetup(el);
    
    % Title message to EDF file
    Eyelink('command', 'add_file_preamble_text ''Eye-tracker data from EyeSound training.''');
    
    % SET UP TRACKER CONFIGURATION
    % Setting the proper recording resolution, proper calibration type,
    % as well as the data file content;
    Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, screenXpixels-1, screenYpixels-1);
    Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, screenXpixels-1, screenYpixels-1);
    
    % set EDF file contents using the file_sample_data and
    % file-event_filter commands
    % set link data thtough link_sample_data and link_event_filter
    Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
    Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
    
    % check the software version
    % add "HTARGET" to record possible target data for EyeLink Remote
    if sw_version >=4
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,HTARGET,GAZERES,STATUS,INPUT');
        Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');
    else
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT');
        Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
    end
    
    % make sure we're still connected.
    if Eyelink('IsConnected')~=1 && dummymode == 0
        fprintf('not connected, clean up\n');
        Eyelink( 'Shutdown');
        Screen('CloseAll');
        return;
    end
end

% -------------------------------------------------------------------------
%                          PREPARE AUDIO DEVICE
% -------------------------------------------------------------------------

% Start the audio device:
nrchannels = 2; % We want the sound output to be stereo
FS = 96000;
device = [];
InitializePsychSound; % Initialize the sound device

headphone_factor = 0.750; % I chose this because it's in the middle between two that were used in IluAg
starting_dB = 70;
intfactor = 10^((starting_dB-100)/20)*headphone_factor;

if headphones == 0
    paHandle = PsychPortAudio('Open', device, [], 0, FS, nrchannels); % On my computer at home
elseif headphones == 1
    % In the lab use this:
    paHandle = PsychPortAudio('Open',[],1,3,FS,2, [], [], [6 7]); % Open the Audio port and get a handle to refer to it in subsequent calls
    % [6 7] are the headphones channels in the lab
end

% Load sounds to be used in this block corresponding to the movement moveDirectionections
SoundNames = EyeSound_data(iSub).Contingencies(iContingency,:);

tone = cell(1,length(SoundNames)); % Initialise array for sounds

for iSound = 1:length(SoundNames)
    [soundfile, ~] = audioread(char(strcat(Sounds_path, SoundNames(iSound)))); % Load sound file
    soundfile = soundfile(:,1)./max(abs(soundfile(:,1))); % Normalize
    soundfile = soundfile'; % Transpose
    soundfile = [soundfile ; soundfile]; % Make tone stereo
    if headphones == 1
        soundfile = soundfile*intfactor; % Apply loudness settings
    end
    tone{iSound} = soundfile;
end

if dummymode == 0
    % do a check of calibration using driftcorrection
    EyelinkDoDriftCorrection(el);
end

Screen('TextSize', window, 60);
DrawFormattedText(window, 'EXPLORAR', 'center', 'center',white);
Screen('Flip',window,0);
WaitSecs(1);

if dummymode == 0
    Eyelink('Message', 'New level: %d.', iContingency-1);
    Eyelink('Message', 'TRIGGER %03d', ContingencyStartTrigger);
    % The message below will be shown on the host PC
    Eyelink('command', 'record_status_message "TRAINING %d/%d"', iContingency-1, length(contingencies));
    % Before recording, we place reference graphics on the host display
    % Must be offline to draw to EyeLink screen
    Eyelink('Command', 'set_idle_mode');
    
    % clear tracker display and draw box at center
    Eyelink('Command', 'clear_screen 0')
    Eyelink('command', 'draw_box %d %d %d %d 15', screenXpixels/2-50, screenYpixels/2-50, screenXpixels/2+50, screenYpixels/2+50);
    
    % start recording eye position (preceded by a short pause so that
    % the tracker can finish the mode transition)
    % The paramerters for the 'StartRecording' call controls the
    % file_samples, file_events, link_samples, link_events availability
    Eyelink('Command', 'set_idle_mode');
    WaitSecs(0.05);
    Eyelink('StartRecording');
    eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
    % returns 0 (LEFT_EYE), 1 (RIGHT_EYE) or 2 (BINOCULAR) depending on what data is
    if eye_used == 2
        eye_used = 0; % use the left_eye data
    end
    % record a few samples before we actually start displaying
    % otherwise you may lose a few msec of data
    WaitSecs(0.1);
    
end

% Prepare the timer that plays sound with delay of 1 sec
soundTimer = timer;
soundTimer.StartDelay = 0.75;
soundTimer.TimerFcn = @(x, y)eval(PsychPortAudio('Start', paHandle, 1));

while ~KbCheck
    %conditional = (GetSecs-AcquisitionStartTime < AcquisitionDur); % Active trials end when the time is up
    if dummymode == 0
        error=Eyelink('CheckRecording');
        if(error~=0)
            break;
        end
    end
    % Draw the matrix of dots to the screen
    Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
    Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
    %     if contingencies(iContingency) == 2 % passive
    %         % Define the position of the cursor using the logfiles
    %         row = row+1;
    %         xMouse = columnX(row);
    %         yMouse = columnY(row);
    %     else % active
    if dummymode == 1
        [xMouse, yMouse, ~] = GetMouse(window);
    elseif dummymode == 0
        if Eyelink( 'NewFloatSampleAvailable') > 0
            disp('new float sample was available');
            % get the sample in the form of an event structure
            evt = Eyelink( 'NewestFloatSample');
            evt.gx
            evt.gy
            if eye_used ~= -1 % do we know which eye to use yet?
                % if we do, get current gaze position from sample
                x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
                y = evt.gy(eye_used+1);
                % do we have valid data and is the pupil visible?
                if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0
                    xMouse=x;
                    yMouse=y;
                end
            end
        end
    end
    %     end
    % Draw the cursor as a white dot
    Screen('DrawDots', window, [xMouse yMouse], 20, white, [], 2);
    HideCursor;
    % Make the squares size relative to the gap size
    squareSize = gap/3; % This is the area that will be responsive when you hover over it
    
    % Define responsive areas relative to center of screen
    square1 = ((centerX-gap)-squareSize <= xMouse && xMouse <= (centerX-gap)+squareSize) && ((centerY-gap)-squareSize <= yMouse && yMouse <= (centerY-gap)+squareSize);
    square2 = ((centerX)-squareSize <= xMouse && xMouse <= (centerX)+squareSize) && ((centerY-gap)-squareSize <= yMouse && yMouse <= (centerY-gap)+squareSize);
    square3 = ((centerX+gap)-squareSize <= xMouse && xMouse <= (centerX+gap)+squareSize) && ((centerY-gap)-squareSize <= yMouse && yMouse <= (centerY-gap)+squareSize);
    square4 = ((centerX-gap)-squareSize <= xMouse && xMouse <= (centerX-gap)+squareSize) && ((centerY)-squareSize <= yMouse && yMouse <= (centerY)+squareSize);
    square5 = ((centerX)-squareSize <= xMouse && xMouse <= (centerX)+squareSize) && ((centerY)-squareSize <= yMouse && yMouse <= (centerY)+squareSize);
    square6 = ((centerX+gap)-squareSize <= xMouse && xMouse <= (centerX+gap)+squareSize) && ((centerY)-squareSize <= yMouse && yMouse <= (centerY)+squareSize);
    square7 = ((centerX-gap)-squareSize <= xMouse && xMouse <= (centerX-gap)+squareSize) && ((centerY+gap)-squareSize <= yMouse && yMouse <= (centerY+gap)+squareSize);
    square8 = ((centerX)-squareSize <= xMouse && xMouse <= (centerX)+squareSize) && ((centerY+gap)-squareSize <= yMouse && yMouse <= (centerY+gap)+squareSize);
    square9 = ((centerX+gap)-squareSize <= xMouse && xMouse <= (centerX+gap)+squareSize) && ((centerY+gap)-squareSize <= yMouse && yMouse <= (centerY+gap)+squareSize);
    
    %---SQUARE_1---%
    if square1 == true && lastStop == 2
        moveDirection = 1;
        lastStop = 1;
    elseif square1 == true && lastStop == 4
        moveDirection = 3;
        lastStop = 1;
    elseif square1 == true && lastStop == 5
        moveDirection = 5;
        lastStop = 1;
    elseif square1 == true
        lastStop = 1;
    end
    
    %---SQUARE_2---%
    if square2 == true && lastStop == 1
        moveDirection = 2;
        lastStop = 2;
    elseif square2 == true && lastStop == 3
        moveDirection = 1;
        lastStop = 2;
    elseif square2 == true && lastStop == 4
        moveDirection = 7;
        lastStop = 2;
    elseif square2 == true && lastStop == 5
        moveDirection = 3;
        lastStop = 2;
    elseif square2 == true && lastStop == 6
        moveDirection = 5;
        lastStop = 2;
    elseif square2 == true
        lastStop = 2;
    end
    
    %---SQUARE_3---%
    if square3 == true && lastStop == 2
        moveDirection = 2;
        lastStop = 3;
    elseif square3 == true && lastStop == 5
        moveDirection = 7;
        lastStop = 3;
    elseif square3 == true && lastStop == 6
        moveDirection = 3;
        lastStop = 3;
    elseif square3 == true
        lastStop = 3;
    end
    
    %---SQUARE_4---%
    if square4 == true && lastStop == 1
        moveDirection = 4;
        lastStop = 4;
    elseif square4 == true && lastStop == 2
        moveDirection = 6;
        lastStop = 4;
    elseif square4 == true && lastStop == 5
        moveDirection = 1;
        lastStop = 4;
    elseif square4 == true && lastStop == 7
        moveDirection = 3;
        lastStop = 4;
    elseif square4 == true && lastStop == 8
        moveDirection = 5;
        lastStop = 4;
    elseif square4 == true
        lastStop = 4;
    end
    
    %---SQUARE_5---%
    if square5 == true && lastStop == 1
        moveDirection = 8;
        lastStop = 5;
    elseif square5 == true && lastStop == 2
        moveDirection = 4;
        lastStop = 5;
    elseif square5 == true && lastStop == 3
        moveDirection = 6;
        lastStop = 5;
    elseif square5 == true && lastStop == 4
        moveDirection = 2;
        lastStop = 5;
    elseif square5 == true && lastStop == 6;
        moveDirection = 1;
        lastStop = 5;
    elseif square5 == true && lastStop == 7
        moveDirection = 7;
        lastStop = 5;
    elseif square5 == true && lastStop == 8
        moveDirection = 3;
        lastStop = 5;
    elseif square5 == true && lastStop == 9
        moveDirection = 5;
        lastStop = 5;
    elseif square5 == true
        lastStop = 5;
    end
    
    %---SQUARE_6---%
    if square6 == true && lastStop == 2
        moveDirection = 8;
        lastStop = 6;
    elseif square6 == true && lastStop == 3
        moveDirection = 4;
        lastStop = 6;
    elseif square6 == true && lastStop == 5
        moveDirection = 2;
        lastStop = 6;
    elseif square6 == true && lastStop == 8
        moveDirection = 7;
        lastStop = 6;
    elseif square6 == true && lastStop == 9
        moveDirection = 3;
        lastStop = 6;
    elseif square6 == true
        lastStop = 6;
    end
    
    %---SQUARE_7---%
    if square7 == true && lastStop == 4
        moveDirection = 4;
        lastStop = 7;
    elseif square7 == true && lastStop == 5
        moveDirection = 6;
        lastStop = 7;
    elseif square7 == true && lastStop == 8
        moveDirection = 1;
        lastStop = 7;
    elseif square7 == true
        lastStop = 7;
    end
    
    %---SQUARE_8---%
    if square8 == true && lastStop == 4
        moveDirection = 8;
        lastStop = 8;
    elseif square8 == true && lastStop == 5
        moveDirection = 4;
        lastStop = 8;
    elseif square8 == true && lastStop == 6
        moveDirection = 6;
        lastStop = 8;
    elseif square8 == true && lastStop == 7
        moveDirection = 2;
        lastStop = 8;
    elseif square8 == true && lastStop == 9
        moveDirection = 1;
        lastStop = 8;
    elseif square8 == true
        lastStop = 8;
    end
    
    %---SQUARE_9---%
    if square9 == true && lastStop == 5
        moveDirection = 8;
        lastStop = 9;
    elseif square9 == true && lastStop == 6
        moveDirection = 4;
        lastStop = 9;
    elseif square9 == true && lastStop == 8
        moveDirection = 2;
        lastStop = 9;
    elseif square9 == true
        lastStop = 9;
    end
    
    Screen('Flip', window); % Use mouse coordinates
    
    if lastStop ~= previousStop
        previousStop = lastStop;
        PsychPortAudio('Stop', paHandle);
        switch (moveDirection)
            case 1
                stop(soundTimer); % Interrupt timers if already running
                PsychPortAudio('FillBuffer', paHandle, tone{1});
                start(soundTimer) % Start new timer for current sound
            case 2
                stop(soundTimer); % Interrupt timers if already running
                PsychPortAudio('FillBuffer', paHandle, tone{2});
                start(soundTimer) % Start new timer for current sound
            case 3
                stop(soundTimer); % Interrupt timers if already running
                PsychPortAudio('FillBuffer', paHandle, tone{3});
                start(soundTimer) % Start new timer for current sound
            case 4
                stop(soundTimer); % Interrupt timers if already running
                PsychPortAudio('FillBuffer', paHandle, tone{4});
                start(soundTimer) % Start new timer for current sound
            case 5
                stop(soundTimer); % Interrupt timers if already running
                PsychPortAudio('FillBuffer', paHandle, tone{5});
                start(soundTimer) % Start new timer for current sound
            case 6
                stop(soundTimer); % Interrupt timers if already running
                PsychPortAudio('FillBuffer', paHandle, tone{6});
                start(soundTimer) % Start new timer for current sound
            case 7
                stop(soundTimer); % Interrupt timers if already running
                PsychPortAudio('FillBuffer', paHandle, tone{7});
                start(soundTimer) % Start new timer for current sound
            case 8
                stop(soundTimer); % Interrupt timers if already running
                PsychPortAudio('FillBuffer', paHandle, tone{8});
                start(soundTimer) % Start new timer for current sound
        end % switch
    end % if lastStop is not previousStop
end % Acquisition trial
stop(soundTimer);
sca;
PsychPortAudio('Close'); % Close the audio device

if dummymode == 0
    
    Eyelink('Command', 'set_idle_mode');
    WaitSecs(0.5);
    Eyelink('CloseFile');
    
    % download data file
    try
        fprintf('Receiving data file ''%s''\n', edfFile );
        status=Eyelink('ReceiveFile');
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2==exist(edfFile, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
        end
    catch
        fprintf('Problem receiving data file ''%s''\n', edfFile );
    end
    
    Eyelink('Shutdown');
    
end

cd(home_path);
ShowCursor;

end