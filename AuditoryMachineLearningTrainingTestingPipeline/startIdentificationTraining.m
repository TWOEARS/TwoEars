% This script initialises the path variables that are needed for running
% the Identification Training Pipeline of the Two!Ears Blackboard System
% module

basePath = fileparts(mfilename('fullpath'));

% Add all relevant folders to the matlab search path
addpath(genpath(fullfile(basePath, 'src')));
addpath(genpath(fullfile(basePath, 'third_party_software')));

clear basePath;
