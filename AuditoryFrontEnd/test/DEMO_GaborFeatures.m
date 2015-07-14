clear;
close all
clc


%% LOAD SIGNAL
% 
% 
% Load a signal
load('AFE_earSignals_16kHz');

% Create a data object based on parts of the right ear signal
dObj = dataObject(earSignals(1:22495,2),fsHz);


%% PLACE REQUEST AND CONTROL PARAMETERS
% 
% 
% Request gabor features  
requests = {'gabor'};

% Parameters of auditory filterbank following the ETSI standard
fb_type       = 'gammatone';
fb_lowFreqHz  = 124;
fb_highFreqHz = 3657;
fb_nChannels  = 23;  

% Window size in seconds
rm_wSizeSec = 25E-3;
rm_wStepSec = 10E-3; % DO NOT CHANGE!!!
rm_decaySec = 8E-3;

% Summary of parameters 
par = genParStruct('fb_type',fb_type,'fb_lowFreqHz',fb_lowFreqHz,...
                   'fb_highFreqHz',fb_highFreqHz,'fb_nChannels',fb_nChannels,...
                   'rm_wSizeSec',rm_wSizeSec,'rm_hSizeSec',rm_wStepSec,...
                   'rm_decaySec',rm_decaySec); 


%% PERFORM PROCESSING
% 
% 
% Create a manager
mObj = manager(dObj,requests,par);

% Request processing
mObj.processSignal();


%% PLOT RESULTS
% 
% 
% Ratemap
dObj.ratemap{1}.plot;
set(gca,'YTick',5:5:20,'YTickLabel',num2str((5:5:20)'))
ylabel('\# channels')


% Gabor features
dObj.gabor{1}.plot;

 