classdef PWDGroup < simulator.source.GroupBase

  properties (Dependent)
    Directions;
    Azimuths;
  end

  properties (Access = private)
    SubDirections;
  end

  %% Constructor
  methods
    function obj = PWDGroup()
      obj = obj@simulator.source.GroupBase();
      obj.addXMLAttribute('Azimuths', 'double', 'Azimuths', @(x) str2num(x));
      obj.addXMLAttribute('Directions', 'double');
    end
  end

  methods
    function init(obj)
      obj.init@simulator.source.GroupBase();
      obj.SubSources = simulator.source.PlaneWave.empty();
      for wdx=1:obj.RequiredChannels
        obj.SubSources(wdx) = simulator.source.PlaneWave();
        obj.SubSources(wdx).GroupObject = obj;
        obj.SubSources(wdx).UnitX = obj.SubDirections(:,wdx);
      end
    end
  end

  %% SSR compatible stuff
  methods
    function v = ssrData(obj, BlockSize)
      v = obj.getData(BlockSize);
    end
    function v = ssrMute(obj)
      v = repmat(obj.Mute, 1, obj.RequiredChannels);
    end
  end

  %% MISC
  methods
    function [h, leg] = plot(obj, figureid)
      if nargin < 2
        figure;
      else
        figure(figureid);
      end

      [h, leg] = obj.plot@simulator.source.GroupBase(figureid);
      set(h(1),'Marker','^');
    end
  end

  %% getter/setter
  methods
    function v = get.Directions(obj)
      v = obj.SubDirections;
    end
    function set.Directions(obj, v)
      % normalize directions
      obj.SubDirections = v./repmat(sqrt(sum(v.^2,1)),3,1);
      obj.RequiredChannels = size(v,2);
    end
    function v = get.Azimuths(obj)
      v = atan2d(obj.SubDirections(2,:), obj.SubDirections(1,:));
    end
    function set.Azimuths(obj, v)
      obj.SubDirections = [cosd(v); sind(v); zeros(1,size(v,2))];
      obj.RequiredChannels = size(v,2);
    end
  end
end
