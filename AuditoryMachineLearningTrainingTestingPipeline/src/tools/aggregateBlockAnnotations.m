function [ag, asgn] = aggregateBlockAnnotations( bap, yp, yt )

[ytIdxR,ytIdxC] = find( yt > 0 );
assert( numel( unique( ytIdxR ) ) == numel( ytIdxR ) ); % because I defined it in my test scripts: target sounds only on src1
isyt = false( size( bap, 1 ), 1 );
isyt(ytIdxR) = true;
isyp = any( yp > 0, 2 );

asgn(:,1) = isyp & isyt;
asgn(:,2) = ~isyp & ~isyt;
asgn(:,3) = isyp & ~isyt;
asgn(:,4) = ~isyp & isyt;

ag = bap(:,1);
[ag.nAct_segStream] = deal( nan );

% tmp = reshape( [bap.multiSrcsAttributability], size( bap ) );
% tmp = num2cell( nanMean( tmp, 2 ) );
% [ag.multiSrcsAttributability] = tmp{:};

if sum( isyt ) > 0
ytIdxs = sub2ind( size( yt ), ytIdxR, ytIdxC );
[ag(isyt).curSnr] = bap(ytIdxs).curSnr;
[ag(isyt).curNrj] = bap(ytIdxs).curNrj;
[ag(isyt).curNrjOthers] = bap(ytIdxs).curNrjOthers;
[ag(isyt).curSnr_db] = bap(ytIdxs).curSnr_db;
[ag(isyt).curNrj_db] = bap(ytIdxs).curNrj_db;
[ag(isyt).curNrjOthers_db] = bap(ytIdxs).curNrjOthers_db;
[ag(isyt).curSnr2] = bap(ytIdxs).curSnr2;
[ag(isyt).azmErr] = bap(ytIdxs).azmErr;
[ag(isyt).dist2bisector] = bap(ytIdxs).dist2bisector;
[ag(isyt).blockClass] = bap(ytIdxs).blockClass;
[ag(isyt).gtAzm] = bap(ytIdxs).gtAzm;
[ag(isyt).estAzm] = bap(ytIdxs).estAzm;
end

if sum( ~isyt ) > 0
tmp = reshape( double( [bap(~isyt,:).curSnr] ), size( bap(~isyt,:) ) );
[~,maxCurSnrIdx] = max( tmp, [], 2 );
nIdxs = sub2ind( size( yt ), find( ~isyt ), maxCurSnrIdx );
[ag(~isyt).curSnr] = bap(nIdxs).curSnr;
[ag(~isyt).curNrj] = bap(nIdxs).curNrj;
[ag(~isyt).curNrjOthers] = bap(nIdxs).curNrjOthers;
tmp = reshape( double( [bap(~isyt,:).curSnr_db] ), size( bap(~isyt,:) ) );
[~,maxCurSnrIdx] = max( tmp, [], 2 );
nIdxs = sub2ind( size( yt ), find( ~isyt ), maxCurSnrIdx );
[ag(~isyt).curSnr_db] = bap(nIdxs).curSnr_db;
[ag(~isyt).curNrj_db] = bap(nIdxs).curNrj_db;
[ag(~isyt).curNrjOthers_db] = bap(nIdxs).curNrjOthers_db;
tmp = reshape( double( [bap(~isyt,:).curSnr2] ), size( bap(~isyt,:) ) );
[~,maxCurSnrIdx] = max( tmp, [], 2 );
nIdxs = sub2ind( size( yt ), find( ~isyt ), maxCurSnrIdx );
[ag(~isyt).curSnr2] = bap(nIdxs).curSnr2;
[ag(~isyt).dist2bisector] = bap(nIdxs).dist2bisector;
[ag(~isyt).blockClass] = bap(nIdxs).blockClass;
[ag(~isyt).gtAzm] = bap(nIdxs).gtAzm;
[ag(~isyt).estAzm] = bap(nIdxs).estAzm;
[ag(~isyt).azmErr] = deal( nan );
end

end

function v = nanIfEmpty( v )
if isempty( v )
    v = nan;
end
end
