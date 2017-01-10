clear
close all
clc


%% LOAD SIGNAL
% 
% 
% Sampling frequency in Hertz
fsHz = 44.1E3;

% Create centered impulse 
dObj = dataObject([zeros(1024,1); 1; zeros(7167,1)],fsHz);


%% PLACE REQUEST AND CONTROL PARAMETERS
% 
% 
% Request gammatone processor
requests = {'filterbank'};

% Parameters of auditory filterbank 
fb_type       = 'gammatone';
fb_nChannels  = 64;  
fb_lowFreqHz  = 50;
fb_highFreqHz = fsHz / 2;
fb_bAlign_1   = false;   % without phase-alignment
fb_bAlign_2   = true;    % with phase-alignment

% Summary of parameters 
par1 = genParStruct('fb_type',fb_type,'fb_lowFreqHz',fb_lowFreqHz,...
                    'fb_highFreqHz',fb_highFreqHz,...
                    'fb_nChannels',fb_nChannels,'fb_bAlign',fb_bAlign_1);
par2 = genParStruct('fb_type',fb_type,'fb_lowFreqHz',fb_lowFreqHz,...
                    'fb_highFreqHz',fb_highFreqHz,...
                    'fb_nChannels',fb_nChannels,'fb_bAlign',fb_bAlign_2);                
                   

%% PERFORM PROCESSING
% 
% 
% Create a manager
mObj1 = manager(dObj,requests,par1);
mObj2 = manager(dObj,requests,par2);

% Request processing
mObj1.processSignal();
mObj2.processSignal();


%% DELAY COMPENSATION
% 
% 
% Get subband signals
subband1 = dObj.filterbank{1}.Data(:);
subband2 = dObj.filterbank{2}.Data(:);

% Allocate signals
aligned1 = zeros(size(subband1));
aligned2 = zeros(size(subband2));

% Get delay in samples
delay = round(mObj1.Processors{2}.delaySec * fsHz);

% Loop over number of subbands and compensate for integer delays
for ii = 1 : numel(delay)
    aligned1(:,ii) = circshift(subband1(:,ii),[max(delay) - delay(ii) 1]);
    aligned2(:,ii) = circshift(subband2(:,ii),[max(delay) - delay(ii) 1]);
end

% Reconstruct input by integrating subband signals across frequency 
out1 = sum(aligned1,2);
out2 = sum(aligned2,2);

% Delay input
input = circshift(dObj.input{1}.Data(:),[max(delay) 1]);


%% GAIN COMPENSATION
% 
% 
% Center frequencies in Hertz 
cfHz = dObj.filterbank{1}.cfHz;

% Dimension of input
nSamples = numel(dObj.input{1}.Data(:));

% Identify FFT bins which correspond to the center frequencies
cfFFTIdx = round(cfHz * nSamples / fsHz);

% Spectral analysis of aligned gammatone output
specAligned = fft(aligned2,[],1);

% Initialize gain factors
gain = ones(numel(cfHz),1);

% Number of iterations
nIterations = 100;

% Loop over the number of iterations
for ii = 1:nIterations
    
    % Select FFT bins
    specAlignedSelected = specAligned(cfFFTIdx,:);
        
    % Apply gain factors
    specAlignedSelected = specAlignedSelected * gain;
    
    % Calculate better gain factors 
    gain = gain ./ abs(specAlignedSelected);
end

% Apply gain factors to subband signals
out3 = aligned2 * gain;


%% SHOW RESULTS
% 
% 
% Plot-related parameters
wavPlotZoom = 5; % Zoom factor
wavPlotDS   = 3; % Down-sampling factor

% Time vector
timeSec = (0:size(subband1,1)-1)/fsHz;

% Plot filterbank output
figure; 
waveplot(subband1,timeSec,dObj.filterbank{1}.cfHz,wavPlotZoom,wavPlotDS);
title('Output (without phase compensation)')
xlim([0 0.08])

figure; 
waveplot(subband2,timeSec,dObj.filterbank{1}.cfHz,wavPlotZoom,wavPlotDS);
title('Output (with phase compensation)')
xlim([0 0.08])

% Plot delay-compensated filterbank output
figure; 
waveplot(aligned1,timeSec,dObj.filterbank{1}.cfHz,wavPlotZoom,wavPlotDS);
title('Delay-compensated output (without phase compensation)')
xlim([0 0.08])

figure; 
waveplot(aligned2,timeSec,dObj.filterbank{1}.cfHz,wavPlotZoom,wavPlotDS);
title('Delay-compensated output (with phase compensation)')
xlim([0 0.08])

% Stack data that should be plotted
data2plot = cat(2,input,out1,out2,out3);

% Create colormap
cmap = colormapVoicebox(size(data2plot,2));

% Reconstructed impulse
figure;
h = plot(timeSec,data2plot);
for ii = 1 : numel(h)
    set(h(ii),'linewidth',1.5,'color',cmap(ii,:))
end
grid on;
h = legend({'input' 'output' 'output with phase compensation' 'output with phase and gain compensation'},'Location','SouthWest');
set(h,'box','off');
xlim([0.0382 0.0394])
xlabel('Time (s)')
ylabel('Amplitude')

% RMS reconstruction error in dB
errordB_OUT = 20*log10(sqrt(mean((input-out1).^2)))
errordB_PHASE = 20*log10(sqrt(mean((input-out2).^2)))
errordB_PHASEandGAIN = 20*log10(sqrt(mean((input-out3).^2)))

% FFT size
nfft = pow2(nextpow2(nSamples));

% Spectral analysis
spec1 = fft(input,nfft,1);
spec2 = fft(aligned1,nfft,1);
spec3 = fft(aligned2,nfft,1);
spec4 = fft(aligned2 .* repmat(gain(:)',[size(aligned1,1) 1]),nfft,1);

freqHz = (0:nfft-1)'/(nfft) * fsHz;

% Stack data that should be plotted
data2plot = cat(2,sum(spec1,2),sum(spec2,2),sum(spec3,2),sum(spec4,2));

figure;
h = semilogx(freqHz,20*log10(abs(data2plot)));
for ii = 1 : numel(h)
    set(h(ii),'linewidth',1.5,'color',cmap(ii,:))
end
grid on;
set(gca,'xscale','log');
set(gca,'xticklabel',num2str([10 100 1000 10000]'));
xlim([10 fsHz/2]);
xlabel('Frequency (Hz)')
ylabel('Response (dB)')
h = legend({'input' 'output' 'output with phase compensation' ...
    'output with phase and gain compensation'},'Location','SouthEast');
set(h,'box','off');

