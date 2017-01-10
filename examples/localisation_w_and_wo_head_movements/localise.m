function localise()
% Localisation example comparing localisation with and without head rotations

warning('off','all');

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

    % GmmLocationKS with head rotation
    phi1 = estimateAzimuth(sim, 'Blackboard.xml');

    % Reset binaural simulation
    sim.rotateHead(0, 'absolute');
    sim.ReInit = true;

    % GmmLocationKS without head rotation
    phi2 = estimateAzimuth(sim, 'BlackboardNoHeadRotation.xml');

    printLocalisationTableColumn(direction, phi1, phi2);

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
