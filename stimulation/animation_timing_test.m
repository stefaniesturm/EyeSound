% How long does the animation take?

AssertOpenGL
Screen('Preference', 'SkipSyncTests', 0);
PsychDefaultSetup(2);
screenNumber=max(Screen('Screens'));
% Appearances
white = [1 1 1];
black = [0 0 0];
red = [1 0 0];

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
% Initialise variables necessary for playing sounds based on movements
% (it's very complicated)
laststop = 0
dir = -1;
olddir = -1;
prevstop = -1;
currentMouse = [-1 -1];
tone = 0;

% This is needed for the animations
speed = 7.5; % This is how fast animation moves!!!
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

xDot = pos2(1);
yDot = pos2(2);
time1 = GetSecs;
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
time2 = GetSecs;
KbStrokeWait;
sca;
time2-time1