clear all; close all; clc;

addpath(genpath('/home/musabini/genom_ws/rosAFE/examples'));

%% Initialization of modules
[ bass, rosAFE, client ] = initRosAFE( );

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
mObj.addProcessor('ratemap'); % With default parameters

%mObj.addProcessor('ild',par); % With given parameters

%mObj.modifyParameter( 'time_0', 'pp_bRemoveDC', '0' );

mObj.processChunk( );

mObj.deleteProcessor( 'ild', 1 );
