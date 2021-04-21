function EyeSound_run(iSub, iContingency)

% iSub is subject number, StartContingency is for restarting at an advanced level
% if something fails; if you start from the beginning, make that 1

% This script runs the main experiment for EyeSound and saves output into 3 files,
% acquisition logfile, test logfile, eyetracker logfile, and it also sends
% triggers to porttalk for EEG recording

% -------------------------------------------------------------------------
%                                  SETUP
% -------------------------------------------------------------------------

location = 1; % 1 if home, 2 if in the lab

% Set this to 1 if you want to use Eyelink and or Porttalk
port_exist = 0;
nano_exist = 0; % Turn on if you want to use Nanopad instead of keyboard
headphones = 0; % In the lab, this should be 1, at home, it should be 0
dummymode = 1; % 0 if you are using eye tracker, 1 if you are using mouse
training = 2; % this means that it is not a training (for the events logfile)

if location == 2
    % In the lab
    cd 'C:\USER\Stefanie\EyeSound\'
    Sounds_path = 'C:\USER\Stefanie\EyeSound\sounds\';
    Results_path = 'C:\USER\Stefanie\EyeSound\results\';
    home_path = 'C:\USER\Stefanie\EyeSound\';
elseif location == 1
    % Linux:
    cd '/home/stefanie/GitHub/EyeSound/';
    Sounds_path = '/home/stefanie/GitHub/EyeSound/sounds/';
    Results_path = '/home/stefanie/GitHub/EyeSound/results/';
    home_path = '/home/stefanie/GitHub/EyeSound/';
    Screen('Preference', 'SkipSyncTests', 1);
end

% Load matrix with info on stimuli
load('EyeSound_data.mat'); % Load the matrix that contains info about stimuli

% Counterbalance order of active and passive conditions
if EyeSound_data(iSub).Counterbalancing == 1 % Active first
    % contingencies = [1 2 1 2 1 2 1 2 1 2 1 2 1 2]; % 1 is active and 2 is passive
    contingencies = [1 2];
elseif EyeSound_data(iSub).Counterbalancing == 2 % Passive first
    %contingencies = [2 1 2 1 2 1 2 1 2 1 2 1 2 1]; % 1 is active and 2 is passive
    contingencies = [2 1]; % debugging
end

nTests = 1; % should be 6
nBlocks = 1; % should be 7
MaxResp = 2.5; % Maximum response time for questions in s
AcquisitionDur = 20; % 20sec for acquisition trials, less for debugging
ttCounter = 7; % If we did one level of training, that should be 7 (blocks)
% If we did two contingencies of training, it would be 14, etc.
columnX = []; % initialise this variable so it exists
columnY = []; % initialise this variable so it exists
row = 0; % initialise this variable so it exists

% -------------------------------------------------------------------------
%                          SETUP FOR VISUAL STIMULI
% -------------------------------------------------------------------------

% AssertOpenGL;
% Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);
screenNumber=max(Screen('Screens'));

% Appearances
white = [1 1 1];
black = [0 0 0];
red = [1 0 0];
% window_size = [0 0 400 400]; % small window for debugging; comment out if fullscreen is wanted

% Open an on screen window and color it black
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
speed = 7.5; % This is how fast animation moves!!!
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

% -------------------------------------------------------------------------
%                     RESPONSE DEVICE SETTINGS
% -------------------------------------------------------------------------

if nano_exist == 0 % This is to use a normal keyboard
    
    % To get the names of keys, execute KbName without arguments and press the
    % key you want to get the code for
    
    % Use common key mapping for all operating systems and define the escape
    % key as abort key:
    KbName('UnifyKeyNames');
    % Counterbalance response keys
    if EyeSound_data(iSub).Counterbalancing == 1
        YesKey = KbName('RightArrow');
        NoKey = KbName('LeftArrow');
    elseif EyeSound_data(iSub).Counterbalancing == 2
        NoKey = KbName('RightArrow');
        YesKey = KbName('LeftArrow');
    end
    % esc = KbName('ESCAPE');
    % keyIsDown = 0; % This may be redundant, check that if everything else is working
    
elseif nano_exist == 1 % This is to use the nanopad
    
    addpath('C:\USER\Stefanie\EyeSound\midi_interface');% add path to midi interface scripts to be able to use nanoPAD2
    midi_interface('open', 1);% open midi_interface
    key = []; % clear any responses
    
    % button codes on NANOPad (setting 1):
    % trackpad || 37    39    41    43    45    47    49    51
    % trackpad || 36    38    40    42    44    46    48    50
    
    if EyeSound_data(iSub).Counterbalancing == 1 % Yes = right, No = left
        % Define response buttons
        % buttontypes = [38;36]; % lower row, closer to the trackpad: left (1/36) = NO/1st, right (2/38) = YES/2nd
        nanoYES = 38;
        nanoNO = 36;
    elseif EyeSound_data(iSub).Counterbalancing == 2 % Yes = left, No = right
        % buttontypes = [36;38]; % lower row, closer to the trackpad: left (1/36) = YES/1st, right (2/38) = NO/2nd
        nanoYES = 36;
        nanoNO = 38;
    end
end

% -------------------------------------------------------------------------
%                            PREPARE LOGFILES
% -------------------------------------------------------------------------

cd(Results_path);

% Acquisition logfile (movement coordinates)
explorelogfilename = [Results_path sprintf('%02d',iSub) 'coordinates.txt'];
LOGFILEexplore = fopen(explorelogfilename, 'a+'); % append information, don't overwrite

% Test logfile (responses)
eventlogfilename = [Results_path sprintf('%02d', iSub) 'events.txt'];
LOGFILEevents = fopen(eventlogfilename, 'a+'); % append, don't overwrite

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
    edfFile= [sprintf('%02d', iSub) 'main.edf'];
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
    
    % Hide the mouse cursor;
    %     Screen('HideCursorHelper', window);
    
    % Calibrate the eye tracker
    EyelinkDoTrackerSetup(el);
    
    % do a final check of calibration using driftcorrection
    EyelinkDoDriftCorrection(el);
    
    % Title message to EDF file
    Eyelink('command', 'add_file_preamble_text ''Eye-tracker data from EyeSound training.''');
    
    % SET UP TRACKER CONFIGURATION
    % Setting the proper recording resolution, proper calibration type,
    % as well as the data file content;
    Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, screenXpixels-1, screenYpixels-1);
    Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, screenXpixels-1, screenYpixels-1);
    % set calibration type.
    
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
%----------------------------------------------------------------------
%                           Start porttalk
%----------------------------------------------------------------------
if port_exist == 1
    config_io('open');
end
% -------------------------------------------------------------------------
%                          PREPARE AUDIO DEVICE
% -------------------------------------------------------------------------

% Start the audio device:
nrchannels = 2; % We want the sound output to be stereo
FS = 96000;
device = [];
InitializePsychSound(1); % Initialize the sound device

headphone_factor = 0.750; % I chose this because it's in the middle between two that were used in IluAg
starting_dB = 50;
intfactor = 10^((starting_dB-100)/20)*headphone_factor;

if headphones == 0
    paHandle = PsychPortAudio('Open', device, [], 0, FS, nrchannels); % On my computer at home
elseif headphones == 1
    % In the lab use this:
    paHandle = PsychPortAudio('Open',[],1,3,FS,2, [], [], [6 7]); % Open the Audio port and get a handle to refer to it in subsequent calls
    % [6 7] are the headphones channels in the lab
end

%%
% -------------------------------------------------------------------------
%                               START EXPERIMENT
% -------------------------------------------------------------------------

ExperimentStartTime = GetSecs;

Screen('TextSize', window, 60); % set text size
Screen('TextFont', window, 'Arial');
DrawFormattedText(window, 'El experimentador iniciará el experimento.', 'center', 'center',white); % Wait for experimenter input
Screen('Flip',window);
KbStrokeWait; % Experimenter button press

% keyIsDown = 0; FlushEvents('keyDown');
% while keyIsDown ==0
%     [keyIsDown, secs, keyCode] = KbCheck;
% end
% keyIsDown = 0;

%%

% Experiment loop (7 active and 7 passive contingencies)
% for iContingency = StartContingency:length(contingencies)

% Information for logfiles
condition = contingencies(iContingency)
ContingencyStartTrigger = 254;

% Load sounds to be used in this block corresponding to the movement moveDirectionections
SoundNames = EyeSound_data(iSub).Contingencies(iContingency+1,:); % +1 to not repeat from training

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

% In passive trials, load coordinates for each block (do this here
% because it will slow down the script and it's better if that happens
% now

random_blocks = randperm(nBlocks); % Randomise order of blocks during
% replay to make them less recognisable (this is only needed in
% passive contingencies

if contingencies(iContingency) == 2 % In passive levels
    
    Screen('TextSize', window, 60);
    DrawFormattedText(window, '...', 'center', 'center',white);
    Screen('Flip',window);
    
    if location == 1 % if at home
        
        % IMPORT COORDINATES FROM ACTIVE LEVEL PREVIOUS TO THIS ONE
        % Set up the Import Options and import the data
        opts = delimitedTextImportOptions("NumVariables", 8);
        
        % Specify range and delimiter
        opts.DataLines = [2, Inf];
        opts.Delimiter = "\t";
        
        % Specify column names and types
        opts.VariableNames = ["SubjectLevelBlockConditionTimeXMouseYMouseSound", "Level", "Block", "Condition", "Time", "xMouse", "yMouse", "Sound"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double"];
        
        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
        
        
        % Import the data
        coordinates_filename = [Results_path sprintf('%02d',iSub) 'coordinates.txt'];
        coordinates = readtable(coordinates_filename, opts);
        % Convert to output type
        coordinates = table2array(coordinates);
        % Clear temporary variables
        clear opts
        
    elseif location == 2 % In the lab
        
        % Initialize variables.
        filename = [Results_path sprintf('%02d',iSub) 'coordinates.txt'];
        delimiter = '\t';
        startRow = 2;
        
        % Read columns of data as text:
        % For more information, see the TEXTSCAN documentation.
        formatSpec = '%s%s%s%s%s%s%s%s%[^\n\r]';
        
        % Open the text file.
        fileID = fopen(filename,'r');
        
        % Read columns of data according to the format.
        % This call is based on the structure of the file used to generate this
        % code. If an error occurs for a different file, try regenerating the code
        % from the Import Tool.
        dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
        
        % Close the text file.
        fclose(fileID);
        
        % Convert the contents of columns containing numeric text to numbers.
        % Replace non-numeric text with NaN.
        raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
        for col=1:length(dataArray)-1
            raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
        end
        numericData = NaN(size(dataArray{1},1),size(dataArray,2));
        
        for col=[1,2,3,4,5,6,7,8]
            % Converts text in the input cell array to numbers. Replaced non-numeric
            % text with NaN.
            rawData = dataArray{col};
            for row=1:size(rawData, 1)
                % Create a regular expression to detect and remove non-numeric prefixes and
                % suffixes.
                regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
                try
                    result = regexp(rawData(row), regexstr, 'names');
                    numbers = result.numbers;
                    
                    % Detected commas in non-thousand locations.
                    invalidThousandsSeparator = false;
                    if numbers.contains(',')
                        thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                        if isempty(regexp(numbers, thousandsRegExp, 'once'))
                            numbers = NaN;
                            invalidThousandsSeparator = true;
                        end
                    end
                    % Convert numeric text to numbers.
                    if ~invalidThousandsSeparator
                        numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                        numericData(row, col) = numbers{1};
                        raw{row, col} = numbers{1};
                    end
                catch
                    raw{row, col} = rawData{row};
                end
            end
        end
        
        % Replace non-numeric cells with NaN
        R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
        raw(R) = {NaN}; % Replace non-numeric cells
        
        % Create output variable
        coordinates = cell2mat(raw);
        
        % Clear temporary variables
        clearvars filename delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp R;
    end
end

% New sounds
Screen('TextSize', window, 60);
DrawFormattedText(window, 'NUEVOS SONIDOS', 'center', 'center',white);
ContingencyStartTime = GetSecs;
Screen('Flip',window);

% REPORT EVENT: CUE %

% 2. Send porttalk trigger
if port_exist == 1
    porttalk(hex2dec('CFB8'), ContingencyStartTrigger, 1000);
end

% 4. Write into logfile
fprintf(LOGFILEevents,'\n%d', iSub);
fprintf(LOGFILEevents,'\t%d', iContingency);
fprintf(LOGFILEevents,'\tNaN'); % iBlock
fprintf(LOGFILEevents,'\tNaN'); % Trial number
fprintf(LOGFILEevents,'\t%d', condition); % Condition: actively or passively learned?
fprintf(LOGFILEevents,'\tNaN'); % TrialType
fprintf(LOGFILEevents,'\t%d', 1); % EventType: 1. cue 2. acquisition-sound 3. test-sound 4. response
fprintf(LOGFILEevents,'\t%d', ContingencyStartTime-ExperimentStartTime); % event time
fprintf(LOGFILEevents,'\tNaN'); % SoundID
fprintf(LOGFILEevents,'\tNaN'); % AnimationID
fprintf(LOGFILEevents,'\tNaN'); % MovDir
fprintf(LOGFILEevents,'\tNaN'); % Congruency
fprintf(LOGFILEevents,'\tNaN'); % Response

% END REPORT

% Each level has 6 blocks
for iBlock = 1:nBlocks
    ttCounter = ttCounter+1; % We count here the blocks without restarting at new level
    % Test trial codes change per block
    testtrials = EyeSound_data(iSub).Blocks(ttCounter).TestTrials;
    
    % Send trigger for new block
    newBlockTrigger = 252;
    
    if iBlock < 1 % In all but the first block of a contingency
        % 2. Send porttalk trigger
        if port_exist == 1
            porttalk(hex2dec('CFB8'), newBlockTrigger, 1000);
        end
        
        % 3. Send Eyelink message
        if dummymode == 0
            Eyelink('Message', 'New block.');
            Eyelink('Message', 'TRIGGER %03d', newBlockTrigger);
        end
    end
    
    % ACQUISITRION TRIAL (can be passive or active)
    
    TrialType = 1; % acquisition trial
    
    if contingencies(iContingency) == 1 && dummymode == 0
        % do a check of calibration using driftcorrection
        EyelinkDoDriftCorrection(el);
    end
    
    % Instructions
    Screen('TextSize', window, 60);
    if contingencies(iContingency) == 1 % Active level
        DrawFormattedText(window, 'EXPLORAR', 'center', 'center',white);
    elseif contingencies(iContingency) == 2 % Passive level
        DrawFormattedText(window, 'OBSERVAR', 'center', 'center',white);
    end
    
    Screen('Flip',window, ContingencyStartTime+1); % Show explore cue 1s after "Nuevos sonidos"
    ExploreCue = GetSecs;
    
    Screen('Flip',window, (ExploreCue+0.5));
    AcquisitionStartTime = GetSecs;
    
    % REPORT EVENT: CUE %
    
    % 1. Create trigger
    
    AcquisitionStartTrigger = 250;
    
    % 2. Send porttalk trigger
    if port_exist == 1
        porttalk(hex2dec('CFB8'), AcquisitionStartTrigger, 1000);
    end
    
    % 3. Send Eyelink message
    if dummymode == 0
        Eyelink('Message', 'Start of acquisition trial.');
        Eyelink('Message', 'TRIGGER %03d', AcquisitionStartTrigger);
    end
    
    % 4. Write into logfile
    fprintf(LOGFILEevents,'\n%d', iSub);
    fprintf(LOGFILEevents,'\t%d', iContingency);
    fprintf(LOGFILEevents,'\t%d', iBlock); % iBlock
    fprintf(LOGFILEevents,'\tNaN'); % Trial number
    fprintf(LOGFILEevents,'\t%d', condition); % Condition: actively or passively learned?
    fprintf(LOGFILEevents,'\t%d', TrialType); % TrialType: 1 = acquisition, 2 = test
    fprintf(LOGFILEevents,'\t%d', 1); % EventType: 1. cue 2. acquisition-sound 3. test-sound 4. response
    fprintf(LOGFILEevents,'\t%d', AcquisitionStartTime-ExperimentStartTime); % event time
    fprintf(LOGFILEevents,'\tNaN'); % SoundID
    fprintf(LOGFILEevents,'\tNaN'); % AnimationID
    fprintf(LOGFILEevents,'\tNaN'); % MovDir
    fprintf(LOGFILEevents,'\tNaN'); % Congruency
    fprintf(LOGFILEevents,'\tNaN'); % Response
    
    % END REPORT
    
    if contingencies(iContingency) == 2 % in passive contingencies
        row = 0;
        ind1 = coordinates(:,2) == iContingency-1; % Make a logical index that selects coordinates from the current contingency
        coordinates_block = coordinates(ind1,:); % Select appropriate coordinates
        ind2 = coordinates_block(:,3) == random_blocks(iBlock); % Logical index for block
        coordinates_block = coordinates_block(ind2,:); % Select coordinates for this specific block
        columnX = coordinates_block(:,6); % This column contains the X values
        columnY = coordinates_block(:,7); % This column contains the Y values
    end
    
    % TRY START RECORDING HERE
    if dummymode == 0 && contingencies(iContingency) == 1
        Eyelink('Message', 'New level: %d.', iContingency);
        Eyelink('Message', 'TRIGGER %03d', ContingencyStartTrigger);
        % The message below will be shown on the host PC
        Eyelink('command', 'record_status_message "CONTINGENCY %d/%d"', iContingency, length(contingencies));
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
    soundTimer.StartDelay = 1;
    soundTimer.TimerFcn = @(x,y)eval(PsychPortAudio('Start', paHandle, 1));
    reportTimer = timer;
    reportTimer.StartDelay = 1;
    
    % Start the animation
    
    % For explanations on how to do gaze contingent Eyelink stuff, check
    % https://www.youtube.com/watch?v=GjHZjgDbedQ&list=PLOdF-B36TwspkYxrpyJVNr5WBi19LpRwi&index=4
    % https://github.com/Psychtoolbox-3/Psychtoolbox-3/blob/master/Psychtoolbox/PsychHardware/EyelinkToolbox/EyelinkDemos/SR-ResearchDemo/EyelinkFixationWindow/EyelinkFixationWindow.m
    
    conditional = 1; % Set conditional for acquisition start to TRUE
    while conditional == 1 % start while loop for acquisition trials
        
        if contingencies(iContingency) == 2 % if trial is passive
            conditional = row+1 < length(columnX); % Passive trials end when they run out of coordinates
        else % if trial is active
            conditional = (GetSecs-AcquisitionStartTime < AcquisitionDur); % Active trials end when the time is up
        end
        
        if dummymode == 0 && contingencies(iContingency) == 1
            error=Eyelink('CheckRecording');
            if(error~=0)
                break;
            end
        end
        % Draw the matrix of dots to the screen
        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
        if contingencies(iContingency) == 2 % passive
            % Define the position of the cursor using the logfiles
            row = row+1;
            xMouse = columnX(row);
            yMouse = columnY(row);
        else % active
            if dummymode == 1
                [xMouse, yMouse, ~] = GetMouse(window);
            elseif dummymode == 0
                if Eyelink( 'NewFloatSampleAvailable') > 0
                    % get the sample in the form of an event structure
                    evt = Eyelink( 'NewestFloatSample');
                    evt.gx;
                    evt.gy;
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
        end
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
        
        % Record all movements into coordinates logfile
        fprintf(LOGFILEexplore,'\n%d', iSub);
        fprintf(LOGFILEexplore,'\t%d', iContingency);
        fprintf(LOGFILEexplore,'\t%d', iBlock);
        fprintf(LOGFILEexplore,'\t%d', condition);
        fprintf(LOGFILEexplore,'\t%d', GetSecs-AcquisitionStartTime);
        fprintf(LOGFILEexplore, '\t%d', xMouse);
        fprintf(LOGFILEexplore, '\t%d', yMouse);
        fprintf(LOGFILEexplore, '\t%d', soundPlayed);
        currentMouse = [xMouse yMouse];
        soundPlayed = 0;
        
        if contingencies(iContingency) == 2 % Animate
            vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
        else
            Screen('Flip', window); % Use mouse coordinates
        end
        
        if lastStop ~= previousStop
            previousStop = lastStop;
            PsychPortAudio('Stop', paHandle);
            switch (moveDirection)
                case 1
                    stop(soundTimer);
                    stop(reportTimer); % Interrupt timer if it is already running
                    PsychPortAudio('FillBuffer', paHandle, tone{1});
                    start(soundTimer); % Start new timer for current sound
                    reportTimer.TimerFcn = @(x,y)report_event(iSub, iContingency, moveDirection, iBlock, condition, TrialType, ExperimentStartTime, dummymode, port_exist, LOGFILEevents, training);
                    start(reportTimer); % This timer writes into logfile
                case 2
                    stop(soundTimer);
                    stop(reportTimer);
                    PsychPortAudio('FillBuffer', paHandle, tone{2});
                    start(soundTimer); % Start new timer for current sound
                    reportTimer.TimerFcn = @(x,y)report_event(iSub, iContingency, moveDirection, iBlock, condition, TrialType, ExperimentStartTime, dummymode, port_exist, LOGFILEevents, training);
                    start(reportTimer);
                case 3
                    stop(soundTimer);
                    stop(reportTimer);
                    PsychPortAudio('FillBuffer', paHandle, tone{3});
                    start(soundTimer); % Start new timer for current sound
                    reportTimer.TimerFcn = @(x,y)report_event(iSub, iContingency, moveDirection, iBlock, condition, TrialType, ExperimentStartTime, dummymode, port_exist, LOGFILEevents, training);
                    start(reportTimer);
                case 4
                    stop(soundTimer);
                    stop(reportTimer);
                    PsychPortAudio('FillBuffer', paHandle, tone{4});
                    start(soundTimer); % Start new timer for current sound
                    reportTimer.TimerFcn = @(x,y)report_event(iSub, iContingency, moveDirection, iBlock, condition, TrialType, ExperimentStartTime, dummymode, port_exist, LOGFILEevents, training);
                    start(reportTimer);
                case 5
                    stop(soundTimer);
                    stop(reportTimer);
                    PsychPortAudio('FillBuffer', paHandle, tone{5});
                    start(soundTimer); % Start new timer for current sound
                    reportTimer.TimerFcn = @(x,y)report_event(iSub, iContingency, moveDirection, iBlock, condition, TrialType, ExperimentStartTime, dummymode, port_exist, LOGFILEevents, training);
                    start(reportTimer);
                case 6
                    stop(soundTimer);
                    stop(reportTimer);
                    PsychPortAudio('FillBuffer', paHandle, tone{6});
                    start(soundTimer); % Start new timer for current sound
                    reportTimer.TimerFcn = @(x,y)report_event(iSub, iContingency, moveDirection, iBlock, condition, TrialType, ExperimentStartTime, dummymode, port_exist, LOGFILEevents, training);
                    start(reportTimer);
                case 7
                    stop(soundTimer);
                    stop(reportTimer);
                    PsychPortAudio('FillBuffer', paHandle, tone{7});
                    start(soundTimer); % Start new timer for current sound
                    reportTimer.TimerFcn = @(x,y)report_event(iSub, iContingency, moveDirection, iBlock, condition, TrialType, ExperimentStartTime, dummymode, port_exist, LOGFILEevents, training);
                    start(reportTimer);
                case 8
                    stop(soundTimer);
                    stop(reportTimer);
                    PsychPortAudio('FillBuffer', paHandle, tone{8});
                    start(soundTimer); % Start new timer for current sound
                    reportTimer.TimerFcn = @(x,y)report_event(iSub, iContingency, moveDirection, iBlock, condition, TrialType, ExperimentStartTime, dummymode, port_exist, LOGFILEevents, training);
                    start(reportTimer);
            end
        end % while movement direction is not -1
    end % While loop for acquisition trials
    stop(soundTimer);
    stop(reportTimer); % Stop timer in case it was still running so that no more sounds are played
    
    endExplore = GetSecs;
    
    % REPORT EVENT: CUE %
    % 1. Create trigger
    EndAcquisition = 251;
    % 2. Send porttalk trigger
    if port_exist == 1
        porttalk(hex2dec('CFB8'), EndAcquisition, 1000);
    end
    % 3. Send Eyelink message
    if dummymode == 0
        Eyelink('Message', 'Acquisition trial ended.');
        Eyelink('Message', 'TRIGGER %03d', EndAcquisition);
    end
    % 4. Write into logfile
    fprintf(LOGFILEevents,'\n%d', iSub);
    fprintf(LOGFILEevents,'\t%d', iContingency);
    fprintf(LOGFILEevents,'\t%d', iBlock); % iBlock
    fprintf(LOGFILEevents,'\tNaN'); % Trial number
    fprintf(LOGFILEevents,'\t%d', condition); % Condition: actively or passively learned?
    fprintf(LOGFILEevents,'\t%d', TrialType); % TrialType: 1 = acquisition, 2 = test
    fprintf(LOGFILEevents,'\t%d', 1); % EventType: 1. cue 2. acquisition-sound 3. test-sound 4. response
    fprintf(LOGFILEevents,'\t%d', endExplore-ExperimentStartTime); % event time
    fprintf(LOGFILEevents,'\tNaN'); % SoundID
    fprintf(LOGFILEevents,'\tNaN'); % AnimationID
    fprintf(LOGFILEevents,'\tNaN'); % MovDir
    fprintf(LOGFILEevents,'\tNaN'); % Congruency
    fprintf(LOGFILEevents,'\tNaN'); % Response
    % END REPORT
    
    % End exploring
    Screen('TextSize', window, 60);
    DrawFormattedText(window, 'Se acabó el tiempo!', 'center', 'center',white);
    Screen('Flip',window);
    Screen('Flip',window, (endExplore+0.5)); % 0.5s after "Se acabÃ³ el tiempo"
    previousStop = -1; % Second to last stop at a significant location
    lastStop = -1; % Last stop at a significant location
    moveDirection = -1; % Last significant movement between two stops
    
    %%
    
    % Test trials (always the same, but only 3 during training block)
    for iTest = 1:nTests % Only 3 for training, otherwise 6
        TrialType = 2; % test trial (for logfiles)
        testsound = tone{testtrials(2,iTest)};
        PsychPortAudio('FillBuffer', paHandle, testsound);
        Screen('TextSize', window, 60);
        DrawFormattedText(window, 'TEST', 'center', 'center',white);
        testTrialStart = GetSecs;
        Screen('Flip',window);
        
        if iTest == 1
            % REPORT EVENT: TEST TRIALS BEGIN %
            
            % 1. Create trigger
            
            TestTrialStartTrigger = 248;
            
            % 2. Send porttalk trigger
            if port_exist == 1
                porttalk(hex2dec('CFB8'), TestTrialStartTrigger, 1000);
            end
            
            % 3. Send Eyelink message
            if dummymode == 0
                Eyelink('Message', 'Test trial started.');
                Eyelink('Message', 'TRIGGER %03d', TestTrialStartTrigger);
            end
            
            % 4. Write into logfile
            fprintf(LOGFILEevents,'\n%d', iSub);
            fprintf(LOGFILEevents,'\t%d', iContingency);
            fprintf(LOGFILEevents,'\t%d', iBlock); % iBlock
            fprintf(LOGFILEevents,'\tNaN'); % Trial number
            fprintf(LOGFILEevents,'\t%d', condition); % Condition: actively or passively learned?
            fprintf(LOGFILEevents,'\t%d', TrialType); % TrialType: 1 = acquisition, 2 = test
            fprintf(LOGFILEevents,'\t%d', 1); % EventType: 1. cue 2. acquisition-sound 3. test-sound 4. response
            fprintf(LOGFILEevents,'\t%d', testTrialStart-ExperimentStartTime); % event time
            fprintf(LOGFILEevents,'\tNaN'); % SoundID
            fprintf(LOGFILEevents,'\tNaN'); % AnimationID
            fprintf(LOGFILEevents,'\tNaN'); % MovDir
            fprintf(LOGFILEevents,'\tNaN'); % Congruency
            fprintf(LOGFILEevents,'\tNaN'); % Response
            
            % END REPORT
        end
        
        Screen('Flip',window, (testTrialStart+0.5));
        
        if testtrials(1,iTest) == 1 % If the moveDirectionection of movement is 1
            animation = randi(6); % There are 6 different animations that have moveDirectionection 1
            switch animation
                case 1
                    % Animation 2-1, moveDirection: 1
                    animationID = 4;
                    xDot = pos2(1);
                    yDot = pos2(2);
                    while xDot > pos1(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        % xDot = xDot - speed;
                        xDot = xDot-speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 2
                    % Animation 3-2, moveDirection: 1
                    animationID = 9;
                    xDot = pos3(1);
                    yDot = pos3(2);
                    while xDot > pos2(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 3
                    % Animation 5-4, moveDirection: 1
                    animationID = 20;
                    xDot = pos5(1);
                    yDot = pos5(2);
                    while xDot > pos4(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 4
                    % Animation 6-5, moveDirection: 1
                    animationID = 27;
                    xDot = pos6(1);
                    yDot = pos6(2);
                    while xDot > pos5(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 5
                    % Animation 8-7, moveDirection: 1
                    animationID = 36;
                    xDot = pos8(1);
                    yDot = pos8(2);
                    while xDot > pos7(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 6
                    % Animation 9-8, moveDirection: 1
                    animationID = 40;
                    xDot = pos9(1);
                    yDot = pos9(2);
                    while xDot > pos8(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
            end
        elseif testtrials(1,iTest) == 2 % If the moveDirectionection of movement is 2
            animation = randi(6); % There are 6 different animations that have moveDirectionection 2
            switch animation
                case 1
                    % Animation 1-2, moveDirection: 2
                    animationID = 1;
                    xDot = pos1(1);
                    yDot = pos1(2);
                    while xDot < pos2(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 2
                    % Animation 2-3, moveDirection: 2
                    animationID = 5;
                    xDot = pos2(1);
                    yDot = pos2(2);
                    while xDot < pos3(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 3
                    % Animation 4-5, moveDirection: 2
                    animationID = 14;
                    xDot = pos4(1);
                    yDot = pos4(2);
                    while xDot < pos5(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 4
                    % Animation 5-6, moveDirection: 2
                    animationID = 21;
                    xDot = pos5(1);
                    yDot = pos5(2);
                    while xDot < pos6(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 5
                    % Animation 7-8, moveDirection: 2
                    animationID = 32;
                    xDot = pos7(1);
                    yDot = pos7(2);
                    while xDot < pos8(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 6
                    % Animation 8-9, moveDirection: 2
                    animationID = 37;
                    xDot = pos8(1);
                    yDot = pos8(2);
                    while xDot < pos9(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
            end
        elseif testtrials(1,iTest) == 3 % If the moveDirectionection of movement is 3
            animation = randi(6); % There are 6 different animations that have moveDirectionection 3
            switch animation
                case 1
                    % Animation 4-1, moveDirection: 3
                    animationID = 12;
                    xDot = pos4(1);
                    yDot = pos4(2);
                    while yDot > pos1(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 2
                    % Animation 5-2, moveDirection: 3
                    animationID = 18;
                    xDot = pos5(1);
                    yDot = pos5(2);
                    while yDot > pos2(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 3
                    % Animation 6-3, moveDirection: 3
                    animationID = 26;
                    xDot = pos6(1);
                    yDot = pos6(2);
                    while yDot > pos3(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 4
                    % Animation 7-4, moveDirection: 3
                    animationID = 30;
                    xDot = pos7(1);
                    yDot = pos7(2);
                    while yDot > pos4(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 5
                    % Animation 8-5, moveDirection: 3
                    animationID = 34;
                    xDot = pos8(1);
                    yDot = pos8(2);
                    while yDot > pos5(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 6
                    % Animation 9-6, moveDirection: 3
                    animationID = 39;
                    xDot = pos9(1);
                    yDot = pos9(2);
                    while yDot > pos6(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
            end % switch
            
        elseif testtrials(1,iTest) == 4 % If the moveDirectionection of movement is 4
            animation = randi(6); % There are 6 different animations that have moveDirectionection 4 (last one where this is the case)
            switch animation
                case 1
                    % Animation 1-4, moveDirection: 4
                    animationID = 2;
                    xDot = pos1(1);
                    yDot = pos1(2);
                    while yDot < pos4(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 2
                    % Animation 2-5, moveDirection: 4
                    animationID = 7;
                    xDot = pos2(1);
                    yDot = pos2(2);
                    while yDot < pos5(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 3
                    % Animation 3-6, moveDirection: 4
                    animationID = 11;
                    xDot = pos3(1);
                    yDot = pos3(2);
                    while yDot < pos6(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 4
                    % Animation 4-7, moveDirection: 4
                    animationID = 15;
                    xDot = pos4(1);
                    yDot = pos4(2);
                    while yDot < pos7(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 5
                    % Animation 5-8, moveDirection: 4
                    animationID = 23;
                    xDot = pos5(1);
                    yDot = pos5(2);
                    while yDot < pos8(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 6
                    % Animation 6-9, moveDirection: 4
                    animationID = 29;
                    xDot = pos6(1);
                    yDot = pos6(2);
                    while yDot < pos9(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
            end % switch
        elseif testtrials(1,iTest) == 5 % If the moveDirectionection of movement is 5
            animation = randi(4); % There are 4 different animations that have moveDirectionection 5
            switch animation
                case 1
                    % Animation 5-1, moveDirection: 5
                    animationID = 17;
                    xDot = pos5(1);
                    yDot = pos5(2);
                    while yDot > pos1(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed;
                        xDot = xDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 2
                    % Animation 6-2, moveDirection: 5
                    animationID = 25;
                    xDot = pos6(1);
                    yDot = pos6(2);
                    while yDot > pos2(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed;
                        xDot = xDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 3
                    % Animation 8-4, moveDirection: 5
                    animationID = 33;
                    xDot = pos8(1);
                    yDot = pos8(2);
                    while xDot > pos4(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed;
                        yDot = yDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 4
                    % Animation 9-5, moveDirection: 5
                    animationID = 38;
                    xDot = pos9(1);
                    yDot = pos9(2);
                    while xDot > pos5(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed;
                        yDot = yDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
            end % switch
        elseif testtrials(1,iTest) == 6 % If the moveDirectionection of movement is 6
            animation = randi(4); % There are 4 different animations that have moveDirectionection 6
            switch animation
                case 1
                    % Animation 2-4, moveDirection: 6
                    animationID = 6;
                    xDot = pos2(1);
                    yDot = pos2(2);
                    while xDot > pos4(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed;
                        yDot = yDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 2
                    % Animation 3-5, moveDirection: 6
                    animationID = 10;
                    xDot = pos3(1);
                    yDot = pos3(2);
                    while xDot > pos5(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed;
                        yDot = yDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 3
                    % Animation 5-7, moveDirection: 6
                    animationID = 22;
                    xDot = pos5(1);
                    yDot = pos5(2);
                    while yDot < pos7(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed;
                        xDot = xDot - speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 4
                    % Animation 6-8, moveDirection: 6
                    animationID = 28;
                    xDot = pos6(1);
                    yDot = pos6(2);
                    while xDot > pos8(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot - speed;
                        yDot = yDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
            end % switch
        elseif testtrials(1,iTest) == 7 % If the moveDirectionection of movement is 7
            animation = randi(4); % There are 4 different animations that have moveDirectionection 7
            switch animation
                case 1
                    % Animation 4-2, moveDirection: 7
                    animationID = 13;
                    xDot = pos4(1);
                    yDot = pos4(2);
                    while yDot > pos2(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed;
                        xDot = xDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 2
                    % Animation 5-3, moveDirection: 7
                    animationID = 19;
                    xDot = pos5(1);
                    yDot = pos5(2);
                    while yDot > pos3(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed;
                        xDot = xDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 3
                    % Animation 7-5, moveDirection: 7
                    animationID = 31;
                    xDot = pos7(1);
                    yDot = pos7(2);
                    while yDot > pos5(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed;
                        xDot = xDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 4
                    % Animation 8-6, moveDirection: 7
                    animationID = 35;
                    xDot = pos8(1);
                    yDot = pos8(2);
                    while yDot > pos6(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot - speed;
                        xDot = xDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
            end % switch
        elseif testtrials(1,iTest) == 8 % If the moveDirectionection of movement is 8
            animation = randi(4); % There are 4 different animations that have moveDirectionection 8
            switch animation
                case 1
                    % Animation 1-5, moveDirection: 8
                    animationID = 3;
                    xDot = pos1(1);
                    yDot = pos1(2);
                    while yDot < pos5(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed;
                        xDot = xDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 2
                    % Animation 2-6, moveDirection: 8
                    animationID = 8;
                    xDot = pos2(1);
                    yDot = pos2(2);
                    while xDot < pos6(1)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        xDot = xDot + speed;
                        yDot = yDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 3
                    % Animation 4-8, moveDirection: 8
                    animationID = 16;
                    xDot = pos4(1);
                    yDot = pos4(2);
                    while yDot < pos8(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed;
                        xDot = xDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
                case 4
                    % Animation 5-9, moveDirection: 8
                    animationID = 24;
                    xDot = pos5(1);
                    yDot = pos5(2);
                    while yDot < pos9(2)
                        % Draw matrix
                        Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
                        Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
                        % Make dot move at "speed"
                        yDot = yDot + speed;
                        xDot = xDot + speed;
                        % Draw dot
                        animationStart = GetSecs;
                        Screen('DrawDots', window, [xDot yDot], 20, white, [], 2);
                        vbl=Screen('Flip', window,vbl+ifi/2); % God knows what this does but we need it
                    end
            end % very long switch
        end % if-statement for movement moveDirectionections
        
        % Present test sound
        WaitSecs(1);
        testSoundTime = GetSecs;
        PsychPortAudio('Start', paHandle, 1);
        
        % REPORT EVENT: TEST SOUND %
        
        % 1. Create trigger
        
        % Prepare trigger code for test sounds
        if testtrials(3,iTest) == 0
            congruencyCode = 2;
        elseif testtrials(3,iTest) == 1
            congruencyCode = 1;
        end
        
        % Trigger consists of congruency (1 or 2), active/passive
        % (1 or 2) and block (1-6)
        testSoundTrigger = str2double(sprintf('%d%d%d', congruencyCode, contingencies(iContingency), iBlock));
        
        % 2. Send porttalk trigger
        if port_exist == 1
            porttalk(hex2dec('CFB8'), testSoundTrigger, 1000);
        end
        
        % 3. Send Eyelink message
        if dummymode == 0
            Eyelink('Message', 'Test sound played.');
            Eyelink('Message', 'TRIGGER %03d', testSoundTrigger);
        end
        
        % 4. Write into logfile
        fprintf(LOGFILEevents,'\n%d', iSub);
        fprintf(LOGFILEevents,'\t%d', iContingency);
        fprintf(LOGFILEevents,'\t%d', iBlock);
        fprintf(LOGFILEevents,'\t%d', iTest); % Trial number
        fprintf(LOGFILEevents, '\t%d', condition); % Condition: actively or passively learned?
        fprintf(LOGFILEevents,'\t%d', TrialType);
        fprintf(LOGFILEevents,'\t%d', 3); % EventType: 1. cue 2. acquisition-sound 3. test-sound 4. response
        fprintf(LOGFILEevents, '\t%d', testSoundTime-ExperimentStartTime); % event time
        fprintf(LOGFILEevents, '\t%d', testtrials(2,iTest)); % SoundID
        fprintf(LOGFILEevents, '\t%d', animationID);
        fprintf(LOGFILEevents, '\t%d', testtrials(1,iTest)); % MovDir
        fprintf(LOGFILEevents, '\t%d', testtrials(3,iTest)); % Congruency
        fprintf(LOGFILEevents, '\tNaN'); % Response (does not apply here)
        
        % END REPORT
        
        % --- Question & response ---
        Screen('TextSize', window, 60);
        if EyeSound_data(iSub).Counterbalancing == 1 % Left is no
            DrawFormattedText(window, 'NO     ?     YES', 'center', 'center', white);
        elseif EyeSound_data(iSub).Counterbalancing == 2 % Left is yes
            DrawFormattedText(window, 'YES    ?      NO', 'center', 'center', white);
        end
        
        questionTime = GetSecs;
        Screen('Flip',window,(testSoundTime+1)); % I made this 2 seconds because 1 second felt super fast
        
        % REPORT EVENT: CUE (Question) %
        
        % 1. Create trigger
        
        QuestionTrigger = 247;
        
        % 2. Send porttalk trigger
        if port_exist == 1
            porttalk(hex2dec('CFB8'), QuestionTrigger, 1000);
        end
        
        % 3. Send Eyelink message
        if dummymode == 0
            Eyelink('Message', 'Question displayed.');
            Eyelink('Message', 'TRIGGER %03d', QuestionTrigger);
        end
        
        % 4. Write into logfile
        fprintf(LOGFILEevents,'\n%d', iSub);
        fprintf(LOGFILEevents,'\t%d', iContingency);
        fprintf(LOGFILEevents,'\t%d', iBlock);
        fprintf(LOGFILEevents,'\t%d', iTest); % Trial number
        fprintf(LOGFILEevents, '\t%d', condition); % Condition: actively or passively learned?
        fprintf(LOGFILEevents,'\t%d', TrialType);
        fprintf(LOGFILEevents,'\t%d', 1); % EventType: 1. cue 2. acquisition-sound 3. test-sound 4. response
        fprintf(LOGFILEevents, '\t%d', questionTime-ExperimentStartTime); % event time
        fprintf(LOGFILEevents, '\tNaN'); % SoundID does not apply
        fprintf(LOGFILEevents, '\tNaN'); % AnimationID does not apply
        fprintf(LOGFILEevents, '\tNaN'); % MovDir does not apply
        fprintf(LOGFILEevents, '\tNaN'); % Congruency does not apply
        fprintf(LOGFILEevents, '\tNaN'); % Response (does not apply here)
        
        % END REPORT
        
        response = -1; % We need this variable to hold something in case people don't press a button
        % Clear any accidental presses before the instruction appeared
        keyCode = [];
        while (GetSecs-questionTime) <= MaxResp % Maximum response time
            if nano_exist == 0
                [~, ~, keyCode] = KbCheck;
                if keyCode(YesKey)
                    % responseTrigger = 88;
                    response = 1;
                    DrawFormattedText(window, '+', 'center', 'center', white);
                    responseTime = GetSecs;
                    Screen('Flip', window);
                elseif keyCode(NoKey)
                    % responseTrigger = 89;
                    response = 0;
                    DrawFormattedText(window, '+', 'center', 'center', white);
                    responseTime = GetSecs;
                    Screen('Flip', window);
                end
            elseif nano_exist == 1
                % Clear any accidental presses before the instruction appeared
                [key,time,messages,Ts] = getmidiresp(); %
                key = [];
                % Check for key presses
                while isempty(key) && (GetSecs-questionTime) <= MaxResp
                    WaitSecs(0.005);
                    [key,time,messages,Ts] = getmidiresp();
                end
                if ~isempty(key) % if a response key is pressed
                    if key == nanoYES
                        % responseTrigger = 88;
                        response = 1;
                        DrawFormattedText(window, '+', 'center', 'center', white);
                        responseTime = GetSecs;
                        Screen('Flip', window);
                    elseif key == nanoNO
                        % responseTrigger == 89;
                        response = 0;
                        DrawFormattedText(window, '+', 'center', 'center', white);
                        responseTime = GetSecs;
                        Screen('Flip', window);
                    end
                end
            end
        end
        
        if response == -1 % after time is up
            response = NaN; % miss
            responseTime = GetSecs;
        end
        
        
        % REPORT EVENT: RESPONSE %
        
        % 1. Create trigger
        
        ReponseTrigger = 246;
        
        if ~isnan(response) % Send these triggers only if a response was made
            % 2. Send porttalk trigger
            if port_exist == 1
                porttalk(hex2dec('CFB8'), ReponseTrigger, 1000);
            end
            
            % 3. Send Eyelink message
            if dummymode == 0
                Eyelink('Message', 'Participant made a response.');
                Eyelink('Message', 'TRIGGER %03d', ReponseTrigger);
            end
        end
        
        % 4. Write into logfile
        fprintf(LOGFILEevents,'\n%d', iSub);
        fprintf(LOGFILEevents,'\t%d', iContingency);
        fprintf(LOGFILEevents,'\t%d', iBlock);
        fprintf(LOGFILEevents,'\t%d', iTest); % Trial number
        fprintf(LOGFILEevents,'\t%d', condition); % Condition: actively or passively learned?
        fprintf(LOGFILEevents,'\t%d', TrialType);
        fprintf(LOGFILEevents,'\t%d', 4); % EventType: 1. cue 2. acquisition-sound 3. test-sound 4. response
        fprintf(LOGFILEevents,'\t%d', responseTime-ExperimentStartTime); % event time
        fprintf(LOGFILEevents,'\t%d', testtrials(2,iTest)); % SoundID
        fprintf(LOGFILEevents,'\t%d', animationID);
        fprintf(LOGFILEevents,'\t%d', testtrials(1,iTest)); % MovDir
        fprintf(LOGFILEevents,'\t%d', testtrials(3,iTest)); % Congruency
        fprintf(LOGFILEevents,'\t%d', response); % Response
        
        % END REPORT
        
    end % for-loop for test trials
    
    if iBlock < nBlocks
        % Wait for button press from experimenter before being able to
        % continue
        DrawFormattedText(window, 'El experimentador iniciará el siguiente bloque.', 'center', 'center', white);
        Screen('Flip',window);
        KbStrokeWait; % Wait for experimenter BP
    end
end
if dummymode == 0
    Eyelink('StopRecording'); % Eyelink takes recording breaks between levels
end

if iContingency < length(contingencies)
    % Wait for button press from experimenter before being able to
    % continue
    DrawFormattedText(window, 'El experimentador iniciará el siguiente nivel.', 'center', 'center', white);
    Screen('Flip',window);
    keyIsDown = 0; FlushEvents('keyDown');
    while keyIsDown ==0
        [keyIsDown, secs, keyCode] = KbCheck;
    end
    keyIsDown = 0;
end
% end % contingencies

%%
% -------------------------------------------------------------------------
%                           CLOSE AND CLEAN UP
% -------------------------------------------------------------------------

sca; % Close window
PsychPortAudio('Close'); % Close the audio device
fclose(LOGFILEevents); % Close logfiles
fclose(LOGFILEexplore); % Close logfiles
if port_exist == 1
    config_io('close'); % Close porttalk
end

if nano_exist == 1
    midi_interface('close'); % Close nanopad
end

if dummymode == 0 % Close EDF file, download it, shut down Eyelink
    
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
end % function