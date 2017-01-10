clear all;
close all;
clc;
p=0.25;

%% Paths
addpath(genpath('~/openrobots/lib/matlab'));
addpath(genpath('/home/musabini/TwoEars/AuditoryModel/TwoEars-1.2/AuditoryFrontEnd'));
startAuditoryFrontEnd;

%% Genom
client = genomix.client;
pause(p);
bass = client.load('bass');
pause(p);
rosAFE = client.load('rosAFE');
pause(p);

%% Acquiring Audio
sampleRate = 44100;
bufferSize_s_bass = 1;
nFramesPerChunk = 2205;
nChunksOnPort = sampleRate * bufferSize_s_bass / nFramesPerChunk;
inputDevice = 'hw:1,0';

% acquire = bass.Acquire('-a', inputDevice, sampleRate, nFramesPerChunk, nChunksOnPort);
% pause(0.25);
% if ( strcmp(acquire.status,'error') )
%    error(strcat('Error',acquire.exception.ex));
% end
menu('Launch rosbag now','Done');

%% Connecting rosAFE to BASS
connection = rosAFE.connect_port('Audio', 'bass/Audio');
pause(p);
if ( strcmp(connection.status,'error') )
    error(strcat('Error',connection.exception.ex));
end

bufferSize_s_rosAFE_port = 2;
bufferSize_s_rosAFE_getSignal = 0.5;

%% Matlab Signals
matlab_buffer = 10;
inputTDS_l = TimeDomainSignal.construct(sampleRate, matlab_buffer, 'input', 'test', 'left');
inputTDS_r = TimeDomainSignal.construct(sampleRate, matlab_buffer, 'input', 'test', 'right');

ppTDS_l = TimeDomainSignal.construct(sampleRate, matlab_buffer, 'pp', 'test', 'left');
ppTDS_r = TimeDomainSignal.construct(sampleRate, matlab_buffer, 'pp', 'test', 'right');

%% Ading processors
inputName = 'input';
thisProc = rosAFE.InputProc('-a', inputName, 12000, bufferSize_s_rosAFE_port, bufferSize_s_rosAFE_getSignal );
pause(p);

preProcName = 'preProc';
preProcProc = rosAFE.PreProc('-a', preProcName, inputName, 1, ... % 'pp_bRemoveDC'
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

%% Process Chunk
while(1)
    
    signal = rosAFE.getSignals();
    if ( strcmp(signal.status,'error') )
       error(strcat('Error',signal.exception.ex));
    end

    % Appending
    inputTDS_l.appendChunk(cell2mat(signal.result.signals.input{1}.left.data)');
    inputTDS_r.appendChunk(cell2mat(signal.result.signals.input{1}.right.data)');
    
    ppTDS_l.appendChunk(cell2mat(signal.result.signals.preProc{1}.left.data)');
    ppTDS_r.appendChunk(cell2mat(signal.result.signals.preProc{1}.right.data)');

    % Ploting
    subplot(2,2,1);
    plot(inputTDS_l.Data(:,:));
    axis([0 sampleRate*matlab_buffer -0.1 0.1]);
    subplot(2,2,2);
    plot(inputTDS_r.Data(:,:));
    axis([0 sampleRate*matlab_buffer -0.1 0.1]);
    subplot(2,2,3);
    plot(ppTDS_l.Data(:,:));
    axis([0 sampleRate*matlab_buffer -0.1 0.1]);
    subplot(2,2,4);
    plot(ppTDS_r.Data(:,:)); 
    axis([0 sampleRate*matlab_buffer -0.1 0.1]);
    
    % Waiting
    pause(0.1);
end

%% Stop and Kill
rosAFE.Stop();
rosAFE.kill();

bass.Stop();
bass.kill();