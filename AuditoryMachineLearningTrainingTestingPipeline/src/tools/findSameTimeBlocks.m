function [blockAnnotations,yt,yp,sameTimeIdxs] = findSameTimeBlocks( blockAnnotations,yt,yp )

[~,~,sameTimeIdxs] = unique( [blockAnnotations.blockOffset] );
for bb = 1 : max( sameTimeIdxs )
    [blockAnnotations(sameTimeIdxs==bb).allGtAzms] = deal( [blockAnnotations(sameTimeIdxs==bb).srcAzms] );
    if any( yt(sameTimeIdxs==bb) == 1 )
        [blockAnnotations(sameTimeIdxs==bb).posSnr] = deal( blockAnnotations(sameTimeIdxs==bb & yt==1).srcSNR2{1} );
    end
end

end

