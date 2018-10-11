classdef MeanStandardBlockCreator < BlockCreators.StandardBlockCreator
    % 
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = MeanStandardBlockCreator( blockSize_s, shiftSize_s, varargin )
            obj = obj@BlockCreators.StandardBlockCreator( blockSize_s, shiftSize_s );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods (Access = protected)
        
        function outputDeps = getBlockCreatorInternOutputDependencies( obj )
            outputDeps.sbc = getBlockCreatorInternOutputDependencies@...
                                                BlockCreators.StandardBlockCreator( obj );
            outputDeps.v = 3;
        end
        %% ------------------------------------------------------------------------------- 

        function [blockAnnots,afeBlocks] = blockify( obj, afeData, annotations )
            if nargout > 1
                [blockAnnots,afeBlocks] = blockify@BlockCreators.StandardBlockCreator( ...
                                                              obj, afeData, annotations );
            else
                blockAnnots = blockify@BlockCreators.StandardBlockCreator( ...
                                                              obj, afeData, annotations );
            end
            [blockAnnots(:).nrj] = deal(struct('t',[],'nrj',[]));
            [blockAnnots(:).nrjOthers] = deal(struct('t',[],'nrjOthers',[]));
            [blockAnnots(:).srcSNRactive] = deal(struct('t',[],'srcSNRactive',[]));
            [blockAnnots(:).srcSNR2] = deal(struct('t',[],'srcSNR2',[]));
            aFields = fieldnames( blockAnnots );
            isSequenceAnnotation = cellfun( @(af)(...
                                            isstruct( blockAnnots(1).(af) ) && ...
                                            isfield( blockAnnots(1).(af), 't' ) && ...
                                            ~isstruct( blockAnnots(1).(af).t ) ...
                                                                             ), aFields );
            sequenceAfields = aFields(isSequenceAnnotation);
            for ii = 1 : numel( blockAnnots )
                blockAnnots(ii) = ...
                    BlockCreators.MeanStandardBlockCreator.adjustPreMeanAnnotations( ...
                                                                        blockAnnots(ii) );
                for jj = 1 : numel( sequenceAfields )
                    seqAname = sequenceAfields{jj};
                    annot = blockAnnots(ii).(seqAname);
                    annotSeq = annot.(seqAname);
                    if length( annot.t ) == size( annotSeq, 1 )
                        if iscell( annotSeq )
                            as_szs = cellfun( @(c)( size( c, 2 ) ), annotSeq(1,:) );
                            blockAnnots(ii).(seqAname) = ...
                                   mat2cell( nanmean( cell2mat( annotSeq ), 1 ), 1, as_szs );
                        else
                            blockAnnots(ii).(seqAname) = nanmean( annotSeq, 1 );
                        end
                    else
                        error( 'unexpected annotations sequence structure' );
                    end
                end
                blockAnnots(ii) = ...
                    BlockCreators.MeanStandardBlockCreator.extendMeanAnnotations( ...
                                                                        blockAnnots(ii) );
            end
        end
        %% ------------------------------------------------------------------------------- 
        
    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
        % TODO: this is the wrong place for the annotation computation; it
        % should be done in SceneEarSignalProc -- and is now here, for the
        % moment, to avoid recomputation with SceneEarSignalProc.
        
        function avgdBlockAnnots = extendMeanAnnotations( avgdBlockAnnots )
            srcsGlobalRefEnergyMeanChannel = cellfun( ...
                                    @(c)(sum(c) ./ 2 ), avgdBlockAnnots.globalSrcEnergy );
            srcsGlobalRefEnergyMeanChannel_db = 10 * log10( srcsGlobalRefEnergyMeanChannel );
            haveSrcsEnergy = srcsGlobalRefEnergyMeanChannel_db > -40;
            isAmbientSource = isnan( avgdBlockAnnots.srcAzms );
            haveSrcsEnergy(isAmbientSource) = [];
            avgdBlockAnnots.nActivePointSrcs = single( sum( haveSrcsEnergy ) );
            avgdBlockAnnots.srcSNR2 = 10 * log10( avgdBlockAnnots.nrj ./ avgdBlockAnnots.nrjOthers );
            avgdBlockAnnots.nrj = 10 * log10( avgdBlockAnnots.nrj );
            avgdBlockAnnots.nrjOthers = 10 * log10( avgdBlockAnnots.nrjOthers );
            avgdBlockAnnots.globalSrcEnergy = cellfun( @(c)(10 * log10( c )), ...
                                avgdBlockAnnots.globalSrcEnergy, 'UniformOutput', false );
        end
        %% ------------------------------------------------------------------------------- 
        
        % TODO: this is the wrong place for the annotation computation; it
        % should be done in SceneEarSignalProc -- and is now here, for the
        % moment, to avoid recomputation with SceneEarSignalProc.
        
        function annotations = adjustPreMeanAnnotations( annotations )
            annotations.srcSNRactive.t = annotations.globalSrcEnergy.t;
            annotations.srcSNRactive.srcSNRactive = annotations.srcSNR_db.srcSNR_db;
            allSrcsInactive = annotations.nActivePointSrcs.nActivePointSrcs == 0;
            annotations.srcSNRactive.srcSNRactive(allSrcsInactive,:) = nan;
            annotations.srcSNRactive.srcSNRactive = annotations.srcSNRactive.srcSNRactive;
            annotations.nrj.t = annotations.globalSrcEnergy.t;
            annotations.nrj.nrj = 10.^(annotations.nrj_db.nrj_db./10);
            annotations.nrjOthers.t = annotations.globalSrcEnergy.t;
            annotations.nrjOthers.nrjOthers = 10.^(annotations.nrjOthers_db.nrjOthers_db./10);
        end
        %% ------------------------------------------------------------------------------- 
        
    end
    
end

        

