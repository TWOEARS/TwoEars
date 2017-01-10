classdef TwoEarsIdTrainPipe < handle
    % TwoEarsIdTrainPipe Two!Ears identification training pipeline wrapper
    %   This wraps around the Two!Ears identification training pipeline
    %   which facilitates training models for classifying sounds.
    %   It manages the data for training and testing, drives the binaural
    %   simulator, orchestrates feature extraction, optimizes the model and
    %   produces performance metrics for evaluating a model.
    %   Trained models can then be integrated into the blackboard system
    %   by loading them in an identitiy knowledge source
    %
    %   The train and test can be specified individually or the data is
    %   provided to be split by the pipeline
    %
    %% --------------------------------------------------------------------
    properties (SetAccess = public)
        blockCreator = [];      % (default: BlockCreators.MeanStandardBlockCreator( 1.0, 0.4 ))
        labelCreator = [];
        ksWrapper = [];
        featureCreator = [];    % feature extraction (default: featureCreators.RatemapPlusDeltasBlockmean())
        modelCreator = [];      % model trainer
        trainset = [];          % file list with train examples
        testset = [];           % file list with test examples
        data = [];              % list of files to split in train and test
        trainsetShare = 0.5;
        checkFileExistence = true;
    end
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        pipeline;
        dataSetupAlreadyDone = false;   % pre-processing steps already done.
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = TwoEarsIdTrainPipe( varargin )
            % TwoEarsIdTrainPipe Construct a training pipeline
            %   TwoEarsIdTrainPipe() instantiate using the default cache-
            %   system and sound-db base directories
            %
            ip = inputParser;
            ip.addOptional( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
            ip.addOptional( 'nPathLevelsForCacheName', 3 );
            ip.parse( varargin{:} );
            ModelTrainers.Base.featureMask( true, [] ); % reset the feature mask
            fprintf( '\nmodelTrainers.Base.featureMask set to []\n' );
            obj.pipeline = Core.IdentificationTrainingPipeline( ...
                                          'cacheSystemDir', ip.Results.cacheSystemDir, ...
                                          'nPathLevelsForCacheName', ip.Results.nPathLevelsForCacheName );
            obj.dataSetupAlreadyDone = false;
        end
        %% -------------------------------------------------------------------------------
        
        function init( obj, sceneCfgs, varargin )
            % init initialize training pipeline
            %   init() init using the default impulse
            %   response dataset to drive the binaural simulator
            %   init( sceneCfgs, 'hrir', hrir ) instantiate using a path to the 
            %   impulse response dataset defined by hrir
            %   (e.g. 'impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa'
            %   
            ip = inputParser;
            ip.addOptional( 'hrir', ...
                            'impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa' );
            ip.addOptional( 'sceneCfgDataUseRatio', 1 );
            ip.addOptional( 'gatherFeaturesProc', true );
            ip.addOptional( 'stopAfterProc', inf );
            ip.addOptional( 'fs', 44100 );
            ip.parse( varargin{:} );
            obj.setupData( true );
            obj.pipeline.resetDataProcs();
            binSim = DataProcs.SceneEarSignalProc( DataProcs.IdSimConvRoomWrapper( ...
                                                       ip.Results.hrir, ip.Results.fs ) );
            if isempty( obj.blockCreator )
                obj.blockCreator = BlockCreators.MeanStandardBlockCreator( 1.0, 0.4 );
            end
            obj.pipeline.blockCreator = obj.blockCreator;
            if isempty( obj.labelCreator )
                error( 'Please specify labelCreator(s).' );
            end
            if isempty( obj.featureCreator )
                obj.featureCreator = FeatureCreators.FeatureSet1Blockmean();
            end
            afeReqs = obj.featureCreator.getAFErequests();
            if ~isempty( obj.ksWrapper )
                obj.ksWrapper.setAfeDataIndexOffset( numel( afeReqs ) );
                afeReqs = [afeReqs obj.ksWrapper.getAfeRequests];
            end
            obj.pipeline.featureCreator = obj.featureCreator;
            multiCfgProcs{1} = DataProcs.MultiSceneCfgsIdProcWrapper( binSim, binSim );
            multiCfgProcs{2} = DataProcs.MultiSceneCfgsIdProcWrapper( ...
                     binSim, ...
                     DataProcs.ParallelRequestsAFEmodule( binSim.getDataFs(), afeReqs ) );
            multiCfgProcs{end+1} =  ...
                        DataProcs.MultiSceneCfgsIdProcWrapper( binSim, obj.blockCreator );
            if ~isempty( obj.ksWrapper )
                multiCfgProcs{end+1} =  ...
                           DataProcs.MultiSceneCfgsIdProcWrapper( binSim, obj.ksWrapper );
            end
            multiCfgProcs{end+1} =  ...
                      DataProcs.MultiSceneCfgsIdProcWrapper( binSim, obj.featureCreator );
            multiCfgProcs{end+1} =  ...
                        DataProcs.MultiSceneCfgsIdProcWrapper( binSim, obj.labelCreator );
            if ip.Results.gatherFeaturesProc
                gatherFeaturesProc = DataProcs.GatherFeaturesProc();
                gatherFeaturesProc.setSceneCfgDataUseRatio( ip.Results.sceneCfgDataUseRatio );
                multiCfgProcs{end+1} = DataProcs.MultiSceneCfgsIdProcWrapper( ...
                                                             binSim, gatherFeaturesProc );
            end
            for ii = 1 : min( numel( multiCfgProcs ), ip.Results.stopAfterProc )
                multiCfgProcs{ii}.setSceneConfig( sceneCfgs );
                obj.pipeline.addDataPipeProc( multiCfgProcs{ii} );
            end
            if isempty( obj.modelCreator )
                obj.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
                    'performanceMeasure', @performanceMeasures.BAC2, ...
                    'cvFolds', 4, ...
                    'alpha', 0.99 );
            end
            obj.pipeline.addModelCreator( obj.modelCreator );
        end
        %% -------------------------------------------------------------------------------

        function set.trainset( obj, newTrainset )
            obj.dataSetupAlreadyDone = strcmp(obj.trainset,newTrainset);
            obj.trainset = newTrainset;
        end
        %% -------------------------------------------------------------------------------

        function set.testset( obj, newTestset )
            obj.dataSetupAlreadyDone = strcmp(obj.testset,newTestset);
            obj.testset = newTestset;
        end
        %% -------------------------------------------------------------------------------

        function set.data( obj, newData )
            % set the data to be split into train and test set by the
            % pipeline
            obj.dataSetupAlreadyDone = strcmp(obj.data,newData);
            obj.data = newData;
        end
        %% -------------------------------------------------------------------------------

        function setupData( obj, skipIfAlreadyDone )
            % setupData set up the train and test set and perform a
            % train/test split on the data if not already specified.
            if nargin > 1 && skipIfAlreadyDone && obj.dataSetupAlreadyDone
                return;
            end
            if ~isempty( obj.trainset ) || ~isempty( obj.testset )
                trainSet = Core.IdentTrainPipeData();
                trainSet.loadFileList( obj.trainset, obj.checkFileExistence );
                obj.pipeline.setTrainData( trainSet );
                testSet = Core.IdentTrainPipeData();
                testSet.loadFileList( obj.testset, obj.checkFileExistence );
                obj.pipeline.setTestData( testSet );
            else
                data = Core.IdentTrainPipeData();
                data.loadFileList( obj.data, obj.checkFileExistence );
                obj.pipeline.connectData( data );
                obj.pipeline.splitIntoTrainAndTestSets( obj.trainsetShare );
            end
            obj.dataSetupAlreadyDone = true;
        end
        %% -------------------------------------------------------------------------------
        
    end

end
