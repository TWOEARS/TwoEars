
dirName = 'azmTrain';

ncs = logspace( log10(3), log10(1000), 25 );
dp = zeros( 1, numel( ncs ) );
dps = zeros( 1, numel( ncs ) );
nd = zeros( 1, numel( ncs ) );
for ii = 1 : numel( ncs )
    [~,dpa,nda] = cmpCoeffsForModels( dirName, ncs(ii) );
    dp(ii) = mean( dpa );
    dps(ii) = std( dpa );
    nd(ii) = ncs(ii) - mean( nda );
end

figure;
hold all;
plot( ncs, dp, 'b', 'LineWidth', 2 );
plot( ncs, dp+dps, 'c--', 'LineWidth', 1 );
plot( ncs, dp-dps, 'c--', 'LineWidth', 1 );
set( gca, 'XScale', 'log' );
xlabel( '# of coefficients' );
ylabel( 'difference in %' );
title( 'difference between glmnet cv and full trainset coefficient distributions' );
