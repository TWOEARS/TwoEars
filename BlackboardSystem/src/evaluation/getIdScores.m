function idScores = getIdScores( identityHypotheses )

idScores = struct();
for ii = numel( identityHypotheses ) : -1 : 1
    off = identityHypotheses(ii).sndTmIdx;
    for jj = 1 : numel( identityHypotheses(ii).data )
        on = max( 0, off - identityHypotheses(ii).data(jj).concernsBlocksize_s );
        score = identityHypotheses(ii).data(jj).p;
        label = identityHypotheses(ii).data(jj).label;
        if isfield( idScores, label )
            idScores.(label).x = [on idScores.(label).x];
            idScores.(label).y = [score idScores.(label).y];
        else
            idScores.(label).x = [on off];
            idScores.(label).y = [score score];
        end
    end
end
