% Colours the data according to the responsibility split.
%
% This is not used, but you may want to call this (with a pause
% command), within the dobirth script (just uncomment the relevant
% line in dobirth.m).
%
% Matthew J. Beal

subplot('position',[.05 .05 .4 .9]);
qq = line(Lm{parent}(1,1)+[0 delta_vector(1)],Lm{parent}(2,1)+[0 delta_vector(2)]); set(qq,'linewidth',10);
hold on;
plot(Y(1,pos_ind),Y(2,pos_ind),'.r')
plot(Y(1,neg_ind),Y(2,neg_ind),'.b')
