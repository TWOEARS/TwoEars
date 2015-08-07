function fl = getFeatureTable( idxs, weights, featureSetNames )

featNames = featureSetNames( ceil( idxs / 4 ) );
featNames = strcat(featNames , int2str(mod(idxs,4)+1) );
fl = table( round(weights*1000)/10, featNames, 'VariableNames', {'impact','featName'} );
