function modelPath = idtrainClean( classname, trainFlist, featureCreator, modelTrainer )

trainpipe = TwoEarsIdTrainPipe();
trainpipe.featureCreator = featureCreator;
trainpipe.modelCreator = modelTrainer;
trainpipe.modelCreator.verbose( 'on' );
trainpipe.trainset = trainFlist;
sc = dataProcs.SceneConfiguration(); % clean
trainpipe.setSceneConfig( [sc] ); 
trainpipe.init();

modelPath = trainpipe.pipeline.run( {classname}, 0 );

end

