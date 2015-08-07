function [pred, score] = BmfaPredict( x, model1, model0 )
% x: matrix of data points
% y: vector of true labels of x
%
% pred: predicted labels (+1, -1)
% val: Balanced accuracy
% llh: log-likelihoods of model1 and model0


xc = x';
[~,llh1] = infer(xc,model1);
P1 = exp(llh1);
[~,llh0] = infer(xc,model0);
P0 = exp(llh0);

pred = repmat(-1,size(x,1),1);
pred(llh1'>llh0')=1;

score = llh1'./(llh1'+llh0');




