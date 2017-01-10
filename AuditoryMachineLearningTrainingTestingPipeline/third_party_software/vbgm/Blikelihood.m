function [R, llh] = Blikelihood(X, model)
% BGMMM from us
% w= model.MixWeight.Mean;
% K=numel(w);
% for k=1:K
% kappa(k) = model.Gaussians(k).MeanPrec;
% mu(:,k) = model.Gaussians(k).Mean;
% v(k) = model.Gaussians(k).WishartDF;
% M(:,:,k) = nearestSPD(model.Gaussians(k).WishartW); % Whishart: M = inv(W)
% end

% using vbgmm
w = model.alpha/sum( model.alpha);
K=numel(w);
mu = model.m;
v = model.v;
kappa = model.kappa;
for k=1:K
M(:,:,k) = inv(model.M(:,:,k));
end
%....................................

for k=1:K
Sigma(:,:,k) =(v(k) * M(:,:,k))^-1;
end


g= gmdistribution(mu',Sigma,w);
R = pdf(g,X');
llh = log(R+eps);




