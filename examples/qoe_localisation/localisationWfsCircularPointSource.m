function localisationWfsCircularPointSource()
% localisationWfsCircularPointSource() computes directions of auditory event of
%                                      synthesized sound fields and compares them
%                                      to humam data from listening experiments
%
%   USAGE
%       localisationWfsCircularPointSource()
%


%% ===== Configuration ===================================================
% Listening experiment files
humanLabelFile = ...
    'experiments/2013-11-01_sfs_localisation/human_label_localization_wfs_ps_circular.txt';
% Binaural simulation files
binSimFile = 'experiments/2013-11-01_sfs_localisation/2013-11-01_sfs_localisation.xml';


%% ===== Main ============================================================
% Initialize Two!Ears model and check dependencies
startTwoEars('Config.xml');

fprintf(1, '\nPROCESS HUMAN LABEL FILE: %s\n', humanLabelFile);

% Get human labels
humanLabels = readHumanLabels(humanLabelFile);

fprintf(1, '\n');
fprintf(1, '----------------------------------------------------------------------------------\n');
fprintf(1, 'condition \t\t\t\t\t experiment \t ItdLocationKS\n');
fprintf(1, '----------------------------------------------------------------------------------\n');

for ii = 1:size(humanLabels, 1)

    brsFile = humanLabels{ii,1};
    headRotationOffset = humanLabels{ii,9};
    % Check if more than one source was perceived by the listener
    if length(humanLabels{ii,4})>1
        % Ignore it by claculating the average location for now
        %perceivedAzimuth = mean([humanLabels{ii,4}(:)]) - headRotationOffset;
        % Ignore it by using only the first entry
        perceivedAzimuth(ii) = humanLabels{ii,4}(1);
        physicalAzimuth(ii) = perceivedAzimuth(ii) - humanLabels{ii,5}(1);% phi-phi_error
    else
        perceivedAzimuth(ii) = humanLabels{ii,4};
        physicalAzimuth(ii) = perceivedAzimuth(ii) - humanLabels{ii,5};
    end

    % Start binaural simulation
    sim = simulator.SimulatorConvexRoom(binSimFile);
    sim.Sources{1}.IRDataset = simulator.DirectionalIR(brsFile); % load BRS file
    sim.Verbose = false;
    sim.LengthOfSimulation = 5;
    sim.rotateHead(0, 'absolute');
    sim.Init = true;

    % Setup blackboard system
    bbs = BlackboardSystem(0);
    bbs.setRobotConnect(sim);
    bbs.buildFromXml('Blackboard.xml');
    % Run blackboard
    bbs.run();

    % Evaluate localization results
    predictedAzimuths = bbs.blackboard.getData('perceivedAzimuths');
    [predictedAzimuth(ii), localisationError(ii)] = ...
        evaluateLocalisationResults(predictedAzimuths, physicalAzimuth(ii));
    predictedAzimuth(ii) = predictedAzimuth(ii) + headRotationOffset;
    %displayLocalisationResults(predictedAzimuths, perceivedAzimuth);

    sim.ShutDown = true;

    % Display results
    [~, condition] = fileparts(brsFile);
    fprintf(1, '%s\t %4.0f deg\t %4.0f deg\n', condition, ...
        wrapTo180(perceivedAzimuth(ii)), ...
        wrapTo180(predictedAzimuth(ii)));

end

fprintf(1, '--------------------------------------------------------------------------------------------\n');
fprintf(1, '\n\n');

% Plot results
X = [humanLabels{:,2}];
Y = [humanLabels{:,3}];
% Loudspeaker positions
x0 = [ ...
    1.5000         0
    1.4906    0.1679
    1.4624    0.3338
    1.4158    0.4954
    1.3515    0.6508
    1.2701    0.7980
    1.1727    0.9352
    1.0607    1.0607
    0.9352    1.1727
    0.7980    1.2701
    0.6508    1.3515
    0.4954    1.4158
    0.3338    1.4624
    0.1679    1.4906
         0    1.5000
   -0.1679    1.4906
   -0.3338    1.4624
   -0.4954    1.4158
   -0.6508    1.3515
   -0.7980    1.2701
   -0.9352    1.1727
   -1.0607    1.0607
   -1.1727    0.9352
   -1.2701    0.7980
   -1.3515    0.6508
   -1.4158    0.4954
   -1.4624    0.3338
   -1.4906    0.1679
   -1.5000         0
   -1.4906   -0.1679
   -1.4624   -0.3338
   -1.4158   -0.4954
   -1.3515   -0.6508
   -1.2701   -0.7980
   -1.1727   -0.9352
   -1.0607   -1.0607
   -0.9352   -1.1727
   -0.7980   -1.2701
   -0.6508   -1.3515
   -0.4954   -1.4158
   -0.3338   -1.4624
   -0.1679   -1.4906
         0   -1.5000
    0.1679   -1.4906
    0.3338   -1.4624
    0.4954   -1.4158
    0.6508   -1.3515
    0.7980   -1.2701
    0.9352   -1.1727
    1.0607   -1.0607
    1.1727   -0.9352
    1.2701   -0.7980
    1.3515   -0.6508
    1.4158   -0.4954
    1.4624   -0.3338
    1.4906   -0.1679];
figure('Position', [100, 100, 800, 550]);
% listening test
[u,v] = pol2cart(deg2rad(perceivedAzimuth+90), ones(1,48));
subplot(2,3,1);
quiver(X(1:16), Y(1:16), u(1:16), v(1:16), 0.5, 'LineWidth', 1); hold on
plot(x0(1:4:end,1), x0(1:4:end,2), 'ok', 'MarkerFaceColor', 'k', 'MarkerSize', 3);
axis equal
axis([-2.3 2.3 -2 2.6])
title('experiment, 14 loudsp.');
xlabel('x/m');
ylabel('y/m');
subplot(2,3,2);
quiver(X(17:32), Y(17:32), u(17:32), v(17:32), 0.5, 'LineWidth', 1); hold on
plot(x0(1:2:end,1), x0(1:2:end,2), 'ok', 'MarkerFaceColor', 'k', 'MarkerSize', 3);
axis equal
axis([-2.3 2.3 -2 2.6])
title('experiment, 28 loudsp.');
xlabel('x/m');
ylabel('y/m');
subplot(2,3,3);
quiver(X(33:48), Y(33:48), u(33:48), v(33:48),0.5, 'LineWidth', 1); hold on
plot(x0(:,1), x0(:,2), 'ok', 'MarkerFaceColor', 'k', 'MarkerSize', 3);
axis equal
axis([-2.3 2.3 -2 2.6])
title('experiment, 56 loudsp.');
xlabel('x/m');
ylabel('y/m');
% model
[u,v,~] = pol2cart(deg2rad(predictedAzimuth+90),ones(1,48),zeros(1,48));
subplot(2,3,4);
quiver(X(1:16), Y(1:16), u(1:16), v(1:16), 0.5, 'LineWidth', 1); hold on
plot(x0(1:4:end,1), x0(1:4:end,2), 'ok', 'MarkerFaceColor', 'k', 'MarkerSize', 3);
axis equal
axis([-2.3 2.3 -2 2.6])
title('model, 14 loudsp.');
xlabel('x/m');
ylabel('y/m');
subplot(2,3,5);
quiver(X(17:32), Y(17:32), u(17:32), v(17:32), 0.5, 'LineWidth', 1); hold on
plot(x0(1:2:end,1), x0(1:2:end,2), 'ok', 'MarkerFaceColor', 'k', 'MarkerSize', 3);
axis equal
axis([-2.3 2.3 -2 2.6])
title('model, 28 loudsp.');
xlabel('x/m');
ylabel('y/m');
subplot(2,3,6);
quiver(X(33:48), Y(33:48), u(33:48), v(33:48), 0.5, 'LineWidth', 1); hold on
plot(x0(:,1), x0(:,2), 'ok', 'MarkerFaceColor', 'k', 'MarkerSize', 3);
axis equal
axis([-2.3 2.3 -2 2.6])
title('model, 56 loudsp.');
xlabel('x/m');
ylabel('y/m');


% vim: set sw=4 ts=4 expandtab textwidth=90 :
