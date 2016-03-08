classdef Base < core.IdProcInterface

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        shiftSize_s;
        minBlockToEventRatio;
        x;
        y;
        blockSize_s;
        labelBlockSize_s;
        afeData;
        description;
        descriptionBuilt = false;
    end
    
    %% --------------------------------------------------------------------
    methods (Abstract)
        afeRequests = getAFErequests( obj )
        outputDeps = getFeatureInternOutputDependencies( obj )
        x = constructVector( obj )
    end

    %% --------------------------------------------------------------------
    methods
        
        function obj = Base( blockSize_s, shiftsize_s, minBlockToEventRatio, labelBlockSize_s )
            obj = obj@core.IdProcInterface();
            obj.blockSize_s = blockSize_s;
            obj.shiftSize_s = shiftsize_s;
            obj.minBlockToEventRatio = minBlockToEventRatio;
            obj.labelBlockSize_s = labelBlockSize_s;
        end
        %% ----------------------------------------------------------------
        
        function setAfeData( obj, afeData )
            obj.afeData = afeData;
        end
        %% ----------------------------------------------------------------
        
        function process( obj, inputFileName )
            in = load( inputFileName );
            [afeBlocks, obj.y] = obj.blockifyAndLabel( in.afeData, in.onOffsOut, in.annotsOut );
            obj.x = [];
            for afeBlock = afeBlocks
                obj.afeData = afeBlock{1};
                xd = obj.constructVector();
                obj.x(end+1,:) = xd{1};
                fprintf( '.' );
                if obj.descriptionBuilt, continue; end
                obj.description = xd{2};
                obj.descriptionBuilt = true;
            end
        end
        %% ----------------------------------------------------------------
        
        function dummyProcess( obj, afeDummy )
            [afeBlocks, ~] = obj.blockifyAndLabel( afeDummy.afeData, [], [] );
            obj.afeData = afeBlocks{1};
            xd = obj.constructVector();
            obj.description = xd{2};
            obj.descriptionBuilt = true;
        end
            
        %% ----------------------------------------------------------------

        function afeBlock = cutDataBlock( obj, afeData, backOffset_s )
            afeBlock = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
            for afeKey = afeData.keys
                afeSignal = afeData(afeKey{1});
                if isa( afeSignal, 'cell' )
                    for ii = 1 : numel( afeSignal )
                        afeSignalExtract{ii} = afeSignal{ii}.cutSignalCopy( obj.blockSize_s, backOffset_s );
                        afeSignalExtract{ii}.reduceBufferToArray();
                    end
                else
                    afeSignalExtract = afeSignal.cutSignalCopy( obj.blockSize_s, backOffset_s );
                    afeSignalExtract.reduceBufferToArray();
                end
                afeBlock(afeKey{1}) = afeSignalExtract;
                fprintf( '.' );
            end
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.blockSize = obj.blockSize_s;
            outputDeps.labelBlockSize = obj.labelBlockSize_s;
            outputDeps.shiftSize = obj.shiftSize_s;
            outputDeps.minBlockEventRatio = obj.minBlockToEventRatio;
            outputDeps.featureProc = obj.getFeatureInternOutputDependencies();
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out.x = obj.x;
            out.y = obj.y;
        end
        %% ----------------------------------------------------------------

        function [afeBlocks, y] = blockifyAndLabel( obj, afeData, onOffs_s, annotsOut )
            afeBlocks = {};
            y = [];
            afeDataNames = afeData.keys;
            anyAFEsignal = afeData(afeDataNames{1});
            if isa( anyAFEsignal, 'cell' ), anyAFEsignal = anyAFEsignal{1}; end;
            sigLen = double( length( anyAFEsignal.Data ) ) / anyAFEsignal.FsHz;
            for backOffset_s = 0.0 : obj.shiftSize_s : max(sigLen+0.01,obj.shiftSize_s) - obj.shiftSize_s
                afeBlocks{end+1} = obj.cutDataBlock( afeData, backOffset_s );
                blockOffset = sigLen - backOffset_s;
                labelBlockOnset = blockOffset - obj.labelBlockSize_s;
                y(end+1) = -1;
                for jj = 1 : size( onOffs_s, 1 )
                    eventOnset = onOffs_s(jj,1);
                    eventOffset = onOffs_s(jj,2);
                    eventBlockOverlapLen = ...
                        min( blockOffset, eventOffset ) - ...
                        max( labelBlockOnset, eventOnset );
                    eventLength = eventOffset - eventOnset;
                    maxBlockEventLen = min( obj.labelBlockSize_s, eventLength );
                    relEventBlockOverlap = eventBlockOverlapLen / maxBlockEventLen;
                    blockIsSoundEvent = relEventBlockOverlap > obj.minBlockToEventRatio;
                    blockIsAmbigous = relEventBlockOverlap > (1-obj.minBlockToEventRatio); 
                    if blockIsSoundEvent
                        y(end) = 1;
                        if isfield( annotsOut, 'srcEnergy' ) && ...
                           size( annotsOut.srcEnergy, 1 ) == 2 % there is ONE distractor
                            energyBlockIdxs = ...
                                annotsOut.srcEnergy_t >= blockOffset - obj.blockSize_s ...
                                & annotsOut.srcEnergy_t <= blockOffset;
                            distBlockEnergy = ...
                                mean(mean(annotsOut.srcEnergy(2,:,energyBlockIdxs)));
                            if distBlockEnergy < -30, y(end) = 0; end
                        end
                        break;
                    elseif blockIsAmbigous
                        y(end) = 0;
                    end;
                end
            end
            afeBlocks = fliplr( afeBlocks );
            y = fliplr( y );
            y = y';
        end
        %% ----------------------------------------------------------------

        function b = makeBlockFromAfe( obj, afeIdx, chIdx, func, grps, varargin )
            afedat = obj.afeData(afeIdx);
            afedat = afedat{chIdx};
            b{1} = func( afedat );
            if obj.descriptionBuilt, return; end
            b2 = {};
            for ii = 1 : length( grps )
                if isa( grps{ii}, 'function_handle' )
                    fg = grps{ii};
                    b2{end+1} = fg( afedat );
                elseif ischar( grps{ii} )
                    b2{end+1} = grps{ii};
                end
            end
            for ii = 1 : length( varargin )
                vaii = varargin{ii};
                for jj = 1 : numel( vaii )
                    if isa( vaii{jj}, 'function_handle' )
                        fd = vaii{jj};
                        vaii{jj} = fd( afedat );
                    end
                    if isnumeric( vaii{jj} )
                        vaii{jj} = num2cell( vaii{jj}, numel( vaii{jj} ) );
                    end
                    if numel( vaii{jj} ) ~= size( b{1}, ii )
                        vaii{1} = repmat( vaii(1), 1, size( b{1}, ii ) );
                    end
                end
                if numel( vaii ) > 1 && numel( vaii{2} ) ~= size( b{1}, ii )
                    warning( 'dimensions not consistent' );
                end
                vaiic = cat( 1, vaii{:} );
                for jj = 1 : size( vaii{1}, 2 )
                    b1ii{1,jj} = { b2{:}, vaiic{:,jj}};
                end
                b{1+ii} = b1ii;
                clear b1ii;
            end
        end
        %% ----------------------------------------------------------------
        
        function b = combineBlocks( obj, combFun, grpAdd, varargin )
            bs = vertcat( varargin{:} );
            bva = cat( 1, bs(:,1) );
            b{1} = combFun( bva{:} );
            if obj.descriptionBuilt, return; end
            for ii = 2 : size( bs, 2 )
                b{ii} = featureCreators.Base.joinGrps( bs(:,ii) );
                b{ii} = featureCreators.Base.removeGrpDuplicates( b{ii} );
                b{ii} = cellfun( @(g)([g grpAdd]), b{ii}, 'UniformOutput', false );
            end
        end
        %% ----------------------------------------------------------------

        function b = concatBlocks( obj, dim, varargin )
            bs = vertcat( varargin{:} );
            b{1} = cat( dim, bs{:,1} );
            if obj.descriptionBuilt, return; end
            d = 1 : size( bs, 2 ) - 1;
            d(dim) = [];
            for ii = d
                b{1+d} = featureCreators.Base.joinGrps( bs(:,1+d) );
                b{1+d} = featureCreators.Base.removeGrpDuplicates( b{1+d} );
            end
            b{1+dim} = cat( dim, bs{:,1+dim} );
        end
        %% ----------------------------------------------------------------

        function b = transformBlock( obj, bl, dim, func, dIdxFun, grps )
            b{1} = func( bl{1} );
            if obj.descriptionBuilt, return; end
            d = 1 : size( bl, 2 ) - 1;
            d(dim) = [];
            for ii = d
                b{1+ii} = bl{1+ii};
                for jj = 1 : numel( b{1+ii} )
                    b{1+ii}{jj} = [b{1+ii}{jj} grps];
                end
            end
            bl1dIdxs = dIdxFun( 1 : numel( bl{1+dim} ) );
            b{1+dim} = bl{1+dim}(bl1dIdxs);
        end
        %% ----------------------------------------------------------------

        function b = reshape2featVec( obj, bl )
            b{1} = reshape( bl{1}, 1, [] );
            if obj.descriptionBuilt, return; end
            for ii = 1 : size( bl, 2 ) - 1
                blszii = size( bl{1} );
                blszii(ii) = 1;
                dgprs{ii} = repmat( shiftdim( bl{ii+1}, 2-ii ), blszii );
                dgprs{ii} = reshape( dgprs{ii}, 1, [] );
            end
            grps = cat( 1, dgprs{:} );
            for ii = 1 : size( grps, 2 )
                grps{1,ii} = cat( 2, grps{:,ii} );
            end
            grps(2,:) = [];
            grps = featureCreators.Base.removeGrpDuplicates( grps );
            b{2} = grps;
        end
        %% ----------------------------------------------------------------

        function b = reshapeBlock( obj, bl, dim )
            rsz = { [], [] };
            rsz{dim} = size( bl{1}, dim );
            b{1} = reshape( bl{1}, rsz{:} );
            if obj.descriptionBuilt, return; end
            d = 1 : size( bl, 2 ) - 1;
            d(dim) = [];
            grps = {};
            dallidx = { ':', ':' };
            dallidx{dim} = 1;
            for ii = 1 : numel( d )
                blszii = size( bl{1} );
                blszii(d(ii)) = 1;
                dgprs{ii} = repmat( shiftdim( bl{d(ii)+1}, 2-d(ii) ), blszii );
                dgprs{ii} = reshape( dgprs{ii}, rsz{:} );
                dgprs{ii} = dgprs{ii}(dallidx{1},dallidx{2});
            end
            grps = cat( dim, dgprs{:} );
            odim = [2 1];
            for ii = 1 : size( grps, odim(dim) )
                iidim = { ':', ':' };
                iidim{odim(dim)} = ii;
                iidim2 = { 1, 1 };
                iidim2{odim(dim)} = ii;
                grps{iidim2{1},iidim2{2}} = cat( 2, grps{iidim{1},iidim{2}} );
            end
            ddim = { ':', ':' };
            ddim{dim} = 2;
            grps(ddim{1},ddim{2}) = [];
            grps = featureCreators.Base.removeGrpDuplicates( grps );
            b{1+odim(dim)} = grps;
            b{1+dim} = bl{1+dim};
        end
        %% ----------------------------------------------------------------

        function x = block2feat( obj, b, func, dim, grpsIdxFun, grpsFun )
            x{1} = func( b{1} );
            if obj.descriptionBuilt, return; end
            grpsIdx = grpsIdxFun( 1:size( b{1}, dim ) );
            grps = b{1+dim}(grpsIdx);
            for ii = 1 : numel( grpsFun )
                gf = grpsFun{ii}{2};
                gfi = gf(1:numel(grps));
                for jj = gfi
                    grps{jj}{end+1} = grpsFun{ii}{1};
                end
            end
            x{2} = grps;
        end
        %% ----------------------------------------------------------------

        function x = concatFeats( obj, varargin )
            xs = cat( 1, varargin{:} );
            x{1} = cat( 2, xs{:,1} );
            if obj.descriptionBuilt, return; end
            x{2} = cat( 2, xs{:,2} );
        end
        %% ----------------------------------------------------------------
        
    end
    %% --------------------------------------------------------------------
    
    methods (Static)
        
        %% ----------------------------------------------------------------
        function b1d = joinGrps( bs )
            bs1d = cat( 1, bs{:} );
            for jj = 1 : size( bs1d, 2 )
                b1d{1,jj} = cat( 2, bs1d{:,jj} );
            end
        end
        %% ----------------------------------------------------------------

        function g = removeGrpDuplicates( g )
            for jj = 1 : size( g, 2 )
                strs = {};
                nums = {};
                dels = [];
                for kk = 1 : size( g{jj}, 2 )
                    if ischar( g{jj}{kk} )
                        if ~any( strcmp( strs, g{jj}{kk} ) )
                            strs{end+1} = g{jj}{kk};
                        else
                            dels(end+1) = kk;
                        end
                    else
                        if ~any( cellfun( @(n)(eq(n,g{jj}{kk})), nums ) )
                            nums{end+1} = g{jj}{kk};
                        else
                            dels(end+1) = kk;
                        end
                    end
                end
                for kk = numel( dels ) : -1 : 1
                    g{jj}(dels(kk)) = [];
                end
                clear dels;
                clear strs;
                clear nums;
            end
        end
        %% ----------------------------------------------------------------
        
    end
    
end

        

