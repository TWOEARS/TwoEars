classdef GatherFeaturesProc < Core.IdProcInterface
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private, Transient)
        sceneCfgDataUseRatio = 1;
        prioClass = [];
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = GatherFeaturesProc()
            obj = obj@Core.IdProcInterface();
        end
        %% -------------------------------------------------------------------------------

        function setSceneCfgDataUseRatio( obj, sceneCfgDataUseRatio, prioClass )
            obj.sceneCfgDataUseRatio = sceneCfgDataUseRatio;
            if nargin < 3, prioClass = []; end
            obj.prioClass = prioClass;
        end
        %% -------------------------------------------------------------------------------

        function process( obj, wavFilepath )
            obj.inputProc.sceneId = obj.sceneId;
            xy = obj.loadInputData( wavFilepath, 'x', 'y' );
            obj.inputProc.inputProc.sceneId = obj.sceneId;
            inDataFilepath = obj.inputProc.inputProc.getOutputFilepath( wavFilepath );
            dataFile = obj.idData(wavFilepath);
            fprintf( '.' );
            if obj.sceneCfgDataUseRatio < 1  &&  ...
                            ~strcmp( obj.prioClass, dataFile.getFileAnnotation( 'type' ) )
                nUsePoints = round( size( xy.x, 1 ) * obj.sceneCfgDataUseRatio );
                useIdxs = randperm( size( xy.x, 1 ) );
                useIdxs(nUsePoints+1:end) = [];
            else
                useIdxs = 1 : size( xy.x, 1 );
            end
            dataFile.x = [dataFile.x; xy.x(useIdxs,:)];
            dataFile.y = [dataFile.y; xy.y(useIdxs,:)];
            dataFile.bIdxs = [dataFile.bIdxs; xy.bIdxs(useIdxs)'];
            dataFile.bacfIdxs = [dataFile.bacfIdxs; ...
                  repmat( numel(dataFile.blockAnnotsCacheFile ) + 1, numel(useIdxs), 1 )];
            dataFile.blockAnnotsCacheFile = [dataFile.blockAnnotsCacheFile; {inDataFilepath}];
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
        function fileProcessed = hasFileAlreadyBeenProcessed( ~, ~ )
            fileProcessed = false;
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
