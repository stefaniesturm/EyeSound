% Concatenate all the syllable names

cd '/home/stefanie/GitHub/EyeSound/'
load('EyeSound_data.mat')

A = [];
for i = 1:30
    B = [EyeSound_data(i).Contingencies{:}];
    A = horzcat(A, B);
    A
end

% This gives one long string and because I suck I just copy-pasted it and
% added commas in the right places in a text editor using regular
% expressions