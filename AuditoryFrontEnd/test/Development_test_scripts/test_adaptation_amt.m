% Test script to compare the output from TwoEars adaptation processor
% to the output from the adaptation loop test code from AMToolbox 
% 
% NB: Adapt path definitions to your own system

clear all
close all
clc

%% Add paths
path = fileparts(mfilename('fullpath'));
% also added twoears-tools folder following the updates re circular buffers
% (assuming the folder is located inside the same folder where twoears-wp2 is) 
addpath(genpath([path filesep '..' filesep '..' filesep '..' filesep 'twoears-tools']))
run([path filesep '..' filesep '..' filesep 'startAuditoryFrontEnd.m'])

%% test signal
% As in the demo in AMToolbox (demo_adaploop.m) ---------------------
fs=10000;
minlvl=setdbspl(0);
duration = 0.4;                
beginSilence=0.2;
endSilence=0.4;
rampDuration=0.1;              

dt=1/fs; % seconds
time=dt: dt: duration;
inputSignal=ones(1, length(time));      

rampTime=dt:dt:rampDuration;
ramp=[sin(pi*rampTime/(2*rampDuration)) ...
    ones(1,length(time)-length(rampTime))];
inputSignal=inputSignal.*ramp;
ramp=fliplr(ramp);
inputSignal=inputSignal.*ramp;

intialSilence = zeros(1,round(beginSilence/dt));
finalSilence = zeros(1,round(endSilence/dt));
inputSignal = [intialSilence inputSignal finalSilence];
inputSignal = max(inputSignal,minlvl);
inputSignal = inputSignal.';
x = (0:length(inputSignal)-1)/fs;

%% Instantiate manager and data object
param_struct = [];
dObj = dataObject(inputSignal, fs);
request = 'adaptation';
adpt_model = 'adt_vandorpschuitman';

% % Summary of parameters 
param_struct = genParStruct('adpt_model', adpt_model);

mObj = manager(dObj);               % Manager instance
out = mObj.addProcessor(request, param_struct);

%% For this test run the adaptation loop separately using the input
adt_testout = mObj.Processors{4}.processChunk(inputSignal);

%% Plot result - compare to the output from AMToolbox
% Input signal
figure; plot(x, 20*log10(inputSignal));
ylim([-110 10]);
xlabel('Time [sec]');
ylabel('Level [dB]');
title('Input signal');

% Output signal
figure; plot(x, adt_testout);
xlabel('Time [sec]');
ylabel('Model Unit(MU)');
title('Adaptation output');
