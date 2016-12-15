% Orbits round a object maintaining the elevation
% for a total of 'deg' degrees, taking 'steps' steps.
% 
%  orbit(handle-to-axis,deg,steps)
%
% Stolen from the Matlab Graphics book :-)
%
% M.Beal GCNU 13/04/1999.

function orbit(h,deg,steps)
[az el] = view;
rotvec = 0:deg/(steps-1):deg;
set(h,'CameraViewAngleMode','manual')
axis vis3d off
for i = 1:length(rotvec)
  view(h,[az+rotvec(i) el])
  drawnow
end
