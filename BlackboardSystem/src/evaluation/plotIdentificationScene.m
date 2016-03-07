function fig = plotIdentificationScene( axh, labels, onOffsets, identityHypotheses, timeRange )

set( axh, 'YLim', [0 1.1], 'XLim', timeRange );

persistent hlin;
persistent htext;
persistent textDone;
persistent hscores;
if isempty( hlin )
    hold( axh,'all' );
    title( axh, 'Identity Information' );
    xlabel( axh, 'time (s)' );
    hlin = line( [0 0], [0 0], ...
        'DisplayName', 'Ground Truth', 'LineWidth', 3, 'Color', [0 0 0], 'Parent', axh );
end
if isempty( hscores )
    hscores = containers.Map('KeyType','char','ValueType','any');
end
if isempty( textDone )
    htext = [];
    textDone = containers.Map('KeyType','double','ValueType','char');
end

set( hlin, 'XData', [0 0], 'YData', [0 0] );
%delete( htext );
%htext = [];

eventInTimeRange = ...
    ((onOffsets(:,1) >= timeRange(1)) & (onOffsets(:,1) <= timeRange(2)))  | ...
    ((onOffsets(:,2) >= timeRange(1)) & (onOffsets(:,2) <= timeRange(2)));
labelsTrunc = labels(eventInTimeRange);
onOffsetsTrunc = onOffsets(eventInTimeRange,:);
for ii = 1 : length(labelsTrunc)
    on = onOffsetsTrunc(ii,1);
    off = onOffsetsTrunc(ii,2);
    set( hlin, 'XData', [get( hlin, 'XData' ) on on off off], ...
               'YData', [get( hlin, 'YData' ) 0 1 1 0] );
    if ~(isKey( textDone, onOffsetsTrunc(ii,1) ) ...
            && strcmp( textDone(onOffsetsTrunc(ii,1)), labelsTrunc{ii} ))
        htext(end+1) = text( onOffsetsTrunc(ii,1), 1.03, labelsTrunc{ii}, 'Parent', axh );
        textDone(onOffsetsTrunc(ii,1)) = labelsTrunc{ii};
    end
end

idScores = getIdScores( identityHypotheses );
idLabels = sort( fieldnames( idScores ) );
for ii = 1 : numel( idLabels )
    if ~isKey( hscores, idLabels{ii} )
        hscores(idLabels{ii}) = ...
            plot( idScores.(idLabels{ii}).x, idScores.(idLabels{ii}).y, ...
            'Parent', axh, 'DisplayName', idLabels{ii}, 'LineWidth', 4, 'LineStyle', '--' );
    else
        set( hscores(idLabels{ii}), ...
            'XData', idScores.(idLabels{ii}).x, 'YData', idScores.(idLabels{ii}).y );
    end
end

persistent legend1;
if isempty( legend1 )
    legend1 = legend( axh, 'show' );
end

hold( axh, 'off' );

