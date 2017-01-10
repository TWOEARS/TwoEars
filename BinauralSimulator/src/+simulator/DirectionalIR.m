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
    maxHeadLeft = inf;
    % Minimum Azimuth of IR-Dataset
    % @type double
    % @default -inf
    maxHeadRight = -inf;
    % Middle Azimuth of IR-Dataset
    % @type double
    % @default 0
    TorsoAzimuth = NaN;
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
    function obj = DirectionalIR(varargin)
      % function obj = DirectionalIR(filename, srcidx)
      % constructor for DirectionIR objects
      %
      % Parameters:
      %   filename: optional filename of HRTF dataset @type char[]
      %   srcidx: index of source, if 'MultiSpeakerBRIR' SOFA-File is used
      %           @type char[] @default 1
      if nargin >= 1
        obj.open(varargin{:});
      end
    end
    function delete(obj)
      try
        isargfile(obj.Filename);
        delete(obj.Filename);
      catch
      end
    end
    function open(obj, varargin)
      % function open(obj, filename, srcidx)
      % open WAV-File for HRTFs
      %
      % Parameters:
      %   filename: name of WAV- or SOFA-file @type char[]
      %   srcidx: index of source, if 'MultiSpeakerBRIR' SOFA-File is used
      %           @type char[] @default 1
      args{1} = db.getFile(varargin{1});  % filename
      if nargin >= 3
        args{2} = varargin{2};  % srcidx
      end
      if nargin >= 4
        args{3} = varargin{3};  % srcidx
      end
      
      % reset maximum and minimum azimuth angle
      obj.maxHeadLeft = inf;
      obj.maxHeadRight = -inf;
      obj.TorsoAzimuth = NaN;
      
      [~,name,ext] = fileparts(args{1});
      if strcmp('.wav', ext)
        [d, fs] = audioread(args{1});
      elseif strcmp('.sofa', ext)
        [d, fs]= obj.convertSOFA(args{:});
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
      [tmpdir, tmpname] = fileparts(tempname(db.tmp()));
      filename = fullfile(tmpdir, [name, '_', tmpname, '.wav']);
      % MATLAB proposes to replace wavwrite with audiowrite, but this does not
      % work for a high number of channels like in HRTF datasets
      % d = d./max(abs(d(:))); % normalize
      simulator.savewav(d,filename,fs);
      
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
    function [d, fs] = convertSOFA(obj, filename, idxLoudspeaker, idxListener)
      %convertSOFA return impulse response from a SOFA file
      %
      %   USAGE
      %    [d, fs] = obj.convertSOFA( filename, idxLoudspeaker, idxListener)
      %
      %   INPUT PARAMETERS
      %       filename        - filename of SOFA file
      %       idxLoudspeaker  - index of loudspeaker to use (default: 1)
      %       idxListener     - index of listener position (default: 1)
      %
      %   OUTPUT PARAMETERS
      %       d               - impulse responses [length of IRs x 360*2]
      %       fs              - sampling frequency of impulse response
      %
      warning('off', 'SOFA:upgrade');

      if nargin <= 2
        idxLoudspeaker = 1;
      end
      if nargin <= 3
        idxListener = 1;
      end

      header = sofa.getHeader(filename);
      switch header.GLOBAL_SOFAConventions
        case 'SimpleFreeFieldHRIR'
          loudspeakerPositions = sofa.getLoudspeakerPositions(header, ...
            'spherical');
          % find entries with approx. zero elevation angle
          loudspeakerPositions = ...
            loudspeakerPositions( abs( loudspeakerPositions(:,2) ) < 0.01, :);
          % error if different distances are present
          if any( abs( ...
              loudspeakerPositions(1,3) - loudspeakerPositions(:,3) ) > 0.001 )
            error('HRTFs with different distance are not supported');
          end
          %
          availableAzimuths = wrapTo360( loudspeakerPositions(:,1) );
        case {'MultiSpeakerBRIR', 'SingleRoomDRIR'}
          %
          if strcmp(header.GLOBAL_SOFAConventions, 'SingleRoomDRIR')
            idxLoudspeaker = 1;
            idxListener = 1;
          end
          % get the sound source position
          loudspeakerPosition = ...
            sofa.getLoudspeakerPositions(filename, idxLoudspeaker, 'cartesian');
          % get the listener position
          [listenerPosition, idxIncludedMeasurements] = ...
            sofa.getListenerPositions(filename, idxListener, 'cartesian');
          % get available head orientations for listener position
          [availableAzimuths, availableElevations] = ...
            sofa.getHeadOrientations(filename, idxIncludedMeasurements);
          % find entries with approx. zero elevation angle
          availableAzimuths = ...
            availableAzimuths( abs( availableElevations ) < 0.01 );
          %
          availableAzimuths = wrapTo360( availableAzimuths );
          %
          listenerOffset = SOFAconvertCoordinates(...
            loudspeakerPosition - listenerPosition, 'cartesian', 'spherical');
      end
      % sort azimuths
      availableAzimuths= sort(availableAzimuths); 
      % distance of measurements along circle
      dist = simulator.DirectionalIR.angularDistanceMeasure( ...
        availableAzimuths(:), circshift(availableAzimuths(:),[1,0]) );
      % get the minimum distance between two measurements = resolution
      resolution = min( dist );
      % get the maximum distance between two measurements
      [gap, adx] = max( dist );
      % define maximum and miminum head orientation
      if gap >= 1.5*resolution  % this is an abitrary bound
        phiMin = availableAzimuths(adx);
        phiMax = availableAzimuths( ...
          mod(adx - 2,length(availableAzimuths)) + 1);
        % center of this area
        obj.TorsoAzimuth = phiMin + mod(phiMax - phiMin, 360)/2;
        
        obj.maxHeadLeft = mod(phiMax - obj.TorsoAzimuth + 180, 360) - 180;
        obj.maxHeadRight = mod(phiMin - obj.TorsoAzimuth + 180, 360) - 180;
      end
      % create regular grid with this distance
      if resolution == 0
        nangle = 1;
      else
        nangle = round(360/resolution);
      end
      % azimuth grid
      phi = (0:nangle-1)./nangle*360;
      % adjust grid corresponding to loudspeaker position
      if ~strcmp('SimpleFreeFieldHRIR', header.GLOBAL_SOFAConventions)
        phi = wrapTo360( -phi + listenerOffset(1) );
      end
      % get the data
      [d, fs] = ...
        sofa.getImpulseResponse(filename, phi, idxLoudspeaker, idxListener);
    end
  end
  
  methods (Static)
    function res = angularDistanceMeasure(a, b)
      x = mod(a - b, 360);
      res = min(abs(x), abs(360 - x));
    end
    function [idx, diff] = nearestNeighbor(grid, b)
      [grid, b] = meshgrid(grid, b);
      diff = simulator.DirectionalIR.angularDistanceMeasure(grid, b);
      [diff, idx] = min(diff,[],1);
    end
  end
end
