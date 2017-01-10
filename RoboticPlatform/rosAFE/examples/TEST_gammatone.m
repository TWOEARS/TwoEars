%%
clear all; close all; clc;
%%
[ bass, rosAFE ] = initRosAFE();

%% Acquiring Audio
acquireAudio();

%% Ading processors
inputName = 'input';
thisProc = rosAFE.InputProc('-a', inputName, 12000, bufferSize_s_rosAFE_port, bufferSize_s_rosAFE_getSignal );
pause(p);

preProcName = 'preProc';
preProcProc = rosAFE.PreProc('-a', preProcName, inputName, 0, ... % 'pp_bRemoveDC'
                                                           5000, ... % 'pp_cutoffHzDC'
                                                           0, ... % 'pp_bPreEmphasis'
                                                           0.97, ... % 'pp_coefPreEmphasis'
                                                           0, ... % 'pp_bNormalizeRMS'
                                                           500e-3, ... % 'pp_intTimeSecRMS'
                                                           0, ... % 'pp_bLevelScaling'
                                                           10, ... % 'pp_refSPLdB'
                                                           0, ... % 'pp_bMiddleEarFiltering'
                                                           'jespen', ... % 'pp_middleEarModel'
                                                           1 ); % 'pp_bUnityComp'
pause(p);

gammatoneName = 'gammatone';
gammatoneProc = rosAFE.GammatoneProc('-a', gammatoneName, preProcName, 'gammatone', ... % 'fb_type'
                                                                       80, ... % 'fb_lowFreqHz'
                                                                       8000, ... % 'fb_highFreqHz'
                                                                       1, ... % 'fb_nERBs'
                                                                       23, ... % 'fb_nChannels'
                                                                       0, ... % 'fb_cfHz'
                                                                       4, ... % 'fb_nGamma'
                                                                       1.0180 );  % 'fb_bwERBs'
pause(p);

%%
exLastFrameIndex = 0;

% Getting the parameters
params = rosAFE.getParameters();
if ( strcmp(params.status,'error') )
   error(strcat('Error',params.exception.ex));
end

cfHz = cell2mat(params.result.parameters.gammatone{1}.fb_cfHz);

sig_l = TimeFrequencySignal.construct(sampleRate,bufferSize_s_matlab,'filterbank', gammatoneName, cfHz,'left');
sig_r = TimeFrequencySignal.construct(sampleRate,bufferSize_s_matlab,'filterbank',gammatoneName,cfHz,'right');

lostFrames = 0;

while( 1 )
    gammatoneOut = rosAFE.gammatonePort(gammatoneName);
    gotFrames = gammatoneOut.gammatonePort.lastFrameIndex - exLastFrameIndex;
    exLastFrameIndex = gammatoneOut.gammatonePort.lastFrameIndex;
    if ( gotFrames > gammatoneOut.gammatonePort.framesOnPort )
        lostFrames = gotFrames - gammatoneOut.gammatonePort.framesOnPort;
        gotFrames = gotFrames - lostFrames;
        disp(strcat('Lost Frames : ', int2str(lostFrames)));
    end

    [ chunkLeft chunkRight ] = adaptTFS( gammatoneOut.gammatonePort.framesOnPort, ...
                                         gammatoneOut.gammatonePort.numberOfChannels, ...
                                         gammatoneOut.gammatonePort.left, ...
                                         gammatoneOut.gammatonePort.right, ...
                                         true );

    sig_l.appendChunk( chunkLeft(end-gotFrames+1:end,:) );
    sig_r.appendChunk( chunkRight(end-gotFrames+1:end,:) );

    f1l = subplot(2,1,1);
    sig_l.plot(f1l);
    f1r = subplot(2,1,2);
    sig_r.plot(f1r);
    pause(0.1);
end

stopAndKill();
                        