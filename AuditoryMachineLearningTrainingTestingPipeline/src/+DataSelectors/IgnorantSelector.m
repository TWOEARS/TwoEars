classdef IgnorantSelector < DataSelectors.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = IgnorantSelector()
            obj = obj@DataSelectors.Base();
        end
        % -----------------------------------------------------------------
    
        function [selectFilter] = getDataSelection( obj, sampleIdsIn, maxDataSize )
            selectFilter = true( size( sampleIdsIn ) );
            rndIdxs = randperm( numel( sampleIdsIn ) );
            selectFilter(rndIdxs(maxDataSize+1:end)) = false;
            obj.verboseOutput = sprintf( ['Out of a pool of %d samples, ' ...
                                          'randomly select %d...\n'], ...
                                          numel( sampleIdsIn ), maxDataSize );
        end
        % -----------------------------------------------------------------

    end

end

