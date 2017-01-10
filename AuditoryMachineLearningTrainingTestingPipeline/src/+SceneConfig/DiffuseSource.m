classdef DiffuseSource < SceneConfig.SourceBase & Parameterized

    %% -----------------------------------------------------------------------------------
    properties
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = DiffuseSource( varargin )
            obj = obj@SceneConfig.SourceBase( varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
        function srcInstance = instantiate( obj )
            srcInstance = instantiate@SceneConfig.SourceBase( obj );
        end
        %% -------------------------------------------------------------------------------
        
        function e = isequal( obj1, obj2 )
            e = isequal@SceneConfig.SourceBase( obj1, obj2 );
        end
        %% -------------------------------------------------------------------------------
                
    end
    
end
