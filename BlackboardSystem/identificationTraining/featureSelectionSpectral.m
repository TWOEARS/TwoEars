function [idFeature] = featureSelectionSpectral(x)
[~,SM, ~] = princomp(x);
style = -1;
[ wFeat, SF ] = fsSpectrum( SM, x, style)