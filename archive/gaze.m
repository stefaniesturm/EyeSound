function EyeSoud_gaze

% This is based on https://github.com/Psychtoolbox-3/Psychtoolbox-3/blob/master/Psychtoolbox/PsychHardware/EyelinkToolbox/EyelinkDemos/EyelinkShortDemos/EyelinkExample.m

% ----------------------------------------------
%       Things shared with other scripts
% ----------------------------------------------

PsychDefaultSetup(2); % Or should this be 1?
screenNumber=max(Screen('Screens'));
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
laststop = 0
dir = -1;
olddir = -1;
prevstop = -1;
currentMouse = [-1 -1];
tone = 0;
% Use common key mapping for all operating systems and define the escape
% key as abort key:
KbName('UnifyKeyNames');
RightArrow = KbName('RightArrow'); % to get the name you have to write, execute KbName without arguments and press the key you want to get the code for
LeftArrow = KbName('LeftArrow');
esc = KbName('ESCAPE');
keyIsDown = 0; % This may be redundant, check that if everything else is working
nrchannels = 1; % stereo
FS = 96000;
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
InitializePsychSound; % Initialize the sound device
paHandle = PsychPortAudio('Open', device, [], 0, FS, nrchannels); % Open the Audio port and get a handle to refer to it in subsequent calls

% ----------------------------------------------
%                 EyeLink things
% ----------------------------------------------

% Initialise EyeLink
el=EyelinkInitDefaults(window);
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

% Show gaze-dependent display
    while 1 % loop till error or escape key is pressed
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
                    % If data is valid, draw a circle on the screen at current gaze position using PsychToolbox's Screen function
                    gazeRect=[ xEye-9 yEye-9 xEye+10 yEye+10];
                    colour=round(rand(3,1)*255); % coloured dot
                    Screen('FillOval', window, colour, gazeRect);
                    Screen('Flip',  el.window, [], 1); % don't erase
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
    end % main loop
    % wait a while to record a few more samples
    WaitSecs(0.1);
    
    % STEP 7
    % finish up: stop recording eye-movements,
    % close graphics window, close data file and shut down tracker
    Eyelink('StopRecording');
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
    catch rdf
        fprintf('Problem receiving data file ''%s''\n', edfFile );
        rdf;
    end
    
    cleanup;
    
% Cleanup routine:
% Shutdown Eyelink:
Eyelink('Shutdown');

% Close window:
sca;

% Restore keyboard output to Matlab:
ListenChar(0);

