function [f,g] = OrdinalLogisticLoss(w,X,y,k)
% w(feature,1)
% X(instance,feature)
% y(instance,1): range from 1 to k
% k: number of orders
[n,p] = size(X);
nVars = length(w);
gamma = [-inf;0;cumsum(w(p+1:end));inf];
w = w(1:p);

L = F(gamma(y+1) - X*w) - F(gamma(y) - X*w);
f = -sum(log(L));

if nargout > 1
   g = zeros(nVars,1);
   
   % Derivative wrt w
   sigm1 = F(gamma(y+1) - X*w);
   sigm2 = F(gamma(y) - X*w);
   inner = (sigm1.*(1-sigm1) - sigm2.*(1-sigm2))./L;
   g(1:p) = X'*inner;

   % Derivative wrt gamma
   for i = 1:n
      if y(i) >= 3
         g(p+1:p+y(i)-2) = g(p+1:p+y(i)-2) + sigm2(i)*(1-sigm2(i))/L(i);
      end
      if y(i)+1 >= 3 && y(i)+1 <= k
          g(p+1:p+y(i)+1-2) = g(p+1:p+y(i)+1-2) - sigm1(i)*(1-sigm1(i))/L(i);
      end
   end
end
end

function [sigm] = F(x)
    sigm = 1./(1+exp(-x));
end