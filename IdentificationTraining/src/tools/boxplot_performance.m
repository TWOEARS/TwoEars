function boxplot_performance( figTitle, labels, cgroup, nvPairs, varargin )

figure('Name', figTitle,'defaulttextfontsize', 12, ...
       'position', [0, 0, sqrt(numel( varargin )*40000), 600]);

boxplot_grps( labels, cgroup, nvPairs, varargin{:} );

ylabel( 'test performance' );
set( gca,'YGrid','on' );
ylim( [(min([varargin{:}])-mod(min([varargin{:}]),0.10)) 1] );

saveTitle = figTitle;
savePng( saveTitle );
