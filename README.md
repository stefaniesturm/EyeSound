# EyeSound
Code for EyeSound eyetracking and EEG experiment.

Execute "EyeSound_experiment.m" to run the experiment. This script uses "EyeSound_train.m" for the training and "EyeSound_run.m" for the real experiment. 

Each contingency can be executed seperately using the loop in "EyeSound_experiment.m". Start, stop and save the EEG recordings in Curry between every contingency (keep training separate). 

Make sure all the sub-folders of the EyeSound directory are in the Matlab path. The scripts use a function called "report_event.m" which is in the main directory, but since during the experiment we spend most of the time in the "results" directory in order to write into the logfiles, we need all the sub-folders to be in the path always. 