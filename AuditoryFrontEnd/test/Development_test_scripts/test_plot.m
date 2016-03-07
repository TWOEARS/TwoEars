% This script tests the capability of the manager to extract a specific
% cue

clear 
close all

% Load a signal
load('AFE_earSignals_16kHz');

data = earSignals;
clear earSignals

% Parameters
request = {'ild'};

% Create a data object
dObj = dataObject(data,fsHz);

% Create empty manager
mObj = manager(dObj);

% Add the request
sOut = mObj.addProcessor(request);

% Request processing
mObj.processSignal;

% Create empty figures
h1 = figure;
h11 = subplot(2,2,1);
h12 = subplot(2,2,2);
h13 = subplot(2,2,3);
h14 = subplot(2,2,4);

h2 = figure;

% Plot results
dObj.time{1}.plot(h13);
dObj.time{2}.plot(h14);
dObj.innerhaircell{1}.plot(h11);
dObj.innerhaircell{2}.plot(h12);

dObj.ild{1}.plot(h2);