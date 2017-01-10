clear
close all
clc


%% CREATE TEST SIGNALS
% 
% 
% sinusoid with onset/offset ramps
% The scripts for the input signals were adopted from MAP1_14h codes
% (Matlab Auditory Periphery, Hearing Research Lab, University of Essex) 
% to potentially test against the MAP implementation
% one or more input frequencies and levels can be tested 
fsHz = 44100;                       % Sampling frequency
toneFrequency= [520 3980];          % Input tone frequency (Hz)
toneDuration = 0.05;                % Duration of the tone (s)
initialSilence = 0.05;              % Initial silence duration (s)
endSilence = 0;                     % Silence duration after the tone part (s)
rampDuration =.0025;                % raised cosine ramp duration (s)
leveldBSPL = 0:10:90;               % Input tone level to be tested (dB SPL)

% AFE online processing chunk size in seconds
chunkSizeSec = 10E-3;

% Calibration factor (see Jepsen et al. 2008)
dBSPLCal = 100;         % signal amplitude 1 should correspond to 100 dB
ampCal = 1;             % signal amplitude to correspond to dBSPLRef
pRef = 2e-5;            % reference sound pressure (p0)
pCal = pRef*10^(dBSPLCal/20);
calibrationFactor = ampCal*10.^((leveldBSPL-dBSPLCal)/20);

% Window position indices in samples over which the output will be calculated
outputWindowStart = round((initialSilence)*fsHz);
outputWindowEnd = round((initialSilence+toneDuration)*fsHz);

% Time indexing
dt = 1/fsHz;                        % seconds
toneTime = dt:dt:toneDuration;      % tone time index
totalTime = dt:dt:initialSilence+toneDuration+endSilence;   
                                    % time index for the whole input signal

% Calculate ramp factor to be multiplied to the input signals
if rampDuration>0.5*toneDuration, rampDuration = toneDuration/2; end
rampTime = dt:dt:rampDuration;
ramp = [0.5*(1+cos(2*pi*rampTime/(2*rampDuration)+pi)) ...
    ones(1,length(toneTime)-length(rampTime))];
ramp_temp = repmat(ramp, [length(leveldBSPL), 1]);  

% derive silence parts to be attached to the tone
intialSilence = zeros(1,round(initialSilence/dt));
finalSilence = zeros(1,round(endSilence/dt));

% Adjusting the input length for online/offline processing comparison,
% depending on the specified chunk size
% AFE online processing chunk size in samples 
chunkSize = fsHz*chunkSizeSec;    
% Number of chunks in the whole signal duration
n_chunks = ceil(length(totalTime)/chunkSize);
% Zero-pad the signal for online vs. offline direct comparison
finalSilence = [finalSilence zeros(1, n_chunks*chunkSize-length(totalTime))];
% Now the lengths of finalSilence section and totalTime have changed
totalTime = (1:length(toneTime)+length(intialSilence)+length(finalSilence))/fsHz;

% Prepare the storage for the input signals (with varying level and tone
% frequency)
inputSignalMatrix = zeros(length(leveldBSPL), ...
    length(totalTime), ...
    length(toneFrequency));

% Generate input signals and store in the input signal matrix
for ii = 1:length(toneFrequency)
    % amplitude -1~+1 -> sqrt(2)
    inputSignal = sin(2*pi*toneFrequency(ii)'*toneTime) .* sqrt(2);      
            % --> RMS OF 1 NOW CORRESPONDS TO 100 dB SPL 
    
    inputSignal = calibrationFactor'*inputSignal;
            % "signal amplitude is scaled in pascals in prior to OME"
    
    % apply ramp
    inputSignal = inputSignal.*ramp_temp;
    ramp_temp = fliplr(ramp_temp);
    inputSignal = inputSignal.*ramp_temp;
    % add initial/final silence
    inputSignal = [repmat(intialSilence, [length(leveldBSPL), 1]) ...
        inputSignal repmat(finalSilence, [length(leveldBSPL), 1])]; 
    % store into the input signal matrix
    inputSignalMatrix(:, :, ii) = inputSignal;
end


%% OUTPUT PREPARATION

% matrix to store output (I/O function)
ioFunctionMatrix = zeros(length(toneFrequency), length(leveldBSPL));
ioFunctionMatrix_moc = zeros(length(toneFrequency), length(leveldBSPL));

% (MOC activity-level function)
mocLevelFunctionMatrix = zeros(length(toneFrequency), length(leveldBSPL));


%% PLACE REQUEST AND CONTROL PARAMETERS

request = 'ratemap';
request_moc = 'moc';

% Parameters of pre-processing
pp_bLevelScaling = true;
pp_bMiddleEarFiltering = true;

% Parameters of auditory filterbank 
fb_type = 'drnl';
fb_cfHz = toneFrequency;

% Parameters of ratemap 
rm_wSizeSec = 20E-3;
rm_hSizeSec = 10E-3;
rm_decaySec = 8E-3;

% Number of ratemap frames in the input signal
nFrames = floor((length(totalTime)-(rm_wSizeSec*fsHz - round(rm_hSizeSec*fsHz)))/round(rm_hSizeSec*fsHz));

% Introduce outer ear filter (imported from AMT, in src/Tools folder)
oe_fir = headphonefilter(fsHz);

% Perform processing and save output
for jj=1:length(toneFrequency)

    % Filter input through outer ear filter
    xME = filter(oe_fir, 1, inputSignalMatrix(:, :, jj).');

    % parameter structure for testing on-freq stimulation
    param_struct = genParStruct('pp_bLevelScaling', pp_bLevelScaling, ...
        'pp_bMiddleEarFiltering', pp_bMiddleEarFiltering, ...
        'fb_type', fb_type, 'fb_cfHz', fb_cfHz(jj));
    param_struct_moc = genParStruct('pp_bLevelScaling', pp_bLevelScaling, ...
        'pp_bMiddleEarFiltering', pp_bMiddleEarFiltering, ...
        'fb_type', fb_type, 'fb_cfHz', fb_cfHz(jj), ...
        'rm_wSizeSec', rm_wSizeSec, 'rm_hSizeSec', rm_hSizeSec, ...
        'rm_decaySec', rm_decaySec);

    %% PERFORM PROCESSING
    
    for kk=1:length(leveldBSPL)
        dObj = dataObject(xME(:, kk), fsHz);
        dObj_moc = dataObject([], fsHz);

        mObj = manager(dObj, request, param_struct);
        mObj_moc = manager(dObj_moc, request_moc, param_struct_moc);

        mObj.processSignal();

        % MOC processor will work only in online (chunk-based) mode
        for nn = 1:n_chunks

            % Read a new chunk of signal
            chunk = xME((nn-1)*chunkSize+1:nn*chunkSize, kk);

            % Request processing for the chunk
            mObj_moc.processChunk(chunk,1);

        end

       %% SAVE OUTPUT
        
        % DRNL output
        bmOut = dObj.filterbank{1}.Data(:);
        bmOutRMSdB = 20*log10(rms(bmOut(outputWindowStart:outputWindowEnd)));

        % DRNL output, with MOC working
        bmOut_moc = dObj_moc.filterbank{1}.Data(:);
        bmOutRMSdB_moc = 20*log10(rms(bmOut_moc(outputWindowStart:outputWindowEnd)));

        % MOC maximum output
        mocOut = dObj_moc.moc{1}.Data(:);
        mocOutMax = max(mocOut);

        % Input vs DRNL RMS output
        ioFunctionMatrix(jj, kk) = bmOutRMSdB;
        ioFunctionMatrix_moc(jj, kk) = bmOutRMSdB_moc;

        % Input vs MOC attenuation output
        mocLevelFunctionMatrix(jj, kk) = mocOutMax;

        % Plot output example with/without MOC for a single input for comparison
        % example
        if jj==1 && kk==5 
            figure;
            plot(totalTime, 1E3*dObj_moc.input{1}.Data(:));
            xlabel('Time (s)');
            ylabel('Amplitude (x 1E$^{-3}$)');
            title(sprintf('Input signal, %ddB SPL, %dHz', leveldBSPL(kk), toneFrequency(jj)));
            figure;
            plot(totalTime, 1E3*bmOut_moc);
            xlabel('Time (s)');
            ylabel('Amplitude (x 1E$^{-3}$)');
            title('DRNL output with reflexive MOC feedback');
        end

    end
    clear xME param_struct param_struct_moc dObj dObj_moc mObj mObj_moc
end

%% PLOT RESULTS

% DRNL filterbank input-output characteristics, without MOC processor
figure;
set(gcf,'DefaultAxesColorOrder',[0 0 0], ...
    'DefaultAxesLineStyleOrder','-o|--s|:x|-.*');
plot(leveldBSPL, ioFunctionMatrix);
grid on
xlabel('Input tone level (dB SPL)');
ylabel('DRNL output (dB re 1 m/s)');
title(sprintf('Input-output characteristics of  DRNL filterbank\non-frequency stimulation, RMS over tone duration'));
legendCell=cellstr(num2str(toneFrequency', '%-dHz'));
legend(legendCell, 'Location', 'NorthWest'); legend('boxoff');

% DRNL filterbank input-output characteristics, with MOC processor
figure;
set(gcf,'DefaultAxesColorOrder',[0 0 0], ...
    'DefaultAxesLineStyleOrder','-o|--s|:x|-.*');
plot(leveldBSPL, ioFunctionMatrix_moc);
grid on
xlabel('Input tone level (dB SPL)');
ylabel('DRNL output (dB re 1 m/s)');
title(sprintf('Input-output characteristics of  DRNL filterbank with MOC feedback\non-frequency stimulation, RMS over tone duration'));
legendCell=cellstr(num2str(toneFrequency', '%-dHz'));
legend(legendCell, 'Location', 'NorthWest'); legend('boxoff');

% Plotting input tone level - MOC attenuation output characteristics, 
% compared against the data of Liberman 1988
% Liberman data, NOTE: scaled to MOC attenuation in Clark et al. 2012!!
libermanMOCdata_520Hz = [0 0 0 5 18.5 29.5 36 38 39 37];       
libermanMOCdata_3980Hz = [0 0 0 10 17.5 24 30 34 37 38];

figure;
set(gcf,'DefaultAxesColorOrder',[0 0 0], ...
    'DefaultAxesLineStyleOrder','-o|-s|:o|:s');
plot(leveldBSPL, mocLevelFunctionMatrix, leveldBSPL, libermanMOCdata_520Hz, leveldBSPL, libermanMOCdata_3980Hz);
grid on
xlabel('Input tone level (dB SPL)');
ylabel('Maximum MOC activity (dB)');
title(sprintf('Input-output characteristics of mocProc'));
legendCell=[cellstr(num2str(toneFrequency', '%-dHz')); ...
    cellstr(num2str(toneFrequency', 'Liberman %-dHz'))];
legend(legendCell, 'Location', 'SouthEast', 'FontSize', 10);
legend('boxoff');


