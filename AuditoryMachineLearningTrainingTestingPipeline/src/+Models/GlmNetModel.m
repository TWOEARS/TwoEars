classdef GlmNetModel < Models.DataScalingModel
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?ModelTrainers.GlmNetTrainer, ?ModelTrainers.GlmNetLambdaSelectTrainer})
        model;
        lPerfsMean;
        lPerfsStd;
    end
    
    %% --------------------------------------------------------------------
    properties
        lambda;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = GlmNetModel()
            obj.lambda = 1e-10;
        end
        %% -----------------------------------------------------------------

        function setLambda( obj, newLambda )
            obj.lambda = newLambda;
        end
        %% -----------------------------------------------------------------

        function [impact, cIdx] = getCoefImpacts( obj, lambda )
            if nargin < 2, lambda = obj.lambda; end
            coefs = glmnetCoef( obj.model, lambda );
            if iscell( coefs )
                coefs = squeeze( cellSqueezeFun( @(c)(mean( c, 2 )), coefs, 2, true ) );
                coefs = coefs{1};
            end
            coefsAtLambda = abs( coefs );
            sumCoefs = sum( coefsAtLambda(2:end) );
            if sumCoefs > 0
                coefsAtLambda = coefsAtLambda(2:end) / sumCoefs;
            else
                coefsAtLambda = coefsAtLambda(2:end);
            end
            [impact,cIdx] = sort( coefsAtLambda );
        end
        %% -----------------------------------------------------------------

        function [coefIdxs,impacts,perf,lambda,nCoefs] = getBestLambdaCVresults( obj )
            lambdasSortedByPerf = sortrows( ...
                [obj.model.lambda,obj.lPerfsMean], [2 1] );
            lambda = lambdasSortedByPerf(end,1);
            perf = lambdasSortedByPerf(end,2);
            [impact, cIdx] = obj.getCoefImpacts( lambda );
            impactsUnsorted = sortrows( [impact,cIdx], 2 );
            nCoefs = sum( impact > 0 );
            impacts = impactsUnsorted(:,1);
            coefIdxs = impactsUnsorted(impacts>0,2);
        end
        %% -----------------------------------------------------------------

        function [coefIdxs,impacts,perf,lambda,nCoefs] = getBestMinStdCVresults( obj )
            lambdasSortedByPerf = sortrows( ...
                [obj.model.lambda,obj.lPerfsMean-obj.lPerfsStd,obj.lPerfsMean], [2 3 1] );
            lambda = lambdasSortedByPerf(end,1);
            perf = lambdasSortedByPerf(end,3);
            [impact, cIdx] = obj.getCoefImpacts( lambda );
            impactsUnsorted = sortrows( [impact,cIdx], 2 );
            nCoefs = sum( impact > 0 );
            impacts = impactsUnsorted(:,1);
            coefIdxs = impactsUnsorted(impacts>0,2);
        end
        %% -----------------------------------------------------------------

        function [coefIdxs,impacts,perf,lambda,nCoefs] = getHighestLambdaWithinStdCVresults( obj )
            lambdasSortedByPerf = sortrows( ...
                [obj.model.lambda,obj.lPerfsMean,obj.lPerfsStd], [2 1] );
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
        %% -----------------------------------------------------------------

        function [lambdas,nCoefs] = getLambdasAndNCoefs( obj )
            lambdas = obj.model.lambda;
            nCoefs = zeros( size( lambdas ) );
            for ii = 1 : numel( lambdas )
                impact = obj.getCoefImpacts( lambdas(ii) );
                nCoefs(ii) = sum( impact > 0 );
            end
        end
        %% -----------------------------------------------------------------

    end
    
    methods (Access = protected)
        
        function [y,score] = applyModelToScaledData( obj, x )
            y = glmnetPredict( obj.model, x, obj.lambda, 'class' );
            score = glmnetPredict( obj.model, x, obj.lambda, 'response' );
            if any( strcmpi( obj.model.class, {'elnet','fishnet'} ) )
                y = score;
            end
        end
        %% -----------------------------------------------------------------

    end
    
end
