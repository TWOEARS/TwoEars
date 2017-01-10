classdef SourceSegregationHypothesis < Hypothesis
    % class SourceSegregationHypothesis represents a soft mask for the
    % target source

    properties (SetAccess = private)
        mask                % segregation mask for target source
        source = 'target';  % source name
        cfHz
        hopSize
    end

    methods
        function obj = SourceSegregationHypothesis(mask, source, cfHz, hopSize)
            obj.mask = mask;
            obj.source = source;
            obj.cfHz = cfHz;
            obj.hopSize = hopSize;
            
        end
    end

end
% vim: set sw=4 ts=4 et tw=90 cc=+1:
