% This script adds the necessary paths for the Two!Ears Auditory Front-End
% extraction framework and set up the needed pathes. Make sure to clear
% yourself the Matlab workspace, if that is necessary.

basePath = fileparts(mfilename('fullpath'));

newPathes = { fullfile(basePath, 'src'), ...
              fullfile(basePath, 'src/Filters'), ...
              fullfile(basePath, 'src/Parameter_handling'), ...
              fullfile(basePath, 'src/Processors'), ...
              fullfile(basePath, 'src/Signals'), ...
              fullfile(basePath, 'src/Tools'), ...
              fullfile(basePath, 'test')};
loadedPathes = strsplit( path, pathsep );
isNewPathIncluded = cellfun( @(np)(any( strcmp( np, loadedPathes ) )), newPathes );
newPathes = newPathes(~isNewPathIncluded);
if ~isempty( newPathes )
    addpath( newPathes{:} );
end

clear basePath
