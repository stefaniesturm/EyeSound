function report_event(iSub, iContingency, soundID, iBlock, condition, TrialType, ExperimentStartTime, EyeSound_data, dummymode, port_exist, LOGFILEevents)
disp('Sound was played');
% Counterbalance order of active and passive conditions
if EyeSound_data(iSub).Counterbalancing == 1 % Active first
    % contingencies = [1 2 1 2 1 2 1 2 1 2 1 2 1 2]; % 1 is active and 2 is passive
    contingencies = [1 2];
elseif EyeSound_data(iSub).Counterbalancing == 2 % Passive first
    %contingencies = [2 1 2 1 2 1 2 1 2 1 2 1 2 1]; % 1 is active and 2 is passive
    contingencies = [2 1]; % debugging
end
% soundID = moveDirection; % Information for logfiles
acquisitionSound = GetSecs; % Information for logfiles
soundPlayed = soundID; % We need this for the coordinates logfile (I think)

% REPORT EVENT: SOUND %
% 1. Create trigger
AcquisitionSoundTrigger = str2double([ '0' sprintf('%d%d', contingencies(iContingency), iBlock)]);
% 2. Send porttalk trigger
if port_exist == 1
    porttalk(hex2dec('CFB8'), AcquisitionSoundTrigger, 1000);
end
% 3. Send Eyelink message
if dummymode == 0
    Eyelink('Message', 'Acquisition sound played.');
    Eyelink('Message', 'TRIGGER %03d', AcquisitionSoundTrigger);
end
disp('Writing into logfile');
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