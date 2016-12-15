function [nBestLambda, nOneSDperfDrop] = plotNoOfActiveWeights( model )

[bp,bpi] = max( model.lPerfsMean );
bps = model.lPerfsStd(bpi);
osddi = find( model.lPerfsMean >= bp - bps, 1, 'first' );

n = [];
for ii = 1 : length( model.model.lambda )
    cMdn = squeeze( median( model.coefsCV(ii,:,:), 2 ) );
    idxs = 1 : length( cMdn );
    weights = cMdn;
    activeWeights = ( abs( weights ) > 0 );
    idxsweights = sortrows( [idxs', abs(weights), sign(weights)], 2 );
    weights = idxsweights(:,2) .* idxsweights(:,3);
    weights(weights == 0) = [];
    n(end+1) = numel( weights );
    if ii == bpi
        nBestLambda = n(end);
        disp( nBestLambda );
        disp( bp );
    end
    if ii == osddi
        nOneSDperfDrop = n(end);
        disp( nOneSDperfDrop );
        disp( model.lPerfsMean(osddi) );
    end
end

figure;

[ax,pgh1,pgh2] = plotyy(model.model.lambda, n, model.model.lambda, model.lPerfsMean);

set( pgh1, 'Color', [0.2 0.8, 0.2],'LineWidth',2 );
set( pgh2, 'Color', [0.2 0.2, 0.8],'LineWidth',2 );

set( ax(1),...
    'YColor',[0.01 0.4, 0.01],...
    'XColor',[0.01 0.4, 0.01],'xscale','log',...
    'YTick', [0;10;50;100;500;1000] );
set( get( ax(1), 'YLabel' ), 'String','# features');
set( ax(2),...
    'YColor',[0.01 0.01, 0.4],...
    'XColor',[0.01 0.01, 0.4],'xscale','log',...
    'YTick', [0;0.5;0.9;1] );
set( get( ax(2), 'YLabel' ), 'String','performance');

title('#features / performance vs \lambda');
xlabel('\lambda');

