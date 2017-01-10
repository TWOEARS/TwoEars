clear;
close all
clc


%% CREATE INPUT SIGNAL
% 
% Get test input data
load('Test_signals/DEMO_Speech_Room_D.mat');

% Load default input parameter structure 
% For more details see afeRAA.m and RAA_param_configuration.m 
%   inside the 'src/Tools' folder
run RAA_param_configuration
% This creates a structure named parConf which can be used
%   as the input to the afeRAA function


%% PERFORM PROCESSING
% Note that afeRAA is a wrapper function based on AFE modules, not an AFE
%   processor so does not follow the convention of the other DEMO scripts
[par, psi] = afeRAA(earSignals, fsHz, parConf);


%% PLOT PART OF RESULTS
% The key output parameters are stored as par and 
%   some additional intermediate information as psi
% Here some intermediate internal representations are plotted for
%   demonstration purpose only

% Input signal
figure;
plot(psi.t_psi, earSignals);
xlim([psi.t_psi(1) psi.t_psi(end)]);
xlabel('Time (s)');
ylabel('Amplitude');
title('Input signal');
legend('left', 'right');

% Plot streams at about 1.4kHz CF for comparison
% For more info on the direct/reverberant streams
%   refer to the van Dorp Schuitman paper/thesis (see afeRAA.m)
figure;
subplot(3, 1, 1)
plot(psi.t_psi, psi.PsiL(:, 14));   % here index 14 corresponds to 1430 Hz CF
ylabel('MU');
title('\Psi_L (Adaptation loop output at 1430 Hz, left channel)');
subplot(3, 1, 2)
plot(psi.t_psi, psi.PsiLdir(:, 14));
ylabel('MU');
title('\Psi_{L,dir} (Direct stream at 1430 Hz, left channel)');
subplot(3, 1, 3)
plot(psi.t_psi, psi.PsiLrev(:, 14));
xlabel('Time (s)');
ylabel('MU');
title('\Psi_{L,rev} (Reverberant stream at 1430 Hz, left channel)');

fprintf(1,'\n\n');
disp('Estimated parameter:')
par
