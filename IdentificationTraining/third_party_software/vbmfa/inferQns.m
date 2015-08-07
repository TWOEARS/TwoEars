% inferQns.m : This script calculates the variational posterior for
% the class-conditional responsibilities for the data. It also removes
% from the model any components which have zero (or below threshold)
% total responsibility.

n = size(Y,2);
p = size(Y,1);
s = size(Lm,2);

allocprobs = sum(Qns,2);
Qns_old = Qns;
col = 0; logQns = [];
for t = 1:s
  col = col + 1;
  kt = size(Lm{t},2);
  LmpsiiLm = Lm{t}'*diag(psii+eps)*Lm{t};
  temp = LmpsiiLm + reshape(reshape(Lcov{t},kt*kt,p)*psii,kt,kt);

  logQns(:,col) = -.5*( +sum(Y.*(diag(psii+eps)*(Y-2*Lm{t}*Xm{t})),1)' ...
      +reshape(temp,kt*kt,1)'*reshape(Xcov{t},kt*kt,1) ...
      +sum( Xm{t}.*(temp*Xm{t}) ,1)' ...
      +trace(Xcov{t}(2:end,2:end)) ...
      +sum( Xm{t}(2:end,:).*Xm{t}(2:end,:) ,1)' ...
      -2*sum(log(diag(chol(Xcov{t}(2:end,2:end)+eps)))) ...
      );
end %t
  
logQns = logQns + ones(n,1)*digamma(u);
logQns = logQns - max(logQns,[],2)*ones(1,s);
Qns(:,1:s) = exp(logQns);
Qns(:,1:s) = Qns .* (  (allocprobs./sum(Qns,2)) * ones(1,s)  );

% check for any empty components, and remove them if allowed
if removal==1
  [dummy,empty_t] = find(sum(Qns,1) < 1 );
  num_died = size(empty_t,2);
  % if there exist components to remove, do so
  if num_died > 0
    remain = 1:size(Lm,2); remain(empty_t) = []; 
    fprintf('\nRemoving component: '); fprintf('%2i, ',empty_t);
    % ascertain if a cophd
    num_children = size(intersect(empty_t,[parent size(Lm,2)]),2);
    if num_children~=num_died
      cophd=0; % i.e. require reordering
    else
      if num_children == 1
	fprintf('\nChild of parent has died')
	cophd = 1;
	decleft = candorder(1:pos-1)>parent;
	decright = candorder(pos+1:end)>parent;
	if empty_t == parent
	  fprintf('\nDead component is original parent - need to change ordering');
	  fprintf('\nOld order'); fprintf(' %i',candorder);
	  decrement = candorder(1:pos-1)>parent;
	  candorder = [candorder(1:pos-1)-decleft size(Lm,2)-1 candorder(pos+1:end)-decright];
	  fprintf('\nNew order'); fprintf(' %i',candorder);
	else % empty_t == size(Lm,2)
	  fprintf('\nDead component is newly born - no change to component ordering');
	end
      end
      if num_children == 2
	cophd = 1;
	decleft = candorder(1:pos-1)>parent;
	decright = candorder(pos+1:end)>parent;
	fprintf('\nBoth children died - need to change ordering');
	fprintf('\nOld order'); fprintf(' %i',candorder);
	candorder = [candorder(1:pos-1)-decleft candorder(pos+1:end)-decright];
	fprintf('\nNew order'); fprintf(' %i',candorder);
	pos = pos-1; % because 2 components died.
      end
    end
    
    Lm = Lm(1,remain);
    Lcov = Lcov(1,remain);
    Xm = Xm(remain);
    Xcov = Xcov(remain);
    b = b(1,remain);
    u = u(remain);
    pu = pu(remain);
    s = size(remain,2);
    Qns = Qns(:,remain);
    inferQns % N.B. this may cause stacking.
  end
end

if size(Qns_old) == size(Qns)
  dQns = abs(Qns-Qns_old);
  dQns_sagit = (sum(dQns,1)./sum(Qns,1)); % The percentage absolute movement
else
  dQns_sagit = ones(1,size(Qns,2)); % i.e. 100% agitated
end

Qns = Qns./repmat(sum(Qns,2),[1 size(Qns,2)]);
Ps = sum(Qns,1)/size(Qns,1);