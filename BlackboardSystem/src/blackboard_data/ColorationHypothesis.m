classdef ColorationHypothesis < Hypothesis
    % class ColorationHypothsis represents an estimate of the difference between an
    % internal reference and the test signal

    properties (SetAccess = private)
        differenceValue;    % Weighted difference between both excitation patterns
                            % ~= coloration
        sourceType;         % "speech" or "non-speech"
    end

    methods
        function obj = ColorationHypothesis(differenceValue, sourceType)
            obj.differenceValue = differenceValue;
            if strcmp('speech', sourceType)
                obj.sourceType = sourceType;
            else
                obj.sourceType = 'non-speech';
            end
        end
    end

end
% vim: set sw=4 ts=4 et tw=90 cc=+1:
