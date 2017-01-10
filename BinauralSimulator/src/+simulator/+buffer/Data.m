classdef (Abstract) Data < simulator.buffer.Base
  % abstract base class for FIFO and Ring buffers.

  properties (SetAccess = protected, Hidden)
    % data source
    % @type double[][]
    data = [];
  end
  properties (GetAccess = private, Dependent)
    % file for data source
    %
    % File is exspected to be a name of an existing File, which can be read
    % via MATLABs audioread
    %
    % @type char[]
    %
    % See also: data
    File;
  end

  methods
    function obj = Data(mapping)
      % function obj = Data(mapping)
      % constructor
      %
      % Parameters:
      %   mapping: corresponds to ChannelMapping @type integer[] @default 1
      if nargin < 1
        mapping = 1;
      end
      obj = obj@simulator.buffer.Base(mapping);
      obj.addXMLAttribute('File', 'dbfile');
    end
    function b = isEmpty(obj)
      % function b = isEmpty(obj)
      % indicates if buffer is empty
      %
      % Return values:
      %   b: indicates if buffer is empty @type logical
      b = isempty(obj.data);
    end
  end

  %% Access-Functionality
  methods
    function setData(obj, data)
      % function setData(obj, data, channels)
      % sets data of buffer (deletes old data)
      %
      % Parameters:
      %   data: data which is stored in buffer @type double[][]
      if size(data,2) ~= obj.NumberOfInputs
        error('number of columns does not match number of input channels');
      end
      obj.data = data;
    end
  end
  methods (Abstract)
    removeData(obj, length)
      % remove data from buffer
      %
      % Parameters:
      %   length: number of samples which should be removed @type integer
      %
      % virtual function which should be implemented in the sub-classes
  end
  %% File-IO
  methods
    function loadFile(obj, filename, fs)
      % load audio file into buffer (deletes old data)
      %
      % Parameters:
      %   filename: name of audio file @type char[]
      %   fs: forced sampling frequency, optional @type double
      %
      % Defining the sampling frequency 'fs' will eventually lead to a
      % resampling of the audio signal provided in 'filename'. If 'fs' is
      % not defined, the original sampling frequency of the audio file is
      % kept.
      
      % read audio data from file
      [obj.data, fsorig] = audioread(db.getFile(filename));
      % optional resampling
      if nargin > 2
        isargpositivescalar(fs);
        if fs ~= fsorig
          obj.data = resample(obj.data, fs, fsorig);
        end
      end
      % normalize data and change precision of data
      obj.data = single(obj.data./max(abs(obj.data(:))));
    end
    function saveFile(obj, filename, fs)
      % save buffer content to audio file
      %
      % Parameters:
      %   filename: name of audio file @type char[]
      %   fs: optional sampling frequency @type double @default 44100
      %
      % This functionality is dependent on the the implementation of the
      % 'getData' method of each potential sub-class.  It does not read the raw
      % data from the buffer matrix. The output content will be normalized to
      % the absolute maximum among all samples inside the output.
      %
      % See also: simulator.buffer.Base.getData

      isargchar(filename);

      if nargin < 3
        fs = 44100;
      else
        isargpositivescalar(fs);
      end

      tmp = obj.getData();
      % check if the buffer was empty
      if isempty(tmp)
        error('Buffer seems to be empty!');
      end

      audiowrite(filename, tmp./max(abs(tmp(:))), fs);  % normalize data

      fprintf(...
        'Saved buffer data (channels=%d, samples=%d, fs=%dHz) to %s \n', ...
        size(tmp,2), size(tmp,1), fs, filename);
    end
  end

  %% setter/getter
  methods
    function set.File(obj, f)
      obj.loadFile(f);
    end
  end
end
