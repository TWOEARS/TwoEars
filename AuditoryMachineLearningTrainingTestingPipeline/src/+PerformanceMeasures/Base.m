classdef (Abstract) Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        performance;
        datapointInfo;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = Base( yTrue, yPred, iw, datapointInfo, testSetIdData )
            if nargin < 3
                iw = ones( size( yTrue ) );
            end
            if nargin < 4
                datapointInfo = struct.empty;
            end
            if nargin < 5
                testSetIdData = [];
            end
            [obj, obj.performance, obj.datapointInfo] = ...
                    obj.calcPerformance( yTrue, yPred, iw, datapointInfo, testSetIdData );
        end
        % -----------------------------------------------------------------
    
        function b = lt( obj, otherPm )
            b = ~( obj == otherPm ) && ~( obj > otherPm );
        end
        % -----------------------------------------------------------------
    
        function po = strapOffDpi( obj )
            po = obj;
            po.datapointInfo = struct.empty;
        end
        % -----------------------------------------------------------------
    
        function b = le( obj, otherPm )
            b = ~( obj > otherPm );
        end
        % -----------------------------------------------------------------
    
        function b = ge( obj, otherPm )
            b = ( obj == otherPm ) || ( obj > otherPm );
        end
        % -----------------------------------------------------------------
    
        function b = ne( obj, otherPm )
            b = ~( obj == otherPm );
        end
        % -----------------------------------------------------------------
    
        function b = eq( obj1, obj2 )
            if isa( obj1, 'numeric' )
                b = obj1 == double( obj2 );
            elseif isa( obj2, 'numeric' )
                b = obj2 == double( obj1 );
            else
                b = obj1.eqPm( obj2 );
            end
        end
        % -----------------------------------------------------------------
    
        function b = gt( obj1, obj2 )
            if isa( obj1, 'numeric' )
                b = obj1 > double( obj2 );
            elseif isa( obj2, 'numeric' )
                b = double( obj1 ) > obj2;
            else
                b = obj1.gtPm( obj2 );
            end
        end
        % -----------------------------------------------------------------
        
        function disp( obj )
            disp( obj.char() );
        end
        % -----------------------------------------------------------------

        function [blockAnnotations, yp, yt] = getBacfDpi( obj, bacfIdx, bacfSubidx )
            allDpi = obj.datapointInfo;
            currentFileDpiIdxs = find( allDpi.fileIdxs == bacfIdx );
            currentFileBacfSubIdxs = allDpi.bacfIdxs(currentFileDpiIdxs);
            currentBacfDpiIdxs = currentFileDpiIdxs(currentFileBacfSubIdxs == bacfSubidx);
            currentBacfUsedIdxs = allDpi.bIdxs(currentBacfDpiIdxs);
            bacfile = load( allDpi.blockAnnotsCacheFiles{bacfIdx}{bacfSubidx}, 'blockAnnotations');
            blockAnnotations = bacfile.blockAnnotations(currentBacfUsedIdxs);
            yp = allDpi.yPred(currentBacfDpiIdxs);
            yt = allDpi.yTrue(currentBacfDpiIdxs);
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
                classInfo = metaclass( obj );
                dpiext(ii) = feval( classInfo.Name, iiDatapointInfo.yTrue, ...
                                                    iiDatapointInfo.yPred,...
                                                    iiDatapointInfo.iw,...
                                                    iiDatapointInfo );
                compiled{ii,1} = udfe;
                compiled{ii,2} = dpiext(ii).(compiledPerfField);
            end
        end
        % -----------------------------------------------------------------

    end

    %% --------------------------------------------------------------------
    methods (Abstract)
        [obj, performance, dpi] = calcPerformance( obj, yTrue, yPred, iw, dpi, testSetIdData )
        b = eqPm( obj, otherPm )
        b = gtPm( obj, otherPm )
        s = char( obj )
        d = double( obj )
    end
    
end

