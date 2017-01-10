% ordercands. This script orders the candidates according to
% a selection method.
%
% Please email m.beal@gatsby.ucl.ac.uk for more information.
%
% Matthew J. Beal

s = size(Lm,2);
n = size(Y,2);

s = s+1;
t = s;

selection_method = 4;
switch selection_method
  case 1
    parent = ceil(rand*(s-1));
  case 2
    parent = mod(rej_count-1,s-1)+1;
  case 3
    if size(Lm,2) == 1
      parent = t-1;
    else
      free_energy = -( sum(Fmatrix([2 3 4],:),1)./sum(Qns,1) + sum(Fmatrix([6 1],:),1) );
      beta = getbeta(free_energy);
      probs = exp(beta*free_energy);
      probs = probs/sum(probs,2);
      [val,parent] = max(cumsum(probs)>rand);
      [val,order] = sort(probs);
      fprintf('\nCreation order:'); fprintf(' %2i',fliplr(order))
      fprintf(' ('); fprintf(' %0.3f',fliplr(probs(order))); fprintf(' )')
    end
  case 4
    free_energy = -( sum(Fmatrix([2 3 4],:),1)./sum(Qns,1) + sum(Fmatrix([6 1],:),1) );
    [dummy,candorder] = sort(free_energy);
    candorder = fliplr(candorder);
    fprintf('\nCreation order:'); fprintf(' %2i',candorder);
end

candorder = [candorder 0];

pos = 1;