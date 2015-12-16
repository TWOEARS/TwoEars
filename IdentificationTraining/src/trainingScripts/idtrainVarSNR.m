function modelPath = idtrainVarSNR( classname, trainFlist, featureCreator, modelTrainer, SNR )

trainpipe = TwoEarsIdTrainPipe();
trainpipe.featureCreator = featureCreator;
trainpipe.modelCreator = modelTrainer;
trainpipe.modelCreator.verbose( 'on' );

trainpipe.trainset = trainFlist;

sc = dataProcs.SceneConfiguration();
sc.angleSignal = dataProcs.ValGen('manual', [0]);
sc.distSignal = dataProcs.ValGen('manual', [3]);
sc.addOverlay( ...
    dataProcs.ValGen('random', [0,359.9]), ...
    dataProcs.ValGen('manual', 3),...
    dataProcs.ValGen('manual', [SNR]), 'diffuse',...
    dataProcs.ValGen('set', {'trainingScripts/noise/whtnoise.wav'}), ...
    dataProcs.ValGen('manual', 0) );
trainpipe.setSceneConfig( [sc] ); 

trainpipe.init();
modelPath = trainpipe.pipeline.run( {classname}, 0 );

end

