classdef TwoEarsIdTrainPipe < handle

    %% -----------------------------------------------------------------------------------
    properties (SetAccess = public)
        featureCreator = [];
        modelCreator = [];
        trainset = [];
        testset = [];
        data = [];
        trainsetShare = 0.5;
    end
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        pipeline;
        binauralSim;
        sceneConfBinauralSim;
        multiConfBinauralSim;
        dataSetupAlreadyDone = false;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = TwoEarsIdTrainPipe()
            modelTrainers.Base.featureMask( true, [] );
            warning( 'modelTrainers.Base.featureMask set to []' );
            obj.pipeline = core.IdentificationTrainingPipeline();
            obj.binauralSim = dataProcs.IdSimConvRoomWrapper();
            obj.sceneConfBinauralSim = ...
                dataProcs.SceneEarSignalProc( obj.binauralSim );
            obj.multiConfBinauralSim = ...
                dataProcs.MultiConfigurationsEarSignalProc( obj.sceneConfBinauralSim );
%             obj.init();
            obj.dataSetupAlreadyDone = false;
        end
        %% -------------------------------------------------------------------------------

        function setSceneConfig( obj, scArray )
            obj.multiConfBinauralSim.setSceneConfig( scArray );
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
            obj.dataSetupAlreadyDone = strcmp(obj.data,newData);
            obj.data = newData;
        end
        %% -------------------------------------------------------------------------------
        
        function init( obj )
            obj.setupData( true );
            if isempty( obj.featureCreator )
                obj.featureCreator = featureCreators.RatemapPlusDeltasBlockmean();
            end
            obj.pipeline.featureCreator = obj.featureCreator;
            obj.pipeline.resetDataProcs();
            obj.pipeline.addDataPipeProc( obj.multiConfBinauralSim );
            obj.pipeline.addDataPipeProc( ...
                dataProcs.MultiConfigurationsAFEmodule( ...
                    dataProcs.AuditoryFEmodule( ...
                        obj.binauralSim.getDataFs(), obj.featureCreator.getAFErequests() ...
                        ) ) );
            obj.pipeline.addDataPipeProc( ...
                dataProcs.MultiConfigurationsFeatureProc( obj.featureCreator ) );
            obj.pipeline.addGatherFeaturesProc( core.GatherFeaturesProc() );
            if isempty( obj.modelCreator )
                obj.modelCreator = modelTrainers.GlmNetLambdaSelectTrainer( ...
                    'performanceMeasure', @performanceMeasures.BAC2, ...
                    'cvFolds', 4, ...
                    'alpha', 0.99 );
            end
            obj.pipeline.addModelCreator( obj.modelCreator );
        end
        %% -------------------------------------------------------------------------------

        function setupData( obj, skipIfAlreadyDone )
            if nargin > 1 && skipIfAlreadyDone && obj.dataSetupAlreadyDone
                return;
            end
            if ~isempty( obj.trainset ) || ~isempty( obj.testset )
                trainSet = core.IdentTrainPipeData();
                trainSet.loadWavFileList( obj.trainset );
                obj.pipeline.setTrainData( trainSet );
                testSet = core.IdentTrainPipeData();
                testSet.loadWavFileList( obj.testset );
                obj.pipeline.setTestData( testSet );
            else
                data = core.IdentTrainPipeData();
                data.loadWavFileList( obj.data );
                obj.pipeline.connectData( data );
                obj.pipeline.splitIntoTrainAndTestSets( obj.trainsetShare );
            end
            obj.dataSetupAlreadyDone = true;
        end
        %% -------------------------------------------------------------------------------
        
    end

end
