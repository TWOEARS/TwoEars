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

% Create a data object based on parts of the ear signals
dObj = dataObject(earSignals(1:20E3,:),fsHz);


%% PLACE REQUEST AND CONTROL PARAMETERS
% 
% 
% Request cross-corrleation function (CCF)
requests = {'crosscorrelation'};

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
% Plot-related parameters
wavPlotZoom = 5; % Zoom factor
wavPlotDS   = 1; % Down-sampling factor

% Summarize plot parameters
p = genParStruct('wavPlotZoom',wavPlotZoom,'wavPlotDS',wavPlotDS);

% Plot the CCF of a single frame
frameIdx2Plot = 10;

% Get sample indexes in that frame to limit waveforms plot
wSizeSamples = 0.5 * round((cc_wSizeSec * fsHz * 2));
wStepSamples = round((cc_hSizeSec * fsHz));
samplesIdx = (1:wSizeSamples) + ((frameIdx2Plot-1) * wStepSamples);

lagsMS = dObj.crosscorrelation{1}.lags*1E3;

% Plot the waveforms in that frame
dObj.plot([],[],'bGray',1,'rangeSec',[samplesIdx(1) samplesIdx(end)]/fsHz);
ylim([-0.35 0.35])

% Plot the cross-correlation in that frame
dObj.crosscorrelation{1}.plot([],p,frameIdx2Plot);


%% SHOW CCF MOVIE
% 
% 
if 0
    h3 = figure;
    % Pause in seconds between two consecutive plots 
    pauseSec = 0.0125;
    dObj.crosscorrelation{1}.plot(h3,p,1);
    
    % Loop over the number of frames
    for ii = 2 : size(dObj.crosscorrelation{1}.Data(:),1)
        h31=get(h3,'children');
        cla(h31(1)); cla(h31(2));
        
        dObj.crosscorrelation{1}.plot(h3,p,ii,'noTitle',1);
        pause(pauseSec);
        title(h31(2),['Frame number ',num2str(ii)])
    end
end
