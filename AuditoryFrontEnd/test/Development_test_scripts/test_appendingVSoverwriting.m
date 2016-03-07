% This scripts compares appending and replacing data when processing signals in chunks

clear all
close all


% Load a signal
load('AFE_earSignals_16kHz');

% Parameters
request = 'ild';
chunkSize = 0.5*fsHz;   % Chunk duration in samples

% Use both ear signals
data = earSignals;

% Create an empty data object. It will be filled up as new ear signal
% chunks are "acquired". 
dObj = dataObject([],fsHz,10,2);     % Last input (2) indicates a stereo signal
mObj = manager(dObj,request);     % Instantiate a manager

% Create an additional data object and manager, for comparison purpose
dObj2 = dataObject([],fsHz,10,2);     % Last input (2) indicates a stereo signal
mObj2 = manager(dObj2,request);     % Instantiate a manager

% From here on, simulating real-time chunk acquisition and processing
% request...

% Number of chunks in the signal
n_chunks = ceil(size(data,1)/chunkSize);

% Zero-pad the signal to an integer number of chunks (use for later
% comparison with signal-based processing)
data = [data;zeros(n_chunks*chunkSize-size(data,1),size(data,2))];

% Loop on all the chunks
for ii = 1:n_chunks
    
    % Read signal chunk
    chunk = data((ii-1)*chunkSize+1:ii*chunkSize,:);
    
    % Request processing for that chunk...
    
    %... and append the output to existing one
    mObj.processChunk(chunk,1);
    
    %... or overwrite the existing output
    mObj2.processChunk(chunk); % Same as "mObj.processChunk(chunk,0);" 
    
    % Display the number of frames in the output
    fprintf('Time-frames in the output: %i (appending), %i (overwriting)\n',...
        size(dObj.ild{1}.Data(:),1),size(dObj2.ild{1}.Data(:),1))
    
    
end




