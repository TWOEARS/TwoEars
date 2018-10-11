function createTrainTestSplitFlists( inputFlist, outputName, baseDir, nFolds, oneFoldForTrain )

if nargin < 5, oneFoldForTrain = false; end;

allData = Core.IdentTrainPipeData();
allData.loadFileList( inputFlist );

folds = allData.splitInPermutedStratifiedFolds( nFolds );

for ff = 1 : nFolds
    foldsIdx = 1 : nFolds;
    foldsIdx(ff) = [];
    foldCombi = Core.IdentTrainPipeData.combineData( folds{foldsIdx} );
    if oneFoldForTrain
        combiTStr = 'Test';
        oneTStr = 'Train';
    else
        combiTStr = 'Train';
        oneTStr = 'Test';
    end
    foldCombi.saveFList( [outputName '_' combiTStr 'Set_' int2str(ff) '.flist'], baseDir );
    folds{ff}.saveFList( [outputName '_' oneTStr 'Set_' int2str(ff) '.flist'], baseDir );
end

