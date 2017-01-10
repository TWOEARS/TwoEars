clear all; close all; clc;

%% Initialization of modules
[ bass, rosAFE, client ] = initRosAFE( );

%% Acquiring Audio

sampleRate = 44100;
bufferSize_s_bass = 1;
nFramesPerChunk = 2205;
inputDevice = 'hw:2,0';
        
acquireAudio(bass, rosAFE, sampleRate, bufferSize_s_bass, nFramesPerChunk, inputDevice);

bufferSize_s_rosAFE_port = 1;
bufferSize_s_rosAFE_getSignal = 1;
bufferSize_s_matlab = 10;

framesPerChunk = 10;

%% Ading processors
inputName = 'input';
thisProc = rosAFE.InputProc('-a', inputName, framesPerChunk, bufferSize_s_rosAFE_port, bufferSize_s_rosAFE_getSignal );
pause(0.2);

%%
exLastFrameIndex = 0;

sig_l = TimeDomainSignal.construct(sampleRate, bufferSize_s_matlab, ...
                            'input', 'Ear Signal', 'left');
sig_r = TimeDomainSignal.construct(sampleRate, bufferSize_s_matlab, ...
                            'input', 'Ear Signal', 'right');
                        
while( 1 )
    inputOut = rosAFE.inputProcPort();
    gotFrames = inputOut.inputProcPort.lastFrameIndex - exLastFrameIndex;
    exLastFrameIndex = inputOut.inputProcPort.lastFrameIndex;
    if ( gotFrames > inputOut.inputProcPort.framesOnPort )
        lostFrames = gotFrames - inputOut.inputProcPort.framesOnPort;
        gotFrames = gotFrames - lostFrames;
    else
        lostFrames = 0;
    end

    left = cell2mat(inputOut.inputProcPort.left.data(end-gotFrames+1:end)');
    sig_l.appendChunk( left );
    right = cell2mat(inputOut.inputProcPort.right.data(end-gotFrames+1:end)');
    sig_r.appendChunk( right );

    f1l = subplot(2,1,1);
    sig_l.plot(f1l);
    f1r = subplot(2,1,2);
    sig_r.plot(f1r);
    pause(0.2);
end

stopAndKill( bass, rosAFE, client );