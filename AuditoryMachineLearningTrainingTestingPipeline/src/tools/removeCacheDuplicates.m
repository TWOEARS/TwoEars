function removeCacheDuplicates( procName )

classFolders = dir( [pwd filesep '*'] );
classFolders = classFolders([classFolders.isdir]);
classFolders(1:2) = [];

Parameters.dynPropsOnLoad( true, false );
for ii = 1 : length( classFolders )
    procFolders = dir( [pwd filesep classFolders(ii).name filesep procName '.201*.*'] );
    procFolders = procFolders([procFolders.isdir]);
    fprintf('\n');
    cfgDirs = cell( length( procFolders ), 2 );
    for jj = length( procFolders ) : -1 : 1
        curDir = [pwd filesep classFolders(ii).name filesep procFolders(jj).name];
        fprintf( '%s\n', curDir );
        cfgDirs{jj,1} = curDir;
        cfg = load( [curDir filesep 'config.mat'] );
        cfgDirs{jj,2} = cfg;
        for kk = length( procFolders ) : -1 : jj + 1
            curCmpDir = cfgDirs{kk,1};
            fprintf( '.' );
            cmpCfg = cfgDirs{kk,2};
            if isequalDeepCompare( cfg, cmpCfg )
                cfgDirs{jj,1} = [];
                cfgDirs{jj,2} = [];
                movefile( [curDir filesep '*'], curCmpDir, 'f' );
                rmdir( curDir );
                break;
            end
        end
        fprintf( '\n' );
    end
end
Parameters.dynPropsOnLoad( true, true );

delete( [procName '.preloadedConfigs.mat'] );
