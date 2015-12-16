function [ia, iaidx, iamis, mia, iapis, t] = coefHist( modelAr, plots, nCoefs )

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
    idx(ii,:) = sii(:,2);
end
impactAvg = mean( impact, 1 );
impactStd = std( impact, [], 1 );

iapis = impactAvg + impactStd;
iis = sortrows( [impactAvg; impactStd; impactAvg+impactStd]', 3);
ia = impactAvg;
[iat, iaidxt] = sort( ia, 'descend' );
iaidxt(iat==0) = [];
iat(iat==0) = [];
t = table( round(iat'*1000)/10, iaidxt', 'VariableNames', {'impact','featIdx'} );
iamis = impactAvg - impactStd;
mia = min(impact,[],1);

if plots
    figure;
    bar( [impactAvg; impactStd]', 'BarLayout', 'stacked' );
    figure;
    bar( iis(:,1:2), 'BarLayout', 'stacked' );
    figure;
    bar( impactAvg );
    figure;
    bar( iamis );
    figure;
    bar( mia );
end