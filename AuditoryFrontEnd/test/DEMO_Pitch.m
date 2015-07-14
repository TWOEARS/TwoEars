clear;
close all
clc


%% LOAD SIGNAL
% 
% 
% Load a signal
load('AFE_earSignals_16kHz');

% Create a data object based on parts of the right ear signal
dObj = dataObject(earSignals(1:20E3,2),fsHz);


%% PLACE REQUEST AND CONTROL PARAMETERS
% 
% 
% Request pitch processor
requests = {'pitch'};

% Parameters of auditory filterbank 
fb_type       = 'gammatone';
fb_lowFreqHz  = 80;
fb_highFreqHz = 8000;
fb_nChannels  = 16;  

% Parameters of innerhaircell processor
ihc_method    = 'dau';

% Parameters of autocorrelation processor
ac_wSizeSec   = 0.02;
ac_hSizeSec   = 0.01;
ac_clipAlpha  = 0.0;
ac_K          = 2;
ac_wname      = 'hann';

% Parameters of pitch processor
pi_rangeHz     = [80 400];
pi_confThres   = 0.7;
pi_medianOrder = 3;

% Parameters 
par = genParStruct('fb_type',fb_type,'fb_lowFreqHz',fb_lowFreqHz,...
                   'fb_highFreqHz',fb_highFreqHz,'fb_nChannels',fb_nChannels,...
                   'ihc_method',ihc_method,'ac_wSizeSec',ac_wSizeSec,...
                   'ac_hSizeSec',ac_hSizeSec,'ac_clipAlpha',ac_clipAlpha,...
                   'ac_K',ac_K,'ac_wname',ac_wname,'pi_rangeHz',pi_rangeHz,...
                   'pi_confThres',pi_confThres,'pi_medianOrder',pi_medianOrder); 
               

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
% Plot time-domain signal
dObj.time{1}.plot;   

% Autocorrelation with raw pitch overlay (in the lag domain)
h2 = figure;
dObj.autocorrelation{1}.plot(h2);  
ylim([0 0.02])
hold on
dObj.pitch{1}.plot(h2,'rawPitch','pitchRange',mObj.Processors{5}.pitchRangeHz,...
                                 'lagDomain',1);

% Confidence plot with threshold
h3 = figure;
dObj.pitch{1}.plot(h3,'confidence','confThres',mObj.Processors{5}.confThresPerc);

% Final pitch estimation
h4 = figure;
dObj.pitch{1}.plot(h4,'pitch','pitchRange',mObj.Processors{5}.pitchRangeHz);

