classdef GatherFeaturesProc < Core.IdProcInterface
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private, Transient)
        sceneCfgDataUseRatio = 1;
        sceneCfgPrioDataUseRatio = 1;
        dataSelector;
        selectPrioClass = [];
        loadBlockAnnotations = false;
        prioClass = [];
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = GatherFeaturesProc( loadBlockAnnotations )
            obj = obj@Core.IdProcInterface();
            if nargin >= 1
                obj.loadBlockAnnotations = loadBlockAnnotations;
            end
        end
        %% -------------------------------------------------------------------------------

        function setSceneCfgDataUseRatio( obj, sceneCfgDataUseRatio, dataSelector, ...
                                               sceneCfgPrioDataUseRatio, selectPrioClass )
            obj.sceneCfgDataUseRatio = sceneCfgDataUseRatio;
            if nargin < 3, dataSelector = DataSelectors.IgnorantSelector(); end
            if nargin < 4, sceneCfgPrioDataUseRatio = 1; end
            if nargin < 5, selectPrioClass = []; end
            obj.dataSelector = dataSelector;
            obj.sceneCfgPrioDataUseRatio = sceneCfgPrioDataUseRatio;
            obj.selectPrioClass = selectPrioClass;
        end
        %% -------------------------------------------------------------------------------

        function process( obj, wavFilepath )
            obj.inputProc.sceneId = obj.sceneId;
            if obj.loadBlockAnnotations
                xy = obj.loadInputData( wavFilepath, 'x', 'y', 'ysi', 'a' );
                xy.blockAnnotations = Core.IdentTrainPipeDataElem.addPPtoBas( xy.a, xy.y );
                xy = rmfield( xy, 'a' );
                sceneCfgDeps = obj.inputProc.getOutputDependencies();
                while ~(isstruct( sceneCfgDeps ) && isfield( sceneCfgDeps, 'sceneCfg' ) )
                    sceneCfgDeps = sceneCfgDeps.preceding;
                end
                npssc = numel( sceneCfgDeps.sceneCfg.sources );
                [xy.blockAnnotations(:).nPointSrcsSceneConfig] = deal( npssc );
            else
                xy = obj.loadInputData( wavFilepath, 'x', 'y', 'ysi' );
            end
            obj.inputProc.inputProc.sceneId = obj.sceneId;
            inDataFilepath = obj.inputProc.inputProc.getOutputFilepath( wavFilepath );
            dataFile = obj.idData(wavFilepath);
            fprintf( '.' );
            if ~isempty( obj.selectPrioClass ) && any( xy.y == obj.selectPrioClass )
                nUsePoints = round( size( xy.x, 1 ) * obj.sceneCfgPrioDataUseRatio );
            else
                nUsePoints = round( size( xy.x, 1 ) * obj.sceneCfgDataUseRatio );
            end
            obj.dataSelector.connectData( xy );
            useIdxs = obj.dataSelector.getDataSelection( 1:size( xy.x, 1 ), nUsePoints );
            dataFile.x = [dataFile.x; xy.x(useIdxs,:)];
            dataFile.y = [dataFile.y; xy.y(useIdxs,:)];
            dataFile.ysi = [dataFile.ysi; xy.ysi(useIdxs)'];
            dataFile.bIdxs = [dataFile.bIdxs; xy.bIdxs(useIdxs)'];
            dataFile.bacfIdxs = [dataFile.bacfIdxs; ...
                  repmat( numel(dataFile.blockAnnotsCacheFile ) + 1, sum(useIdxs), 1 )];
            dataFile.blockAnnotsCacheFile = [dataFile.blockAnnotsCacheFile; {inDataFilepath}];
            if obj.loadBlockAnnotations
                dataFile.blockAnnotations = [dataFile.blockAnnotations; xy.blockAnnotations(useIdxs)];
            end
            fprintf( '.' );
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function [out, outFilepath] = loadProcessedData( ~, ~ ) 
            out = [];
            outFilepath = '';
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function outFilepath = getOutputFilepath( ~, ~ )
            outFilepath = [];
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function [fileProcessed,cacheDir] = hasFileAlreadyBeenProcessed( ~, ~ )
            fileProcessed = false;
            cacheDir = [];
        end
        %% -------------------------------------------------------------------------------
       
        % override of Core.IdProcInterface's method
        function currentFolder = getCurrentFolder( ~ )
            currentFolder = [];
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function out = save( ~, ~, ~ )
            out = [];
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function setCacheSystemDir( ~, ~, ~ )
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function saveCacheDirectory( ~ )
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function loadCacheDirectory( ~ )
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function getSingleProcessCacheAccess( ~ )
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function releaseSingleProcessCacheAccess( ~ )
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function delete( obj )
            removefilesemaphore( obj.outFileSema );
        end
        %% -------------------------------------------------------------------------------
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( ~ )
            outputDeps.gatherDeps = [];
        end
        %% -------------------------------------------------------------------------------

        function out = getOutput( ~, ~ )
            out = [];
        end
        %% -------------------------------------------------------------------------------
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
    end
    
end
