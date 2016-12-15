function Bprob = PredictiveDensity(x,model)
% if using VB-GMM from us
D= size(x,2);

alpha= model.MixWeight.Weight;
K=numel(alpha);

for k=1:K
kappa(k) = model.Gaussians(k).MeanPrec;
m(:,k) = model.Gaussians(k).Mean;
v(k) = model.Gaussians(k).WishartDF;
M(:,:,k) = model.Gaussians(k).WishartW; % Whishart: M = inv(W)
end

K=numel(alpha);
for k=1:K
    nu(k) = v(k)+1-D;
    L(:,:,k) = (nu(k)*kappa(k))/(1+kappa(k)).*(M(:,:,k));
    Sigma(:,:,k) = inv(L(:,:,k));
end
mu = m;
logP = [];
for k=1:K
logP = [logP, alpha(k)*mvtLogpdf(x, mu(:,1), Sigma(:,:,k), nu(k))];
end
Bprob = sum(logP,2)/sum(alpha);





% if using vbgmm 
% D= size(x,2);
% alpha = model.alpha;
% kappa = model.kappa;
% m = model.m;
% v = model.v;
% M = model.M; % Whishart: M = inv(W)
% 
% K=numel(alpha);
% for k=1:K
%     nu(k) = v(k)+1-D;
%     L(:,:,k) = (nu(k)*kappa(k))/(1+kappa(k)).*inv(M(:,:,k));
%     Sigma(:,:,k) = inv(L(:,:,k));
% end
% mu = m;
% logP = [];
% for k=1:K
% logP = [logP, alpha(k)*mvtLogpdf(x, mu(:,1), Sigma(:,:,k), nu(k))];
% end
% Bprob = sum(logP,2)/sum(alpha);
% 




