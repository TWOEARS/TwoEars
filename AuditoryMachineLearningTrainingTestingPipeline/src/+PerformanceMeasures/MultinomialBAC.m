classdef MultinomialBAC < PerformanceMeasures.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        confusionMatrix;
        sens;
        acc;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = MultinomialBAC( yTrue, yPred, datapointInfo )
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
            labels = unique( [yTrue;yPred] );
            n_acc = 0;
            for tt = 1 : numel( labels )
                for pp = 1 : numel( labels )
                    obj.confusionMatrix(tt,pp) = ...
                                     sum( (yTrue == labels(tt)) & (yPred == labels(pp)) );
                end
                n_tt = sum( obj.confusionMatrix(tt,:) );
                if n_tt > 0
                    obj.sens(tt) = obj.confusionMatrix(tt,tt) / n_tt;
                else
                    obj.sens(tt) = nan;
                end
                n_acc = n_acc + obj.confusionMatrix(tt,tt);
            end
            if nargin < 4
                dpi = struct.empty;
            else
                dpi.yTrue = yTrue;
                dpi.yPred = yPred;
            end
            obj.acc = n_acc / sum( sum( obj.confusionMatrix ) ); 
            performance = sum( obj.sens(~isnan(obj.sens)) ) / ...
                                                      numel( obj.sens(~isnan(obj.sens)) );
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

