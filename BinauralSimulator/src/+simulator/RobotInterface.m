classdef (Abstract) RobotInterface < hgsetget
  % wrapper class for the actual robot functionality

  %% Head Rotation
  methods
    function rotateHead(obj, angleDeg, mode)
      % function rotateHead(obj, angleDeg, mode)
      % rotate head
      %
      % Parameters:
      %   angleDeg: angle in degree @type double
      %   mode: either 'relative' or 'absolute' @type char[] @default 'relative'
      %
      % rotate head either about (mode='relative') or to (mode='absolute')

      isargscalar(angleDeg);
      if (nargin < 3)
        mode = 'relative';
      else
        isargchar(mode);
      end

      switch mode
        case 'relative'
          obj.rotateHeadRelative(angleDeg);
        case 'absolute'
          obj.rotateHeadAbsolute(angleDeg);
        otherwise
          error('mode (%s) not supported', mode);
      end
    end
  end
  %% signal acquisition
  methods (Abstract)
    [sig, timeIncSec, timeIncSamples] = getSignal(obj, timeIncSec)
    % function [sig, timeIncSec, timeIncSamples] = getSignal(obj, timeIncSec)
    % get binaural of specified length
    %
    % Parameters:
    %   timeIncSec: length of signal in seconds @type double
    %
    % Return Values:
    %   timeIncSec: length of signal in seconds @type double
    %   timeIncSamples: length of signal in samples @type integer
    %
    % Due to the frame-wise processing length of the output signal can
    % vary from specified signal length. This is indicated by the 2nd and
    % 3rd return value.
  end
  methods (Abstract)
    azimuth = getCurrentHeadOrientation(obj)
    % function azimuth = getCurrentHeadOrientation(obj)
    % get current head orientation in degrees
    %
    % Return Values:
    %   azimuth: absolute angle in degree @type double
    %
    % look directions:
    %   0/ 360 degree = positive x-axis
    %  90/-270 degrees = positive y-axis
    % 180/-180 degrees = negative x-axis
    % 270/- 90 degrees = negative y-axis
  end
  methods (Abstract, Access=protected)
    rotateHeadAbsolute(obj, angleDeg)
    % function rotateHeadAbsolute(obj, angleDeg)
    % rotate about an incremental angle in degrees
    %
    % Parameters:
    %   angleDeg: absolute angle in degree @type double
    %
    % look directions:
    %   0/ 360 degree = positive x-axis
    %  90/-270 degrees = positive y-axis
    % 180/-180 degrees = negative x-axis
    % 270/- 90 degrees = negative y-axis
  end
  methods (Abstract, Access=protected)
    rotateHeadRelative(obj, angleIncDeg)
    % function rotateHeadRelative(obj, angleIncDeg)
    % rotate about an incremental angle in degrees
    %
    % Parameters:
    %   angleIncDeg: angle increment in degree @type double
    %
    % negative angle result in rotation to the right
    % positive angle result in rotation to the left
  end
end
