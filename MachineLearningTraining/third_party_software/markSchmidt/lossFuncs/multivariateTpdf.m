function [lik] = multivariateT(X,mu,sigma,dof,deriv)
[n,d] = size(X);
nll = zeros(n,1);

[R,err]=chol(sigma);
if err == 0
	sigmaInv = sigma^-1;
	for i = 1:n
		tmp = 1 + (1/dof)*(X(i,:)'-mu)'*sigmaInv*(X(i,:)'-mu);
		nll(i,1) = ((d+dof)/2)*log(tmp);
	end
	logSqrtDetSigma = sum(log(diag(R)));
	logZ = gammaln((dof+d)/2) - (d/2)*log(pi) - logSqrtDetSigma - gammaln(dof/2) - (d/2)*log(dof);
	nll = nll - logZ;
	lik = exp(-nll);
else
	lik(:) = inf;
end
