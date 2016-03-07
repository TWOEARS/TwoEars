% This is a test script to investigate Matlab's event-based programming, for use with
% inter-processors communication in the event of feedback

% To see which processors are updating, uncomment the displaying of a message to the 
% command window in the Processor.update method.

clear all
close all


% Load a signal
load('AFE_earSignals_16kHz');
data = earSignals(:,2);     % Right channel has higher energy

% Parameters
request = {'ratemap'};
p = [];

% Create a data object
dObj = dataObject(data,fsHz);

% Create empty manager
mObj = manager(dObj);

% Add the request
sOut = mObj.addProcessor(request,p);

% Modify a parameter
fprintf('\n')
disp('Modifying the pre-processor should trigger a reset for all dependent processor:')
mObj.Processors{1}.modifyParameter('pp_bNormalizeRMS',0)

fprintf('\n')
disp('Modifying the inner hair-cell processor should only trigger processors depending on it:')
mObj.Processors{3}.modifyParameter('ihc_method','hilbert')