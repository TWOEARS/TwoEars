function [mAve, indexDimAve, indexDimClus]=featureSelection(model,limit)
% thr: threshold between 0 and 1
% Jalil Taghia
km = size(model.params.u,2);  % number of remaining components
dim = size(model.params.Lcov{1},3);          % original dimensionality

if nargin<2
    limit = .5;
end
for j=1:km
    for i=1:dim
        mm(i,j)=sum(diag((model.params.Lcov{j}(:,:,i))));
    end
    mn(:,j) = model.params.u(j)* mm(:,j)/sum( model.params.u(j)*mm(:,j));
    thr = limit/dim;
    indexDimClus{j} = find(mn(:,j)>thr);
    
    mAve = sum(mn,2)/sum(sum(mn,2));
    indexDimAve = find(mAve>thr);
end
figure;
% plot(mn,'.-')
plot(mAve,'.-')

hold on; plot(thr*ones(1,dim),'--k')
ylabel('weight')
xlabel('dimension')
title('contribution of each feature dimension')
% figure;
% plot(sum(mn,2)/sum(sum(mn,2)));
% 
