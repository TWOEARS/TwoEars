classdef GlmGroupModel < models.DataScalingModel
    
    properties (SetAccess = {?modelTrainers.GlmGroupTrainer, ?modelTrainers.GlmGroupLambdaSelectTrainer})
        model;
        perf_lambda_mean;
        perf_lambda_std;
    end
    
    properties
        lambda;
    end
    
    methods
        %% CONSTRUCTOR
        function self = GlmGroupModel()
            self.lambda = 1e-10;
        end
        
        %% LAMBDA
        function setLambda(self, lambda)
            self.lambda = lambda;
        end
        
        %% IMPACTS
        %         function [impact, cIdx] = getCoefImpacts(self, lambda)
        %             % IMPORTANT: do not use the exact=true flag for `glmnetCoefs`!
        %             if nargin < 2, lambda = self.lambda; end
        %             coefsAtLambda = abs(glmnetCoef(self.model, lambda));
        %             sumCoefs = sum(coefsAtLambda(2:end));
        %             if sumCoefs > 0
        %                 coefsAtLambda = coefsAtLambda(2:end) / sumCoefs;
        %             else
        %                 coefsAtLambda = coefsAtLambda(2:end);
        %             end
        %             [impact,cIdx] = sort( coefsAtLambda );
        %         end
        %
        %         %% BEST CV FIT
        %         function [coefIdxs,impacts,perf,lambda,nCoefs] = getBestLambdaCVresults(self)
        %             [perf, perf_idx] = max(self.perf_lambda_mean);
        %             lambda = self.model.lambdas(perf_idx);
        %             [impact, cIdx] = self.getCoefImpacts(lambda);
        %             impactsUnsorted = sortrows( [impact,cIdx], 2 );
        %             nCoefs = sum( impact > 0 );
        %             impacts = impactsUnsorted(:,1);
        %             coefIdxs = impactsUnsorted(impacts>0,2);
        %         end
        %
        %         function [lambdas,df] = getLambdasAndNCoefs(self)
        %             lambdas = self.model.lambda;
        %             df = self.model.df;
        %         end
        
        %%-- GlmNetModel copy kill
        
        function [impact, cIdx] = getCoefImpacts( obj, lambda )
            if nargin < 2, lambda = obj.lambda; end
            coefsAtLambda = abs( glmnetCoef( obj.model, lambda ) );
            sumCoefs = sum( coefsAtLambda(2:end) );
            if sumCoefs > 0
                coefsAtLambda = coefsAtLambda(2:end) / sumCoefs;
            else
                coefsAtLambda = coefsAtLambda(2:end);
            end
            [impact,cIdx] = sort( coefsAtLambda );
        end
        
        function [coefIdxs,impacts,perf,lambda,nCoefs] = getBestLambdaCVresults( obj )
            lambdasSortedByPerf = sortrows( ...
                [obj.model.lambda,obj.perf_lambda_mean], [2 1] );
            lambda = lambdasSortedByPerf(end,1);
            perf = lambdasSortedByPerf(end,2);
            [impact, cIdx] = obj.getCoefImpacts( lambda );
            impactsUnsorted = sortrows( [impact,cIdx], 2 );
            nCoefs = sum( impact > 0 );
            impacts = impactsUnsorted(:,1);
            coefIdxs = impactsUnsorted(impacts>0,2);
        end
        
        function [coefIdxs,impacts,perf,lambda,nCoefs] = getBestMinStdCVresults( obj )
            lambdasSortedByPerf = sortrows( ...
                [obj.model.lambda,obj.perf_lambda_mean-obj.perf_lambda_std,obj.perf_lambda_mean], [2 3 1] );
            lambda = lambdasSortedByPerf(end,1);
            perf = lambdasSortedByPerf(end,3);
            [impact, cIdx] = obj.getCoefImpacts( lambda );
            impactsUnsorted = sortrows( [impact,cIdx], 2 );
            nCoefs = sum( impact > 0 );
            impacts = impactsUnsorted(:,1);
            coefIdxs = impactsUnsorted(impacts>0,2);
        end
        
        function [coefIdxs,impacts,perf,lambda,nCoefs] = getHighestLambdaWithinStdCVresults( obj )
            lambdasSortedByPerf = sortrows( ...
                [obj.model.lambda,obj.perf_lambda_mean,obj.perf_lambda_std], [2 1] );
            idx = find( lambdasSortedByPerf(:,2) >= ...
                lambdasSortedByPerf(end,2) - lambdasSortedByPerf(end,3) );
            performingLambdasSortedByLambda = sortrows( lambdasSortedByPerf(idx,:), 1 );
            lambda = performingLambdasSortedByLambda(end,1);
            perf = performingLambdasSortedByLambda(end,2);
            [impact, cIdx] = obj.getCoefImpacts( lambda );
            impactsUnsorted = sortrows( [impact,cIdx], 2 );
            nCoefs = sum( impact > 0 );
            impacts = impactsUnsorted(:,1);
            coefIdxs = impactsUnsorted(impacts>0,2);
        end
        
        function [lambdas,nCoefs] = getLambdasAndNCoefs( obj )
            lambdas = obj.model.lambda;
            nCoefs = zeros( size( lambdas ) );
            for ii = 1 : numel( lambdas )
                impact = obj.getCoefImpacts( lambdas(ii) );
                nCoefs(ii) = sum( impact > 0 );
            end
        end
        %%-- OLD
    end
    
    methods (Access = protected)
        %% PREDICTION
        function [y_pred,score] = applyModelToScaledData(self, x)
            y_pred = glmnetPredict(self.model, x, self.lambda, 'class');
            y_unique = unique(y_pred);
            if all(y_unique == [1;2])
                y_pred = y_pred * 2 - 3; % from 1/2 to -1/1
            elseif any((y_unique ~= -1) & (y_unique ~= 1))
                error( 'unexpected labels' );
            end
            score = glmnetPredict(self.model, x, self.lambda, 'response');
        end
    end
end
