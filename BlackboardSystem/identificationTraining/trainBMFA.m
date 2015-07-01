function [model1, model0, trVal] = trainBMFA( y, x, esetup )
% y: labels of x
% x: matrix of data points (+1 and -1!)
% esetup: training parameters
%
% model: trained gmm
% trVal: performance of trained model on training data

% inds = round(random('uni',1 ,size(y,1),1,round(size(y,1)*0.1)));
% x = x(inds,:);
% y= y(inds);

x1 = (x(y==1,:,:))';
if sum(sum(isnan(x1)))>0
    warning('there is some missing data that create NaN which are replaced by zero')
    x1(isnan(x1))=0;
end
%  [x1,~] = preprocess(x1);
model1 = vbmfa(x1,esetup.mfaK);
% [W Dim1 indexDimClus]=featureSelection(model1);
% model1.posFeature = x1;

x0 = (x(y==-1,:,:))';
if sum(sum(isnan(x0)))>0
    warning('there is some missing data that create NaN which are replaced by zero')
    x0(isnan(x0))=0;
end
% [x0,~] = preprocess(x0);
model0 = vbmfa(x0,esetup.mfaK);
% [Dim0 indexDimClus]=featureSelection(model0);

% model0.negFeature = x0;
% [~, trVal, ~,~,~,~] = BmfaPredict( x, model1, model0);
