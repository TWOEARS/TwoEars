function [ bass, rosAFE, client ] = initRosAFE( openRobotsMatlabPath, twoEarsPath )
%INITROSAFE [ bass, rosAFE, client ] = initRosAFE( openRobotsPath, twoEarsPath )
%   Initialization of the needed modules.

if ( nargin == 0 )
    openRobotsMatlabPath = '~/openrobots/lib/matlab';
    twoEarsPath = '~/TwoEars/AuditoryModel/TwoEars-1.2/';
end

%% Paths
addpath(genpath(openRobotsMatlabPath));
addpath(genpath(twoEarsPath));
startTwoEars;

startRosAFE;

%% Genom Modules
client = genomix.client;
bass = client.load('bass');
rosAFE = client.load('rosAFE');

end