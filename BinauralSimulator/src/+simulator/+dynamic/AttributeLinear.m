classdef AttributeLinear < simulator.dynamic.AttributeBase
  %ATTRIBUTESTATIC Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    Velocity;
  end
  
  methods
    function obj = AttributeLinear(default, v)
      % call constructor of base class
      obj = obj@simulator.dynamic.AttributeBase(default);
      
      if (nargin < 3)
        v = inf(obj.Dimensions);
      else
        isargequalsize(default, v);
      end
      
      obj.Velocity = v;
      obj.Dynamic = any(~isinf(v));  
      obj.Current = default;
      obj.Target = default;
    end
    function obj = refresh(obj, T)
      if obj.Dynamic
        isargpositivescalar(T);
        delta = obj.Target - obj.Current;
        inc = sign(delta).*min(abs(obj.Velocity)*T,abs(delta));
        obj.Current = obj.Current + inc;
      end
    end
  end
  %% setter, getter
  methods
    function obj = set.Velocity(obj,v) 
      obj.Dynamic = any(~isinf(v(:)));
      obj.Velocity = v;
    end
  end  
end

