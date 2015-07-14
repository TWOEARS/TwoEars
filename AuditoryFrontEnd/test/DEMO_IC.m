clear;
close all
clc


%% LOAD SIGNAL
% 
% 
% Load anechoic signal
load('DEMO_Speech_Anechoic');

% Create a data object based on the ear signals
dObj1 = dataObject(earSignals(1:22494,:),fsHz);

% Load erverberant signal
load('DEMO_Speech_Room_D');

% Create a data object based on the ear signals
dObj2 = dataObject(earSignals(1:22494,:),fsHz);


%% PLACE REQUEST AND CONTROL PARAMETERS
% 
% 
% Request interaural coherence (IC)
requests = {'ic'};

% Parameters of the auditory filterbank processor
fb_type       = 'gammatone';
fb_lowFreqHz  = 80;
fb_highFreqHz = 8000;
fb_nChannels  = 32;  

% Parameters of innerhaircell processor
ihc_method    = 'dau';

% Parameters of crosscorrelation processor
cc_wSizeSec  = 0.02;
cc_hSizeSec  = 0.01;
cc_wname     = 'hann';

% Summary of parameters 
par = genParStruct('fb_type',fb_type,'fb_lowFreqHz',fb_lowFreqHz,...
                   'fb_highFreqHz',fb_highFreqHz,'fb_nChannels',fb_nChannels,...
                   'ihc_method',ihc_method,'cc_wSizeSec',cc_wSizeSec,...
                   'cc_hSizeSec',cc_hSizeSec,'cc_wname',cc_wname); 
               
               
%% PERFORM PROCESSING
% 
% 
% Create two managers
mObj1 = manager(dObj1,requests,par);
mObj2 = manager(dObj2,requests,par);

% Request processing
mObj1.processSignal();
mObj2.processSignal();


%% PLOT RESULTS
% 
% 
% Plot the original ear signal
dObj1.plot([],[],'bGray',1,'decimateRatio',3,'bSignal',1);
ylim([-1.25 1.25]);

% Plot IC
dObj1.ic{1}.plot;
title('Interaural coherence (anechoic)')

% Plot the original ear signal
dObj2.plot([],[],'bGray',1,'decimateRatio',3,'bSignal',1);
ylim([-1.25 1.25]);

% Plot IC
dObj2.ic{1}.plot;
title('Interaural coherence (reverberant)')
