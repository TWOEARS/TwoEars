function createTrainTestSplitFlists( inputFlist, outputName, baseDir, nFolds, oneFoldForTrain )

if nargin < 5, oneFoldForTrain = false; end;

allData = core.IdentTrainPipeData();
allData.loadWavFileList( inputFlist );

folds = allData.splitInPermutedStratifiedFolds( nFolds );

for ff = 1 : nFolds
    foldsIdx = 1 : nFolds;
    foldsIdx(ff) = [];
    foldCombi = core.IdentTrainPipeData.combineData( folds{foldsIdx} );
    if oneFoldForTrain
        combiTStr = 'Test';
        oneTStr = 'Train';
    else
        combiTStr = 'Train';
        oneTStr = 'Test';
    end
    foldCombi.saveDataFList( [outputName '_' combiTStr 'Set_' int2str(ff) '.flist'], baseDir );
    folds{ff}.saveDataFList( [outputName '_' oneTStr 'Set_' int2str(ff) '.flist'], baseDir );
end

