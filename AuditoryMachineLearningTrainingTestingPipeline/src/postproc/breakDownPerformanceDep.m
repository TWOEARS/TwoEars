function [bac,sens,spec] = breakDownPerformanceDep( counts, vars )

countsSummarizedDown = summarizeDown( counts, [vars, ndims( counts )] );
dimidxs = [ndims(countsSummarizedDown), 1 : ndims( countsSummarizedDown ) - 1];
countsSummarizedDown = permute( countsSummarizedDown, dimidxs );

dimidxs = size( countsSummarizedDown );
dimidxs(1) = [];
if numel( dimidxs ) == 1, dimidxs(end+1) = 1; end
tp = reshape( squeeze( countsSummarizedDown(1,:) ), dimidxs );
tn = reshape( squeeze( countsSummarizedDown(2,:) ), dimidxs );
fp = reshape( squeeze( countsSummarizedDown(3,:) ), dimidxs );
fn = reshape( squeeze( countsSummarizedDown(4,:) ), dimidxs );

sens = tp./(tp+fn);
spec = tn./(tn+fp);

bac = 0.5*sens + 0.5*spec;

end
