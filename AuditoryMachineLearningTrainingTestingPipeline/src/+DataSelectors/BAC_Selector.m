classdef BAC_Selector < DataSelectors.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = BAC_Selector()
            obj = obj@DataSelectors.Base();
        end
        % -----------------------------------------------------------------
    
        function [selectFilter] = getDataSelection( obj, sampleIdsIn, maxDataSize )
            selectFilter = true( size( sampleIdsIn ) );
            y = obj.getData( 'y' );
            y = y(sampleIdsIn);
            [throwoutIdxs,nClassSamples,nPerLabel,labels] = ...
                          DataSelectors.BAC_Selector.getBalThrowoutIdxs( y, maxDataSize );
            selectFilter(throwoutIdxs) = false;
            obj.verboseOutput = sprintf( '\nOut of a pool of %d samples,\n', ...
                                         numel( sampleIdsIn ) );
            for ii = 1 : numel( nClassSamples )
                obj.verboseOutput = sprintf( ['%s' ...
                                              'randomly select %d/%d of class %d\n'], ...
                                             obj.verboseOutput, ...
                                             nClassSamples(ii), nPerLabel(ii), labels(ii) );
            end
        end
        % -----------------------------------------------------------------

    end
    % ---------------------------------------------------------------------
    
    methods (Static)
        
        function [throwoutIdxs,nClassSamples,nPerLabel,labels] = getBalThrowoutIdxs( y, maxDataSize )
            labels = unique( y );
            nPerLabel = arrayfun( @(l)(sum( l == y )), labels );
            [~, labelOrder] = sort( nPerLabel );
            nLabels = numel( labels );
            nClassSamples = zeros( nLabels, 1 );
            nRemaining = maxDataSize;
            throwoutIdxs = [];
            for ii = labelOrder'
                nKeep = min( int32( nRemaining/nLabels ), nPerLabel(ii) );
                nClassSamples(ii) = nKeep;
                nRemaining = nRemaining - nKeep;
                nLabels = nLabels - 1;
                lIdxs = find( y == labels(ii) );
                lIdxs = lIdxs(randperm(nPerLabel(ii)));
                throwoutIdxs = [throwoutIdxs; lIdxs(nKeep+1:end)];
            end
        end
        % -----------------------------------------------------------------

    end

end

