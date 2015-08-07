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
    
    while true
        procList = listProcFolders( procFoldersDir );
        
        choice = [];
        choice = input( ['\n''q'' to quit. ' ...
                         'Enter to go back, '...
                         '''l'' nr to look, '...
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
                continue;
            elseif strcmp( cmd, 'L' )
                procFoldersDir = [procFoldersDir(idxs)];
                continue;
            elseif strcmpi( cmd, 'd' )
                for ii = idxs
                    fprintf( 'Deleting %s...\n', [procFoldersDir(ii).class filesep procFoldersDir(ii).name] );
                    rmdir( [procFoldersDir(ii).class filesep procFoldersDir(ii).name], 's' );
                end
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
                 '''C'' by class, ''e'' by earsignal''s config >> '], 's' );
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
        procList = configSort( procFolders, ii, procList, @isequalDeepCompare );
        if mod( ceil( 100 * ii/length( procFolders ) ), 5 ) == 0, fprintf( '.' ); end
    end
    fprintf( '\n' );
elseif strcmp( choice, 'e' )
    fprintf( '\n' );
    pfidxs = 1 : length( procFolders );
    for ii = pfidxs(strcmpi({procFolders.type},'IdSimConvRoomWrapper'))
        procList = configSort( procFolders, ii, procList, @isequalDeepCompare );
        if mod( ceil( 100 * ii/length( procFolders ) ), 5 ) == 0, fprintf( '.' ); end
    end
    for ii = pfidxs(~strcmpi({procFolders.type},'IdSimConvRoomWrapper'))
        procList = configSort( procFolders, ii, procList, @isProcConfIncludedDeepCompare );
        if mod( ceil( 100 * ii/length( procFolders ) ), 5 ) == 0, fprintf( '.' ); end
    end
    fprintf( '\n' );
end
procNames = keys( procList );
for ii = 1 : length( procNames )
    nFolders = numel( getMapStructElem( procList, procNames{ii}, 'idxs' ) );
    sizeFolders = sum( [procFolders(getMapStructElem( procList, procNames{ii}, 'idxs' )).size] ) / (1024*1000);
    fprintf( '%i: \t%s \t(%i folders, %i MB)\n', ii, procNames{ii}, nFolders, ceil( sizeFolders ) );
end


end

% ---------------------------------------------------------------------------------------%

function procList = configSort( procFolders, ii, procList, compFunc )

iiConfig = load( [procFolders(ii).class filesep procFolders(ii).name filesep 'config.mat'] );
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
    if ~configFound
        assignMapStructElem( procList, [procFolders(ii).class filesep procFolders(ii).name], 'idxs', ii );
        assignMapStructElem( procList, [procFolders(ii).class filesep procFolders(ii).name], 'config', iiConfig );
    end
end
        
end

% ---------------------------------------------------------------------------------------%

function presentProcFolder( procFolder )

cprintf( '-Blue', '\n.:%s:.\n', procFolder );
config = load( [procFolder filesep 'config.mat'] );
flatPrintObject( config, 10 );

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
end

eq = false;

end

