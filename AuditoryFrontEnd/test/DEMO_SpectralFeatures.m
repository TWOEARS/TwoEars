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
% Request spectral feature processor
requests = {'spectralFeatures'};

% Parameters of Gammatone processor
fb_nChannels  = 64;  
fb_lowFreqHz  = 80;
fb_highFreqHz = 8000;

% Parameters of innerhaircell processor
ihc_method    = 'dau';

% Parameters of ratemap processor
rm_wSizeSec  = 0.02;
rm_hSizeSec  = 0.01;
rm_scaling   = 'power';
rm_decaySec  = 8E-3;
rm_wname     = 'hann';

% Parameters 
par = genParStruct('fb_lowFreqHz',fb_lowFreqHz,'fb_highFreqHz',fb_highFreqHz,...
                   'fb_nChannels',fb_nChannels,'ihc_method',ihc_method,...
                   'ac_wSizeSec',rm_wSizeSec,'ac_hSizeSec',rm_hSizeSec,...
                   'rm_scaling',rm_scaling,'rm_decaySec',rm_decaySec,...
                   'ac_wname',rm_wname); 

               
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
% Plot time domain signal
dObj.time{1}.plot

% Handle to the ratemap for plot overlay
rmap = dObj.ratemap{1};   

% Plot spectral features
dObj.spectralFeatures{1}.plot([],[],'overlay',rmap,'noSubPlots',1);

