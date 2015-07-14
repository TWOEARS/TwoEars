%# store breakpoints
tmp = dbstatus('-completenames');
save('tmp.mat','tmp')

%# clear all
close all
clear classes %# clears even more than clear all
clear functions
clc

%# reload breakpoints
load('tmp.mat')
dbstop(tmp)

%# clean up
clear tmp
delete('tmp.mat')
