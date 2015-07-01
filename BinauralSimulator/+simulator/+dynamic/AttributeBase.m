classdef AttributeBase
  %ATTRIBUTEBASE Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    Target;
  end
  properties (SetAccess = protected)
    Current;
    Dimensions;
  end
  properties (Access = protected)
    Dynamic;
  end
  
  methods
    function obj = AttributeBase(default)
      obj.Dimensions = size(default);
      obj.Current = default;
      obj.Target = default;
    end
  end
  
  methods (Abstract)
    refresh(obj,T)
  end
  %% setter, getter
  methods
    function obj = set.Target(obj, v)
      obj.Target = v;
      if ~obj.Dynamic
        obj.Current = v;
      end
    end
  end
end