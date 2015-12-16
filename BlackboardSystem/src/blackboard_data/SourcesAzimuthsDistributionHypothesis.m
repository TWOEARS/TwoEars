classdef SourcesAzimuthsDistributionHypothesis < Hypothesis
    % class SourcesAzimuthsDistributionHypothesis represents a distribution of azimuths
    % for possible source positions

    properties (SetAccess = private)
        sourcesDistribution;           % Posterior distribution of possible sources
        azimuths;                      % Relative azimuths (x-axis of sourcesDistribution)
        headOrientation;               % Head orientation angle
        seenByConfusionKS = false;
        seenByConfusionSolvingKS = false;
    end

    methods
        function obj = SourcesAzimuthsDistributionHypothesis( ...
                headOrientation, azimuths, sourcesDistribution)
            obj.headOrientation = headOrientation;
            obj.azimuths = azimuths;
            obj.sourcesDistribution = sourcesDistribution;
        end
        function obj = setSeenByConfusionKS(obj)
            obj.seenByConfusionKS = true;
        end
        function obj = setSeenByConfusionSolvingKS(obj)
            obj.seenByConfusionSolvingKS = true;
        end
    end

end
% vim: set sw=4 ts=4 et tw=90 cc=+1:
