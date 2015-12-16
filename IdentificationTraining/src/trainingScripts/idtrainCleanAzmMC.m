function modelPath = idtrainCleanAzmMC( classname, trainFlist, featureCreator, modelTrainer )

trainpipe = TwoEarsIdTrainPipe();
trainpipe.featureCreator = featureCreator;
trainpipe.modelCreator = modelTrainer;
trainpipe.modelCreator.verbose( 'on' );

trainpipe.trainset = trainFlist;

sc1 = dataProcs.SceneConfiguration();
sc1.angleSignal = ValGen('manual', 0);
sc2 = dataProcs.SceneConfiguration();
sc2.angleSignal = ValGen('manual', 45);
sc3 = dataProcs.SceneConfiguration();
sc3.angleSignal = ValGen('manual', 90);
sc4 = dataProcs.SceneConfiguration();
sc4.angleSignal = ValGen('manual', 135);
sc5 = dataProcs.SceneConfiguration();
sc5.angleSignal = ValGen('manual', 180);
trainpipe.setSceneConfig( [sc1,sc2,sc3,sc4,sc5] ); 

trainpipe.init();
modelPath = trainpipe.pipeline.run( {classname}, 0 );

end

