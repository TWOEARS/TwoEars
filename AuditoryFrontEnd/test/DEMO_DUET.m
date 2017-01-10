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

% Create a data object based on the ear signals
dObj = dataObject(earSignals(1:22494,:),fsHz);


%% PLACE REQUEST AND CONTROL PARAMETERS
% 
% 
% Request
% 1. interaural level differences (ILDs)
% 2. interaural time differences (ITDs)
% 3. weighted histogram of level/phase differences from DUET
requests = {'ild', 'itd', 'duet'};

% Parameters of the auditory filterbank processor
fb_type       = 'gammatone';
fb_lowFreqHz  = 80;
fb_highFreqHz = 8000;
fb_nChannels  = 32;  

% Parameters of innerhaircell processor
ihc_method    = 'dau';

% Parameters of crosscorrelation processor
cc_wSizeSec   = 0.02;
cc_hSizeSec   = 0.01;
cc_wname      = 'hann';

% Summary of parameters 
par = genParStruct('fb_type',fb_type,'fb_lowFreqHz',fb_lowFreqHz,...
                   'fb_highFreqHz',fb_highFreqHz,'fb_nChannels',fb_nChannels,...
                   'ihc_method',ihc_method,'cc_wSizeSec',cc_wSizeSec,...
                   'cc_hSizeSec',cc_hSizeSec,'cc_wname',cc_wname); 
               
               
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
% Plot the original ear signal
figure()
h1 = subplot(321);
dObj.plot(h1,[],'bGray',1,'decimateRatio',3,'bSignal',1);
ylim([-1.25 1.25]);

% Plot ILDs
h2 = subplot(323);
dObj.ild{1}.plot(h2);
title('ILD')

% Plot ITDs
h2 = subplot(324);
dObj.itd{1}.plot(h2);
title('ITD')

h3 = subplot(325);
dObj.duet{1}.plot(h3);
title('DUET')

[ild_itd_hist, ild_edges, itd_edges] = histcounts2(dObj.ild{1}.Data(:), ...
    dObj.itd{1}.Data(:), ...
    'Normalization', 'probability');
subplot(326);
contour(itd_edges(2:end), ild_edges(2:end), ild_itd_hist);
title('ILD-ITD histogram')
xlabel('ITD')
ylabel('ILD')
colorbar();
