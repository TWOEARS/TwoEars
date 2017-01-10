clear
close all
clc


%% LOAD SIGNAL
% 
% 
% Audio path
audioPath = fullfile(fileparts(mfilename('fullpath')),'Test_signals');

% Load a signal
load([audioPath,filesep,'AFE_earSignals_16kHz']);

% Create a data object based on parts of the right ear signal
dObj = dataObject(earSignals(1:22495,2),fsHz);


%% PLACE REQUEST AND CONTROL PARAMETERS
% 
% 
% Request innerhaircell processor    
requests = {'innerhaircell'};

% Parameters of Gammatone processor
fb_nChannels  = 16;  
fb_lowFreqHz  = 80;
fb_highFreqHz = 8000;

% Parameters of innerhaircell processor
ihc_method    = 'dau';

% Parameters 
par = genParStruct('fb_lowFreqHz',fb_lowFreqHz,'fb_highFreqHz',fb_highFreqHz,...
                   'fb_nChannels',fb_nChannels,'ihc_method',ihc_method); 
               

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
% Plot-related parameters
wavPlotZoom = 5; % Zoom factor
wavPlotDS   = 3; % Down-sampling factor

% Summarize plot parameters
p = genParStruct('wavPlotZoom',wavPlotZoom,'wavPlotDS',wavPlotDS);

% Plot gammatone responses
dObj.filterbank{1}.plot([],p);
% title('Gamatone response')

% Plot IHC responses
dObj.innerhaircell{1}.plot([],p);
title('IHC signal')
