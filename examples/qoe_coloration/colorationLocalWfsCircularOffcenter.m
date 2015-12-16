function colorationLocalWfsCircularOffcenter()

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
    'human_label_coloration_localwfs_circular_offcenter_noise.csv'; ...
    'human_label_coloration_localwfs_circular_offcenter_music.csv'; ...
    'human_label_coloration_localwfs_circular_offcenter_speech.csv'; ...
    });
conditions = {'ref', 'anchor', 'Stereo', 'WFS', 'LWFS 60cm', 'Stereo off', ...
              'WFS off', 'NFC-HOA off', 'LWFS 30cm off', 'LWFS 60cm off', 'LWFS 90cm off'};
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
title('circular array, offcenter position');

% Store prediction results in the same format as the human label files,
% see common/saveColoration.m
saveColoration('localwfs', 'circular', 'offcenter', prediction, sourceTypes, humanLabelFiles);

% vim: set sw=4 ts=4 et tw=90:
