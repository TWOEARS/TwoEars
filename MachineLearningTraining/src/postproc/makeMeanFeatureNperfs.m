function [lambdas,ncoefs,perfs,stds] = makeMeanFeatureNperfs(lambdasAr,ncoefsAr,...
                                                             perfsAr,...
                                                             fs1lAr, fs3lAr)

allNs = [];
for ii = 1 : numel( lambdasAr )
    lnp{ii} = sortrows( [lambdasAr{ii}, ncoefsAr{ii}, perfsAr{ii}'], [2 -1] );
    lnp{ii}(lnp{ii}(:,2)==0,:) = [];
    fs1N{ii} = lnp{ii}(lnp{ii}(:,1)==fs1lAr{ii},2);
    fs3N{ii} = lnp{ii}(lnp{ii}(:,1)==fs3lAr{ii},2);
    [~,uniqueNcoefs] = unique(lnp{ii}(:,2));
    lnp{ii} = lnp{ii}(uniqueNcoefs,:);
    allNs = unique( [allNs lnp{ii}(:,2)']);
end

