function coefHist4( modelAr, fnameBuildSet )

categoryIndexes = 0;
for ii = 1 : size( fnameBuildSet, 1 )
    catIdxCalc = buildFeatureCategoryIdxCalc( fnameBuildSet, ii );
    categoryIndexes(ii+1) = prod( catIdxCalc ) + categoryIndexes(max(1,ii) );
end
    
nCoefs = unique( floor( logspace(log10(3),log10(categoryIndexes(end)),33) ) );
for jj = 1:length(nCoefs)/3
    
    for ii = 1 : length( modelAr )
        if isempty( jj )
            lambda = modelAr(ii).model.lambda;
        else
            lIdx = find( modelAr(ii).model.nCoefs >= nCoefs(jj), 1 );
            if isempty( lIdx )
                lIdx = length( modelAr(ii).model.model.lambda );
            end
            lambda = modelAr(ii).model.model.lambda(lIdx);
        end
        [impact(jj,ii,:), idx(jj,ii,:)] = modelAr(ii).model.getCoefImpacts( lambda );
        sii = sortrows( [squeeze(impact(jj,ii,:)), squeeze(idx(jj,ii,:))], 2 );
        impact(jj,ii,:) = sii(:,1);
        idx(jj,ii,:) = sii(:,2);
    end
    
    % average impact for each feature
    ia(jj,:) = mean( impact(jj,:,:), 2 );

    % average impact for each category of features
    for kk = 1 : length( categoryIndexes ) - 1
        cia(jj,kk) = sum( ia(jj,categoryIndexes(kk)+1:categoryIndexes(kk+1)) );
    end

    % average impact for each subcategory
    for kk = 1 : length( categoryIndexes ) - 1
        catIdxCalc = buildFeatureCategoryIdxCalc( fnameBuildSet, kk );
        scIdxRange = prod( catIdxCalc(2:end) );
        for ss = 1 : catIdxCalc(1)
            scia(jj,kk,ss) = sum( ia(jj,categoryIndexes(kk)+1+(ss-1)*scIdxRange:categoryIndexes(kk)+ss*scIdxRange) );
        end
    end
    
end


figure;
hold all;
plot( mean(ia) );

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTickLabel',fnameBuildSet(1:6,1),...
    'XTick',1 : length( fnameBuildSet(1:6,1) ));
hold(axes1,'all');
bar1 = bar( [mean( cia(:,1:6) )' mean( cia(:,7:12) )'], 'Parent',axes1 );
set(bar1(1),'DisplayName','low res category impacts');
set(bar1(2),'DisplayName','high res category impacts');
legend(axes1,'show');

rmiaL = scia(:,1,:) + scia(:,2,:) + scia(:,3,:) + scia(:,4,:);

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTick',1 : 8 );
hold(axes1,'all');
bar1 = bar( squeeze( mean( rmiaL ) ),'Parent',axes1 );
title('low res freq channels impacts');

rmiaH = scia(:,7,:) + scia(:,8,:) + scia(:,9,:) + scia(:,10,:);

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTick',1 : 32 );
hold(axes1,'all');
bar1 = bar( squeeze( mean( rmiaH ) ),'Parent',axes1 );
title('high res freq channels impacts');

amiaL = scia(:,5,:) + scia(:,6,:);

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTick',1 : 8 );
hold(axes1,'all');
bar1 = bar( squeeze( mean( amiaL ) ),'Parent',axes1 );
title('low res freq channels AM impacts');

amiaH = scia(:,11,:) + scia(:,12,:);

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTick',1 : 16 );
hold(axes1,'all');
bar1 = bar( squeeze( mean( amiaH ) ),'Parent',axes1 );
title('high res freq channels AM impacts');
