function [p,names] = getLiveEvalSort( flist, classIdx, pmeas, perfOverview )

recName = {};
for ii = 1 : numel( flist )
    [~,recName{ii}] = fileparts( flist{ii} );
    recName{ii} = [recName{ii} num2str(ii)];
end

bacSort = [];
sensSort = [];
specSort = [];
for ii = 1 : numel( flist )
    [bacSort(ii,:),sensSort(ii,:),specSort(ii,:)] = getLiveEvalPerf( perfOverview, ii );
end

switch pmeas
    case 'bac'
        [p,sortIdxs] = sort( bacSort(:,classIdx) );
    case 'sens'
        [p,sortIdxs] = sort( sensSort(:,classIdx) );
    case 'spec'
        [p,sortIdxs] = sort( specSort(:,classIdx) );
end
names = recName(sortIdxs)';

