function plotLambdaNCoefsPerf( lambdas, ncoefs, perfs, stds, addTitle, fs1L, fs3L,...
                               svmFs1perf, svmFs3perf, svmOperf, svmoN, svmFs1std, svmFs3std, svmOstd)

if nargin < 4 || isempty( stds ), stds = zeros( size( perfs ) ); end
if size( perfs, 1 ) < size( perfs, 2 ), perfs = perfs'; end
if size( stds, 1 ) < size( stds, 2 ), stds = stds'; end

lnps = sortrows( [lambdas, ncoefs, perfs, stds], [2 -1] );
lnps(lnps(:,2)==0,:) = [];
fs1N = lnps(lnps(:,1)==fs1L,2);
fs3N = lnps(lnps(:,1)==fs3L,2);
[~,uniqueNcoefs] = unique(lnps(:,2));
lnps = lnps(uniqueNcoefs,:);

if nargin < 5, addTitle = ''; end

fig = figure('Name',['perf vs #features ' addTitle],'defaulttextfontsize', 12);
hold all;
hPlot = mseb( lnps(:,2)', lnps(:,3)', lnps(:,4)' );
ax = gca;
set( ax, 'XScale', 'log','FontSize',12 );
xlabel( '# of features' );
ylabel( 'test performance' );
% set( ax, 'XLim', [ncu(1), ncu(end)] );


plot( ax, [fs1N], [lnps(lnps(:,2)==fs1N,3)], 'bo','MarkerSize',10, 'LineWidth', 2 );
plot( ax, [fs3N], [lnps(lnps(:,2)==fs3N,3)], 'bd','MarkerSize',10, 'LineWidth', 2 );

svmLegend = {};
svmP = [];
svmN = [];
if nargin >= 11 && ~isempty( svmoN ) && ~isempty( svmOperf )
    if nargin >= 14 && ~isempty( svmOstd )
        errorbar( ax, [svmoN], [svmOperf], [svmOstd], 'gs','MarkerSize',10, 'LineWidth', 2 );
    else
        plot( ax, [svmoN], [svmOperf], 'gs','MarkerSize',10, 'LineWidth', 2 );
    end
    svmLegend{end+1} = 'O-svm';
    svmP(end+1) = svmOperf;
    svmN(end+1) = svmoN;
end
if nargin >= 8 && ~isempty( fs1N ) && ~isempty( svmFs1perf )
    if nargin >= 12 && ~isempty( svmFs1std )
        errorbar( ax, [fs1N], [svmFs1perf], [svmFs1std], 'go','MarkerSize',10, 'LineWidth', 2 );
    else
        plot( ax, [fs1N], [svmFs1perf], 'go','MarkerSize',10, 'LineWidth', 2 );
    end
    svmLegend{end+1} = 'fs1-svm';
    svmP(end+1) = svmFs1perf;
    svmN(end+1) = fs1N;
end
if nargin >= 9 && ~isempty( fs3N ) && ~isempty( svmFs3perf )
    if nargin >= 13 && ~isempty( svmFs3std )
        errorbar( ax, [fs3N], [svmFs3perf], [svmFs3std], 'gd','MarkerSize',10, 'LineWidth', 2 );
    else
        plot( ax, [fs3N], [svmFs3perf], 'gd','MarkerSize',10, 'LineWidth', 2 );
    end
    svmLegend{end+1} = 'fs3-svm';
    svmP(end+1) = svmFs3perf;
    svmN(end+1) = fs3N;
end
plot( ax, svmN, svmP, 'g--', 'LineWidth', 1 );

legend( {'glmnet', 'fs1-glmnet', 'fs3-glmnet', svmLegend{:}},'Location','Best' );

saveTitle = ['perfVsNf_' addTitle];
savePng( saveTitle );

