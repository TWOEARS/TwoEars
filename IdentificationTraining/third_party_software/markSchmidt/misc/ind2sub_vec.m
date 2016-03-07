%% Variant of ind2sub that returns all dimensions in a vector rather than as separate arguments
function ind = ind2sub_vec(siz,ndx)
n = length(siz);
k = [1 cumprod(siz(1:end-1))];
ind = zeros(n,1);
for i = n:-1:1
   vi = rem(ndx-1,k(i)) + 1;
   vj = (ndx - vi)/k(i) + 1;
   ind(i) = vj;
   ndx = vi;
end
end