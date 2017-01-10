function renameCacheFolders( dstFormatString, varargin )

cDirs = dir( pwd );
cDirs(1:2) = [];
cacheDirs = cell( 0, 2 );
fprintf( '-> read cache folders\n' );
for ii = 1 : numel( cDirs )
    fprintf( '%d/%d ', ii, numel( cDirs ) );
    if exist( [pwd filesep cDirs(ii).name filesep 'cfg.mat'], 'file' )
        cacheDirs{end+1,1} = [pwd filesep cDirs(ii).name];
        cacheDirs{end,2} = load( [cacheDirs{end,1} filesep 'cfg.mat'], 'cfg' );
        cfg = cacheDirs{end,2}.cfg;
        cfgVars = cellfun( @eval, varargin, 'un', false );
        newCDname = sprintf( dstFormatString, cfgVars{:} );
        if exist( [pwd filesep newCDname], 'dir' )
            newCDname = [newCDname buildCurrentTimeString];
        end
        movefile( cacheDirs{end,1}, [pwd filesep newCDname] );
    end
end
fprintf( '\n' );


end
