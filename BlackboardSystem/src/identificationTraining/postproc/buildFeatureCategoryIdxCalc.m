function [rowIdxCalc, names] = buildFeatureCategoryIdxCalc( fnameBuildSet, catIdx )

rowIdxCalc = [];
names = {};
for jj = 1 : 2 : size( fnameBuildSet, 2 )
    if ~isempty( fnameBuildSet{catIdx,jj} )
        rowIdxCalc(end+1) = max( 1, length( fnameBuildSet{catIdx,jj+1} ) );
        names{end+1} = fnameBuildSet{catIdx, jj};
    end
end
