function createTFfigure( tfData, cm, clim )

if nargin < 2 || isempty( cm ), cm = 'parula'; end
if nargin < 3 || isempty( clim )
    cl{1} = 'CLimMode';
    cl{2} = 'auto';
else
    cl{1} = 'CLimMode';
    cl{2} = 'manual';
    cl{3} = 'CLim';
    cl{4} = clim;
end

figure1 = figure;
colormap( cm );

axes1 = axes( 'Parent', figure1 );
hold( axes1, 'on' );

image( tfData, 'Parent', axes1, 'CDataMapping', 'scaled' );

xlabel('t/s');
ylabel('f/Hz');
xlim(axes1,[0.5 100.5]);
ylim(axes1,[0.5 32.5]);

box(axes1,'on');

set( axes1, 'FontSize', 12, 'Layer', 'top',...
    'XTick', [10,20,30,40,50,60,70,80,90,100], ...
    'XTickLabel', {'0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'}, ...
    'YTick', [1 8 16 24 32], 'YTickLabel', {'80','242','572','1131','8000'}, ...
    cl{:} );

%colorbar( 'peer', axes1 );

