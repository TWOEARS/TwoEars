classdef SourcesAzimuthsDistributionHypothesis < Hypothesis
    % class SourcesAzimuthsDistributionHypothesis represents a distribution of azimuths
    % for possible source positions

    properties (SetAccess = private)
        sourcesDistribution;           % Posterior distribution of possible sources
        azimuths;                      % Relative azimuths (x-axis of sourcesDistribution)
        headOrientation;               % Head orientation angle
        seenByLocalisationDecisionKS = false;
        seenByHeadRotationKS = false;
    end

    methods
        function obj = SourcesAzimuthsDistributionHypothesis( ...
                headOrientation, azimuths, sourcesDistribution)
            obj.headOrientation = headOrientation;
            obj.azimuths = azimuths;
            obj.sourcesDistribution = sourcesDistribution;
        end
        function obj = setSeenByHeadRotationKS(obj)
            obj.seenByHeadRotationKS = true;
        end
        function obj = setSeenByLocalisationDecisionKS(obj)
            obj.seenByLocalisationDecisionKS = true;
        end
    end

end
% vim: set sw=4 ts=4 et tw=90 cc=+1:
