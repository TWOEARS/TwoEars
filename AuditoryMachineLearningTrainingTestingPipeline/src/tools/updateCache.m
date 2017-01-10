function updateCache()

classFolders = dir( [pwd filesep '*'] );
classFolders = classFolders([classFolders.isdir]);
classFolders(1:2) = [];

Parameters.dynPropsOnLoad( true, false );
for ii = 1 : length( classFolders )
    procFolders = dir( [pwd filesep classFolders(ii).name filesep '*.201*.*'] );
    procFolders = procFolders([procFolders.isdir]);
    fprintf('\n');
    for jj = 1 : length( procFolders )
        curDir = [pwd filesep classFolders(ii).name filesep procFolders(jj).name];
        fprintf( '%s\n', curDir );
        cfg = load( [curDir filesep 'config.mat'] );
        cfg = recRepHrir( cfg );
        save( [curDir filesep 'config.mat'], '-struct', 'cfg' );
    end
end
Parameters.dynPropsOnLoad( true, true );


    function updCfg = recRepHrir( oldCfg )
        oldHrir = '78cb3abcc363eda96fb529cf00c90b7d';
        newHrir = 'dce36743a00e91c26d5d650ac178b116';
        
        updCfg = oldCfg;
        if isfield( oldCfg, 'hrir' ) && strcmp( oldCfg.hrir, oldHrir )
            updCfg.hrir = newHrir;
        end
        cfgFields = fieldnames( oldCfg );
        remFields = false( size( cfgFields ) );
        for ff = 1 : numel( cfgFields )
            if strcmp( 'extern', cfgFields{ff} ), continue; end
            if strcmp( 'binSimCfg', cfgFields{ff} ), continue; end
            if length( cfgFields{ff} ) > 11  && ...
                    strcmp( 'sceneConfig', cfgFields{ff}(1:11) )
                continue; 
            end
            remFields(ff) = true;
        end
        cfgFields(remFields) = [];
        for ff = 1 : numel( cfgFields )
            updCfg.(cfgFields{ff}) = recRepHrir( oldCfg.(cfgFields{ff}) );
        end
    end

end