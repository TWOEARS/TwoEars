classdef PerceivedAzimuth < Hypothesis
    % class PerceivedAzimuth represents the perceived source azimuth

    properties (SetAccess = private)
        azimuth;                         % source azimuth
        headOrientation;                 % head orientation
        relativeAzimuth;                 % source azimuth relative to head orientation
    end

    methods
        function obj = PerceivedAzimuth(headOrientation, azimuth, posterior)
            obj.azimuth = wrapTo360(azimuth);
            obj.headOrientation = wrapTo360(headOrientation);
            obj.relativeAzimuth = wrapTo360(obj.azimuth + obj.headOrientation);
            obj.setScore(posterior);
        end
    end

end

% vim: set sw=4 ts=4 expandtab textwidth=90 :
