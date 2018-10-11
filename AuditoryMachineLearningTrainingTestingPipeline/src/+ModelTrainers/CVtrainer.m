classdef CVtrainer < ModelTrainers.Base

    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        trainer;
        nFolds;
        folds;
        foldsPerformance;
        models;
    end

    %% --------------------------------------------------------------------
    properties (SetAccess = public)
        abortPerfMin;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = CVtrainer( trainer )
            if ~isa( trainer, 'ModelTrainers.Base' )
                error( 'trainer must implement ModelTrainers.Base' );
            end
            obj.trainer = trainer;
            obj.nFolds = 5;
            obj.abortPerfMin = -inf;
            obj.performanceMeasure = trainer.performanceMeasure;
        end
        %% ----------------------------------------------------------------

        function setNumberOfFolds( obj, nFolds )
            if nFolds < 2, error( 'CV cannot be executed with less than two folds.' ); end
            obj.nFolds = nFolds;
        end
        %% ----------------------------------------------------------------
        
        function run( obj )
            obj.buildModel();
        end
        %% ----------------------------------------------------------------
        
        function buildModel( obj, ~, ~, ~ )
            obj.trainer.setPerformanceMeasure( obj.performanceMeasure );
            obj.createFolds();
            obj.foldsPerformance = ones( obj.nFolds, 1 );
            for ff = 1 : obj.nFolds
                foldsRecombinedData = obj.getAllFoldsButOne( ff );
                obj.trainer.setData( foldsRecombinedData, obj.folds{ff} );
                verboseFprintf( obj, 'Starting run %d of CV... ', ff );
                obj.trainer.run();
                obj.models{ff} = obj.trainer.getModel();
                obj.foldsPerformance(ff) = double( obj.trainer.getPerformance() );
                verboseFprintf( obj, 'Done. Performance = %f\n\n', obj.foldsPerformance(ff) );
                maxPossiblePerf = mean( obj.foldsPerformance );
                if (ff < obj.nFolds) && (maxPossiblePerf <= obj.abortPerfMin)
                    break;
                end
            end
        end
        %% ----------------------------------------------------------------
        
        function performance = getPerformance( obj )
            performance.avg = mean( obj.foldsPerformance );
            performance.std = std( obj.foldsPerformance );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( ~ )
            error( 'cvtrainer -- which model do you want?' );
        end
        %% ----------------------------------------------------------------
        
        function createFolds( obj )
            obj.folds = obj.trainSet.splitInPermutedStratifiedFolds( obj.nFolds );
        end
        %% ----------------------------------------------------------------
        
        function foldCombi = getAllFoldsButOne( obj, exceptIdx )
            foldsIdx = 1 : obj.nFolds;
            foldsIdx(exceptIdx) = [];
            foldCombi = Core.IdentTrainPipeData.combineData( obj.folds{foldsIdx} );
        end
        %% ----------------------------------------------------------------

    end
    
end