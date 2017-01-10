% inferQX.m : This script calculates the sufficient statistics for the
% variational posterior over hidden factors.

n = size(Y,2);
p = size(Y,1);
s = size(Lm,2);

for t = 1:s
  kt = size(Lm{t},2);
  T1 = reshape(reshape(Lcov{t}(2:end,2:end,:),(kt-1)*(kt-1),p)*psii,kt-1,kt-1) ...
      + Lm{t}(:,2:end)'*diag(psii+eps)*Lm{t}(:,2:end);
  Xcov{t}              = zeros(kt,kt);
  Xcov{t}(2:end,2:end) = inv( eye(kt-1)+T1 );
  trXm{t}              = Xcov{t}(2:end,2:end)*Lm{t}(:,2:end)'*diag(psii+eps)*(Y-Lm{t}(:,1)*ones(1,n));
  Xm{t}                = [ones(1,n); trXm{t}];
end


