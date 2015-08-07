% inferpsii.m : This script calculates the ML estimate for the
% hyperparameters of the sensor noise in the $\Psi$ matrix.

n = size(Y,2);
p = size(Y,1);
s = size(Lm,2);

psi = zeros(p); zeta = 0;

for t = 1:s
  kt = size(Lm{t},2);
  temp_alt = Xm{t}.*repmat(Qns(:,t)',kt,1);
  temp = Xcov{t}*sum(Qns(:,t),1)  +  Xm{t}*temp_alt';
  if pcaflag == 0
    psi = psi + (repmat(Qns(:,t)',p,1).*Y) * (Y-2*Lm{t}*Xm{t})' ...
	+ Lm{t}*temp*Lm{t}';
    for q = 1:p
      psi(q,q) = psi(q,q) + trace( Lcov{t}(:,:,q)*temp );
    end
  else
    zeta = zeta + ( + sum((Y.*(Y-2*Lm{t}*Xm{t}))*Qns(:,t),1) ...
	+ trace(Lm{t}*temp*Lm{t}') ...
	+ trace(sum(Lcov{t},3)*temp) ...
	);
  end
end

% psii is the inverse of the noise variances, and is a column vector.
% Note the PCA analogue produces isotropic noise with the averaged
% variance of the sensors in FA.

if pcaflag == 0
  psi = 1/n * psi;
  psii = 1./diag(psi);
  if any( (1./psii) < psimin )
    fprintf('psi threshold');
    psii(find(psii>(1./psimin))) = 1./psimin;
  end
else
  psii = n*p*ones(p,1)*zeta^-1;
end


