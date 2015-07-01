classdef Ring < simulator.buffer.Data
  % basically implements a loop buffer

  properties (Access = private)
    % array of position pointer for each output channel
    % @type integer[]
    DataPointer;
  end

  methods
    function obj = Ring(mapping, StartPointer)
      % function obj = Ring(mapping, StartPointer)
      % constructor
      %
      % Parameters:
      %   mapping: corresponds to ChannelMapping @type integer[] @default 1
      %   StartPointer: initial value of DataPointer @type integer[] @default [0]
      if nargin < 1
        mapping = 1;
      end
      obj = obj@simulator.buffer.Data(mapping);

      if nargin < 2
        StartPointer = zeros(1, obj.NumberOfOutputs);
      end
      obj.DataPointer = StartPointer;
    end
    function setData(obj, data, StartPointer)
      % function setData(obj, data)
      % sets data of buffer (deletes old data)
      %
      % Parameters:
      %   data: data which is stored in buffer @type double[][]
      if nargin < 3
        StartPointer = zeros(1, obj.NumberOfOutputs);
      end
      obj.DataPointer = StartPointer;
      obj.setData@simulator.buffer.Data(data);
    end
    function data = getData(obj, length, channels)
      % function data = getData(obj, length, data)
      % reads data from FIFO buffer of specified length
      %
      % If length is longer than the current buffer content, zero padding is applied
      %
      % Parameters:
      %   length: number of samples @type integer @default inf
      %   channels: optional select of outputchannels @type integer[]
      %   @default [1:simulator.buffer.Base.NumberOfOutputs]
      %
      % Return values:
      %   data: @type double[][]
      %
      % See also: simulator.Base.getData

      % optional pre-selection of channels
      if nargin < 3
        mapping = obj.ChannelMapping;
      else
        mapping = obj.ChannelMapping(channels);
      end

      % optional length definition
      if nargin < 2
        if size(obj.data,1) <= 0
          data = [];
          return;
        end
        length = size(obj.data, 1);
      end

      data = zeros(length, obj.NumberOfOutputs);
      if size(obj.data,1) ~= 0
        data = zeros(length, obj.NumberOfOutputs);
        for idx=1:obj.NumberOfOutputs
          selector = mod(obj.DataPointer(idx)+(0:length-1),size(obj.data,1));
          data(:,idx) = obj.data(selector+1,mapping(idx));
        end
      end
    end
    function removeData(obj, length)
      % function removeData(obj, length)
      % shifts the data DataPointer about length
      %
      % Parameters:
      %   length: shift in samples @type integer
      if ~isempty(obj.data)
        obj.DataPointer = mod(obj.DataPointer+length,size(obj.data,1));
      end
    end
  end

  %% Setter, Getter
  methods
    function set.DataPointer(obj, v)
      isargvector(v)
      if obj.NumberOfOutputs ~= length(v)
        error('number of outputs (%d) does not match number of start pointers (%d)', ...
          obj.NumberOfOutputs, length(v));
      end
      obj.DataPointer = v;
    end
  end
end
