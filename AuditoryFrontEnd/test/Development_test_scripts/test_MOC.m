clear all
close all
clc

%% CREATE TEST SIGNALS
% sinusoid with some onset/offset ramps
% adopted from MAP1_14h test codes to potentially test against the MAP
% implementation
fsHz = 44100;             
toneFrequency= [520 3980];          % (Hz)
toneDuration = 0.05;                % 
beginSilence=0.05;
endSilence=0;
rampDuration=.0025;                 % raised cosine ramp (seconds)
leveldBSPL= 0:10:90;   

% calibration factor (see Jepsen et al. 2008)
dBSPLCal = 100;         % signal amplitude 1 should correspond to max SPL 100 dB
ampCal = 1;             % signal amplitude to correspond to dBSPLRef
pRef = 2e-5;            % reference sound pressure (p0)
pCal = pRef*10^(dBSPLCal/20);
calibrationFactor = ampCal*10.^((leveldBSPL-dBSPLCal)/20);
levelPressure = pRef*10.^(leveldBSPL/20);

% define 20-ms onset sample after ramp completed 
%  allowing 5-ms response delay
onsetPTR1=round((rampDuration+ beginSilence +0.005)*fsHz);
onsetPTR2=round((rampDuration+ beginSilence +0.005 + 0.020)*fsHz);
% last half 
lastHalfPTR1=round((beginSilence+toneDuration/2)*fsHz);
lastHalfPTR2=round((beginSilence+toneDuration-rampDuration)*fsHz);
% output window
outputWindowStart = round((beginSilence)*fsHz);
outputWindowEnd = round((beginSilence+toneDuration)*fsHz);

dt = 1/fsHz; % seconds
toneTime = dt: dt: toneDuration;
totalTime = dt:dt:beginSilence+toneDuration+endSilence;

% calculate ramp factor
if rampDuration>0.5*toneDuration, rampDuration=toneDuration/2; end
rampTime=dt:dt:rampDuration;
ramp=[0.5*(1+cos(2*pi*rampTime/(2*rampDuration)+pi)) ...
    ones(1,length(toneTime)-length(rampTime))];
ramp_temp = repmat(ramp, [length(leveldBSPL), 1]);  % to be multiplied to inputSignal

% derive silence parts
intialSilence= zeros(1,round(beginSilence/dt));
finalSilence= zeros(1,round(endSilence/dt));

% Online processing parameters
% Chunk size in samples (for online processing)
chunkSize = fsHz * 10E-3;    

% Number of chunks in the signal - use inputSignal to calculate the signal
% length
n_chunks = ceil(length(totalTime)/chunkSize);

% Zero-pad the signal for online vs. offline direct comparison
finalSilence = [finalSilence zeros(1, n_chunks*chunkSize-length(totalTime))];
% Now the lengths of finalSilence section and totalTime have changed
totalTime = (1:length(toneTime)+length(intialSilence)+length(finalSilence))/fsHz;

inputSignalMatrix = zeros(length(leveldBSPL), ...
    length(totalTime), ...
    length(toneFrequency));

for ii=1:length(toneFrequency)
    inputSignal=sin(2*pi*toneFrequency(ii)'*toneTime) .* sqrt(2);      % amplitude -1~+1 -> sqrt(2)
    % "input amplitude of 1 corresponds to a maximum SPL of 100 dB"
    % --> RMS OF 1 NOW CORRESPONDS TO 100 dB SPL! 
    % calibration: calculate difference between input level dB SPL and the
    % given SPL for calibration (100 dB)
    inputSignal = calibrationFactor'*inputSignal;
    % "signal amplitude is scaled in pascals in prior to OME"
    
    % apply ramp
    inputSignal=inputSignal.*ramp_temp;
    ramp_temp=fliplr(ramp_temp);
    inputSignal=inputSignal.*ramp_temp;
    % add silence
    inputSignal= [repmat(intialSilence, [length(leveldBSPL), 1]) ...
        inputSignal repmat(finalSilence, [length(leveldBSPL), 1])]; 
    
    % Obtain the dboffset currently used
    dboffset=dbspl(1);

    % Switch signal to the correct scaling
    inputSignal=gaindb(inputSignal, dboffset-100);
    
    inputSignalMatrix(:, :, ii) = inputSignal;
end


%% OUTPUT PREPARATION

% matrix to store output (I/O function)
ioFunctionMatrix = zeros(length(toneFrequency), length(leveldBSPL));
ioFunctionMatrix_moc = zeros(length(toneFrequency), length(leveldBSPL));

% (AN firing rate-level function)
rateLevelFunctionMatrix = zeros(length(toneFrequency), length(leveldBSPL));

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
        bmOutMax = max(bmOut);
        bmOutMaxdB = 20*log10(bmOutMax);
        bmOutRMSdB = 20*log10(rms(bmOut(outputWindowStart:outputWindowEnd)));

        % ratemap output
        anOut = dObj.ratemap{1}.Data(:);
        anOutMax = max(anOut);
        anOutMaxdB = 20*log10(anOutMax);

        % DRNL output, with MOC working
        bmOut_moc = dObj_moc.filterbank{1}.Data(:);
        bmOutMax_moc = max(bmOut_moc);
        bmOutMaxdB_moc = 20*log10(bmOutMax_moc);
        bmOutRMSdB_moc = 20*log10(rms(bmOut_moc(outputWindowStart:outputWindowEnd)));

        % ratemap maximum output, with MOC working
        anOut_moc = dObj_moc.ratemap{1}.Data(:);
        anOutMax_moc = max(anOut_moc);
        anOutMaxdB_moc = 20*log10(anOutMax_moc);

        % MOC maximum output
        mocOut = dObj_moc.moc{1}.Data(:);
        mocOutMax = max(mocOut);

        % Input vs DRNL maximum output
        ioFunctionMatrix(jj, kk) = bmOutRMSdB;
        ioFunctionMatrix_moc(jj, kk) = bmOutRMSdB_moc;

        % Input vs ratemap maximum output
        rateLevelFunctionMatrix(jj, kk) = anOutMaxdB;

        % Input vs MOC attenuation output
        mocLevelFunctionMatrix(jj, kk) = mocOutMax;

        % Plot output with/without MOC for a single input for comparison
        % example
        if jj==1 && kk==5 
            subplot(2,1,1);
            plot(totalTime, dObj_moc.input{1}.Data(:));
            ylabel('Amplitude');
            title('Input signal');
            subplot(2,1,2);
            plot(totalTime, bmOut_moc);
            xlabel('Time (s)');
            ylabel('Amplitude');
            title('DRNL output with reflexive MOC feedback');
%             figure; plot(bmOut);
%             figure; plot(bmOut_moc);
%             figure; plot(anOut);
%             figure; plot(anOut_moc);
%             figure; plot(mocOut);
        end

    end
    clear xME param_struct param_struct_moc dObj dObj_moc mObj mObj_moc
end

%% PLOT RESULTS

figure;
set(gcf,'DefaultAxesColorOrder',[0 0 0], ...
    'DefaultAxesLineStyleOrder','-o|--s|:x|-.*');
plot(leveldBSPL, ioFunctionMatrix);
grid on
xlabel('Input tone level (dB SPL)');
ylabel('DRNL output (dB re 1 m/s)');
title(sprintf('Input-output characteristics of  DRNL filterbank\non-frequency stimulation, RMS over tone duration'));
legendCell=cellstr(num2str(toneFrequency', '%-dHz'));
legend(legendCell, 'Location', 'NorthWest');


figure;
set(gcf,'DefaultAxesColorOrder',[0 0 0], ...
    'DefaultAxesLineStyleOrder','-o|--s|:x|-.*');
plot(leveldBSPL, ioFunctionMatrix_moc);
grid on
xlabel('Input tone level (dB SPL)');
ylabel('DRNL output (dB re 1 m/s)');
title(sprintf('Input-output characteristics of  DRNL filterbank with MOC feedback\non-frequency stimulation, RMS over tone duration'));
legendCell=cellstr(num2str(toneFrequency', '%-dHz'));
legend(legendCell, 'Location', 'NorthWest');


libermanMOCdata_520Hz = [0 0 0 5 18.5 29.5 36 38 39 37];       % scaled to MOC attenuation in Clark et al. 2012!!
libermanMOCdata_3980Hz = [0 0 0 10 17.5 24 30 34 37 38];

figure;
set(gcf,'DefaultAxesColorOrder',[0 0 0], ...
    'DefaultAxesLineStyleOrder','-o|-s|:x|:*');
plot(leveldBSPL, mocLevelFunctionMatrix, leveldBSPL, libermanMOCdata_520Hz, leveldBSPL, libermanMOCdata_3980Hz);
grid on
xlabel('Input tone level (dB SPL)');
ylabel('Maximum MOC activity (dB)');
title(sprintf('Input-output characteristics of MOC processor (on-frequency stimulation)\nRelationship derived by curve fitting to Liberman-Clark data'));
legendCell=[cellstr(num2str(toneFrequency', '%-dHz')); ...
    cellstr(num2str(toneFrequency', '%-dHz Liberman data'))];
legend(legendCell, 'Location', 'NorthWest', 'FontSize', 10);


