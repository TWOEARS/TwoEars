% This script tests the results obtained for online vs. offline processing
% for a given feature

clear 
close all


% Request and parameters for feature extraction
% request = {'modulation'};
request = {'filterbank'};
p = [];
p = genParStruct('ihc_method','fullwave','fb_type','drnl');


% Online processing parameters
chunkSize = 10000;    % Chunk size in samples

%% Signal
% Load a signal
load('AFE_earSignals_16kHz');

% Only mono processing for this test
data = earSignals(:,2);
clear earSignals

% Number of chunks in the signal
n_chunks = ceil(size(data,1)/chunkSize);

% Zero-pad the signal for online vs. offline direct comparison
data = [data;zeros(n_chunks*chunkSize-size(data,1),1)];

%% Manager instantiation

% Create data objects
dObj_off = dataObject(data,fsHz);
dObj_on = dataObject([],fsHz);

% Instantiate managers
mObj_off = manager(dObj_off);
mObj_on = manager(dObj_on);

% Add the request
s_off = mObj_off.addProcessor(request,p);
s_on = mObj_on.addProcessor(request,p);

fprintf(['Online performance of ' Processor.findProcessorFromRequest(request,p) ':\n'])

%% Processing

% Offline processing
tic;mObj_off.processSignal;t_off = toc;

% Online processing
tic
for ii = 1:n_chunks
    
    % Read a new chunk of signal
    chunk = data((ii-1)*chunkSize+1:ii*chunkSize);
    
    % Request processing for the chunk
    mObj_on.processChunk(chunk,1);
    
end
t_on = toc;

%% Results comparison

% Normalized RMS error
RMS = 20*log10(norm(reshape(s_on{1}.Data(:),[],1)-reshape(s_off{1}.Data(:),[],1),2)/norm(reshape(s_off{1}.Data(:),[],1),2));
fprintf('\tNormalized RMS error in offline vs. online processing: %d dB\n',round(RMS))

% Timing
fprintf('\tComputation time for online: %f s (%d%% of signal duration)\n',t_on,round(100*t_on*fsHz/size(data,1)))
fprintf('\tComputation time for offline: %f s (%d%% of signal duration)\n',t_off,round(100*t_off*fsHz/size(data,1)))

% Try and plot the difference
% Try to add your own case to the loop if it is missing
switch s_off{1}.Name

    case {'innerhaircell' 'gammatone' 'onset_strength' 'offset_strength' 'ratemap_magnitude' ...
            'ratemap_power' 'filterbank' 'adaptation'}
        figure,imagesc(20*log10(abs(s_off{1}.Data(:)-s_on{1}.Data(:))+eps).')
        axis xy
        colorbar
        title(['Error for chunk vs signal-based, ' s_off{1}.Name])
        
    otherwise
        fprintf('\tCould not print the online vs. offline data difference\n')
end
