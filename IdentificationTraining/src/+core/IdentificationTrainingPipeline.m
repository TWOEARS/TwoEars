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
            obj.data = core.IdentTrainPipeData();
            obj.trainSet = core.IdentTrainPipeData();
            obj.testSet = core.IdentTrainPipeData();
        end
        %% ------------------------------------------------------------------------------- 
        
        %   -----------------------
        %   setting up the pipeline
        %   -----------------------

        function addModelCreator( obj, trainer )
            if ~isa( trainer, 'modelTrainers.Base' )
                error( 'ModelCreator must be of type modelTrainers.Base' );
            end
            obj.trainer = trainer;
            obj.generalizationPerfomanceAssessCVtrainer = modelTrainers.CVtrainer( obj.trainer );
        end
        %   -------------------
        
        function resetDataProcs( obj )
            obj.dataPipeProcs = {};
        end
        %   -------------------

        function addDataPipeProc( obj, dataProc )
            if ~isa( dataProc, 'core.IdProcInterface' )
                error( 'dataProc must be of type core.IdProcInterface.' );
            end
            dataPipeProc = core.DataPipeProc( dataProc ); 
            dataPipeProc.init();
            dataPipeProc.connectData( obj.data );
            obj.dataPipeProcs{end+1} = dataPipeProc;
        end
        %   -------------------
        
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
        %   -------------------

        function setTrainData( obj, trainData )
            obj.trainSet = trainData;
            obj.data = core.IdentTrainPipeData.combineData( obj.trainSet, obj.testSet );
        end
        %   -------------------
        
        function setTestData( obj, testData )
            obj.testSet = testData;
            obj.data = core.IdentTrainPipeData.combineData( obj.trainSet, obj.testSet );
        end
        %   -------------------
        
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
            end
            for ii = length( obj.dataPipeProcs ) : -1 : 1
                if ii == length( obj.dataPipeProcs )
                    obj.dataPipeProcs{ii}.checkDataFiles();
                else
                    obj.dataPipeProcs{ii}.checkDataFiles(obj.dataPipeProcs{ii+1}.fileListOverlay);
                end
            end
            for ii = 1 : length( obj.dataPipeProcs )
                obj.dataPipeProcs{ii}.run();
            end
            
            if strcmp(models{1}, 'donttrain'), return; end;
            
            obj.gatherFeaturesProc.connectToOutputFrom( obj.dataPipeProcs{end} );
            obj.gatherFeaturesProc.run();

            featureCreator = obj.featureCreator;
            if isempty( featureCreator.description )
                dummyData = obj.data(1,1);
                dummyInput = obj.dataPipeProcs{end}.inputFileNameBuilder( dummyData.wavFileName );
                in = load( dummyInput );
                obj.dataPipeProcs{end}.dataFileProcessor.featProc.process( in.singleConfFiles{1} );
            end
            lastDataProcParams = obj.dataPipeProcs{end}.getOutputDependencies();
            if strcmp(models{1}, 'dataStore')
                data = obj.data;
                save( 'dataStore.mat', ...
                      'data', 'featureCreator', 'lastDataProcParams' );
                return; 
            elseif strcmp(models{1}, 'dataStoreUni')
                x = obj.data(:,:,'x');
                classnames = obj.data.classNames;
                featureNames = obj.featureCreator.description;
                for ii = 1 : length( classnames )
                    y(:,ii) = obj.data(:,:,'y', classnames{ii});
                end
                save( 'dataStoreUni.mat', ...
                      'x', 'y', 'classnames', 'featureNames' );
                return; 
            end;
            
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
                testTime = nan;
                testPerfresults = [];
                if ~isempty( obj.testSet )
                    fprintf( '\n==  Testing model on testSet... \n\n' );
                    tic;
                    testPerfresults = obj.trainer.getPerformance();
                    testTime = toc;
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
                end
                model = obj.trainer.getModel();
                modelFileExt = ['.model.mat'];
                modelFilename = [modelName{1} modelFileExt];
                save( modelFilename, ...
                      'model', 'featureCreator', ...
                      'testPerfresults', 'trainTime', 'testTime', 'lastDataProcParams' );
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
            obj.trainSet.saveDataFList( ['trainSet' curTimeStr '.flist'], 'sound_databases' );
            if ~isempty( obj.testSet )
                obj.testSet.saveDataFList( ['testSet' curTimeStr '.flist'], 'sound_databases' );
            end
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end

