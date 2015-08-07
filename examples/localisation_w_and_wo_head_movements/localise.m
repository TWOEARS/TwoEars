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

    % LocationKS with head rotation for confusion solving
    bbs = BlackboardSystem(0);
    bbs.setRobotConnect(sim);
    bbs.buildFromXml('Blackboard.xml');
    bbs.run();
    % Evaluate localization results
    predictedLocations = bbs.blackboard.getData('perceivedLocations');
    [predictedAzimuth1, localisationError1] = ...
        evaluateLocalisationResults(predictedLocations, direction);
    %displayLocalisationResults(predictedLocations, direction)

    % Reset binaural simulation
    sim.rotateHead(0, 'absolute');
    sim.ReInit = true;

    % LocationKS without head rotation and confusion solving
    bbs = BlackboardSystem(0);
    bbs.setRobotConnect(sim);
    bbs.buildFromXml('BlackboardNoHeadRotation.xml');
    bbs.run();
    predictedLocations = bbs.blackboard.getData('perceivedLocations');
    [predictedAzimuth2, localisationError2] = ...
        evaluateLocalisationResults(predictedLocations, direction);

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
            azimuthInPlusMinus180(direction), ...
            azimuthInPlusMinus180(azimuth1), ...
            azimuthInPlusMinus180(azimuth2));
end

function printLocalisationTableFooter()
    fprintf(1, '------------------------------------------------------------------\n');
end

% vim: set sw=4 ts=4 expandtab textwidth=90 :
