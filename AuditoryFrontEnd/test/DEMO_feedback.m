% DEMO_feedback
%
% This script demonstrates feedback capabilities by computing the ratemap of a pure sine
% wave with an auditory filterbank of filters of increasing bandwidth 

clear;
close all;


% Request and parameters for feature extraction
request = {'ratemap'};
p = [];

% Online processing parameters
chunkSize = 5000;    % Chunk size in samples

% Parameter to modify
parName = 'fb_bwERBs';  % Name
procIndex = 2;          % Index of the concerned processor in the Processors array
range = [1 4];          % Range of values to span in the simulation

% Signal properties
f = 1000;       % Frequency of the pure tone (Hz)
fsHz = 16000;   % Sampling frequency (Hz)
T = 5;          % Duration (s)

%% Signal

% Generate a pure sine wave
t = (0:1/fsHz:T)';
data = 0.5*sin(2*pi*f*t);

% Number of chunks in the signal
n_chunks = floor(size(data,1)/chunkSize);

% Zero-pad the signal for online vs. offline direct comparison
% data = [data;zeros(n_chunks*chunkSize-size(data,1),1)];

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

parValue = linspace(range(1),range(2),n_chunks);

% Online processing

for ii = 1:n_chunks
    
    % Read a new chunk of signal
    chunk = data((ii-1)*chunkSize+1:ii*chunkSize);
    
    % Change the parameter
    mObj.Processors{procIndex}.modifyParameter(parName,parValue(ii));
    
    % Request processing for the chunk
    mObj.processChunk(chunk,1);
    
    % Plot the computed representation
    s{1}.plot(h);
    
end
