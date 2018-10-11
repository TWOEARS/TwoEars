classdef IdentificationTrainingPipeline < handle
    % IdentificationTrainingPipeline The identification training pipeline
    %   facilitates training models for classifying sounds.
    %   It manages the data for training and testing, orchestrates feature
    %   extraction, optimizes the model and produces performance metrics 
    %   for evaluating a model.
    %   Trained models can then be integrated into the blackboard system
    %   by loading them in an identitiy knowledge source
    %
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        trainer;
        generalizationPerfomanceAssessCVtrainer; % k-fold cross validation
        dataPipeProcs;
        data;       
        trainSet;
        testSet;
        cacheSystemDir;
        nPathLevelsForCacheName;
    end
    
    %% -----------------------------------------------------------------------------------
    properties 
        blockCreator;
        featureCreator; % feature extraction
        verbose = true; % log level
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = IdentificationTrainingPipeline( varargin )
            ip = inputParser;
            ip.addOptional( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
            ip.addOptional( 'nPathLevelsForCacheName', 3 );
            ip.parse( varargin{:} );
            obj.cacheSystemDir = ip.Results.cacheSystemDir;
            obj.nPathLevelsForCacheName = ip.Results.nPathLevelsForCacheName;
            obj.dataPipeProcs = {};
            obj.data = Core.IdentTrainPipeData();
            obj.trainSet = Core.IdentTrainPipeData();
            obj.testSet = Core.IdentTrainPipeData();
        end
        %% ------------------------------------------------------------------------------- 
        
        function addModelCreator( obj, trainer )
            if ~isa( trainer, 'ModelTrainers.Base' )
                error( 'ModelCreator must be of type ModelTrainers.Base' );
            end
            obj.trainer = trainer;
            obj.generalizationPerfomanceAssessCVtrainer = ModelTrainers.CVtrainer( obj.trainer );
        end
        %% ------------------------------------------------------------------------------- 
        
        function resetDataProcs( obj )
            obj.dataPipeProcs = {};
        end
        %% ------------------------------------------------------------------------------- 

        function addDataPipeProc( obj, idProc )
            if ~isa( idProc, 'Core.IdProcInterface' )
                error( 'idProc must be of type Core.IdProcInterface.' );
            end
            idProc.setCacheSystemDir( obj.cacheSystemDir, obj.nPathLevelsForCacheName );
            idProc.connectIdData( obj.data );
            dataPipeProc = Core.DataPipeProc( idProc ); 
            dataPipeProc.init();
            dataPipeProc.connectData( obj.data );
            obj.dataPipeProcs{end+1} = dataPipeProc;
            if numel( obj.dataPipeProcs ) > 1
                obj.dataPipeProcs{end}.connectToOutputFrom( obj.dataPipeProcs{end-1} );
            end
        end
        %% ------------------------------------------------------------------------------- 
        
        function connectData( obj, data )
            obj.data = data;
        end
        %% ------------------------------------------------------------------------------- 

        function setTrainData( obj, trainData )
            obj.trainSet = trainData;
            obj.data = Core.IdentTrainPipeData.combineData( obj.trainSet, obj.testSet );
        end
        %% ------------------------------------------------------------------------------- 
        
        function setTestData( obj, testData )
            obj.testSet = testData;
            obj.data = Core.IdentTrainPipeData.combineData( obj.trainSet, obj.testSet );
        end
        %% ------------------------------------------------------------------------------- 
        
        function splitIntoTrainAndTestSets( obj, trainSetShare )
            [obj.trainSet, obj.testSet] = obj.data.getShare( trainSetShare );
        end
        %% ------------------------------------------------------------------------------- 
        
        %% function run( obj, modelname, nGenAssessFolds )
        %       Runs the pipeline, creating the models specified in models
        %       All models trained in one run use the same training and
        %       test sets.
        %
        %   modelName: name for model. default: 'amlttp.model.mat'
        %   modelPath: path where to store model. default: 'amlttpRun.<curTimeString>'
        %   runOption:
        %                'onlyGenCache' stops after data processing
        %                'dataStore' saves data in native format
        %                'dataStoreUni' saves data as x,y matrices
        %   nGenAssessFolds: number of folds of generalization assessment through
        %                    cross validation (default: 0 - no folds)
        %
        function [modelPath, model, testPerfresults] = run( obj, varargin )
            ip = inputParser;
            ip.addOptional( 'nGenAssessFolds', 0 );
            ip.addOptional( 'modelPath', ['amlttpRun' buildCurrentTimeString()] );
            ip.addOptional( 'modelName', 'amlttp' );
            ip.addOptional( 'runOption', [] );
            ip.addOptional( 'startWithProc', 1 );
            ip.addOptional( 'filterPipeInput', [] );
            ip.addOptional( 'debug', false );
            ip.parse( varargin{:} );
            
            cleaner = onCleanup( @() obj.finish() );
            modelPath = obj.createFilesDir( ip.Results.modelPath );
            modelFilename = [ip.Results.modelName '.model.mat'];
            testPerfresults = [];
            model = [];
            
            successiveProcFileFilter = ip.Results.filterPipeInput;
            gcpMode = strcmpi( ip.Results.runOption, 'getCachePathes' );
            rwcMode = strcmpi( ip.Results.runOption, 'rewriteCache' );
            if rwcMode
                Core.IdProcInterface.forceCacheRewrite( true );
            else
                Core.IdProcInterface.forceCacheRewrite( false );
            end
            cacheDirs = cell( numel( obj.dataPipeProcs ), 1 );
            for ii = numel( obj.dataPipeProcs ) : -1 : ip.Results.startWithProc
                if ~gcpMode
                    obj.dataPipeProcs{ii}.checkDataFiles( successiveProcFileFilter );
                else
                    gcpFileFilter = false( length( obj.data(:) ), 1 );
                    gcpFileFilter(1) = true;
                    cacheDirs{ii} = obj.dataPipeProcs{ii}.checkDataFiles( gcpFileFilter );
                end
                if ~gcpMode && ~rwcMode
                    successiveProcFileFilter = obj.dataPipeProcs{ii}.fileListOverlay;
                end
            end
            if gcpMode
                save( modelFilename, ...
                      'cacheDirs' );
                return;
            end
            errs = {};
            for ii = ip.Results.startWithProc : numel( obj.dataPipeProcs )
                if ~ip.Results.debug
                    try
                        obj.dataPipeProcs{ii}.run();
                    catch err
                        if any( strcmpi( err.identifier, ...
                                {'AMLTTP:dataprocs:fileErrors'} ...
                                ) )
                            errs{end+1} = err;
                            warning( err.message );
                        else
                            rethrow( err );
                        end
                    end
                else
                    obj.dataPipeProcs{ii}.run( 'debug', true );
                end
            end
            if numel( errs ) > 0
                cellfun(@(c)(warning(c.message)), errs);
                error( 'PipeProcError(s)' );
            end
            
            if strcmp(ip.Results.runOption, 'onlyGenCache'), return; end;
            if rwcMode, return; end;
            
            featureCreator = obj.featureCreator;
            lastDataProcParams = ...
                obj.dataPipeProcs{end}.dataFileProcessor.getOutputDependencies();
            blockCreator = obj.blockCreator;
            if strcmp( ip.Results.runOption, 'dataStore' )
                data = obj.data;
                save( 'dataStore.mat', ...
                      'data', ...,
                      'featureCreator', 'blockCreator', ...
                      'lastDataProcParams', '-v7.3' );
                return; 
            elseif strcmp( ip.Results.runOption, 'dataStoreUni' )
                x = obj.data(:,'x');
                y = obj.data(:,'y');
                featureNames = obj.featureCreator.description;
                save( 'dataStoreUni.mat', ...
                      'x', 'y', 'featureNames', '-v7.3' );
                return; 
            elseif strcmp( ip.Results.runOption, 'dataStoreGT' )
                bIdxs = obj.data(:,'bIdxs');
                y = obj.data(:,'y');
                save( 'dataStoreGT.mat', ...
                      'bIdxs', 'y', '-v7.3' );
                return; 
            end;
            
            fprintf( ['\n\n===================================\n',...
                          '##   Training model "%s"\n',...
                          '===================================\n\n'], ip.Results.modelName );
            if ip.Results.nGenAssessFolds > 1
                fprintf( '\n==  Generalization performance assessment CV...\n\n' );
                obj.generalizationPerfomanceAssessCVtrainer.setNumberOfFolds( ip.Results.nGenAssessFolds );
                obj.generalizationPerfomanceAssessCVtrainer.setData( obj.trainSet );
                obj.generalizationPerfomanceAssessCVtrainer.run();
                genPerfCVresults = obj.generalizationPerfomanceAssessCVtrainer.getPerformance();
                fprintf( '\n==  Performance after generalization assessment CV:\n' );
                disp( genPerfCVresults );
            end
            obj.trainer.setData( obj.trainSet, obj.testSet );
            fprintf( '\n==  Training model on trainSet...\n\n' );
            tic;
            obj.trainer.run();
            trainTime = toc;
            testTime = nan;
            if ~isempty( obj.testSet )
                fprintf( '\n==  Testing model on testSet... \n\n' );
                tic;
                testPerfresults = obj.trainer.getPerformance( true );
                testTime = toc;
                if numel( testPerfresults ) == 1
                    fprintf( ['\n\n===================================\n',...
                              '##   "%s" Performance: %f\n',...
                              '===================================\n\n'], ...
                             ip.Results.modelName, testPerfresults.double() );
                else
                    fprintf( ['\n\n===================================\n',...
                              '##   "%s" Performance: more than one value\n',...
                              '===================================\n\n'], ...
                             ip.Results.modelName );
                end
            end
            model = obj.trainer.getModel();
            save( modelFilename, ...
                'model', 'featureCreator', 'blockCreator', ...
                'testPerfresults', 'trainTime', 'testTime', 'lastDataProcParams' );
        end
        
        %% -------------------------------------------------------------------------------
        
        function finish( obj )    
            diary off;
            cd( '..' );
        end
        %% -------------------------------------------------------------------------------

        function path = createFilesDir( obj, filesPath )
            mkdir( filesPath );
            cd( filesPath );
            path = pwd;
            diary( 'amlttp.run.log' );
            obj.trainSet.saveFList( 'trainSet.flist', 'sound_databases' );
            if ~isempty( obj.testSet )
                obj.testSet.saveFList( 'testSet.flist', 'sound_databases' );
            end
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
    end
    
end

