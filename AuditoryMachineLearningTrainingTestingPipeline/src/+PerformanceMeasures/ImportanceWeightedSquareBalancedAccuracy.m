classdef ImportanceWeightedSquareBalancedAccuracy < PerformanceMeasures.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        tp;
        fp;
        tn;
        fn;
        sensitivity;
        specificity;
        acc;
        bac;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = ImportanceWeightedSquareBalancedAccuracy( yTrue, yPred, varargin )
            obj = obj@PerformanceMeasures.Base( yTrue, yPred, varargin{:} );
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
            if numel( obj ) > 1
                warning( 'only returning first object''s performance' );
            end
            s = num2str( obj(1).performance );
        end
        % -----------------------------------------------------------------
    
        function [obj, performance, dpi] = calcPerformance( obj, yTrue, yPred, iw, dpi, ~ )
            if ~isempty( dpi )
                dpi.yTrue = yTrue;
                dpi.yPred = yPred;
                dpi.iw = iw;
            end
            tps = iw .* (yTrue == 1 & yPred > 0);
            tns = iw .* (yTrue == -1 & yPred < 0);
            fps = iw .* (yTrue == -1 & yPred > 0);
            fns = iw .* (yTrue == 1 & yPred < 0);
            tp_fn = sum( [tps(:);fns(:)], 1 );
            tn_fp = sum( [tns(:);fps(:)], 1 );
            obj.tp = sum( tps );
            obj.tn = sum( tns );
            obj.fp = sum( fps );
            obj.fn = sum( fns );
            if tp_fn == 0;
                warning( 'No positive true label.' );
                obj.sensitivity = nan;
            else
                obj.sensitivity = obj.tp / tp_fn;
            end
            if tn_fp == 0;
                warning( 'No negative true label.' );
                obj.specificity = nan;
            else
                obj.specificity = obj.tn / tn_fp;
            end
            obj.acc = (obj.tp + obj.tn) / (tp_fn + tn_fp); 
            obj.bac = 0.5 * obj.sensitivity + 0.5 * obj.specificity;
            performance = 1 - (((1 - obj.sensitivity)^2 + (1 - obj.specificity)^2) / 2)^0.5;
       end
        % -----------------------------------------------------------------

    end

end

