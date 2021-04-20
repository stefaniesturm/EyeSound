%% Build MIDI Interface
% This script builds a simple MIDI input interface for Windows. It requires
% the Windows SDK and a compiler. Note that the MIDI Interface comes with
% pre-compiled binaries for Windows 32-bit and 64-bit, so running this
% builder should not be required.
%
% Tucker McClure @ The MathWorks
% Copyright 2012-2013 The MathWorks, Inc.

function midi_interface_builder()

% Set some paths to the Windows SDK.
sdk_path = 'C:\Program Files (x86)\Microsoft SDKs\Windows\v5.0';
include_sub = '\Include';
library_sub = '\Lib\IA64';

% Specify the Include directory for Windows and the Library directory
% containing WinMM.lib and build everything.
fprintf('Building MEX file... ');
mex(['-I' sdk_path include_sub], ...
    ['-L' sdk_path library_sub], ....
    '-lwinmm', ...
    'midi_interface.cpp')

% Oh yeah.
fprintf('done.\n');
