% A scrappy script to display the performance so far, for a 2d or 3d
% data set.
%
% Matthew J. Beal

figure(1);

subplot('position',[.35 0.02 .3 .96]);
title('3sd ellipses for variance of means');
switch p
  case 2
    plot(Y(1,:),Y(2,:),'.w');
  case 3
    plot3(Y(1,:),Y(2,:),Y(3,:),'.w');
end
hold on;
h2 = zeros(1,size(Lm,2));
for t = 1:size(Lm,2);
  h2(t) = plot_gaussian(diag(squeeze(Lcov{t}(1,1,:)))*3^2,Lm{t}(:,1),t,15); hold on 
end
axis equal
axis off
hold off;

subplot('position',[.7 .55 .28 .4]);
title('History of F');
plot(Fhist(:,1),Fhist(:,2));
set(gca,'Fontsize',15); l1 = ylabel('{\bf F}');
set(l1,'FontSize',20,'rotation',0);
axis([0 it -2000 -500]);
subplot('position',[.7 .05 .28 .4]);
title('Mixing Proportions')
set(gca,'Fontsize',15);
bar(Ps);
l2 = ylabel('\pi_s');
set(l2,'FontSize',20,'rotation',0);
set(1,'doublebuffer','on')

orbh = subplot('position',[0.02 0.02 .3 .96]);
title('1sd ellipse for each analyser')
switch p
  case 2
    plot(Y(1,:),Y(2,:),'.w');
  case 3
    plot3(Y(1,:),Y(2,:),Y(3,:),'.w');
end
hold on;
h1 = zeros(1,size(Lm,2));
for t = 1:size(Lm,2);
  h1(t) = plot_gaussian(Lm{t}(:,2:end)*Lm{t}(:,2:end)'+diag(1./psii),Lm{t}(:,1),t,15); hold on 
end
axis equal
axis off
hold off;

view(orbh,375,38);
drawnow