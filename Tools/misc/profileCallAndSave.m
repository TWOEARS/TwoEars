function profileCallAndSave( useWallclockTime, memprof, fh, varargin )

if useWallclockTime && memprof
    profile on -memory -timer real
elseif useWallclockTime
    profile on -timer real
elseif memprof
    profile on -memory
else
    profile on -timer cpu
end

cleaner = onCleanup( @offAndSave );

fh( varargin{:} );

end


function offAndSave()

fprintf( '\n\nsaving profile\n\n' );
profile( 'off' );
p = profile('info');

save( ['profile_results' buildCurrentTimeString() '.mat'], 'p' );

end