function idScores = getIdDecisions( identityHypotheses )

idScores = struct();
for ii = numel( identityHypotheses ) : -1 : 1
    off = identityHypotheses(ii).sndTmIdx;
    for jj = 1 : numel( identityHypotheses(ii).data )
        on = max( 0, off - identityHypotheses(ii).data(jj).concernsBlocksize_s );
        d = identityHypotheses(ii).data(jj).d;
        label = identityHypotheses(ii).data(jj).label;
        loc = identityHypotheses(ii).data(jj).loc;
        if isfield( idScores, label )
            if idScores.(label).x(1) == on && d == 1
                idScores.(label).y(1) = d;
                idScores.(label).loc = [{[loc,idScores.(label).loc{1}]} idScores.(label).loc(2:end)];
            elseif idScores.(label).x(1) ~= on
                idScores.(label).x = [on idScores.(label).x];
                idScores.(label).y = [d idScores.(label).y];
                if d == 1
                    idScores.(label).loc = [{loc} idScores.(label).loc];
                else
                    idScores.(label).loc = [{[]} idScores.(label).loc];
                end
            end
        else
            idScores.(label).x = [on off];
            idScores.(label).y = [d d];
            if d == 1
                idScores.(label).loc = {loc loc};
            else
                idScores.(label).loc = {[] []};
            end
        end
    end
end
