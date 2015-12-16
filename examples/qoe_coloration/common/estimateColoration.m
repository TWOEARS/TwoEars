function prediction = estimateColoration(sim, sourceFiles, sourceTypes, humanLabelFiles)
%estimateColoration runs the Two!Ears Blackboard Systems Coloration knowledge
%                   source in order to predict the coloration for the specified
%                   conditions
%
%   USAGE
%       prediction = estimateColoration(sim, sourceFiles, humanLabelFiles)
%
%   INPUT PARAMETERS
%       sim             - Binaural Simulator object
%       sourceFiles     - Cell containing all audio source files
%       sourceTypes     - Cell containing all audio source types
%       humanLabelFiles - Cell containing all human labels from the listening
%                         experiment
%
%   OUTPUT PARAMETERS
%       prediction      - Predictions of the coloration for the different
%                         conditions presented in humanLabelFiles
%
%   DETAILS
%       The humanLabelFiles need to state the used BRS files of every condition
%       in the first row, the second row contains the rating, and the third row
%       the confidence interval from the listening experiment on coloration.
%       The coloration prediction is done by the coloration model after Moore
%       and Tan (2004).

for ii = 1:length(sourceFiles)

    % === Get results and conditions from listening test
    humanLabels = readHumanLabels(humanLabelFiles{ii});

    % === Read audio source material
    sourceMaterial = audioread(xml.dbGetFile(sourceFiles{ii}));

    % === Estimate reference
    sim.Sources{1}.IRDataset = simulator.DirectionalIR(humanLabels{1,1});
    sim.Sources{1}.setData(sourceMaterial);
    sim.Init = true;
    bbs = BlackboardSystem(0);
    bbs.setRobotConnect(sim);
    bbs.setDataConnect('AuditoryFrontEndKS');
    ColorationKS = bbs.createKS('ColorationKS', {sourceTypes{ii}});
    bbs.blackboardMonitor.bind({bbs.scheduler}, {bbs.dataConnect}, 'replaceOld', ...
                               'AgendaEmpty' );
    bbs.blackboardMonitor.bind({bbs.dataConnect}, {ColorationKS}, 'replaceOld' );
    bbs.run(); % The ColorationKS runs automatically until the end of the signal
    sim.ShutDown = true;

    % === Estimate coloration for conditions
    for jj = 1:size(humanLabels,1)
        sim.Sources{1}.IRDataset = simulator.DirectionalIR(humanLabels{jj,1});
        sim.Sources{1}.setData(sourceMaterial);
        sim.Init = true;
        bbs.run()
        prediction(ii,jj) = ...
            bbs.blackboard.getLastData('colorationHypotheses').data.differenceValue;
        sim.ShutDown = true;
    end

end

% vim: set sw=4 ts=4 et tw=90:
