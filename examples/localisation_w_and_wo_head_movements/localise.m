function localise()
% Localisation example comparing localisation with and without head rotations

warning('off','all');

% Initialize Two!Ears model and check dependencies
startTwoEars('Config.xml');

% Different angles the sound source is placed at
sourceAngles = [0 33 76 239];

% === Initialise binaural simulator
sim = simulator.SimulatorConvexRoom('SceneDescription.xml');
sim.Verbose = false;
sim.Init = true;

printLocalisationTableHeader();

for direction = sourceAngles

    sim.Sources{1}.set('Azimuth', direction);
    sim.rotateHead(0, 'absolute');
    sim.ReInit = true;

    % GmtkLocationKS with head rotation for confusion solving
    bbs = BlackboardSystem(0);
    bbs.setRobotConnect(sim);
    bbs.buildFromXml('Blackboard.xml');
    bbs.run();
    % Evaluate localization results
    predictedAzimuths = bbs.blackboard.getData('perceivedAzimuths');
    [predictedAzimuth1, localisationError1] = ...
        evaluateLocalisationResults(predictedAzimuths, direction);
    %displayLocalisationResults(predictedAzimuths, direction)

    % Reset binaural simulation
    sim.rotateHead(0, 'absolute');
    sim.ReInit = true;

    % GmtkLocationKS without head rotation and confusion solving
    bbs = BlackboardSystem(0);
    bbs.setRobotConnect(sim);
    bbs.buildFromXml('BlackboardNoHeadRotation.xml');
    bbs.run();
    predictedAzimuths = bbs.blackboard.getData('perceivedAzimuths');
    [predictedAzimuth2, localisationError2] = ...
        evaluateLocalisationResults(predictedAzimuths, direction);

    printLocalisationTableColumn(direction, predictedAzimuth1, predictedAzimuth2);

end

printLocalisationTableFooter();

sim.ShutDown = true;

end % of main function

function printLocalisationTableHeader()
    fprintf(1, '\n');
    fprintf(1, '------------------------------------------------------------------\n');
    fprintf(1, 'Source direction        Model w head rot.       Model wo head rot.\n');
    fprintf(1, '------------------------------------------------------------------\n');
end

function printLocalisationTableColumn(direction, azimuth1, azimuth2)
    fprintf(1, '%4.0f \t\t\t %4.0f \t\t\t %4.0f\n', ...
            wrapTo180(direction), wrapTo180(azimuth1), wrapTo180(azimuth2));
end

function printLocalisationTableFooter()
    fprintf(1, '------------------------------------------------------------------\n');
end

% vim: set sw=4 ts=4 expandtab textwidth=90 :
