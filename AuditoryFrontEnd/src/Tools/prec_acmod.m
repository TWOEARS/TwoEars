function [ITD,ILD,lagL,lagR,BL,BR,LLARmode,cc]=prec_acmod(x1,x2,Fs,cfHz,maxLag,cc)

% function [ITD,ILD,lagL,lagR,BL,BR,LLARmode,info]=acmod(y,Fs);
%
% Implementation of a precedence effect model to simulate localization 
% dominance using an adaptive, stimulus parameter-based inhibition process
% 
% J. Braasch (2013) J. Acoust. Soc. Am. 134(1): 420-435.
% For section references see paper
%
% (c) 2013, Rensselaer Polytechnic Institute
% contact: jonasbraasch@gmail.com
%
% Modified by Ryan Chungeun Kim for Two!Ears software framework, 2015
%
% INPUT PARAMETERS:
% x1, x2    : binaural input signal, time x frequency domain (after filterbank)
% Fs        : sampling frequency (tested for 48 kHz)
% cfHz      : vector of auditory filterbank centre frequencies (e.g., gammatone filterbank)
% maxLag    : maximum lag for correlation calculation
% cc        : structure to save various internal/intermediate calculation results

% OUTPUT PARAMETERS:
% ITD      = Interaural Time Difference collapsed over time and frequency
% ILD      = Interaural Level Difference collapsed over time and frequency
% lagL     = lag delay for left lag [ms]
% lagR     = lag delay for right lag [ms]
% BL       = left-lag amplitude, relative according to Eq. A5    
% BR       = right-lag amplitude, relative according to Eq. A5    
% LLARmode = Lag-to-Lead Amplitude Ratio mode, see Table 1
%
% dependent functions:
% db2amp.m    =
% anaone.m    =
% de_conv.m   =
% derive.m    =
% ncorr.m     =
% rev_conv.m  =
% PeakRatio.m =
% reconHW.m   =

Fms=Fs./1000; % sampling frequency based on milliseconds

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Monaural preprocessing (Section II.E) ^
% Lag removal (Section II.B)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if nargin==3 % new instance 
if isempty(cc.ac1) % new instance 
%     [yL_LgS,yL_LgL,lagL,BL,midFreq,cc.ac1]=anaoneR(x1,Fs); % left channel
%     [yR_LgS,yR_LgL,lagR,BR,midFreq,cc.ac2]=anaoneR(x2,Fs); % right channel
    [yL_LgS,yL_LgL,lagL,BL,cc.ac1]=prec_anaone(x1, Fs, cfHz, maxLag); % left channel
    [yR_LgS,yR_LgL,lagR,BR,cc.ac2]=prec_anaone(x2, Fs, cfHz, maxLag); % right channel
else
%     [yL_LgS,yL_LgL,lagL,BL,midFreq,cc.ac1]=anaoneR(x1,Fs,cc.ac1); % left channel
%     [yR_LgS,yR_LgL,lagR,BR,midFreq,cc.ac2]=anaoneR(x2,Fs,cc.ac2); % right channel
    [yL_LgS,yL_LgL,lagL,BL,cc.ac1]=prec_anaone(x1, Fs, cfHz, maxLag, cc.ac1); % left channel
    [yR_LgS,yR_LgL,lagR,BR,cc.ac2]=prec_anaone(x2, Fs, cfHz, maxLag, cc.ac2); % right channel

end    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine correct LLAR mode
% Section II.D, Table 1 & Fig. 6
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% if nargin==3 
if isempty(cc.cc1)  % ??
%     cc.cc1=xcorr(sum(yL_LgS),sum(yR_LgS),Fms); % calc ICC ofr LLAR mode 1
%     cc.cc2=xcorr(sum(yL_LgL),sum(yR_LgL),Fms); % calc ICC ofr LLAR mode 2
%     cc.cc3=xcorr(sum(yL_LgS),sum(yR_LgL),Fms); % calc ICC ofr LLAR mode 3
%     cc.cc4=xcorr(sum(yL_LgL),sum(yR_LgS),Fms); % calc ICC ofr LLAR mode 4   
    cc.cc1=calcXCorr(sum(yL_LgS).',sum(yR_LgS).',Fms); % calc ICC ofr LLAR mode 1
    cc.cc2=calcXCorr(sum(yL_LgL).',sum(yR_LgL).',Fms); % calc ICC ofr LLAR mode 2
    cc.cc3=calcXCorr(sum(yL_LgS).',sum(yR_LgL).',Fms); % calc ICC ofr LLAR mode 3
    cc.cc4=calcXCorr(sum(yL_LgL).',sum(yR_LgS).',Fms); % calc ICC ofr LLAR mode 4
    
else 
%     cc.cc1=cc.cc1+xcorr(sum(yL_LgS),sum(yR_LgS),Fms); % calc ICC ofr LLAR mode 1
%     cc.cc2=cc.cc2+xcorr(sum(yL_LgL),sum(yR_LgL),Fms); % calc ICC ofr LLAR mode 2
%     cc.cc3=cc.cc3+xcorr(sum(yL_LgS),sum(yR_LgL),Fms); % calc ICC ofr LLAR mode 3
%     cc.cc4=cc.cc4+xcorr(sum(yL_LgL),sum(yR_LgS),Fms); % calc ICC ofr LLAR mode 4
    cc.cc1=cc.cc1+calcXCorr(sum(yL_LgS).',sum(yR_LgS).',Fms); % calc ICC ofr LLAR mode 1
    cc.cc2=cc.cc2+calcXCorr(sum(yL_LgL).',sum(yR_LgL).',Fms); % calc ICC ofr LLAR mode 2
    cc.cc3=cc.cc3+calcXCorr(sum(yL_LgS).',sum(yR_LgL).',Fms); % calc ICC ofr LLAR mode 3
    cc.cc4=cc.cc4+calcXCorr(sum(yL_LgL).',sum(yR_LgS).',Fms); % calc ICC ofr LLAR mode 4
    
end
% cross-correlation to determine best combination
n1=max(cc.cc1); % calc ICC ofr LLAR mode 1
n2=max(cc.cc2); % calc ICC ofr LLAR mode 2
n3=max(cc.cc3); % calc ICC ofr LLAR mode 3
n4=max(cc.cc4); % calc ICC ofr LLAR mode 4
% Pick LLARmode based on highest coherence
[maxi,LLARmode]=max([n1 n2 n3 n4]);

% asign left and right signals x1/x2 form best LLAR mode
switch LLARmode
    case 1
        x1=yL_LgS;
        x2=yR_LgS;
    case 2
        x1=yL_LgL;
        x2=yR_LgL;
    case 3
        x1=yL_LgS;
        x2=yR_LgL;
    case 4
        x1=yL_LgL;
        x2=yR_LgS;
end % switch

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determination of binaural cues in individual frequency bands
% Section III.A, see Box "CE?in Fig. 9
%
% Note: In this model version we do NOT select LLAR Mode 1 
% automatically if all four correlation values
% differ by less than 0.1 (p. 428)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

windowlength=50.*Fms; % windowlength for temporal steps
steps=ceil(length(x1(1,:))/windowlength); % determine number of steps
h=triang(windowlength); % window for overlap-add method

for n=1:length(cfHz) % loop over all frequency bands
    xL=x1(n,:)';
    xR=x2(n,:)';
%         ICC=xcorr(xL,xR,Fms)'; % interaural cross-correlation
        ICC=calcXCorr(xL,xR,Fms)'; % interaural cross-correlation
        eL=mean(sqrt(xL.^2)); % rms energy in left channel
        eR=mean(sqrt(xR.^2)); % rms energy in right channel
        if eL>0 & eR>0; % if signal in both channels exist
            ILD_f=20*log10(eL./eR); % ILD within frequency band
            En=eL.*eR; % Amplitude
        else 
            ILD_f=0;
            En=0;
        end % of of                    

    % Frequency weighting according to Stern et al. (1988)
    % frequency weighting filter coefficients: b1, b2, b3
    b1=-0.0938272;
    b2=0.000112586;
    b3=-0.0000000399154;
    f=cfHz(n);
    if f<1200
        w=10.^((-b1.*f-b2.*f.^2-b3.*f.^3)./10)./276;
    else
        w=10.^((-b1.*1200-b2.*1200.^2-b3.*1200.^3)./10)./276;
    end % of if 
    ICCintT(n,:)=ICC.*w; % integrate ICC over time with Freq weighting
   % whos
    ILDint(n)=ILD_f.*En./sum(En); % integrated ILD, energy weighted
    Eint(n)=En; % integrated Energy
end % of for 

% if nargin==3 
if isempty(cc.ICCintT) 
    cc.ICCintT=ICCintT;
    cc.ILDint=ILDint;
    cc.Eint=Eint;
else 
    cc.ICCintT=cc.ICCintT+ICCintT;
    cc.ILDint=(cc.ILDint.*cc.Eint+ILDint.*Eint)./(Eint+cc.Eint);
    %cc.ILD=ILDint;
    cc.Eint=Eint+cc.Eint;
end

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determination of binaural cues across frequency bands
% See Section III.A.1. Decision device
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ICCintF=sum(cc.ICCintT); % Detemine ICC collapsed over all frequency bands

% Normalize signal for centroid calculation
ICCintF=ICCintF-min(ICCintF);
index=find(ICCintF<max(ICCintF)./2);
ICCintF(index)=0;

ITD=sum((-Fms:Fms).*ICCintF./sum(ICCintF))./Fms; % ITD estimation based on centroid

[maxCorr,indexITD]=max(ICCintF);
ITD=(indexITD-Fms-1)./Fms;
% ILD calculation amplitude weighted over frequency bands
ILD=sum(cc.ILDint.*cc.Eint)./sum(cc.Eint);

% convert lag delays to ms:
lagL=lagL./Fms;
lagR=lagR./Fms;

