clear;
close all
clc


%% LOAD SIGNAL
% 
% 
% Load a signal
load('Test_signals/AFE_earSignals_16kHz');

% Create a data object based on parts of the right ear signal
dObj = dataObject(earSignals(1:22494,2),fsHz);


%% PLACE REQUEST AND CONTROL PARAMETERS
% 
% 
% Request onset and offset maps
requests = {'onsetMap' 'offsetMap'};

% Parameters of auditory filterbank 
fb_type       = 'gammatone';
fb_lowFreqHz  = 80;
fb_highFreqHz = 8000;
fb_nChannels  = 64;  

% Parameters of innerhaircell processor
ihc_method    = 'dau';

% Parameters of ratemap processor
rm_wSizeSec  = 0.02;
rm_hSizeSec  = 0.01;
rm_decaySec  = 8E-3;
rm_wname     = 'hann';

% Parameters for switching off the transient detector
trm_off_minValuedB    = -80;
trm_off_minStrengthdB = 0;
trm_off_minSpread     = 0;
trm_off_fuseWithinSec = 0;

% Parameters of transient detector (same parameters for onsets & offests)
trm_on_minValuedB    = -80;
trm_on_minStrengthdB = 3;
trm_on_minSpread     = 5;
trm_on_fuseWithinSec = 30E-3;

% Summary of parameters without transient detector
parOff = genParStruct('fb_type',fb_type,'fb_lowFreqHz',fb_lowFreqHz,...
                      'fb_highFreqHz',fb_highFreqHz,'fb_nChannels',fb_nChannels,...
                      'ihc_method',ihc_method,'ac_wSizeSec',rm_wSizeSec,...
                      'ac_hSizeSec',rm_hSizeSec,'rm_decaySec',rm_decaySec,...
                      'ac_wname',rm_wname,'trm_minValuedB',trm_off_minValuedB,...
                      'trm_minStrengthdB',trm_off_minStrengthdB,'trm_minSpread',trm_off_minSpread,...
                      'trm_fuseWithinSec',trm_off_fuseWithinSec); 

% Summary of parameters for transient detector
parOn = genParStruct('fb_type',fb_type,'fb_lowFreqHz',fb_lowFreqHz,...
                     'fb_highFreqHz',fb_highFreqHz,'fb_nChannels',fb_nChannels,...
                     'ihc_method',ihc_method,'ac_wSizeSec',rm_wSizeSec,...
                     'ac_hSizeSec',rm_hSizeSec,'rm_decaySec',rm_decaySec,...
                     'ac_wname',rm_wname,'trm_minValuedB',trm_on_minValuedB,...
                     'trm_minStrengthdB',trm_on_minStrengthdB,'trm_minSpread',trm_on_minSpread,...
                     'trm_fuseWithinSec',trm_on_fuseWithinSec); 
                    
                    
%% PERFORM PROCESSING
% 
% 
% Create managers
mObj1 = manager(dObj,requests,parOff);
mObj2 = manager(dObj,requests,parOn);

% Request processing
mObj1.processSignal();
mObj2.processSignal();


%% PLOT RESULTS
% 
% 
% Plot the onset
h = dObj.onsetMap{1}.plot;
hold on

% Superimposed the offset (in white)
p = genParStruct('binaryMaskColor',[1 1 1]);    % White mask
dObj.offsetMap{1}.plot(h,p,1);

% Replace the title
title('Onset (black) and offset (white) maps')

% Plot the onset
h = dObj.onsetMap{2}.plot;
hold on

% Superimposed the offset (in white)
p = genParStruct('binaryMaskColor',[1 1 1]);   % White mask
dObj.offsetMap{2}.plot(h,p,1);

% Replace the title
title('Onset (black) and offset (white) maps')

