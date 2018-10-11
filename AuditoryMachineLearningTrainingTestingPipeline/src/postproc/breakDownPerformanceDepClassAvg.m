function [bac,sens,spec,bacstd,sensstd,specstd] = breakDownPerformanceDepClassAvg( counts, classVar, vars )

vars = sort( [classVar, vars] );
[bac,sens,spec] = breakDownPerformanceDep( counts, vars );
classVarNew = find( vars == classVar );

bacstd = squeeze( nanStd( bac, classVarNew ) );
sensstd = squeeze( nanStd( sens, classVarNew ) );
specstd = squeeze( nanStd( spec, classVarNew ) );
bac = squeeze( nanMean( bac, classVarNew ) );
sens = squeeze( nanMean( sens, classVarNew ) );
spec = squeeze( nanMean( spec, classVarNew ) );

end
