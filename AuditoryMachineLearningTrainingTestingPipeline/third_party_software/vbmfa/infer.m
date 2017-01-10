% This function takes as input a test data set, hyperparameters and
% parameters of a model, and outputs the inferred hidden state
% posterior as well as a calculation of the lower bound for the
% evidence for the test data.
%
% ensure data is preprocessed using same 'ppparams' as was used on
% training set.
%
% [tehidden,F] = infer(Ytest,net);

function [tehidden,Ftest] = infer(Y,net);

psii = net.hparams.psii;
pa = net.hparams.pa;
pb = net.hparams.pb;
alpha = net.hparams.alpha;
Lm = net.params.Lm;
Lcov = net.params.Lcov;
u = net.params.u;

s = size(Lm,2);
n = size(Y,2); p = size(Y,1);
allcomps
pa_mcl =pa; pb_mcl = 25*p;  pu = ones(1,s)/s;
tol = 6; dQns_sagit_tol = exp(-tol); removal = 0;

% calculate P for the test data. We can't find marginal for P
% analytically.  Content to report few terms of \cF as a lower bound
% for the log predictive density.

Qns = ones(n,s)/s;
inferQnu
allcomps
% No need to iteratively update posteriors QX and Qns, as QX posterior
% is not a function of Qns posterior.
inferQX
inferQns

% calculate last few terms of $\mathcal{F}$, i.e. terms 2, 3 and 4
Qnsmod = Qns; Qnsmod(find(Qnsmod==0)) = 1;
tempdig_u = digamma(u);
tempdig_usum = digamma(sum(u,2));
Ps = sum(Qns,1)/n;
Fmatrix = zeros(6,s);

for t = 1:s
  kt = size(Lm{t},2);
  temp_alt = Xm{t}.*repmat(Qns(:,t)',kt,1);
  Xcor_t_Qns_weighted = Xcov{t}*sum(Qns(:,t),1)  +  Xm{t}*temp_alt';
  n_Fmatrix(2,t,:) = + Qns(:,t).*( -log(Qnsmod(:,t)) +ones(n,1)*(tempdig_u(t)-tempdig_usum) );
  
  temppp = Lm{t}'*diag(psii+eps)*Lm{t} + reshape(reshape(Lcov{t},kt*kt,p)*psii,kt,kt);
  n_Fmatrix(3,t,:) = +.5*(kt-1)*Ps(t) ...
      -.5*trace(Xcov{t}(2:end,2:end))*Qns(:,t)' -.5*sum(Xm{t}(2:end,:).^2,1).*Qns(:,t)' ...
      +.5*Ps(t)*( log(det(Xcov{t}(2:end,2:end))) );
%   n_Fmatrix(4,t,:) = -.5*Ps(t)*( -log(det(diag(psii))+eps) +p*log(2*pi) ) ...
%       -.5*trace( Xcov{t} *temppp )*Qns(:,t)' ...
%       -.5*Qns(:,t)'.*sum(Xm{t}.*(temppp'*Xm{t}),1) ...
%       -.5*sum((diag(psii+eps)*(Y.*repmat(Qns(:,t)',p,1))).*(Y-2*Lm{t}*Xm{t}),1);
    n_Fmatrix(4,t,:) = -.5*Ps(t)* -sum(log(psii)) +p*log(2*pi)  ...
      -.5*trace( Xcov{t} *temppp )*Qns(:,t)' ...
      -.5*Qns(:,t)'.*sum(Xm{t}.*(temppp'*Xm{t}),1) ...
      -.5*sum((diag(psii+eps)*(Y.*repmat(Qns(:,t)',p,1))).*(Y-2*Lm{t}*Xm{t}),1);
end

Ftest = squeeze(sum(sum(n_Fmatrix,1),2))';

tehidden.Xm = Xm;
tehidden.Xcov = Xcov;
tehidden.Qns = Qns;
tehidden.a = a;
tehidden.b = b;