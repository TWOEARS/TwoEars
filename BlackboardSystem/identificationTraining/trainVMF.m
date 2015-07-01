function [model1, model0] = trainVMF( y, x, esetup )
% y: labels of x
% x: matrix of data points (+1 and -1!)
% esetup: training parameters
%
% model: trained gmm
% trVal: performance of trained model on training data

x1 = (x(y==1,:,:))';
if sum(sum(isnan(x1)))>0
    warning('there is some missing data that create NaN which are replaced by zero')
    x1(isnan(x1))=0;
end

pDprior=init(vMFMMB(esetup.initComps),x1);
[model1]=adapt(pDprior,x1, 5000, 'fixed',0.1);
% model1.posFeature = x1;

x0 = real((x(y~=1,:,:))');
if sum(sum(isnan(x0)))>0
    warning('there is some missing data that create NaN which are replaced by zero')
    x0(isnan(x0))=0;
end

pDprior=init(vMFMMB(esetup.initComps),x0);
[model0]=adapt(pDprior,x0, 5000, 'fixed',0.1);
% model0.negFeature = x0;

% [~, trVal, ~,~,~,~] = gmmPredict( y, x, model1, model0);




