function coefHist1( modelAr )

nCoefs = unique( floor( logspace(log10(3),log10(1888),33) ) );
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
    ia(jj,:) = mean( impact(jj,:,1:944), 2 );
    ian(jj,:) = mean( impact(jj,:,945:end), 2 );
    
    if ~exist( 'ia4' )
        ia4 = zeros( length(nCoefs), ceil(length(ia(jj,:)) / 4) );
    end
    for ii = 1:length(ia(jj,:))
        ia4(jj,ceil(ii/4)) = ia4(jj,ceil(ii/4)) + ia(jj,ii);
    end
    if ~exist( 'ian4' )
        ian4 = zeros( length(nCoefs), ceil(length(ian(jj,:)) / 4) );
    end
    for ii = 1:length(ian(jj,:))
        ian4(jj,ceil(ii/4)) = ian4(jj,ceil(ii/4)) + ian(jj,ii);
    end
    
    c.rm(jj) = sum( ia4(jj,1:16) );
    c.sp(jj) = sum( ia4(jj,17:30) );
    c.ons(jj) = sum( ia4(jj,31:46) );
    c.rmd(jj) = sum( ia4(jj,47:62) );
    c.spd(jj) = sum( ia4(jj,63:76) );
    c.onsd(jj) = sum( ia4(jj,77:92) );
    c.am(jj) = sum( ia4(jj,93:164) );
    c.amd(jj) = sum( ia4(jj,165:236) );
    
    cn.rmn(jj) = sum( ian4(jj,1:16) );
    cn.spn(jj) = sum( ian4(jj,17:30) );
    cn.onsn(jj) = sum( ian4(jj,31:46) );
    cn.rmdn(jj) = sum( ian4(jj,47:62) );
    cn.spdn(jj) = sum( ian4(jj,63:76) );
    cn.onsdn(jj) = sum( ian4(jj,77:92) );
    cn.amn(jj) = sum( ian4(jj,93:164) );
    cn.amdn(jj) = sum( ian4(jj,165:236) );
    
    for ll = 1:4
        cl.rm(jj,ll) = sum( ia(jj,1+ll-1:4:16*4) ) + sum( ian(jj,1+ll-1:4:16*4) );
        cl.sp(jj,ll) = sum( ia(jj,17*4+ll-4:4:30*4) ) + sum( ian(jj,17*4+ll-4:4:30*4) );
        cl.ons(jj,ll) = sum( ia(jj,31*4+ll-4:4:46*4) ) + sum( ian(jj,31*4+ll-4:4:46*4) );
        cl.rmd(jj,ll) = sum( ia(jj,47*4+ll-4:4:62*4) ) + sum( ian(jj,47*4+ll-4:4:62*4) );
        cl.spd(jj,ll) = sum( ia(jj,63*4+ll-4:4:76*4) ) + sum( ian(jj,63*4+ll-4:4:76*4) );
        cl.onsd(jj,ll) = sum( ia(jj,77*4+ll-4:4:92*4) ) + sum( ian(jj,77*4+ll-4:4:92*4) );
        cl.am(jj,ll) = sum( ia(jj,93*4+ll-4:4:164*4) ) + sum( ian(jj,93*4+ll-4:4:164*4) );
        cl.amd(jj,ll) = sum( ia(jj,165*4+ll-4:4:236*4) ) + sum( ian(jj,165*4+ll-4:4:236*4) );
    end
    for ll = 1:4
        cl1.rm(jj,ll) = sum( ia(jj,1+ll-1:4:16*4) );
        cl1.sp(jj,ll) = sum( ian(jj,17*4+ll-4:4:30*4) );
        cl1.ons(jj,ll) = sum( ian(jj,31*4+ll-4:4:46*4) );
        cl1.rmd(jj,ll) = sum( ia(jj,47*4+ll-4:4:62*4) );
        cl1.spd(jj,ll) = sum( ian(jj,63*4+ll-4:4:76*4) );
        cl1.onsd(jj,ll) = sum( ian(jj,77*4+ll-4:4:92*4) );
        cl1.am(jj,ll) = sum( ian(jj,93*4+ll-4:4:164*4) );
        cl1.amd(jj,ll) = sum( ian(jj,165*4+ll-4:4:236*4) );
    end
end

clrm = mean( cl.rm );
clsp = mean( cl.sp );
clons = mean( cl.ons );
clrmd = mean( cl.rmd );
clspd = mean( cl.spd );
clonsd = mean( cl.onsd );
clam = mean( cl.am );
clamd = mean( cl.amd );

clrm1 = mean( cl1.rm );
clsp1 = mean( cl1.sp );
clons1 = mean( cl1.ons );
clrmd1 = mean( cl1.rmd );
clspd1 = mean( cl1.spd );
clonsd1 = mean( cl1.onsd );
clam1 = mean( cl1.am );
clamd1 = mean( cl1.amd );


figure;
hold all;
plot( mean(ia) );
plot( mean(ian) );

figure;
hold all;
plot( mean(ia4) );
plot( mean(ian4) );

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTickLabel',{'RM','SP','ONS','RM_d','SP_d','ONS_d','AM','AM_d'},...
    'XTick',[1 2 3 4 5 6 7 8]);
hold(axes1,'all');
bar1 = bar( [mean(cell2mat( struct2cell( c ))');mean(cell2mat( struct2cell( cn ))')]', 'Parent',axes1 );
set(bar1(1),'DisplayName','normalized');
set(bar1(2),'DisplayName','unnormalized');
legend(axes1,'show');

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTickLabel',{'RM','SP','ONS','RM_d','SP_d','ONS_d','AM','AM_d'},...
    'XTick',[1 2 3 4 5 6 7 8]);
hold(axes1,'all');
bar1 = bar( [clrm; clsp; clons; clrmd; clspd; clonsd; clam; clamd],'Parent',axes1 );
set(bar1(1),'DisplayName','LMoment 1');
set(bar1(2),'DisplayName','LMoment 2');
set(bar1(3),'DisplayName','LMoment 3');
set(bar1(4),'DisplayName','LMoment 4');
legend(axes1,'show');
title('LMoments strengths');

figure1 = figure;
axes1 = axes('Parent',figure1,...
    'XTickLabel',{'RM','SP','ONS','RM_d','SP_d','ONS_d','AM','AM_d'},...
    'XTick',[1 2 3 4 5 6 7 8]);
hold(axes1,'all');
bar1 = bar( [clrm1; clsp1; clons1; clrmd1; clspd1; clonsd1; clam1; clamd1],'Parent',axes1 );
set(bar1(1),'DisplayName','LMoment 1');
set(bar1(2),'DisplayName','LMoment 2');
set(bar1(3),'DisplayName','LMoment 3');
set(bar1(4),'DisplayName','LMoment 4');
legend(axes1,'show');
title('LMoments strengths (normalized RM, unnormalized rest)');
