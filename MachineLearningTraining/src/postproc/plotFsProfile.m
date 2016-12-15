function plotFsProfile( labels, impacts, counts, addTitle, noFig, style )

if nargin < 4, addTitle = ''; end
if nargin < 5, noFig = false; end
if nargin < 6, style = 'bar'; end

if ~noFig
    fig = figure('Name',['Feature Profile ' addTitle],'defaulttextfontsize', 12);
end

nTotal = sum( counts );
switch style
    case 'bar'
        hold all;
        hPlot = bar( impacts, 'FaceColor', [0.3 0.3 0.3], 'EdgeColor', 'none' );
        ax = gca;
        labels = cellfun( @(c)(strcat( c(:)', '.' )), labels, 'UniformOutput', false );
        labels = cellfun( @(c)(strcat( c{:} )), labels, 'UniformOutput', false );
        set( ax, 'XTick', 1 : numel(labels), 'XTickLabel', labels, 'FontSize', 12, 'YGrid', 'on' );
        xlabel( 'feature grp' );
        ylabel( 'grp impact' );
        xlim( ax, [0 numel(labels)+1] );
        ylim( ax, [0 0.7] );
        rotateXLabels( ax, 90 );
        op = get( gca, 'OuterPosition');
        ip = get( gca, 'Position');
        annotation( gcf, 'textbox',...
            [ip(1)-0.1 op(2)-0.1 0.01 0.05],...
            'String',{['#total ' num2str(nTotal)]},...
            'FontSize',12,...
            'FitBoxToText','off',...
            'EdgeColor','none');
        
    case 'pie'
        hPlot = pie( impacts/sum(impacts), arrayfun(@num2str,round( impacts*100 )/100, 'UniformOutput', false) );
        op = get( gca, 'OuterPosition');
        ip = get( gca, 'Position');
        legend( cellfun( @(c)(c), labels ), 'Location', [ip(1)+0.05 op(2)-0.07 0.1 0.1] );
        annotation( gcf, 'textbox',...
            [ip(1)-0.1 op(2) 0.01 0.05],...
            'String',{['#total ' num2str(nTotal)]},...
            'FontSize',12,...
            'FitBoxToText','off',...
            'EdgeColor','none');
end
        

% savePng( ['fsProf_' addTitle] );
