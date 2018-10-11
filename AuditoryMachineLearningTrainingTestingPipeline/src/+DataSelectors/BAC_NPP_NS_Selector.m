classdef BAC_NPP_NS_Selector < DataSelectors.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        discardNsNotNa = true;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = BAC_NPP_NS_Selector( discardNsNotNa )
            obj = obj@DataSelectors.Base();
            if nargin >= 1
                obj.discardNsNotNa = discardNsNotNa;
            end
        end
        % -----------------------------------------------------------------
    
        function [selectFilter] = getDataSelection( obj, sampleIdsIn, maxDataSize )
            selectFilter = true( size( sampleIdsIn ) );
            ba = obj.getData( 'blockAnnotations' );
            ba = ba(sampleIdsIn);
            ba_ns = cat( 1, ba.nActivePointSrcs );
            if obj.discardNsNotNa
                % nPointSrcsSceneConfig is only in blockAnnotations if they
                % are loaded through GatherFeaturesProc
                ba_ns_scp = cat( 1, ba.nPointSrcsSceneConfig );
                nsNotNa = (ba_ns ~= ba_ns_scp) & ~(ba_ns == 0 & ba_ns_scp == 1);
                selectFilter(nsNotNa) = false;
                sampleIdsIn(nsNotNa) = [];
                ba(nsNotNa) = [];
                ba_ns(nsNotNa) = [];
            end
            ba_pp = cat( 1, ba.posPresent );
            clear ba;
            y = obj.getData( 'y' );
            y = y(sampleIdsIn);
            y_ = y .* (ba_ns+1) .* (1 + ~ba_pp * 9);
            y_Idxs = find( selectFilter );
            shouldNotExistPos = (y_ == 1); % pos although ba_ns==0
            shouldNotExistPos_l = false( size( selectFilter ) );
            shouldNotExistPos_l(y_Idxs) = shouldNotExistPos;
            selectFilter = selectFilter & ~shouldNotExistPos_l;
            y_(shouldNotExistPos) = [];
            [throwoutIdxs,nClassSamples,nPerLabel,labels] = ...
                          DataSelectors.BAC_Selector.getBalThrowoutIdxs( y_, maxDataSize );
            selectFilter(y_Idxs(throwoutIdxs)) = false;
            obj.verboseOutput = sprintf( ['\nOut of a pool of %d samples,\n' ...
                                            'discard %d where na ~= ns, and\n'], ...
                                         numel( nsNotNa ), sum( nsNotNa ) );
            for ii = 1 : numel( nClassSamples )
                trueLabel = unique( y(y_==labels(ii)) );
                obj.verboseOutput = sprintf( ['%s' ...
                                              'randomly select %d/%d of class %d (%d)\n'], ...
                                             obj.verboseOutput, ...
                                             nClassSamples(ii), nPerLabel(ii), labels(ii), trueLabel );
            end
        end
        % -----------------------------------------------------------------

    end
    % ---------------------------------------------------------------------
    
    methods (Static)
    end

end

