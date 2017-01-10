classdef IdentityLocationHypothesis < IdentityHypothesis & SourcesAzimuthsDistributionHypothesis
    
    properties (SetAccess = private)
        azimuthDecisions;   % per-azimuth decisions
    end
    
    methods
        function obj = IdentityLocationHypothesis( label, ...,
                p, d, blocksize_s, ...
                headOrientation, azimuths, azimuthProbs, azimuthDecisions )
                
                obj@IdentityHypothesis( label, ...,
                    p, d, blocksize_s );
                obj@SourcesAzimuthsDistributionHypothesis( ...
                    headOrientation, azimuths, azimuthProbs );
                obj.azimuthDecisions = azimuthDecisions;
        end
    end
    
end
