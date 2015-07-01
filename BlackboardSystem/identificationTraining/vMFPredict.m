function [pred] = vMFPredict( x, model1, model0 )
% x: matrix of data points
% y: vector of true labels of x
%
% pred: predicted labels (+1, -1)
% val: Balanced accuracy
% llh: log-likelihoods of model1 and model0

% ML-EM approach
xc = x';
 [llh1,~] = likelihoodVMF(xc,model1);
 [llh0,~] = likelihoodVMF(xc,model0);
pred = repmat(-1,size(llh1,1),1);
pred(llh1'>llh0')=1;
% val = validation_function(pred, y);


