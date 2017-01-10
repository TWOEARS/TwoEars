function [bac,sens,spec,baca,sensa,speca] = getCmplRecEvalPerf( recEvalPerfs )

% 1 src, more balanced occurence of individual classes
sceneIdxs{1} = [1,9,32,2,11,33,5,5,5,5,5,5,5,5,5,5,7,17,13,13,13,13,15,41,43,48,15,41,43,48,19,38,20,21,24,49,24,49,24,49,24,49];
% 2 srcs
sceneIdxs{2} = [4,4,22,39,26]; % baby_piano, general_female, alarm_general
sceneIdxs{3} = [14,36,47,22,39,22,39,22,39,22,39,26,26,26]; % scream_baby, general_female, alarm_general
sceneIdxs{4} = [16,26,26]; % female_baby,alarm_general
sceneIdxs{5} = [22,39,22,39,22,39,28,26,26,26]; % general_female, baby_fire, alarm_general
sceneIdxs{6} = [25,50,25,50,25,50,28,26,26,26]; % male_female, baby_fire, alarm_general
% 3 srcs
sceneIdxs{7} = [3,6,23,31]; % baby_dog_fire, general_male_female
sceneIdxs{8} = [23,31,27]; % general_male_female, baby_female_general
sceneIdxs{9} = [3,6,27]; % baby_female_general, baby_dog_fire
% 4 srcs
sceneIdxs{10} = [18,37,42,44]; % fire_alarm_baby_female
sceneIdxs{11} = [29,34,46]; % baby_fire_alarm_scream
sceneIdxs{12} = [10,45,12,35,40]; % alarm_general_footsteps_fire, baby_male_female_scream
sceneIdxs{13} = [18,37,42,44,29,34,46]; % fire_alarm_baby_female, baby_fire_alarm_scream
sceneIdxs{14} = [29,34,46,10,45,12,35,40]; % baby_fire_alarm_scream, alarm_general_footsteps_fire, baby_male_female_scream
sceneIdxs{15} = [10,45,12,35,40,18,37,42,44]; % alarm_general_footsteps_fire, baby_male_female_scream, fire_alarm_baby_female

ba = [];
se = [];
sp = [];
for ii = 1 : numel( sceneIdxs )
    [ba(ii,:),se(ii,:),sp(ii,:)] = getLiveEvalPerf( recEvalPerfs, sceneIdxs{ii} );
end

bac(1,:) = ba(1,:); sens(1,:) = se(1,:); spec(1,:) = sp(1,:);

bac(2,:) = nanMean( ba(2:6,:), 1 ); 
sens(2,:) = nanMean( se(2:6,:), 1 ); 
spec(2,:) = nanMean( sp(2:6,:), 1 );

bac(3,:) = nanMean( ba(7:9,:), 1 ); 
sens(3,:) = nanMean( se(7:9,:), 1 ); 
spec(3,:) = nanMean( sp(7:9,:), 1 );

bac(4,:) = nanMean( ba(10:15,:), 1 ); 
sens(4,:) = nanMean( se(10:15,:), 1 ); 
spec(4,:) = nanMean( sp(10:15,:), 1 );

bac(5,:) = nanMean( bac(1:4,:), 1 ); 
sens(5,:) = nanMean( sens(1:4,:), 1 ); 
spec(5,:) = nanMean( spec(1:4,:), 1 );

baca = nanMean( bac, 2 );
sensa = nanMean( sens, 2 );
speca = nanMean( spec, 2 );
