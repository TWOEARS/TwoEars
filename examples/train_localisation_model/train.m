function train(name, sceneDescription, angularResolution)
%TRAIN will train the localisation stage for the specified data
%
%   USAGE
%       train(name, sceneDescription)
%
%   INPUT PARAMETERS
%       name             - name the learned model will be stored under
%       sceneDescription - scene description file that will be used by the Binaural
%                          Simulator to create the binaural signals that will be used for
%                          learning

warning('off','all');

% Initialize Two!Ears model and check dependencies
startTwoEars('Config.xml');

% Check input parameters
narginchk(3,3)
isargchar(name)
isargfile(sceneDescription)
isargpositivescalar(angularResolution)

% Create a GmtkLocationKS in training mode
bTrain = true;
loc = GmtkLocationKS(name, angularResolution, bTrain);

% Generate binaural signals and extract ITD, ILD for learning.
% The used HRTF set, audio material and signal length are specified in the scene
% description file
loc.generateTrainingData(sceneDescription);

% Train model
loc.train();

% Remove unneeded data
loc.removeTrainingData();

% vim: set sw=4 ts=4 expandtab textwidth=90 :
