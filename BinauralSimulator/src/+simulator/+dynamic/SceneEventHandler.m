classdef SceneEventHandler < xml.MetaObject
  % class for events for changing parameters
  
  properties
    % reference to unique identifier of target object
    % @type cell
    SceneObjects;
    % simulator object
    % @type simulator.SimulatorInterface
    Simulator;
    % event queue
    % @type simulator.dynamic.SceneEvent
    Events;
  end
  
  properties (SetAccess=private)
    Time = 0;
  end
  
  %% Constructor
  methods
    function obj = SceneEventHandler(sim)
      obj.Simulator = sim;
      obj.SceneObjects = {};
      obj.SceneObjects = [obj.SceneObjects, sim.Sources];
      obj.SceneObjects = [obj.SceneObjects, num2cell(sim.Sinks)];
      obj.SceneObjects = [obj.SceneObjects, num2cell(sim.Walls)];
      
      obj.addXMLElement('Events', 'simulator.dynamic.SceneEvent', 'event');
    end
  end
  
  %% Simulation
  methods
    function init(obj)
      % sort events
      [~, idx] = sort([obj.Events.Start],'ascend');
      obj.Events = obj.Events(idx);
      
      % index events in order to match to the names of the scene objects.
      % This is necessary in order to speed-up the refresh while simulating.
      for idx=1:length(obj.SceneObjects)
        krange = find(...
          strcmp(obj.SceneObjects{idx}.Name, {obj.Events.Name})...
          );
        for kdx=krange
          obj.Events(kdx).Index = idx;
          % find Constructor of target Attribute
          wdx = find(...
            strcmp(obj.Events(kdx).Attribute, {obj.SceneObjects{idx}.XMLAttributes.Name})...
            );
          obj.Events(kdx).Constructor ...
            = obj.SceneObjects{idx}.XMLAttributes(wdx).Constructor;
        end
      end
      
      % set the time to zero
      obj.Time = 0;
    end
    function refresh(obj, timeinc)
      obj.Time = obj.Time + timeinc;
      while ~isempty(obj.Events) && obj.Events(1).Start <= obj.Time
        event = obj.Events(1);
        % manipulate attribute of target scene object
        obj.SceneObjects{event.Index}.(event.Attribute) ...
          = event.Constructor(event.Value);
        % delete past event
        obj.Events(1) = [];
        delete(event);
      end
    end
  end
  
  %% getter, setter
  methods
    function set.Simulator(obj, v)
      isargclass('simulator.SimulatorInterface',v);
      obj.Simulator = v;
    end
    function set.Events(obj, v)
      isargclass('simulator.dynamic.SceneEvent',v);
      obj.Events = v;
    end
  end
end
