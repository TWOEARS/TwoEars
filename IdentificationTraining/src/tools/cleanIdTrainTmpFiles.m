function cleanIdTrainTmpFiles( )

fprintf( ['\nCleaning Training Pipeline Temporary Files Tool\n' ...
          '===============================================\n'] );

while true
    currentDir = pwd;
    fprintf( '\nWe''re in %s.\n\n', currentDir );
    fprintf( 'Looking for tmp proc folders...\nFound:\n' );
    
    classFoldersDir = dir( [currentDir filesep '*'] );
    classFoldersDir(1:2) = []; % "." and ".."
    classFoldersDir([classFoldersDir.isdir] == 0) = [];
    procFoldersDir = [];
    for jj = 1 : length( classFoldersDir )
        classProcFoldersDir = dir( [currentDir filesep classFoldersDir(jj).name filesep '*.*'] );
        classProcFoldersDir(1:2) = []; % "." and ".."
        classProcFoldersDir([classProcFoldersDir.isdir] == 0) = [];
        [classProcFoldersDir(:).class] = deal( classFoldersDir(jj).name );
        procFoldersDir = [procFoldersDir; classProcFoldersDir];
    end
    ii = 1;
    while ii <= length( procFoldersDir )
        if exist( [procFoldersDir(ii).class filesep procFoldersDir(ii).name filesep 'config.mat'], 'file' )
            procFoldersDir(ii).type = strtok( procFoldersDir(ii).name, '.' );
            pfd = dir( [procFoldersDir(ii).class filesep procFoldersDir(ii).name filesep '*'] );
            procFoldersDir(ii).size = sum( [pfd.bytes] );
            ii = ii + 1;
        else
            procFoldersDir(ii) = [];
        end
    end
    
    makeProcList = true;
    
    while true
        if ~exist( 'procList', 'var' ) || isempty( procList ) || makeProcList
            procList = listProcFolders( procFoldersDir );
        end
        procNames = keys( procList );
        for ii = 1 : length( procNames )
            nFolders = numel( getMapStructElem( procList, procNames{ii}, 'idxs' ) );
            sizeFolders = sum( [procFoldersDir(getMapStructElem( procList, procNames{ii}, 'idxs' )).size] ) / (1024*1000);
            fprintf( '%i: \t%s \t(%i folders, %i MB)\n', ii, procNames{ii}, nFolders, ceil( sizeFolders ) );
        end
        
        choice = [];
        choice = input( ['\n''q'' to quit. ' ...
                         'Enter to go back, '...
                         '''l'' nr to look, '...
                         '''p'' nr to peek into one config, '...
                         '''L'' nr to list, '...
                         '''d'' nr to delete. '...
                         'nr can be a range as in 10-50. >> '], 's' );

        if strcmpi( choice, 'q' )
            return;
        elseif ~isempty( choice )
            [cmd,arg] = strtok( choice, ' ' );
            listNames = keys(procList);
            [arg1,arg2] = strtok( arg, '-' );
            if isempty( arg2 ), arg2 = arg1; end
            arg = str2double( arg1 ) : str2double( arg2(2:end) );
            idxs = [];
            for ii = 1 : numel( arg )
                idxs = [idxs getMapStructElem( procList, listNames{arg(ii)}, 'idxs' )];
            end
            if strcmp( cmd, 'l' )
                for ii = idxs
                    presentProcFolder( [procFoldersDir(ii).class filesep procFoldersDir(ii).name] );
                    input( 'press enter to continue', 's' );
                end
                makeProcList = false;
                continue;
            elseif strcmp( cmd, 'p' )
                presentProcFolder( [procFoldersDir(idxs(1)).class filesep procFoldersDir(idxs(1)).name] );
                input( 'press enter to continue', 's' );
                makeProcList = false;
                continue;
            elseif strcmp( cmd, 'L' )
                procFoldersDir = [procFoldersDir(idxs)];
                makeProcList = true;
                continue;
            elseif strcmpi( cmd, 'd' )
                for ii = flip( idxs )
                    fprintf( 'Deleting %s...\n', [procFoldersDir(ii).class filesep procFoldersDir(ii).name] );
                    rmdir( [procFoldersDir(ii).class filesep procFoldersDir(ii).name], 's' );
%                    procList(proc
%                    procFoldersDir(ii) = [];
                end
                makeProcList = false;
                continue;
            end
        end
        break;
    end
end

end

% ---------------------------------------------------------------------------------------%

function procList = listProcFolders( procFolders )

choice = input( ['Enter to see all folders, '...
                 '''t'' to see by type, ''c'' by config,'...
                 '''C'' by class, ''e'' by earsignal''s config, '...
                 '''o'' for outdated folders >> '], 's' );
procList = containers.Map('KeyType','char','ValueType','any');
if isempty( choice )
    for ii = 1 : length( procFolders )
        assignMapStructElem( procList, [procFolders(ii).class filesep procFolders(ii).name], 'idxs', ii );
    end
elseif strcmpi( choice, 't' )
    for ii = 1 : length( procFolders )
        if ~procList.isKey( procFolders(ii).type )
            assignMapStructElem( procList, procFolders(ii).type, 'idxs', ii );
        else
            assignMapStructElem( procList, procFolders(ii).type, 'idxs', ...
                [getMapStructElem( procList, procFolders(ii).type, 'idxs' ) ii] );
        end
    end
elseif strcmp( choice, 'C' )
    for ii = 1 : length( procFolders )
        if ~procList.isKey( procFolders(ii).class )
            assignMapStructElem( procList, procFolders(ii).class, 'idxs', ii );
        else
            assignMapStructElem( procList, procFolders(ii).class, 'idxs', ...
                [getMapStructElem( procList, procFolders(ii).class, 'idxs' ) ii] );
        end
    end
elseif strcmp( choice, 'c' )
    fprintf( '\n' );
    for ii = 1 : length( procFolders )
        procList = configSort( procFolders, ii, procList, @isequalDeepCompare, true );
        if mod( ceil( 100 * ii/length( procFolders ) ), 5 ) == 0, fprintf( '.' ); end
    end
    fprintf( '\n' );
elseif strcmp( choice, 'o' )
    fprintf( '\n' );
    assignMapStructElem( procList, 'outdated', 'idxs', [] );
    iiConfig.error = 'MATLAB:load:cannotInstantiateLoadedVariable';
    assignMapStructElem( procList, 'outdated', 'config', iiConfig );
    for ii = 1 : length( procFolders )
        procList = configSort( procFolders, ii, procList, @isequalDeepCompare, false );
        if mod( ceil( 100 * ii/length( procFolders ) ), 5 ) == 0, fprintf( '.' ); end
    end
    fprintf( '\n' );
elseif strcmp( choice, 'e' )
    fprintf( '\n' );
    pfidxs = 1 : length( procFolders );
    for ii = pfidxs(strcmpi({procFolders.type},'SceneEarSignalProc'))
        procList = configSort( procFolders, ii, procList, @isequalDeepCompare, true );
        if mod( ceil( 100 * ii/length( procFolders ) ), 5 ) == 0, fprintf( '.' ); end
    end
    for ii = pfidxs(~strcmpi({procFolders.type},'SceneEarSignalProc'))
        procList = configSort( procFolders, ii, procList, @isProcConfIncludedDeepCompare, false );
        if mod( ceil( 100 * ii/length( procFolders ) ), 5 ) == 0, fprintf( '.' ); end
    end
    fprintf( '\n' );
end

end

% ---------------------------------------------------------------------------------------%

function procList = configSort( procFolders, ii, procList, compFunc, addIfNotFound )

warning('error','MATLAB:load:cannotInstantiateLoadedVariable');
try
    iiConfig = load( [procFolders(ii).class filesep procFolders(ii).name filesep 'config.mat'] );
catch err
    if strcmp( err.identifier, 'MATLAB:load:cannotInstantiateLoadedVariable' )
        fprintf( '\n%s: config is of old class definition.', ...
            [procFolders(ii).class filesep procFolders(ii).name] );
        iiConfig.error = 'MATLAB:load:cannotInstantiateLoadedVariable';
    else
        rethrow( err );
    end
end
if isempty( procList )
    assignMapStructElem( procList, [procFolders(ii).class filesep procFolders(ii).name], 'idxs', ii );
    assignMapStructElem( procList, [procFolders(ii).class filesep procFolders(ii).name], 'config', iiConfig );
else
    procNames = keys( procList );
    configFound = false;
    for jj = 1 : length( procNames )
        if compFunc( getMapStructElem( procList, procNames{jj}, 'config' ), iiConfig )
            assignMapStructElem( procList, procNames{jj}, 'idxs',...
                [getMapStructElem( procList, procNames{jj}, 'idxs' ), ii] );
            configFound = true;
            break;
        end
    end
    if addIfNotFound && ~configFound
        assignMapStructElem( procList, [procFolders(ii).class filesep procFolders(ii).name], 'idxs', ii );
        assignMapStructElem( procList, [procFolders(ii).class filesep procFolders(ii).name], 'config', iiConfig );
    end
end
        
end

% ---------------------------------------------------------------------------------------%

function presentProcFolder( procFolder )

cprintf( '-Blue', '\n.:%s:.\n', procFolder );
config = load( [procFolder filesep 'config.mat'] );
presentCfg( config );

end

% ---------------------------------------------------------------------------------------%

function presentCfg( config )

if isfield( config, 'featureProc' ) && isfield( config, 'blockSize' )
    fprintf( '..:: featureCreator.cfg ::..\n' );
    fprintf( '     %s\n', config.featureProc.featureProc );
    choice = input( ['Enter: next category, '...
                     '''d'': details >> '], 's' );
    if strcmp( choice, 'd' )
        fn = fieldnames( config.featureProc );
        for ii = 1 : length( fn )
            if strcmp( fn{ii}, 'featureProc' ), continue; end
            fprintf( '        %s: %s\n', fn{ii}, mat2str( config.featureProc.(fn{ii}) ) );
        end
        fprintf( '        blockSize: %f; labelBlockSize: %f\n',...
            config.blockSize, config.labelBlockSize );
        fprintf( '        shiftSize: %f; minBlockEventRatio: %f\n',...
            config.shiftSize, config.minBlockEventRatio );
        disp( 'press key to continue' ); pause;
    end
elseif isfield( config, 'afeParams' )
    fprintf( '..:: AFE.cfg ::..\n' );
    fprintf( '     ' );
    for ii = 1 : numel( config.afeParams.s )
        if isfield( config.afeParams.s(ii).a, 'cfHz' )
            nCh = numel( config.afeParams.s(ii).a.cfHz );
        elseif isfield( config.afeParams.s(ii).a, 'flist' )
            nCh = numel( config.afeParams.s(ii).a.flist );
        else
            error( 'not implemented case' );
        end
        fprintf( '- %d-ch %s -', nCh, config.afeParams.s(ii).a.name );
    end
    choice = input( ['\nEnter: next category, '...
                     '''d'': details >> '], 's' );
    if strcmp( choice, 'd' )
        fprintf( 'TODO\n' );
        disp( 'press key to continue' ); pause;
    end
elseif isfield( config, 'binSimCfg' ) && isfield( config, 'sc' )
    fprintf( '..:: earSig.cfg ::..\n' );
    if isempty( config.sc.room ), fprintf( '     no room\n' ); 
    else fprintf( '     ROOM' ); end
    if strcmpi( config.sc.sources(1).azimuth.type, 'manual' )
        azm = config.sc.sources(1).azimuth.value;
    else
        azm = nan;
    end
    fprintf( '     target@%d°\n', azm );
    for ii = 2 : numel( config.sc.sources )
        if strcmpi( config.sc.SNRs(ii).type, 'manual' )
            snr = config.sc.SNRs(ii).value;
        else
            snr = nan;
        end
        if isa( config.sc.sources(ii), 'sceneConfig.PointSource' )
            if strcmpi( config.sc.sources(ii).azimuth.type, 'manual' )
                azm = config.sc.sources(ii).azimuth.value;
            else
                azm = nan;
            end
            fprintf( '     distractor@%d°@%ddB', azm, snr );
        else
            fprintf( '     ambient distractor@%ddB', snr );
        end
        if numel( config.sc.loop ) >= ii  &&  config.sc.loop(ii)
            fprintf( ' (looped)' );
        end
        fprintf( '\n' );
    end
    choice = input( ['Enter: next category, '...
                     '''d'': details >> '], 's' );
    if strcmp( choice, 'd' )
        fprintf( '        SampleRate: %f; ReverbMaxOrder: %f\n',...
            config.binSimCfg.SampleRate, config.binSimCfg.ReverberationMaxOrder );
        fprintf( '        hrir: %s\n', config.binSimCfg.hrir );
        disp( 'press key to continue' ); pause;
    end
elseif isfield( config, 'sceneConfig' ) && isfield( config, 'hrir' )
    fprintf( '..:: binSim.cfg ::..\n' );
    if isempty( config.sceneConfig.room ), fprintf( '     no room\n' ); 
    else fprintf( 'ROOM' ); end
    if isa( config.sceneConfig.sources(1), 'sceneConfig.PointSource' )
        if strcmpi( config.sceneConfig.sources(1).azimuth.type, 'manual' )
            azm = config.sceneConfig.sources(1).azimuth.value;
        else
            azm = nan;
        end
        fprintf( '     source@%d°', azm );
    else
        fprintf( '     ambient distractor' );
    end
    fprintf( '\n' );
    choice = input( ['Enter: next category, '...
                     '''d'': details >> '], 's' );
    if strcmp( choice, 'd' )
        fprintf( '        SampleRate: %f; ReverbMaxOrder: %f\n',...
            config.SampleRate, config.ReverberationMaxOrder );
        fprintf( '        hrir: %s\n', config.hrir );
        disp( 'press key to continue' ); pause;
    end
end
if isfield( config, 'extern' )
    presentCfg( config.extern );
else
    for ii = 1 : length( fieldnames( config ) )
        if isfield( config, ['sceneConfig' num2str(ii)] )
            fprintf( '..:: Multi.cfg.%d ::..\n', ii );
            presentCfg( config.(['sceneConfig' num2str(ii)]) );
        end
    end
end

end

% ---------------------------------------------------------------------------------------%

function assignMapStructElem( map, key, fieldname, val )

if map.isKey( key )
    s = map(key);
end
s.(fieldname) = val;
map(key) = s;

end

function val = getMapStructElem( map, key, fieldname  )

s = map(key);
val = s.(fieldname);

end

% ---------------------------------------------------------------------------------------%

function eq = isProcConfIncludedDeepCompare( a, b )

eq = true;

if isequalDeepCompare( a, b ), return; end;
if isfield( b, 'extern' )
    eq = isProcConfIncludedDeepCompare( a, b.extern );
    return;
elseif numel( fieldnames( b ) ) == 1  &&  isfield( b, 'sceneConfig1' )
    eq = isProcConfIncludedDeepCompare( a, b.sceneConfig1 );
    return;
end

eq = false;

end

