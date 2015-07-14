function prinComps = featureSelectionPCA(x,thr)
if nargin<2
    thr = 0.9;
end
[~,comp, e] = princomp(x);
en = e/sum(e);
area = 0;
i=1;
if thr~=1
    while area<thr
        area = area + en(i);
        i = i+1;
    end
    ind = min(i,size(x,2));
    prinComps = comp(:,1:ind);
else
    prinComps = comp;
end


