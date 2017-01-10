classdef RoomValGen < SceneConfig.ValGen

    %%
    methods
        
        function obj = RoomValGen( val )
            if ~( ...
                    isfield( val, 'lengthX' ) && isa( val.lengthX, 'SceneConfig.ValGen' ) && ...
                    isfield( val, 'lengthY' ) && isa( val.lengthY, 'SceneConfig.ValGen' ) && ...
                    isfield( val, 'height' ) && isa( val.height, 'SceneConfig.ValGen' ) && ...
                    isfield( val, 'rt60' ) && isa( val.rt60, 'SceneConfig.ValGen' ) )
                error( 'val does not provide all needed fields' );
            end
            obj = obj@SceneConfig.ValGen( 'manual', val );
        end
        
        function val = value( obj )
            if obj.instantiated, val = value@SceneConfig.ValGen( obj ); return; end
            room = simulator.room.Shoebox();
            room.set( 'ReverberationMaxOrder', 5 ); 
            room.set( 'UnitZ', [0; 0; 1] );
            room.set( 'UnitX', [1; 0; 0] );
            room.set( 'LengthX', obj.val.lengthX.value() );
            room.set( 'LengthY', obj.val.lengthY.value() );
            room.set( 'LengthZ', obj.val.height.value() );
            room.set( 'Position', [-3; -3; 0] );
            room.set( 'RT60', obj.val.rt60.value() );
            val = room;
        end
        
        % TODO: rt60? reflection coeffs? absorb coeffs? Position?
    end
        
end
