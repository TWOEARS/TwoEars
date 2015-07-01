classdef GlmNetModel < DataScalingModel
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?GlmNetTrainer, ?GlmNetLambdaSelectTrainer})
        model;
        lPerfsMean;
        lPerfsStd;
        coefsRelAvg;
        coefsRelStd;
        coefsCV;
        lambdasSortedByPerf;
        nCoefs;
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
            coefsAtLambda = abs( glmnetCoef( obj.model, lambda ) );
            sumCoefs = sum( coefsAtLambda(2:end) );
            if sumCoefs > 0
                coefsAtLambda = coefsAtLambda(2:end) / sumCoefs;
            else
                coefsAtLambda = coefsAtLambda(2:end);
            end
            [impact,cIdx] = sort( coefsAtLambda );
        end
        %% -----------------------------------------------------------------

    end
    
    methods (Access = protected)
        
        function [y,score] = applyModelToScaledData( obj, x )
            y = glmnetPredict( obj.model, x, obj.lambda, 'class' );
            y = y * 2 - 3; % from 1/2 to -1/1
            score = glmnetPredict( obj.model, x, obj.lambda, 'response' );
        end
        %% -----------------------------------------------------------------

    end
    
end

