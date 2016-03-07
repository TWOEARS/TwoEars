% Test of the Braasch (2013) model
% using a lead/lag pair with configurable ITDs
% at different lag/lead ratios and interstimulus 
% intervals
% both AFE-ported version and the original Braasch's version

% halfwave rectification has been disabled (see flag on Line 37 in anaoneR.m)

% minimum windowlength needs to be in order of binaural sluggishness for
% the model to operate properly (now set to 1024 tabs). Needs sufficient
% length to perform autocorrelation over both lead and lag.

clear

Fs=48000;          % Sampling Frequency [Hz]
ISI=[3];       % Inter-stimulus Interval [ms]
Ratio=[0]; % lead/lag level ratio [dB]
StimDuration=200;  % stimulus duration [ms]

% create test stimulus (binaural)
x = stimulusBraasch(Fs, 2, 400, 500, 800, 0.4, -0.4, 3, 20, 20, 0,db2amp(0));
% usage: STIMULUS(Fs,mode,len,f,bw,itd1,itd2,isi,at,dc)

%% USING AFE
% Create a data object based on parts of the right ear signal
dObj = dataObject(x, Fs);

requests = 'precedence';
fb_lowFreqHz = 100;
fb_highFreqHz = 1400;

prec_wSizeSec = 0.03;
prec_hSizeSec = 0.015;

par = genParStruct('fb_lowFreqHz',fb_lowFreqHz, ...
    'fb_highFreqHz',fb_highFreqHz, ...
    'prec_wSizeSec', prec_wSizeSec, ...
    'prec_hSizeSec', prec_hSizeSec);
 
% Create a manager
mObj = manager(dObj,requests,par);

% Request processing
mObj.processSignal();

figure
subplot(2,1,1)
plot(dObj.precedence{1}.Data(:))
title('accumulated ITD') 
xlabel('iteration steps/# number of analyzed windows')
ylabel('ITD [ms]');

subplot(2,1,2)
plot(dObj.precedence{2}.Data(:))
title('accumulated ILD') 
xlabel('iteration steps/# number of analyzed windows')
ylabel('ILD [dB]');



%% USING JONAS' DEMO

ITD=zeros(length(Ratio),length(ISI));
ILD=zeros(length(Ratio),length(ISI));

windowlength=round(Fs*prec_wSizeSec);
stepsize=floor(windowlength./2);
windowlength=stepsize*2;
% [X1]=OLAsplit(x(:,1),windowlength);
% [X2]=OLAsplit(x(:,2),windowlength);

% Frame calculation - follows the AFE convention (don't add zeros, but
% terminate at the last complete frame)
nFrames = floor((length(x(:,1))-(windowlength-stepsize))/stepsize);

ITD = zeros(nFrames, 1);
ILD = zeros(nFrames, 1);

% Divide signal into windowed chunks (windowlength x nFrames)
for ii = 1:nFrames
    % Get start and end indices for the current frame
    n_start = (ii-1)*stepsize+1;
    n_end = (ii-1)*stepsize+windowlength;

%     % Extract current frame (this will be in time-frequency domain)
%     frame_l = repmat(hanning(pObj.wSize), 1, nChannels) .* in_l(n_start:n_end, :);
%     frame_r = repmat(hanning(pObj.wSize), 1, nChannels) .* in_r(n_start:n_end, :);

    X1(:, ii) = hanning(windowlength) .* x(n_start:n_end, 1);
    X2(:, ii) = hanning(windowlength) .* x(n_start:n_end, 2);

end

for n=1:length(X1(1,:))
    if n==1 % new instance
        [ITD(n),ILD(n),lagL,lagR,BL,BR,LLARmode,cc]=acmodR2(X1(:,n),X2(:,n),Fs);
    else % running window 
        [ITD(n),ILD(n),lagL,lagR,BL,BR,LLARmode,cc]=acmodR2(X1(:,n),X2(:,n),Fs,cc);
    end
end

figure
subplot(2,1,1)
plot(ITD)
title('accumulated ITD') 
xlabel('iteration steps/# number of analyzed windows')
ylabel('ITD [ms]');

subplot(2,1,2)
plot(ILD)
title('accumulated ILD') 
xlabel('iteration steps/# number of analyzed windows')
ylabel('ILD [dB]');





