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
inputDevice = 'hw:2,0';

acquire = bass.Acquire('-a', inputDevice, sampleRate, nFramesPerChunk, nChunksOnPort);
pause(0.25);
if ( strcmp(acquire.status,'error') )
   error(strcat('Error',acquire.exception.ex));
end
% menu('Launch rosbag now','Done');

%% Connecting rosAFE to BASS
connection = rosAFE.connect_port('Audio', 'bass/Audio');
pause(p);
if ( strcmp(connection.status,'error') )
    error(strcat('Error',connection.exception.ex));
end

bufferSize_s_rosAFE_port = 2;
bufferSize_s_rosAFE_getSignal = 5;

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
                                                           1, ... % 'pp_bLevelScaling'
                                                           10, ... % 'pp_refSPLdB'
                                                           0, ... % 'pp_bMiddleEarFiltering'
                                                           'jespen', ... % 'pp_middleEarModel'
                                                           1 ); % 'pp_bUnityComp'
pause(p);

gammatoneName = 'gammatoneProc';
gammatoneProc = rosAFE.GammatoneProc('-a', gammatoneName, preProcName, 'gammatone', ... % 'fb_type'
                                                                       80, ... % 'fb_lowFreqHz'
                                                                       8000, ... % 'fb_highFreqHz'
                                                                       1, ... % 'fb_nERBs'
                                                                       23, ... % 'fb_nChannels'
                                                                       0, ... % 'fb_cfHz'
                                                                       4, ... % 'fb_nGamma'
                                                                       1.0180 );  % 'fb_bwERBs'
pause(p);

ihcName = 'ihcP';
ihcProc = rosAFE.IhcProc('-a', ihcName, gammatoneName, 'dau' );  %
pause(p);

ildName = 'ildP';
ildProc = rosAFE.IldProc('-a', ildName, ihcName, 'hann', 0.02, 0.01 );  % 
pause(p);

%% Services
% Getting the parameters
params = rosAFE.getParameters();
if ( strcmp(params.status,'error') )
   error(strcat('Error',params.exception.ex));
end

% Modifying a parameter
modif = rosAFE.modifyParameter(preProcName, 'pp_bLevelScaling', '0');
if ( strcmp(modif.status,'error') )
   error(strcat('Error',modif.exception.ex));
end

% Killing a processor
kill = rosAFE.removeProcessor(preProcName);
if ( strcmp(kill.status,'error') )
   error(strcat('Error',kill.exception.ex));
end

%% Getting the output signals

signal = rosAFE.getSignals();
if ( strcmp(signal.status,'error') )
   error(strcat('Error',signal.exception.ex));
end

%% Getting the individual outputs

ildOut = rosAFE.ildPort(ildName);
ihcOut = rosAFE.ihcPort(ihcName);
gammatoneOut = rosAFE.gammatonePort(gammatoneName);
preProcOut = rosAFE.preProcPort(preProcName);
inputOut = rosAFE.inputProcPort();
bassOut = bass.Audio();

%% Stop and Kill
rosAFE.Stop();
rosAFE.kill();

bass.Stop();
bass.kill();
