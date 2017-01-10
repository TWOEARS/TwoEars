classdef Base < Core.IdProcInterface
    % Base Abstract base class for labeling blocks
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        y;
        x;
        blockAnnotations;
        labelBlockSize_s;
        labelBlockSize_auto;
        removeUnclearBlocks;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract, Access = protected)
        outputDeps = getLabelInternOutputDependencies( obj )
        y = label( obj, annotations )
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = Base( varargin )
            obj = obj@Core.IdProcInterface();
            ip = inputParser;
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.addOptional( 'removeUnclearBlocks', true );
            ip.parse( varargin{:} );
            obj.labelBlockSize_s = ip.Results.labelBlockSize_s;
            obj.removeUnclearBlocks = ip.Results.removeUnclearBlocks;
            if isempty( obj.labelBlockSize_s )
                obj.labelBlockSize_auto = true;
            else
                obj.labelBlockSize_auto = false;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function process( obj, wavFilepath )
            obj.inputProc.sceneId = obj.sceneId;
            in = obj.loadInputData( wavFilepath, 'blockAnnotations' );
            obj.y = [];
            for blockAnnotation = in.blockAnnotations'
                if obj.labelBlockSize_auto
                    obj.labelBlockSize_s = ...
                                 blockAnnotation.blockOffset - blockAnnotation.blockOnset;
                end
                obj.y(end+1,:) = obj.label( blockAnnotation );
                if obj.labelBlockSize_auto
                    obj.labelBlockSize_s = [];
                end
                fprintf( '.' );
            end
        end
        %% -------------------------------------------------------------------------------

        % override of DataProcs.IdProcInterface's method
        function [out, outFilepath] = loadProcessedData( obj, wavFilepath, varargin )
            [tmpOut, outFilepath] = loadProcessedData@Core.IdProcInterface( ...
                                                                  obj, wavFilepath, 'y' );
            obj.y = tmpOut.y;
            obj.inputProc.sceneId = obj.sceneId;
            if nargin < 3  || (any( strcmpi( 'x', varargin ) ) && any( strcmpi( 'a', varargin ) ))
                inData = obj.loadInputData( wavFilepath, 'x', 'blockAnnotations' );
                obj.x = inData.x;
                obj.blockAnnotations = inData.blockAnnotations;
            elseif any( strcmpi( 'a', varargin ) )
                inData = obj.loadInputData( wavFilepath, 'blockAnnotations' );
                obj.blockAnnotations = inData.blockAnnotations;
            elseif any( strcmpi( 'x', varargin ) )
                inData = obj.loadInputData( wavFilepath, 'x' );
                obj.x = inData.x;
            end
            out = obj.getOutput( varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function out = saveOutput( obj, wavFilepath )
            out = obj.getOutput( 'y' );
            obj.save( wavFilepath, out );
        end
        %% -------------------------------------------------------------------------------
        
        % override of DataProcs.IdProcInterface's method
        function save( obj, wavFilepath, ~ )
            out.y = obj.y;
            save@Core.IdProcInterface( obj, wavFilepath, out ); 
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.v = 1;
            outputDeps.labelBlockSize = obj.labelBlockSize_s;
            outputDeps.labelBlockSize_auto = obj.labelBlockSize_auto;
            outputDeps.labelProc = obj.getLabelInternOutputDependencies();
        end
        %% -------------------------------------------------------------------------------

        function out = getOutput( obj, varargin )
            out.y = obj.y;
            out.bIdxs = 1 : numel( out.y );
            if nargin < 2  || any( strcmpi( 'x', varargin ) )
                out.x = obj.x;
                if obj.removeUnclearBlocks
                    out.x(any(isnan(out.y),2),:) = [];
                end
            end
            if nargin < 2  || any( strcmpi( 'a', varargin ) )
                out.a = obj.blockAnnotations;
                if obj.removeUnclearBlocks
                    out.a(any(isnan(out.y),2)) = [];
                end
            end
            if obj.removeUnclearBlocks
                out.bIdxs(any(isnan(out.y),2)) = [];
                out.y(any(isnan(out.y),2),:) = [];
            end
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

