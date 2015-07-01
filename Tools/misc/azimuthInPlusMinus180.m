function phi = azimuthInPlusMinus180(phi)
%azimuthInPlusMinus180 converts a given azimuth value to lie between -180°..180°
%
% USAGE:
%   phi = azimuthInPlusMinus180(phi)
%
% INPUT PARAMETERS:
%   phi - azimuth angle in deg
%
% OUTPUT PARAMETERS:
%   phi - azmuth angle in deg
%
narginchk(1, 1);
% Ensure -360 <= phi <= 360
phi = rem(phi, 360);
% Ensure -180 <= phi < 180
phi(phi<-180) = phi(phi<-180) + 360;
phi(phi>=180) = phi(phi>=180) - 360;

% vim: set sw=4 ts=4 expandtab textwidth=90 :
