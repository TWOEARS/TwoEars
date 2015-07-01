% This script initialises the path variables that are needed for running
% the Two!Ears Blackboard System module

basePath = [fileparts(mfilename('fullpath')) filesep];

% Add all relevant folders to the matlab search path
addpath([basePath 'blackboard_core']);
addpath([basePath 'blackboard_data']);
addpath([basePath 'evaluation']);
addpath([basePath 'gmtk_matlab_interface']);
addpath([basePath 'identificationTraining']);
addpath([basePath 'knowledge_sources']);

clear basePath;
