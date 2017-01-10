function [idLabels, perfs] = idScoresBAC(bbs, labels, onOffsets)

fprintf( '\n\nEvaluate scores...\n\n' );
idHyps = bbs.blackboard.getData( 'identityHypotheses' );
idDescisions = getIdDecisions( idHyps );
idLabels = sort( fieldnames( idDescisions ) );

% assume blockSize remains constant throughout
% assume all hypotheses have the same concernsBlocksize_s
assert( numel(labels) == numel(onOffsets) );
labelBlockSize_s = idHyps(1).data(1).concernsBlocksize_s;
%blockAnnotations_list = {};
types = cell(1, numel( labels ) );
for il = 1 : numel( labels )
    if ~isempty(labels{il})
        types(il) = labels{il}(1);
        for idl = 1 : numel( idLabels )
            if strcmp(idLabels{idl}, types{il})
                idDescisions.(idLabels{idl}).labelIdx = il;
            end
        end % idLabels
    end
end % labels

labeler = StandaloneMultiEventTypeLabeler( ...
            'labelBlockSize_s', labelBlockSize_s, ...
            'types', types );

% populate the ground truth
groundTruth = zeros(numel( idHyps ), numel( labels ));
% for each hypothesis, create a block annotation struct to use with the
% labelcreator instance
blockAnnotations.srcType.t.onset = [];
blockAnnotations.srcType.t.offset = [];
blockAnnotations.srcType.srcType = {};
for il = 1 : numel( labels )
    ons = onOffsets{il}(:,1);
    offs = onOffsets{il}(:,2);
    labelsExtract = cellfun( @(c)( c{1} ), labels{il}, 'UniformOutput', false );
    blockAnnotations.srcType.t.onset = [blockAnnotations.srcType.t.onset, ons'];
    blockAnnotations.srcType.t.offset = [blockAnnotations.srcType.t.offset, offs'];
    blockAnnotations.srcType.srcType = [blockAnnotations.srcType.srcType; [labelsExtract', repmat( {NaN}, size( labelsExtract' ) )]];
end % labels, onOffsets
for ih = 1:numel(idHyps)
    blockAnnotations.blockOffset =  idHyps(ih).sndTmIdx;
    blockAnnotations.blockOnset = max( 0, ...
                  blockAnnotations.blockOffset - idHyps(ih).data(1).concernsBlocksize_s );
    groundTruth(ih,:) = labeler.labelBlock( blockAnnotations );
end % idHyps

groundTruth(groundTruth == 0) = -1; % from [0, 1] to [-1, 1]

for idl = 1 : numel( idLabels )
    if isfield( idDescisions.(idLabels{idl}) , 'labelIdx' )
        yTrue = groundTruth(:, idDescisions.(idLabels{idl}).labelIdx);
    else
        yTrue = zeros(numel(idHyps), 1) - 1;
    end
    yPred = idDescisions.(idLabels{idl}).y(1:end-1)';
    dpi.loc = idDescisions.(idLabels{idl}).loc(1:end-1)';
    % remove uncertain blocks
    dpi.loc = dpi.loc(~isnan(yTrue));
    yPred = yPred(~isnan(yTrue));
    yTrue = yTrue(~isnan(yTrue));
    perfmeasure = PerformanceMeasures.BAC( yTrue, yPred, dpi );
    disp(idLabels{idl})
    disp(perfmeasure.performance)
    perfs(idl) = perfmeasure;
end
