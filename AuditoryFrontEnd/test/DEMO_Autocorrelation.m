clear;
close all
clc


%% LOAD SIGNAL
% 
% 
% Load a signal
load('Test_signals/AFE_earSignals_16kHz');

% Create a data object based on parts of the right ear signal
dObj = dataObject(earSignals(1:20E3,2),fsHz);


%% PLACE REQUEST AND CONTROL PARAMETERS
% 
% 
% Request auto-corrleation function (ACF)
requests = {'autocorrelation'};

% Parameters of the auditory filterbank processor
fb_type       = 'gammatone';
fb_lowFreqHz  = 80;
fb_highFreqHz = 8000;
fb_nChannels  = 16;  

% Parameters of innerhaircell processor
ihc_method    = 'dau';

% Parameters of autocorrelation processor
ac_wSizeSec  = 0.02;
ac_hSizeSec  = 0.01;
ac_clipAlpha = 0.0;
ac_K         = 2;
ac_wname     = 'hann';

% Summary of parameters 
par = genParStruct('fb_type',fb_type,'fb_lowFreqHz',fb_lowFreqHz,...
                   'fb_highFreqHz',fb_highFreqHz,'fb_nChannels',fb_nChannels,...
                   'ihc_method',ihc_method,'ac_wSizeSec',ac_wSizeSec,...
                   'ac_hSizeSec',ac_hSizeSec,'ac_clipAlpha',ac_clipAlpha,...
                   'ac_K',ac_K,'ac_wname',ac_wname); 


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
wavPlotZoom = 3; % Zoom factor
wavPlotDS   = 1; % Down-sampling factor

% Summarize plot parameters
p = genParStruct('wavPlotZoom',wavPlotZoom,'wavPlotDS',wavPlotDS);

% Plot the ACF of a single frame
frameIdx2Plot = 10;     

% Get the corresponding sample range for plotting the ihc in that range
wSizeSamples = 0.5 * round((ac_wSizeSec * fsHz * 2));
wStepSamples = round((ac_hSizeSec * fsHz));
samplesIdx = (1:wSizeSamples) + ((frameIdx2Plot-1) * wStepSamples);

dObj.innerhaircell{1}.plot([],p,'rangeSec',[samplesIdx(1) samplesIdx(end)]/fsHz);

% Plot the autocorrelation in that frame
dObj.autocorrelation{1}.plot([],p,frameIdx2Plot);


%% SHOW ACF MOVIE
% 
if 0
    h3 = figure;
    pauseSec = 0.0125;  % Pause between two consecutive plots
    dObj.autocorrelation{1}.plot(h3,par,1);
    
    % Loop over the number of frames
    for ii = 1 : size(dObj.autocorrelation{1}.Data(:),1)
        h31=get(h3,'children');
        cla(h31(1)); cla(h31(2));
        
        dObj.autocorrelation{1}.plot(h3,par,ii,'noTitle',1);
        pause(pauseSec);
        title(h31(2),['Frame number ',num2str(ii)])
    end
end


