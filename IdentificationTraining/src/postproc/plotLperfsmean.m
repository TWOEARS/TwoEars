function plotLperfsmean( modelAr, invColors )

if nargin < 2, invColors = false; end
if invColors
    fnInvColor = @(c)(1-c);
else
    fnInvColor = @(c)(c);
end

for ii = 1 : length( modelAr )
    lambdas{ii} = modelAr(ii).model.model.lambda;
    lperfs{ii} = modelAr(ii).model.lPerfsMean;
    lstds{ii} = modelAr(ii).model.lPerfsStd;
    ncoefs{ii} = modelAr(ii).model.nCoefs;
end

allLambdas = sort( unique( vertcat( lambdas{:} ) ) );
for ii = 1 : length( modelAr )
    lperfsi(ii,:) = interp1( lambdas{ii}, lperfs{ii}, allLambdas, 'pchip' );
    lstdsi(ii,:) = interp1( lambdas{ii}, lstds{ii}, allLambdas, 'pchip' );
    ncoefsi(ii,:) = interp1( lambdas{ii}, ncoefs{ii}, allLambdas, 'pchip' );
end

lperfsm = mean( lperfsi, 1 );
lstdsm = mean( lstdsi, 1 );
ncoefsm = mean( ncoefsi, 1 );

figure1 = figure('Color','none');

[ax,pgh1,pgh2] = plotyy(allLambdas,ncoefsm,allLambdas, lperfsm-lstdsm);

set( pgh1, 'Color', fnInvColor([0.5 0, 0.5]),'LineWidth',2 );
set( pgh2, 'Color', fnInvColor([0.5 0.5, 0]),'LineWidth',2 );

set( ax(1),...
    'YColor',fnInvColor([0 0 0]),...
    'XColor',fnInvColor([0 0 0]),...
    'Color',fnInvColor([1 1 1]) );
set( get( ax(1), 'YLabel' ), 'String','# features');
set( ax(2),...
    'YColor',fnInvColor([0 0 0]),...
    'XColor',fnInvColor([0 0 0]),...
    'Color','none' );
set( get( ax(2), 'YLabel' ), 'String','performance (avg-std)');

title('#features / performance vs \lambda','Color',fnInvColor([0 0 0]));
xlabel('\lambda');


