classdef Shoebox < simulator.room.Base
  %BASE Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    % Length of room in UnitRight direction
    % @type double
    % @default 1
    LengthX = 1;
    % Length of room in UnitFront direction
    % @type double
    % @default 1
    LengthY = 1;
    % Length of room in UnitUp direction
    % @type double
    % @default 1
    LengthZ = 1;
    % 
    % @type char[]
    % @default '2D'
    ReverberationMode = '2D'
    % RT60 after Sabine's formula
    % @type double
    RT60;
    % amount of acoustic pressure which is reflected by the wall
    % @type double
    % @default [1.0 1.0 1.0 1.0 1.0 1.0]
    ReflectionCoeffs = [1.0 1.0 1.0 1.0 1.0 1.0];
  end
    
  properties (Dependent)
    % amount of acoustic energy which is absorbed by the wall
    %
    % @default [0.0 0.0 0.0 0.0 0.0 0.0]
    % @type double
    AbsorptionCoeffs;
  end 
  
  properties (Access = private)
    Q, M  % auxiliary matrices for computing the image source positions faster
    R  % resulting absorption factors for each image source
  end
  
  methods
    function obj = Shoebox()
      obj = obj@simulator.room.Base();
      
      obj.addXMLAttribute('LengthX', 'double');
      obj.addXMLAttribute('LengthY', 'double');
      obj.addXMLAttribute('LengthZ', 'double');
      obj.addXMLAttribute('ReverberationMode', 'char');
      obj.addXMLAttribute('RT60', 'double');      
    end
    
    function init(obj)
      N = ceil(obj.ReverberationMaxOrder/2);
      
      switch obj.ReverberationMode
        case '2D'
          [qq, jj, kk, mx, my, mz] = ...
            ndgrid([0,1], [0,1], 0, -N:N, -N:N, 0);
        case '3D'
          [qq, jj, kk, mx, my, mz] = ...
            ndgrid([0,1], [0,1], [0,1], -N:N, -N:N, -N:N);
      end
      
      select = abs(2*mx - qq) + abs(2*my - jj) + abs(2*mz - kk) <= obj.ReverberationMaxOrder;
      
      obj.Q = 1 - 2 * [qq(select), jj(select), kk(select)]';
      obj.M = 2*[obj.LengthX*mx(select), obj.LengthY*my(select), obj.LengthZ*mz(select)]';
      
      if ~isempty(obj.RT60)        
        V = obj.LengthX*obj.LengthY*obj.LengthZ;
        A = 2*( obj.LengthX*obj.LengthZ + obj.LengthY*obj.LengthZ);
        if strcmp(obj.ReverberationMode, '3D')
          A = A + 2*obj.LengthX*obj.LengthY;
        end
        % Sabine formula for the reverberation time of rectangular rooms
        obj.AbsorptionCoeffs = repmat(24*log(10.0)*V / (343*A*obj.RT60),1,6);
      end
      
      obj.R = prod([ ...
        obj.ReflectionCoeffs(1).^abs(mx(select) - qq(select)), ...
        obj.ReflectionCoeffs(2).^abs(mx(select)), ...
        obj.ReflectionCoeffs(3).^abs(my(select) - jj(select)), ...
        obj.ReflectionCoeffs(4).^abs(my(select)), ...
        obj.ReflectionCoeffs(5).^abs(mz(select) - kk(select)), ...
        obj.ReflectionCoeffs(6).^abs(mz(select))  ...
        ], 2);      
    end
    
    function initSubSources(obj, source)      
      % re-initialize image objects
      source.SubSources = simulator.source.Image.empty();
      for idx=1:obj.NumberOfSubSources()
        source.SubSources(idx) = simulator.source.Image(source);
      end
    end
    
    function refreshSubSources(obj, source)      
      pos = obj.RotationMatrix' * (source.Position - obj.Position);
      
      if any(pos < 0) || any(pos > [obj.LengthX; obj.LengthY; obj.LengthZ])
        for idx=1:obj.NumberOfSubSources
          source.SubSources(idx).Valid = false;
        end
        return;
      end
      
      for idx=1:obj.NumberOfSubSources
        source.SubSources(idx).Valid = true;        
        source.SubSources(idx).Position = obj.Position + obj.RotationMatrix ...
        * ( obj.Q(:,idx).*pos + obj.M(:,idx) );
                
        source.SubSources(idx).Volume = obj.R(idx)* source.Volume;      
      end
    end
    
    function v = NumberOfSubSources(obj)
      n = obj.ReverberationMaxOrder;
      
      switch obj.ReverberationMode
        case '2D'
          v = 1 + 2*n*(n+1);
        case '3D'
          v = 1 + n*(n+1)*(n+2);
        otherwise
          error('unsupported number of walls!');
      end
    end
    
    function [h, leg] = plot(obj, id)
      % function plot(obj, id)
      % draw shoebox room
      %
      % Parameters:
      %  id: figure id @type uint @default 1
      if nargin < 2
        id = figure;
      else
        figure(id);
      end

      % Create Faces
      facs = [1 2 3 4; 5 6 7 8; 3 2 7 6; 1 4 5 8];      
      if strcmp(obj.ReverberationMode, '3D')
        facs = [facs; 2 1 8 7; 4 3 6 5]; 
      end            
      
      % Create Vertices
      x = obj.LengthX*[0 1 1 0 0 1 1 0]';
      y = obj.LengthY*[1 1 1 1 0 0 0 0]';
      z = obj.LengthZ*[0 0 1 1 1 1 0 0]';
       
      % Rotate and Translate Vertices  
      verts = zeros(3,8);
      for i = 1:8
          verts(:,i) = obj.RotationMatrix*[x(i);y(i);z(i)]+obj.Position;
      end
      
      h = patch('Faces',facs,'Vertices',verts','FaceColor','b','FaceAlpha', 0.2);      
      leg = [obj.Name, 'Room'];
    end    
  end
  
  %% setter/getter
  methods
    function set.RT60(obj, v)
      isargpositivescalar(v);
      obj.RT60 = v;
    end
    function set.ReflectionCoeffs(obj, v)
      isargvector(v);        
      if any(abs(v) > 1)
        error('ReflectionCoeffs must be between -1 and +1');
      end
      obj.ReflectionCoeffs = v;
    end
    function v = get.AbsorptionCoeffs(obj)
      v = 1 - obj.ReflectionCoeffs.^2;
    end
    function set.AbsorptionCoeffs(obj, v)
      isargvector(v);
      if any(v > 1 | v < 0)
        error('AbsorptionCoeffs must be smaller equal 1 and greater zero');
      end
      obj.ReflectionCoeffs = - sqrt(1 - v);
    end
  end 
end