function [modelfiles, diffsPerc, nDiff] = cmpCoeffsForModels( dirName, nCoeffs )

if nargin < 2
    ncArg = {};
else
    ncArg = {nCoeffs};
end

modelfiles = {};
diffsPerc = [];
nDiff = [];

dm = dir( [dirName filesep '*.model.mat'] );
for dmi = 1 : length( dm )
    m = load( [dirName filesep dm(dmi).name], 'model' );
    modelfiles{end+1} = [dirName filesep dm(dmi).name];
    [diffsPerc(end+1), nDiff(end+1)] = cmpGlmnetCvCoeffsVsTrainsetCoeffs( m.model, ncArg{:} );
end

d = dir( dirName);
d(1:2) = [];
for di = 1 : length( d )
    if d(di).isdir
        [mf, dp, nd] = cmpCoeffsForModels( [dirName filesep d(di).name], ncArg{:} );
        modelfiles = [modelfiles; mf];
        diffsPerc = [diffsPerc; dp];
        nDiff = [nDiff; nd];
    end
end

