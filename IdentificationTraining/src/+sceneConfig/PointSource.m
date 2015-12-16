classdef PointSource < sceneConfig.SourceBase & Parameterized

    %% -----------------------------------------------------------------------------------
    properties
        azimuth;
        distance;
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = PointSource( varargin )
            pds{1} = struct( 'name', 'azimuth', ...
                             'default', sceneConfig.ValGen( 'manual', 0 ), ...
                             'valFun', @(x)(isa(x, 'sceneConfig.ValGen')) );
            pds{2} = struct( 'name', 'distance', ...
                             'default', sceneConfig.ValGen( 'manual', 3 ), ...
                             'valFun', @(x)(isa(x, 'sceneConfig.ValGen')) );
            obj = obj@Parameterized( pds );
            obj = obj@sceneConfig.SourceBase( varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
        function srcInstance = instantiate( obj )
            srcInstance = instantiate@sceneConfig.SourceBase( obj );
            srcInstance.azimuth = obj.azimuth.instantiate();
            srcInstance.distance = obj.distance.instantiate();
        end
        %% -------------------------------------------------------------------------------
        
        function e = isequal( obj1, obj2 )
            e = isequal@sceneConfig.SourceBase( obj1, obj2 ) && ...
                isequal( obj1.distance, obj2.distance ) && ...
                isequal( obj1.azimuth, obj2.azimuth );
        end
        %% -------------------------------------------------------------------------------
                
    end
    
end
