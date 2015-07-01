function [pred] = BgmmPredict(x, model1, model0)
% x: matrix of data points
% y: vector of true labels of x
%
% pred: predicted labels (+1, -1)
% val: Balanced accuracy
% llh: log-likelihoods of model1 and model0

% Bayesian approach Using computing marginal likelihood
% not successful yet???!!!
% xc = x';
% mLLh1 = zeros(1,size(xc,2));
% mLLh0 = zeros(1,size(xc,2));
% for i=1:size(xc,2)
%     xcr = repmat(xc(:,1),1,size(xc,2));
%     mLLh1(i) = marginalLikelihood(xc,model1,esetup);
%     mLLh0(i) = marginalLikelihood(xc,model0,esetup);
% end

% Bayesian approach using computing the predictive density
% this should be the elgont way of doing this
% 
% logP1 = PredictiveDensity(x,model1);
% logP0 = PredictiveDensity(x,model0);
% 
% pred = repmat(-1,size(x,1),1);
% pred(logP1'>logP0')=1;
% 
% prob0 = 1./(1+exp(logP1-logP0));
% I = 1./(1+exp(logP0-logP1));

% 
xc = x';
[~, llh1] = Blikelihood(xc, model1);
[~, llh0] = Blikelihood(xc, model0);
pred = repmat(-1,size(llh1,1),1);
pred(llh1'>llh0')=1;


