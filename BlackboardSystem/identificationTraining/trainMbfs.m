function [model1, model0] = trainMbfs( y, x, esetup )
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
% [~, model1, llh1] = emgm(x1, esetup.initComps);
% model1.posFeature = x1;

x0 = real((x(y~=1,:,:))');
if sum(sum(isnan(x0)))>0
    warning('there is some missing data that create NaN which are replaced by zero')
    x0(isnan(x0))=0;
end
factorDim = 1;
mySetup.nIter = 6;
mySetup.minLLstep = 1E-3;
mySetup.TOLERANCE = 1E-1;
% ind = randperm(2*size(x1,2));
% x00 = x0(ind);
% x1 = preprocess(x1);
pDprior1 = init(MixtureFactorAnalysers(esetup.nComp),x1 ,factorDim);
[model1,LL1,r1] = adapt(pDprior1, x1 ,mySetup);
% x0 = preprocess(x0);
pDprior0 = init(MixtureFactorAnalysers(esetup.nComp),x0 ,factorDim);
[model0,LL0,r0] = adapt(pDprior0, x0 ,mySetup);


% model1 =  gmdistribution.fit(x1',esetup.nComp,'Options',options);
% model0 =  gmdistribution.fit(x0',esetup.nComp,'Options',options);


% [~, model0, llh0] = emgm(x0, esetup.initComps);
% model0.negFeature = x0;

% [~, trVal, ~,~,~,~] = gmmPredict( y, x, model1, model0);




