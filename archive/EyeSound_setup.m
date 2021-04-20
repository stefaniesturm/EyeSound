function EyeSound_setup(nSubjects)



%% Setup overall parameters for task organization
nContingencies = 21; % 10 for each condition, 1 for training
nBlocksPerContingency = 6;
nTestTrialsperBlock = 6;
nMovementDirs = 8;

for iSub = 1:nSubjects
    
    if rem(iSub,2)==0
        Counterbalancing = 1;
    else
        Counterbalancing = 2;
    end
    
    % Save to EyeSound_NEW structure
    EyeSound_NEW(iSub).nContingencies = nContingencies;
    EyeSound_NEW(iSub).nBlocksPerContingency = nBlocksPerContingency;
    EyeSound_NEW(iSub).nTestTrialsperBlock = nTestTrialsperBlock;
    EyeSound_NEW(iSub).Counterbalancing = Counterbalancing;% 1 = start with Active; 2 = start with Passive
    EyeSound_NEW(iSub).nMovementDirs = nMovementDirs;
    
    %% Set contingencies
    % We need to create a set of 8 sounds for each
    % contingency. I each set the we assign a differet pitch and a different consonant to each sound
    % exemplar, and the same vowel to all exemplars.
    Pitches = {'90' '120' '150' '180' '210' '240' '270' '300'};
    Vowels = {'a' 'e' 'i' 'o' 'u'};
    Consonants = {'p' 'g' 'm' 'f' 'd' 'l' 's' 't'};
    nPitches = length(Pitches);
    nVowels = length(Vowels);
    nConsonants = length(Consonants);
    
    % First we make sure we run through all the vowels before repeating
    Vowels_sub = [];
    while size(Vowels_sub,2)<nContingencies
        Vowels_sub = [Vowels_sub randperm(nVowels)];
    end
    
    % Now we randomize the order of the pitches within each contingency
    for iContingency = 1:nContingencies
        Pitches_sub(iContingency,:) = randperm(nPitches);
    end
    
    % Now we randomize the order of the consonants within each contingency
    for iContingency = 1:nContingencies
        Consonants_sub(iContingency,:) = randperm(nConsonants);
    end
    
    % Now we construct the name of the wavfile
    for iContingency = 1:nContingencies
        for iExemplar = 1:nMovementDirs
            wavname = [Pitches{Pitches_sub(iContingency,iExemplar)} Consonants{Consonants_sub(iContingency,iExemplar)} Vowels{Vowels_sub(iContingency)} '.wav'];
            Contingencies{iContingency,iExemplar} = wavname;
        end
    end
    
    % Save to EyeSound_NEW structure
    EyeSound_NEW(iSub).Contingencies = Contingencies;% array with the wavfile names of the nContingencies x nExemplars corresponding to each movement direction in each contingency block
    
    
    %% Define test trials (50% correct 50% incorrect)
    
    % Create a matrix to read from for each block that has test trials in columns and in rows:
    % row 1: sound to be played
    % row 2: position/movement direction to show
    % row 3: code for congruent = 1 / incongruent = 0
    
    iBlock = 1;% counter for overall block number (irrespective of contingency)
    
    for iContingency = 1:nContingencies
        for iBlockperCont = 1:nBlocksPerContingency
            
            % Take all possible movement directions to test and randomize order
            PossibleTests = randperm(EyeSound_NEW(iSub).nMovementDirs);
            
            % Select the first half as the sounds to be presented as correct
            nCorrect = nTestTrialsperBlock/2;
            CorrectTrials = PossibleTests(1:nCorrect);
            % Save the info for this trials into the TestTrials matrix for this
            % block
            TestTrialsBlock(1,:) = CorrectTrials;% Sounds to be played (indices to read from 'SoundNames' in Active/Passive script)
            TestTrialsBlock(2,:) = CorrectTrials;% Positions/movementDirs to be played
            TestTrialsBlock(3,:) = repmat(1,1,nCorrect);% All coded as congruent (correct)
            
            % Select the second half of the possible positions/movement directions to be tested as incorrect
            IncorrectPositions = PossibleTests(nCorrect+1:nTestTrialsperBlock);
            
            
            % Set the sounds to use with the incorrect positions/movement directions out of the remaining sounds used in this contingengy block
            RemainingSounds = IncorrectPositions;
            % Shuffle the order of sounds until none of the sounds matches with its
            % congruent position/movementDir (until they are all incorrect)
            while any(IncorrectPositions == RemainingSounds)
                RemainingSounds = RemainingSounds(randperm(length(RemainingSounds)));
            end
            
            TestTrialsBlock(:,nCorrect+1:nCorrect*2) = [RemainingSounds;IncorrectPositions;repmat(0,1,nCorrect)];
            
            
            % Shuffle presentation order of congruent/incongruent (columns of
            % TestTrialsBlock matrix)
            TestTrialsBlock = TestTrialsBlock(:,randperm(nTestTrialsperBlock));
            
            % Save into EyeSound_NEW structure
            EyeSound_NEW(iSub).Blocks(iBlock).TestTrials = TestTrialsBlock;
            iBlock = iBlock+1; % counter for overall block number (irrespective of contingency)
            clear TestTrialsBlock;
        end
    end
    
end

%% Save parameters in matlab structure to read from block scripts
save('EyeSound_NEW.mat','EyeSound_NEW')


end