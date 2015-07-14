classdef (ConstructOnLoad) BlackboardEventData  < event.EventData
    
    properties
      data = 0;
    end
   
    methods
      function obj = BlackboardEventData(data)
            obj.data = data;
      end
    end
   
end

