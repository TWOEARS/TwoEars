classdef (Abstract) Base < simulator.Object
  %BASE Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    % order of image source model (number of subsequent reflections)
    % @type integer
    % @default 0
    ReverberationMaxOrder = 0;
  end
  
  methods
    function obj = Base()
      obj.addXMLAttribute('ReverberationMaxOrder', 'double');
      obj.addXMLAttribute('ReflectionCoeffs', 'double');
      obj.addXMLAttribute('AbsorptionCoeffs', 'double');
    end
  end
  
  methods (Abstract)
    init(obj)
    v = NumberOfSubSources(obj)
    refreshSubSources(obj, source)
    initSubSources(obj, source)
  end
  
  %% setter/getter
  methods
    function set.ReverberationMaxOrder(obj, ReverberationMaxOrder)
      isargpositivescalar(ReverberationMaxOrder);  % check if positive scalar
      obj.ReverberationMaxOrder = ReverberationMaxOrder;
    end
  end
end