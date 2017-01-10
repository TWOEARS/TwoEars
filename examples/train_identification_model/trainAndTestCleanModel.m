function trainAndTestCleanModel( classname )
%trainAndTestCleanModel This function provides an example of training a
% sound type identification model for a single sound type using the
% the Auditory Machine Learning Trainign and Testing Pipeline
%
% The function will set up the pipeline to:
% - Configuring auditory scenes where a single sound source is active
% - Simulating ambient sounds
% - Extract block-based features from the auditory representations
% - Labeling each block by assigning it either to the target sound or use them
%   as a negative example during training (the sound type is retrieved from the
%   originating sound file name)
% - Define a model and configure the training procedure
% - Perform the training
% - Repeat the above (without training) on a different set of sound files 
%   in order to evaluate the trained model.
% 
if nargin < 1, classname = 'speech'; end;


cacheSystemDir = fullfile(getMFilePath(), '..', 'idPipeCache');
if ~exist(cacheSystemDir, 'dir')
    mkdir('../idPipeCache')
    if ~exist(cacheSystemDir, 'dir')
    error(['The cache directory required by the pipeline for saving intermediate data ', ...
        'does not exist and could not be created. Please create it and run the script again.']);
    end
end
pipe = TwoEarsIdTrainPipe('cacheSystemDir', cacheSystemDir);
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 0.5, 0.5/3 );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
% <classname> will be 1, rest -1
oneVsRestLabeler = LabelCreators.MultiEventTypeLabeler( ...
                                     'types', {{classname}}, 'negOut', 'rest' );
pipe.labelCreator = oneVsRestLabeler;
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 ); % giving higher numerical stability (instead of 1.0)
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_80pTrain_TrainSet_1.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
                          'data', SceneConfig.FileListValGen( 'pipeInput' ) ) );
            
fprintf( ['\nThe pipeline will now initialise, this may involve downloading'...
    ' the training and testing sound files from the online Two!Ears-database, if '...
    'you don''t have a local copy of it and are running this example for the '...
    'first time.\nPress key to continue\n'] );
pause
pipe.init( sc, 'fs', 16000 );

fprintf( ['\nThe pipeline is now ready to run. The first time doing so, the processing'...
    ' through binaural simulation, auditory front-end and feature creation '...
    'will take some time. However, you can abort any time - when restarting, '...
    'the pipeline will load the intermediate results (it saves them for this '...
    'reason) and go on at the point where you aborted before. All subsequent '...
    'runs will take much shorter time, as only the actual model training will '...
    'have to be done.\n'...
    'Warnings about missing label annotation files for voidxx.wav sounds '...
    'and non-existent cache-directories (if run the first time) are '...
    'features, not bugs. '...
    '\nPress key to continue\n'] );
pause
modelPath = pipe.pipeline.run( 'modelName', classname, ...
                               'modelPath', 'test_1vsAll_training' );

fprintf( ' -- Model is saved at %s -- \n', modelPath );

fprintf( ['\nAfter model training, test data for evaluating the model will '...
          'now be generated. This involves the same steps as before, apart '...
          'from training, which is replaced by testing. '...
          '\nPress key to continue\n'] );
pause
pipe = TwoEarsIdTrainPipe('cacheSystemDir', cacheSystemDir);
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 0.5, 0.5/3 );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
% <classname> will be 1, rest -1
oneVsRestLabeler = LabelCreators.MultiEventTypeLabeler( ...
                                     'types', {{classname}}, 'negOut', 'rest' );
pipe.labelCreator = oneVsRestLabeler;
pipe.modelCreator = ...
    ModelTrainers.LoadModelNoopTrainer( ...
        fullfile( modelPath, [classname '.model.mat'] ), ...
        'performanceMeasure', @PerformanceMeasures.BAC,...
        'maxDataSize', inf ...
        ); % we trained with BAC2, but test with BAC.

pipe.trainset = [];
pipe.testset = 'learned_models/IdentityKS/trainTestSets/IEEE_AASP_80pTrain_TestSet_1.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
                          'data', SceneConfig.FileListValGen( 'pipeInput' ) ) );
pipe.init( sc, 'fs', 16000 );

modelPath = pipe.pipeline.run( 'modelName', classname, 'modelPath', 'test_1vsAll_testing' );

fprintf( ' -- Test is saved at %s -- \n', modelPath );

