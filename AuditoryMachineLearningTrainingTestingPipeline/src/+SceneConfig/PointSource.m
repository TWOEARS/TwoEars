classdef PointSource < SceneConfig.SourceBase & Parameterized

    %% -----------------------------------------------------------------------------------
    properties
        azimuth;
        distance;
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = PointSource( varargin )
            pds{1} = struct( 'name', 'azimuth', ...
                             'default', SceneConfig.ValGen( 'manual', 0 ), ...
                             'valFun', @(x)(isa(x, 'SceneConfig.ValGen')) );
            pds{2} = struct( 'name', 'distance', ...
                             'default', SceneConfig.ValGen( 'manual', 3 ), ...
                             'valFun', @(x)(isa(x, 'SceneConfig.ValGen')) );
            obj = obj@Parameterized( pds );
            obj = obj@SceneConfig.SourceBase( varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
        function srcInstance = instantiate( obj )
            srcInstance = instantiate@SceneConfig.SourceBase( obj );
            srcInstance.azimuth = obj.azimuth.instantiate();
            srcInstance.distance = obj.distance.instantiate();
        end
        %% -------------------------------------------------------------------------------
        
        function e = isequal( obj1, obj2 )
            e = isequal@SceneConfig.SourceBase( obj1, obj2 ) && ...
                isequal( obj1.distance, obj2.distance ) && ...
                isequal( obj1.azimuth, obj2.azimuth );
        end
        %% -------------------------------------------------------------------------------
                
    end
    
end
