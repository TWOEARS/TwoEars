clear;
close all;

% This script illustrates the chunk-based compatibility of the AFE framework with 
% arbitrary chunk size.
% It goes along the description in section 2.4 of the user manual (Deliverable 2.2)

% Loading a signal
load('Test_signals/AFE_earSignals_16kHz');
sIn = earSignals;
clear earSignals

L = size(sIn,1);    % Number of samples in the input signal
request = 'innerhaircell';


% Boundaries for arbitrary chunk size
chunkSizeMin = 100;
chunkSizeMax = 20000;

% Instantiation of data and manager objects
dataObj = dataObject([],fsHz,10,2);
managerObj = manager(dataObj);

% Place a request
sOut = managerObj.addProcessor(request);

% Initialize current chunk indexes
chunkStart = 0;
chunkStop = 0;

% Simulate a chunk-based aquisition of the input
while chunkStop < L
    
    % Generate new chunk boundaries
    chunkStart = chunkStop + 1;
    chunkStop = chunkStart + chunkSizeMin + ...
                randsample(chunkSizeMax-chunkSizeMin,1);
            
    % Limit the end of the chunk to the end of the signal
    chunkStop = min(chunkStop,L);
            
    % Request the processing of the chunk
    managerObj.processChunk(sIn(chunkStart:chunkStop,:),1);
    
end


% Comparison with offline processing
dataObjOff = dataObject(sIn,fsHz,10);
managerObjOff = manager(dataObjOff);
sOutOff = managerObjOff.addProcessor(request);
managerObjOff.processSignal;

% Plot the difference between the two representations
figure,imagesc((sOut{1}.Data(:)-sOutOff{1}.Data(:)).'),colorbar
axis xy
xlabel('# frames','fontname','Times','fontsize',15)
ylabel('# channels','fontname','Times','fontsize',15)
title(['Difference in ' request ' between online and offline processing'],...
        'FontName','Times','fontsize',15)
set(gca,'fontname','Times','fontsize',14)

