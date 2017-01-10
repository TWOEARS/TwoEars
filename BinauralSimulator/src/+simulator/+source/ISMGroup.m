classdef ISMGroup < simulator.source.GroupBase
  % Class for mirror source objects used for the mirror image model

  properties
    Room;
  end

  methods
    function init(obj)      
      obj.Room.initSubSources(obj);
    end
    
    function refresh(obj, sim)
      
      obj.refresh@simulator.source.GroupBase(sim);
      
      obj.Room.refreshSubSources(obj);
      
      for idx=1:length(obj.SubSources)
        % mute invalid image sources and sources with muted OriginalObject
        obj.SubSources(idx).Mute = ~obj.SubSources(idx).Valid;
      end
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

      [h, leg] = obj.plot@simulator.source.GroupBase(figureid);
      set(h(1),'Marker','square');
    end
  end

  %% setter/getter
  methods
    function set.Room(obj, r)
      isargclass('simulator.room.Base',r);
      obj.Room = r;
    end
  end
end
