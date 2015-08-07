function [testPerfu, cvPerfu, cvStdu, ncu, lu] = cmpCvAndTestPerf( trainModelDir, testModelDir, bPlot, plotTitle )

trainModelDirEntry = dir( [trainModelDir filesep '*.model.mat'] );
trainModelVars = load( [trainModelDir filesep trainModelDirEntry.name] );

lambdas = trainModelVars.model.model.lambda;
nc = sum( abs( trainModelVars.model.model.beta ) > 0 );

cvPerf = trainModelVars.model.lPerfsMean';
cvStd = trainModelVars.model.lPerfsStd';

testModelDirEntry = dir( [testModelDir filesep '*.model.mat'] );
testModelVars = load( [testModelDir filesep testModelDirEntry.name] );

testPerf = double( testModelVars.testPerfresults );

nc0i = (nc == 0);
nc(nc0i) = [];
cvPerf(nc0i) = [];
cvStd(nc0i) = [];
testPerf(nc0i) = [];
lambdas(nc0i) = [];

[ncu, ~, ncui] = unique( nc );
for ii = 1 : length( ncu )
    testPerfu(ii) = mean( testPerf(ncui==ii) );
    cvPerfu(ii) = mean( cvPerf(ncui==ii) );
    cvStdu(ii) = mean( cvStd(ncui==ii) );
    lu(ii) = mean( lambdas(ncui==ii) );
end

if nargin > 2 && bPlot
    fig = figure;
    hCvPlot = mseb( ncu, cvPerfu, cvStdu );
    ax = gca;
    set( ax, 'XScale', 'log' );
    hold all;
    hTestPlot = plot( ncu, testPerfu, 'g', 'LineWidth', 3 );
    xlabel( '# of coefficients' );
    ylabel( 'BAC_2' );
    legend( 'cvPerf', 'testPerf' );
    if nargin > 3
        title( plotTitle );
    end
    set( ax, 'XLim', [ncu(1), ncu(end)] );
end