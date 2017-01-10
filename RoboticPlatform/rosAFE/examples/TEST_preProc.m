%%
clear all; close all; clc;
p=0.15;
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

%%
exLastFrameIndex = 0;
sig_l = TimeDomainSignal.construct(sampleRate, bufferSize_s_matlab, ...
                            'preProc', preProcName, 'left');
sig_r = TimeDomainSignal.construct(sampleRate, bufferSize_s_matlab, ...
                            'preProc', preProcName, 'right');
                        
while( 1 )
    preProcOut = rosAFE.preProcPort(preProcName);
    gotFrames = preProcOut.preProcPort.lastFrameIndex - exLastFrameIndex;
    exLastFrameIndex = preProcOut.preProcPort.lastFrameIndex;
    if ( gotFrames > preProcOut.preProcPort.framesOnPort )
        lostFrames = gotFrames - preProcOut.preProcPort.framesOnPort;
        gotFrames = gotFrames - lostFrames;
    else lostFrames = 0;
    
    end

    left = cell2mat(preProcOut.preProcPort.left.data(end-gotFrames+1:end)');
    sig_l.appendChunk( left );
    right = cell2mat(preProcOut.preProcPort.right.data(end-gotFrames+1:end)');
    sig_r.appendChunk( right );

    f1l = subplot(2,1,1);
    sig_l.plot(f1l);
    f1r = subplot(2,1,2);
    sig_r.plot(f1r);
    pause(0.2);
end


