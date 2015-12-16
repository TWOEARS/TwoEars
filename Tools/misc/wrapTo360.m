function phi = wrapTo360(phi)
%wrapTo360 Wrap angle in degrees to [0 360]
%
% USAGE:
%   phi = wrapTo360(phi)
%
% INPUT PARAMETERS:
%   phi - azimuth angle in deg
%
% OUTPUT PARAMETERS:
%   phi - azmuth angle in deg
%
narginchk(1, 1);
% Ensure 0 <= phi <= 360
phi = mod(phi, 360);

% vim: set sw=4 ts=4 expandtab textwidth=90 :
