function acquisition_trial(iSub, iContingency)

    % Linux:
    cd '/home/stefanie/GitHub/EyeSound/';
    Sounds_path = '/home/stefanie/GitHub/EyeSound/sounds/';
    Results_path = '/home/stefanie/GitHub/EyeSound/results/';
    home_path = '/home/stefanie/GitHub/EyeSound/';
    Screen('Preference', 'SkipSyncTests', 1);

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
AcquisitionDur = 10; % 20sec for acquisition trials, less for debugging
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
window_size = [0 0 400 400]; % small window for debugging; comment out if fullscreen is wanted

% Open an on screen window and color it black
if exist('window_size')
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black, window_size); % Open for debugging
else
    HideCursor;
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
soundWasPlayed = 0; % Boolean

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

    paHandle = PsychPortAudio('Open', device, [], 0, FS, nrchannels); % On my computer at home

%%
% -------------------------------------------------------------------------
%                               START EXPERIMENT
% -------------------------------------------------------------------------

ExperimentStartTime = GetSecs;

Screen('TextSize', window, 60); % set text size
Screen('TextFont', window, 'Arial');
DrawFormattedText(window, 'El experimentador iniciará el experimento.', 'center', 'center',white); % Wait for experimenter input
Screen('Flip',window);
% KbStrokeWait; % Experimenter button press

keyIsDown = 0; FlushEvents('keyDown');
while keyIsDown ==0
    [keyIsDown, secs, keyCode] = KbCheck;
end
keyIsDown = 0;

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


% 4. Write into logfile
fprintf(LOGFILEevents,'\n%d', iSub);
fprintf(LOGFILEevents,'\t%d', iContingency);
fprintf(LOGFILEevents,'\tNA'); % iBlock
fprintf(LOGFILEevents,'\tNA'); % Trial number
fprintf(LOGFILEevents,'\t%d', condition); % Condition: actively or passively learned?
fprintf(LOGFILEevents,'\tNA'); % TrialType
fprintf(LOGFILEevents,'\t%d', 1); % EventType: 1. cue 2. acquisition-sound 3. test-sound 4. response
fprintf(LOGFILEevents,'\t%d', ContingencyStartTime-ExperimentStartTime); % event time
fprintf(LOGFILEevents,'\tNA'); % SoundID
fprintf(LOGFILEevents,'\tNA'); % AnimationID
fprintf(LOGFILEevents,'\tNA'); % MovDir
fprintf(LOGFILEevents,'\tNA'); % Congruency
fprintf(LOGFILEevents,'\tNA'); % Response

% END REPORT

% Each level has 6 blocks
for iBlock = 1:nBlocks
    ttCounter = ttCounter+1; % We count here the blocks without restarting at new level
    % Test trial codes change per block
    testtrials = EyeSound_data(iSub).Blocks(ttCounter).TestTrials;
    
    % Send trigger for new block, with info on trial type (acquisition,
    % 0), level type (1 or 2) and block number
    newBlockTrigger = str2double(['0', sprintf('1%d', iBlock)]);
    
    % 2. Send porttalk trigger
   
    
%% ACQUISITRION TRIAL (can be passive or active)

TrialType = 1; % acquisition trial


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


% 4. Write into logfile
fprintf(LOGFILEevents,'\n%d', iSub);
fprintf(LOGFILEevents,'\t%d', iContingency);
fprintf(LOGFILEevents,'\t%d', iBlock); % iBlock
fprintf(LOGFILEevents,'\tNA'); % Trial number
fprintf(LOGFILEevents,'\t%d', condition); % Condition: actively or passively learned?
fprintf(LOGFILEevents,'\t%d', TrialType); % TrialType: 1 = acquisition, 2 = test
fprintf(LOGFILEevents,'\t%d', 1); % EventType: 1. cue 2. acquisition-sound 3. test-sound 4. response
fprintf(LOGFILEevents,'\t%d', AcquisitionStartTime-ExperimentStartTime); % event time
fprintf(LOGFILEevents,'\tNA'); % SoundID
fprintf(LOGFILEevents,'\tNA'); % AnimationID
fprintf(LOGFILEevents,'\tNA'); % MovDir
fprintf(LOGFILEevents,'\tNA'); % Congruency
fprintf(LOGFILEevents,'\tNA'); % Response

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



% Prepare the timer that plays sound with delay of 1 sec
% t = timer("TimerFcn", "soundWasPlayed = true; eval(PsychPortAudio('Start', paHandle, 1))", "StartDelay",1);
t = timer;
t.StartDelay = 1;
t.TimerFcn = @(soundTimer, playSound)eval(PsychPortAudio('Start', paHandle, 1));
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
    

    % Draw the matrix of dots to the screen
    Screen('DrawDots', window, dotPositionMatrix, dotBig, dotRed, dotCenter, 0);
    Screen('DrawDots', window, dotPositionMatrix, dotSmall, dotBlack, dotCenter, 0);
    if contingencies(iContingency) == 2 % passive
        % Define the position of the cursor using the logfiles
        row = row+1;
        xMouse = columnX(row);
        yMouse = columnY(row);
    else % active
            [xMouse, yMouse, ~] = GetMouse(window);
    end     
    % Draw the cursor as a white dot
    Screen('DrawDots', window, [xMouse yMouse], 20, white, [], 2);
    HideCursor;
    
    % Make the squares size relative to the gap size
    squareSize = gap/5; % This is the area that will be responsive when you hover over it
    
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
        % stop(t)
        %start(t)
    elseif square1 == true && lastStop == 4
        moveDirection = 3;
        lastStop = 1;
        % stop(t)
        %start(t)
    elseif square1 == true && lastStop == 5
        moveDirection = 5;
        lastStop = 1;
        % stop(t)
        %start(t)
    elseif square1 == true
        lastStop = 1;
        % stop(t)
        %start(t)
    end
    
    %---SQUARE_2---%
    if square2 == true && lastStop == 1
        moveDirection = 2;
        lastStop = 2;
        % stop(t)
        %start(t)
    elseif square2 == true && lastStop == 3
        moveDirection = 1;
        lastStop = 2;
        % stop(t)
        %start(t)
    elseif square2 == true && lastStop == 4
        moveDirection = 7;
        lastStop = 2;
        % stop(t)
        %start(t)
    elseif square2 == true && lastStop == 5
        moveDirection = 3;
        lastStop = 2;
        % stop(t)
        %start(t)
    elseif square2 == true && lastStop == 6
        moveDirection = 5;
        lastStop = 2;
        % stop(t)
        %start(t)
    elseif square2 == true
        lastStop = 2;
        % stop(t)
        %start(t)
    end
    
    %---SQUARE_3---%
    if square3 == true && lastStop == 2
        moveDirection = 2;
        lastStop = 3;
        % stop(t)
        %start(t)
    elseif square3 == true && lastStop == 5
        moveDirection = 7;
        lastStop = 3;
        % stop(t)
        %start(t)
    elseif square3 == true && lastStop == 6
        moveDirection = 3;
        lastStop = 3;
        % stop(t)
        %start(t)
    elseif square3 == true
        lastStop = 3;
        % stop(t)
        %start(t)
    end
    
    %---SQUARE_4---%
    if square4 == true && lastStop == 1
        moveDirection = 4;
        lastStop = 4;
        % stop(t)
        %start(t)
    elseif square4 == true && lastStop == 2
        moveDirection = 6;
        lastStop = 4;
        % stop(t)
        %start(t)
    elseif square4 == true && lastStop == 5
        moveDirection = 1;
        lastStop = 4;
        % stop(t)
        %start(t)
    elseif square4 == true && lastStop == 7
        moveDirection = 3;
        lastStop = 4;
        % stop(t)
        %start(t)
    elseif square4 == true && lastStop == 8
        moveDirection = 5;
        lastStop = 4;
        % stop(t)
        %start(t)
    elseif square4 == true
        lastStop = 4;
        % stop(t)
        %start(t)
    end
    
    %---SQUARE_5---%
    if square5 == true && lastStop == 1
        moveDirection = 8;
        lastStop = 5;
        % stop(t)
        %start(t)
    elseif square5 == true && lastStop == 2
        moveDirection = 4;
        lastStop = 5;
        % stop(t)
        %start(t)
    elseif square5 == true && lastStop == 3
        moveDirection = 6;
        lastStop = 5;
        % stop(t)
        %start(t)
    elseif square5 == true && lastStop == 4
        moveDirection = 2;
        lastStop = 5;
        % stop(t)
        %start(t)
    elseif square5 == true && lastStop == 6;
        moveDirection = 1;
        lastStop = 5;
        % stop(t)
        %start(t)
    elseif square5 == true && lastStop == 7
        moveDirection = 7;
        lastStop = 5;
        % stop(t)
        %start(t)
    elseif square5 == true && lastStop == 8
        moveDirection = 3;
        lastStop = 5;
        % stop(t)
        %start(t)
    elseif square5 == true && lastStop == 9
        moveDirection = 5;
        lastStop = 5;
        % stop(t)
        %start(t)
    elseif square5 == true
        lastStop = 5;
        % stop(t)
        %start(t)
    end
    
    %---SQUARE_6---%
    if square6 == true && lastStop == 2
        moveDirection = 8;
        lastStop = 6;
        % stop(t)
        %start(t)
    elseif square6 == true && lastStop == 3
        moveDirection = 4;
        lastStop = 6;
        % stop(t)
        %start(t)
    elseif square6 == true && lastStop == 5
        moveDirection = 2;
        lastStop = 6;
        % stop(t)
        %start(t)
    elseif square6 == true && lastStop == 8
        moveDirection = 7;
        lastStop = 6;
        % stop(t)
        %start(t)
    elseif square6 == true && lastStop == 9
        moveDirection = 3;
        lastStop = 6;
        % stop(t)
        %start(t)
    elseif square6 == true
        lastStop = 6;
        % stop(t)
        %start(t)
    end
    
    %---SQUARE_7---%
    if square7 == true && lastStop == 4
        moveDirection = 4;
        lastStop = 7;
        % stop(t)
        %start(t)
    elseif square7 == true && lastStop == 5
        moveDirection = 6;
        lastStop = 7;
        % stop(t)
        %start(t)
    elseif square7 == true && lastStop == 8
        moveDirection = 1;
        lastStop = 7;
        % stop(t)
        %start(t)
    elseif square7 == true
        lastStop = 7;
        % stop(t)
        %start(t)
    end
    
    %---SQUARE_8---%
    if square8 == true && lastStop == 4
        moveDirection = 8;
        lastStop = 8;
        % stop(t)
        %start(t)
    elseif square8 == true && lastStop == 5
        moveDirection = 4;
        lastStop = 8;
        % stop(t)
        %start(t)
    elseif square8 == true && lastStop == 6
        moveDirection = 6;
        lastStop = 8;
        % stop(t)
        %start(t)
    elseif square8 == true && lastStop == 7
        moveDirection = 2;
        lastStop = 8;
        % stop(t)
        %start(t)
    elseif square8 == true && lastStop == 9
        moveDirection = 1;
        lastStop = 8;
        % stop(t)
        %start(t)
    elseif square8 == true
        lastStop = 8;
        % stop(t)
        %start(t)
    end
    
    %---SQUARE_9---%
    if square9 == true && lastStop == 5
        moveDirection = 8;
        lastStop = 9;
        % stop(t)
        %start(t)
    elseif square9 == true && lastStop == 6
        moveDirection = 4;
        lastStop = 9;
        % stop(t)
        %start(t)
    elseif square9 == true && lastStop == 8
        moveDirection = 2;
        lastStop = 9;
        % stop(t)
        %start(t)
    elseif square9 == true
        lastStop = 9;
        % stop(t)
        %start(t)
    end
    
    stationary = isequal(currentMouse, [xMouse yMouse]);
    
    if stationary == 0
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
    end
    
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
                stop(t) % Interrupt timer if it is already running
                PsychPortAudio('FillBuffer', paHandle, tone{1});
                start(t) % Start new timer for current sound
            case 2
                stop(t)
                PsychPortAudio('FillBuffer', paHandle, tone{2});
                start(t)
            case 3
                stop(t)
                PsychPortAudio('FillBuffer', paHandle, tone{3});
                start(t)
            case 4
                stop(t)
                PsychPortAudio('FillBuffer', paHandle, tone{4});
                start(t)
            case 5
                stop(t)
                PsychPortAudio('FillBuffer', paHandle, tone{5});
                start(t)
            case 6
                stop(t)
                PsychPortAudio('FillBuffer', paHandle, tone{6});
                start(t)
            case 7
                stop(t)
                PsychPortAudio('FillBuffer', paHandle, tone{7});
                start(t)
            case 8
                stop(t)
                PsychPortAudio('FillBuffer', paHandle, tone{8});
                start(t)
        end
        disp('We left the switch');
        if soundWasPlayed == 1 % Do the following every time a sound was actually played
            disp('Sound was played');
            soundWasPlayed = 0; % Reset this condition
            soundID = moveDirection; % Information for logfiles
            acquisitionSound = GetSecs; % Information for logfiles
            soundPlayed = moveDirection; % We need this for the coordinates logfile (I think)
            
           
            % 4. Write into logfile
            fprintf(LOGFILEevents,'\n%d', iSub);
            fprintf(LOGFILEevents,'\t%d', iContingency);
            fprintf(LOGFILEevents,'\t%d', iBlock); % iBlock
            fprintf(LOGFILEevents,'\tNA'); % Trial number
            fprintf(LOGFILEevents,'\t%d', condition); % Condition: actively or passively learned?
            fprintf(LOGFILEevents,'\t%d', TrialType); % TrialType: 1 = acquisition, 2 = test
            fprintf(LOGFILEevents,'\t%d', 2); % EventType: 1. cue 2. acquisition-sound 3. test-sound 4. response
            fprintf(LOGFILEevents,'\t%d', acquisitionSound-ExperimentStartTime); % event time
            fprintf(LOGFILEevents,'\t%d', soundID); % SoundID
            fprintf(LOGFILEevents,'\tNA'); % AnimationID
            fprintf(LOGFILEevents,'\tNA'); % MovDir
            fprintf(LOGFILEevents,'\tNA'); % Congruency
            fprintf(LOGFILEevents,'\tNA'); % Response
            % END REPORT
        end
    end % while movement direction is not -1
end % While loop for acquisition trials
stop(t); % Stop timer in case it was still running so that no more sounds are played
end % Blocks

endExplore = GetSecs;

% REPORT EVENT: CUE %
% 1. Create trigger
EndAcquisition = 251;
% 2. Send porttalk trigger

% 4. Write into logfile
fprintf(LOGFILEevents,'\n%d', iSub);
fprintf(LOGFILEevents,'\t%d', iContingency);
fprintf(LOGFILEevents,'\t%d', iBlock); % iBlock
fprintf(LOGFILEevents,'\tNA'); % Trial number
fprintf(LOGFILEevents,'\t%d', condition); % Condition: actively or passively learned?
fprintf(LOGFILEevents,'\t%d', TrialType); % TrialType: 1 = acquisition, 2 = test
fprintf(LOGFILEevents,'\t%d', 1); % EventType: 1. cue 2. acquisition-sound 3. test-sound 4. response
fprintf(LOGFILEevents,'\t%d', endExplore-ExperimentStartTime); % event time
fprintf(LOGFILEevents,'\tNA'); % SoundID
fprintf(LOGFILEevents,'\tNA'); % AnimationID
fprintf(LOGFILEevents,'\tNA'); % MovDir
fprintf(LOGFILEevents,'\tNA'); % Congruency
fprintf(LOGFILEevents,'\tNA'); % Response
% END REPORT

% End exploring
Screen('TextSize', window, 60);
DrawFormattedText(window, '¡Se acabó el tiempo!', 'center', 'center',white);
Screen('Flip',window);
Screen('Flip',window, (endExplore+0.5)); % 0.5s after "Se acabó el tiempo"
previousStop = -1; % Second to last stop at a significant location
lastStop = -1; % Last stop at a significant location
moveDirection = -1; % Last significant movement between two stops

end %function
