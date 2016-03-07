% This script is for testing the behavior of the hasProcessor method of the
% manager class. It illustrates how the method hasProcessor does not look
% only at the final processing stage, but also checks lower-level stages to
% control that they also have the requested parameters.

clear
close all

%#ok<*NOPTS>
%#ok<*EQEFF>

% Load a signal
load('AFE_earSignals_16kHz');

% Multiple requests
request1 = 'innerhaircell';
p1 = genParStruct;

request2 = 'innerhaircell';
p2 = genParStruct('fb_nERBs',1/3);


% Instantiate data and manager objects
dObj = dataObject(earSignals(:,2),fsHz);    % Create a data object based on this signal
mObj = manager(dObj);                       % Instantiate an empty manager

% Add requests
out1 = mObj.addProcessor(request1,p1);
out2 = mObj.addProcessor(request2,p2);

% Request the processing
mObj.processSignal


echo on

% There are two IHC Processors (3 & 5), both have the same IHC parameters:

mObj.Processors{3} 
mObj.Processors{5}

% Find which IHC processor has parameters p2:

h = mObj.hasProcessor('ihcProc',p2);

% Even though both IHC processors have same parameters, only one has its dependencies
% with the right set of parameters:

h == mObj.Processors{3} 
h == mObj.Processors{5}

echo off


