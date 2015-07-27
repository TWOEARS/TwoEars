classdef DirectionalIR < hgsetget
  % Class for HRIRs-Datasets

  properties (SetAccess=private)
    % Number of directions of IR-Dataset
    % @type integer
    % @default 0
    NumberOfDirections = 0;
    % Number of samples of IR-Dataset
    % @type integer
    % @default 0
    NumberOfSamples = 0;
    % Angular Resolution of IR-Dataset
    % @type double
    % @default inf
    AzimuthResolution = inf;
    % Maximum Azimuth of IR-Dataset
    % @type double
    % @default inf
    AzimuthMax = inf;
    % Minimum Azimuth of IR-Dataset
    % @type double
    % @default -inf
    AzimuthMin = -inf;
    % Sample Rate of HRIR-Dataset in Hz
    % @type double
    SampleRate;
    % location of original wav-file
    % @type char[]
    Filename = '';
  end

  properties (Access=private)
    Data = [];
  end

  methods
    function obj = DirectionalIR(filename)
      % function obj = DirectionalIR(filename)
      % constructor for DirectionIR objects
      %
      % Parameters:
      %   filename: optional filename of HRTF dataset @type char[]
      if nargin == 1
        obj.open(filename);
      end
    end
    function delete(obj)
      try
        isargfile(obj.Filename);
        delete(obj.Filename);
      catch
      end
    end
    function open(obj, filename)
      % function open(obj, filename)
      % open WAV-File for HRTFs
      %
      % Parameters:
      %   filename: name of WAV- or SOFA-file @type char[]
      filename = xml.dbGetFile(filename);

      % reset maximum and minimum azimuth angle
      obj.AzimuthMax = inf;
      obj.AzimuthMin = -inf;
      
      [~,name,ext] = fileparts(filename);
      if strcmp('.wav', ext)
        [d, fs] = audioread(filename);
      elseif strcmp('.sofa', ext)
        warning('SOFA HRTF support is still very experimental');
        [d, fs]= obj.convertSOFA(filename);
      else
        error('file extension (%s) not supported (only .wav and .sofa)', ext);
      end

      % check whether the number of channels is even
      s = size(d, 2);
      if (mod(s,2) ~= 0)
        error('number of channels of input file has to be an integer of 2!');
      end

      % create local copy of data for the SSR MEX-Code
      % TODO: include SOFA support into the SSR
      [tmpdir, tmpname] = fileparts(tempname(xml.dbTmp()));
      filename = fullfile(tmpdir, [name, '_', tmpname, '.wav']);
      % MATLAB proposes to replace wavwrite with audiowrite, but this does not
      % work for a high number of channels like in HRTF datasets
      d = d./max(abs(d(:))); % normalize
      wavwrite(d,fs,32,filename);

      obj.SampleRate = fs;
      obj.Data = d;
      obj.NumberOfDirections = s/2;
      obj.NumberOfSamples = size(d,1);
      obj.AzimuthResolution = 360/obj.NumberOfDirections;
      obj.Filename = filename;
    end
    function tf = getImpulseResponses(obj, azimuth)
      % function tf = getImpulseResponses(obj, azimuth)
      % get HRIR for distinct azimuth angles
      %
      % nearest neighbor interpolation
      %
      % Parameters:
      %   azimuth:  azimuth angle in degree @type double[]
      %
      % Return values:
      %   tf: struct containing left (tf.left) and right (tf.right) irs
      selector = ...
        mod(round(azimuth/obj.AzimuthResolution), obj.NumberOfDirections)*2 + 1;
      tf.left = obj.Data(:,selector);
      tf.right = obj.Data(:,selector+1);
    end

    function plot(obj, id)
      % function plot(obj, id)
      % plot whole HRIR dataset
      %
      % Parameters:
      %   id:  id of figure @type integer @default 1
      if nargin < 2
        id = figure;
      else
        figure(id);
      end

      azimuth = -180:179;

      tf = obj.getImpulseResponses(azimuth);

      tfmax = max(max(abs(tf.left(:)),abs(tf.right(:))));

      tl = 20*log10(abs(tf.left)/tfmax);
      tr = 20*log10(abs(tf.right)/tfmax);

      time = (0:size(tl,1)-1)/obj.SampleRate*1000;

      subplot(1,2,1);
      imagesc(azimuth,time, tl);
      title('Left Ear Channel');
      xlabel('angle (deg)');
      ylabel('time (ms)');
      set(gca,'CLim',[-50 0]);
      colorbar;

      subplot(1,2,2);
      imagesc(azimuth,time, tr);
      title('Right Ear Channel');
      xlabel('angle (deg)');
      ylabel('time (ms)');
      set(gca,'CLim',[-50 0]);
      colorbar;
    end
    function [d, fs] = convertSOFA(obj,filename)

      header = SOFAload(filename, 'nodata');

      switch header.GLOBAL_SOFAConventions
        case 'SimpleFreeFieldHRIR'
          % convert to spherical coordinates
          header.SourcePosition = SOFAconvertCoordinates(...
            header.SourcePosition,header.SourcePosition_Type,'spherical');
          % find entries with approx. zero elevation angle
          select = find( abs( header.SourcePosition(:,2) ) < 0.01 );
          % error if different distances are present
          if any( header.SourcePosition(select(1),3) ~= ...
              header.SourcePosition(select,3) )
            error('HRTFs with different distance are not supported');
          end
          % sort remaining with respect to azimuth angle
          [azimuths, ind] = sort(header.SourcePosition(select,1));
        case 'SingleRoomDRIR'
          % convert to spherical coordinates
          header.ListenerView = SOFAconvertCoordinates(...
            header.ListenerView, header.ListenerView_Type,'spherical');
          % find entries with approx. zero elevation angle
          select = find( abs( header.ListenerView(:,2) ) < 0.01 );
          % sort remaining with respect to azimuth angle
          [azimuths, ind] = sort(header.ListenerView(select,1));
          % reset maximum and minimum azimuth angle
          obj.AzimuthMax = azimuths(end);
          obj.AzimuthMin = azimuths(1);          
        otherwise
          error('SOFA Conventions (%s) not supported', ...
            header.GLOBAL_SOFAConventions);
      end

      % get segments of selected indices, which are comming after each other
      segments = [1; find( select(2:end) - select(1:end-1) ~= 1)+1; ...
        length(select)+1];

      % slide-wise load of IRs (saves memory)
      d = zeros(length(select), header.API.R, header.API.N);
      jdx = 1;
      for idx=1:length(segments)-1
        iseg = select(segments(idx));  % first element of segment
        lseg = segments(idx+1) - segments(idx);  % number of elements in segment
        tmp = SOFAload(filename, [iseg lseg], 'M');  % get data from SOFA file
        d(jdx:jdx+lseg-1,:,:) = tmp.Data.IR;  % copy data into array
        jdx = jdx + lseg;
      end
      % get sampling frequency
      fs = tmp.Data.SamplingRate;
      % sort data
      d = d(ind,:,:);
      % get the minimum distance between two measurements
      resolution = min(...
        simulator.DirectionalIR.angularDistanceMeasure( ...
        azimuths, circshift(azimuths,1)...
        ) ...
        );
      % create regular grid with this distance
      nangle = round(360/resolution);
      azimuth_grid = (0:nangle-1)./nangle*360;
      % determine nearest neighbor between grid and measurements
      knd = ...
        simulator.DirectionalIR.nearestNeighbor(azimuth_grid, azimuths);
      % select nearest neightbor measurements for grid
      d = d(knd, :, :);
      % reshape the array
      d = permute(d,[3 2 1]);
      d = reshape(d,size(d,1),[]);
    end
  end

  methods (Static)   
    function res = angularDistanceMeasure(a, b)
      res = abs(mod(abs(a - b) + 180, 360) - 180);
    end
    function [idx, diff] = nearestNeighbor(grid, b)
      [grid, b] = meshgrid(grid, b);
      diff = simulator.DirectionalIR.angularDistanceMeasure(grid, b);
      [diff, idx] = min(diff,[],1);
    end
  end
end
