function colorationWfsLinearOffoffcenter()

startTwoEars('Config.xml');
addpath('common');

%% ===== Configuration ===================================================
sourceTypes = { ...
    'music'; ...
    'speech'; ...
    };
sourceFiles = strcat('stimuli/anechoic/aipa/', { ...
    'music1_48k.wav'; ...
    'speech_48k.wav'; ...
    });
humanLabelFiles = strcat('experiments/2015-10-01_wfs_coloration/', { ...
    'human_label_coloration_wfs_linear_offcenter_music.csv'; ...
    'human_label_coloration_wfs_linear_offcenter_speech.csv'; ...
    });
conditions = {'ref', 'stereo', '75 cm', '38 cm', '18 cm', '9 cm', '4 cm', '2 cm', ...
              'stereo center', 'anchor'};
colors = {'g','r'}; % Plot colors


%% ===== Main ============================================================
% Get Binaural Simulator object with common settings already applied,
% see common/setupBinauralSimulator.m
sim = setupBinauralSimulator();

% Run the Blackboard System and the ColorationKS to estimate the coloration rating,
% see common/estimateColoration.m
prediction = estimateColoration(sim, sourceFiles, sourceTypes, humanLabelFiles);

% Plot the ratings from the listening test together with the predictions,
% see common/plotColoration.m
plotColoration(prediction, sourceTypes, humanLabelFiles, conditions, colors);
title('linear array, offcenter position');

% Store prediction results in the same format as the human label files,
% see common/saveColoration.m
saveColoration('wfs', 'linear', 'offcenter', prediction, sourceTypes, humanLabelFiles);

% vim: set sw=4 ts=4 et tw=90:
