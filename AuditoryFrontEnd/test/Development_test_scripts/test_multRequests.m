% This script demonstrates the different approaches to requesting multiple
% representations at a time in the Two!Ears Auditory Front-End processing framework.

clear all
close all
clc


% Which demo(s) to run:
demo = [1:4];

% Load a signal
load('AFE_earSignals_16kHz');

% data = earSignals(:,2);     % Take channel with higher energy
data = earSignals;
fs = fsHz;
clear earSignals fsHz

%% 1-Multiple requests at instantiation, all with default parameters
% Only a cell array of requests is provided

if ismember(1,demo)
    
% requests = {'ild','itd_xcorr','ratemap'};
requests = {'ild' 'itd' 'ic'};
% requests = {'ic_xcorr'}

% Create a data object
dObj = dataObject(data,fs);

% Create a manager
mObj = manager(dObj,requests);

% Request processing
mObj.processSignal();

% Plot the results
h1 = dObj.ild{1}.plot;
h2 = dObj.itd{1}.plot;
h3 = dObj.ic{1}.plot;

% Position the figures
set(h1,'Units','normalized','Position',[0.1 0.1 0.25 0.3])
set(h2,'Units','normalized','Position',[0.4 0.1 0.25 0.3])
set(h3,'Units','normalized','Position',[0.7 0.1 0.25 0.3])

disp('Test 1: Multiple requests having default parameter')
pause

close all

end

%% 2-Multiple requests at instantiation all with same, non-default, parameters
% Provide cell array of requests as well as a single parameter structure

if ismember(2,demo)

requests = {'ild','itd','ratemap'};
p =genParStruct('fb_nERBs',3);

% Create a data object
dObj = dataObject(data,fs);

% Create a manager
mObj = manager(dObj,requests,p);

% Request processing
mObj.processSignal

% Plot the results
h1 = dObj.ild{1}.plot;
h2 = dObj.itd{1}.plot;
h3 = dObj.ratemap{1}.plot;

% Position the figures
set(h1,'Units','normalized','Position',[0.1 0.1 0.25 0.3])
set(h2,'Units','normalized','Position',[0.4 0.1 0.25 0.3])
set(h3,'Units','normalized','Position',[0.7 0.1 0.25 0.3])

disp('Test 2: Multiple requests having same non-default parameter')
pause

close all

end

%% 3-Multiple requests at instantiation with different individual parameters
% Provide cell array of requests and cell array of parameter structures of
% same dimensions

if ismember(3,demo)
    
requests = {'ild','itd','ratemap'};
p1 = genParStruct();            % Default parameters
p2 = genParStruct('fb_nERBs',3);   % Lower filterbank resolution
p3 = genParStruct('fb_nERBs',1/2); % Higher filterbank resolution

% Create a data object
dObj = dataObject(data,fs);

% Create a manager
mObj = manager(dObj,requests,{p1,p2,p3});

% Request processing
mObj.processSignal

% Plot the results
h1 = dObj.ild{1}.plot;
h2 = dObj.itd{1}.plot;
h3 = dObj.ratemap{1}.plot;

% Position the figures
set(h1,'Units','normalized','Position',[0.1 0.1 0.25 0.3])
set(h2,'Units','normalized','Position',[0.4 0.1 0.25 0.3])
set(h3,'Units','normalized','Position',[0.7 0.1 0.25 0.3])

disp('Test 3: Multiple requests having individual parameters')

% An error is generated if the cell array of parameters does not match the
% request array
disp('  If the array of parameter does not match the request array, an error is generated:')
try 
    mObj_fail = manager(dObj,requests,{p1,p2});
catch err
    disp('    !!This is a non execution-interupting error message!!')
end

pause 
close all
    
end

%% 4-Multiple requests with different individual parameters using the addProcessor method
% Provide cell array of requests and cell array of parameter structures of
% same dimensions to the addProcessor() method of the manager.

% The advantage is that the method returns handles to the requested signals
% (impossible through the manager constructor).

if ismember(4,demo)
    
requests = {'ild','itd','ratemap'};
p1 = genParStruct();            % Default parameters
p2 = genParStruct('fb_nERBs',3);   % Lower filterbank resolution
p3 = genParStruct('fb_nERBs',1/2); % Higher filterbank resolution
p = {p1,p2,p3};

% Create a data object
dObj = dataObject(data,fs);

% Create an empty manager
mObj = manager(dObj);

% Add the requests
[out1,out2,out3] = mObj.addProcessor(requests,p);

% Request processing
mObj.processSignal

% Plot the results from the provided signal handles
h1 = out1{1}.plot;
h2 = out2{1}.plot;
h3 = out3{1}.plot;  % out3 is a ratemap, hence it is a cell array with left and right channels

% Position the figures
set(h1,'Units','normalized','Position',[0.1 0.1 0.25 0.3])
set(h2,'Units','normalized','Position',[0.4 0.1 0.25 0.3])
set(h3,'Units','normalized','Position',[0.7 0.1 0.25 0.3])

disp('Test 4: Multiple requests having individual parameters')


% pause 
    
end






