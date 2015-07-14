classdef IdentificationTrainingPipeline < handle

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        trainer;
        generalizationPerfomanceAssessCVtrainer;
        dataPipeProcs;
        gatherFeaturesProc;
        data;       
        trainSet;
        testSet;
    end
    
    %% --------------------------------------------------------------------
    properties 
        featureCreator;
        verbose = true;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods
        
        %% Constructor.
        function obj = IdentificationTrainingPipeline()
            obj.dataPipeProcs = {};
        end
        %% ------------------------------------------------------------------------------- 
        
        %   -----------------------
        %   setting up the pipeline
        %   -----------------------
        function addModelCreator( obj, trainer )
            if ~isa( trainer, 'IdTrainerInterface' )
                error( 'ModelCreator must be of type IdTrainerInterface.' );
            end
            obj.trainer = trainer;
            obj.generalizationPerfomanceAssessCVtrainer = CVtrainer( obj.trainer );
        end
        %% ------------------------------------------------------------------------------- 
        
        function addDataPipeProc( obj, dataProc )
            if ~isa( dataProc, 'IdProcInterface' )
                error( 'dataProc must be of type IdProcInterface.' );
            end
            dataPipeProc = DataPipeProc( dataProc ); 
            dataPipeProc.connectData( obj.data );
            obj.dataPipeProcs{end+1} = dataPipeProc;
        end
        %% ------------------------------------------------------------------------------- 
        
        function addGatherFeaturesProc( obj, gatherFeaturesProc )
            gatherFeaturesProc.connectData( obj.data );
            obj.gatherFeaturesProc = gatherFeaturesProc;
        end
        %% ------------------------------------------------------------------------------- 
        
        %   -------------------
        %   setting up the data
        %   -------------------
        function connectData( obj, data )
            obj.data = data;
        end
        %% ------------------------------------------------------------------------------- 
        
        function splitIntoTrainAndTestSets( obj, trainSetShare )
            [obj.trainSet, obj.testSet] = obj.data.getShare( trainSetShare );
        end
        %% ------------------------------------------------------------------------------- 
        
        %   --------------------
        %   running the pipeline
        %   --------------------

        %% function run( obj, models, trainSetShare, nGenAssessFolds )
        %       Runs the pipeline, creating the models specified in models
        %       All models trained in one run use the same training and
        %       test sets.
        %
        %   models: 'all' for all training data classes (but not 'general')
        %           cell array of strings with model names for particular
        %           set of models
        %   trainSetShare:  value between 0 and 1. testSet gets share of
        %                   1 - trainSetShare.
        %   nGenAssessFolds: number of folds of generalization assessment cross validation
        %
        function modelPath = run( obj, models, nGenAssessFolds )
            cleaner = onCleanup( @() obj.finish() );
            modelPath = obj.createFilesDir();
            
            if strcmpi( models, 'all' )
                models = obj.data.classNames;
                models(strcmp('general', models)) = [];
            end

            for ii = 1 : length( obj.dataPipeProcs )
                if ii > 1
                    obj.dataPipeProcs{ii}.connectToOutputFrom( obj.dataPipeProcs{ii-1} );
                end
                obj.dataPipeProcs{ii}.run();
            end
            
            if strcmp(models{1}, 'donttrain'), return; end;
            
            obj.gatherFeaturesProc.connectToOutputFrom( obj.dataPipeProcs{end} );
            obj.gatherFeaturesProc.run();

            for modelName = models
                fprintf( ['\n\n===================================\n',...
                              '##   Training model "%s"\n',...
                              '===================================\n\n'], modelName{1} );
                if nGenAssessFolds > 1
                    fprintf( '\n==  Generalization performance assessment CV...\n\n' );
                    obj.generalizationPerfomanceAssessCVtrainer.setNumberOfFolds( nGenAssessFolds );
                    obj.generalizationPerfomanceAssessCVtrainer.setData( obj.trainSet );
                    obj.generalizationPerfomanceAssessCVtrainer.setPositiveClass( modelName{1} );
                    obj.generalizationPerfomanceAssessCVtrainer.run();
                    genPerfCVresults = obj.generalizationPerfomanceAssessCVtrainer.getPerformance();
                    fprintf( '\n==  Performance after generalization assessment CV:\n' );
                    disp( genPerfCVresults );
                end
                obj.trainer.setData( obj.trainSet, obj.testSet );
                obj.trainer.setPositiveClass( modelName{1} );
                fprintf( '\n==  Training model on trainSet...\n\n' );
                tic;
                obj.trainer.run();
                trainTime = toc;
                if ~isempty( obj.testSet )
                    fprintf( '\n==  Testing model on testSet... \n\n' );
                    testPerfresults = obj.trainer.getPerformance();
                    if numel( testPerfresults ) == 1
                        fprintf( ['\n\n===================================\n',...
                            '##   "%s" Performance: %f\n',...
                            '===================================\n\n'], ...
                            modelName{1}, testPerfresults.double() );
                    else
                        fprintf( ['\n\n===================================\n',...
                            '##   "%s" Performance: more than one value\n',...
                            '===================================\n\n'], ...
                            modelName{1} );
                    end
                else
                    testPerfresults = [];
                end
                model = obj.trainer.getModel();
                featureCreator = obj.featureCreator;
                modelFileExt = ['.model.mat'];
                modelFilename = [modelName{1} modelFileExt];
                lastDataProcParams = obj.dataPipeProcs{end}.getOutputDependencies();
                save( modelFilename, ...
                      'model', 'featureCreator', ...
                      'testPerfresults', 'trainTime', 'lastDataProcParams' );
            end;
        end
        
        %% -------------------------------------------------------------------------------
        
        function finish( obj )    
            diary off;
            cd( '..' );
        end
        %% -------------------------------------------------------------------------------

        function path = createFilesDir( obj )
            curTimeStr = buildCurrentTimeString();
            saveDir = ['Training' curTimeStr];
            mkdir( saveDir );
            cd( saveDir );
            path = pwd;
            diary( ['IdTrainPipe' curTimeStr '.log'] );
            obj.trainSet.saveDataFList( ['trainSet' curTimeStr '.flist'] );
            if ~isempty( obj.testSet )
                obj.testSet.saveDataFList( ['testSet' curTimeStr '.flist'] );
            end
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end

