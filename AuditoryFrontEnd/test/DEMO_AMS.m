clear;
close all
clc


%% LOAD SIGNAL
% 
% 
% Load a signal
load('AFE_earSignals_16kHz');

% Create a data object based on the right ear signal
dObj = dataObject(earSignals(:,2),fsHz);


%% PLACE REQUEST AND CONTROL PARAMETERS
% 
% 
% Request amplitude modulation spectrogram (AMS) feaures
requests = 'amsFeatures';

% Parameters of auditory filterbank
fb_type       = 'gammatone';  
fb_lowFreqHz  = 80;
fb_highFreqHz = 8000;
fb_nChannels  = 23;  

% Parameters of AMS processor
ams_fbType_lin = 'lin';
ams_fbType_log = 'log';
ams_wSizeSec   = 32E-3;
ams_hSizeSec   = 16E-3;

% Parameters for linearly-scaled AMS
parLin = genParStruct('fb_type',fb_type,'fb_lowFreqHz',fb_lowFreqHz,...
                      'fb_highFreqHz',fb_highFreqHz,'fb_nChannels',fb_nChannels,...
                      'ams_wSizeSec',ams_wSizeSec,'ams_hSizeSec',ams_hSizeSec,...
                      'ams_fbType',ams_fbType_lin); 
                  
% Parameters for logarithmically-scaled AMS                  
parLog = genParStruct('fb_type',fb_type,'fb_lowFreqHz',fb_lowFreqHz,...
                      'fb_highFreqHz',fb_highFreqHz,'fb_nChannels',fb_nChannels,...
                      'ams_wSizeSec',ams_wSizeSec,'ams_hSizeSec',ams_hSizeSec,...
                      'ams_fbType',ams_fbType_log); 

               
%% PERFORM PROCESSING
% 
% 
% Create a manager
mObj = manager(dObj,requests,{parLin parLog});

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

% Plot time domain signal
dObj.time{1}.plot;grid on;ylim([-1 1]);title('Time domain signal')

% Plot IHC representation
dObj.innerhaircell{1}.plot([],p);title('IHC signal')

% Plot linear AMS pattern
dObj.amsFeatures{1}.plot;title('linear AMS features')
delete(findobj( 0, 'tag', 'Colorbar' ));

% Plot logarithmic AMS pattern
dObj.amsFeatures{2}.plot;title('logarithmic AMS features')
delete(findobj( 0, 'tag', 'Colorbar' ))

