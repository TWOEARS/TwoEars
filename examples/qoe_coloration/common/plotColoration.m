function plotColoration(predictions, sourceTypes, humanLabelFiles, conditions, colors)
%plotColoration plots coloration ratings from a listening test together with its
%               model predictions
%
%   USAGE
%       plotColoration(prediction, sourceTypes, humanLabelFiles, conditions,
%                      colors)
%
%   INPUT PARAMETERS
%       predictions     - matrix with model predictions
%       sourceTypes     - cell with audio source material names
%       humanLabelFiles - cell with human label file names
%       conditions      - cell with names of different conditions
%       colors          - cell with Matlab color names

figure
hold on;
for ii = 1:size(humanLabelFiles,1)
    humanLabels = readHumanLabels(humanLabelFiles{ii});
    errorbar(([humanLabels{:,2}]+1)./2, [humanLabels{:,3}]./2, ['o', colors{ii}]);
    p(ii) = plot(predictions(ii,:), ['-', colors{ii}]);
end
hold off;
axis([0 11 0 1]);
xlabel('System');
ylabel('Coloration');
set(gca, 'XTick', [1:10]);
set(gca, 'XTickLabel', conditions);
legend(p, sourceTypes, 'location', 'northwest');

% vim: set sw=4 ts=4 et tw=90:
