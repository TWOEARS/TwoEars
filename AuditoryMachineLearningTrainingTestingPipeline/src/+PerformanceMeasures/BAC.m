classdef BAC < PerformanceMeasures.Base
    
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
        
        function obj = BAC( yTrue, yPred, varargin )
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
            tps = yTrue == 1 & yPred > 0;
            tns = yTrue == -1 & yPred < 0;
            fps = yTrue == -1 & yPred > 0;
            fns = yTrue == 1 & yPred < 0;
            if ~isempty( dpi )
                dpi.yTrue = yTrue;
                dpi.yPred = yPred;
                dpi.iw = iw;
            end
            obj.tp = sum( tps );
            obj.tn = sum( tns );
            obj.fp = sum( fps );
            obj.fn = sum( fns );
            tp_fn = sum( yTrue == 1 );
            tn_fp = sum( yTrue == -1 );
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
            performance = 0.5 * obj.sensitivity + 0.5 * obj.specificity;
        end
        % -----------------------------------------------------------------

    end

end

