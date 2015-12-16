function displayLocalisationResults(perceivedAzimuths, sourceAzimuth)
%displayLocalisationResults will print detailed information to the screen
%
%   USAGE:
%       displayLocalisationResults(perceivedAzimuths, sourceAzimuth)
%
%   INPUT PARAMETERS:
%       perceivedAzimuths    - as returned by Blackboard.getData('perceivedAzimuths')
%       sourceAzimuth        - actual physical position of sound source

if nargin<2
    sourceAzimuth = NaN;
end

fprintf('\n------------------------------------------------------------------------------------\n');
fprintf('Reference target angle: %3.0f degrees\n', sourceAzimuth);
fprintf('------------------------------------------------------------------------------------\n');
fprintf('Localised source angle:\n');
%fprintf('------------------------------------------------------------------------------------\n');
fprintf('BlockTime\tPerceivedAzimuth\t(head orient., relative azimuth)\tProbability\n');
fprintf('------------------------------------------------------------------------------------\n');

estAngles = zeros(length(perceivedAzimuths),1);

for m=1:length(perceivedAzimuths)
    fprintf('% 6.2f\t\t%3.0f degrees\t\t(%3.0f degrees,    %3.0f degrees)\t%.2f\n', ...
        perceivedAzimuths(m).sndTmIdx, ...
        perceivedAzimuths(m).data.relativeAzimuth, ...
        perceivedAzimuths(m).data.headOrientation, ...
        perceivedAzimuths(m).data.azimuth, ...
        perceivedAzimuths(m).data.score);
end
fprintf('------------------------------------------------------------------------------------\n');
[~, locError] = evaluateLocalisationResults(perceivedAzimuths, sourceAzimuth);
fprintf('Mean localisation error: %g\n', locError );
fprintf('------------------------------------------------------------------------------------\n\n');

% vim: set sw=4 ts=4 et tw=90:
