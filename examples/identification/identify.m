function bbs = identify(idModels)
%IDENTIFY identifies sources positioned at 0 deg and returns the blackboard object

if nargin < 1, idModels = setDefaultIdModels(); end

%warning('off', 'all');
disp( 'Initializing Two!Ears, setting up binaural simulator...' );

% === Initialize Two!Ears model and check dependencies
startTwoEars('Config.xml');

% === load test sounds
% leave away the second argument to use the whole testlist
[sourceSignal, labels, onOffsets] = makeTestSignal(idModels, 'shortTest.flist');

% === Initialise binaural simulator
sim = simulator.SimulatorConvexRoom('SceneDescription.xml');
sim.Verbose = false;
sim.Init = true;
sim.Sources{1}.set('Azimuth', 0);
sim.rotateHead(0, 'absolute');
sim.ReInit = true;
sim.Sources{1}.setData(sourceSignal);

% === Initialise and run model
disp( 'Building blackboard system...' );
bbs = buildIdentificationBBS(sim,idModels,labels,onOffsets);
disp( 'Starting blackboard system.' );
bbs.run();

% === Evaluate scores
idScoresRelativeError(bbs,labels,onOffsets);

% finish
sim.ShutDown = true;


% vim: set sw=4 ts=4 expandtab textwidth=90 :
