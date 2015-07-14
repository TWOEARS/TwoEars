classdef Noise < simulator.buffer.Base
  % basically implements a AWGN buffer
  
  properties
    % mu of gaussian distribution
    % @type double
    Mean = 0.0
    % sigma of gaussian distribution
    % @type double
    Variance = 1.0
  end
  
  methods
    function obj = Noise(mapping)
      % function obj = Data(mapping)
      % constructor
      %
      % Parameters:
      %   mapping: corresponds to ChannelMapping @type integer[] @default 1
      if nargin < 1
        mapping = 1;
      end
      obj = obj@simulator.buffer.Base(mapping);
      obj.addXMLAttribute('Mean','double');
      obj.addXMLAttribute('Variance','double');
    end
  end
  
  %% Access-Functionality
  methods
    function data = getData(obj, len, channels)
      % function data = getData(obj, len, channels)
      % reads data from buffer of specified length
      %
      % Parameters:
      %   len: number of samples @type integer @default inf
      %   channels: optional select of outputchannels @type integer[]
      %   @default [1:simulator.buffer.Base.NumberOfOutputs]
      %
      % Return values:
      %   data: @type double[][]
      
      % optional pre-selection of channels
      if nargin < 3
        mapping = obj.ChannelMapping;
      else
        mapping = obj.ChannelMapping(channels);
      end
      [~, kdx, idx] = unique(mapping);      
      
      data = randn(len,length(kdx));
      data = obj.Variance.*data(:,idx) - obj.Mean;
    end
    function v = isEmpty(obj)
      % function b = isEmpty(obj)
      % always false
      v = false;
    end
  end
  
  %% Setter, Getter
  methods
    function set.Variance(obj,v)
      isargscalar(v);
      obj.Variance = v;
    end
    function set.Mean(obj,v)
      isargscalar(v);
      obj.Mean = v;
    end
  end
end