% Fcalc.m : This script calculates the lower bound on the log evidence
% using the formula for $\cF$.

s = size(Lm,2);
p = size(Y,1);

Ps = sum(Qns,1)/n;
F_old = F;

Fmatrix = zeros(6,s);
tempdig_a = digamma(a);
tempdig_u = digamma(u);
tempdig_usum = digamma(sum(u,2));
pu = alpha/s *ones(1,s);
Qnsmod = Qns; Qnsmod(find(Qnsmod==0)) = 1;

FmatrixKLpi = -kldirichlet(u,pu);

for t = 1:s
  kt = size(Lm{t},2);
  temp_alt = Xm{t}.*repmat(Qns(:,t)',kt,1);
  Xcor_t_Qns_weighted = Xcov{t}*sum(Qns(:,t),1)  +  Xm{t}*temp_alt';
  
  Fmatrix(2,t) = +sum( Qns(:,t).*( -log(Qnsmod(:,t)) +ones(n,1)*(tempdig_u(t)-tempdig_usum) ) );
  
  Fmatrix(3,t) = +.5*n*(kt-1)*Ps(t) ...
      -.5*trace( Xcor_t_Qns_weighted(2:end,2:end) ) ...
      +.5*n*Ps(1,t)*( ...
      2*sum(log(diag(chol(Xcov{t}(2:end,2:end))))) );
      
  Fmatrix(4,t) = -.5*n*Ps(t)*( -log(det(diag(psii))) +p*log(2*pi) ) ...
      -.5*trace( Lm{t}'*diag(psii)*Lm{t} * Xcor_t_Qns_weighted ) ...
      -.5*trace( reshape(reshape(Lcov{t},kt*kt,p)*psii,kt,kt) * Xcor_t_Qns_weighted ) ...
      -.5*trace( diag(psii)* ((ones(p,1)*Qns(:,t)').*Y) * (Y-2*Lm{t}*Xm{t})' );
  
  Fmatrix(6,t) = -klgamma([a],[b{t}],pa,pb);
end

% Fmatrix(1,:) reimplementation
for t = 1:s
  f1 = 0;
  priorlnnum{t} = [log(nu_mcl) repmat(tempdig_a-log(b{t}),[p 1])];
  priornum{t} = [nu_mcl repmat(a./b{t},[p 1])];
  f1 = f1 + sum(sum(priorlnnum{t}));
  for q = 1:p
    f1 = f1 + log(det(Lcov{t}(:,:,q))) - size(Lcov{t}(:,:,q),1);
    f1 = f1 - ( diag(Lcov{t}(:,:,q))'+Lm{t}(q,:).^2 ) * priornum{t}(q,:)';
    f1 = f1 - priornum{t}(q,1)*( -2*Lm{t}(q,1)*mean_mcl(q,1) + mean_mcl(q,1).^2);
  end
  Fmatrix(1,t) = f1/2;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

F = sum(sum(Fmatrix)) + FmatrixKLpi;
dF = F-F_old; 
Fhist = [Fhist; it F];
