clear
close all
clc

%% This demo needs the following function(s) to create input stimuli:
% stimulusCustomBraasch.m

% Refer to \test\Development_test_scripts\test_precedence_variousInputs.m
%  for more tests with noise, anechoic speech-based artificial lags, and
%  reverberant speech-based stimulus

%% CREATE INPUT SIGNAL

% Speech signal, based on anechoic version
% then added with a 'lag' version (using stimulusBraasch function)

% Load anechoic signal
load('Test_signals/DEMO_Speech_Anechoic');

% Create lead-lag pair using the stimulusCustomBraasch function
% input parameters:
%       Fs                 : sampling frequency
%       lead, lag          : original signals to be synthesised as lead-lag pair
%       ISI                : ISI in milliseconds
%       operationMode      : 0 - specified operation (both lead and lag are present)
%                            1 - switch off the lead
%                            2 - switch off the lag
%       lagLevel           : Specific lag level as multiplication factor
%                           (amplitude)

Fs = fsHz;
lead = earSignals(1:22494,:);
lag = fliplr(earSignals(1:22494,:));
ISI = 4;                    % Inter-Stimulus Interval in ms
operationMode = 0;          % both lead and lag present
lagLevel = db2amp(-3);      % Lag level: -3 dB

[earSignals, signal1, signal2] = ...
    stimulusCustomBraasch(Fs, lead, lag, ISI, operationMode, lagLevel);

% Create a data object
dObj_anechoic = dataObject(earSignals, fsHz);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (C) Speech signal, reverberant version
% Load reverberant signal
load('Test_signals/DEMO_Speech_Room_D');
% Create a data object
dObj_reverberant = dataObject(earSignals, fsHz);

% IT IS ASSUMED THAT fsHz for dObj_anechoic and dObj_reverberant is the
% same!

%% PLACE REQUEST AND CONTROL PARAMETERS

requests = 'precedence';

fb_lowFreqHz  = 80;
fb_highFreqHz = 8000;
fb_nChannels  = 32; 

% Note copied from Braasch's code:
% minimum windowlength needs to be in order of binaural sluggishness for
% the model to operate properly. Needs sufficient length to perform 
% autocorrelation over both lead and lag.
prec_wSizeSec = 0.02;
prec_hSizeSec = 0.01;
prec_maxDelaySec = 0.001;

par = genParStruct('fb_lowFreqHz',fb_lowFreqHz, ...
    'fb_highFreqHz',fb_highFreqHz, ...
    'fb_nChannels', fb_nChannels, ...
    'prec_wSizeSec', prec_wSizeSec, ...
    'prec_hSizeSec', prec_hSizeSec, ...
    'prec_maxDelaySec', prec_maxDelaySec);
 

%% PERFORM PROCESSING

% Create manager
mObj_anechoic = manager(dObj_anechoic,requests,par);
mObj_reverberant = manager(dObj_reverberant,requests,par);

% Request processing
mObj_anechoic.processSignal();
mObj_reverberant.processSignal();


%% PLOT RESULTS
%% 1. Anechoic speech + synthesised lag version (dObj_anechoic)

% Input signals
dObj_anechoic.plot([],[], 'bGray',1,'decimateRatio',3,'bSignal',1);
set(gca, 'FontSize', 14, 'fontname','times');
ylim([-0.8 0.8]);
xlabel('Time (s)');
ylabel('Amplitude');
title('Time domain signals (with synthesised lag)');
legend('boxoff');

% Output ITD / ILD
dObj_anechoic.precedence{1}.plot;
set(gca, 'FontSize', 14, 'fontname','times');
title('ITD (synthesised lag)', 'FontSize', 14, 'fontname','times');
xlabel('Time (s)');
ylabel('Center frequency (Hz)');
ax = colorbar;
ytick = get(ax, 'YTickLabel');
set(ax, 'YTickLabel', str2double(ytick));

dObj_anechoic.precedence{2}.plot;
set(gca, 'FontSize', 14, 'FontName','times');
title('ILD (synthesised lag)', 'FontSize', 14, 'fontname','times');
xlabel('Time (s)');
ylabel('Center frequency (Hz)');

% Plot-related parameters
wavPlotZoom = 1.5; % Zoom factor
wavPlotDS   = 1; % Down-sampling factor
fsize_label = 14;
fsize_title = 14;
ftype = 'times';

% Summarize plot parameters
p = genParStruct('wavPlotZoom',wavPlotZoom,'wavPlotDS',wavPlotDS, ...
    'fsize_label', fsize_label, 'fsize_title', fsize_title, 'ftype', ftype);

% Plot the CCF of a single frame
frameIdx2Plot = 25;

% Get sample indexes in that frame to limit waveforms plot
wSizeSamples = 0.5 * round((prec_wSizeSec * fsHz * 2));
wStepSamples = round((prec_hSizeSec * fsHz));
samplesIdx = (1:wSizeSamples) + ((frameIdx2Plot-1) * wStepSamples);

lagsMS = dObj_anechoic.precedence{3}.lags*1E3;

% Plot the waveforms in that frame
dObj_anechoic.plot([],[],'bGray',1,'rangeSec',[samplesIdx(1) samplesIdx(end)]/fsHz);
set(gca, 'FontSize', 12, 'FontName','times');
xlabel('Time (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title(sprintf('Waveform of frame %d\n(with synthesised lag)', frameIdx2Plot));

% Plot the cross-correlation in that frame
dObj_anechoic.precedence{3}.plot([],p, frameIdx2Plot);
set(subplot(4,1,1:3), 'FontSize', 14, 'FontName','times');
title(sprintf('Precedence-CCF, frame %d (with synthesised lag)', frameIdx2Plot));
set(subplot(4,1,4), 'FontSize', 14, 'FontName','times');

% Derive ITD from frame-wise CC summed over frequency channels
% 1) From frame-wise CC
ccOutput = dObj_anechoic.precedence{3}.Data(:);
% 2) sum over freq. channels
ccSumAcrossFreq = squeeze(sum(ccOutput, 2));
% 3) find maxima -> derive ITD
[maxCorr, indexITD] = max(ccSumAcrossFreq, [], 2);
maxLag = ceil(prec_maxDelaySec*fsHz);
ITD = (indexITD-maxLag-1)./fsHz;

t = (1:size(ITD, 1)).*prec_hSizeSec;
figure; plot(t, ITD.*1E3);
set(gca, 'FontSize', 14, 'FontName','times');
xlabel('Time (s)');
ylabel('ITD (ms)');
title(sprintf('ITD based on CCF summed over frequency\n(synthesised lag)'));


%% 2. Reverberant speech version (dObj_reverberant)

% Input signals
dObj_reverberant.plot([],[], 'bGray',1,'decimateRatio',3,'bSignal',1);
set(gca, 'FontSize', 14, 'fontname','times');
ylim([-0.8 0.8]);
xlabel('Time (s)');
ylabel('Amplitude');
title('Time domain signals (reverberant ver.)');
legend('boxoff');

% Output ITD / ILD
dObj_reverberant.precedence{1}.plot;
set(gca, 'FontSize', 14, 'fontname','times');
title('ITD (reverberant ver.)', 'FontSize', 14, 'fontname','times');
xlabel('Time (s)');
ylabel('Center frequency (Hz)');
ax = colorbar;
ytick = get(ax, 'YTickLabel');
set(ax, 'YTickLabel', str2double(ytick));

dObj_reverberant.precedence{2}.plot;
set(gca, 'FontSize', 14, 'FontName','times');
title('ILD (reverberant ver.)', 'FontSize', 14, 'fontname','times');
xlabel('Time (s)');
ylabel('Center frequency (Hz)');

% Plot-related parameters
wavPlotZoom = 1.5; % Zoom factor
wavPlotDS   = 1; % Down-sampling factor
fsize_label = 14;
fsize_title = 14;
ftype = 'times';

% Summarize plot parameters
p = genParStruct('wavPlotZoom',wavPlotZoom,'wavPlotDS',wavPlotDS, ...
    'fsize_label', fsize_label, 'fsize_title', fsize_title, 'ftype', ftype);

% Plot the CCF of a single frame
frameIdx2Plot = 25;

% Get sample indexes in that frame to limit waveforms plot
wSizeSamples = 0.5 * round((prec_wSizeSec * fsHz * 2));
wStepSamples = round((prec_hSizeSec * fsHz));
samplesIdx = (1:wSizeSamples) + ((frameIdx2Plot-1) * wStepSamples);

lagsMS = dObj_reverberant.precedence{3}.lags*1E3;

% Plot the waveforms in that frame
dObj_reverberant.plot([],[],'bGray',1,'rangeSec',[samplesIdx(1) samplesIdx(end)]/fsHz);
set(gca, 'FontSize', 12, 'FontName','times');
xlabel('Time (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title(sprintf('Waveform of frame %d\n(reverberant ver.)', frameIdx2Plot));

% Plot the cross-correlation in that frame
dObj_reverberant.precedence{3}.plot([],p, frameIdx2Plot);
set(subplot(4,1,1:3), 'FontSize', 14, 'FontName','times');
title(sprintf('Precedence-CCF, frame %d (reverberant ver.)', frameIdx2Plot));
set(subplot(4,1,4), 'FontSize', 14, 'FontName','times');

% Derive ITD from frame-wise CC summed over frequency channels
% 1) From frame-wise CC
ccOutput = dObj_reverberant.precedence{3}.Data(:);
% 2) sum over freq. channels
ccSumAcrossFreq = squeeze(sum(ccOutput, 2));
% 3) find maxima -> derive ITD
[maxCorr, indexITD] = max(ccSumAcrossFreq, [], 2);
maxLag = ceil(prec_maxDelaySec*fsHz);
ITD = (indexITD-maxLag-1)./fsHz;

t = (1:size(ITD, 1)).*prec_hSizeSec;
figure; plot(t, ITD.*1E3);
set(gca, 'FontSize', 14, 'FontName','times');
xlabel('Time (s)');
ylabel('ITD (ms)');
title(sprintf('ITD based on CCF summed over frequency\n(reverberant ver.)'));

