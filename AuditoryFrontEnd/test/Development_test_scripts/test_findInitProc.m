% This script is for testing the behavior of the findInitProc method of the
% manager class.

% NOTE: The findInitProc method of the manager class has to be made public for this test
% to work. Simply uncomment temporarily the (Access = protected) command that precedes the
% method definition.

clear all
close all
clc

% Load a signal
load('AFE_earSignals_16kHz');

% Original request with default parameters
request = 'crosscorrelation';

% Instantiate data and manager objects
dObj = dataObject(earSignals,fsHz);     % Create a data object based on this signal
mObj = manager(dObj,request);           % Instantiate a manager for the original request
% mObj = manager(dObj);                   % What happens with an empty manager?

% Ask which processor should be taken as a starting point for different
% scenarios (read outputs in command window as well as code):
% 1- We change the frequency resolution of the filterbank
    new_request1 = 'innerhaircell';
    p1 = genParStruct('fb_nERBs',1/3);
%     p1.fb_nERBs = 1/3;
    [init_proc1,list1] = mObj.findInitProc(new_request1,p1);
    fprintf(['Changing the resolution of the filterbank implies recomputing the '...
        'signals \n%s, from the output of the following processor:\n'],strjoin(list1,' and '))
    init_proc1{1}
    
% 2- We request ITDs based on the same original parameter
    new_request2 = 'itd';
    p2 = Parameters;    % Empty parameter object means using default values
    [init_proc2,list2] = mObj.findInitProc(new_request2,p2);
    fprintf(['Computing ITDs with default parameter involves computing only '...
        'the signal \n%s, from the output of the following processor:\n'],strjoin(list2,' and '))
    init_proc2{1}
    
% 3- We request ITDs but using a different window shape
    new_request3 = 'itd';
    p3 = genParStruct('cc_wname','rect');
    [init_proc3,list3] = mObj.findInitProc(new_request3,p3);
    fprintf(['However, ITDs with e.g., a different window shape, requires '...
        'the computation of signals \n%s, from the output of:\n'],strjoin(list3,' and '))
    init_proc3{1}
