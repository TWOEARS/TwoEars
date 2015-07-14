function [ wFeat, SF ] = fsSpectrum( W, X, style, spec )
%function [ wFeat, SF ] = fsSpectrum( W, X, style, spec )
%   Select feature using the spectrum information of the graph laplacian
%   W - the similarity matrix or a kernel matrix
%   X - the input data, each row is an instance
%   style - -1, use all, 0, use all except the 1st. k, use first k except 1st.
%   spec - the spectral function to modify the eigen values.

[numD,numF] = size(X);

if nargin < 4 || ~isa(spec, 'function_handle')
    spec = @EQU;
end

% build the degree matrix
D = diag(sum(W,2));
% build the laplacian matrix
L = D - W;

% D1 = D^(-0.5)
d1 = (sum(W,2)).^(-0.5);
d1(isinf(d1)) = 0;

% D2 = D^(0.5)
d2 = (sum(W,2)).^0.5;
v = diag(d2)*ones(numD,1);
v = v/norm(v);

%  build the normalized laplacian matrix hatW = diag(d1)*W*diag(d1)
hatL = repmat(d1,1,numD).*L.*repmat(d1',numD,1);

% calculate and construct spectral information
[V, EVA] = svd(hatL,'econ');
EVA = diag(EVA);
EVA = spec(EVA);

% begin to select features
wFeat = ones(numF,1)*1000;

for i = 1:numF
    f = X(:,i);
    hatF = diag(d2)*f;
    l = norm(hatF);

    if l < 100*eps
        wFeat(i) = 1000;
        continue;
    else
        hatF = hatF/l;
    end

    a = hatF'*V;
    a = a.*a;
    a = a';

    switch style
        case -1, % use f'Lf formulation
            wFeat(i) = sum(a.*EVA);
        case 0, % using all eigenvalues except the 1st
            a(numD) = [];
            wFeat(i) = sum(a.*EVA(1:numD-1))/(1-(hatF'*v)^2);
        otherwise,
            a(numD) = [];
            a(1:numD-style) = [];
            wFeat(i) = sum(a.*(2-EVA(numD-style+1:numD-1)));
    end
end

SF = 1:numD;

if style ~= -1 && style ~= 0
    wFeat(wFeat==1000) = -1000;
end

function [newd] = EQU(d)
newd = d;