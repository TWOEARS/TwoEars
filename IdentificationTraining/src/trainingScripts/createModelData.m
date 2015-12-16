function createModelData( dataFlist, sceneConfig, featureCreator )

%startTwoEars( '../../IdentificationTraining.xml' );
addpath( '../..' );
startIdentificationTraining();

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = featureCreator;
pipe.modelCreator = modelTrainers.LoadModelNoopTrainer( 'noop' );
pipe.modelCreator.verbose( 'on' );

pipe.data = dataFlist;
pipe.trainsetShare = 1;
pipe.setupData();

if isempty( sceneConfig )
    sceneConfig = sceneConfig.SceneConfiguration();
end
pipe.setSceneConfig( sceneConfig ); 

pipe.init();
pipe.pipeline.run( {'donttrain'}, 0 );

