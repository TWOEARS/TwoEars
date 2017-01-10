classdef SimulatorConvexRoom < simulator.SimulatorInterface & simulator.RobotInterface
  %SIMULATORCONVEXROOM is the core class for simulating acoustic room scenarios

  properties (Access=private, Hidden)
    NumberOfSSRSources;
    SSRInput;
    SSRPositionXY;
    SSROrientationXY;
    SSRMute;
    SSRGain;
    SSRReferencePosXY;
    SSRReferenceOriXY;    
  end
  
  properties (SetAccess=private)
    Time = 0.0;
  end
  properties
    % Torso Azimuth in world frame
    TorsoAzimuth = 0;
  end
  
  %% Constructor
  methods
    function obj = SimulatorConvexRoom(xmlfile, init)
      % Constructor
      %
      % Parameters:
      %   xmlfile: optional name of xmlfile @type char[] @default ''
      %
      % See also: xml.open xml.validate xml.MetaObject

      obj = obj@simulator.SimulatorInterface();
      obj = obj@simulator.RobotInterface();

      if nargin >= 1, obj.loadConfig(xmlfile); end;
      if nargin >= 2 && init, obj.init(); end;
    end
  end
  %% Initialization
  methods
    function obj = init(obj)
      % function init(obj)
      % initialize Simulator
      obj.bActive = true;

      % initialize Room
      if ~isempty(obj.Room)
        obj.Room.init();
      end      
      
      % define source types
      source_types = {};
      source_irfiles = {};
      obj.NumberOfSSRSources = 0;
      for idx=1:length(obj.Sources)
        if isa(obj.Sources{idx},'simulator.source.ISMGroup')
          obj.Sources{idx}.Room = obj.Room;
        end
        obj.Sources{idx}.init();
        obj.NumberOfSSRSources ...
          = obj.NumberOfSSRSources + obj.Sources{idx}.ssrChannels;
        source_types = [source_types, obj.Sources{idx}.ssrType];
        source_irfiles = [source_irfiles, obj.Sources{idx}.ssrIRFile];
      end

      % initialize SSR compatible arraysHead
      obj.SSRPositionXY = zeros(2, obj.NumberOfSSRSources);
      obj.SSROrientationXY = zeros(1, obj.NumberOfSSRSources);
      obj.SSRReferencePosXY = zeros(2, 1);
      obj.SSRReferenceOriXY = zeros(1, 1);
      obj.SSRMute = false(1, obj.NumberOfSSRSources);
      obj.SSRGain = ones(1, obj.NumberOfSSRSources);
      obj.SSRInput = single(zeros(obj.BlockSize, obj.NumberOfSSRSources));

      % SSR initialization parameters
      params.block_size = obj.BlockSize;
      params.sample_rate = obj.SampleRate;
      % HOTFIX for SSR bug
      if ~isempty(obj.HRIRDataset.Filename)
        params.hrir_file = obj.HRIRDataset.Filename;
      end
      params.threads = obj.NumberOfThreads;
      params.delayline_size = ceil(obj.MaximumDelay*obj.SampleRate);
      params.initial_delay = ceil(obj.PreDelay*obj.SampleRate);

      % initialize SSR
      % TODO: remove workaround by providing newest binaries for Windows/Mac
      if obj.Verbose
        obj.Renderer('init', source_irfiles, params);      
      else
        obj.Renderer('init', source_irfiles, params, obj.Verbose); 
      end
      
      if ~isempty(source_types)
        % TODO: remove this workaround and handle this inside the SSR
        obj.Renderer('source_model', source_types);
      end

      % ensure initial scene to be valid
      obj.reinit();
    end
    %% Processing
    function process(obj)
      % function process(obj)
      % process next audio block
      %
      % process next audio block provided by the audio sources of Sources
      % Output will be written to the Buffer of Sinks

      begin = 1;
      for idx=1:length(obj.Sources)
        if obj.Sources{idx}.ssrChannels == 0
          continue;
        end
        range = begin:(begin-1+obj.Sources{idx}.ssrChannels);

        obj.SSRInput(:,range) = obj.Sources{idx}.ssrData(obj.BlockSize);
        begin = range(end) + 1;
      end

      out = obj.Renderer(...
        'source_position', obj.SSRPositionXY, ...
        'source_orientation', obj.SSROrientationXY, ...
        'source_mute', obj.SSRMute, ...
        'source_gain', obj.SSRGain, ...
        'reference_position', obj.SSRReferencePosXY,...
        'reference_orientation', obj.SSRReferenceOriXY, ...
        'process', obj.SSRInput);

      % add binaural input and remove data for original sources
      for idx=1:length(obj.Sources)
        if isa(obj.Sources{idx},'simulator.source.Binaural') && ...
           ~obj.Sources{idx}.Mute
          out = out + obj.Sources{idx}.getData(obj.BlockSize);
        end
        obj.Sources{idx}.removeData(obj.BlockSize);
      end

      obj.Sinks.appendData(out);  % append Data to Sinks
    end
  %% Refresh
    function refresh(obj)
      % function refresh(obj)
      % refresh positions of all scene objects including image source model

      % incorporate new events from the event queue
      if ~isempty(obj.EventHandler)
        obj.EventHandler.refresh(obj.BlockSize/obj.SampleRate);
      end

      % refresh position of Sinks for limited-speed modifications
      obj.Sinks.refresh(obj);

      % refresh ism and scene objects
      for idx=1:length(obj.Sources)
        obj.Sources{idx}.refresh(obj);
      end

      obj.updateSSRarrays;

      % increase the time
      obj.Time = obj.Time + obj.BlockSize/obj.SampleRate;
    end
  end
  methods (Access = private)
    function updateSSRarrays(obj)
      % refresh SSR compatible arrays
      begin = 1;
      for idx=1:length(obj.Sources)
        if obj.Sources{idx}.ssrChannels == 0
          continue;
        end
        range = begin:(begin-1+obj.Sources{idx}.ssrChannels);

        obj.SSRPositionXY(:, range) = obj.Sources{idx}.ssrPosition();
        obj.SSROrientationXY(:, range) = obj.Sources{idx}.ssrOrientation();
        obj.SSRGain(:, range) = obj.Sources{idx}.ssrGain();
        obj.SSRMute(:, range) = obj.Sources{idx}.ssrMute();

        begin = range(end) + 1;
      end
      obj.SSRReferencePosXY = obj.Sinks.ssrPosition();
      obj.SSRReferenceOriXY = obj.Sinks.ssrOrientation();
    end
  end
  
  methods
    %% isFinished?
    function b = isFinished(obj)
      b = true;
      if obj.Time >= obj.LengthOfSimulation
        return;
      end
      for idx=1:length(obj.Sources)
        if ~obj.Sources{idx}.isEmpty()
          b = false;
          return;
        end
      end
    end
    %% reinitialization
    function reinit(obj)
      % function reinit(obj)
      % re-initialize simulator
      %
      % Somehow a weak form of init, which clears the memory of the
      % convolver and clears the history of object positions, orientations
      % and mutes. However, clearing means that the memory of the convolver
      % is filled with zeros and the history is filled with current
      % properties for each object. Be sure, that you have chosen the right
      % properties BEFORE running reinit.
      %
      % See also: simulator.SimulatorInterface.init

      % init EventHandler
      if ~isempty(obj.EventHandler)
        obj.EventHandler.init();
        % get events which have a timestamp of 0 seconds
        obj.EventHandler.refresh(0);
      end

      % refresh ism and scene objects
      for idx=1:length(obj.Sources)
        obj.Sources{idx}.refresh(obj);
      end

      obj.updateSSRarrays;

      obj.Renderer(...
        'source_position', obj.SSRPositionXY, ...
        'source_orientation', obj.SSROrientationXY, ...
        'source_mute', obj.SSRMute, ...
        'source_gain', obj.SSRGain, ...
        'reference_position', obj.SSRReferencePosXY,...
        'reference_orientation', obj.SSRReferenceOriXY);

      % clear convolver memory by processing some zeros
      obj.clearmemory();

      % reset global time
      obj.Time = 0.0;
    end
    %% Clear Memory
    function clearmemory(obj)
      % function clearmemory(obj)
      % clear memory of renderer
      %
      % obsolete functionality (will be replaced by reinit in mid-term)
      %
      % See also: reinit
      blocks = ceil( (obj.HRIRDataset.NumberOfSamples + ...
        2*obj.MaximumDelay*obj.SampleRate)/obj.BlockSize ...
        );
      input = single(zeros(obj.BlockSize, obj.NumberOfSSRSources));
      for idx=1:blocks
        [~] = obj.Renderer('process', input);
      end
    end
    %% Shut Down
    function shutdown(obj)
      % function shutdown(obj)
      obj.SSRPositionXY = [];
      obj.SSROrientationXY = [];
      obj.SSRReferencePosXY = [];
      obj.SSRReferenceOriXY = [];
      obj.SSRGain = [];
      obj.SSRMute = [];
      obj.SSRInput = [];

      obj.Renderer('clear');
    end
  end

  %% Robot-Interface
  methods
      
      % Returns true if robot is active
      function b = isActive(obj)
          b = false;
          if obj.bActive
              b = ~obj.isFinished;
          end
      end
      
    function [sig, timeIncSec, timeIncSamples] = getSignal(obj, timeIncSec)
      % function [sig, timeIncSec, timeIncSamples] = getSignal(obj, timeIncSec)
      %
      % See also: simulator.RobotInterface.getSignal
      if nargin < 2
        timeIncSec = inf;
      end
      blocks = ceil(timeIncSec*obj.SampleRate/obj.BlockSize);
      
      idx = 0;
      while ~obj.isFinished() && idx < blocks
        obj.refresh();
        obj.process();
        idx = idx + 1;
      end
      
      timeIncSamples = idx*obj.BlockSize;
      timeIncSec = timeIncSamples/obj.SampleRate;
      
      sig = obj.Sinks.getData(timeIncSamples);
      obj.Sinks.removeData(timeIncSamples);
    end
    
    function rotateHead(obj, angleDeg, mode)
      % function rotateHead(obj, angleDeg, mode)
      %
      % See also: simulator.RobotInterface.rotateHead
      
      isargscalar(angleDeg);
      if (nargin < 3)
        mode = 'relative';
      else
        isargchar(mode);
      end
      
      azi = obj.Sinks.OrientationXY;  % get current XY-Orientation
      switch mode
        case 'relative'
          % consider limits of head orientation
          angleDeg = azi + angleDeg;
        case 'absolute'
          % consider limits of head orientation
          angleDeg = obj.TorsoAzimuth + angleDeg;
        otherwise
          error('mode (%s) not supported', mode);
      end
      % rotate Sink around z-axis
      obj.Sinks.rotateAroundAxis([0; 0; 1], angleDeg - azi);
    end
    
    function azimuth = getCurrentHeadOrientation(obj)
      % function azimuth = getCurrentHeadOrientation(obj)
      % get current head orientation in degrees
      %
      % See also: simulator.RobotInterface.getCurrentHeadOrientation
      azimuth = mod(obj.Sinks.OrientationXY - obj.TorsoAzimuth + 180, 360) - 180;
    end
    
    function [maxLeft, maxRight] = getHeadTurnLimits(obj)
      % function [maxLeft, maxRight] = getHeadTurnLimits(obj)
      %
      % See also: simulator.RobotInterface.getHeadTurnLimits
      
      [maxLeft, maxRight] = obj.Sources{1}.getHeadLimits();
    end
    
    function moveRobot(obj, posX, posY, theta, mode)
      % function moveRobot(obj, posX, posY, theta, mode)
      %
      % See also: simulator.RobotInterface.moveRobot
      
      if (nargin < 5)
        mode = 'relative';
      else
        isargchar(mode);
      end
      
      switch mode
        case 'relative'
          % rotate Sink around z-axis
          obj.Sinks.rotateAroundAxis([0; 0; 1], theta)
          % set torso azimuth
          obj.TorsoAzimuth = mod(theta + obj.TorsoAzimuth, 360);
          % set torso position
          obj.Sinks.Position = obj.Sinks.Position + [posX; posY; 0];
        case 'absolute'
          % rotate Sink around z-axis
          obj.Sinks.rotateAroundAxis([0; 0; 1], theta - obj.TorsoAzimuth)
          % set torso azimuth
          obj.TorsoAzimuth = mod(theta, 360);
          % set torso position
          obj.Sinks.Position = [posX; posY; obj.Sinks.Position(3)];
        otherwise
          error('mode (%s) not supported', mode);
      end     
    end
    
    %% Get the current robot position
    function [posX, posY, theta] = getCurrentRobotPosition(obj)
    % function [posX, posY, theta] = getCurrentRobotPosition(obj)
    %
    % See also: simulator.RobotInterface.getCurrentRobotPosition

      theta = obj.TorsoAzimuth;
      posX = obj.Sinks.Position(1);
      posY = obj.Sinks.Position(2);
    end
  end
  %% MISC
  methods
    function plot(obj, id)
      % function plot(obj, id)
      % plot walls, sources, sinks + image sources/sinks
      if nargin < 2
        id = figure;
      else
        figure(id);
      end

      h = [];
      leg = {};
      hold on;
      for idx=1:length(obj.Sources)
        [htmp, legtmp] = obj.Sources{idx}.plot(id);
        h = [h, htmp];
        leg = [leg, legtmp];
      end
      [htmp, legtmp] = obj.Sinks.plot(id);
      h = [h, htmp];
      leg = [leg, legtmp];
      if ~isempty(obj.Room)
        [htmp, legtmp] = obj.Room.plot(id);
        h = [h, htmp];
        leg = [leg, legtmp];
      end
      hold off;
      axis equal;
      legend(h, leg);
    end
  end
end
