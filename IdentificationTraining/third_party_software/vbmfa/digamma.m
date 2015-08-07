%res = digamma(x)
%
%Calculates the digamma function.
%
%Multiple evaluations should enter as a row vector.
%
%Thanks to Zoubin Ghahramani and Yw Teh for helping put this fast
%version together.
%
%Matthew J. Beal GCNU 06/02/01

function res=digamma(x);

coef=[-1/12 1/120 -1/252 1/240 -1/132 691/32760 -1/12];
krange = [1:7]';

y = ceil(max(0,6-x));

z = x + y;

logz = log(z);

res = logz - .5./z + coef*exp(-2*krange*logz) ...
      - (y>=1)./x - (y>=2)./(x+1) - (y>=3)./(x+2) - (y>=4)./(x+3) - ...
        (y>=5)./(x+4) - (y>=6)./(x+5);

return;

