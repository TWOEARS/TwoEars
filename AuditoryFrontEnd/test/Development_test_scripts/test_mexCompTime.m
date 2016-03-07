% This script reports the differences in computation time when using mex files or not (for framing only at the moment).

clear all
close all


% Load a signal
load('AFE_earSignals_16kHz');

% Parameters
request = 'ratemap';
% N.B: The requests affected by framing (hence use of mex) are ratemaps,
% auto- and cross-correlation.

request_ref = 'innerhaircell';    % Will remove computation time of dependent representation

% Create two identical data objects
dObj1 = dataObject(earSignals,fsHz);
dObj2 = dataObject(earSignals,fsHz);

% Plus a third as a reference
dObj_ref = dataObject(earSignals,fsHz);

% Create empty manager (with mex)
mObj_mex = manager(dObj1);
mObj_nomex = manager(dObj2,[],[],0);

% Create reference manager 
mObj_ref = manager(dObj_ref);

% Add the request
mObj_mex.addProcessor(request);
mObj_nomex.addProcessor(request);
mObj_ref.addProcessor(request_ref);

% Request and time processing
tic;
mObj_mex.processSignal;
t_mex = toc;
tic;
mObj_nomex.processSignal;
t_nomex = toc;
tic;
mObj_ref.processSignal;
t_ref = toc;

fprintf('Elapsed time (approximate) for computation of %s: %fs (with mex), %fs (without mex).\n',request,t_mex-t_ref,t_nomex-t_ref)

% Check that both representations are similar
m = max(max(max(abs(dObj1.(request){1,1}.Data(:)-dObj2.(request){1,1}.Data(:)))));

fprintf('Maximum absolute sample-by-sample difference: %f\n',m)
