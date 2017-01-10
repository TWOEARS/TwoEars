classdef BRSGroup < simulator.source.GroupBase

  properties (SetAccess = private)
    CurrentSubSource = [];
  end
  
  methods
    function refresh(obj, sim)
      obj.refresh@simulator.Object(sim);
      
      [~, idx] = min(sqrt(sum( bsxfun(@minus, [obj.SubSources.Position], ...
        sim.Sinks.Position).^2, 1)));
      for wdx=1:length(obj.SubSources)
        obj.SubSources(wdx).Mute = true;
      end
      obj.CurrentSubSource = obj.SubSources(idx);
      obj.CurrentSubSource.Mute = false;
      
      [left, right, torso] = obj.getHeadLimits();

      headAzimuth = sim.getCurrentHeadOrientation();
      if headAzimuth > left || headAzimuth < right
        error(['head-above-torso azimuth (%2.2f deg) out of bounds', ...
          ' (%2.2f:%2.2f deg)!'], headAzimuth, right,left);
      end
      [~, ~, torsoAzimuth] = sim.getCurrentRobotPosition();
      if ~isnan(torso) && abs(torsoAzimuth - torso) >= 1E-5
        warning(['The specified torso azimuth (%2.2f deg) of the simulator' ...
          ' does not match the available torso azimuth of the IR Dataset.' ...
          ' The torso azimuth will be set to %2.2f deg. The resulting head' ...
          ' azimuth in world coordinates is now %2.2f deg'], torsoAzimuth, ...
          torso, mod(headAzimuth + torso, 360));
        % rotate Sink around z-axis
        sim.Sinks.rotateAroundAxis([0; 0; 1], torso - torsoAzimuth)
        % set torso azimuth
        sim.TorsoAzimuth = mod(torso , 360);
      end
    end
    
    %%
    function loadBRSFile(obj, filename, srcidx)
      
      if nargin < 3
        srcidx = 1;
      end      
      header = SOFAload(db.getFile(filename), 'nodata');  % filename
      % convert listener position to cartesian coordinates
      positions = SOFAconvertCoordinates(...
        header.ListenerPosition, header.ListenerPosition_Type, 'cartesian');
      positions = unique(positions, 'rows', 'stable');
      
      obj.SubSources = simulator.source.Point.empty();        
      for wdx=1:size(positions,1)
        obj.SubSources(wdx) = simulator.source.Point();
        obj.SubSources(wdx).Position = positions(wdx,:).';
        obj.SubSources(wdx).GroupObject = obj;
        obj.SubSources(wdx).IRDataset = ...
            simulator.DirectionalIR(filename, srcidx, wdx);
      end
    end
    function [left, right, torso] = getHeadLimits(obj)
      left = obj.CurrentSubSource.IRDataset.maxHeadLeft;
      right = obj.CurrentSubSource.IRDataset.maxHeadRight;
      torso = obj.CurrentSubSource.IRDataset.TorsoAzimuth;
    end    
  end 
  
  %% SSR compatible stuff
  methods
    function v = ssrData(obj, BlockSize)
      v = obj.getData(BlockSize);
      v = repmat(v, 1, length(obj.SubSources));
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

  end
end
