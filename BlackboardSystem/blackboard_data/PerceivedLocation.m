classdef PerceivedLocation < Hypothesis
    % class PerceivedLocation represents a perceived source location

    properties (SetAccess = private)
        location;                         % source location
        headOrientation;                  % head orientation
        relativeLocation;                 % source location relative to head orientation
    end

    methods
        function obj = PerceivedLocation(headOrientation, location, posterior)
            obj.location = location;
            obj.headOrientation = headOrientation;
            obj.relativeLocation = mod(location + headOrientation, 360);
            obj.setScore(posterior);
        end
    end

end

% vim: set sw=4 ts=4 expandtab textwidth=90 :
