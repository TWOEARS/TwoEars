function azimuthsSurrey = convertAzimuthsWP1ToSurrey(azimuthsWP1)
%convertAzimuthsWP1ToSurrey Converts to the Surrey azimuth convention.
% 
%   This function converts the 0:359 counter-clockwise azimuth convention 
%   used in WP1 code (0:front, 90:left, 180:back, 270:right) to the 
%   -179:180 clockwise azimuth convention used in the Surrey BRIR 
%   recordings (0:front, -90:left, 180:back, 90:right)
%   
%USAGE
%   azimuthsSurrey = convertAzimuthsWP1ToSurrey(azimuthsWP1)
%
%INPUT ARGUMENTS
%     azimuthsWP1    : a vector of azimuths in the WP1 convention
%
%OUTPUT ARGUMENTS
%     azimuthsSurrey : a vector of azimuths in the Surrey convention
%


azimuthsSurrey = zeros(size(azimuthsWP1));
azimuthsSurrey(azimuthsWP1<180) = -azimuthsWP1(azimuthsWP1<180);
azimuthsSurrey(azimuthsWP1>=180) = 360 - azimuthsWP1(azimuthsWP1>=180);
