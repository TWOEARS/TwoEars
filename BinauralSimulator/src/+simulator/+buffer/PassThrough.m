classdef PassThrough < simulator.buffer.Base
  % uses output channels of other buffer object as input and maps it to a new
  % output
  
  properties
    % Input buffer
    % @type simulator.buffer.Base
    ParentBuffer
  end
  
  methods
    function obj = PassThrough(mapping, buffer)
      % function obj = Data(mapping)
      % constructor
      %
      % Parameters:
      %   mapping: corresponds to ChannelMapping @type integer[]
      %   buffer: corresponds to ParentBuffer @type simulator.buffer.Base
      obj = obj@simulator.buffer.Base(mapping);
      obj.ParentBuffer = buffer;
    end
  end
  
  %% Access-Functionality
  methods
    function data = getData(obj, length, channels)
      % function data = getData(obj, length, channels)
      % reads data from the parent buffer
      %
      % Parameters:
      %   length: number of samples @type integer @default inf
      %   channels: optional select of outputchannels @type integer[]
      %   @default [1:simulator.buffer.Base.NumberOfOutputs]      
      %
      % Return values:
      %   data: @type double[][]
      %
      % See also: simulator.buffer.Base.getData
      
      % optional pre-selection of channels
      if nargin < 3
        mapping = obj.ChannelMapping;
      else
        mapping = obj.ChannelMapping(channels);
      end
      
      if nargin < 2
        data = obj.ParentBuffer.getData();
        data = data(:,mapping);
      else
        data = obj.ParentBuffer.getData(length, mapping);
      end
    end
    function b = isEmpty(obj)
      % function b = isEmpty(obj)
      % indicates if ParentBuffer is empty
      b = obj.ParentBuffer.isEmpty(obj);
    end
  end
  %% setter/getter
  methods
    function set.ParentBuffer(obj, v)
      isargclass('simulator.buffer.Base', v);
      obj.ParentBuffer = v;
    end
  end
end