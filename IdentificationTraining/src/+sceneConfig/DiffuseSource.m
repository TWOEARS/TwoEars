classdef DiffuseSource < sceneConfig.SourceBase & Parameterized

    %% -----------------------------------------------------------------------------------
    properties
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = DiffuseSource( varargin )
            obj = obj@sceneConfig.SourceBase( varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
        function srcInstance = instantiate( obj )
            srcInstance = instantiate@sceneConfig.SourceBase( obj );
        end
        %% -------------------------------------------------------------------------------
        
        function e = isequal( obj1, obj2 )
            e = isequal@sceneConfig.SourceBase( obj1, obj2 );
        end
        %% -------------------------------------------------------------------------------
                
    end
    
end
