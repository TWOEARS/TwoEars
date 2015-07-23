function modelPath = idtrainTestClean( classname, trainFlist, testFlist, featureCreator, modelTrainer )

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = featureCreator;
pipe.modelCreator = modelTrainer;
pipe.modelCreator.verbose( 'on' );

pipe.trainset = trainFlist;
pipe.testset = testFlist;

sc = dataProcs.SceneConfiguration(); % clean
pipe.setSceneConfig( [sc] ); 

pipe.init();
modelPath = pipe.pipeline.run( {classname}, 0 );

end
