function [bac,sens,spec] = getLiveEvalPerf( perfOverview, sceneIdxs )

if nargin < 2, sceneIdxs = ':'; end

tp = sum( arrayfun( @(x)(x.tp), perfOverview(sceneIdxs,:) ), 1 );
fp = sum( arrayfun( @(x)(x.fp), perfOverview(sceneIdxs,:) ), 1 );
tn = sum( arrayfun( @(x)(x.tn), perfOverview(sceneIdxs,:) ), 1 );
fn = sum( arrayfun( @(x)(x.fn), perfOverview(sceneIdxs,:) ), 1 );

tpfn = tp + fn;
tnfp = tn + fp;

sens = tp ./ tpfn;
spec = tn ./ tnfp;
bac = 0.5*sens + 0.5*spec;
