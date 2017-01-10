classdef Point < simulator.source.Base & dynamicprops
  % Class for source-objects in audio scene

  properties (Access = private)
    DistanceCorrectionWeight = 1.0;
  end

  %% SSR compatible stuff
  methods
    function v = ssrType(obj)
      v = repmat({'point'}, size(obj));
    end
  end

  %% Distance correction for 3D-2D case
  methods
%     function correctDistance(obj, RefPosition)
%       % function correctDistance(obj, RefPosition)
%       % corrects distance attenuation for point sources in 3D
%       %
%       % Since the SoundScape Renderer only supports 2D scenarios, distance
%       % correction of images sources in 3D has to be applied.
%       %
%       % Parameters:
%       %   RefPosition: reference  @type double[]
%       isargcoord(RefPosition);
% 
%       RefPosition = (obj.Position - RefPosition).^2;
%       distanceXY = max(0.5, sqrt(RefPosition(1) + RefPosition(2)));
%       distanceXYZ = max(0.5, sqrt(sum(RefPosition)));
%       obj.DistanceCorrectionWeight = distanceXY./distanceXYZ;
%     end

    function d = getData(obj,length)
      if nargin < 2
        d = obj.getData@simulator.source.Base();
      else
        d = obj.getData@simulator.source.Base(length);
      end
%       d = d.*obj.DistanceCorrectionWeight;
    end
  end

  %% MISC
  methods
    function [h, leg] = plot(obj, figureid)
      if nargin < 2
        figureid = figure;
      else
        figure(figureid);
      end

      [h, leg] = obj.plot@simulator.source.Base(figureid);
      set(h,'Marker','o');
    end
  end
end
