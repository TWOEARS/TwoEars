clear all
close all

% Basic script used throughout chapter 2 of deliverable 2.2
% Using echo for copy/pasting to deliverable text

load('AFE_earSignals_16kHz');
s = earSignals;
clear earSignals

% Start echo now
echo on

% Instantiation of data and manager objects
dataObj = dataObject(s,fsHz);
managerObj = manager(dataObj);

% Non-default parameter values
parameters = genParStruct('ild_wSizeSec',0.04,'ild_hSizeSec',0.02);

% Place a request for the computation of ILDs
sOut = managerObj.addProcessor('ild',parameters);

% Place another request
sOut2 = managerObj.addProcessor('onsetStrength');

% And a last one, with some parameter changes
moreParameters = genParStruct('ac_hSizeSec',0.015);
managerObj.addProcessor('autocorrelation',moreParameters);

% Request the processing
managerObj.processSignal;

echo off