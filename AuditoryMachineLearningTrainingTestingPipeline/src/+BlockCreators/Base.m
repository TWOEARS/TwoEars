classdef Base < Core.IdProcInterface
    % Base Abstract base class for extraction of blocks from streams (wavs)
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
        shiftSize_s;                % shift between blocks
        blockSize_s;                % size of the AFE data block in seconds
        afeBlocks;
        blockAnnotations;
        curWavFilepath;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract, Access = protected)
        outputDeps = getBlockCreatorInternOutputDependencies( obj )
        [blockAnnotations,afeBlocks] = blockify( obj, afeStream, streamAnnotations )
    end

    %% ----------------------------------------------------------------------------------- 
    methods
        
        function obj = Base( blockSize_s, shiftsize_s )
            obj = obj@Core.IdProcInterface();
            obj.blockSize_s = blockSize_s;
            obj.shiftSize_s = shiftsize_s;
        end
        %% -------------------------------------------------------------------------------
        
        function process( obj, wavFilepath )
            obj.curWavFilepath = wavFilepath;
        end
        %% -------------------------------------------------------------------------------
        
        function afeBlock = cutDataBlock( obj, afeData, backOffset_s )
            afeBlock = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
            for afeKey = afeData.keys
                afeSignal = afeData(afeKey{1});
                if isa( afeSignal, 'cell' )
                    afeSignalExtract = cell( size( afeSignal ) );
                    for ii = 1 : numel( afeSignal )
                        afeSignalExtract{ii} = ...
                            afeSignal{ii}.cutSignalCopyReducedToArray( obj.blockSize_s,...
                                                                       backOffset_s );
                    end
                else
                    afeSignalExtract = ...
                        afeSignal.cutSignalCopyReducedToArray( obj.blockSize_s, ...
                                                               backOffset_s );
                end
                afeBlock(afeKey{1}) = afeSignalExtract;
            end
            %fprintf( '.' );
        end
        %% ------------------------------------------------------------------------------- 

        % override of Core.IdProcInterface's method
        function fileProcessed = hasFileAlreadyBeenProcessed( ~, ~ )
            fileProcessed = false;
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function [out, outFilepath] = loadProcessedData( obj, wavFilepath, varargin )
            outFilepath = obj.getOutputFilepath( wavFilepath );
            obj.curWavFilepath = wavFilepath;
            out = obj.getOutput( varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function out = saveOutput( obj, wavFilepath )
            obj.curWavFilepath = wavFilepath;
            if nargout > 0
                out = obj.getOutput();
            end
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function save( ~, ~, ~ )
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function outFilepath = getOutputFilepath( ~, ~ )
            outFilepath = [];
        end
        %% -------------------------------------------------------------------------------
       
        % override of Core.IdProcInterface's method
        function currentFolder = getCurrentFolder( ~ )
            currentFolder = [];
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

        %% -------------------------------------------------------------------------------
        function processInternal( obj, varargin )
            obj.inputProc.sceneId = obj.sceneId;
            in = obj.loadInputData( obj.curWavFilepath, 'afeData', 'annotations' );
            if nargin < 2  || any( strcmpi( 'afeBlocks', varargin ) )
                [obj.blockAnnotations,obj.afeBlocks] = ...
                                               obj.blockify( in.afeData, in.annotations );
            else
                obj.blockAnnotations = obj.blockify( in.afeData, in.annotations );
            end                
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function out = getOutput( obj, varargin )
            obj.processInternal( varargin{:} );
            if nargin < 2  || any( strcmpi( 'afeBlocks', varargin ) )
                out.afeBlocks = obj.afeBlocks;
            end
            if nargin < 2  || any( strcmpi( 'blockAnnotations', varargin ) )
                out.blockAnnotations = obj.blockAnnotations;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.blockSize = obj.blockSize_s;
            outputDeps.shiftSize = obj.shiftSize_s;
            outputDeps.v = 2;
            outputDeps.blockProc = obj.getBlockCreatorInternOutputDependencies();
        end
        %% ------------------------------------------------------------------------------- 
        
    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        %% ------------------------------------------------------------------------------- 
        %% ------------------------------------------------------------------------------- 
        
    end
    
end

        

