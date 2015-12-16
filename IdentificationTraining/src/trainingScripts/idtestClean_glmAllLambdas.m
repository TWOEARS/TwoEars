function idtestClean_glmAllLambdas( classname, testFlist, modelPath )

testpipe = TwoEarsIdTrainPipe();
m = load( fullfile( modelPath, [classname '.model.mat'] ) );
testpipe.featureCreator = m.featureCreator;
testpipe.modelCreator = LoadModelNoopTrainer( ...
    @(cn)(fullfile( modelPath, [cn '.model.mat'] )), ...
    'performanceMeasure', @BAC2, ...
    'modelParams', struct('lambda', []) );
testpipe.modelCreator.verbose( 'on' );

testpipe.testset = testFlist;

sc = dataProcs.SceneConfiguration(); % clean
testpipe.setSceneConfig( [sc] ); 

testpipe.init();

testpipe.pipeline.run( {classname}, 0 );

end




