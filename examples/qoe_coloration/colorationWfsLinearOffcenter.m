function colorationWfsLinearOffoffcenter()

addpath('common');

%% ===== Configuration ===================================================
sourceTypes = { ...
    'speech'; ...
    };
sourceFiles = strcat('experiments/2015-10-01_wfs_coloration/stimuli/', { ...
    'speech.wav'; ...
    });
resultFiles = strcat('experiments/2015-10-01_wfs_coloration/analysis/data_mean/', { ...
    'coloration_wfs_linear_offcenter_speech.csv'; ...
    });
conditions = {'ref', 'stereo', '75 cm', '38 cm', '18 cm', '9 cm', '4 cm', '2 cm', ...
              'stereo center', 'anchor'};
colors = {'r'}; % Plot colors


%% ===== Main ============================================================
% Get Binaural Simulator object with common settings already applied,
% see common/setupBinauralSimulator.m
sim = setupBinauralSimulator();

% Run the Blackboard System and the ColorationKS to estimate the coloration rating,
% see common/estimateColoration.m
prediction = estimateColoration(sim, sourceFiles, sourceTypes, resultFiles);

% Plot the ratings from the listening test together with the predictions,
% see common/plotColoration.m
plotColoration(prediction, sourceTypes, resultFiles, conditions, colors);
title('linear array, offcenter position');

% Store prediction results in the same format as the human label files,
% see common/saveColoration.m
saveColoration('wfs', 'linear', 'offcenter', prediction, sourceTypes, resultFiles);

% vim: set sw=4 ts=4 et tw=90:
