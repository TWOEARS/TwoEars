function [sourceSignal, labels, onOffsets] = makeTestSignal( idModels, otherTestFlist )

if nargin < 2
    [~, idModelVersion] = strtok(idModels(1).dir, '.');
    testFlist = [idModels(1).dir filesep 'testSet' idModelVersion '.flist'];
    % the testFlists of the different models loaded in THIS case are identical,
    % but in general the intersection of them would have to be formed as test set
    % to avoid using files that have been used in training of one of the models.
else
    testFlist = otherTestFlist;
end

[sourceFiles,nFiles] = readFileList(testFlist);
sourceFiles = sourceFiles(randperm(nFiles));
[sourceSignals, sourceLabels] = readAudioFiles(...
    sourceFiles, ...
    'Samplingrate', 44100, ...
    'Zeropadding', 0.25 * 44100,...
    'Normalize', true, ...
    'CellOutput', true);
sourceSignal = vertcat(sourceSignals{:});
labels = {sourceLabels.class};
labels(cellfun(@isempty,labels)==1) = [];
onOffsets = vertcat(sourceLabels.cumOnsetsOffsets);
