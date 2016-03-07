% This script tests the various methods to access the parameter values that
% were used for the computation of some representations. It demonstrates the three
% alternatives:
%   - Access parameters used by a processor via its getCurrentParameters method
%   - Access parameters used to compute a given signal (getParameters method)
%   - Access a summary of all parameters used in a processing tree (manager's
%     getParameterSummary method)

clear all
close all


% Test on monoral or binaural signal
do_stereo = 1;

% Load a signal
load('AFE_earSignals_16kHz');
data = earSignals;
clear earSignals

% Parameters
request1 = 'itd';
p1 = genParStruct('fb_lowFreqHz',80,'fb_highFreqHz',8000,'fb_nChannels',30);

request2 = 'ild';
p2 = genParStruct('fb_lowFreqHz',80,'fb_highFreqHz',8000,'fb_nERBs',1/2);


% Instantiation and processing
dObj = dataObject(data,fsHz);           % Create a data object
mObj = manager(dObj);                   % Create empty manager
sOut = mObj.addProcessor(request1,p1);  % Add first request
mObj.addProcessor(request2,p2);         % Add second request
mObj.processSignal;                     % Request processing

fprintf('\n')

echo on
% Get the parameters of the requested signal...

% ... via its processor (has to be known)
mObj.Processors{6,1}.getCurrentParameters

% ... or directly from the signal handle 
sOut{1}.getParameters(mObj)

% Summary of all parameters used for the computation of all signals:
p = dObj.getParameterSummary(mObj);

% It shows that two different filterbanks and IHC representation exist,
% e.g.:
p.filterbank

% Though it stores which of these were used for dependent representations,
% e.g.:
p.ild



echo off
