clear all; close all; clc;

openRobotsMatlabPath = '~/openrobots/lib/matlab';
twoEarsPath = '~/TwoEars/AuditoryModel/TwoEars-1.2/';
rosAFE_matlab_Path = '~/genom_ws/rosAFE/matlabFiles';

addpath(genpath(rosAFE_matlab_Path));

%% Initialization of modules
[ bass, rosAFE, client ] = initRosAFE( openRobotsMatlabPath, twoEarsPath );

%% Parameters for data object
sampleRate = 44100;

bufferSize_s_bass = 1;
bufferSize_s_rosAFE_port = 1;
bufferSize_s_rosAFE_getSignal = 1;
bufferSize_s_matlab = 10;

inputDevice = 'hw:2,0'; % Check your input device by bass.ListDevices();

framesPerChunk = 12000; % Each chunk is (framesPerChunk/sampleRate) seconds.

%% Data Object
dObj = dataObject_RosAFE( bass, rosAFE, inputDevice, sampleRate, framesPerChunk, bufferSize_s_bass, ...
                                                                                 bufferSize_s_rosAFE_port, ...
                                                                                 bufferSize_s_rosAFE_getSignal, ...
                                                                                 bufferSize_s_matlab );

%% Manager
mObj = manager_RosAFE(dObj);
                
mObj.addProcessor('ild'); % With default parameters

%% Searching gammatone filter's fsHz parameter
name = 'ild_0';
output = mObj.RosAFE.ildPort(name);

sig = TimeFrequencySignal.construct(output.ildPort.sampleRate, mObj.dObj.bufferSize_s_matlab, 'ild', name, cell2mat(mObj.Processors.gammatone{1}.fb_cfHz), 'mono');
f = figure(1);

while (1)
    output = mObj.RosAFE.ildPort(name);

    chunkLeft = adaptTFS( output.ildPort.framesOnPort, output.ildPort.numberOfChannels, output.ildPort.left, 0 );
    sig.appendChunk( chunkLeft );
    sig.plot(f);
    
    pause(0.3);
end