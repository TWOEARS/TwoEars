function timestr = buildCurrentTimeString( plusRnd )

timestr = arrayfun( @num2str, clock(), 'UniformOutput', false );
for ii = 1 : length( timestr )
    if str2num(timestr{ii}) < 10
        timestr{ii} = ['0' timestr{ii}];
    end
end
timestr = strcat( '.', timestr );
timestr = [timestr{:}];

if nargin > 0  && plusRnd
    rnd = randi( 900000, 1 ) + 99999;
    timestr = [timestr num2str(rnd)];
end

    