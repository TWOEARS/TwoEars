function profileCallAndSave( useWallclockTime, fh, varargin )

if useWallclockTime
    profile on -timer real
else
    profile on -timer cpu
end

cleaner = onCleanup( @() profile( 'off' ) );

fh( varargin{:} );

p = profile('info');
profsave(p,'profile_results');


