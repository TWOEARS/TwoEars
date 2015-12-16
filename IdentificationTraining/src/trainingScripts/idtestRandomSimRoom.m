function idtestRandomSimRoom( classname, testFlist, modelPath )

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

sc = dataProcs.SceneConfiguration();
sc.angleSignal = dataProcs.ValGen('random', [0,359.9]);
sc.distSignal = dataProcs.ValGen('random', [0.5,3]);
wall.front = dataProcs.ValGen('random', [3,5]);
wall.back = dataProcs.ValGen('random', [-3,-5]);
wall.right = dataProcs.ValGen('random', [-3,-5]);
wall.left = dataProcs.ValGen('random', [3,5]);
wall.height = dataProcs.ValGen('random', [2,3]);
wall.rt60 = dataProcs.ValGen('random', [1,8]);
sc.addWalls( dataProcs.WallsValGen(wall) );

testpipe.setSceneConfig( [sc] ); 

testpipe.init();
testpipe.pipeline.run( {classname}, 0 );

end
