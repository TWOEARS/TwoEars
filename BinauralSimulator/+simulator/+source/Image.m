classdef Image < simulator.source.Point
  % Class for mirror source objects used for the mirror image model

  properties
    % flag indicating if the image source is valid by means of the mirror image
    % model
    % @default true
    % @type logical
    Valid = true;
  end
  
  methods
    function obj = Image(OriginalSource)
      if nargin < 1
        OriginalSource = [];
      else
        isargclass('simulator.source.ISMGroup', OriginalSource);
      end
      obj = obj@simulator.source.Point();
      obj.AudioBuffer = simulator.buffer.PassThrough(1, OriginalSource.AudioBuffer);
    end
  end
end
