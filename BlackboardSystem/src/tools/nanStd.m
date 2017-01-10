function s = nanStd(x, dim)

if nargin == 1
    dim = 1;
end

nans = isnan(x);
n = sum(~nans, dim);

nm = nanMean(x, dim);
dev = bsxfun(@minus, x, nm);
dev = dev.*dev;
dev(nans) = 0;
ds = sum(dev, dim);
v = ds./(n-1);
s = sqrt( v );

