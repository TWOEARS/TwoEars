function iis = isInSet( a, b )

iis = zeros(size(a));
for ii = 1 : numel(a)
    iis(ii) = any( a(ii) == b );
end
