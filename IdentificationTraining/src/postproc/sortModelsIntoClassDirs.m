function sortModelsIntoClassDirs( dirName )

d = dir( [dirName filesep 'Training.*']);
for di = 1 : length( d )
    de = dir( [dirName filesep d(di).name filesep '*.model.mat'] );
    if isempty( de ), continue; end;
    classname = strtok( de.name, '.' );
    if ~exist( [dirName filesep classname], 'file' )
        mkdir( dirName, classname );
    end
    movefile( [dirName filesep d(di).name], [dirName filesep classname] );
end
