classdef RescSparse
    % class for results count sparse matrices
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = public)
        dataConvert;
        dataIdxsConvert;
        data;
        dataIdxs;
        id;
        dataInitialize;
        dataAdd;
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods
        
        function obj = RescSparse( datatype, dataidxstype, dataInitialize, dataAdd )
            if nargin < 1 || isempty( datatype )
                datatype = 'double';
            end
            obj = obj.setDataType( datatype );
            if nargin < 2 || isempty( dataidxstype )
                dataidxstype = 'double';
            end
            switch dataidxstype
                case 'double'
                    obj.dataIdxsConvert = @double;
                case 'single'
                    obj.dataIdxsConvert = @single;
                case 'int64'
                    obj.dataIdxsConvert = @int64;
                case 'int32'
                    obj.dataIdxsConvert = @int32;
                case 'int16'
                    obj.dataIdxsConvert = @int16;
                case 'int8'
                    obj.dataIdxsConvert = @int8;
                case 'uint64'
                    obj.dataIdxsConvert = @uint64;
                case 'uint32'
                    obj.dataIdxsConvert = @uint32;
                case 'uint16'
                    obj.dataIdxsConvert = @uint16;
                case 'uint8'
                    obj.dataIdxsConvert = @uint8;
                case 'logical'
                    obj.dataIdxsConvert = @logical;
                otherwise
                    obj.dataIdxsConvert = @double;
            end
            if nargin < 3 || isempty( dataInitialize )
                dataInitialize = obj.dataConvert( 0 );
            end
            obj.dataInitialize = dataInitialize;
            if nargin < 4 || isempty( dataAdd )
                dataAdd = @(a,b)(a+b);
            end
            obj.dataAdd = dataAdd;
            obj.data = obj.dataConvert( zeros( 0 ) );
            obj.dataIdxs = obj.dataIdxsConvert( zeros( 0 ) );
            obj.id = [];
        end
        %% -------------------------------------------------------------------------------
        function obj = setDataType( obj, newDataType )
            switch newDataType
                case 'double'
                    obj.dataConvert = @double;
                case 'single'
                    obj.dataConvert = @single;
                case 'int64'
                    obj.dataConvert = @int64;
                case 'int32'
                    obj.dataConvert = @int32;
                case 'int16'
                    obj.dataConvert = @int16;
                case 'int8'
                    obj.dataConvert = @int8;
                case 'uint64'
                    obj.dataConvert = @uint64;
                case 'uint32'
                    obj.dataConvert = @uint32;
                case 'uint16'
                    obj.dataConvert = @uint16;
                case 'uint8'
                    obj.dataConvert = @uint8;
                case 'logical'
                    obj.dataConvert = @logical;
                otherwise
                    obj.dataConvert = @double;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function ecpy = emptyCopy( obj )
            ecpy = RescSparse();
            ecpy.dataConvert = obj.dataConvert;
            ecpy.dataIdxsConvert = obj.dataIdxsConvert;
            ecpy.dataAdd = obj.dataAdd;
            ecpy.dataInitialize = obj.dataInitialize;
        end
        %% -------------------------------------------------------------------------------
        
        function value = get( obj, idxs )
            value = 0;
            if size( idxs, 2 ) < size( obj.dataIdxs, 2 )
                error( 'AMLTTP:usage:unexpected', 'idxs dimensions too small.' );
            end
            if size( idxs, 2 ) > size( obj.dataIdxs, 2 )
                error( 'AMLTTP:usage:unexpected', 'idxs dimensions too big.' );
            end
            rowIdxEq = obj.rowSearch( idxs );
            if rowIdxEq ~= 0
                value = obj.data(rowIdxEq,:);
            end
        end
        %% -------------------------------------------------------------------------------
        
        function [data,dataIdxs] = getRowIndexed( obj, rowIdxs )
            if max( rowIdxs ) > size( obj.dataIdxs, 1 )
                error( 'AMLTTP:usage:unexpected', 'max rowIdxs too big.' );
            end
            data = obj.data(rowIdxs,:);
            if nargout > 1
                dataIdxs = obj.dataIdxs(rowIdxs,:);
            end
        end
        %% -------------------------------------------------------------------------------
        
        function rowIdxs = getRowIdxs( obj, idxsMask )
            if isempty( obj.dataIdxs )
                rowIdxs = [];
                return;
            end
            if size( idxsMask, 2 ) ~= size( obj.dataIdxs, 2 )
                error( 'AMLTTP:usage:unexpected', 'idxsMask dimensions wrong.' );
            end
            dataIdxsMask = true( size( obj.dataIdxs, 1 ), sum( cellfun( @(c)(~ischar( c ) ), idxsMask ) ) );
            jj = 0;
            for ii = 1 : size( obj.dataIdxs, 2 )
                if ischar( idxsMask{ii} ) && idxsMask{ii} == ':', continue; end
                jj = jj + 1;
                if jj == 1
                    dataIdxsMask(:,jj) = idxsMask{ii}( obj.dataIdxs(:,ii) );
                else
                    tmp = dataIdxsMask(:,jj-1);
                    dataIdxsMask(tmp,jj) = idxsMask{ii}( obj.dataIdxs(tmp,ii) );
                end
            end
            rowIdxsMask = all( dataIdxsMask, 2 );
            rowIdxs = find( rowIdxsMask );
        end
        %% -------------------------------------------------------------------------------
        
        function obj = deleteData( obj, rowIdxs )
            if max( rowIdxs ) > size( obj.dataIdxs, 1 )
                error( 'AMLTTP:usage:unexpected', 'max rowIdxs too big.' );
            end
            obj.data(rowIdxs,:) = [];
            obj.dataIdxs(rowIdxs,:) = [];
        end
        %% -------------------------------------------------------------------------------
        
        function obj = filter( obj, varargin )
            obj = obj.deleteData( obj.getRowIdxs( ...
                                   getIdxMask( size( obj.dataIdxs, 2 ), varargin{:} ) ) );
        end
        %% -------------------------------------------------------------------------------
        
        function [obj,incidxs,insidxs] = addData( obj, idxs, data, areIdxsPresorted )
            if isempty( idxs )
                incidxs = []; insidxs = [];
                return;
            end
            idxs = obj.dataIdxsConvert( idxs );
            data = obj.dataConvert( data );
            if size( idxs, 2 ) < size( obj.dataIdxs, 2 )
                error( 'AMLTTP:usage:unexpected', 'idxs dimensions too small.' );
            end
            if size( idxs, 2 ) > size( obj.dataIdxs, 2 )
                if isempty( obj.dataIdxs )
                    obj.dataIdxs = obj.dataIdxsConvert( zeros( 0, size( idxs, 2 ) ) );
                else
                    obj.dataIdxs(:,size( obj.dataIdxs, 2 )+1:size( idxs, 2 )) = obj.dataIdxsConvert( 1 );
                end
            end
            rowIdxEq = zeros( size( idxs, 1 ), 1 );
            rowIdxGt = zeros( size( idxs, 1 ), 1 );
            iis = [1, size( idxs, 1 ), 2:size( idxs, 1 )-1];
            for ii = iis
                if (nargin >=4) && areIdxsPresorted && (ii==2) && (rowIdxGt(1)==rowIdxGt(end)) && (all( rowIdxEq == 0 ))
                    rowIdxGt(:) = rowIdxGt(1);
                    break;
                end
                [rowIdxEq(ii),~,rowIdxGt(ii)] = obj.rowSearch( idxs(ii,:) );
                if rowIdxEq(ii) ~= 0
                    obj.data(rowIdxEq(ii),:) = obj.dataAdd( obj.data(rowIdxEq(ii),:), data(ii,:) );
                end
            end
            rowIdxGt(rowIdxEq ~= 0) = [];
            idxs(rowIdxEq ~= 0,:) = [];
            data(rowIdxEq ~= 0,:) = [];
            [rigtidxs,order] = sortrows( [rowIdxGt,double( idxs )] );
            insidxs = rigtidxs(:,1);
            incidxs = sort( [insidxs; (1:size( obj.dataIdxs, 1 ))'] );
            obj.dataIdxs(end+1,:) = obj.dataIdxsConvert( 0 );
            obj.data(end+1,:) = obj.dataConvert( 0 );
            obj.dataIdxs = obj.dataIdxs(incidxs,:);
            obj.data = obj.data(incidxs,:);
            insidxs = insidxs + (0:numel( insidxs )-1)';
            obj.dataIdxs(insidxs,:) = rigtidxs(:,2:end);
            obj.data(insidxs,:) = data(order,:);
        end
        %% -------------------------------------------------------------------------------

        function [rowIdxEq,rowIdxLt,rowIdxGt] = rowSearch( obj, idxs, preRowIdxGt )
%             if numel( idxs ) ~= size( obj.dataIdxs, 2 )
%                 error( 'AMLTTP:implementation:unexpected', 'This should not have happened.' );
%             end
            rowIdxEq = 0; 
            rowIdxLt = 0;
            if nargin < 3 || isempty( preRowIdxGt )
                preRowIdxGt = size( obj.dataIdxs, 1 );
            end
            rowIdxGt = preRowIdxGt + 1;
            ni = size( idxs, 2 );
            while rowIdxGt - rowIdxLt > 1
                mRowIdx = floor( 0.5*rowIdxLt + 0.5*rowIdxGt );
                idxAreEq = 1; idxAisltB = 0; idxAisgtB = 0;
                for ii = 1 : ni
                    if idxs(ii) < obj.dataIdxs(mRowIdx,ii)
                        idxAisltB = 1;
                        idxAreEq = 0;
                        break;
                    elseif idxs(ii) > obj.dataIdxs(mRowIdx,ii)
                        idxAisgtB = 1;
                        idxAreEq = 0;
                        break;
                    end
                end
                if idxAreEq
                    rowIdxEq = mRowIdx;
                    rowIdxLt = mRowIdx - 1;
                    rowIdxGt = mRowIdx + 1;
                    break;
                elseif idxAisltB
                    rowIdxGt = mRowIdx;
                elseif idxAisgtB
                    rowIdxLt = mRowIdx;
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
        function obj = partJoin( obj, otherObj, keepMask, overrideMask )
            obj = obj.deleteData( obj.getRowIdxs( overrideMask ) );
            otherObj = otherObj.deleteData( otherObj.getRowIdxs( keepMask ) );
            obj = obj.addData( otherObj.dataIdxs, otherObj.data, true );
        end
        %% -------------------------------------------------------------------------------
        
        function [summedResc,summedDataOrigin] = summarizeDown( obj, keepDims, rowIdxs, idxReplaceMask, fun, sdoPrior, intraGroupNorm )
            summedResc = obj;
            if nargin < 2
                return;
            end
            if isempty( keepDims ) && (nargin < 4 || isempty( idxReplaceMask ))
                return;
            end
            if nargin < 3 || (ischar( rowIdxs ) && (rowIdxs == ':')) %isempty( rowIdxs )
                rowIdxs = 1 : size( summedResc.dataIdxs, 1 );
            end
            if nargin >= 4 && ~isempty( idxReplaceMask )
                keepDims = 1:size( obj.dataIdxs, 2 );
                if size( idxReplaceMask, 2 ) ~= size( summedResc.dataIdxs, 2 )
                    error( 'AMLTTP:usage:unexpected', 'idxsMask dimensions wrong.' );
                end
                for ii = 1 : size( summedResc.dataIdxs, 2 )
                    if isempty( idxReplaceMask{ii} ), continue; end
                    summedResc.dataIdxs(:,ii) = idxReplaceMask{ii}( summedResc.dataIdxs(:,ii) );
                end
            end
            if nargin < 5
                fun = [];
            end
            if (nargin < 6 || isempty( sdoPrior )) && nargout > 1
                clear sdoPrior;
                sdoPrior(:,1) = mat2cell( summedResc.dataIdxs(rowIdxs,:), ones( size( summedResc.dataIdxs(rowIdxs,:), 1 ), 1 ) );
                sdoPrior(:,2) = mat2cell( summedResc.data(rowIdxs,:), ones( size( summedResc.data(rowIdxs,:), 1 ), 1 ) );
            end
            [keepDimsUniqueIdxs,~,ic] = unique( summedResc.dataIdxs(rowIdxs,keepDims), 'rows' );
            summedData = accumarray( ic, summedResc.data(rowIdxs,:), [], fun );
            if nargout > 1
                if nargin >= 7 && intraGroupNorm
                    ignFactor = arrayfun( @(a,b)(sum( cellfun( @sum, sdoPrior(ic==b,2) ) ) / (sum( a{:} ) * numel( sdoPrior(ic==b,2) ))), sdoPrior(:,2), ic );
                else
                    ignFactor = ones( size( ic ) );
                end
                [summedDataOrigin(:,1), summedDataOrigin(:,2)] = splitapply( @(x,a)(deal({cell2mat( x(:,1) )},{cell2mat( arrayfun( @(c,b)(c{:}*b), x(:,2), a, 'UniformOutput', false ) )})), sdoPrior, ignFactor, ic );
            end
            summedResc.dataIdxs = keepDimsUniqueIdxs;
            summedResc.data = summedData;
            if ~isempty( obj.id )
                idxDescr = fieldnames( obj.id );
                idxDescr = idxDescr(keepDims);
                summedResc.id = ...
                    cell2struct( num2cell( 1:numel( idxDescr ) )', idxDescr );
            end
        end
        %% -------------------------------------------------------------------------------

        function robj = resample( obj, depIdx, rIdx, resample_weights, conditions )
            if nargin >= 5 && ~isempty( conditions )
                useIdxs = obj.getRowIdxs( conditions );
            else
                useIdxs = ':';
            end
            drIdxs = obj.dataIdxs( useIdxs,[depIdx,rIdx] );
            drIdxs = mat2cell( drIdxs, size( drIdxs, 1 ), ones( 1, size( drIdxs, 2 ) ) );
            drIdxs = sub2ind( size( resample_weights ), drIdxs{:} );
            w = resample_weights( drIdxs );
            w(isnan(w)) = 1;
            robj = obj;
            robj.data(useIdxs,:) = robj.data(useIdxs,:) .* w;
            robj.dataIdxs(robj.data==0,:) = [];
            robj.data(robj.data==0,:) = [];
        end
        %% -------------------------------------------------------------------------------

        function dist = idxDistribution( obj, depIdx, defIdx )
            sobj = obj.summarizeDown( [defIdx, depIdx] );
            defIdx = 1 : numel( defIdx );
            depIdx = defIdx(end) + 1;
            maxDepIdx = max( sobj.dataIdxs(:,depIdx) );
            maxDefIdxs = cell( 1, numel( defIdx ) );
            for ii = 1 : numel( defIdx )
                maxDefIdxs{ii} = max( sobj.dataIdxs(:,defIdx(ii)) );
            end
            dist = nan( maxDefIdxs{:}, maxDepIdx );
            [defUniqueIdxs,~,ic] = unique( sobj.dataIdxs(:,defIdx), 'rows' );
            for ii = 1 : size( defUniqueIdxs, 1 )
                dui_ii = (ic == ii);
                depIdxs_dui = sobj.dataIdxs(dui_ii,depIdx);
                depData_dui = sobj.data(dui_ii,:);
                dui = num2cell( defUniqueIdxs(ii,:) );
                dist(dui{:},depIdxs_dui) = depData_dui;
            end
        end
        %% -------------------------------------------------------------------------------

        function [obj, sdo] = combineFun_legacy( obj, fun, cdim, argIdxs, cidx, newDataType, sdo )
            if nargin > 5 && ~isempty( newDataType )
                obj = obj.setDataType( newDataType );
            end
            nargs = numel( argIdxs );
            diDim = size( obj.dataIdxs, 2 );
            rowIdxs = cell( 1, nargs );
            for ii = 1 : nargs
                idxsMask = repmat( {':'}, 1, diDim );
                idxsMask{cdim} = @(x)(x == argIdxs(ii));
                rowIdxs{ii} = obj.getRowIdxs( idxsMask );
            end
            nri = cellfun( @numel, rowIdxs );
            newDataIdxs = zeros( sum( nri ), diDim );
            newData = zeros( sum( nri ), 1 );
            newSdo = cell( size( newData, 1 ), 2 );
            ndiIdx = 1;
            riIdx = ones( size( nri ) );
            curDataIdxs = zeros( nargs, diDim );
            iis = 1 : nargs;
            args = cell( 1, nargs );
            oldProgress = 0;
            while any( riIdx <= nri )
                progress = int8( 100 * sum( riIdx ) / sum( nri ) );
                if progress > oldProgress
                    fprintf( '.' );
                    oldProgress = progress;
                end
                for ii = iis
                    if riIdx(ii) > nri(ii)
                        curDataIdxs(ii,:) = inf( 1, diDim );
                    else
                        curDataIdxs(ii,:) = obj.dataIdxs(rowIdxs{ii}(riIdx(ii)),:);
                        curDataIdxs(ii,cdim) = cidx;
                    end
                end
                me = 1 : nargs;
                for cc = 1 : diDim
                    m = min( curDataIdxs(me,cc), [], 1 );
                    me = me(curDataIdxs(me,cc) == m);
                    if numel( me ) == 1, break; end;
                end
                newDataIdxs(ndiIdx,:) = curDataIdxs(me(1),:);
                iis = [];
                for ii = 1 : nargs
                    if any( ii == me )
                        if nargout > 1
                            newSdo{ndiIdx,1} = cat( 1, newSdo{ndiIdx,1}, sdo{rowIdxs{ii}(riIdx(ii)),1} );
                            newSdo{ndiIdx,2} = cat( 1, newSdo{ndiIdx,2}, sdo{rowIdxs{ii}(riIdx(ii)),2} );
                        end
                        args{ii} = obj.data(rowIdxs{ii}(riIdx(ii)));
                        riIdx(ii) = riIdx(ii) + 1;
                        iis(end+1) = ii;
                    else
                        args{ii} = obj.dataConvert( 0 );
                    end
                end
                newData(ndiIdx) = fun(args{:});
                ndiIdx = ndiIdx + 1;
            end
            newDataIdxs(ndiIdx:end,:) = [];
            newData(ndiIdx:end) = [];
            newSdo(ndiIdx:end,:) = [];
            delIdxs = unique( cat( 1, rowIdxs{:} ) );
            obj = obj.deleteData( delIdxs );
            [obj,incidxs,insidxs] = obj.addData( newDataIdxs, newData );
            if nargout > 1
                sdo(delIdxs,:) = [];
                sdo(end+1,:) = {[],[]};
                sdo = sdo(incidxs,:);
                sdo(insidxs,:) = newSdo;
            end
            fprintf( '\n' );
        end
        %% -------------------------------------------------------------------------------

        function [obj, sdo] = combineFun( obj, fun, cdim, argIdxs, cidx, newDataType, sdo )
            if nargin > 5 && ~isempty( newDataType )
                obj = obj.setDataType( newDataType );
            end
            nargs = numel( argIdxs );
            diDim = size( obj.dataIdxs, 2 );
            dDim = size( obj.data, 2 );
            argRowIdxs = cell( 1, nargs );
            argDataIdxs = cell( 1, nargs );
            argData = cell( 1, nargs );
            argGroups = cell( 1, nargs );
            for ii = 1 : nargs
                idxsMask = repmat( {':'}, 1, diDim );
                idxsMask{cdim} = @(x)(x == argIdxs(ii));
                argRowIdxs{ii} = obj.getRowIdxs( idxsMask );
                argDataIdxs{ii} = obj.dataIdxs(argRowIdxs{ii},:);
                argData{ii} = obj.data(argRowIdxs{ii},:);
                argGroups{ii} = repmat( ii, size( argRowIdxs{ii}, 1 ), 1 );
            end
            if all( cellfun( @isempty, argRowIdxs ) )
                return;
            end
            obj.dataIdxs(cat( 1, argRowIdxs{:} ),:) = [];
            obj.data(cat( 1, argRowIdxs{:} ),:) = [];
            funnedDataIdxs = cat( 1, argDataIdxs{:} );
            funnedDataIdxs(:,cdim) = cidx;
            [funnedDataIdxs,~,ic] = unique( funnedDataIdxs, 'rows' );
            funnedData = obj.dataConvert( zeros( size( funnedDataIdxs, 1 ), dDim ) );
            argGroups = cat( 1, argGroups{:} );
            icGrouped = splitapply( @(x)({x}), ic, argGroups );
            argData2beFunned = repmat( {funnedData}, 1, nargs );
            for ii = 1 : nargs
                argData2beFunned{ii}(icGrouped{ii},:) = argData{ii};
            end
            funnedData = fun( argData2beFunned{:} );
            obj = obj.addData( funnedDataIdxs, funnedData, true );
        end
        %% -------------------------------------------------------------------------------

        function [mat, sdomat] = resc2mat( obj, ridx2midx, rowIdxs, sdo )
            if nargin < 2 || isempty( ridx2midx )
                ridx2midx = repmat( {@(idx)(idx)}, 1, size( obj.dataIdxs, 2 ) );
            end
            if nargin < 3 || isempty( rowIdxs )
                rowIdxs = 1 : size( obj.dataIdxs, 1 );
            end
            midxs = obj.dataIdxs(rowIdxs,:);
            for ii = 1 : size( obj.dataIdxs, 2 )
                midxs(:,ii) = ridx2midx{ii}( midxs(:,ii) );
            end
            maxMidxs = num2cell( max( midxs, [], 1 ) );
            minMidxs = int16( min( midxs, [], 1 ) );
            mat(maxMidxs{:}) = 0;
            if nargout > 1
                sdomat{maxMidxs{:},2} = {};
            end
            midxs = midxs + repmat( uint8(max(0, 1 - minMidxs)), size( midxs, 1 ), 1 );
            midxs = num2cell( midxs );
            for ii = 1 : size( midxs, 1 )
                mat(midxs{ii,:}) = obj.data(rowIdxs(ii),:);
                if nargout > 1
                    sdomat(midxs{ii,:},:) = sdo(rowIdxs(ii),:);
                end
            end
        end
        %% -------------------------------------------------------------------------------

    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        function [idxAreEq,idxAisltB,idxAisgtB] = idxsCmp( idxsA, idxsB )
            idxAreEq = 0; idxAisltB = 0; idxAisgtB = 0;
%             if numel( idxsA ) ~= numel( idxsB )
%                 error( 'AMLTTP:implementation:unexpected', 'This should not have happened.' );
%             end
            for ii = 1 : size( idxsA, 2 )
                if idxsA(ii) < idxsB(ii)
                    idxAisltB = 1;
                    return;
                elseif idxsA(ii) > idxsB(ii)
                    idxAisgtB = 1;
                    return;
                end
            end
            idxAreEq = 1;
        end
        %% -------------------------------------------------------------------------------

end
    
end
