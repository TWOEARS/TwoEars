function addPathsIfNotIncluded( newPathes )

% for some reason, addpath in some situations takes forever. This function shall
% circumvent any unnecessary addpath call.

if ~iscell( newPathes ), newPathes = {newPathes}; end
pathes = strsplit( path, pathsep );
isNewPathNotYetIncluded = cellfun( @(np)(~any( strcmp( np, pathes ) )), newPathes );
newPathes = newPathes(isNewPathNotYetIncluded);

if ~isempty( newPathes )
    addpath( newPathes{:} );
end
