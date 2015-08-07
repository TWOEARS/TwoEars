function modelPath = idtrainSimReverb( classname, trainFlist, featureCreator, modelTrainer )

trainpipe = TwoEarsIdTrainPipe();
trainpipe.featureCreator = featureCreator;
trainpipe.modelCreator = modelTrainer;
trainpipe.modelCreator.verbose( 'on' );

trainpipe.trainset = trainFlist;

sc = dataProcs.SceneConfiguration();
sc.angleSignal = dataProcs.ValGen('manual', [0]);
sc.distSignal = dataProcs.ValGen('manual', [2]);
room.lengthX = dataProcs.ValGen('manual', [6]);
room.lengthY = dataProcs.ValGen('manual', [6]);
room.height = dataProcs.ValGen('manual', [2.5]);
room.rt60 = dataProcs.ValGen('manual', [1]);
sc.addRoom( dataProcs.RoomValGen(room) );
trainpipe.setSceneConfig( [sc] ); 

trainpipe.init();
modelPath = trainpipe.pipeline.run( {classname}, 0 );

end

