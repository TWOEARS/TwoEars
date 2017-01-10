classdef MultiSceneCfgsIdProcWrapper < DataProcs.IdProcWrapper
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        sceneConfigurations;
        sceneProc;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
        
        function b = doEarlyHasProcessedStop( bSet, newValue )
            persistent dehps;
            if isempty( dehps )
                dehps = false;
            end
            if nargin > 0  &&  bSet
                dehps = newValue;
            end
            b = dehps;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiSceneCfgsIdProcWrapper( sceneProc, wrapProc,...
                                                              multiSceneCfgs )
            obj = obj@DataProcs.IdProcWrapper( wrapProc, true );
            if ~isa( sceneProc, 'Core.IdProcInterface' )
                error( 'sceneProc must implement Core.IdProcInterface.' );
            end
            obj.sceneProc = sceneProc;
            if nargin < 3, multiSceneCfgs = SceneConfig.SceneConfiguration.empty; end
            obj.sceneConfigurations = multiSceneCfgs;
        end
        %% ----------------------------------------------------------------

        function setSceneConfig( obj, multiSceneCfgs )
            obj.sceneConfigurations = multiSceneCfgs;
        end
        %% ----------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function fileProcessed = hasFileAlreadyBeenProcessed( obj, wavFilepath )
            fileProcessed = true;
            for ii = 1 : numel( obj.sceneConfigurations )
                obj.sceneProc.setSceneConfig( obj.sceneConfigurations(ii) );
                obj.wrappedProcs{1}.sceneId = ii;
                processed = obj.wrappedProcs{1}.hasFileAlreadyBeenProcessed( wavFilepath );
                fileProcessed = fileProcessed && processed;
                % not stopping early because hasFileAlreadyBeenProcessed triggers cache
                % directory creation
                if processed
                    fprintf( '.' );
                else
                    fprintf( '*' );
                end
                if DataProcs.MultiSceneCfgsIdProcWrapper.doEarlyHasProcessedStop ...
                        && ~fileProcessed
                    return;
                end
            end
            fprintf( '\n' );
        end
        %% -------------------------------------------------------------------------------
       
        % override of Core.IdProcInterface's method
        function out = processSaveAndGetOutput( obj, wavFilepath )
            obj.process( wavFilepath );
            out = [];
        end
        %% -------------------------------------------------------------------------------

        function process( obj, wavFilepath )
            for ii = 1 : numel( obj.sceneConfigurations )
                fprintf( 'sc%d', ii );
                obj.sceneProc.setSceneConfig( obj.sceneConfigurations(ii) );
                obj.wrappedProcs{1}.sceneId = ii;
                obj.wrappedProcs{1}.processSaveAndGetOutput( wavFilepath );
                fprintf( '#' );
            end
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function [out, outFilepath] = loadProcessedData( ~, ~ ) 
            out = [];
            outFilepath = '';
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function inData = loadInputData( ~, ~, ~ )
            inData = [];
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function outFilepath = getOutputFilepath( ~, ~ )
            outFilepath = [];
        end
        %% -------------------------------------------------------------------------------
       
        % override of Core.IdProcInterface's method
        function currentFolder = getCurrentFolder( obj )
            currentFolder = [];
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function out = save( ~, ~, ~ )
            out = [];
        end
        %% -------------------------------------------------------------------------------
        
        % override of DataProcs.IdProcWrapper's method
        function setCacheSystemDir( obj, cacheSystemDir, nPathLevelsForCacheName )
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.setCacheSystemDir( cacheSystemDir, nPathLevelsForCacheName );
            end
        end
        %% -------------------------------------------------------------------------------
        
        % override of DataProcs.IdProcWrapper's method
        function loadCacheDirectory( obj )
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.loadCacheDirectory();
            end
        end
        %% -----------------------------------------------------------------        

        % override of DataProcs.IdProcWrapper's method
        function getSingleProcessCacheAccess( obj )
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.getSingleProcessCacheAccess();
            end
        end
        %% -------------------------------------------------------------------------------
        
        % override of DataProcs.IdProcWrapper's method
        function releaseSingleProcessCacheAccess( obj )
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.releaseSingleProcessCacheAccess();
            end
        end
        %% -------------------------------------------------------------------------------
        
        % override of DataProcs.IdProcWrapper's method
        function delete( obj )
            removefilesemaphore( obj.outFileSema );
        end
        %% -------------------------------------------------------------------------------
    end
        
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            for ii = 1 : numel( obj.sceneConfigurations )
                outDepName = sprintf( 'sceneConfig%d', ii );
                outputDeps.(outDepName) = obj.sceneConfigurations(ii);
            end
            obj.sceneProc.setSceneConfig( [] );
            outputDeps.wrapDeps = getInternOutputDependencies@DataProcs.IdProcWrapper( obj );
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj, varargin )
            out = [];
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
    end
    
end
