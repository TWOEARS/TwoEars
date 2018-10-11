classdef BAC_NS_NPP_Weighter < ImportanceWeighters.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
%         labelWeights;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = BAC_NS_NPP_Weighter( labelWeights )
            obj = obj@ImportanceWeighters.Base();
%             if nargin >= 1
%                 obj.labelWeights = labelWeights;
%             end
        end
        % -----------------------------------------------------------------
    
        function [importanceWeights] = getImportanceWeights( obj, sampleIds )
            importanceWeights = ones( size( sampleIds ) );
            y = obj.data(:,'y');
            y = y(sampleIds,:);
            assert( size( y, 2 ) == 1 );
            ba = obj.data(:,'blockAnnotations');
            ba = ba(sampleIds);
            ba_ns = cat( 1, ba.nActivePointSrcs );
            ba_pp = cat( 1, ba.posPresent );
            clear ba;
            y_ = y .* (ba_ns+1) .* (1 + ~ba_pp * 9);
            y_unique = unique( y_ );
            for ii = 1 : numel( y_unique )
                y_unique_ii_lidxs = y_ == y_unique(ii);
                lw = numel( sampleIds ) / sum( y_unique_ii_lidxs );
                if y_unique(ii) > 0
                    lw = lw * 2; % because their is p vs (npp+nnp)
                end
                importanceWeights(y_unique_ii_lidxs) = lw;
            end
            importanceWeights = importanceWeights / min( importanceWeights );
            obj.verboseOutput = '\nWeighting samples of \n';
            for ii = 1 : numel( y_unique )
                trueLabel = unique( y(y_==y_unique(ii)) );
                labelWeight = unique( importanceWeights(y_==y_unique(ii)) );
                obj.verboseOutput = sprintf( ['%s' ...
                                              '  class %d (%d) with %f\n'], ...
                                             obj.verboseOutput, ...
                                             y_unique(ii), trueLabel, labelWeight );
            end
        end
        % -----------------------------------------------------------------

    end

end

