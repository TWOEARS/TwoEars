function [bcv, bcvs, swb] = modelsCvTestStats( bestCV, bestCVstd, smallestWithinBest )

bcv.cvPerf = mean( [bestCV.cvPerf] );
bcv.testPerf = mean( [bestCV.testPerf] );
bcv.nc = mean( [bestCV.nc] );
bcv.l = mean( [bestCV.l] );
bcv.cvPerfStd = std( [bestCV.cvPerf] );
bcv.testPerfStd = std( [bestCV.testPerf] );
bcv.ncStd = std( [bestCV.nc] );
bcv.lStd = std( [bestCV.l] );

bcvs.cvPerf = mean( [bestCVstd.cvPerf] );
bcvs.testPerf = mean( [bestCVstd.testPerf] );
bcvs.nc = mean( [bestCVstd.nc] );
bcvs.l = mean( [bestCVstd.l] );
bcvs.cvPerfStd = std( [bestCVstd.cvPerf] );
bcvs.testPerfStd = std( [bestCVstd.testPerf] );
bcvs.ncStd = std( [bestCVstd.nc] );
bcvs.lStd = std( [bestCVstd.l] );

swb.cvPerf = mean( [smallestWithinBest.cvPerf] );
swb.testPerf = mean( [smallestWithinBest.testPerf] );
swb.nc = mean( [smallestWithinBest.nc] );
swb.l = mean( [smallestWithinBest.l] );
swb.cvPerfStd = std( [smallestWithinBest.cvPerf] );
swb.testPerfStd = std( [smallestWithinBest.testPerf] );
swb.ncStd = std( [smallestWithinBest.nc] );
swb.lStd = std( [smallestWithinBest.l] );

if nargout < 1
    disp( bcv );
end
if nargout < 2
        disp( bcvs );
end
if nargout < 3
        disp( swb );
end
