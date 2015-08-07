% inferQpi.m : This script infers the sufficient statistics for the
% variational posterior for the Dirichlet parameter $\bpi$.

s = size(Lm,2);
pu = alpha/s *ones(1,s);

u = pu + sum(Qns,1);


