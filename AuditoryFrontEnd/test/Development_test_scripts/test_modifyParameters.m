% This script tests parameter changes in online scenarios

clear 
close all


% Request and parameters for feature extraction
request = {'ratemap'};
p = genParStruct('fb_nERBs',1/3);

% Online processing parameters
chunkSize = 5000;    % Chunk size in samples

% Parameter to modify
parName = 'fb_bwERBs';  % Name
procIndex = 2;          % Index of the concerned processor in the Processors array
range = [3 0.2];        % Range of values to span in the simulation
steps = 3;              % In how many steps this range should be spanned

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
[s pitch] = mObj.addProcessor({request 'pitch'},p);


%% Processing

% Open a figure
h = figure;
h1 = subplot(3,1,[1 2]);

steps = n_chunks/steps;
parValue = linspace(range(1),range(2),n_chunks/steps);
parVector = [];

% Online processing
tic
for ii = 1:n_chunks
    
    % Read a new chunk of signal
    chunk = data((ii-1)*chunkSize+1:ii*chunkSize);
    
    % Change the parameter
    if mod(ii,steps) == 1
        jj = (ii-1)/steps+1;
        mObj.Processors{procIndex}.modifyParameter(parName,parValue(jj));
    end
    
    % Request processing for the chunk
    mObj.processChunk(chunk,1);
    
    % Accumulate the parameter values in a vector for plotting
    parVector = [parVector parValue(jj)*ones(1,size(s{1}.Data('new'),1))]; %#ok
    
end
toc

% Plot the computed representation
s{1}.plot(h1,genParStruct('bColorbar',0));
xlabel([])

% Plot the parameter's trace
t = 0:1/s{1}.FsHz:(size(s{1}.Data(:),1)-1)/s{1}.FsHz;
% t_par = (0:chunkSize:size(data,1)-1)/fsHz;

h2 = subplot(3,1,3);
plot(t,parVector)
linkaxes([h1 h2],'x')
xlabel('Time (s)','fontsize',12)
ylabel(parName,'fontsize',12,'interpreter','none')
set(gca,'YLim',[0 1.1*max(range)])

dObj.autocorrelation{1}.plot;  
% ylim([0 0.02])
% hold on
dObj.pitch{1}.plot%(h3,'pitch')%,'pitchRange',mObj.Processors{6}.pitchRangeHz,...
                              %   'lagDomain',1);
