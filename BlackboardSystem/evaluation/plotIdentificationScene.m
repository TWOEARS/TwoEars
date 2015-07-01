function fig = plotIdentificationScene( scenewav, scenedesc, identityHypotheses, bbscene )

fig = figure( 'Name', 'testscene' ); 
axes1 = axes( 'Parent', fig, 'YTickLabel', {}, 'YTick', zeros(1,0) );
hold( axes1,'all' );
xlabel( 'time (s)' );

[scene, fs] = audioread( scenewav );
x = (1:length(scene))./fs;
l = zeros( size(x) );
for i = 1:size(scenedesc,1)
    name = scenedesc{i,3};
    on = floor( scenedesc{i,3} * fs );
    off = min( length(x), floor( scenedesc{i,4} * fs ) );
    l(on:off) = max(scene)+0.02;
    text( scenedesc{i,3}, max(scene)+0.03, name, 'Parent',axes1, 'BackgroundColor',[.6 .8 .6] );
end

plot( x, scene, 'Parent', axes1, 'DisplayName', 'signal' );
plot( x, l, 'Parent', axes1, 'DisplayName', 'true labels', 'Color',[.6 .8 .6], 'LineWidth', 2 );

e = zeros( size(x) );
if nargin > 2
    oldname = '';
    for n = 1:length( identityHypotheses )
        ident = identityHypotheses(n);
        shiftSamples = bbscene.frameShift;
        name = ident.getIdentityText();
        on = (ident.blockNo-1)*shiftSamples +1;
        off = min( length(x), ident.blockNo*shiftSamples );
        e(on:off) = min(scene)-0.02;
        if ident.blockNo~=1  &&  (e(on-1) == e(on))  &&  strcmp( oldname, name ) %adjacent blocks labeled the same
            continue;
        end
        text( on / fs, min(scene)-0.03, name, 'Parent',axes1, 'BackgroundColor',[.8 .6 .6] );
        oldname = name;
    end
end
plot( x, e, 'Parent', axes1, 'DisplayName', 'estimated labels', 'Color',[.8 .6 .6], 'LineWidth', 2 );

legend1 = legend( axes1,'show' );
set( legend1,'Location','EastOutside' );

title( 'testscene' );
