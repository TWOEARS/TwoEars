classdef PropertyDescription
  % class which connects MATLAB object property with XML-descriptions for 
  % XML-parsing and auto-configuration.
  %
  % See also: xml.MetaObject xmlread
  
  properties (SetAccess=private)
    % name of xml-attribute
    % @type char[]
    Alias;
    % name of object properties
    % @type char[]
    Name;
    % name of property class
    % @type char[]
    Class;
    % constructor function
    % @type function_handle
    Constructor;
  end
  
  methods
    function obj = PropertyDescription(Name, Class, Alias, Constructor)
      % function obj = PropertyDescription(Name, Class, Alias, Constructor)
      % constructor
      %
      % Parameters:
      %   Name: name of object properties @type char[]
      %   Class: name of property class @type char[]
      %   Alias: name of xml-attribute @type char[]
      %   Constructor: constructor function @type function_handle
      obj.Name = Name;
      obj.Alias = Alias;
      obj.Class = Class;
      obj.Constructor = Constructor;
    end
  end
end
