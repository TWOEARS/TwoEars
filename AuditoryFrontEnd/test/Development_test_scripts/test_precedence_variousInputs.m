clear;
close all
clc

%% This demo needs the following functions to create input stimuli:
% stimulsBraasch.m
% stimulusCustomBraasch.m

%% CREATE INPUT SIGNAL
% % THREE input types can be tested - comment/uncomment as needed 
% %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % (A) Input signal, created for the demo using stimulusBraasch function
% % (see below for the input parameters and usage)
% 
% % Sampling Frequency [Hz]
% fsHz = 48000;           
% 
% % integer to select a waveform:
% %           0 - Sine Wave
% %           1 - Triangle Wave
% %           2 - Bandpass Noise
% %           3 - White Noise (Uniform Distribution)
% %           4 - Two sine waves (1st & 3rd harmonics; f = f of 2nd harmonic)
% %           5 - Three sine waves (1st, 2nd & 3rd harmonics; f = f of 2nd harmonic)
% %           6 - peak train
% waveForm = 2;           % Used for the stimulusBraasch function
% 
% length = 400;           % Signal length in ms
% fc = 500;               % For periodic waves: Frequency in Hz,
%                         % For Bandpass Noise: Fc of the bandpass filter
% bw = 800;               % Bandwidth of the FFT bandpass filters
% itd = 0.4;              % ITD in ms (applied in positive/negative pair for 
%                         %   lead/lag to stimulusBraasch function)                      
% ISI = 3;                % Inter-Stimulus Interval in ms
% attackTime = 20;        % Attach time in ms
% decayTime = 20;         % Decay time in ms
% 
% %           0: specified operation (both lead and lag are present), 
% %           1: switch off the lead, 2: switch off the lag
% operationMode = 0;      % Used for the stimulusBraasch function
% lagLevel = 0;           % Lag level in dB
% 
% % Binaural test stimulus using Braasch's function
% earSignals = stimulusBraasch(fsHz, waveForm, length, fc, bw, itd, -itd, ISI, ...
%     attackTime, decayTime, operationMode, db2amp(lagLevel));
% 
% % Create a data object
% dObj = dataObject(earSignals, fsHz);
% 

% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % (B) Speech signal, based on anechoic version
% % then added with a 'lag' version (using stimulusBraasch function)
% 
% % Load anechoic signal
% load('Test_signals/DEMO_Speech_Anechoic');
% % load('Test_signals/AFE_earSignals_16kHz');
% % Create lead-lag pair using the anechoic stimulus
% %Fs:    sampling frequency
% %signal1, signal2: original signal to be synthesised as lead-lag pair
% %isi:   ISI in milliseconds
% %nn:    0: specified operation, 1: switch off S1, 2: switch off S2
% %lag_level: Specific lag level
% ISI = 4;                % Inter-Stimulus Interval in ms
% %           0: specified operation (both lead and lag are present), 
% %           1: switch off the lead, 2: switch off the lag
% operationMode = 0;      % Used for the stimulusBraasch function
% lagLevel = -3;           % Lag level in dB
% 
% [earSignals, signal1, signal2] = stimulusCustomBraasch(fsHz, ...
%     earSignals(1:22494,:), fliplr(earSignals(1:22494,:)), ...
%     ISI, operationMode, db2amp(lagLevel));
% 
% % Create a data object
% dObj = dataObject(earSignals, fsHz);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (C) Speech signal, reverberant version
% Load reverberant signal
load('Test_signals/DEMO_Speech_Room_D');
% Create a data object
dObj = dataObject(earSignals, fsHz);


%% PLACE REQUEST AND CONTROL PARAMETERS

requests = 'precedence';
% fb_lowFreqHz = 100;
% fb_highFreqHz = 1400;

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

% Create a manager
mObj = manager(dObj,requests,par);

% Request processing
mObj.processSignal();


%% PLOT RESULTS

% Input signals
% dObj.plot([],[],'rangeSec', [0 0.1], 'bGray',1,'decimateRatio',3,'bSignal',1);
dObj.plot([],[], 'bGray',1,'decimateRatio',3,'bSignal',1);
set(gca, 'FontSize', 14, 'fontname','times');
ylim([-0.8 0.8]);
xlabel('Time (s)');
ylabel('Amplitude');
title('Time domain signals');
legend('boxoff');
% save2pdf('PrecedenceDEMO_input');
% save2pdf('PrecedenceDEMO_SpeechAnechoic_input');
save2pdf('PrecedenceDEMO_SpeechReverberant_input');

% Output ITD / ILD
dObj.precedence{1}.plot;
set(gca, 'FontSize', 14, 'fontname','times');
title('ITD', 'FontSize', 14, 'fontname','times');
xlabel('Time (s)');
ylabel('Center frequency (Hz)');
ax = colorbar;
ytick = get(ax, 'YTickLabel');
set(ax, 'YTickLabel', str2double(ytick));
% save2pdf('PrecedenceDEMO_ITD');
% save2pdf('PrecedenceDEMO_SpeechAnechoic_ITD');
save2pdf('PrecedenceDEMO_SpeechReverberant_ITD');

dObj.precedence{2}.plot;
set(gca, 'FontSize', 14, 'FontName','times');
title('ILD', 'FontSize', 14, 'fontname','times');
xlabel('Time (s)');
ylabel('Center frequency (Hz)');
% save2pdf('PrecedenceDEMO_ILD');
% save2pdf('PrecedenceDEMO_SpeechAnechoic_ILD');
save2pdf('PrecedenceDEMO_SpeechReverberant_ILD');

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

lagsMS = dObj.precedence{3}.lags*1E3;

% Plot the waveforms in that frame
dObj.plot([],[],'bGray',1,'rangeSec',[samplesIdx(1) samplesIdx(end)]/fsHz)
% ylim([-0.35 0.35])
set(gca, 'FontSize', 12, 'FontName','times');
xlabel('Time (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
% save2pdf('PrecedenceDEMO_inputFrame');
% save2pdf('PrecedenceDEMO_SpeechAnechoic_inputFrame');
save2pdf('PrecedenceDEMO_SpeechReverberant_inputFrame');

% Plot the cross-correlation in that frame
% dObj.precedence{3}.plot([],p, frameIdx2Plot, 'fsize_label', 14);
dObj.precedence{3}.plot([],p, frameIdx2Plot);
set(subplot(4,1,1:3), 'FontSize', 14, 'FontName','times');
title('Precedence-CCF');
set(subplot(4,1,4), 'FontSize', 14, 'FontName','times');
% save2pdf('PrecedenceDEMO_ccFrame');
% save2pdf('PrecedenceDEMO_SpeechAnechoic_ccFrame');
save2pdf('PrecedenceDEMO_SpeechReverberant_ccFrame');

% Calculate ITD comparable to Braasch's original version,
% based on summed CC (over frequency)

% 1) From frame-wise CC, calculated cumulative sum
ccOutput = dObj.precedence{3}.Data(:);
ccCumSum = cumsum(ccOutput, 1);
% 2) sum over freq. channels
ccSumAcrossFreq = squeeze(sum(ccCumSum, 2));
% 3) find maxima -> derive ITD
[maxCorr, indexITD] = max(ccSumAcrossFreq, [], 2);
maxLag = ceil(prec_maxDelaySec*fsHz);
ITD = (indexITD-maxLag-1)./fsHz;

t = (1:size(ITD, 1)).*prec_hSizeSec;
figure; plot(t, ITD.*1E3);
set(gca, 'FontSize', 14, 'FontName','times');
xlabel('Time (s)');
ylabel('ITD (ms)');
title(sprintf('ITD based on cumulative CCF summed over frequency'));
% save2pdf('PrecedenceDEMO_CumulativeITDsum');
% save2pdf('PrecedenceDEMO_SpeechAnechoic_CumulativeITDsum');
save2pdf('PrecedenceDEMO_SpeechReverberant_CumulativeITDsum');


% 1) From frame-wise CC
ccOutput = dObj.precedence{3}.Data(:);
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
title(sprintf('ITD based on CCF summed over frequency'));
% save2pdf('PrecedenceDEMO_ITDsum');
% save2pdf('PrecedenceDEMO_SpeechAnechoic_ITDsum');
save2pdf('PrecedenceDEMO_SpeechReverberant_ITDsum');


