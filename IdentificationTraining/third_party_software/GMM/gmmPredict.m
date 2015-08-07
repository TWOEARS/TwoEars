function [pred, score ] = gmmPredict( x, model1, model0 )
% x: matrix of data points
% y: vector of true labels of x
%
% pred: predicted labels (+1, -1)
% val: Balanced accuracy
% llh: log-likelihoods of model1 and model0

% ML-EM approach
[~,~,~,llh1] =cluster(model1,x);
[~,~,~,llh0] =cluster(model0,x);
pred = repmat(-1,size(llh1,1),1);
pred(llh1>llh0)=1;

score = llh1./(llh1+llh0);



