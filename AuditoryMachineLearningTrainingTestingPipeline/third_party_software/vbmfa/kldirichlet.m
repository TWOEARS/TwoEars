%res = kldirichlet(vecP,vecQ)
%
%Calculates KL(P||Q) where P and Q are Dirichlet distributions with
%parameters 'vecP' and 'vecQ', which are row vectors, not
%necessarily normalised.
%
% KL(P||Q) = \int d\pi P(\pi) ln { P(\pi) / Q(\pi) }.
%
%Matthew J. Beal GCNU 06/02/01

function [res] = kldirichlet(vecP,vecQ)

alphaP = sum(vecP,2);
alphaQ = sum(vecQ,2);

res = gammaln(alphaP)-gammaln(alphaQ) ...
    - sum(gammaln(vecP)-gammaln(vecQ),2) ...
    + sum( (vecP-vecQ).*(digamma(vecP)-digamma(alphaP)) ,2);