function [model1, model0] = trainBGMMs( y, x, esetup )
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


x0 = (x(y~=1,:,:))';
if sum(sum(isnan(x0)))>0
    warning('there is some missing data that create NaN which are replaced by zero')
    x0(isnan(x0))=0;
end

[~, model1, L1] = vbgm(x1, esetup.nComp); %

[~, model0, L0] = vbgm(x0, esetup.nComp); %




% model1=init(GMMB(esetup.nComp),x1);
% model1=adapt(model1,x1,1000);
% 
% model0=init(GMMB(esetup.nComp),x0);
% model0=adapt(model0,x0,1000);