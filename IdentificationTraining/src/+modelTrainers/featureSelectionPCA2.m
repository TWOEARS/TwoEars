function [idFeature] = featureSelectionPCA2(x,thr)
if nargin<2
    thr = 0.9;
end
[PC,~, e] = princomp(x);
en = e/sum(e);
area = 0;
i = 1;
if thr~=1
    while area<thr
        area = area + en(i);
        i = i+1;
    end
    ind = min(i,size(x,2));
else
    ind = size(x,2);
end

r = PC(:,1)/sum(PC(:,1));
[~,idx]=sort(r,'descend');
idFeature = idx(1:ind);