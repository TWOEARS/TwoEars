classdef SourceBase < matlab.mixin.Copyable & matlab.mixin.Heterogeneous & Parameterized

    %% -----------------------------------------------------------------------------------
    properties
        data;
        offset;
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = SourceBase( varargin )
            pds{1} = struct( 'name', 'data', ...
                             'default', sceneConfig.NoiseValGen( ...
                                            struct('len',sceneConfig.ValGen('manual',44100))), ...
                             'valFun', @(x)(isa(x, 'sceneConfig.ValGen')) );
            pds{2} = struct( 'name', 'offset', ...
                             'default', sceneConfig.ValGen('manual',0.5), ...
                             'valFun', @(x)(isa(x, 'sceneConfig.ValGen')) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
        function srcInstance = instantiate( obj )
            srcInstance = copy( obj );
            srcInstance.data = obj.data.instantiate();
            srcInstance.offset = obj.offset.instantiate();
        end
        %% -------------------------------------------------------------------------------
        
        function e = isequal( obj1, obj2 )
            e = isequal( obj1.data, obj2.data ) && isequal( obj1.offset, obj2.offset );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
        function e = isequalHetrgn( obj1, obj2 )
            e = zeros( size( obj2 ) );
            if numel( obj1 ) > 1
                error( 'SourceBase.isequalHetrgn expects a single object as first argument.' );
            end
            for ii = 1 : numel( obj2 )
                if strcmp( class( obj1 ), class( obj2(ii) ) ) && isequal( obj1, obj2(ii) )
                    e(ii) = 1; 
                end
            end
            e = logical( e );
        end
        %% -------------------------------------------------------------------------------
                
    end
    
end
