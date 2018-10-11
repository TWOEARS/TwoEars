classdef NSE < PerformanceMeasures.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        mae;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = NSE( yTrue, yPred, varargin )
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
            e = yTrue - yPred;
            se = e.^2;
            performance = - mean( se );
            obj.mae = mean( abs( e ) );
            if ~isempty( dpi )
                dpi.yTrue = yTrue;
                dpi.yPred = yPred;
                dpi.iw = iw;
            end
        end
        % -----------------------------------------------------------------
    
        function [cm, performance, acc, sens] = getConfusionMatrix( obj, ypRange )
            if isempty( obj.datapointInfo )
                cm = [];
                return;
            end
            if nargin < 2, ypRange = [-inf inf]; end
            ypOrd = round( obj.datapointInfo.yPred );
            ypOrd = max( ypOrd, ypRange(1) );
            ypOrd = min( ypOrd, ypRange(2) );
            yTrue = obj.datapointInfo.yTrue;
            labels = unique( [yTrue;ypOrd] );
            n_acc = 0;
            for tt = 1 : numel( labels )
                for pp = 1 : numel( labels )
                    cm(tt,pp) = sum( (yTrue == labels(tt)) & (ypOrd == labels(pp)) );
                end
                n_tt = sum( cm(tt,:) );
                if n_tt > 0
                    sens(tt) = cm(tt,tt) / n_tt;
                else
                    sens(tt) = nan;
                end
                n_acc = n_acc + cm(tt,tt);
            end
            acc = n_acc / sum( sum( cm ) ); 
            performance = sum( sens(~isnan(sens)) ) / numel( sens(~isnan(sens)) );
        end
        % -----------------------------------------------------------------

    end

end

