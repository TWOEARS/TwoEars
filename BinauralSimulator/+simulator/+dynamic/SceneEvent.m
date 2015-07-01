classdef SceneEvent < xml.MetaObject
  % class for events for changing parameters
  
  properties
    % reference to unique identifier of target object
    % @type char[]
    Name;
    Index;
    % reference to attribute of target object
    % @type char[]
    Attribute;
    Constructor;
    % target value of attribute
    % @type char[]
    Value;
    % start of event in seconds
    % @type double
    Start;
    % end of event in seconds
    % @type double
    End;
  end  
  
  %% Constructor
  methods
    function obj = SceneEvent()
      obj.addXMLAttribute('Name', 'char');
      obj.addXMLAttribute('Attribute', 'char');
      obj.addXMLAttribute('Value', 'char');
      obj.addXMLAttribute('Start', 'double');
      obj.addXMLAttribute('End', 'double');
    end
  end
  %% getter, setter
  methods
    function set.Name(obj, v)
      isargclass('char',v);
      obj.Name = v;
    end
    function set.Index(obj, v)
      isargclass('double',v);
      obj.Index = v;
    end
    function set.Attribute(obj, v)
      isargclass('char',v);
      obj.Attribute = v;
    end
    function set.Value(obj, v)
      isargclass('char',v);
      obj.Value = v;
    end
    function set.Start(obj, v)
      isargclass('double',v);
      obj.Start = v;
    end
    function set.End(obj, v)
      isargclass('double',v);
      obj.End = v;
    end
  end  
end
