classdef (Abstract) Meta < xml.MetaObject
  % MetaObject implements the funtionalities necessary for visual simulation
  properties
    % directory which contains files for the visual representation
    %
    % See also: MeshFile
    %
    % @type char[]
    RootPath;
    % name of mesh file used for graphical processing
    % @type char[]
    %
    % See also: RootPath
    MeshFile;
  end
  methods
    function obj = Meta()
      obj.addXMLAttribute('RootPath', 'char');
      obj.addXMLAttribute('MeshFile', 'char');
    end
  end
end
