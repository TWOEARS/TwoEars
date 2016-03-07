% This script demonstrates how an instance of the Segmentation
% Knowledge Source can be trained for a specific set of HRTFs. The KS
% performs a segmentation of auditory features and estimates the angular
% positions of an acoustic mixture, given the number of sound sources 
% that are present.
%
% AUTHOR:
%   Christopher Schymura (christopher.schymura@rub.de)
%   Cognitive Signal Processing Group
%   Ruhr-Universitaet Bochum
%   Universitaetsstr. 150, 44801 Bochum

% Start the Two!Ears auditory model
startTwoEars('segmentation_config.xml');

%% Step 1: Create an instance of the KS that should be trained

% Each instance needs an unique identifier, specified as a string
ksName = 'DemoKS';

% Additional parameters for pre-processing can be specified. Note that if
% the parameters are changed, the KS has to be re-trained for the new
% parameters. The specification of these parameters is optional. If no
% parameters are set, training will be conducted using default settings,
% which are specified in the corresponding KS class.
nChannels = 32;             % Number of filterbank channels
winSize = 0.02;             % Size of the processing window in [s]
hopSize = 0.01;             % Frame shift in [s]
fLow = 80;                  % Lowest filterbank center frequency in [Hz]
fHigh = 8000;               % Highest filterbank center frequency in [Hz]

% Create an instance of the KS
segKS = SegmentationKS(ksName, ...
    'NumChannels', nChannels, ...
    'WindowSize', winSize, ...
    'HopSize', hopSize, ...
    'FLow', fLow, ...
    'FHigh', fHigh, ...
    'Verbosity', true);     % Enable status messages during training

%% Step 2: Run training

% Generate a training dataset for a training scene. The training scene has
% to be specified as a XML-file which can be handled by the Binaural
% Simulator and contains the HRTF dataset that should be used for training.
xmlSceneDescription = 'training_scene.xml';
segKS.generateTrainingData(xmlSceneDescription);

% Train the model. This may take several hours depending on your machine.
% If you already have conducted training for your KS and you want to
% re-train your models, you have to set the training method in overwriting
% mode, which is set to 'false' by default (see KS class file for details).
segKS.train();

% Use the following command if you want to overwrite an existing model:
% segKS.train(true);

% Remove the generated training dataset. This data is not necessary for
% using the KS within the blackboard system.
segKS.removeTrainingData();
