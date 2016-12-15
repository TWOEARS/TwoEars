function [pred, score] = BgmmPredict(x, model1, model0)
% x: matrix of data points
% y: vector of true labels of x
%
% pred: predicted labels (+1, -1)
% val: Balanced accuracy
% llh: log-likelihoods of model1 and model0


% 
xc = x';
[~, llh1] = Blikelihood(xc, model1);
[~, llh0] = Blikelihood(xc, model0);
pred = repmat(-1,size(llh1,1),1);
pred(llh1'>llh0')=1;

score = llh1'./(llh1'+llh0');


