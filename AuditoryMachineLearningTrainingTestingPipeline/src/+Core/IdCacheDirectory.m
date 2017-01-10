classdef IdCacheDirectory < handle
    
    properties (Access = protected)
        treeRoot;
        topCacheDirectory;
        cacheDirectoryFilename = 'cacheDirectory.mat';
        cacheFileInfo;
        cacheFileRWsema;
        cacheDirChanged;
        cacheSingleProcessSema;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = IdCacheDirectory()
            obj.treeRoot = Core.IdCacheTreeElem();
            obj.cacheFileInfo = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            obj.cacheDirChanged = false;
        end
        %% -------------------------------------------------------------------------------
        
        function delete( obj )
            obj.saveCacheDirectory();
            obj.releaseSingleProcessCacheAccess();
        end
        %% -------------------------------------------------------------------------------
        
        function setCacheTopDir( obj, topDir, createIfnExist )
            if ~exist( topDir, 'dir' ) 
                if nargin > 2 && createIfnExist
                    mkdir( topDir );
                else
                    error( '"%s" cannot be found', topDir );
                end
            end
            obj.topCacheDirectory = cleanPathFromRelativeRefs( topDir );
        end
        %% -------------------------------------------------------------------------------
        
        function filepath = getCacheFilepath( obj, cfg, createIfnExist )
            if isempty( cfg ), filepath = obj.topCacheDirectory; return; end
            if nargin < 3, createIfnExist = false; end
            treeNode = obj.findCfgTreeNode( cfg, createIfnExist );
            if isempty( treeNode ), filepath = []; return; end
            if isempty( treeNode.path ) && createIfnExist
                treeNode.path = obj.makeNewCacheFolder( cfg );
                obj.cacheDirChanged = true;
            end
            filepath = treeNode.path;
        end
        %% -------------------------------------------------------------------------------

        function getSingleProcessCacheAccess( obj )
            if ~isempty( obj.cacheSingleProcessSema ), return; end
            cacheFilepath = [obj.topCacheDirectory filesep obj.cacheDirectoryFilename];
            cacheSpFilepath = [cacheFilepath '.singleProcess'];
            obj.cacheSingleProcessSema = setfilesemaphore( cacheSpFilepath );
        end
        %% -------------------------------------------------------------------------------
        
        function releaseSingleProcessCacheAccess( obj )
            removefilesemaphore( obj.cacheSingleProcessSema );
            obj.cacheSingleProcessSema = [];
        end
        %% -------------------------------------------------------------------------------
        
        function saveCacheDirectory( obj, filename )
            if nargin < 2 
                filename = obj.cacheDirectoryFilename;
            end
            if ~isempty( [strfind( filename, '/' ), strfind( filename, '\' )] )
                error( 'filename supposed to be only file name without any path' );
            end
            if ~obj.cacheDirChanged, return; end
            obj.cacheDirectoryFilename = filename;
            cacheFilepath = [obj.topCacheDirectory filesep obj.cacheDirectoryFilename];
            cacheWriteFilepath = [cacheFilepath '.write'];
            cacheWriteSema = setfilesemaphore( cacheWriteFilepath );
            obj.cacheFileRWsema.getReadAccess();
            newCacheFileInfo = dir( cacheFilepath );
            obj.cacheFileRWsema.releaseReadAccess();
            if ~isempty( newCacheFileInfo ) && ...
                    ~isequalDeepCompare( newCacheFileInfo, obj.cacheFileInfo(cacheFilepath) )
                obj.cacheFileRWsema.getReadAccess();
                Parameters.dynPropsOnLoad( true, false );
                newCacheFile = load( cacheFilepath );
                Parameters.dynPropsOnLoad( true, true );
                obj.cacheFileRWsema.releaseReadAccess();
                obj.treeRoot.integrateOtherTreeNode( newCacheFile.cacheTree );
            end
            cacheTree = obj.treeRoot;
            save( cacheWriteFilepath, 'cacheTree' );
            obj.cacheFileRWsema.getWriteAccess();
            copyfile( cacheWriteFilepath, cacheFilepath ); % this blocks cacheFile shorter
            obj.cacheFileInfo(cacheFilepath) = dir( cacheFilepath );
            obj.cacheFileRWsema.releaseWriteAccess();
            delete( cacheWriteFilepath );
            removefilesemaphore( cacheWriteSema );
            obj.cacheDirChanged = false;
        end
        %% -------------------------------------------------------------------------------
        
        function loadCacheDirectory( obj, filename )
            if nargin < 2
                filename = obj.cacheDirectoryFilename;
            end
            if ~isempty( [strfind( filename, '/' ), strfind( filename, '\' )] )
                error( 'filename supposed to be only file name without any path' );
            end
            obj.cacheDirectoryFilename = filename;
            cacheFilepath = [obj.topCacheDirectory filesep obj.cacheDirectoryFilename];
            if ~obj.cacheFileInfo.isKey( cacheFilepath )
                obj.cacheFileRWsema = ReadersWritersFileSemaphore( cacheFilepath );
                if exist( cacheFilepath, 'file' )
                    obj.cacheFileRWsema.getReadAccess();
                    Parameters.dynPropsOnLoad( true, false ); % don't load unnecessary stuff
                    obj.cacheFileInfo(cacheFilepath) = dir( cacheFilepath ); % for later comparison
                    cacheFile = load( cacheFilepath );
                    Parameters.dynPropsOnLoad( true, true );
                    obj.cacheFileRWsema.releaseReadAccess();
                    obj.treeRoot = cacheFile.cacheTree;
                    obj.cacheDirChanged = false;
                else
                    warning( 'could not load %s', cacheFilepath );
                    obj.cacheFileInfo(cacheFilepath) = [];
                end
            else
                try
                    newCacheFileInfo = dir( cacheFilepath );
                catch
                    % another process just have written the cache, try again
                    pause(1);
                    newCacheFileInfo = dir( cacheFilepath );
                end
                if ~isempty( newCacheFileInfo ) && ~isequalDeepCompare( ...
                                      newCacheFileInfo, obj.cacheFileInfo(cacheFilepath) )
                    obj.cacheFileRWsema.getReadAccess();
                    Parameters.dynPropsOnLoad( true, false );
                    newCacheFile = load( cacheFilepath );
                    Parameters.dynPropsOnLoad( true, true );
                    obj.cacheFileRWsema.releaseReadAccess();
                    obj.cacheDirChanged = ...
                            obj.treeRoot.integrateOtherTreeNode( newCacheFile.cacheTree );
                    obj.cacheFileInfo(cacheFilepath) = newCacheFileInfo;
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
        function maintenance( obj )
            cDirs = dir( [obj.topCacheDirectory filesep 'cache.*'] );
            cacheDirs = cell( 0, 3 );
            fprintf( '-> read cache folders\n' );
            for ii = 1 : numel( cDirs )
                fprintf( '%d/%d ', ii, numel( cDirs ) );
                if ~exist( [obj.topCacheDirectory filesep cDirs(ii).name filesep 'cfg.mat'], 'file' )
                    fprintf( '''%s'' does not contain a ''cfg.mat''.\nPress key to continue\n', cDirs(ii).name );
                    pause;
                else
                    cdContents = dir( [obj.topCacheDirectory filesep cDirs(ii).name filesep '*.mat'] );
                    if all( strcmpi( 'cfg.mat', {cdContents.name} ) | strcmpi( 'fdesc.mat', {cdContents.name} ) )
                        rmdir( [obj.topCacheDirectory filesep cDirs(ii).name], 's' );
                        fprintf( 'deleting empty cache folder ' );
                    else
                        cacheDirs{end+1,1} = [obj.topCacheDirectory filesep cDirs(ii).name];
                        cl = load( [cacheDirs{end,1} filesep 'cfg.mat'], 'cfg' );
                        cacheDirs{end,2} = Core.IdCacheDirectory.unfoldCfgStruct( cl.cfg );
                    end
                end
            end
            fprintf( '\n' );
            fprintf( '-> find cache folder duplicates\n' );
            for ii = 1 : size( cacheDirs, 1 )-1
                fprintf( '%d/%d ', ii, size( cacheDirs, 1 )-1 );
            for jj = ii+1 : size( cacheDirs, 1 )
                if isequalDeepCompare( cacheDirs{ii,2}, cacheDirs{jj,2} )
                    cacheDirs{ii,3} = [cacheDirs{ii,3} jj];
                    cacheDirs{jj,3} = [cacheDirs{jj,3} ii];
                end
            end
            end
            fprintf( '\n' );
            fprintf( '-> findAllLeaves\n' );
            [leaves, ucfgs] = obj.treeRoot.findAllLeaves( [] );
            if numel( leaves ) == 1  && leaves(1) == obj.treeRoot
                leaves = [];
                ucfgs = {};
            end
            remCfgs = {};
            deleteCdIdxs = [];
            fprintf( '-> check leaves ' );
            for ii = 1 : numel( leaves )
                leafPath = leaves(ii).path;
                cdIdx = find( strcmp( leafPath, cacheDirs(:,1) ) );
                if isempty( cdIdx ) % leafPath not existing
                    remCfgs{end+1} = ucfgs{ii}; % remove cfg from tree
                elseif ~isequalDeepCompare( ucfgs{ii}, cacheDirs{cdIdx,2} ) % leafPath hosts differing cfg
                    remCfgs{end+1} = ucfgs{ii}; % remove cfg from tree
                elseif ~isempty( cacheDirs{cdIdx,3} ) % leafPath has same cfg, but duplicate folders existing
                    for jj = cacheDirs{cdIdx,3}
                        fprintf( ':' );
                        duplDir = cacheDirs{jj,1};
                        Core.IdCacheDirectory.cacheDuplicateRemove( leafPath, duplDir );
                    end
                    deleteCdIdxs = [deleteCdIdxs cdIdx cacheDirs{cdIdx,3}]; % remove leafPath and duplicate folders from folder list
                else % leafPath hosts same cfg as tree
                    deleteCdIdxs = [deleteCdIdxs cdIdx]; % remove leafPath from folder list
                end
                fprintf( '%d/%d ', ii, numel( leaves ) );
            end
            fprintf( '\n' );
            [cacheDirs{deleteCdIdxs,:}] = deal( [] ); % remove folder pathes that are found and valid
            fprintf( '-> deleteCfg ' ); % delete cfgs that have not been found in folders
            for ii = 1 : numel( remCfgs )
                obj.treeRoot.deleteCfg( remCfgs{ii} );
                obj.cacheDirChanged = true;
                fprintf( '%d/%d ', ii, numel( remCfgs ) );
            end
            fprintf( '\n' );
            ii = 1;
            fprintf( '-> unregistered duplicates ' );
            while any( false == cellfun( @isempty, cacheDirs(:,3) ) )
                if ~isempty( cacheDirs{ii,3} )
                    fprintf( '%d/%d ', ii, sum( ~cellfun( @isempty, cacheDirs(:,3) ) ) );
                    for jj = cacheDirs{ii,3}
                        fprintf( ':' );
                        duplDir = cacheDirs{jj,1};
                        Core.IdCacheDirectory.cacheDuplicateRemove( cacheDirs{ii,1}, duplDir );
                    end
                    [cacheDirs{cacheDirs{ii,3},:}] = deal( [] );
                    cacheDirs{ii,3} = [];
                else
                    ii = ii + 1;
                end
            end
            fprintf( '\n' );
            cacheDirs(all( cellfun(@isempty,cacheDirs), 2 ),:) = [];
            fprintf( '-> add unregistered ' );
            for ii = 1 : size( cacheDirs, 1 )
                newCacheLeaf = obj.treeRoot.getCfg( cacheDirs{ii,2}, true );
                newCacheLeaf.path = cacheDirs{ii,1};
                obj.cacheDirChanged = true;
                fprintf( '%d/%d ', ii, size( cacheDirs, 1 ) );
            end
            fprintf( '\n' );
            fprintf( '-> saveCacheDirectory\n' );
            obj.saveCacheDirectory();
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function treeNode = findCfgTreeNode( obj, cfg, createIfMissing )
            if nargin < 3, createIfMissing = false; end
            ucfg = Core.IdCacheDirectory.unfoldCfgStruct( cfg );
            treeNode = obj.treeRoot.getCfg( ucfg, createIfMissing );
        end
        %% -------------------------------------------------------------------------------
        
        function folderName = makeNewCacheFolder( obj, cfg )
            timestr = buildCurrentTimeString( true );
            folderName = [obj.topCacheDirectory filesep 'cache' timestr];
            mkdir( folderName );
            save( [folderName filesep 'cfg.mat'], 'cfg' );
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Static)
        
        function ucfg = unfoldCfgStruct( cfg, sortUcfgArray, prefix )
            if ~isstruct( cfg )
                error( 'cfg has to be struct' ); 
            end
            if numel( cfg ) > 1
                error( 'cfg must not be array' );
            end
            if nargin < 2, sortUcfgArray = true; end
            if nargin < 3
                prefix = ''; 
            else
                prefix = [prefix '_'];
            end
            cfgFieldnames = fieldnames( cfg );
            cfgSubCfgIdxs = cellfun( @(cf)(isstruct( cfg.(cf) )), cfgFieldnames );
            subCfgFieldnames = cfgFieldnames(cfgSubCfgIdxs);
            uSubCfgs = cellfun( ...
                   @(fn)(Core.IdCacheDirectory.unfoldCfgStruct( cfg.(fn), ...
                                                                false, [prefix fn] )),...
                   subCfgFieldnames, 'UniformOutput', false );
            cfg = rmfield( cfg, cfgFieldnames(cfgSubCfgIdxs) );
            cfgFieldnames = cfgFieldnames(~cfgSubCfgIdxs);
            if isempty( cfgFieldnames )
                ucfg = struct('fieldname',{},'field',{});
            else
                ucfg = cellfun( @(sf,fn)(struct('fieldname',[prefix fn],'field',{sf})),...
                                  struct2cell( cfg ), cfgFieldnames );
            end
            ucfg = vertcat( ucfg, uSubCfgs{:} );
            if sortUcfgArray
                [~, order] = sort( {ucfg.fieldname} );
                ucfg = ucfg(order);
            end
        end
        %% -------------------------------------------------------------------------------
        
        function standaloneMaintain( cacheTopDir )
            cache = Core.IdCacheDirectory();
            cache.setCacheTopDir( cacheTopDir );
            cache.loadCacheDirectory();
            cache.maintenance();
        end
        %% -------------------------------------------------------------------------------
        
        function cacheDuplicateRemove( dir1, dir2 ) % dir2 will be removed
            fprintf( '\ncopy from ''%s'' to ''%s''', dir2, dir1 );
            d1_to_d2 = dir( [dir1 filesep '*.mat'] );
            d2_to_d1 = dir( [dir2 filesep '*.mat'] );
            d1_to_d2_copy = d1_to_d2;
            d2_to_d1_copy = d2_to_d1;
            for ii = numel( d1_to_d2 ) : -1 : 1
                fileContainedInD2 = strcmp( d1_to_d2(ii).name, {d2_to_d1(:).name} );
                if ~any( fileContainedInD2 )
                    continue; % needs to be copied
                elseif (d1_to_d2(ii).bytes ~= d2_to_d1(fileContainedInD2).bytes) && ...
                        (d1_to_d2(ii).datenum > d2_to_d1(fileContainedInD2).datenum)
                    continue; % needs to be copied
                else
                    d1_to_d2_copy(ii) = []; % same or newer file in dir2
                end
            end
            for ii = numel( d2_to_d1 ) : -1 : 1
                fileContainedInD1 = strcmp( d2_to_d1(ii).name, {d1_to_d2(:).name} );
                if ~any( fileContainedInD1 )
                    continue; % needs to be copied
                elseif (d2_to_d1(ii).bytes ~= d1_to_d2(fileContainedInD1).bytes) && ...
                        (d2_to_d1(ii).datenum > d1_to_d2(fileContainedInD1).datenum)
                    continue; % needs to be copied
                else
                    d2_to_d1_copy(ii) = []; % same or newer file in dir1
                end
            end
            d1_to_d2_bytes = sum( [d1_to_d2_copy(:).bytes] );
            d2_to_d1_bytes = sum( [d2_to_d1_copy(:).bytes] );
            if d1_to_d2_bytes < d2_to_d1_bytes
                for ii = 1 : numel( d1_to_d2_copy )
                    copyfile( fullfile( dir1, d1_to_d2_copy(ii).name ), fullfile( dir2, filesep ) );
                    fprintf( '.' );
                end
                rmdir( dir1, 's' );
                movefile( dir2, dir1 );
            else
                for ii = 1 : numel( d2_to_d1_copy )
                    copyfile( fullfile( dir2, d2_to_d1_copy(ii).name ), fullfile( dir1, filesep ) );
                    fprintf( '.' );
                end
                rmdir( dir2, 's' );
            end
            fprintf( '\n' );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
end
