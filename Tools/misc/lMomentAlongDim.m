function [LM] = lMomentAlongDim( X, nL, dim, vectorOutput )

% based on lmom by Kobus N. Bekker, 14-09-2004
% changed to work with matrix input by Ivo Trowitzsch, 29-07-2015
%
% Given nonnegative integer nL, compute the 
% nL l-moments for given data vector X. 
% Return the l-moments as vector L.

if nargin < 4, vectorOutput = false; end

selectNl = nL;
nL = max( nL );

if dim > 2, error('function not built for dim>2 yet'); end
if dim == 1
    X = X'; 
    dim = 2;
end

nm = size(X,dim);
X = sort(X,dim);
bm = zeros(size(X,1),nL-1);
lm = zeros(size(X,1),nL-1);
b0M = mean(X,dim);

for r = 1:nL-1
    NumM = prod(repmat(r+1:nm,r,1)-repmat([1:r]',1,nm-r),1);
    DenM = prod(repmat(nm,1,r) - [1:r]);
    bm(:,r) = (1/nm) * (NumM/DenM) * X(:,r+1:nm)';
end

tBm = [b0M bm]';
BM = tBm(size(tBm,1):-1:1,:);

for i = 1:nL-1
    SpcM = zeros(size(BM,1)-(i+1),size(BM,2));
    CoeffM = [SpcM ; repmat(legendreShiftPoly(i),1,size(X,1))];
    lm(:,i) = sum(CoeffM .* BM,1);
end

LM = [b0M lm];

if nargin > 2 && nL > 2 && all(LM(:,2) ~= 0)
    for ii = 3 : size(LM,2)
        LM(:,ii) = LM(:,ii) ./ LM(:,2);
    end
end

LM = LM(:,selectNl);

if vectorOutput
    LM = reshape(LM',[1,numel(LM)]);
end