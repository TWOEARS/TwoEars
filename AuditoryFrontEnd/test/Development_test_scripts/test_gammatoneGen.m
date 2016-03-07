% This script illustrates the three different ways of requesting an auditory filterbank,
% and the priorities between them in case of a conflict in the user-provided parameters.

clear 
close all
clc

% Load a signal
load('AFE_earSignals_16kHz');


%% Instantiate manager and data object

% Request a gammatone filtering...
request = 'filterbank';
dObj = dataObject(earSignals,fsHz); % Data object
mObj = manager(dObj);               % Manager instance

% ... in three different ways
p1 = genParStruct('fb_lowFreqHz',80,'fb_highFreqHz',8000,'fb_nERBs',1);          % Standard (default) way, frequency range and distance between channels
p2 = genParStruct('fb_lowFreqHz',80,'fb_highFreqHz',8000,'fb_nChannels',20);     % Frequency range and number of channels
p3 = genParStruct('fb_cfHz',[50 100 200 400 800 1600 3200]);                     % Entire vector of center frequencies

% Note the priority order when conflicting infos are provided:

% 1- Number of channels has priority over channel distance
p2_bis = genParStruct('fb_lowFreqHz',80,'fb_highFreqHz',8000,'fb_nERBs',1,'fb_nChannels',20);
% 2- Provided vector of center frequencies has priority over all
p3_bis = genParStruct('fb_lowFreqHz',80,'fb_highFreqHz',8000,'fb_nERBs',1,'fb_nChannels',20,'fb_cfHz',[50 100 200 400 800 1600 3200]);


% Add requested processors and display output signal properties
out1 = mObj.addProcessor(request,p1);
fprintf('First filterbank has center frequencies: \n%s\n',mat2str(out1{1}.cfHz,4))
out2 = mObj.addProcessor(request,p2);
fprintf('Second filterbank has center frequencies: \n%s\n',mat2str(out2{1}.cfHz,4))
out3 = mObj.addProcessor(request,p3);
fprintf('Third filterbank has center frequencies: \n%s\n\n',mat2str(out3{1}.cfHz,4))

out2_bis = mObj.addProcessor(request,p2_bis);
out3_bis = mObj.addProcessor(request,p3_bis);

% Illustrate the priority between parameters, both tests should return true (1)
echo on
out2_bis{1} == out2{1}
out3_bis{1} == out3{1}
echo off

