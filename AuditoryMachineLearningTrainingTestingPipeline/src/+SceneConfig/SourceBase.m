classdef SourceBase < matlab.mixin.Copyable & matlab.mixin.Heterogeneous & Parameterized

    %% -----------------------------------------------------------------------------------
    properties
        data;
        offset;
        normalize;
        normalizeLevel;
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = SourceBase( varargin )
            pds{1} = struct( 'name', 'data', ...
                             'default', SceneConfig.NoiseValGen( ...
                                            struct('len',SceneConfig.ValGen('manual',44100))), ...
                             'valFun', @(x)(isa(x, 'SceneConfig.ValGen')) );
            pds{2} = struct( 'name', 'offset', ...
                             'default', SceneConfig.ValGen('manual',0.5), ...
                             'valFun', @(x)(isa(x, 'SceneConfig.ValGen')) );
            pds{3} = struct( 'name', 'normalize', ...
                             'default', true, ...
                             'valFun', @islogical );
            pds{4} = struct( 'name', 'normalizeLevel', ...
                             'default', 1.0, ...
                             'valFun', @(x)(isnumeric(x) && (x > 0)) );
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
            e = isequal( obj1.data, obj2.data ) && isequal( obj1.offset, obj2.offset ) ...
                && isequal( obj1.normalize, obj2.normalize ) ...
                && isequal( obj1.normalizeLevel, obj2.normalizeLevel );
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
