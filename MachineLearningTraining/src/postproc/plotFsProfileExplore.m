function plotFsProfileExplore( impacts, featureNames, addTitle )

if nargin < 3, addTitle = ''; end

allGrps = getFeatureGrps( featureNames );
allGrps = sort( allGrps );
allGrps = cellfun( @(c)({c}), allGrps );

plotFsGrps( allGrps, impacts, featureNames, ['Exploration ' addTitle] );

