classdef Binaural < simulator.source.Base
  % Class for source-objects in audio scene

  methods
    function obj = Binaural()
      % function obj = Binaural()

      obj = obj@simulator.source.Base();
      obj.RequiredChannels = 2;
    end
  end

  %% SSR compatible stuff
  methods
    function v = ssrData(obj, BlockSize)
      v = [];
    end
    function v = ssrPosition(obj)
      v = [];
    end
    function v = ssrOrientation(obj)
      v = [];
    end
    function v = ssrType(obj)
      v = {};
    end
    function v = ssrIRFile(obj)
      v = {};
    end
    function v = ssrChannels(obj)
      v = 0;
    end
  end
end
