function localise()
% Localisation example comparing localisation with and without head rotations

warning('off','all');

% Initialize Two!Ears model and check dependencies
startTwoEars('Config.xml');

% === Configuration
% Different source positions given by BRIRs
% see:
% http://twoears.aipa.tu-berlin.de/doc/latest/database/impulse-responses/#tu-berlin-telefunken-building-room-auditorium-3
brirs = { ...
    'impulse_responses/qu_kemar_rooms/auditorium3/QU_KEMAR_Auditorium3_src1_xs+0.00_ys+3.97.sofa'; ...
    'impulse_responses/qu_kemar_rooms/auditorium3/QU_KEMAR_Auditorium3_src2_xs+4.30_ys+3.42.sofa'; ...
    'impulse_responses/qu_kemar_rooms/auditorium3/QU_KEMAR_Auditorium3_src3_xs+2.20_ys-1.94.sofa'; ...
    'impulse_responses/qu_kemar_rooms/auditorium3/QU_KEMAR_Auditorium3_src4_xs+0.00_ys+1.50.sofa'; ...
    'impulse_responses/qu_kemar_rooms/auditorium3/QU_KEMAR_Auditorium3_src5_xs-0.75_ys+1.30.sofa'; ...
    'impulse_responses/qu_kemar_rooms/auditorium3/QU_KEMAR_Auditorium3_src6_xs+0.75_ys+1.30.sofa'; ...
    };
headOrientation = 90; % towards y-axis (facing src1)
sourceAngles = [90, 38.5, -41.4, 90, 120, 60] - headOrientation; % phi = atan2d(ys,xs)

% === Initialise binaural simulator
sim = setupBinauralSimulator();

printLocalisationTableHeader();

for ii = 1:length(sourceAngles)

    direction = sourceAngles(ii);

    sim.Sources{1}.IRDataset = simulator.DirectionalIR(brirs{ii});
    sim.rotateHead(headOrientation, 'absolute');
    sim.Init = true;

    phi1 = estimateAzimuth(sim, 'BlackboardDnn.xml');                % DnnLocationKS w head movements
    resetBinauralSimulator(sim, headOrientation);
    phi2 = estimateAzimuth(sim, 'BlackboardDnnNoHeadRotation.xml');  % DnnLocationKS wo head movements

    printLocalisationTableColumn(direction, ...
                                 phi1 - headOrientation, ...
                                 phi2 - headOrientation);

    sim.ShutDown = true;
end

printLocalisationTableFooter();


end % of main function

function printLocalisationTableHeader()
    fprintf('\n');
    fprintf('-------------------------------------------------------------------------\n');
    fprintf('Source direction   DnnLocationKS w head rot.   DnnLocationKS wo head rot.\n');
    fprintf('-------------------------------------------------------------------------\n');
end

function printLocalisationTableColumn(direction, phi1, phi2)
    fprintf('     %4.0f              %4.0f                       %4.0f\n', ...
            wrapTo180(direction), wrapTo180(phi1), wrapTo180(phi2));
end

function printLocalisationTableFooter()
    fprintf('------------------------------------------------------------------------\n');
end

% vim: set sw=4 ts=4 expandtab textwidth=90 :
