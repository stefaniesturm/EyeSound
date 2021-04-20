
%%% ------------------ EYESOUND EXPERIMENT SESSION ------------------ %%%

% This script guides the experimenter through an experimental session
% step-by-step

cd 'C:\USER\Stefanie\EyeSound\'

% What number is the participant?
iSub = 2;

% Check counterbalancing of participant and note it down on the "experiment 
% sheet"
load EyeSound_data.mat;
counterbalancing = EyeSound_data(iSub).Counterbalancing

% Run training
% EyeSound_train(iSub, iContingency) 
% in the logfiles, it will be recorded as iContingency-1 = 0
EyeSound_train(iSub, 1)

% Run experimental levels
% EyeSound_run(iSub, StartLevel)
% To retrieve contingencies from EyeSound_data.mat, iContingency+1 will be used 
% (in order not to repeat the contingencies from the training)
 
 for iContingency = 1:14
     EyeSound_run(iSub, iContingency)
     prompt = 'Ready for next contingency? Y/N';
     str = input(prompt,'s');
    if str == 'Y'
        disp('Moving on!');
    elseif str == 'N'
        break
    end
 end