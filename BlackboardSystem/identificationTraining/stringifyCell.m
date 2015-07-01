function c = stringifyCell( c )

for k = 1:size(c,1)
for j = 1:size(c,2)
    if isa( c{k,j}, 'function_handle' )
        c{k,j} = func2str( c{k,j} );
    end
    while isa( c{k,j}, 'cell' ) && ~isempty( c{k,j} )
        c{k,j} = {c{k,j}{:}};
        a = stringifyCell( c{k,j} );
        a = strcat( a, {'; '} );
        c(k,j) = {strcat( a{:} )};
    end
    if isa( c{k,j}, 'struct' )
        if isempty( fieldnames( c{k,j} ) )
            c{k,j} = 'empty struct';
        else
            sc = descriptiveStructCells( c{k,j} );
            sc(:,2) = stringifyCell( sc(:,2) );
            a = strcat( sc(:,1), {': '}, sc(:,2), {', '} );
            c(k,j) = {strcat( a{:} )};
        end
    end
    if isa( c{k,j}, 'numeric' ) || isa( c{k,j}, 'logical' )
        c{k,j} = mat2str( c{k,j} );
    end
end
end