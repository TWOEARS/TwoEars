function fname = buildFname( fnameBuildSet, idx )

rowsBeforeIdxCount = 0;

for ii = 1 : size( fnameBuildSet, 1 )
    rowIdxCalc = buildFeatureCategoryIdxCalc( fnameBuildSet, ii );
    if idx <= rowsBeforeIdxCount + prod( rowIdxCalc )
        rowIdx = idx - rowsBeforeIdxCount;
        for kk = 1 : length( rowIdxCalc ) - 1
            rowIdxs(kk) = ceil( rowIdx / prod( rowIdxCalc(kk+1:end) ) );
            rowIdx = rowIdx - (rowIdxs(kk) - 1) * prod( rowIdxCalc(kk+1:end) );
        end
        rowIdxs(end+1) = rowIdx;
        fname = '';
        for kk = 1 : length( rowIdxCalc )
            if ~isempty( fnameBuildSet{ii,kk*2} )
                if isnumeric( fnameBuildSet{ii,kk*2} )
                    fname = [fname, ...
                        fnameBuildSet{ii,kk*2-1}, ...
                        num2str( fnameBuildSet{ii,kk*2}(rowIdxs(kk)) ), ...
                        ' '];
                else
                    fname = [fname, ...
                        fnameBuildSet{ii,kk*2-1}, ...
                        fnameBuildSet{ii,kk*2}{rowIdxs(kk)}, ...
                        ' '];
                end
            else
                fname = [fname, ...
                    fnameBuildSet{ii,kk*2-1}, ...
                    ' '];
            end
        end
        break;
    end
    rowsBeforeIdxCount = rowsBeforeIdxCount + prod( rowIdxCalc );
end