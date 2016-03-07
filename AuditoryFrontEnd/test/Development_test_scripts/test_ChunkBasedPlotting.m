% This script tests the block-based ploting routine.
% Block-based plotting is done simply by recalling the plot routine at each block. It is
% very inefficient, and this script is at the moment only a place-holder. "Real" testing
% will be conducted if/when new plotting methods are devised for "real-time" plotting of
% signals (e.g., routines that would not involve recomputing all axes properties)

clear 
close all


% Request and parameters for feature extraction
request = {'ratemap'};
p = [];

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
dObj = dataObject([],fsHz,10,1);

% Instantiate managers
mObj = manager(dObj);

% Add the request
s = mObj.addProcessor(request,p);


%% Processing

% Open a figure
h = figure;

% Online processing

for ii = 1:n_chunks
    
    % Read a new chunk of signal
    chunk = data((ii-1)*chunkSize+1:ii*chunkSize);
    
    % Request processing for the chunk
    mObj.processChunk(chunk,1);
    
    % Plot the computed representation
    s{1}.plot(h);
    
end
