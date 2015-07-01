classdef AttributeAngular < simulator.dynamic.AttributeBase
  %ATTRIBUTESTATIC Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    Velocity;    
  end
  
  methods
    function obj = AttributeAngular(default, v)
      isargcoord(default);
      if (nargin < 3)
        v = inf;
      else
        isargpositivescalar(v);
      end
      
      % call constructor of base class
      obj = obj@simulator.dynamic.AttributeBase(default);
      
      obj.Velocity = v;
      obj.Dynamic = ~isinf(v);  
      obj.Current = default;
      obj.Target = default;
    end
    function obj = refresh(obj, T)
      if obj.Dynamic
        isargpositivescalar(T);
        
        inc = acosd((obj.Target'*obj.Current)/ ...
          (norm(obj.Target)*norm(obj.Current)));
        
        inc = sign(inc).*min(abs(obj.Velocity)*T,abs(inc));
        
        n = cross(obj.Current, obj.Target);
        
        if (norm(n) > 1e-5) 
          n = n/norm(n);
          
          c = cosd(inc);
          omc = 1 - c;
          s = sind(inc);

          R = ((n*n')*omc) + ...
            [ c     , -n(3)*s,  n(2)*s; ...
              n(3)*s,  c     , -n(1)*s; ...
             -n(2)*s,  n(1)*s,  c     ];          
           
          obj.Current = R*obj.Current;        
          
        elseif (abs(inc + 1) < 1e-5)
          warning('Current and Target antiparallel, dont know how to rotate');
        end        
      end
    end
  end
  %% setter, getter
  methods
    function obj = set.Velocity(obj,v)
      isargpositivescalar(v);
      obj.Dynamic = ~isinf(v);
      obj.Velocity = v;
    end
  end  
end

