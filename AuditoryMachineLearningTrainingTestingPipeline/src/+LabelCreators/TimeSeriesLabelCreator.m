classdef TimeSeriesLabelCreator < LabelCreators.Base
    % Base Abstract base class for labeling blocks
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract, Access = protected)
        outputDeps = getLabelInternOutputDependencies( obj )
        [y, ysi] = label( obj, annotations )
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = TimeSeriesLabelCreator( varargin )
            ip = inputParser;
            ip.addOptional( 'removeUnclearBlocks', 'sequence-wise' ); % 'sequence-wise', 'time-wise', 'false'
            ip.parse( varargin{:} );
            obj = obj@LabelCreators.Base();
            obj.removeUnclearBlocks = ip.Results.removeUnclearBlocks;
            if ~any( strcmpi( obj.removeUnclearBlocks, {'false','sequence-wise','time-wise'} ) )
                error( 'AMLTTP:usage:unsupportedOptionSetting', 'use one of ''false'',''block-wise'',''time-wise''.' );
            end
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        % override of LabelCreators.Base's method
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.base = getInternOutputDependencies@LabelCreators.Base( obj );
            outputDeps.ts_v = 1;
            outputDeps.labelProc = obj.getLabelInternOutputDependencies();
        end
        %% -------------------------------------------------------------------------------

        % override of LabelCreators.Base's method
        function out = getOutput( obj, varargin )
            out.y = obj.y;
            out.bIdxs = 1 : size( out.y, 1 );
            removeNanBlocks = strcmpi( obj.removeUnclearBlocks, ...
                                       {'sequence-wise','time-wise'} );
            if ~any( removeNanBlocks ) || any( strcmpi( 'noRemoveNanBlocks', varargin ) )
                removeNanBlocks_lidx = [];
            else
                error( 'AMLTTP:notImplemented', 'data removal for time-series not implemented yet' );
                removeNanBlocks_lidx = any( isnan( out.y ), 3 );
                if removeNanBlocks(2)
                    error( 'AMLTTP:notImplemented', 'time-wise data removal for time-series not implemented yet' );
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

        

