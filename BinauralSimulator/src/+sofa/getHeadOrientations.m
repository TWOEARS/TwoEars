function [phi, theta] = getHeadOrientations(brir, idx)
%getHeadOrientations returns azimuth and elevation from the given SOFA data set
%
%   USAGE
%       [phi, theta] = getHeadOrientations(brir, [idx])
%
%   INPUT PARAMETERS
%       brir    - impulse response data set (SOFA struct/file)
%       idx     - index of measurement for that orientation should be returned.
%                 If no index is specified all orientations will be returned.
%
%   OUTPUT PARAMETERS
%       phi     - head orientations in the horizontal plane / deg
%       theta   - head orientations in the median plane / deg
%
if nargin == 1, idx = ':'; end
header = sofa.getHeader(brir);
listenerView = SOFAconvertCoordinates(header.ListenerView, ...
                                      header.ListenerView_Type, 'spherical');
phi     = wrapTo360(listenerView(:, 1));
theta   = wrapTo180(listenerView(:, 2));
phi = phi(idx);
theta = theta(idx);
% vim: sw=4 ts=4 et tw=90:
