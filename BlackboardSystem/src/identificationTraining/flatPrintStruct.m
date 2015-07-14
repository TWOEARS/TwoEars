function flatPrintStruct( s )

sc = descriptiveStructCells( s );
sc(:,2) = stringifyCell( sc(:,2) );
t = table( sc(:,2), 'VariableNames', {inputname(1)}, 'RowNames', sc(:,1));
disp( t );
