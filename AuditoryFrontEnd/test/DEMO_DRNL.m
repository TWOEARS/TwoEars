clear;
close all
clc


%% LOAD SIGNAL
% 
% 
% Load a signal
load('AFE_earSignals_16kHz');

% Take single channel (1- Left or 2 - Right)
earSignal = earSignals(:,2);
fprintf('1st half: %.1f dB(SPL), 2nd half: %.1f dB\n', dbspl(earSignal/5), ...
    dbspl(earSignal));

% Replicate signals at a higher level
earSignal = cat(1,earSignal(1:22495),5*earSignal(1:22495))/5;
fprintf('Overall: %.1f dB(SPL)\n', dbspl(earSignal));

% Apply additional gain (to find a level region where 
% the compressive nonlinearity can be shown effectively)
addGain = -10;              % Change this to adjust final input level
earSignalScaled = gaindb(earSignal, addGain);
fprintf('Scaled level: %.1f dB(SPL)\n', dbspl(earSignalScaled));

% Create data objects
dObj_DRNL = dataObject(earSignalScaled,fsHz);
dObj_GT = dataObject(earSignalScaled, fsHz);

% Plot properties
p_plot = genParStruct('fsize_label',10,'fsize_axes',10,'fsize_title',10);

% % Plot the original ear signal
% dObj_DRNL.plot([],p_plot,'bGray',1,'decimateRatio',3,'bSignal',1);
% legend off, ylim([-0.4 0.4])
% title(sprintf('Original input signal sampled at %i Hz',fsHz))

%% PLACE REQUEST AND CONTROL PARAMETERS
% 
%
% Request DRNL / gammatone
requests = {'filterbank'};

% Parameters of pre-processing
pp_refSPLdB = 100;
pp_middleEarModel = 'jepsen';

% Parameters of auditory filterbank 
% fb_cfHz = [500 1000 2000 4000 8000];
fb_cfHz = 1000;
% Summary of parameters 
par_DRNL = genParStruct('pp_bLevelScaling', true, 'pp_refSPLdB', pp_refSPLdB, ...
                        'pp_bMiddleEarFiltering', true, ...
                        'pp_middleEarModel', pp_middleEarModel, ...
                        'fb_type', 'drnl', 'fb_cfHz', fb_cfHz);

par_GT = genParStruct('pp_bLevelScaling', true, 'pp_refSPLdB', pp_refSPLdB, ...
                        'pp_bMiddleEarFiltering', true, ...
                        'pp_middleEarModel', pp_middleEarModel, ...
                        'fb_type', 'gammatone', 'fb_cfHz', fb_cfHz);

                    
%% PERFORM PROCESSING
% 
% 
% Create managers
mObj_DRNL = manager(dObj_DRNL, requests, par_DRNL);
mObj_GT = manager(dObj_GT, requests, par_GT);

% Request processing
mObj_DRNL.processSignal();
mObj_GT.processSignal();


%% PLOT RESULTS
% 
% 
% % Plot time domain signal (after pre-processing)
% dObj_DRNL.time{1}.plot
% 
% 
% % Plot-related parameters
% wavPlotZoom = 2; % Zoom factor
% wavPlotDS   = 3; % Down-sampling factor
% 
% % Summarize plot parameters
% p = genParStruct('wavPlotZoom',wavPlotZoom,'wavPlotDS',wavPlotDS);
% 
% % Plot filterbank output
% dObj_DRNL.filterbank{1}.plot([],p);
% dObj_GT.filterbank{1}.plot([],p);

tSec = (1:size(earSignalScaled,1))/fsHz;
figure;
plot(tSec, 1E5 * dObj_GT.filterbank{1}.Data(:));
xlim([tSec(1) tSec(end)]);
xlabel('Time (s)');
ylabel('Amplitude (x 1E$^{-5}$)')
title(sprintf('Gammatone filterbank output at %d Hz', dObj_GT.filterbank{1}.cfHz));

figure;
plot(tSec, dObj_DRNL.filterbank{1}.Data(:));
xlim([tSec(1) tSec(end)]);
title(sprintf('DRNL filterbank output at %d Hz', dObj_DRNL.filterbank{1}.cfHz));
xlabel('Time (s)');
ylabel('Amplitude (x 1E$^{-5}$)')



