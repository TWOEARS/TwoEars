function phi = estimateAzimuth(sim, blackboardConfig)
%estimateAzimuth Runs a Blackboard for the given Binaural Simulator and
%                Blackboard configuration file
%
%   USAGE
%       phi = estimateAzimuth(sim, blackboardConfig)
%
%   INPUT PARAMETERS
%       sim              - Binaural simulator object
%       blackboardConfig - blackboard configuration xml file (string)
%
%   OUTPUT PARAMETERS
%       phi              - estimated azimuth

bbs = BlackboardSystem(0);
bbs.setRobotConnect(sim);
bbs.buildFromXml(blackboardConfig);
bbs.run();
% Evaluate localization results
locationHypotheses = bbs.blackboard.getLastData('locationHypothesis');
phi = locationHypotheses.data.azimuth;
