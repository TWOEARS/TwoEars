% LegendreShiftPoly.m by Peter Roche, 12-08-2004
% Based on recurrence relation
% (n + 1)Pn+1 (x) - (1 + 2 n)(2 x - 1)Pn (x) + n Pn-1 (x) = 0

% Given nonnegative integer n, compute the 
% Shifted Legendre polynomial P_n. 
% Return the result as a vector whose mth
% element is the coefficient of x^(n+1-m).
% polyval(LegendreShiftPoly(n),x) evaluates P_n(x).


function pk = legendreShiftPoly(n)

if n==0 
    pk = 1;
elseif n==1
    pk = [2 -1]';
else
    
    pkm2 = zeros(n+1,1);
    pkm2(n+1) = 1;
    pkm1 = zeros(n+1,1);
    pkm1(n+1) = -1;
    pkm1(n) = 2;

    for k=2:n
        
        pk = zeros(n+1,1);

        for e=n-k+1:n
            pk(e) = (4*k-2)*pkm1(e+1) + (1-2*k)*pkm1(e) + (1-k)*pkm2(e);
        end
        
        pk(n+1) = (1-2*k)*pkm1(n+1) + (1-k)*pkm2(n+1);
        pk = pk/k;
        
        if k<n
            pkm2 = pkm1;
            pkm1 = pk;
        end
        
    end
    
end