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
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos1.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos2.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos3.sofa'; ...
    'impulse_responses/twoears_kemar_adream/TWOEARS_KEMAR_ADREAM_pos4.sofa'; ...
    };

%headOrientation = -90; % towards y-axis (facing src1)
%sourceAngles = [-90, -157, -141, -125] - headOrientation; % phi = atan2d(ys,xs)

% === Initialise binaural simulator
sim = setupBinauralSimulator();

printLocalisationTableHeader();

for ii = 1:length(brirs)

    % Get metadata from BRIR
    brir = SOFAload(xml.dbGetFile(brirs{ii}), 'nodata');

    % Get 0 degree look head orientation from BRIR
    nsteps = size(brir.ListenerView, 1);
    headPos = SOFAconvertCoordinates(brir.ListenerView(ceil(nsteps/2),:),'cartesian','spherical');
    headOrientation = headPos(1);

    fprintf('Head position %d:\n', ii);
    
    for jj = 1:size(brir.EmitterPosition,1); % loop over all loudspeakers

        % Get source direction from BRIR
        y = brir.EmitterPosition(jj, 2) - brir.ListenerPosition(2);
        x = brir.EmitterPosition(jj, 1) - brir.ListenerPosition(1);
        direction = atan2d(y, x) - headOrientation;

        sim.Sources{1}.IRDataset = simulator.DirectionalIR(brirs{ii}, jj);
        sim.rotateHead(headOrientation, 'absolute');
        sim.Init = true;

        phi1 = estimateAzimuth(sim, 'BlackboardDnn.xml'); % DnnLocationKS w head movements
        resetBinauralSimulator(sim, headOrientation);
        phi2 = estimateAzimuth(sim, 'BlackboardDnnNoHeadRotation.xml'); % DnnLocationKS wo head movements

        printLocalisationTableColumn(direction, ...
                                     phi1 - headOrientation, ...
                                     phi2 - headOrientation);

        sim.ShutDown = true;
    end
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
