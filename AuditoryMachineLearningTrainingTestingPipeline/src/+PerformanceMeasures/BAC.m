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
        
        function obj = BAC( yTrue, yPred, datapointInfo )
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
            tps = yTrue == 1 & yPred > 0;
            tns = yTrue == -1 & yPred < 0;
            fps = yTrue == -1 & yPred > 0;
            fns = yTrue == 1 & yPred < 0;
            if nargin < 4
                dpi = struct.empty;
            else
                dpi.yTrue = yTrue;
                dpi.yPred = yPred;
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

