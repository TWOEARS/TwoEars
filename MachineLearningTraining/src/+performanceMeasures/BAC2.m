classdef BAC2 < performanceMeasures.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        tp;
        fp;
        tn;
        fn;
        sensitivity;
        specificity;
        acc;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = BAC2( yTrue, yPred )
            obj = obj@performanceMeasures.Base( yTrue, yPred );
        end
        % -----------------------------------------------------------------
    
        function b = eqPm( obj, otherPm )
            b = obj.performance == otherPm.performance;
        end
        % -----------------------------------------------------------------
    
        function b = gtPm( obj, otherPm )
            b = obj.performance > otherPm.performance;
        end
        % -----------------------------------------------------------------
    
        function d = double( obj )
            for ii = 1 : size( obj, 2 )
                d(ii) = double( obj(ii).performance );
            end
        end
        % -----------------------------------------------------------------
    
        function s = char( obj )
            s = num2str( obj.performance );
        end
        % -----------------------------------------------------------------
    
        function [obj, performance] = calcPerformance( obj, yTrue, yPred )
            obj.tp = sum( yTrue == 1 & yPred > 0 );
            obj.tn = sum( yTrue == -1 & yPred < 0 );
            obj.fp = sum( yTrue == -1 & yPred > 0 );
            obj.fn = sum( yTrue == 1 & yPred < 0 );
            tp_fn = sum( yTrue == 1 );
            tn_fp = sum( yTrue == -1 );
            if tp_fn == 0;
                warning( 'No positive true label.' );
                obj.sensitivity = 0;
            else
                obj.sensitivity = obj.tp / tp_fn;
            end
            if tn_fp == 0;
                warning( 'No negative true label.' );
                obj.specificity = 0;
            else
                obj.specificity = obj.tn / tn_fp;
            end
            performance = 1 - (((1 - obj.sensitivity)^2 + (1 - obj.specificity)^2) / 2)^0.5;
            obj.acc = (obj.tp + obj.tn) / (tp_fn + tn_fp); 
        end
        % -----------------------------------------------------------------

    end

end

