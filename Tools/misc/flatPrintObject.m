function flatPrintObject( s, maxRecDep )

if nargin < 2, maxRecDep = 5; end

sc = descriptiveStructCells( s, maxRecDep );
sc(:,2) = stringifyCell( sc(:,2) );
names = char( sc(:,1) );
for ii = 1 : size( sc, 1 )
    cprintf( '*Black', '\t%s\t', names(ii,:) );
    val = sc{ii,2};
    if ~isempty( val ), val = val(1:min(1000,length(val))); end;
    fprintf( '%s\n', val );
end

end
%% --------------------------------------------------------------------------------------%

function sc = descriptiveStructCells( s, maxRecDep, curRecDep )

if nargin < 2, maxRecDep = 5; end
if nargin < 3, curRecDep = 1; end

if curRecDep > maxRecDep
    sc = {[], '!!## max recursion depth reached ##!!'};
    return;
end

fOuterNames = fieldnames( s );
if isempty( fOuterNames ), sc = {[],''};
else sc = [];
end
for ii = 1:size( fOuterNames, 1 )
    if isstruct( s.(fOuterNames{ii}) ) && ~isempty( s.(fOuterNames{ii}) )
        sctmp = descriptiveStructCells( s.(fOuterNames{ii}), maxRecDep, curRecDep+1 );
        if ~isempty( sctmp )
            sctmp(:,1) = strcat( fOuterNames{ii}, '.', sctmp(:,1) );
        else
            sctmp(:,1) = strcat( fOuterNames{ii}, [] );
        end
        sc = [sc; sctmp];
    elseif isobject( s.(fOuterNames{ii}) ) && ~isempty( s.(fOuterNames{ii}) )
        warning off MATLAB:structOnObject
        propsStruct = struct( s.(fOuterNames{ii}) );
        warning on MATLAB:structOnObject
        sctmp = descriptiveStructCells( propsStruct, maxRecDep, curRecDep+1 );
        if ~isempty( sctmp )
            sctmp(:,1) = strcat( fOuterNames{ii}, '.', sctmp(:,1) );
        else
            sctmp(:,1) = strcat( fOuterNames{ii}, [] );
        end
        sc = [sc; sctmp];
    elseif isempty( s.(fOuterNames{ii}) )
        sc = [sc; {fOuterNames{ii} '[]'}];
    else
        sc = [sc; {fOuterNames{ii} s.(fOuterNames{ii})}];
    end
end

end

%% --------------------------------------------------------------------------------------%

function c = stringifyCell( c )

for kk = 1:size(c,1)
for jj = 1:size(c,2)
    if isa( c{kk,jj}, 'function_handle' )
        c{kk,jj} = func2str( c{kk,jj} );
    end
    while isa( c{kk,jj}, 'cell' ) && ~isempty( c{kk,jj} )
        c{kk,jj} = {c{kk,jj}{:}};
        a = stringifyCell( c{kk,jj} );
        a = strcat( a, {'; '} );
        c(kk,jj) = {strcat( a{:} )};
    end
    if isobject( c{kk,jj} ) && ~isempty( c{kk,jj} )
        warning off MATLAB:structOnObject
        propsCell = {struct( c{kk,jj} )};
        warning on MATLAB:structOnObject
        c{kk,jj} = stringifyCell( propsCell );
    end
    if isa( c{kk,jj}, 'struct' )
        if isempty( fieldnames( c{kk,jj} ) )
            c{kk,jj} = 'empty struct';
        else
            sc = descriptiveStructCells( c{kk,jj} );
            sc(:,2) = stringifyCell( sc(:,2) );
            a = strcat( sc(:,1), {': '}, sc(:,2), {', '} );
            c(kk,jj) = {strcat( a{:} )};
        end
    end
    if isa( c{kk,jj}, 'numeric' ) || isa( c{kk,jj}, 'logical' )
        c{kk,jj} = mat2str( c{kk,jj} );
    end
end
end

end

