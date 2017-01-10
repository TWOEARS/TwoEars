classdef GlmNetLambdaSelectTrainer < ModelTrainers.Base & Parameterized
    % GlmNetLambdaSelectTrainer trainer for a GlmNetModel
    %   Will fit an elastic net regression model. For alpha = 1 this 
    %   corresponds to LASSO regularization. 
    %   This trainer will additionally do a k-fold 
    %   crossvalidation to choose the best lambda along the path according
    %   to a performance measure.
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        cvTrainer;      % for k-fold cross validation
        coreTrainer;
        fullSetModel;
        alpha;          % elastic net parameter
        family;
        nLambda;        % number of lambdas on the regularization path
        cvFolds;        % no. of folds for cross validation
        labelWeights;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = GlmNetLambdaSelectTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @PerformanceMeasures.BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            pds{3} = struct( 'name', 'alpha', ...
                             'default', 1, ...
                             'valFun', @(x)(isfloat(x) && x >= 0 && x <= 1.0) );
            pds{4} = struct( 'name', 'family', ...
                             'default', 'binomial', ...
                             'valFun', @(x)(ischar(x) && any(strcmpi(x, ...
                                                                     {'binomial',...
                                                                      'multinomial',...
                                                                      'multinomialGrouped',...
                                                                      'gaussian',...
                                                                      'poisson'}))) );
            pds{5} = struct( 'name', 'nLambda', ...
                             'default', 100, ...
                             'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            pds{6} = struct( 'name', 'cvFolds', ...
                              'default', 10, ...
                              'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            pds{7} = struct( 'name', 'labelWeights', ...
                             'default', [], ...
                             'valFun', @(x)(isempty(x) || isfloat(x)) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
        function run( obj )
            obj.buildModel();
        end
        %% ----------------------------------------------------------------
        
        function buildModel( obj, ~, ~ )
            verboseFprintf( obj, '\nRun on full trainSet...\n' );
            obj.coreTrainer = ModelTrainers.GlmNetTrainer( ...
                'performanceMeasure', obj.performanceMeasure, ...
                'maxDataSize', obj.maxDataSize, ...
                'alpha', obj.alpha, ...
                'family', obj.family, ...
                'nLambda', obj.nLambda, ...
                'labelWeights', obj.labelWeights );
            obj.coreTrainer.setData( obj.trainSet, obj.testSet );
            obj.coreTrainer.run();
            obj.fullSetModel = obj.coreTrainer.getModel();
            lambdas = obj.fullSetModel.model.lambda;
            verboseFprintf( obj, '\nRun cv to determine best lambda...\n' );
            obj.coreTrainer.setParameters( false, 'lambda', lambdas );
            obj.cvTrainer = ModelTrainers.CVtrainer( obj.coreTrainer );
            obj.cvTrainer.setPerformanceMeasure( obj.performanceMeasure );
            obj.cvTrainer.setData( obj.trainSet, obj.testSet );
            obj.cvTrainer.setNumberOfFolds( obj.cvFolds );
            obj.cvTrainer.run();
            cvModels = obj.cvTrainer.models;
            verboseFprintf( obj, 'Calculate Performance for all lambdas...\n' );
            lPerfs = zeros( numel( lambdas ), numel( cvModels ) );
            for ii = 1 : numel( cvModels )
                cvModels{ii}.setLambda( [] );
                thisFoldPerfs = Models.Base.getPerformance( ...
                    cvModels{ii}, obj.cvTrainer.folds{ii}, ...
                    obj.performanceMeasure );
                lPerfs(1:numel(thisFoldPerfs),ii) = thisFoldPerfs;
                verboseFprintf( obj, '.' );
            end
            obj.fullSetModel.lPerfsMean = nanMean( lPerfs, 2 );
            obj.fullSetModel.lPerfsStd = nanStd( lPerfs, 2 );
            verboseFprintf( obj, 'Done\n' );
            lambdasSortedByPerf = sortrows( [lambdas,obj.fullSetModel.lPerfsMean], 2 );
            obj.fullSetModel.setLambda( lambdasSortedByPerf(end,1) );
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = obj.fullSetModel;
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = private)
        
    end
        
end