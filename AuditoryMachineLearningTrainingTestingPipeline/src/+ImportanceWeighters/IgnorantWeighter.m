classdef IgnorantWeighter < ImportanceWeighters.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = IgnorantWeighter()
            obj = obj@ImportanceWeighters.Base();
        end
        % -----------------------------------------------------------------
    
        function [importanceWeights] = getImportanceWeights( ~, sampleIds )
            importanceWeights = ones( size( sampleIds ) );
        end
        % -----------------------------------------------------------------

    end

end

