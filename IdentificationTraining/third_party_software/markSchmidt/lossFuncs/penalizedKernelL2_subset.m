function [nll,g,H] = penalizedKernelL2_subset(w,K,subset,gradFunc,lambda,varargin)
% Adds kernel L2-penalization to a loss function, when the weight vector
% (you can use this instead of always adding it to the loss function code)
%
% This version applies the regularization to a subset of the variables

if nargout <= 1
    [nll] = gradFunc(w,varargin{:});
elseif nargout == 2
    [nll,g] = gradFunc(w,varargin{:});
else
    [nll,g,H] = gradFunc(w,varargin{:});
end

nll = nll+sum(lambda*w(subset)'*K*w(subset));

if nargout > 1
    g(subset) = g(subset) + 2*lambda*K*w(subset);
end

if nargout > 2
    H(subset,subset) = H(subset,subset) + 2*lambda*K;
end