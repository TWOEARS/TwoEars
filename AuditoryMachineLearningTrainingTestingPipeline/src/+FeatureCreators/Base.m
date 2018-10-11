classdef Base < Core.IdProcInterface
    % Base Abstract base class for specifying features sets with which features
    % are extracted.
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        x;
        blockAnnotations;
        afeData;                    % current AFE signals used for vector construction
        description;
        descriptionBuilt = false;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        afeRequests = getAFErequests( obj )
        outputDeps = getFeatureInternOutputDependencies( obj )
        x = constructVector( obj ) % has to return a cell, first item the feature vector, 
                                   % second item the features description.
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = Base()
            obj = obj@Core.IdProcInterface();
        end
        %% -------------------------------------------------------------------------------
        
        function setAfeData( obj, afeData )
            obj.afeData = afeData;
        end
        %% -------------------------------------------------------------------------------
        
        function process( obj, wavFilepath )
            obj.inputProc.sceneId = obj.sceneId;
            inData = obj.loadInputData( wavFilepath );
            obj.blockAnnotations = inData.blockAnnotations;
            obj.x = [];
            for afeBlock = inData.afeBlocks'
                obj.afeData = afeBlock{1};
                xd = obj.constructVector();
                obj.x(end+1,:,:) = xd{1};
                fprintf( '.' );
                if obj.descriptionBuilt, continue; end
                obj.description = xd{2};
                obj.descriptionBuilt = true;
            end
        end
        %% -------------------------------------------------------------------------------
        
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function [out, outFilepath] = loadProcessedData( obj, wavFilepath, varargin )
            [tmpOut, outFilepath] = loadProcessedData@Core.IdProcInterface( ...
                                                     obj, wavFilepath );
            obj.x = tmpOut.x;
            if nargin < 3  || any( strcmpi( 'blockAnnotations', varargin ) )
                if isfield( tmpOut, 'blockAnnotations' ) % new version
                    obj.blockAnnotations = tmpOut.blockAnnotations;
                else % old version; ba was saved in blockCreator cache
                    obj.inputProc.sceneId = obj.sceneId;
                    inData = obj.loadInputData( wavFilepath, 'blockAnnotations' );
                    obj.blockAnnotations = inData.blockAnnotations;
                    obj.save( wavFilepath );
                end
            end
            out = obj.getOutput( varargin{:} );
            fdescFilepath = [obj.getCurrentFolder() filesep 'fdesc.mat'];
            if ~obj.descriptionBuilt 
                if exist( fdescFilepath, 'file' )
                    fdescFileSema = setfilesemaphore( fdescFilepath, 'semaphoreOldTime', 30 );
                    ld = load( fdescFilepath, 'description' );
                    obj.description = ld.description;
                    removefilesemaphore( fdescFileSema );
                    obj.descriptionBuilt = true;
                else
                    warning( ['%s not found, delete at least one used cache file in ' ...
                              'this folder to rebuild description.'], fdescFilepath );
                end
            end
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function save( obj, wavFilepath, ~ )
            out.x = obj.x;
            out.blockAnnotations = obj.blockAnnotations;
            save@Core.IdProcInterface( obj, wavFilepath, out ); 
            fdescFilepath = [obj.getCurrentFolder() filesep 'fdesc.mat'];
            if obj.descriptionBuilt && ~exist( fdescFilepath, 'file' )
                description = obj.description; %#ok<NASGU,PROPLC>
                fdescFileSema = setfilesemaphore( fdescFilepath, 'semaphoreOldTime', 30 );
                save( fdescFilepath, 'description' );
                removefilesemaphore( fdescFileSema );
            end
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.v = 4;
            outputDeps.featureProc = obj.getFeatureInternOutputDependencies();
        end
        %% -------------------------------------------------------------------------------

        function out = getOutput( obj, varargin )
            if nargin < 2  || any( strcmpi( 'blockAnnotations', varargin ) )
                out.blockAnnotations = obj.blockAnnotations;
            end
            if nargin < 2  || any( strcmpi( 'x', varargin ) )
                out.x = obj.x;
            end
        end
        %% ------------ Feature Description Utilities ------------------------------------

        function b = makeBlockFromAfe( obj, afeIdx, chIdx, func, grps, varargin )
            % makeBlockFromAfe transform AFE data into a feature block
            %
            afedat = obj.afeData(afeIdx);
            % handle single channel AFE data not stored inside a cell,
            % in that case the channel index is ingored
            if isa(afedat, 'cell')
                afedat = afedat{chIdx};
            end
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
                    b1ii{1,jj} = { b2{:}, vaiic{:,jj} };
                end
                b{1+ii} = b1ii;
                clear b1ii;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function b = combineBlocks( obj, combFun, grpAdd, varargin )
            bs = vertcat( varargin{:} );
            bva = cat( 1, bs(:,1) );
            b{1} = combFun( bva{:} );
            if obj.descriptionBuilt, return; end
            for ii = 2 : size( bs, 2 )
                b{ii} = FeatureCreators.Base.joinGrps( bs(:,ii) );
                b{ii} = FeatureCreators.Base.removeGrpDuplicates( b{ii} );
                b{ii} = cellfun( @(g)([g grpAdd]), b{ii}, 'UniformOutput', false );
            end
        end
        %% -------------------------------------------------------------------------------

        function b = concatBlocks( obj, dim, varargin )
            bs = vertcat( varargin{:} );
            b{1} = cat( dim, bs{:,1} );
            if obj.descriptionBuilt, return; end
            d = 1 : size( bs, 2 ) - 1;
            d(dim) = [];
            for ii = d
                b{1+d} = FeatureCreators.Base.joinGrps( bs(:,1+d) );
                b{1+d} = FeatureCreators.Base.removeGrpDuplicates( b{1+d} );
            end
            b{1+dim} = cat( dim, bs{:,1+dim} );
        end
        %% -------------------------------------------------------------------------------

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
        %% -------------------------------------------------------------------------------

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
            grps(2:end,:) = [];
            grps = FeatureCreators.Base.removeGrpDuplicates( grps );
            b{2} = grps;
        end
        %% -------------------------------------------------------------------------------

        function b = reshape2timeSeriesFeatVec( obj, bl )
            b{1} = reshape( bl{1}, size( bl{1}, 1), [] );
            if obj.descriptionBuilt, return; end
            for ii = 2 : size( bl, 2 ) - 1
                bl{ii} = bl{ii+1};
            end
            bl(end) = [];
            for ii = 1 : size( bl, 2 ) - 1
                blszii = size( bl{1} );
                blszii(ii+1) = 1;
                blszii(1) = [];
                dgprs{ii} = repmat( shiftdim( bl{ii+1}, 2-ii ), blszii );
                dgprs{ii} = reshape( dgprs{ii}, 1, [] );
            end
            grps = cat( 1, dgprs{:} );
            for ii = 1 : size( grps, 2 )
                grps{1,ii} = cat( 2, grps{:,ii} );
            end
            grps(2:end,:) = [];
            grps = FeatureCreators.Base.removeGrpDuplicates( grps );
            b{2} = grps;
        end
        %% -------------------------------------------------------------------------------

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
            grps = FeatureCreators.Base.removeGrpDuplicates( grps );
            b{1+odim(dim)} = grps;
            b{1+dim} = bl{1+dim};
        end
        %% -------------------------------------------------------------------------------

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
        %% -------------------------------------------------------------------------------

        function x = concatFeats( obj, varargin )
            xs = cat( 1, varargin{:} );
            x{1} = cat( 2, xs{:,1} );
            if obj.descriptionBuilt, return; end
            x{2} = cat( 2, xs{:,2} );
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        function b1d = joinGrps( bs )
            bs1d = cat( 1, bs{:} );
            for jj = 1 : size( bs1d, 2 )
                b1d{1,jj} = cat( 2, bs1d{:,jj} );
            end
        end
        %% -------------------------------------------------------------------------------

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
    %% -----------------------------------------------------------------------------------
        
    end
    
end

        

