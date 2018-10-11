classdef Fscore < PerformanceMeasures.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        tp;
        fp;
        tn;
        fn;
        recall;
        precision;
        acc;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = Fscore( yTrue, yPred, varargin )
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
            tp_fp = obj.tp + obj.fp;
            tn_fp = sum( yTrue == -1 );
            if tp_fn == 0;
                warning( 'No positive true label.' );
                obj.recall = nan;
            else
                obj.recall = obj.tp / tp_fn;
            end
            if tp_fp == 0;
                warning( 'No positive prediction.' );
                obj.precision = nan;
            else
                obj.precision = obj.tp / tp_fp;
            end
            obj.acc = (obj.tp + obj.tn) / (tp_fn + tn_fp); 
            performance = 2 * obj.recall * obj.precision / (obj.recall + obj.precision);
        end
        % -----------------------------------------------------------------
    
    end

end

