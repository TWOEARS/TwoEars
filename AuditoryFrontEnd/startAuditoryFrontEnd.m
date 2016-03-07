% This script adds the necessary paths for the Two!Ears Auditory Front-End
% extraction framework and set up the needed pathes. Make sure to clear
% yourself the Matlab workspace, if that is necessary.

basePath = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(basePath, 'src')))
addpath(genpath(fullfile(basePath, 'test')))

clear basePath
