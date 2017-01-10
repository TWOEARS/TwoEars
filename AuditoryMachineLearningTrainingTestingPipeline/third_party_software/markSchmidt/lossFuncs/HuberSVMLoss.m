function [f,g,H] = HuberSVMLoss(w,X,y,t)
[n,p] = size(X);
f = 0;
g = zeros(p,1);
yhat = y.*(X*w);
ind1 = yhat <= t;
ind2 = yhat > t & yhat <= 1;
if any(ind1)
	f = f + sum((1-t)^2 + 2*(1-t)*(t-yhat(ind1)));
	g = g - X(ind1,:)'*(2)*(1-t)*y(ind1);
end
if any(ind2)
	f = f + sum((1-yhat(ind2)).^2);
	g = g - X(ind2,:)'*2*((1-yhat(ind2)).*y(ind2));
end