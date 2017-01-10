function grpLabels = getGroupLabels( featureNames, grps )

grpLabels = zeros( size( featureNames ) );

for ii = 1 : numel( grps )
    iidxs = getFeatureIdxs( featureNames, grps{ii} );
    grpLabels(iidxs) = ii;
end

    