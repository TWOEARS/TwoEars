function p = profilePathChange( p, oldPath, newPath )

for ii = 1 : numel( p.FunctionTable )
    p.FunctionTable(ii).CompleteName = ...
        strrep( p.FunctionTable(ii).CompleteName, oldPath, newPath );
    p.FunctionTable(ii).FileName = ...
        strrep( p.FunctionTable(ii).FileName, oldPath, newPath );
end
