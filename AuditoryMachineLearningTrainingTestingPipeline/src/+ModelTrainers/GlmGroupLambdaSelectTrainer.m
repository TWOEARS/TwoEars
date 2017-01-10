classdef GlmGroupLambdaSelectTrainer < ModelTrainers.Base & Parameterized
    %GLMGROUPLAMBDASELECTTRAINER trainer for a GlmGroupModel, will fit a regression
    % model with L1,0, L1,2 or L1,inf norm regularization.
    % this trainer will additionally do a k-folded crossvalidation to choose
    % the best lambda along the path according to a performance measure.
    
    properties (SetAccess = {?Parameterized})
        trainer_cv; % ModelTrainers.CVTrainer
        trainer_core; % ModelTrainers.GlmGroupTrainer
        model; % Models.GlmGroupModel
        family; % only 'binomial' works for now
        norm; % one of [0,2,inf], the norm to apply with groups
        groups; % one integer label feature
        nlambdas; % numberof lambda vaues along the path
        kfolds; % number of folds for the cross validation
    end
    
    methods
        
        %% CONSTRUCTOR
        function self = GlmGroupLambdaSelectTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                'default', @PerformanceMeasures.BAC2, ...
                'valFun', @(x)(isa( x, 'function_handle' )), ...
                'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'family', ...
                'default', 'binomial', ...
                'valFun', @(x)(ischar(x) && any(strcmpi(x, {'binomial'}))) );
            pds{3} = struct( 'name', 'norm', ...
                'default', 2, ...
                'valFun', @(x)(x==0 || x==2 || isinf(x)) );
            pds{4} = struct( 'name', 'groups', ...
                'default', ones(10), ...
                'valFun', @(x)(isvector(x)) );
            pds{5} = struct( 'name', 'nlambdas', ...
                'default', 100, ...
                'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            pds{6} = struct( 'name', 'kfolds', ...
                'default', 10, ...
                'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            pds{7} = struct( 'name', 'maxDataSize', ...
                'default', inf, ...
                'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x >= 0)) );
            self = self@Parameterized( pds );
            self.setParameters( true, varargin{:} );
        end
        
        %% RUN
        function run(self)
            self.buildModel();
        end
        
        %% BUILD MODEL
        function buildModel(self, ~, ~)
            verboseFprintf(self, '\nRun on full trainSet...\n');
            % run core trainer once to determine the lambda path
            self.trainer_core = ModelTrainers.GlmGroupTrainer( ...
                'performanceMeasure', self.performanceMeasure, ...
                'maxDataSize', self.maxDataSize, ...
                'family', self.family, ...
                'groups', self.groups, ...
                'norm', self.norm, ...
                'nlambdas', self.nlambdas);
            self.trainer_Core.setData(self.trainSet, self.testSet);
            self.trainer_Core.run();
            self.model = self.trainer_Core.getModel();
            lambdas = self.model.model.lambda;
            
            verboseFprintf( self, '\nRun cv to determine best lambda...\n' );
            % run cv trainer on all folds
            self.trainer_Core.setParameters(false, 'lambda', lambdas);
            self.trainer_cv = ModelTrainers.CVtrainer(self.trainer_core);
            self.trainer_cv.setPerformanceMeasure(self.performanceMeasure);
            self.trainer_cv.setData(self.trainSet, self.testSet);
            self.trainer_cv.setNumberOfFolds(self.kfolds);
            self.trainer_cv.run();
            models_cv = self.trainer_cv.models;
            
            verboseFprintf(self, 'Calculate Performance for all lambdas...\n');
            % calculate performances
            perf_lambda = zeros(self.nlambdas, self.kfolds);
            for i = 1:self.kfolds
                models_cv{i}.setLambda([]);
                perf_lambda(:,i) = Models.Base.getPerformance( ...
                    models_cv{i}, self.trainer_cv.folds{i}, ...
                    self.performanceMeasure);
                verboseFprintf(self, '.');
            end
            self.model.perf_lambda_mean = mean(perf_lambda, 2);
            self.model.perf_lambda_std = std(perf_lambda, [], 2);
            verboseFprintf( self, 'Done\n' );
            lambdas_by_perf = sortrows( [lambdas,self.model.perf_lambda_mean], 2 );
            self.model.setLambda( lambdas_by_perf(end,1) );
        end
        
        %         
        function rval = getPerformance(self)
            rval = Models.Base.getPerformance( ...
                self.model, self.testSet, ...
                self.performanceMeasure );
        end
    end
    
    methods (Access = protected)

        %% GET MODEL
        function rval = giveTrainedModel(self)
            rval = self.model;
        end
    end
end