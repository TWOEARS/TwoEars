% This script initialises the path variables that are needed for running
% the Two!Ears Blackboard System module

basePath = fileparts(mfilename('fullpath'));

% Add all relevant folders to the matlab search path
addpath(fullfile(basePath, 'src', 'blackboard_core'));
addpath(fullfile(basePath, 'src', 'blackboard_data'));
addpath(fullfile(basePath, 'src', 'evaluation'));
addpath(fullfile(basePath, 'src', 'gmtk_matlab_interface'));
addpath(fullfile(basePath, 'src', 'knowledge_sources'));

clear basePath;
