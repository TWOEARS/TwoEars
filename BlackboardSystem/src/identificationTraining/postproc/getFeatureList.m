function [fl, fls] = getFeatureList( modelAr, nCoefs, fNames )

for ii = 1 : length( modelAr )
    if isempty( nCoefs )
        lambda = modelAr(ii).model.lambda;
    else
        lIdx = find( modelAr(ii).model.nCoefs >= nCoefs, 1 );
        if isempty( lIdx )
            lIdx = length( modelAr(ii).model.model.lambda );
        end
        lambda = modelAr(ii).model.model.lambda(lIdx);
    end
    [impact(ii,:), idx(ii,:)] = modelAr(ii).model.getCoefImpacts( lambda );
    sii = sortrows( [impact(ii,:)', idx(ii,:)'], 2 );
    impact(ii,:) = sii(:,1);
end
impactAvg = mean( impact, 1 );

ia = impactAvg;
[iat, iaidxt] = sort( ia, 'descend' );
iaidxt(iat<0.005) = [];
iat(iat<=0.005) = [];
idxn = fNames( ceil( mod(iaidxt,944) / 4 ) );
idxn = strcat(idxn , int2str(mod(iaidxt,4)'+1) );
fl = table( round(iat'*1000)/10, idxn, 'VariableNames', {'impact','featName'} );
fls = sortrows( fl, 'featName' );