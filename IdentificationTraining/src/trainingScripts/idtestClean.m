function modelPath = idtestClean( classname, testFlist, modelPath )

testpipe = TwoEarsIdTrainPipe();
m = load( fullfile( modelPath, [classname '.model.mat'] ) );
testpipe.featureCreator = m.featureCreator;
testpipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelPath, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2 ...
        );
testpipe.modelCreator.verbose( 'on' );
testpipe.testset = testFlist;
sc = dataProcs.SceneConfiguration(); % clean
testpipe.setSceneConfig( [sc] ); 
testpipe.init();

modelPath = testpipe.pipeline.run( {classname}, 0 );

end
