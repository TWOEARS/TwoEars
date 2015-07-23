function [idxs,weights,acIdxs,acWeights] = plotMostImportantNweights( model, n )

acWeights = zeros( size( model.dataScalors ) );
for ii = 1 : length( model.model.lambda )
    cMdn = squeeze( median( model.coefsCV(ii,:,:), 2 ) );
    idxs = 1 : length( cMdn );
    weights = cMdn;
    activeWeights = ( abs( weights ) > 0 );
    idxsweights = sortrows( [idxs', abs(weights), sign(weights)], 2 );
    idxs = idxsweights(:,1);
    weights = idxsweights(:,2) .* idxsweights(:,3);
    idxsRanks = length( idxs ) : -1 : 1;
    idxsRanks(weights == 0) = sum( abs(weights) > 0 ) +1;
    acWeights(idxs) = acWeights(idxs) + idxsRanks;
    idxs(weights == 0) = [];
    weights(weights == 0) = [];
    weights = weights ./ ( sum( abs( weights ) ) );
    if numel( weights ) >= n, break; end
end

[acWeights,acIdxs] = sort( acWeights ); 

figure;
bar( abs( cMdn ) ./ (sum( abs( cMdn )) ) );

figure;
cQntl1 = squeeze( quantile( model.coefsCV(ii,:,:), 0.25, 2 ) );
plot( cMdn, 'rx', 'MarkerSize', 15 );
hold all;
plot( cQntl1, 'r.', 'MarkerSize', 15 );
cQntl2 = squeeze( quantile( model.coefsCV(ii,:,:), 0.75, 2 ) );
plot( cQntl2, 'r.', 'MarkerSize', 15 );
for jj = 1:size( cQntl1, 1 )
    line( [jj,jj], [cQntl1(jj), cQntl2(jj)], 'Color', 'r' );
end

figure;
cQntl1 = squeeze( quantile( model.coefsCV(ii,:,activeWeights), 0.25, 2 ) );
cMdn = squeeze( median( model.coefsCV(ii,:,activeWeights), 2 ) );
plot( cMdn, 'rx', 'MarkerSize', 15 );
hold all;
plot( cQntl1, 'r.', 'MarkerSize', 15 );
cQntl2 = squeeze( quantile( model.coefsCV(ii,:,activeWeights), 0.75, 2 ) );
plot( cQntl2, 'r.', 'MarkerSize', 15 );
for jj = 1:size( cQntl1, 1 )
    line( [jj,jj], [cQntl1(jj), cQntl2(jj)], 'Color', 'r' );
end




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
