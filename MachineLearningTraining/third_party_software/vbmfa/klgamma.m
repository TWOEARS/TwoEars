%kl = klgamma(pa,pb,qa,qb);
%
%Calculates KL(P||Q) where P and Q are Gamma distributions with
%parameters {pa,pb} and {qa,qb}.
%
% KL(P||Q) = \int d\pi P(\pi) ln { P(\pi) / Q(\pi) }.
%
%This routine handles factorised P distributions, if their parameters
%are specified multiply in either 'pa' or 'pb', as elements of a row
%vector.
%
%Matthew J. Beal GCNU 06/02/01

function [kl] = klgamma(pa,pb,qa,qb)

n = max([size(pb,2) size(pa,2)]);

if size(pa,2) == 1, pa = pa*ones(1,n); end
if size(pb,2) == 1, pb = pb*ones(1,n); end
qa = qa*ones(1,n); qb = qb*ones(1,n);

kl = sum( pa.*log(pb)-gammaln(pa) ...
         -qa.*log(qb)+gammaln(qa) ...
	 +(pa-qa).*(digamma(pa)-log(pb)) ...
	 -(pb-qb).*pa./pb ,2);