classdef (Abstract) Base < simulator.Object
  % Class for source-objects in audio scene

  properties
    % mute flag to mute source output
    %
    % Note that toggling Mute will fade in/out the source signal in the next
    % block. There is no instant switch on/off.
    %
    % See also: Volume
    %
    % @type logical
    % @default false
    Mute = false;
    % volume of sound source
    %
    % Linear factor (0.0 == silence). Note that changing the Volume will result
    % in a cross-fade between the old and new volume value in the next block.
    % There is no instant switch between the two values.
    %
    % See also: Mute
    %
    % @type double
    % @default 1.0
    Volume = 1.0;
    % audio buffer which contains input signal of source
    % @type simulator.buffer.Base
    AudioBuffer;
    % impulse response file for BRS or Generic Renderer
    %
    % This File is required for the BRS Renderer, defining the BRIR-Dataset of
    % the source. This should be a n-channel *.wav file. All other Renderers
    % will ignore this property
    %
    % See also: db.getFile()
    % @type DirectionalIR
    % @default simulator.DirectionalIR()
    IRDataset = simulator.DirectionalIR();
  end

  properties (SetAccess = protected, Hidden=true)
    % required number of channels of input signal
    % @type integer
    % @default 1
    %
    % To set AudioBuffer to the Source object AudioBuffer.NumberOfChannels
    % has to match RequiredChannels
    RequiredChannels = 1;
  end

  methods
    function obj = Base()
      % function obj = Base()

      obj.addXMLAttribute('Mute', 'logical');
      obj.addXMLAttribute('Volume', 'double');
      obj.addXMLAttribute('IRDataset',  ...
        'simulator.DirectionalIR', ...
        'IRs', ...
        @(x) simulator.DirectionalIR(db.getFile(x)));
    end
  end

  methods
    function init(obj)
      if obj.AudioBuffer.NumberOfOutputs ~= obj.RequiredChannels
        obj.errormsg(...
          'Number of outputs of obj.AudioBuffer does not match obj.RequiredChannels!');
      end
    end
    function refresh(obj, sim)    
      obj.refresh@simulator.Object(sim);

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
    function [left, right, torso] = getHeadLimits(obj)
      left = obj.IRDataset.maxHeadLeft;
      right = obj.IRDataset.maxHeadRight;
      torso = obj.IRDataset.TorsoAzimuth;
    end
  end

  %% SSR compatible stuff
  methods
    function v = ssrData(obj, BlockSize)
      v = obj.getData(BlockSize);
    end
    function v = ssrChannels(obj)
      v = obj.RequiredChannels;
    end
    function v = ssrMute(obj)
      v = obj.Mute;
    end
    function v = ssrGain(obj)
      v = obj.Volume;
    end
    function v = ssrIRFile(obj)
      v = cell(size(obj));
      for idx=1:numel(v)
        v{idx} = obj(idx).IRDataset.Filename;
      end
    end
  end
  methods (Abstract)
    v = ssrType(obj);
  end

  %% XML
  methods (Access=protected)
    function configureXMLSpecific(obj, xmlnode)
      % init Buffer
      buffer = xmlnode.getElementsByTagName('buffer').item(0);

      mapping = 1:obj.RequiredChannels;

      import simulator.buffer.*
      switch (char(buffer.getAttribute('Type')))
        case 'fifo'
          obj.AudioBuffer = simulator.buffer.FIFO(mapping);
        case 'ring'
          obj.AudioBuffer = simulator.buffer.Ring(mapping);
        case 'noise'
          obj.AudioBuffer = simulator.buffer.Noise(mapping);
        otherwise
          error('source type (%s) not supported',char(buffer.getAttribute('Type')));
      end
      obj.AudioBuffer.XML(buffer);
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

      [h, leg] = obj.plot@simulator.Object(figureid);
      set(h,'MarkerEdgeColor', [0, 0, 0]);
      if (~obj.Mute)
        white = 1.0 - min(1.0, abs(obj.Volume));
        set(h,'MarkerFaceColor', [1.0, white, white]);
      end
    end
  end

  %% setter/getter
  methods
    function set.AudioBuffer(obj, b)
      isargclass('simulator.buffer.Base', b);

      if b.NumberOfOutputs ~= obj.RequiredChannels
        obj.warnmsg(...
          'Number of outputs of obj.AudioBuffer does not match obj.RequiredChannels!');
      end
      obj.AudioBuffer = b;
    end
    function set.Volume(obj, v)
      isargscalar(v);
      obj.Volume = v;
    end
    function v = get.Volume(obj)
      v = obj.Volume;
      try
        v = v * obj.GroupObject.Volume;
      catch
      end
    end
    function v = get.Mute(obj)
      v = obj.Mute;
      try
        v = v || obj.GroupObject.Mute;
      catch
      end
    end
  end

  %% functionalities of AudioBuffer which have to be encapsulated
  methods
    function setData(obj,data)
      obj.AudioBuffer.setData(data);
    end
    function d = getData(obj,length)
      if nargin < 2
        d = obj.AudioBuffer.getData();
      else
        d = obj.AudioBuffer.getData(length);
      end
    end
    function removeData(obj, length)
      if nargin < 2
        obj.AudioBuffer.removeData();
      else
        obj.AudioBuffer.removeData(length);
      end
    end
    function appendData(obj, data)
      obj.AudioBuffer.appendData(data);
    end
    function b = isEmpty(obj)
      b = obj.AudioBuffer.isEmpty();
    end
  end
end
