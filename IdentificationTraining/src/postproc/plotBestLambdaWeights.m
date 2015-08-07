function [idxs,weights] = plotBestLambdaWeights( model )

bestLambda = model.lambdasSortedByPerf(end,1);
bestLambdaIdx = find( model.model.lambda >= bestLambda, 1, 'last' );
activeWeights = ( abs( model.coefsRelAvg(bestLambdaIdx,:) ) > 0 );
cRelAvg = model.coefsRelAvg(bestLambdaIdx,activeWeights);
cRelStd = model.coefsRelStd(bestLambdaIdx,activeWeights);

% figure;
% errorbar( cRelAvg, cRelStd, 'rx' );
% 
% figure;
% t = squeeze( model.coefsCV(bestLambdaIdx,:,activeWeights) );
% plot(t','r.', 'MarkerSize', 15);
% 
% for ii = 1:size( t, 2 )
%     minw = min( t(:,ii) );
%     maxw = max( t(:,ii) );
%     line( [ii,ii], [minw, maxw], 'Color', 'r' );
% end

figure;
cMdn = squeeze( median( model.coefsCV(bestLambdaIdx,:,activeWeights), 2 ) );
cQntl1 = squeeze( quantile( model.coefsCV(bestLambdaIdx,:,activeWeights), 0.25, 2 ) );
plot( cMdn, 'rx', 'MarkerSize', 15 );
hold all;
plot( cQntl1, 'r.', 'MarkerSize', 15 );
cQntl2 = squeeze( quantile( model.coefsCV(bestLambdaIdx,:,activeWeights), 0.75, 2 ) );
plot( cQntl2, 'r.', 'MarkerSize', 15 );
for ii = 1:size( cQntl1, 1 )
    line( [ii,ii], [cQntl1(ii), cQntl2(ii)], 'Color', 'r' );
end

idxs = 1:length(activeWeights);
idxs = idxs(activeWeights);
weights = cMdn;
idxsweights = sortrows( [idxs', abs(weights), sign(weights)], 2 );
idxs = idxsweights(:,1);
weights = idxsweights(:,2) .* idxsweights(:,3);
idxs(weights == 0) = [];
weights(weights == 0) = [];
weights = weights ./ ( sum( abs( weights ) ) );





% figure1 = figure('Color','white');
% 
% [ax,pgh1,pgh2] = plotyy(allLambdas,ncoefsm,allLambdas, lperfsm);
% 
% set( pgh1, 'Color', [0.5 1, 0.5],'LineWidth',2 );
% set( pgh2, 'Color', [0.5 0.5, 1],'LineWidth',2 );
% 
% set( ax(1),...
%     'YColor',[1 1 1],...
%     'XColor',[1 1 1],...
%     'Color',[0 0 0] );
% set( get( ax(1), 'YLabel' ), 'String','# features');
% set( ax(2),...
%     'YColor',[1 1 1],...
%     'XColor',[1 1 1],...
%     'Color','none' );
% set( get( ax(2), 'YLabel' ), 'String','performance');
% 
% title('#features / performance vs \lambda','Color',[1 1 1]);
% xlabel('\lambda');
% 
% 
