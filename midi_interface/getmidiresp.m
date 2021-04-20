function [key,time,messages,times] = getmidiresp()

%   [key, time] = getmidiresp() returns the numer of the keys pressed since
%   the last call to this function or to midi_interface(). The timing
%   values are milliseconds since the interface was started (since the
%   'open' command). These values come from the system's MIDI driver via Windows.

%   - The maximum buffer size is 65536 messages. Beyond this number, 
%   messages will be dropped, so the buffer should be checked quickly.

[messages,times] = midi_interface();
press = messages(1,:) == 144;
key = messages(2,press);
time = times(press);