function [bestCV, bestCVstd, smallestWithinBest] = cmpCvAndTestPerfBestModels( trainModelDir, testModelDir, bplot, plotTitle )

if nargin < 3, bplot = 0; end;
if nargin < 4, plotTitle = ''; end;
    
[testPerf, cvPerf, cvStd, nc, l] = cmpCvAndTestPerf( trainModelDir, testModelDir, bplot, plotTitle );

[bestCV.cvPerf, bestCVidx] = max( cvPerf );
bestCV.testPerf = testPerf(bestCVidx);
bestCV.nc = nc(bestCVidx);
bestCV.l = l(bestCVidx);

[~, bestCVstdIdx] = max( cvPerf - cvStd );
bestCVstd.cvPerf = cvPerf(bestCVstdIdx);
bestCVstd.testPerf = testPerf(bestCVstdIdx);
bestCVstd.nc = nc(bestCVstdIdx);
bestCVstd.l = l(bestCVstdIdx);

swbIdx = find( cvPerf >= bestCV.cvPerf - cvStd(bestCVidx), 1, 'first' );
smallestWithinBest.cvPerf = cvPerf(swbIdx);
smallestWithinBest.testPerf = testPerf(swbIdx);
smallestWithinBest.nc = nc(swbIdx);
smallestWithinBest.l = l(swbIdx);

if bplot
    plot( gca, [bestCV.nc, bestCV.nc], get(gca,'YLim'), 'r--' ); 
    plot( gca, [bestCVstd.nc, bestCVstd.nc], get(gca,'YLim'), 'r-.' ); 
    plot( gca, [smallestWithinBest.nc, smallestWithinBest.nc], get(gca,'YLim'), 'r:' ); 
end