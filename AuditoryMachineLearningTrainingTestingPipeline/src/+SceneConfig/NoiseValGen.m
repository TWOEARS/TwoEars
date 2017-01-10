classdef NoiseValGen < SceneConfig.ValGen

    %%
    methods
        
        function obj = NoiseValGen( val )
            if ~( isfield( val, 'len' ) && isa( val.len, 'SceneConfig.ValGen' ) )
                error( 'val does not provide all needed fields' );
            end
            obj = obj@SceneConfig.ValGen( 'manual', val );
        end
        
        function val = value( obj )
            if obj.instantiated, val = value@SceneConfig.ValGen( obj ); return; end
            len = floor( obj.val.len.value() );
            val = rand( len, 1 ) * 2 - 1;
        end
        
    end
        
end
