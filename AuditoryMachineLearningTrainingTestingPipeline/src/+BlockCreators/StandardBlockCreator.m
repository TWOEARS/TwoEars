classdef StandardBlockCreator < BlockCreators.Base
    % 
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = StandardBlockCreator( blockSize_s, shiftSize_s )
            obj = obj@BlockCreators.Base( blockSize_s, shiftSize_s );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods (Access = protected)
        
        function outputDeps = getBlockCreatorInternOutputDependencies( obj )
            outputDeps.v = 4;
        end
        %% ------------------------------------------------------------------------------- 

        function [blockAnnots,afeBlocks] = blockify( obj, afeData, annotations )
            currentDependencies = obj.getOutputDependencies();
            sceneConfig = currentDependencies.preceding.preceding.sceneCfg;
            annotations = BlockCreators.StandardBlockCreator.extendAnnotations( ...
                                                               sceneConfig, annotations );
            anyAFEsignal = afeData(1);
            if isa( anyAFEsignal, 'cell' ), anyAFEsignal = anyAFEsignal{1}; end;
            streamLen_s = double( size( anyAFEsignal.Data, 1 ) ) / anyAFEsignal.FsHz;
            backOffsets_s = ...
                       0.0 : obj.shiftSize_s : max( streamLen_s-obj.shiftSize_s+0.01, 0 );
            blockAnnots = repmat( annotations, numel( backOffsets_s ), 1 );
            blockOffsets = [streamLen_s - backOffsets_s]';
            blockOnsets = max( 0, blockOffsets - obj.blockSize_s );
            aFields = fieldnames( annotations );
            isSequenceAnnotation = cellfun( @(af)(...
                      isstruct( annotations.(af) ) && isfield( annotations.(af), 't' ) ...
                                                                             ), aFields );
            sequenceAfields = aFields(isSequenceAnnotation);
            afeBlocks = cell( numel( backOffsets_s ), 1 );
            for ii = 1 : numel( backOffsets_s )
                backOffset_s = backOffsets_s(ii);
                if nargout > 1
                    afeBlocks{ii} = obj.cutDataBlock( afeData, backOffset_s );
                end
                blockOn = blockOnsets(ii);
                blockOff = blockOffsets(ii);
                blockAnnots(ii).blockOnset = blockOn;
                blockAnnots(ii).blockOffset = blockOff;
                for jj = 1 : numel( sequenceAfields )
                    seqAname = sequenceAfields{jj};
                    annot = annotations.(seqAname);
                    if ~isstruct( annot.t ) % time series
                        if length( annot.t ) == size( annot.(seqAname), 1 )
                            isTinBlock = (annot.t >= blockOn) & (annot.t <= blockOff);
                            blockAnnots(ii).(seqAname).(seqAname)(~isTinBlock,:) = [];
                            blockAnnots(ii).(seqAname).t(~isTinBlock) = [];
                        else
                            error( 'unexpected annotations sequence structure' );
                        end
                    elseif all( isfield( annot.t, {'onset','offset'} ) ) % event series
                        if isequal( size( annot.t.onset ), size( annot.t.offset ) ) && ...
                                length( annot.t.onset ) == size( annot.(seqAname), 1 )
                            isEventInBlock = arrayfun( @(eon,eoff)(...
                                               (eon >= blockOn && eon <= blockOff) || ...
                                              (eoff >= blockOn && eoff <= blockOff) || ...
                                               (eon <= blockOn && eoff >= blockOff)...
                                                       ), annot.t.onset, annot.t.offset );
                            blockAnnots(ii).(seqAname).(seqAname)(~isEventInBlock,:) = [];
                            blockAnnots(ii).(seqAname).t.onset(~isEventInBlock) = [];
                            blockAnnots(ii).(seqAname).t.offset(~isEventInBlock) = [];
                        else
                            error( 'unexpected annotations sequence structure' );
                        end
                    else
                        error( 'unexpected annotations sequence structure' );
                    end
                end
            end
            afeBlocks = flipud( afeBlocks );
            blockAnnots = flipud( blockAnnots );
        end
        %% ------------------------------------------------------------------------------- 
    
    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        %% ------------------------------------------------------------------------------- 
        
        % TODO: this is the wrong place for the annotation computation; it
        % should be done in SceneEarSignalProc -- and is now here, for the
        % moment, to avoid recomputation with SceneEarSignalProc.
        
        function annotations = extendAnnotations( sceneConfig, annotations )
            annotations.srcSNR_db.t = annotations.globalSrcEnergy.t;
            annotations.srcSNR_db.srcSNR_db = zeros( size( annotations.globalSrcEnergy.globalSrcEnergy ) );
            annotations.nrj_db.t = annotations.globalSrcEnergy.t;
            annotations.nrj_db.nrj_db = zeros( size( annotations.globalSrcEnergy.globalSrcEnergy ) );
            annotations.nrjOthers_db.t = annotations.globalSrcEnergy.t;
            annotations.nrjOthers_db.nrjOthers_db = zeros( size( annotations.globalSrcEnergy.globalSrcEnergy ) );
            annotations.nActivePointSrcs.t = annotations.globalSrcEnergy.t;
            annotations.nActivePointSrcs.nActivePointSrcs = zeros( size( annotations.globalSrcEnergy.globalSrcEnergy ) );
            if std( sceneConfig.snrRefs ) ~= 0
                error( 'AMLTTP:usage:snrRefMustBeSame', 'different snrRefs not supported' );
            end
            snrRef = sceneConfig.snrRefs(1);
            nSrcs = size( annotations.globalSrcEnergy.globalSrcEnergy, 2 );
            srcsGlobalRefEnergyMeanChannel = zeros( ...
                                    size( annotations.globalSrcEnergy.globalSrcEnergy ) );
            for ss = 1 : nSrcs
                srcsGlobalRefEnergyMeanChannel(:,ss) = mean( ...
                       cell2mat( annotations.globalSrcEnergy.globalSrcEnergy(:,ss) ), 2 );
            end
            srcsGlobalRefEnergyMeanChannel_db = 10 * log10( srcsGlobalRefEnergyMeanChannel );
            snrRefNrjOffsets = cell2mat( annotations.globalNrjOffsets.globalNrjOffsets ) ...
                                  - annotations.globalNrjOffsets.globalNrjOffsets{snrRef};
            annotations.globalNrjOffsets = snrRefNrjOffsets;
            for ss = 1 : nSrcs
                otherIdxs = 1 : size( srcsGlobalRefEnergyMeanChannel, 2 );
                otherIdxs(ss) = [];
                srcsCurrentSrcRefEnergy_db = srcsGlobalRefEnergyMeanChannel_db ...
                                                                   - snrRefNrjOffsets(ss);
                srcsCurrentSrcRefEnergy = 10.^(srcsCurrentSrcRefEnergy_db./10);
                sumOtherSrcsEnergy = sum( srcsCurrentSrcRefEnergy(:,otherIdxs), 2 );
                sumOthersSrcsEnergy_db = 10 * log10( sumOtherSrcsEnergy );
                annotations.nrjOthers_db.nrjOthers_db(:,ss) = single( sumOthersSrcsEnergy_db );
                annotations.nrj_db.nrj_db(:,ss) = single( srcsCurrentSrcRefEnergy_db(:,ss) );
                annotations.srcSNR_db.srcSNR_db(:,ss) = single( ...
                              srcsCurrentSrcRefEnergy_db(:,ss) - sumOthersSrcsEnergy_db );
            end
            haveSrcsEnergy = srcsGlobalRefEnergyMeanChannel_db > -40;
            isAmbientSource = all( isnan( annotations.srcAzms.srcAzms ), 1 );
            haveSrcsEnergy(:,isAmbientSource) = [];
            annotations.nActivePointSrcs.nActivePointSrcs = single( sum( haveSrcsEnergy, 2 ) );
        end
        %% ------------------------------------------------------------------------------- 
        
    end
    
end

        

