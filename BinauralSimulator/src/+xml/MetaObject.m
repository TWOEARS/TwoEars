classdef (Abstract) MetaObject < hgsetget
  % MetaObject implements the parsing funtionality to configure MATLAB-Objects
  % with XML-DOM-Nodes.
  %
  % http://www.mathworks.de/de/help/matlab/ref/xmlread.html

  properties (SetAccess=protected, Hidden=true)
    % array of parseable xml-attributes
    % @type xml.PropertyDescription
    XMLAttributes;

    % array of parseable xml-elements
    % @type xml.PropertyDescription
    XMLElements;
  end

  methods
    function loadConfig(obj, xmlfile)
      % load XML-Config
      %
      % Parameters:
      %   xmlfile: name of xmlfile @type char[]
      %
      % See also: xml.open xml.validate xml.MetaObject.XML
      theNode = xml.open(xmlfile);
      obj.XML(theNode);
    end
    function XML(obj, xmlnode)
      % function XML(obj, xmlnode)
      % configure object with the information from a XML-DOM-Node
      %
      % Parameters:
      %   xmlnode: XML-DOM-Node extracted from xmlread
      %
      % executes the methods
      %  -# configureXMLAttributes()
      %  -# configureXMLSpecific()
      %  -# configureXMLElements()
      %
      % See also: xmlread
      obj.configureXMLAttributes(xmlnode);
      obj.configureXMLSpecific(xmlnode);
      obj.configureXMLElements(xmlnode);
    end
  end

  methods (Access=protected)
    function configureXMLAttributes(obj, xmlnode)
      % function configureXMLAttributes(obj, xmlnode)
      % configure XMLAttributes from XML-DOM-Node
      %
      % Parameters:
      %   xmlnode: XML-DOM-Node extracted from xmlread
      %
      % parses xmlnode with respect to the properties provided in
      % XMLAttributes
      for kdx = 1:length(obj.XMLAttributes)
        value = char(xmlnode.getAttribute(obj.XMLAttributes(kdx).Alias));

        if ~isempty(value)
          obj.(obj.XMLAttributes(kdx).Name) ...
            = obj.XMLAttributes(kdx).Constructor(value);
        end
      end
    end
    function configureXMLElements(obj, xmlnode)
      % function configureXMLElements(obj, xmlnode)
      % configure XMLElements from XML-DOM-Node
      %
      % Parameters:
      %   xmlnode: XML-DOM-Node extracted from xmlread
      %
      % parses xmlnode with respect to the properties provided in
      % XMLElements and executes XML Parsing on child nodes of xmlnode
      for kdx = 1:length(obj.XMLElements)
        eleList = xmlnode.getElementsByTagName(obj.XMLElements(kdx).Alias);
        eleNum = eleList.getLength;

        if eleNum > 0
          tmpElem = [];
          for idx=1:eleNum;
            ele = eleList.item(idx-1);
            tmpElem = [tmpElem, ...
              obj.XMLElements(kdx).Constructor()];
            tmpElem(idx).XML(ele);
          end
          obj.(obj.XMLElements(kdx).Name) = tmpElem;
        end
      end
    end

    function configureXMLSpecific(obj, xmlnode)
      % function configureXMLSpecific(obj, xmlnode)
      % class specific configuration of object from XML-DOM-Node
      %
      % Parameters:
      %   xmlnode: XML-DOM-Node extracted from xmlread
      %
      % this function can be used to implement class specific parsing
      % functionality.
    end
    function addXMLAttribute(obj, Name, Class, Alias, Constructor)
      % function addXMLAttribute(obj, Name, Class, Alias, Constructor)
      % connects XML attribute to object properties
      %
      % Parameters:
      %   Name: name of object properties @type char[]
      %   Class: name of property class @type char[]
      %   Alias: name of xml-attribute @type char[] @default Name
      %   Constructor: constructor function @type function_handle
      %
      % If Constructor is undefined the function tries to find a suitable
      % constructor function for the specified Class. In most cases, this
      % will be the constructor with one input parameter.
      %
      % See also: xmlread addXMLElement configureXMLAttributes
      if nargin < 4
        Alias = Name;
      end
      if nargin < 5
        switch Class
          case 'char'
            Constructor = @(x)char(x);
          case 'dbfile'
            Constructor = @(x)db.getFile(x);
          case 'cell'
            Constructor = @(x)strsplit(x, ' ');
          case 'logical'
            Constructor = @(x)str2num(x);
          case 'double'
            Constructor = @(x)str2num(x).';
          case 'function_handle'
            Constructor = @(x)str2func(char(x));
          otherwise
            Constructor = str2func(['@(x)' Class '(x)']);
        end
      end
      obj.XMLAttributes = [obj.XMLAttributes, ...
        xml.PropertyDescription(Name, Class, Alias, Constructor)];
    end
    function addXMLElement(obj, Name, Class, Alias, Constructor)
      % function addXMLElement(obj, Name, Class, Alias, Constructor)
      % connects XML element to object properties
      %
      % Parameters:
      %   Name: name of object properties @type char[]
      %   Class: name of property class @type char[]
      %   Alias: name of xml-element @type char[] @default Name
      %   Constructor: constructor function @type function_handle
      %
      % If Constructor is undefined the function tries to find a suitable
      % constructor function for the specified Class. In most cases, this
      % will be the constructor with one input parameter.
      %
      % See also: xmlread addXMLAttribute configureXMLElement
      if nargin < 4
        Alias = Name;
      end
      if nargin < 5
        Constructor = str2func(['@()' Class]);
      end
      obj.XMLElements = [obj.XMLElements, ...
        xml.PropertyDescription(Name, Class, Alias, Constructor)];
    end
  end

  %% getter, setter
  methods
    function set.XMLElements(obj, v)
      isargclass('xml.PropertyDescription',v);
      obj.XMLElements = v;
    end
    function set.XMLAttributes(obj, v)
      isargclass('xml.PropertyDescription',v);
      obj.XMLAttributes = v;
    end
  end
end
