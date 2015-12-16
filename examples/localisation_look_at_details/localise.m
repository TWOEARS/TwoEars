function bbs = localise()
%LOCALISE localises a source positioned at 0 deg and return the blackboard object

warning('off', 'all');

% Initialize Two!Ears model and check dependencies
startTwoEars('Config.xml');

% Source angle
direction = 0;

% === Initialise binaural simulator
sim = simulator.SimulatorConvexRoom('SceneDescription.xml');
sim.Verbose = false;
sim.Init = true;
sim.LengthOfSimulation = 5;

% === Initialise model
bbs = BlackboardSystem(0);
bbs.setRobotConnect(sim);
bbs.buildFromXml('Blackboard.xml');
sim.Sources{1}.set('Azimuth', direction);
sim.rotateHead(0, 'absolute');
sim.ReInit = true;
bbs.run();
sim.ShutDown = true;

% === Look at detail results (see:
% http://twoears.aipa.tu-berlin.de/doc/examples/localisation-details.html)
%
%perceivedAzimuths = bbs.blackboard.getData('perceivedAzimuths');
%[loc, locError] = evaluateLocalisationResults(perceivedAzimuths, sourceAzimuth);
%displayLocalisationResults(perceivedAzimuths, sourceAzimuth)
%bbs.listAfeData
%bbs.plotAfeData('time');
%bbs.plotAfeData('ild');
%bbs.plotAfeData('head_rotation');

% vim: set sw=4 ts=4 expandtab textwidth=90 :
