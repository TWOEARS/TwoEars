function boxplot_performance( figTitle, labels, cgroup, nvPairs, varargin )

if numel( varargin ) > 1 && ischar( varargin{1} ) && strcmpi( varargin{1}, 'fid' )
    fid = varargin{2};
    varargin(1:2) = [];
else
    fid = figure;
end
% set( fid, 'Name', figTitle,'defaulttextfontsize', 11, ...
%        'position', [0, 0, sqrt(numel( varargin )*40000), 600]);

boxplot_grps( labels, cgroup, nvPairs, varargin{:} );

ylabel( 'test performance' );
set( gca,'YGrid','on' );
ylim( [(min([varargin{:}])-mod(min([varargin{:}]),0.10)) 1] );

texts = findobj(gca,'Type','text');
set( texts,'FontSize',11, 'Interpreter', 'tex' );
textPos = get( texts, 'Position' );
textExt = cell2mat( get( texts, 'Extent' ) );
maxHeight = max( textExt(:,4) );
heightSaved = -textPos{1}(2) - maxHeight;
textPos = cellfun( @(c)([c(1) -maxHeight-4 0]), textPos, 'UniformOutput', false );
set( gca, 'Units', 'pixels' );
axesPos = get( gca, 'Position' );
axesPos(2) = axesPos(2) - heightSaved;
axesPos(4) = axesPos(4) + heightSaved;
set( gca, 'Position', axesPos );
for ii = 1 : numel( texts )
    set( texts(ii), 'Position', textPos{ii} );
end

fprintf( '\n' );
disp( figTitle );
for ii = 1 : numel( labels )
    fprintf( '\t%s -- mean: %f\n', labels{ii}, nanMean(varargin{ii}) );
end
fprintf( '\n' );
