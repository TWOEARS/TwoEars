function coefHist2( modelAr, fnameBuildSet )

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
    for kk = 1 : length( categoryIndexes ) - 1
        [catIdxCalc,catNms] = buildFeatureCategoryIdxCalc( fnameBuildSet, kk );
        lcatpos = strcmp( catNms, 'LMom ' ) | strcmp( catNms, 'LMom' );
        lstep = catIdxCalc(lcatpos);
        for ll = 1 : catIdxCalc(lcatpos)
            lmom = fnameBuildSet{kk,find(lcatpos==1)*2}(ll);
            cial(jj,kk,lmom) = sum( ia(jj,categoryIndexes(kk)+ll:lstep:categoryIndexes(kk+1)) );
        end
    end

    % average impact for each subcategory
    for kk = 1 : length( categoryIndexes ) - 1
        catIdxCalc = buildFeatureCategoryIdxCalc( fnameBuildSet, kk );
        scIdxRange = prod( catIdxCalc(2:end) );
        for ss = 1 : catIdxCalc(1)
            scia(jj,kk,ss) = sum( ia(jj,categoryIndexes(kk)+1+(ss-1)*scIdxRange:categoryIndexes(kk)+ss*scIdxRange) );
        end
    end
    
    % individual subcategories:
    % ratemap freq channels
    rmia = scia(:,1,:) + scia(:,4,:) + scia(:,7,:);
    spia = scia(:,2,:) + scia(:,5,:) + scia(:,8,:);
    onsia = scia(:,3,:) + scia(:,6,:) + scia(:,9,:);
    amia = scia(:,10,:) + scia(:,11,:) + scia(:,12,:);

    % average impact for each am mod ch
    ammiajj = zeros(1,9);
    for kk = 10 : 12
        [catIdxCalc,catNms] = buildFeatureCategoryIdxCalc( fnameBuildSet, kk );
        lcatpos = strcmp( catNms, 'mod ch ' ) | strcmp( catNms, 'mod ch' );
        scIdxRange = prod( catIdxCalc(3:end) );
        amchStep = prod( catIdxCalc(2:end) );
        for amch = 1: catIdxCalc(1)
        for modch = 1 : catIdxCalc(lcatpos)
            ammiajj(modch) = ammiajj(modch) + sum( ia(...
                jj,...
                categoryIndexes(kk)+1+(amch-1)*amchStep+(modch-1)*scIdxRange:...
                categoryIndexes(kk)+(amch-1)*amchStep+modch*scIdxRange...
                ) );
        end
        end
    end
    ammia(jj,:) = ammiajj;
end


figure;
hold all;
plot( mean(ia) );

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTickLabel',fnameBuildSet(:,1),...
    'XTick',1 : length( fnameBuildSet(:,1) ));
hold(axes1,'all');
bar1 = bar( mean( cia )', 'Parent',axes1 );
set(bar1(1),'DisplayName','category impacts');
legend(axes1,'show');

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTickLabel',fnameBuildSet(:,1),...
    'XTick',1 : length( fnameBuildSet(:,1) ));
hold(axes1,'all');
bar1 = bar( squeeze( mean( cial ) ),'Parent',axes1 );
set(bar1(1),'DisplayName','LMoment 1');
set(bar1(2),'DisplayName','LMoment 2');
set(bar1(3),'DisplayName','LMoment 3');
set(bar1(4),'DisplayName','LMoment 4');
legend(axes1,'show');
title('LMoments strengths');

figure1 = figure;
axes1 = axes('Parent',figure1);%,...
hold(axes1,'all');
bar1 = bar( squeeze( mean( rmia ) ),'Parent',axes1 );
title('RM freq channels impacts');

figure1 = figure;
axes1 = axes('Parent',figure1,...
   'XTickLabel',fnameBuildSet{2,2},...
   'XTick',1 : length( fnameBuildSet{2,2} ));
hold(axes1,'all');
bar1 = bar( squeeze( mean( spia ) ),'Parent',axes1 );
title('SP feature impacts');

figure1 = figure;
axes1 = axes('Parent',figure1);%,...
hold(axes1,'all');
bar1 = bar( squeeze( mean( onsia ) ),'Parent',axes1 );
title('ONS freq channels impacts');

figure1 = figure;
axes1 = axes('Parent',figure1);%,...
hold(axes1,'all');
bar1 = bar( squeeze( mean( amia ) ),'Parent',axes1 );
title('AM freq channels impacts');

figure1 = figure;
axes1 = axes('Parent',figure1);%,...
hold(axes1,'all');
bar1 = bar( squeeze( mean( ammia ) ),'Parent',axes1 );
title('AM mod channels impacts');

