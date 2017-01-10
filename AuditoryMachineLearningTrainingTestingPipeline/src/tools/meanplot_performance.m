function meanplot_performance( name, labels, nvPairs, varargin )

% figure('Name', figTitle,'defaulttextfontsize', 12, ...
%        'position', [0, 0, sqrt(numel( varargin )*40000), 600]);

setlabels = isempty( labels );
for ii = 1 : numel( varargin )
    if setlabels
        labels{ii} = inputname( ii + 3 );
    end
end
    
if isempty( nvPairs )
    nvPairs = {'LineWidth', 2};
end

plot( cellfun(@mean,varargin), 'DisplayName', name, nvPairs{:} );

set( gca, 'XTick', 1:numel(labels), 'XTickLabel', labels );

ylabel( 'test performance' );
set( gca,'YGrid','on' );
% ylim( [(min([varargin{:}])-mod(min([varargin{:}]),0.10)) 1] );

% saveTitle = figTitle;
% savePng( saveTitle );
