function sc = descriptiveStructCells( s )

fOuterNames = fieldnames( s );
sc = [];
for ii = 1:size( fOuterNames, 1 )
    if isstruct( s.(fOuterNames{ii}) )
        sctmp = descriptiveStructCells( s.(fOuterNames{ii}) );
        sctmp(:,1) = strcat( fOuterNames{ii}, '.', sctmp(:,1) );
        sc = [sc; sctmp];
    else
        sc = [sc; {fOuterNames{ii} s.(fOuterNames{ii})}];
    end
end
