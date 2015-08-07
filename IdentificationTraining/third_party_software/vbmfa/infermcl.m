% infermcl.m : Infers the hyperparameters governing the mean
% (mean_mcl) and the precisions on the mean (nu_mcl) of all the factor
% loading matrices.

s = size(Lm,2);

if s>1
  temp_mcl = cat(3,Lm{:});
  temp_mcl = squeeze(temp_mcl(:,1,:)); % now p x s
  temp_Lcov = cat(4,Lcov{:,:,:});
  
  mean_mcl = mean(temp_mcl,2);
  nu_mcl = s./( sum(squeeze(temp_Lcov(1,1,:,:)),2) ... %squeeze gives p x s
      + sum(temp_mcl.^2,2) ...
      - 2*mean_mcl.*sum(temp_mcl,2) ...
      + s*mean_mcl.^2 );
end
