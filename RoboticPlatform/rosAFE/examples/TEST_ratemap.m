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

ihcName = 'ihc';
ihcProc = rosAFE.IhcProc('-a', ihcName, gammatoneName, 'dau' );  %
pause(p);

ratemapName = 'ratemap';
ratemapProc = rosAFE.RatemapProc('-a', ratemapName, ihcName, 'hann', ... % rm_wname
                                                          0.02, ... % rm_wSizeSec
                                                          0.01, ... % rm_hSizeSec
                                                          'magnitude', ... % rm_scaling
                                                          0.008 ); % rm_decaySec
pause(p);

%% Getting the parameters
params = rosAFE.getParameters();
if ( strcmp(params.status,'error') )
   error(strcat('Error',params.exception.ex));
end

cfHz = cell2mat(params.result.parameters.gammatone{1}.fb_cfHz);

ratemapOut = rosAFE.ratemapPort(ratemapName);
exLastFrameIndex = ratemapOut.ratemapPort.lastFrameIndex;

sig_l = TimeFrequencySignal.construct(ratemapOut.ratemapPort.sampleRate ,bufferSize_s_matlab,'ratemap', ratemapName, cfHz,'left');
sig_r = TimeFrequencySignal.construct(ratemapOut.ratemapPort.sampleRate ,bufferSize_s_matlab,'ratemap', ratemapName, cfHz,'right');

while( 1 )
    ratemapOut = rosAFE.ratemapPort(ratemapName);
    gotFrames = ( ratemapOut.ratemapPort.lastFrameIndex - exLastFrameIndex ) / sampleRate * ratemapOut.ratemapPort.sampleRate;
    exLastFrameIndex = ratemapOut.ratemapPort.lastFrameIndex;
    if ( gotFrames > ratemapOut.ratemapPort.framesOnPort )
        lostFrames = gotFrames - ratemapOut.ratemapPort.framesOnPort;
        gotFrames = gotFrames - lostFrames;
        disp(strcat('Lost Frames : ', int2str(lostFrames)));
    else
        lostFrames = 0;
    end

    [ chunkLeft, chunkRight ] = adaptTFS( ratemapOut.ratemapPort.framesOnPort, ...
                              ratemapOut.ratemapPort.numberOfChannels, ...
                              ratemapOut.ratemapPort.left, ...
                              true, ...
                              ratemapOut.ratemapPort.right);
         
    sig_l.appendChunk( chunkLeft(end-floor(gotFrames)+1:end,:) );
    sig_r.appendChunk( chunkRight(end-floor(gotFrames)+1:end,:) );
    
    f1l = subplot(2,1,1);
    sig_l.plot(f1l);
    f1r = subplot(2,1,2);
    sig_r.plot(f1r);
    pause(0.1);
end

stopAndKill();