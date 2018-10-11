classdef MultiEventTypeTimeSeriesLabeler < LabelCreators.TimeSeriesLabelCreator
    % class for multi-class labeling blocks by event
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        types;
        negOut;
        srcPrioMethod;
        segIdTargetSrcFilter = [];
        srcTypeFilterOut;
        fileFilterOut = {};
    end
    
    %% -----------------------------------------------------------------------------------
    properties (Access = public)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = MultiEventTypeTimeSeriesLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'removeUnclearBlocks', 'sequence-wise' );
            ip.addOptional( 'types', {{'Type1'},{'Type2'}} );
            ip.addOptional( 'negOut', 'rest' ); % rest, none
            ip.addOptional( 'srcPrioMethod', 'order' ); % energy, order
%             ip.addOptional( 'segIdTargetSrcFilter', [] ); % e.g. [1,1;3,2]: throw away time-aggregate blocks with type 1 on other than src 1 and type 2 on other than src 3
            ip.addOptional( 'srcTypeFilterOut', [] ); % e.g. [2,1;3,2]: throw away type 1 blocks from src 2 and type 2 blocks from src 3
%             ip.addOptional( 'fileFilterOut', {} ); % blocks containing these files get filtered out
            ip.parse( varargin{:} );
            obj = obj@LabelCreators.TimeSeriesLabelCreator( 'removeUnclearBlocks', ...
                                                         ip.Results.removeUnclearBlocks );
            obj.types = ip.Results.types;
            obj.negOut = ip.Results.negOut;
            obj.srcPrioMethod = ip.Results.srcPrioMethod;
%             obj.segIdTargetSrcFilter = ip.Results.segIdTargetSrcFilter;
            obj.srcTypeFilterOut = ip.Results.srcTypeFilterOut;
%             obj.fileFilterOut = sort( ip.Results.fileFilterOut );
            obj.procName = [obj.procName '(' strcat( obj.types{1}{:} ) ')'];
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.types = obj.types;
            outputDeps.negOut = obj.negOut;
            outputDeps.srcPrioMethod = obj.srcPrioMethod;
            outputDeps.srcTypeFilterOut = sortrows( obj.srcTypeFilterOut );
            outputDeps.segIdTargetSrcFilter = sortrows( obj.segIdTargetSrcFilter );
            outputDeps.fileFilterOut = obj.fileFilterOut;
            outputDeps.v = 1;
        end
        %% -------------------------------------------------------------------------------
        
        function eit = eventIsType( obj, typeIdx, type )
            eit = any( strcmp( type, obj.types{typeIdx} ) );
        end
        %% -------------------------------------------------------------------------------
        
        function [y, ysi] = label( obj, blockAnnotations )
            [activeTypes, srcIdxs] = obj.getActiveTypes( blockAnnotations );
            y = zeros( size( activeTypes, 1 ), 1 );
            ysi = cell( size( activeTypes, 1 ), 1 );
            if any( activeTypes(:) )
                switch obj.srcPrioMethod
                    case 'energy'
                        error( 'AMLTTP:notImplemented', 'energy PrioMethod for time-series not implemented yet' );
                        for ss = 1 : size( blockAnnotations.globalSrcEnergy.globalSrcEnergy, 2 )
                            eSrcs(:,ss) = mean( cell2mat( ...
                                blockAnnotations.globalSrcEnergy.globalSrcEnergy(:,ss) ), 2 );
                        end
                        eTypes = eSrcs .* activeTypes;
                        [~,labelTypeIdxs] = max( eTypes, [], 2 );
                        y = labelTypeIdxs .* double( any( activeTypes, 2 ) );
                    case 'order'
                        labelTypeIdxs = activeTypes .* repmat( 1:size( activeTypes, 2), size( activeTypes, 1), 1 );
                        y = min( labelTypeIdxs, [], 2 );
                    otherwise
                        error( 'AMLTTP:unknownOptionValue', ['%s: unknown option value.'...
                                     'Use ''energy'' or ''order''.'], obj.srcPrioMethod );
                end
                ysi_ = y;
                ysi_(ysi_==0) = 1;
                ysi = srcIdxs(sub2ind( size( srcIdxs ), 1:size( srcIdxs, 1 ), ysi_' ));
            end
            if strcmp( obj.negOut, 'rest' )
                y(y==0) = -1;
            else
                y(y==0) = NaN;
                return;
            end
%             if ~isempty( obj.segIdTargetSrcFilter )
%                 for ii = 1 : size( obj.segIdTargetSrcFilter, 1 )
%                     srcf = obj.segIdTargetSrcFilter(ii,1);
%                     typef = obj.segIdTargetSrcFilter(ii,2);
%                     srcfAzm = obj.lastConfig{obj.sceneId}.preceding.preceding.preceding.preceding.preceding.sceneCfg.sources(srcf).azimuth;
%                     if isa( srcfAzm, 'SceneConfig.ValGen' )
%                         srcfAzm = srcfAzm.val;
%                     end
%                     if activeTypes(typef) && any( abs( blockAnnotations.srcAzms(srcIdxs{typef}) - srcfAzm ) >= 0.1 )
%                         y = NaN;
%                         return;
%                     end
%                 end
%             end
            for ii = 1 : size( obj.srcTypeFilterOut, 1 )
                srcfo = obj.srcTypeFilterOut(ii,1);
                typefo = obj.srcTypeFilterOut(ii,2);
                fo_lidxs = activeTypes(:,typefo) ...
                           & cellfun( @(si)(any( si == srcfo )), srcIdxs(:,typefo) );
                y(fo_lidxs) = NaN;
            end
%             for ii = 1 : numel( obj.fileFilterOut )
%                 if any( strcmpi( obj.fileFilterOut{ii}, blockAnnotations.srcFile.srcFile(:,1) ) )
%                     y = NaN;
%                     return;
%                 end
%             end
        end
        %% -------------------------------------------------------------------------------
        
        function [activeTypes, srcIdxs] = getActiveTypes( obj, blockAnnotations )
            ts = blockAnnotations.globalSrcEnergy.t;
            activeTypes = zeros( numel( ts ), numel( obj.types ) );
            srcIdxs = cell( numel( ts ), numel( obj.types ) );
            eventOnsets = blockAnnotations.srcType.t.onset;
            eventOffsets = blockAnnotations.srcType.t.offset;
            for tt = 1 : numel( obj.types )
                eventsAreType = cellfun( @(ba)(obj.eventIsType( tt, ba )), ...
                                                  blockAnnotations.srcType.srcType(:,1) );
                srcIdxs_tt = [blockAnnotations.srcType.srcType{eventsAreType,2}];
                eventOnOffs_tt = [eventOnsets(eventsAreType)',eventOffsets(eventsAreType)'];
                eventOnOffs_tt = eventOnOffs_tt - ts(1) + 1;
                if ~isempty( eventOnOffs_tt )
                    for ii = 1:2
                        eventOnOffs_tt(:,ii) = max( ...
                                                [zeros( size(eventOnOffs_tt, 1), 1 ), ...
                                                 eventOnOffs_tt(:,ii)], [], 2 );
                        eventOnOffs_tt(:,ii) = min( ...
                                   [repmat( numel( ts ), size(eventOnOffs_tt, 1), 1 ), ...
                                    eventOnOffs_tt(:,ii)], [], 2 );
                    end
                else
                    eventOnOffs_tt = [];
                end
                for jj = 1 : size( eventOnOffs_tt, 1 )
                    event_jj_idxs = eventOnOffs_tt(jj,1) : eventOnOffs_tt(jj,2);
                    activeTypes(event_jj_idxs,tt) = 1;
                    srcIdxs(event_jj_idxs,tt) = cellfun( @(a,b)([a,b]), ...
                                srcIdxs(event_jj_idxs,tt), ...
                                repmat( {srcIdxs_tt(jj)}, numel( event_jj_idxs ), 1 ), ...
                                                                 'UniformOutput', false );
                end
            end
        end
        %% -------------------------------------------------------------------------------
                
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

