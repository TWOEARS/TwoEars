function coefHist3( modelAr, fnameBuildSet )

categoryIndexes = 0;
for ii = 1 : size( fnameBuildSet, 1 )
    catIdxCalc = buildFeatureCategoryIdxCalc( fnameBuildSet, ii );
    categoryIndexes(ii+1) = prod( catIdxCalc ) + categoryIndexes(max(1,ii) );
end
    
nCoefs = unique( floor( logspace(log10(3),log10(categoryIndexes(end)),33) ) );
for jj = 1:length(nCoefs)
    
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

    % average impact for each lmoment across categories
    for kk = 1 : 12
        [catIdxCalc,catNms] = buildFeatureCategoryIdxCalc( fnameBuildSet, kk );
        lcatpos = strcmp( catNms, 'LMom ' ) | strcmp( catNms, 'LMom' );
        lstep = catIdxCalc(lcatpos);
        for ll = 1 : catIdxCalc(lcatpos)
            lmom = fnameBuildSet{kk,find(lcatpos==1)*2}(ll);
            cial(jj,kk,lmom) = sum( ia(jj,categoryIndexes(kk)+ll:lstep:categoryIndexes(kk+1)) );
        end
    end

    % average impact for each moment across categories
    for kk = 13 : 24
        [catIdxCalc,catNms] = buildFeatureCategoryIdxCalc( fnameBuildSet, kk );
        lcatpos = strcmp( catNms, 'Mom ' ) | strcmp( catNms, 'Mom' );
        lstep = catIdxCalc(lcatpos);
        for ll = 1 : catIdxCalc(lcatpos)
            mom = fnameBuildSet{kk,find(lcatpos==1)*2}(ll);
            ciam(jj,kk-12,mom) = sum( ia(jj,categoryIndexes(kk)+ll:lstep:categoryIndexes(kk+1)) );
        end
    end

end


figure;
hold all;
plot( mean(ia) );

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTickLabel',fnameBuildSet(:,1),...
    'XTick',1 : length( fnameBuildSet(:,1) ));
hold(axes1,'all');
bar1 = bar( [mean( cia(:,1:12) )' mean( cia(:,13:24) )'], 'Parent',axes1 );
set(bar1(1),'DisplayName','lmom category impacts');
set(bar1(2),'DisplayName','mom category impacts');
legend(axes1,'show');

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTickLabel',fnameBuildSet(1:12,1),...
    'XTick',1 : length( fnameBuildSet(1:12,1) ));
hold(axes1,'all');
bar1 = bar( squeeze( mean( cial ) ),'Parent',axes1 );
set(bar1(1),'DisplayName','LMoment 1');
set(bar1(2),'DisplayName','LMoment 2');
set(bar1(3),'DisplayName','LMoment 3');
set(bar1(4),'DisplayName','LMoment 4');
legend(axes1,'show');
title('LMoments strengths');

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTickLabel',fnameBuildSet(13:24,1),...
    'XTick',1 : length( fnameBuildSet(13:24,1) ));
hold(axes1,'all');
bar1 = bar( squeeze( mean( ciam ) ),'Parent',axes1 );
set(bar1(1),'DisplayName','Mean');
set(bar1(2),'DisplayName','Std');
set(bar1(3),'DisplayName','Skewness');
set(bar1(4),'DisplayName','Kurtosis');
legend(axes1,'show');
title('Moments strengths');

ciall = mean(squeeze( mean( cial ) ));
ciamm = mean(squeeze( mean( ciam ) ) );

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTick',1 : 4);
hold(axes1,'all');
bar1 = bar( [ciall' ciamm'],'Parent',axes1 );
set(bar1(1),'DisplayName','lmoms');
set(bar1(2),'DisplayName','moms');
legend(axes1,'show');
title('Moments strengths');
