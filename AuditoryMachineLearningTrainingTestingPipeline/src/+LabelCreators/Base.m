classdef Base < Core.IdProcInterface
    % Base Abstract base class for labeling blocks
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        y;
        ysi;
        x;
        blockAnnotations;
        labelBlockSize_s;
        labelBlockSize_auto;
        removeUnclearBlocks;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract, Access = protected)
        outputDeps = getLabelInternOutputDependencies( obj )
        [y, ysi] = label( obj, annotations )
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = Base( varargin )
            obj = obj@Core.IdProcInterface();
            ip = inputParser;
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.addOptional( 'removeUnclearBlocks', 'block-wise' ); % 'false','block-wise','time-wise'
            ip.parse( varargin{:} );
            obj.labelBlockSize_s = ip.Results.labelBlockSize_s;
            obj.removeUnclearBlocks = ip.Results.removeUnclearBlocks;
            if ~any( strcmpi( obj.removeUnclearBlocks, {'false','block-wise','time-wise'} ) )
                error( 'AMLTTP:usage:unsupportedOptionSetting', 'use one of ''false'',''block-wise'',''time-wise''.' );
            end
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
            obj.ysi = {};
            for blockAnnotation = in.blockAnnotations'
                if obj.labelBlockSize_auto
                    obj.labelBlockSize_s = ...
                                 blockAnnotation.blockOffset - blockAnnotation.blockOnset;
                end
                [obj.y(end+1,:), obj.ysi{end+1}] = obj.label( blockAnnotation );
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
                                                           obj, wavFilepath, 'y', 'ysi' );
            obj.y = tmpOut.y;
            obj.ysi = tmpOut.ysi;
            obj.inputProc.sceneId = obj.sceneId;
            if nargin < 3  || (any( strcmpi( 'x', varargin ) ) && (any( strcmpi( 'a', varargin ) )  || strcmpi( obj.removeUnclearBlocks, 'time-wise' )))
                inData = obj.loadInputData( wavFilepath, 'x', 'blockAnnotations' );
                obj.x = inData.x;
                obj.blockAnnotations = inData.blockAnnotations;
            elseif any( strcmpi( 'a', varargin ) ) || strcmpi( obj.removeUnclearBlocks, 'time-wise' )
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
            out = obj.getOutput( 'y', 'ysi', 'noRemoveNanBlocks' );
            obj.save( wavFilepath, out );
        end
        %% -------------------------------------------------------------------------------
        
        % override of DataProcs.IdProcInterface's method
        function save( obj, wavFilepath, ~ )
            out.y = obj.y;
            out.ysi = obj.ysi;
            save@Core.IdProcInterface( obj, wavFilepath, out ); 
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.v = 2;
            outputDeps.labelBlockSize = obj.labelBlockSize_s;
            outputDeps.labelBlockSize_auto = obj.labelBlockSize_auto;
            outputDeps.labelProc = obj.getLabelInternOutputDependencies();
        end
        %% -------------------------------------------------------------------------------

        function out = getOutput( obj, varargin )
            out.y = obj.y;
            out.bIdxs = 1 : size( out.y, 1 );
            removeNanBlocks = strcmpi( obj.removeUnclearBlocks, {'block-wise','time-wise'} );
            if ~any( removeNanBlocks ) || any( strcmpi( 'noRemoveNanBlocks', varargin ) )
                removeNanBlocks_lidx = [];
            else
                removeNanBlocks_lidx = any(isnan(out.y),2);
                if removeNanBlocks(2)
                    [~,~,sameTimeIdxs] = unique( [obj.blockAnnotations.blockOffset] );
                    nanTimeIdxs = sameTimeIdxs(removeNanBlocks_lidx);
                    removeNanBlocks_lidx = ismember( sameTimeIdxs, nanTimeIdxs );
                end
            end
            if nargin < 2  || any( strcmpi( 'x', varargin ) )
                out.x = obj.x;
                out.x(removeNanBlocks_lidx,:,:) = [];
            end
            if nargin < 2  || any( strcmpi( 'a', varargin ) )
                out.a = obj.blockAnnotations;
                out.a(removeNanBlocks_lidx) = [];
            end
            if nargin < 2  || any( strcmpi( 'ysi', varargin ) )
                out.ysi = obj.ysi;
                out.ysi(removeNanBlocks_lidx) = [];
            end
            out.bIdxs(removeNanBlocks_lidx) = [];
            out.y(removeNanBlocks_lidx,:,:) = [];
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

