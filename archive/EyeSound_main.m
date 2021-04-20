function EyeSound_main(iSub,StartCond,StartBlock)

% if experiment is interrupted, can restart at whichever Condition/Block by
% adding the input arguments when calling the script.
if ~exist(StartCond)
    StartCond = 1;
end
if ~exist(StartBlock)
    StartBlock = 1;
end

% Add screen settings to open screen

%----------------------------------------------------------------------
%               Experiment instructions
%----------------------------------------------------------------------

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
DrawFormattedText(window, 'Ready?', 'center', 'center', textcolor);
Screen('Flip', window);
KbStrokeWait;

% Close screen


% Call blocks one by one according to counterbalancing
for iCond = StartCond:2
    if EyeSound(iSub).Counterbalancing == 1
        FirstCond = 'Active';
        SecondCond = 'Passive';
    elseif EyeSound(iSub).Counterbalancing == 1
        FirstCond = 'Passive';
        SecondCond = 'Active';
    end
    for iBlock = StartBlock:nBlocks
        display(['Press any key to start Condition ' FirstCond ' Block ' num2str(iBlock)]);
        pause
        eval(['EyeSound_' FirstCond '(' num2str(iSub) ',' num2str(iBlock)]);
        display(['Press any key to start Condition ' SecondCond ' Block ' num2str(iBlock)]);
        pause
        eval(['EyeSound_' SecondCond '(' num2str(iSub) ',' num2str(iBlock)]);
    end
end

end