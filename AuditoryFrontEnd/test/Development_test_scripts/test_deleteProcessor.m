% This is a test script to investigate Matlab's event-based programming

clear;
close all

% Load a signal
load('AFE_earSignals_16kHz');
data = earSignals;   

% Parameters
request = {'itd'};
p = [];

% Create a data object
dObj = dataObject(data,fsHz);

% Create empty manager
mObj = manager(dObj);

% Add the request
sOut = mObj.addProcessor(request,p);

% Remove cross-correlation processor
mObj.Processors{4}.remove;
mObj.cleanup;

disp('mObj.Processors :')
mObj.Processors
