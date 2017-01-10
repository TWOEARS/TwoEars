classdef NSE < PerformanceMeasures.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        mae;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = NSE( yTrue, yPred, datapointInfo )
           if nargin < 3
                dpiarg = {};
            else
                dpiarg = {datapointInfo};
            end
            obj = obj@PerformanceMeasures.Base( yTrue, yPred, dpiarg{:} );
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
    
        function [obj, performance, dpi] = calcPerformance( obj, yTrue, yPred, dpi )
            e = yTrue - yPred;
            se = e.^2;
            performance = - mean( se );
            obj.mae = mean( abs( e ) );
            if nargin < 4
                dpi = struct.empty;
            else
                dpi.yTrue = yTrue;
                dpi.yPred = yPred;
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
    
        function [dpiext, compiled] = makeDatapointInfoStats( obj, fieldname, compiledPerfField )
            if isempty( obj.datapointInfo ), dpiext = []; return; end
            if ~isfield( obj.datapointInfo, fieldname )
                error( '%s is not a field of datapointInfo', fieldname );
            end
            if nargin < 3, compiledPerfField = 'performance'; end
            uniqueDpiFieldElems = unique( obj.datapointInfo.(fieldname) );
            for ii = 1 : numel( uniqueDpiFieldElems )
                if iscell( uniqueDpiFieldElems )
                    udfe = uniqueDpiFieldElems{ii};
                    udfeIdxs = strcmp( obj.datapointInfo.(fieldname), ...
                                       udfe );
                else
                    udfe = uniqueDpiFieldElems(ii);
                    udfeIdxs = obj.datapointInfo.(fieldname) == udfe;
                end
                for fn = fieldnames( obj.datapointInfo )'
                    if any( size( obj.datapointInfo.(fn{1}) ) ~= size( udfeIdxs ) )
                        iiDatapointInfo.(fn{1}) = obj.datapointInfo.(fn{1});
                        continue
                    end
                    iiDatapointInfo.(fn{1}) = obj.datapointInfo.(fn{1})(udfeIdxs);
                end
                dpiext(ii) = PerformanceMeasures.BAC( iiDatapointInfo.yTrue, ...
                                                       iiDatapointInfo.yPred,...
                                                       iiDatapointInfo );
                compiled{ii,1} = udfe;
                compiled{ii,2} = dpiext(ii).(compiledPerfField);
            end
        end
        % -----------------------------------------------------------------

    end

end

