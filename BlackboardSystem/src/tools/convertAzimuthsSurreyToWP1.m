function azimuthsWP1 = convertAzimuthsSurreyToWP1(azimuthsSurrey)
%convertAzimuthsSurreyToWP1 Converts to the WP1 azimuth convention.
% 
%   This function converts the -179:180 clockwise azimuth convention used 
%   in the Surrey BRIR recordings (0:front, -90:left, 180:back, 90:right) 
%   to the 0:359 counter-clockwise azimuth convention used in WP1 code 
%   (0:front, 90:left, 180:back, 270:right) 
%   
%USAGE
%   azimuthsWP1 = convertAzimuthsSurreyToWP1(azimuthsSurrey)
%
%INPUT ARGUMENTS
%     azimuthsSurrey : a vector of azimuths in the Surrey convention
%
%OUTPUT ARGUMENTS
%     azimuthsWP1    : a vector of azimuths in the WP1 convention
%

azimuthsWP1 = zeros(size(azimuthsSurrey));
azimuthsWP1(azimuthsSurrey<=0) = -azimuthsSurrey(azimuthsSurrey<=0);
azimuthsWP1(azimuthsSurrey>0) = 360 - azimuthsSurrey(azimuthsSurrey>0);
