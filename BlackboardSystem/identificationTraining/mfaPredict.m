function [pred, llh1,llh0] = mfaPredict( x, model1, model0 )
% x: matrix of data points
% y: vector of true labels of x
%
% pred: predicted labels (+1, -1)
% val: Balanced accuracy
% llh: log-likelihoods of model1 and model0

% ML-EM approach
Lh1 = model1.Lh;
Ph1 = model1.Ph;
Mu1 = model1.Mu;
Pi1 = model1.Pi;

Lh0 = model0.Lh;
Ph0 = model0.Ph;
Mu0 = model0.Mu;
Pi0 = model0.Pi;

[llh1, llh1v] = mfa_cl2(x,Lh1,Ph1,Mu1,Pi1);
[llh0, llh0v] = mfa_cl2(x,Lh0,Ph0,Mu0,Pi0);

pred = repmat(-1,size(x,1),1);
pred(llh1v'>llh0v') = 1;




