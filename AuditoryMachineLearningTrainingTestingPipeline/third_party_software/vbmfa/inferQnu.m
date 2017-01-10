% inferQnu.m : This script calculates the sufficient statistics for
% the variational posterior over precision parameters for each column
% of each factor loading matrix.

s = size(Lm,2);

a = pa + .5*size(Lm{1},1);
for t = 1:s
  kt = size(Lm{t},2);
  b{t} = pb*ones(1,kt-1) + .5*( diag(sum(Lcov{t}(2:end,2:end,:),3))' + sum(Lm{t}(:,2:end).^2,1) );
end


