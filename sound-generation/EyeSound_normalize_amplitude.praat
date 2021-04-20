
# Normalize amplitude
# Stefanie Sturm, 2021

# This Praat script will create amplitude normalized stimuli in WAV format and save to a new directory


form Normalize Amplitude in sound files
	sentence sound_file_extension .wav
   	comment Directory path of input files:
   	text input_directory  /home/stefanie/GitHub/EyeSound/sound-generation/Spanish/flat_pitch/
   	comment Directory path of resampled files (old files will be overwritten!):
   	text output_directory  /home/stefanie/GitHub/EyeSound/sound-generation/Spanish/final/
	comment What amplitude do you want to set to?
   		positive amplitude 40
endform

Create Strings as file list... list 'input_directory$'*'sound_file_extension$'
number_files = Get number of strings

for ifile to number_files
	select Strings list
	sound$ = Get string... ifile
	Read from file... 'input_directory$''sound$'
	objectname$ = selected$ ("Sound", 1)
	Scale intensity... 'amplitude'
	Write to WAV file... 'output_directory$''objectname$'.wav
	Remove
endfor

select Strings list
Remove