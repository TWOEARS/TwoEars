classdef (Abstract) IdProcInterface < handle
    %% data file processor
    %
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        procName;
        cacheSystemDir;
        nPathLevelsForCacheName = 3;
    end
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected, Transient = true)
        cacheDirectory;
        inputProc;
        idData;
        lastFolder = {};
        lastConfig = {};
        outFileSema;
        sceneId = 1;
        saveImmediately = true;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function delete( obj )
            removefilesemaphore( obj.outFileSema );
            if ~isempty( obj.cacheDirectory )
                obj.saveCacheDirectory();
            end
        end
        %% -------------------------------------------------------------------------------
        
        function saveCacheDirectory( obj )
            obj.cacheDirectory.saveCacheDirectory();
        end
        %% -------------------------------------------------------------------------------
        
        function loadCacheDirectory( obj )
            obj.cacheDirectory.loadCacheDirectory();
        end
        %% -------------------------------------------------------------------------------

        function getSingleProcessCacheAccess( obj )
            obj.cacheDirectory.getSingleProcessCacheAccess();
        end
        %% -------------------------------------------------------------------------------
        
        function releaseSingleProcessCacheAccess( obj )
            obj.cacheDirectory.releaseSingleProcessCacheAccess();
        end
        %% -------------------------------------------------------------------------------

        function connectIdData( obj, idData )
            obj.idData = idData;
        end
        %% -------------------------------------------------------------------------------
        
        function init( obj )
            obj.lastFolder = {};
            obj.lastConfig = {};
            obj.sceneId = 1;
        end
        %% -------------------------------------------------------------------------------
        
        function out = saveOutput( obj, wavFilepath )
            out = obj.getOutput();
            obj.save( wavFilepath, out );
        end
        %% -------------------------------------------------------------------------------
        
        function out = processSaveAndGetOutput( obj, wavFilepath )
            if ~obj.hasFileAlreadyBeenProcessed( wavFilepath )
                obj.process( wavFilepath );
                if nargout > 0
                    out = obj.saveOutput( wavFilepath );
                else
                    obj.saveOutput( wavFilepath );
                end
            elseif nargout > 0
                out = obj.loadProcessedData( wavFilepath );
            end
        end
        %% -------------------------------------------------------------------------------

        function [out, outFilepath] = loadProcessedData( obj, wavFilepath, varargin )
            outFilepath = obj.getOutputFilepath( wavFilepath );
            obj.outFileSema = setfilesemaphore( outFilepath, 'semaphoreOldTime', 30 );
            out = load( outFilepath, varargin{:} );
            removefilesemaphore( obj.outFileSema );
        end
        %% -------------------------------------------------------------------------------
        
        function [inData, inDataFilepath] = loadInputData( obj, wavFilepath, varargin )
            [inData, inDataFilepath] = ...
                              obj.inputProc.loadProcessedData( wavFilepath, varargin{:} );
        end
        %% -------------------------------------------------------------------------------

        function outFilepath = getOutputFilepath( obj, wavFilepath )
            filepath = '';
            for ii = 1 : obj.nPathLevelsForCacheName
                [wavFilepath, filepathPart, ext] = fileparts( wavFilepath );
                filepath = [filepathPart ext '.' filepath];
            end
            filepath = filepath(1:end-1);
            filepath = strrep( filepath, '/', '.' );
            filepath = strrep( filepath, '\', '.' );
            filepath = strrep( filepath, ':', '.' );
            filepath = strrep( filepath, ' ', '.' );
            outFilepath = ...
                fullfile( obj.getCurrentFolder(), [filepath obj.getProcFileExt] );
        end
        %% -------------------------------------------------------------------------------

        function [fileProcessed,cacheDir] = hasFileAlreadyBeenProcessed( obj, wavFilepath )
            if isempty( wavFilepath ), fileProcessed = false; return; end
            cacheFile = obj.getOutputFilepath( wavFilepath );
            if obj.forceCacheRewrite
                fileProcessed = false;
            else
                fileProcessed = exist( cacheFile, 'file' );
            end
            if nargout > 1
                cacheDir = fileparts( cacheFile );
            end
        end
        %% -------------------------------------------------------------------------------
        
        function outputDeps = getOutputDependencies( obj )
            outputDeps = obj.getInternOutputDependencies();
            if ~isa( outputDeps, 'struct' )
                error( 'getInternOutputDependencies must combine values in a struct.' );
            end
            if isfield( outputDeps, 'preceding' )
                error( 'Intern output dependencies must not contain field named "preceding"' );
            end
            if ~isempty( obj.inputProc )
                outputDeps.preceding = obj.inputProc.getOutputDependencies();
            end
        end
        %% -------------------------------------------------------------------------------

        function setCacheSystemDir( obj, cacheSystemDir, nPathLevelsForCacheName )
            if exist( cacheSystemDir, 'dir' )
                obj.cacheSystemDir = fullfile( cacheSystemDir, obj.procName );
                obj.cacheDirectory.setCacheTopDir( obj.cacheSystemDir, true );
            else
                error( 'cannot find directory "%s": does it exist?', cacheSystemDir ); 
            end
            if exist( 'nPathLevelsForCacheName', 'var' ) 
                obj.nPathLevelsForCacheName = nPathLevelsForCacheName;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function currentFolder = getCurrentFolder( obj )
            currentConfig = obj.getOutputDependencies();
            if numel( obj.lastFolder ) >= obj.sceneId ...
                    && ~isempty( obj.lastFolder{obj.sceneId} ) ...
                    && isequalDeepCompare( currentConfig, obj.lastConfig{obj.sceneId} )
                currentFolder = obj.lastFolder{obj.sceneId};
                return;
            end
            obj.cacheDirectory.loadCacheDirectory();
            currentFolder = obj.cacheDirectory.getCacheFilepath( currentConfig, true );
            if obj.saveImmediately
                obj.cacheDirectory.saveCacheDirectory();
            end
            obj.lastFolder{obj.sceneId} = currentFolder;
            obj.lastConfig{obj.sceneId} = currentConfig;
        end
        %% -------------------------------------------------------------------------------
        
        function setInputProc( obj, inputProc )
            if ~isempty( inputProc ) && ~isa( inputProc, 'Core.IdProcInterface' )
                error( 'inputProc must be of type Core.IdProcInterface' );
            end
            obj.inputProc = inputProc;
        end
        %% -------------------------------------------------------------------------------
        
        function setDirectCacheSave( obj, saveImmediately )
            obj.saveImmediately = saveImmediately;
        end            
        %% -------------------------------------------------------------------------------
        
        % this can be overridden in subclasses
        function outObj = getOutputObject( obj )
            outObj = obj;
        end
        %% -------------------------------------------------------------------------------
        
        function save( obj, wavFilepath, out )
            if isempty( wavFilepath ), return; end
            outFilepath = obj.getOutputFilepath( wavFilepath );
            obj.outFileSema = setfilesemaphore( outFilepath, 'semaphoreOldTime', 30 );
            save( outFilepath, '-struct', 'out' );
            removefilesemaphore( obj.outFileSema );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function obj = IdProcInterface( procName )
            if nargin < 1
                classInfo = metaclass( obj );
                [classname1, classname2] = strtok( classInfo.Name, '.' );
                if isempty( classname2 ), obj.procName = classname1;
                else obj.procName = classname2(2:end); end
            else
                obj.procName = procName;
            end
            obj.cacheDirectory = Core.IdCacheDirectory();
        end
        %% -------------------------------------------------------------------------------

        function procFileExt = getProcFileExt( obj )
            procFileExt = '.mat';
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Static)

        function b = forceCacheRewrite( newValue )
            persistent fcrw;
            if isempty( fcrw )
                fcrw = false;
            end
            if nargin > 0 
                fcrw = newValue;
            else
                b = fcrw;
            end
        end
                
    end
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        process( obj, wavFilepath )
    end
    methods (Abstract, Access = protected)
        outputDeps = getInternOutputDependencies( obj )
        out = getOutput( obj, varargin )
    end
    
end

        