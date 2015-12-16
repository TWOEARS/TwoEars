function colorationWfsCircularCenter()

startTwoEars('Config.xml');
addpath('common');

%% ===== Configuration ===================================================
sourceTypes = { ...
    'noise'; ...
    'music'; ...
    'speech'; ...
    };
sourceFiles = strcat('stimuli/anechoic/aipa/', { ...
    'pnoise_pulse_48k.wav'; ...
    'music1_48k.wav'; ...
    'speech_48k.wav'; ...
    });
humanLabelFiles = strcat('experiments/2015-10-01_wfs_coloration/', { ...
    'human_label_coloration_wfs_circular_center_noise.csv'; ...
    'human_label_coloration_wfs_circular_center_music.csv'; ...
    'human_label_coloration_wfs_circular_center_speech.csv'; ...
    });
conditions = {'ref', 'stereo', '67 cm', '34 cm', '17 cm', '8 cm', '4 cm', '2 cm', ...
              '1 cm', 'anchor'};
colors = {'b','g','r'}; % Plot colors


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
title('circular array, center position');

% Store prediction results in the same format as the human label files,
% see common/saveColoration.m
saveColoration('wfs', 'circular', 'center', prediction, sourceTypes, humanLabelFiles);

% vim: set sw=4 ts=4 et tw=90:
