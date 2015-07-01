
function plot_localisation_errors(label)
% label: 'clean', '0dB'

load(strcat('localisation_errors_GMM_', label));
hold off
errorbar(mean(locErrors,2), std(locErrors,0,2), 'Marker','*', 'LineStyle','--', 'LineWidth', 1, 'Color',[0.36 0.4 0.6]);
ymax = max(30, max(mean(locErrors,2)+std(locErrors,0,2)));

load(strcat('localisation_errors_BB_', label));
hold on
errorbar(mean(locErrors,2), std(locErrors,0,2), 'Marker','o', 'LineStyle','--', 'LineWidth', 1, 'Color',[0.8 0.2 0]);
ymax = max(ymax, max(mean(locErrors,2)+std(locErrors,0,2)));

h = legend('GMM Baseline', 'Proposed Blackboard');
set(h,'FontSize',14);

nPos = length(srcPositions);

axis([0.5 nPos+0.5 -5 ceil(ymax/10)*10]);
    
set(gca,'XTick',1:nPos,'XTickLabel', srcPositions, 'FontSize', 14);
xlabel('Target source azimuth (degrees)','FontSize',14);
ylabel('Localization Errors (degrees)','FontSize',14);

plot([0.5 nPos+0.5], [0 0], 'k:');

