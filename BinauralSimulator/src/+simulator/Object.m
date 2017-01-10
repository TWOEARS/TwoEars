classdef Object < simulator.vision.Meta & xml.MetaObject
  % Base class for scene-objects
  % Some MetaData
  properties
    % unique identifier for this objects
    % @type char[]
    Name;
    % some labels (TODO: define possible labels)
    % @type char{}
    Labels;
  end

  % Geometry
  properties (SetObservable, AbortSet)
    % view-up vector
    % @type double[]
    % @default [0; 0; 1]
    UnitZ = [0; 0; 1];
  end
  properties (Dependent)
    % 3D-Position
    % @type double[]
    % @default [0; 0; 0]
    Position;
    % front vector
    % @type double[]
    % @default [1; 0; 0]
    UnitX;

    % radius (spherical coordinates) of Position in meter
    % @type double
    % @default 0
    Radius;
    % azimuth angle (spherical coordinates) of Position in degree
    % @type double
    % @default 0
    Azimuth;
    % polar angle (spherical coordinates) of Position in degree
    % @type double
    % @default 0
    Polar;
  end
  properties (Dependent, SetAccess=private)
    % vector resulting of UnitZ x UnitX 
    % @type double[]
    % @default [0; 1; 0]
    UnitY;
    % xy-coordinates of Position
    % @type double[]
    % @default [0; 0]
    PositionXY;
    % azimuth of UnitX in degree
    % @type double
    % @default 0
    OrientationXY;
    % RotationMatrix resulting of [obj.UnitZ, obj.UnitY, obj.UnitX]
    % @type double[][]
    % @default eye(3)
    RotationMatrix;
  end

  % Dynamic Stuff
  properties (SetAccess = private)
    PositionDynamic = simulator.dynamic.AttributeLinear([0; 0; 0]);
    UnitXDynamic = simulator.dynamic.AttributeAngular([1; 0; 0]);
  end

  % Hierarchical Stuff
  properties
    % Parent Object used for grouping Objects
    % @type simulator.Object
    % using the Grouping Object will lead to the following behaviour:
    % setting Object.Position or Object.Unit... will define the parameters
    % inside the coordinates system of the GroupObject:
    %
    % Object.Positon := Object.GroupObject.RotationMatrix
    %   *(Object.Position - Object.GroupObject.Position)
    %
    % Object.Unit... := Object.GroupObject.RotationMatrix*Object.Unit...
    GroupObject;
  end
  properties (Dependent, Access=private)
    GroupTranslation;
    GroupRotation;
  end

  %% Constructor
  methods
    function obj = Object()
      obj = obj@simulator.vision.Meta();
      obj.addXMLAttribute('UnitX', 'double');
      obj.addXMLAttribute('UnitZ', 'double');
      obj.addXMLAttribute('Position', 'double');
      obj.addXMLAttribute('Radius', 'double');
      obj.addXMLAttribute('Name', 'char');
      obj.addXMLAttribute('Labels', 'cell');
    end
  end

  methods
    %% Rotation
    function rotateAroundX(obj, alpha)
      % rotate object around its UnitX vector
      %
      % Parameters:
      %   alpha:  rotation angle in degree @type double
      obj.rotateAroundAxis(obj.UnitX, alpha);
    end
    function rotateAroundY(obj, alpha)
      % rotate object around its UnitY vector
      %
      % Parameters:
      %   alpha:  rotation angle in degree @type double
      obj.rotateAroundAxis(obj.UnitY, alpha);
    end
    function rotateAroundZ(obj, alpha)
      % rotate object around its UnitZ vector
      %
      % Parameters:
      %   alpha:  rotation angle in degree @type double
      obj.rotateAroundAxis(obj.UnitZ, alpha);
    end
    function rotateAroundAxis(obj, n, alpha)
      % function rotateAroundAxis(obj, n, alpha)
      % rotate object around unit vector
      %
      % Parameters:
      %   n: unit vector defining the rotation axis @type double[]
      %   alpha:  rotation angle in degree @type double
      isargcoord(n);
      isargunitvector(n);
      isargscalar(alpha);

      c = cosd(alpha);
      omc = 1 - c;
      s = sind(alpha);

      R = ((n*n')*omc) + ...
        [ c     , -n(3)*s,  n(2)*s; ...
        n(3)*s,  c     , -n(1)*s; ...
        -n(2)*s,  n(1)*s,  c     ];

      obj.UnitX = R*obj.UnitX;
      obj.UnitZ = R*obj.UnitZ;
    end
  end
  %% dynamic stuff
  methods
    function init(obj)
      % initialize scene object
      %
      % By default, this function does nothing. It can be overloaded in sub-
      % classes in order to implement custom initialization functionality.
    end
    function refresh(obj, sim)
      % refresh properties with finite-speed modification
      %
      % Parameters:
      %   sim: simulator object @type double
      %
      % Properties with finite-speed modification speed will change over time to
      % its target value. This functions refreshes this properties to a new
      % timestamp which has a difference to the old timestamp of T
      %
      % See also: simulator.dynamic.AttributeLinear
      if nargin < 2
        return;
      end
      T = sim.BlockSize/sim.SampleRate;
      obj.PositionDynamic = obj.PositionDynamic.refresh(T);
      obj.UnitXDynamic = obj.UnitXDynamic.refresh(T);
    end
    % extended setter, getter for dynamic extension
    function setDynamic(obj, name, prop, value)
      % set settings of certain property for finite-speed modification
      %
      % Parameters:
      %   name: name of the property @type char[]
      %   prop: name of the limited speed parameter @type char[]
      %   value: value for the limited speed parameter
      %
      % supported properties (name)
      % - Position
      % - UnitX
      %
      % supported limited speed parameters (prop)
      % - Velocity
      %
      % See also: simulator.dynamic.AttributeLinear
      isargchar(prop, name);
      if (~isprop(obj,name))
        error('unknown property: %s', name);
      end
      if (~isprop(obj,[name,'Dynamic']))
        error('%s is a not dynamic property', name);
      end
      obj.([name,'Dynamic']).(prop) = value;
    end
    function v = getDynamic(obj, name, prop)
      % set settings of certain property for limited speed motion
      %
      % Parameters:
      %   name: name of the property @type char[]
      %   prop: name of the dynamic property @type char[]
      %
      % Return Values:
      %   v: value for the limited speed parameter
      %
      % See also: setDynamic simulator.dynamic.AttributeLinear
      isargchar(prop, name);
      if (~isprop(obj,name))
        error('unknown property: %s', name);
      end
      if (~isprop(obj,[name,'Dynamic']))
        error('%s is a not dynamic property', name);
      end
      v = obj.([name,'Dynamic']).(prop);
    end
  end

  %% SSR compatible stuff
  methods
    function v = ssrPosition(obj)
      v = obj.PositionXY;
    end
    function v = ssrOrientation(obj)
      v = obj.OrientationXY;
    end
  end

  %% MISC
  methods (Access=protected)
    function errormsg(obj, msg)
      isargchar(msg);
      error(['Scene Object: ', obj.Name, ' | Error: ', msg]);
    end
    function warnmsg(obj, msg)
      isargchar(msg);
      warning(['Scene Object: ', obj.Name, ' | Warning: ', msg]);
    end
  end

  methods
    function [h, leg] = plot(obj, figureid)
      if nargin < 2
        figure;
      else
        figure(figureid);
      end
      % Draw Position
      pos = obj.Position;
      h = plot3(pos(1), pos(2), pos(3),'k.');      
      leg = {[obj.Name, ' (', class(obj), ')']};
      % Draw Orientation
      ori = 0.25*obj.UnitX;
      quiver3(pos(1), pos(2), pos(3), ori(1), ori(2), ori(3));
    end
  end

  %% setter, getter
  methods
    %
    function set.Position(obj,v)
      isargcoord(v);
      obj.PositionDynamic.Target = v;
    end
    function v = get.Position(obj)
      v = obj.PositionDynamic.Current;
      v = obj.GroupRotation*v + obj.GroupTranslation;
    end
    %
    function set.UnitZ(obj,v)
      isargcoord(v);
      try
        isargunitvector(v);
      catch
        warning('re-normalization of non-unit vector');
        v = v./norm(v,2);
      end
      obj.UnitZ = v;
    end
    %
    function set.UnitX(obj,v)
      isargcoord(v);
      try
        isargunitvector(v);
      catch
        warning('re-normalization of non-unit vector');
        v = v./norm(v,2);
      end
      obj.UnitXDynamic.Target = v;
    end
    function v = get.UnitX(obj)
      v = obj.UnitXDynamic.Current;
      v = obj.GroupRotation*v;
    end
    %
    function v = get.UnitY(obj)
      v = cross(obj.UnitZ, obj.UnitX);
    end
    %
    function v = get.UnitZ(obj)
      v = obj.GroupRotation*obj.UnitZ;
    end
    %
    function v = get.PositionXY(obj)
      v = obj.Position(1:2,:);
    end
    %
    function v = get.Radius(obj)
      x = obj.Position;
      v = sqrt(sum(x.^2,1));
    end
    function set.Radius(obj, r)
      isargscalar(r);
      phi = obj.Azimuth;
      theta = obj.Polar;
      obj.Position = r.*[cosd(phi).*sind(theta); ...
        sind(phi).*sind(theta); ...
        cosd(theta)];
    end
    %
    function v = get.Azimuth(obj)
      v = atan2d(obj.Position(2,:), obj.Position(1,:));
    end
    function set.Azimuth(obj, v)
      isargscalar(v);
      x = obj.Position;
      r = sqrt(x(2).^2 + x(1).^2);
      obj.Position = [r.*cosd(v); r.*sind(v); x(3)];
    end
    %
    function v = get.Polar(obj)
      v = acosd(obj.Position(3,:));
    end
    function set.Polar(obj, theta)
      isargscalar(theta);
      phi = obj.Azimuth;
      r = obj.Radius;
      obj.Position = r.*[cosd(phi).*sind(theta); ...
        sind(phi).*sind(theta); ...
        cosd(theta)];
    end
    %
    function v = get.OrientationXY(obj)
      v = atan2d(obj.UnitX(2,:), obj.UnitX(1,:));
    end
    %
    function v = get.RotationMatrix(obj)
      v = [obj.UnitX, obj.UnitY, obj.UnitZ];
    end

    %
    function set.GroupObject(obj, v)
      isargclass('simulator.Object', v);
      if (~isempty(v))
        isargequalsize(1,v);
      end
      obj.GroupObject = v;
    end
    function v = get.GroupRotation(obj)
      if isempty(obj.GroupObject)
        v = eye(3);
      else
        v = obj.GroupObject.RotationMatrix;
      end
    end
    function v = get.GroupTranslation(obj)
      if isempty(obj.GroupObject)
        v = [0; 0; 0];
      else
        v = obj.GroupObject.Position;
      end
    end
  end
end
