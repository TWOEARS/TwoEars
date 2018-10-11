classdef MultiEventTypeLabeler < LabelCreators.Base
    % class for multi-class labeling blocks by event
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        minBlockToEventRatio;
        maxNegBlockToEventRatio;
        types;
        negOut;
        srcPrioMethod;
        segIdTargetSrcFilter;
        srcTypeFilterOut;
        nrgSrcsFilter;
        fileFilterOut;
        sourcesMinEnergy;
    end
    
    %% -----------------------------------------------------------------------------------
    properties (Access = public)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = MultiEventTypeLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'minBlockToEventRatio', 0.75 );
            ip.addOptional( 'maxNegBlockToEventRatio', 0 );
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.addOptional( 'removeUnclearBlocks', 'block-wise' );
            ip.addOptional( 'types', {{'Type1'},{'Type2'}} );
            ip.addOptional( 'negOut', 'rest' ); % rest, none
            ip.addOptional( 'srcPrioMethod', 'order' ); % energy, order, time
            ip.addOptional( 'segIdTargetSrcFilter', [] ); % e.g. [1,1;3,2]: throw away time-aggregate blocks with type 1 on other than src 1 and type 2 on other than src 3
            ip.addOptional( 'srcTypeFilterOut', [] ); % e.g. [2,1;3,2]: throw away type 1 blocks from src 2 and type 2 blocks from src 3
            ip.addOptional( 'nrgSrcsFilter', [] ); % idxs of srcs to be account for block-filtering based on too low energy. If empty, do not use
            ip.addOptional( 'fileFilterOut', {} ); % blocks containing these files get filtered out
            ip.addOptional( 'sourcesMinEnergy', -20 ); 
            ip.parse( varargin{:} );
            obj = obj@LabelCreators.Base( ...
                        'labelBlockSize_s', ip.Results.labelBlockSize_s, ...
                        'removeUnclearBlocks', ip.Results.removeUnclearBlocks );
            obj.minBlockToEventRatio = ip.Results.minBlockToEventRatio;
            obj.maxNegBlockToEventRatio = ip.Results.maxNegBlockToEventRatio;
            obj.types = ip.Results.types;
            obj.negOut = ip.Results.negOut;
            obj.srcPrioMethod = ip.Results.srcPrioMethod;
            obj.segIdTargetSrcFilter = ip.Results.segIdTargetSrcFilter;
            obj.srcTypeFilterOut = ip.Results.srcTypeFilterOut;
            obj.nrgSrcsFilter = ip.Results.nrgSrcsFilter;
            obj.sourcesMinEnergy = ip.Results.sourcesMinEnergy;
            obj.fileFilterOut = sort( ip.Results.fileFilterOut );
            obj.procName = [obj.procName '(' strcat( obj.types{1}{:} ) ')'];
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.minBlockEventRatio = obj.minBlockToEventRatio;
            outputDeps.maxNegBlockToEventRatio = obj.maxNegBlockToEventRatio;
            outputDeps.types = obj.types;
            outputDeps.negOut = obj.negOut;
            outputDeps.srcPrioMethod = obj.srcPrioMethod;
            outputDeps.nrgSrcsFilter = obj.nrgSrcsFilter;
            outputDeps.sourcesMinEnergy = obj.sourcesMinEnergy;
            outputDeps.srcTypeFilterOut = sortrows( obj.srcTypeFilterOut );
            outputDeps.segIdTargetSrcFilter = sortrows( obj.segIdTargetSrcFilter );
            outputDeps.fileFilterOut = obj.fileFilterOut;
            outputDeps.v = 9;
        end
        %% -------------------------------------------------------------------------------
        
        function eit = eventIsType( obj, typeIdx, type )
            eit = any( strcmp( type, obj.types{typeIdx} ) );
        end
        %% -------------------------------------------------------------------------------
        
        function [y, ysi] = label( obj, blockAnnotations )
            [activeTypes, relBlockEventOverlap, srcIdxs] = obj.getActiveTypes( blockAnnotations );
            [maxPosRelOverlap,maxTimeTypeIdx] = max( relBlockEventOverlap );
            ysi = {};
            if any( activeTypes )
                switch obj.srcPrioMethod
                    case 'energy'
                        eSrcs = cellfun( @mean, blockAnnotations.globalSrcEnergy ); % mean over channels
                        for ii = 1 : numel( activeTypes )
                            if activeTypes(ii)
                                eTypes(ii) = 1/sum( 1./eSrcs([srcIdxs{ii}]) );
                            else
                                eTypes(ii) = -inf;
                            end
                        end
                        [~,labelTypeIdx] = max( eTypes );
                    case 'order'
                        labelTypeIdx = find( activeTypes, 1, 'first' );
                    case 'time'
                        labelTypeIdx = maxTimeTypeIdx;
                    otherwise
                        error( 'AMLTTP:unknownOptionValue', ['%s: unknown option value.'...
                                     'Use ''energy'' or ''order''.'], obj.srcPrioMethod );
                end
                y = labelTypeIdx;
                ysi = srcIdxs(y);
            elseif strcmp( obj.negOut, 'rest' ) && ...
                    (maxPosRelOverlap <= obj.maxNegBlockToEventRatio) 
                y = -1;
            else
                y = NaN;
                return;
            end
            if ~isempty( obj.segIdTargetSrcFilter )
                for ii = 1 : size( obj.segIdTargetSrcFilter, 1 )
                    srcf = obj.segIdTargetSrcFilter(ii,1);
                    typef = obj.segIdTargetSrcFilter(ii,2);
                    srcfAzm = obj.lastConfig{obj.sceneId}.preceding.preceding.preceding.preceding.preceding.sceneCfg.sources(srcf).azimuth;
                    if isa( srcfAzm, 'SceneConfig.ValGen' )
                        srcfAzm = srcfAzm.val;
                    end
                    if activeTypes(typef) && (any( abs( blockAnnotations.srcAzms(srcIdxs{typef}) - srcfAzm ) >= 0.1 ) || any( abs( blockAnnotations.globalNrjOffsets(srcIdxs{typef}) ) >= 0.1 ))
                        y = NaN;
                        return;
                    end
                end
            end
            for ii = 1 : size( obj.srcTypeFilterOut, 1 )
                srcfo = obj.srcTypeFilterOut(ii,1);
                typefo = obj.srcTypeFilterOut(ii,2);
                if activeTypes(typefo) && any( srcIdxs{typefo} == srcfo )
                    y = NaN;
                    return;
                end
            end
            if ~isempty( obj.nrgSrcsFilter )
                rejectBlock = LabelCreators.EnergyDependentLabeler.isEnergyTooLow( ...
                              blockAnnotations, obj.nrgSrcsFilter, obj.sourcesMinEnergy );
                if rejectBlock
                    y = NaN;
                    return;
                end
            end
            for ii = 1 : numel( obj.fileFilterOut )
                if any( strcmpi( obj.fileFilterOut{ii}, blockAnnotations.srcFile.srcFile(:,1) ) )
                    y = NaN;
                    return;
                end
            end
        end
        %% -------------------------------------------------------------------------------
        function [activeTypes, relBlockEventOverlap, srcIdxs] = getActiveTypes( obj, blockAnnotations )
            [relBlockEventOverlap, srcIdxs] = obj.relBlockEventsOverlap( blockAnnotations );
            activeTypes = relBlockEventOverlap >= obj.minBlockToEventRatio;
        end
        
        function [relBlockEventsOverlap, srcIdxs] = relBlockEventsOverlap( obj, blockAnnotations )
            blockOffset = blockAnnotations.blockOffset;
            labelBlockOnset = blockOffset - obj.labelBlockSize_s;
            eventOnsets = blockAnnotations.srcType.t.onset;
            eventOffsets = blockAnnotations.srcType.t.offset;
            relBlockEventsOverlap = zeros( size( obj.types ) );
            srcIdxs = cell( size( obj.types ) );
            for ii = 1 : numel( obj.types )
                eventsAreType = cellfun( @(ba)(...
                                  obj.eventIsType( ii, ba )...
                                              ), blockAnnotations.srcType.srcType(:,1) );
                thisTypeEventOnOffs = ...
                               [eventOnsets(eventsAreType)' eventOffsets(eventsAreType)'];
                thisTypeMergedEventOnOffs = sortAndMergeOnOffs( thisTypeEventOnOffs );
                thisTypeMergedOnsets = thisTypeMergedEventOnOffs(:,1);
                thisTypeMergedOffsets = thisTypeMergedEventOnOffs(:,2);
                eventBlockOverlaps = arrayfun( @(eon,eof)(...
                                  min( blockOffset, eof ) - max( labelBlockOnset, eon )...
                                         ), thisTypeMergedOnsets, thisTypeMergedOffsets );
                isEventBlockOverlap = eventBlockOverlaps' > 0;
                eventBlockOverlapLen = sum( eventBlockOverlaps(isEventBlockOverlap) );
                if eventBlockOverlapLen == 0
                    relBlockEventsOverlap(ii) = 0;
                else
                    eventLen = sum( thisTypeMergedOffsets(isEventBlockOverlap) ...
                                            - thisTypeMergedOnsets(isEventBlockOverlap) );
                    maxBlockEventLen = min( obj.labelBlockSize_s, eventLen );
                    relBlockEventsOverlap(ii) = eventBlockOverlapLen / maxBlockEventLen;
                end
                srcIdxs{ii} = unique( [blockAnnotations.srcType.srcType{eventsAreType,2}] );
            end
        end
        %% -------------------------------------------------------------------------------
                
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

