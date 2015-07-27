function m = angleMean(phi)
%angleMean returns the geometric mean of the provided angles
%
%   USAGE:
%       m = angleMean(phi)
%
%   INPUT PARAMETERS:
%       phi   - azimuth angle(s) in degree
%
%   OUTPUT PARAMETERS:
%       m     - mean angle
%
%   The mean is calculated by transforming the angles to unit vectors, averaging
%   them and transform the averaged vector back to an angle.

% Transform to unit vectors
[x,y,z] = sph2cart(phi./180*pi, zeros(size(phi)), ones(size(phi)));
m = mean(cart2sph(mean(x), mean(y), mean(z)))/pi*180;
