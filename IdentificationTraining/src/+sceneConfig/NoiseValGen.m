classdef NoiseValGen < sceneConfig.ValGen

    %%
    methods
        
        function obj = NoiseValGen( val )
            if ~( isfield( val, 'len' ) && isa( val.len, 'sceneConfig.ValGen' ) )
                error( 'val does not provide all needed fields' );
            end
            obj = obj@sceneConfig.ValGen( 'manual', val );
        end
        
        function val = value( obj )
            if obj.instantiated, val = value@sceneConfig.ValGen( obj ); return; end
            len = floor( obj.val.len.value() );
            val = rand( len, 1 ) * 2 - 1;
        end
        
    end
        
end
