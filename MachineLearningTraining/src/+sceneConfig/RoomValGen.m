classdef RoomValGen < sceneConfig.ValGen

    %%
    methods
        
        function obj = RoomValGen( val )
            if ~( ...
                    isfield( val, 'lengthX' ) && isa( val.lengthX, 'sceneConfig.ValGen' ) && ...
                    isfield( val, 'lengthY' ) && isa( val.lengthY, 'sceneConfig.ValGen' ) && ...
                    isfield( val, 'height' ) && isa( val.height, 'sceneConfig.ValGen' ) && ...
                    isfield( val, 'rt60' ) && isa( val.rt60, 'sceneConfig.ValGen' ) )
                error( 'val does not provide all needed fields' );
            end
            obj = obj@sceneConfig.ValGen( 'manual', val );
        end
        
        function val = value( obj )
            if obj.instantiated, val = value@sceneConfig.ValGen( obj ); return; end
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
