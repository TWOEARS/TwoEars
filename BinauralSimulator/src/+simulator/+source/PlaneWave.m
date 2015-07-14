classdef PlaneWave < simulator.source.Base & dynamicprops
  % Class for source-objects in audio scene

  %% SSR compatible stuff
  methods
    function v = ssrType(obj)
      v = repmat({'plane'}, size(obj));
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

      [h, leg] = obj.plot@simulator.source.Base(figureid);
      set(h,'Marker', 'd');
    end
  end
end
