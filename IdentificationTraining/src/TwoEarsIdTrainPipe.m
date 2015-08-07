classdef TwoEarsIdTrainPipe < handle

    %% -----------------------------------------------------------------------------------
    properties (SetAccess = public)
        featureCreator;
        modelCreator;
        trainset = [];
        testset = [];
        data = [];
        trainsetShare = 0.5;
    end
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        pipeline;
        binauralSim;
        multiConfBinauralSim;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = TwoEarsIdTrainPipe()
            obj.pipeline = core.IdentificationTrainingPipeline();
            obj.binauralSim = dataProcs.IdSimConvRoomWrapper();
            obj.multiConfBinauralSim = ...
                dataProcs.MultiConfigurationsEarSignalProc( obj.binauralSim );
            obj.setSceneConfig( dataProcs.SceneConfiguration() );
            obj.featureCreator = featureCreators.RatemapPlusDeltasBlockmean();
            obj.modelCreator = modelTrainers.GlmNetLambdaSelectTrainer( ...
                'performanceMeasure', @performanceMeasures.BAC2, ...
                'cvFolds', 4, ...
                'alpha', 0.99 );
            obj.init();
        end
        %% -------------------------------------------------------------------------------

        function setSceneConfig( obj, scArray )
            obj.multiConfBinauralSim.setSceneConfig( scArray );
        end
        %% -------------------------------------------------------------------------------
        
        function init( obj )
            obj.setupData();
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
            obj.pipeline.addModelCreator( obj.modelCreator );
        end
        %% -------------------------------------------------------------------------------

        function setupData( obj )
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
        end
        %% -------------------------------------------------------------------------------
        
    end

end
