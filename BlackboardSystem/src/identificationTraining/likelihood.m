function [R, llh] = likelihood(X, model)
mu = model.mu;
Sigma = model.Sigma;
w = model.weight;

g= gmdistribution(mu',Sigma,w);
R = pdf(g,X');
llh = log(R+eps);