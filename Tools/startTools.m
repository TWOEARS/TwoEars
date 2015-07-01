% This script initialises the path variables that are needed for running
% the Tools code.

basePath = [fileparts(mfilename('fullpath')) filesep];

% Add all relevant folders to the matlab search path
addpath([basePath 'args']);
addpath([basePath 'misc']);

clear basePath;
