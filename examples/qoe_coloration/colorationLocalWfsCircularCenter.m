function colorationLocalWfsCircularCenter()

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
humanLabelFiles = strcat('experiments/2015-10-05_localwfs_coloration/', { ...
    'human_label_coloration_localwfs_circular_center_noise.csv'; ...
    'human_label_coloration_localwfs_circular_center_music.csv'; ...
    'human_label_coloration_localwfs_circular_center_speech.csv'; ...
    });
conditions = {'ref', 'anchor', 'Stereo', 'WFS', 'NFC-HOA', 'LWFS 30cm', ...
              'LWFS 60cm', 'LWFS 90cm', 'LWFS 120cm', 'LWFS 180cm', 'LWFS 240cm'};
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
saveColoration('localwfs', 'circular', 'center', prediction, sourceTypes, humanLabelFiles);

% vim: set sw=4 ts=4 et tw=90:
