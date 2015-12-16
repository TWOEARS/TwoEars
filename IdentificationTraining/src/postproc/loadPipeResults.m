function pipeResults = loadPipeResults( dirname )

subdirList = dir( dirname );
subdirList = subdirList(3:end); % discard '.' and '..'

for ii = 1 : length( subdirList )
    modelFileInfo = dir( fullfile( dirname, subdirList(ii).name, '*.model.mat' ) );
    if isempty( modelFileInfo ), continue; end
    modelFileName = modelFileInfo.name;
    sepPos = strfind( modelFileName, '.' );
    modelName = modelFileName(1:sepPos(1)-1);
    if exist( 'pipeResults', 'var' ) && isfield( pipeResults, modelName )
        pipeResults.(modelName)(end+1) = load( fullfile( dirname, subdirList(ii).name, modelFileName ) );
    else
        pipeResults.(modelName) = load( fullfile( dirname, subdirList(ii).name, modelFileName ) );
    end
end