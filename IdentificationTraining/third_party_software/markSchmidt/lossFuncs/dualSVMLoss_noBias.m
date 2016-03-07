function [f,g] = dualSVMLoss_noBias(alpha,A,y)

f = (1/2)*alpha'*A*alpha - sum(alpha);
g = A*alpha - ones(size(alpha));