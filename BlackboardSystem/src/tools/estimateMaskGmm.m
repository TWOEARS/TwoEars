function [mask, logLikelihood] = estimateMaskGmm(data, gmm_x, gmm_n)
% estimateMaskGmm   Estimate a soft mask using source GMMs
%
% 
%USAGE  
%  [mask, logLikelihood] = estimate_mask_GMM2(data, gmm_x, gmm_n)
%
%INPUT ARGUMENTS
%           data : Observed spectral data [nChannels x nFrames]
%          gmm_x : Target model (Netlab-format GMM)
%          gmm_n : Background noise model (Netlab-format GMM)
%
%OUTPUT ARGUMENTS
%           mask : Estimated soft mask [nDim x nFrames]
%  logLikelihood : Log likelihood
%
%
%The probability that the observed y_d belongs to Sx and not Sn is given by
%P(x_d=y_d|y) = P(x_d>n_d|y)
%
%             = \sum_{k_x,k_n} P(k_x,k_n|y) P(x_d>n_d|y_d,k_x,k_n)      (1)
%
%
%                Px(k_x) Pn(k_n) P(y|k_x,k_n)
%P(k_x,k_n|y) = ------------------------------
%                           P(y)
%
%                Px(k_x) Pn(k_n) \prod_d P(y_d|k_x,k_n)
%             = ----------------------------------------                (2)
%                                P(y)

%
%                          P(x_d=y_d,n_d<y_d|k_x,k_n)
%P(x_d>n_d|y_d,k_x,k_n) = ----------------------------
%                                P(y_d|k_x,k_n)
%
%                          Px(y_d|k_x) Cn(y_d|k_n)
%                       = -------------------------                     (3)
%                               P(y_d|k_x,k_n)
%
%Thus (1) becomes
%
%                                            Px(y_d|k_x) Cn(y_d|k_n)
%P(x_d=y_d|y) = \sum_{k_x,k_n} P(k_x,k_n|y) ------------------------- 
%                                                 P(y_d|k_x,k_n)
%
%                   Px(k_x) Pn(k_n) \prod_d P(y_d|k_x,k_n)   Px(y_d|k_x) Cn(y_d|k_n)
% = \sum_{k_x,k_n} ---------------------------------------- -------------------------  (4)
%                                  P(y)                          P(y_d|k_x,k_n)
%
%where
%P(y_d|k_x,k_n) = Px(y_d|k_x) Cy(y_d|k_n) + Cx(y_d|k_x) Py(y_d|k_n)     (5)
%
%

% Compute probabilities for the speech model Sx
[Px_y, Cx_y] = compute_likelihood_marginals(data, gmm_x);

% Compute probabilities for the noise model Sn
[Pn_y, Cn_y] = compute_likelihood_marginals(data, gmm_n);

K_x = gmm_x.ncentres;
K_n = gmm_n.ncentres;
[nChannels, nFrames] = size(data);

like = zeros(K_x * K_n, nFrames);
w = zeros(nChannels, nFrames, K_x, K_n);
for kx= 1:K_x
    % p1 = Px(y_d|k_x) Cn(y_d|k_n)
    p1 = bsxfun(@times, Cn_y, Px_y(:,:,kx));
    
    %p(y|kx,kn)= px(y|kx)Cn(n<=y|kn) + pn(y|kn)Cx(x<=y|kx)
    obsProb = p1 + bsxfun(@times, Pn_y, Cx_y(:,:,kx));
    
    %p(y|kx,kn)*Px(k_x)*Pn(k_n)
    like(kx:K_x:K_x*K_n,:) = bsxfun(@times, squeeze(prod(obsProb))', gmm_x.priors(kx)*gmm_n.priors');
    %like((kx-1)*Kn+1:kx*Kn,:)= like_kx;
    
    %w_d^{kx,kn}= Px(y_d|k_x)*Cn(y_d|k_n)/p(y_d)
    W = p1 ./ obsProb;
    W(isnan(W) | isinf(W)) = 0.5;  
    w(:,:,kx,:) = W;
end

postProb = bsxfun(@times, like, 1./sum(like));
postProb4d = reshape(postProb', [1 nFrames K_x K_n]);
mask = sum(sum(bsxfun(@times, w, postProb4d), 4), 3); 
mask(isnan(mask) | isinf(mask)) = 1;
mask(mask<0.01) = 0.01;
postProb(postProb<eps) = eps;
logLikelihood = sum(log(postProb));
logLikelihood = logLikelihood ./ size(postProb,1); % normalise by num mixtures

%subplot(211); imagesc(data); axis xy; title('Binaural Mixture'); colorbar
%subplot(212); imagesc(mask); axis xy; title('Soft mask'); colorbar



%--------------------------------------------------------------------------
function [Px_y, Cx_y] = compute_likelihood_marginals(data, gmm)
[nChannels, nFrames] = size(data);
nMix = gmm.ncentres;
Px_y = zeros(nChannels, nFrames, nMix); %Px(y|k)
Cx_y = zeros(nChannels, nFrames, nMix); %Px(x<=y|k)
for k = 1:nMix
    mu_k = repmat(gmm.centres(k,:)', 1, nFrames);
    if strcmp(gmm.covar_type,'diag')
        var_k = repmat(gmm.covars(k,:)', 1, nFrames);
    else
        var_k = repmat(diag(gmm.covars(:,:,k)), 1, nFrames);
    end

    Px_y(:,:,k) = probabilityMat(data, mu_k, var_k);
    Cx_y(:,:,k) = cumulativeProbMat(data, mu_k, var_k);
end


%--------------------------------------------------------------------------
function p = probability(x, x_mu, x_var)
invs = 1./sqrt(x_var);
z = invs.*(x-x_mu);
p = normPdf(z).*invs;


%--------------------------------------------------------------------------
function P = probabilityMat(X, X_mu, X_var)
Invs = 1./sqrt(X_var);
Z = (X-X_mu).*Invs;
P = normPdf(Z).*Invs;


%--------------------------------------------------------------------------
function p = cumulativeProb(x, x_mu, x_var)
z = (x-x_mu)./sqrt(x_var);
p = normCdf(z);


%--------------------------------------------------------------------------
function C= cumulativeProbMat(X, X_mu, X_var)
Z = (X-X_mu)./sqrt(X_var);
C = normCdf(Z);


%--------------------------------------------------------------------------
function p = normCdf(x)
p = 0.5 * erfc(-x/sqrt(2));


%--------------------------------------------------------------------------
function y = normPdf(x, mu, sigma)
y = exp(-0.5 * x.^2) ./ sqrt(2*pi);
