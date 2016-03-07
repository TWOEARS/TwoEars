function plotFsGrps( grpDefs, impacts, featureNames, addTitle, showZero, noFig, style )

if nargin < 4, addTitle = ''; end
if nargin < 5, showZero = true; end
if nargin < 6, noFig = false; end
if nargin < 7, style = 'bar'; end

grpImpact = zeros( size(grpDefs) );
grpCount = zeros( size(grpDefs) );

for ii = 1 : numel( grpDefs )
    grpIdxs = getFeatureIdxs( featureNames, grpDefs{ii} );
    grpImpact(ii) = sum( impacts(grpIdxs) );
    grpCount(ii) = sum( impacts(grpIdxs) > 0 );
end
if ~showZero
    grpDefs(grpCount==0) = [];
    grpImpact(grpCount==0) = [];
    grpCount(grpCount==0) = [];
end

plotFsProfile( grpDefs, grpImpact, grpCount, addTitle, noFig, style );
