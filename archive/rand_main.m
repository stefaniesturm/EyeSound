function rand_main(subject,iPart,iBlock)
%
% RAND experiment
% Main script
% Runs all blocks one by one
% Can be restarted from any block
%
% INPUT VARIABLES:
% subject = subject number e.g. 1
% iPart = Part number from which you want to restart after interruption (default 1)
% iBlock = Block number from which you want to restart after interruption (default 1)
%
% OUTPUT:
% Saves a tab separated logfile in \res\subjectnr.txt that contains one line per trial and in columns: 
% 'TRIAL','SUBJECT','PART','COND','BLOCK','tPress','SOUND','SOA','Trigger' 
% New info is appeded to the same logfile every time the script is run with
% the same subject number
%
% CONDITIONS:
% T - Training without sounds
% MAR - Motor auditory random
% MAS - Motor auditory single
% M - Motor only
%
% PARTS / BLOCKS:
% PART 1: (7 blocks)
% 3 MAR and 3 MAS blocks in random order
% 1 Motor-only block
%
% PART 2: (5 blocks)
% 2 MAR and 2 MAS blocks in random order
% 1 Motor-only block
%
% PART 3: (5 blocks)
% 2 MAR and 2 MAS blocks in random order
% 1 Motor-only block
%
% NEEDS:
% Scripts from all blocks: rand_mar.m, rand_mas.m, rand_m.m, rand_t.m
% Experiment config scripts: rand_stimuli.m, rand_config.m
% Additional scripts in \lib: sleep, pottalk (for sending triggers through
% parallel port), start_cogent (modified version), jst (for reading button
% presses on the gamepad)
%
% RAND, 2011, San Miguel, I., Schröger, E.
% (c) Iria San Miguel, University of Leipzig,
% iria.sanmiguel@uni-leipzig.de


global BlockOrder;

%%%%%%%%%%%%% PATHS %%%%%%%%%%%%%%%%%%%%%%%%%

addpath('D:\user\iria\RAND\scripts\lib'); % Additional scripts library path
addpath('C:\toolbox\Cogent2000v1.29\toolbox'); % COGENT path


%%%%%%%%%%%%% SETUP %%%%%%%%%%%%%%%%%%%%%%%%%

% Parts and conditions
Conditions = {'MAR', 'MAS', 'M'};
nParts = 3;

% Default start point
if nargin < 3;
    iBlock = 1;
end
if nargin < 2;
    iBlock = 1;
    iPart = 1;
end

% Set Matlab's random number generator to a replicable state for each
% subject
rand('state',subject);

% Initialize LOGFILE
logfilename = ['..\res\' sprintf('%02d',subject) '.txt'];
if exist(logfilename,'file')~=0;
    append = input('WARNING: Logfile already exists, data will be appended. Continue? (1=yes 0=no)');
    if append == 0;
        return;
    end;
end;

LOGFILE = fopen(logfilename, 'a'); % creates if nonexistent, appends
if exist('append','var') == 0 % write header only the first time
    fprintf(LOGFILE,'\n%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s',...
        'TRIAL','SUBJECT','PART','COND','BLOCK','tPress','SOUND','SOA','Trigger');
end


%%%%%%%%%%% START %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Wait for experimenter key press
disp 'press any key to start'
pause

%%%%%%%%%%%%% RUN PRACTICE BLOCK %%%%%%%%%%%%%%%%%%%%%%%%

% Run block
rand_T;
% Repeat as many times as necessary
repeat = input(['Repeat training? yes = 1, no = 0']);
while repeat == 1
    rand_T;
    repeat = input(['Repeat training again? yes = 1, no = 0']);
end

%%%%%%%%%%%%% PARTS LOOP %%%%%%%%%%%%%%%%%%%%%%%%%´

while iPart <= nParts
    disp(['Next Part ' num2str(iPart)]);

    % RANDOMIZE THE CONDITION ORDER
    % Specify number of condition blocks for this part
    if iPart == 1  % then there are 3 blocks of each condition
        nBlocks = 3; % of each MAR and MAS
    elseif iPart == 3 || iPart == 2
        nBlocks = 2; % of each MAR and MAS
    end
    % Randomize the order
    BlockOrder = shuffle([repmat(1,[1,nBlocks]) repmat(2,[1, nBlocks])]); % 1 = MAR, 2 = MAS

    %%%%%%%% BLOCKS LOOP %%%%%%%%%%%%
    while iBlock <= nBlocks*2

        % Display info to experimenter
        disp(['Next block ' num2str(iBlock) ', Condition: ' Conditions{BlockOrder(iBlock)}]);

        % Run block
        next = ['rand_' Conditions{BlockOrder(iBlock)} '(' num2str(subject) ',' num2str(iPart) ',' num2str(iBlock) ')'];
        eval(next);

        % Repeat practice if necessary
        repeat = input(['Do training? yes = 1, no = 0']);
        while repeat == 1
            rand_T;
            repeat = input(['Do training again? yes = 1, no = 0']);
        end

        % Repeat block if necessary
        repeat = input(['Repeat block ' num2str(iBlock) ', Condition: ' Conditions{BlockOrder(iBlock)} '? yes = 1, no = 0']);
        if repeat == 1
            next = ['rand_' Conditions{BlockOrder(iBlock)} '(' num2str(subject) ',' num2str(iPart) ',' num2str(iBlock) ')'];
            eval(next);
        end

        % Update block counter
        iblock = iblock + 1;
    end

    % RUN MOTOR CONDITION after all MAR and MAS blocks

    % Display info to experimenter
    disp(['Next block ' num2str(iBlock) ', Condition: M']);

    % Run block
    next = ['rand_m(' num2str(subject) ',' num2str(iPart) ',' num2str(iBlock) ')'];
    eval(next);

    % Repeat practice if necessary
    repeat = input(['Do training? yes = 1, no = 0']);
    while repeat == 1
        rand_T;
        repeat = input(['Do training again? yes = 1, no = 0']);
    end

    % Repeat block if necessary
    repeat = input(['Repeat block ' num2str(iBlock) ', Condition: M? yes = 1, no = 0']);
    if repeat == 1
        next = ['rand_m(' num2str(subject) ',' num2str(iPart) ',' num2str(iBlock) ')'];
        eval(next);
    end

    % Reset block counter
    iBlock = 1;

    % Update Part counter
    iPart = iPart + 1;
end

fclose(LOGFILE);
disp('EXPERIMENT FINISHED!!!');

end