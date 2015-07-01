classdef (Abstract) Base < xml.MetaObject
  % abstract base class for all audio buffers.

  properties
    % mapping between input/data channels and output channels
    % @type integer[]
    ChannelMapping;
  end
  properties (SetAccess=private, Dependent)
    % Number of input/data channels
    % @type integer
    NumberOfInputs;
    % Number of output channels
    % @type integer
    NumberOfOutputs;
  end

  methods
    function obj = Base(mapping)
      % function obj = Base(mapping)
      % constructor
      %
      % Parameters:
      %   mapping: corresponds to ChannelMapping @type integer[] @default 1
      if nargin < 1
        mapping = 1;
      end
      obj.ChannelMapping = mapping;

      % xml
      obj.addXMLAttribute('ChannelMapping', 'double');
    end
    function removeData(obj, length)
      % function removeData(obj, length)
      % this function does nothing by default
      %
      % overload this function for implementing sub-class-specific
      % functionalities
    end
  end

  %% Abstract Functions
  methods (Abstract)
    data = getData(obj, length, channels)
    % function data = getData(obj, length, channels)
    % reads data from buffer of specified length
    %
    % Parameters:
    %   length: number of samples @type integer
    %   channels: optional select of outputchannels @type integer[]
    %
    % Return values:
    %   data: @type double[][]

    b = isEmpty(obj)
    % function b = isEmpty(obj)
    % indicates if buffer is empty
    %
    % Return values:
    %   b: indicates if buffer is empty @type logical
  end

  %% Setter, Getter
  methods
    function set.ChannelMapping(obj,v)
      isargvector(v);
      obj.ChannelMapping = v;
    end
    function v = get.NumberOfOutputs(obj)
      v = length(obj.ChannelMapping);
    end
    function v = get.NumberOfInputs(obj)
      v = max(obj.ChannelMapping);
    end
  end
end
