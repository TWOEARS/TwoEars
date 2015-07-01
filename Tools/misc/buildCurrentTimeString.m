function timestr = buildCurrentTimeString()

timestr = arrayfun( @num2str, clock(), 'UniformOutput', false );
for ii = 1 : length( timestr )
    if length(timestr{ii}) == 1
        timestr{ii} = ['0' timestr{ii}];
    end
end
timestr = strcat( '.', timestr );
timestr = [timestr{:}];
