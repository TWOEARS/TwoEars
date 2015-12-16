function [predictedAzimuth, localisationError] = evaluateLocalisationResults(perceivedAzimuths, sourceAzimuth)
%displayLocalisationResults will print detailed information to the screen
%
%   USAGE:
%       displayLocalisationResults(perceivedAzimuths, sourceAzimuth)
%
%   INPUT PARAMETERS:
%       perceivedAzimuths    - as returned by Blackboard.getData('perceivedAzimuths')
%       sourceAzimuth        - actual physical position of sound source (optional)
%
%   OUTPUT PARAMETERS:
%       predictedAzimuth     - model prediction of azimuth position
%       localisationError    - localisation error compared to real physical position (only
%                              if sourceAzimuth was provided as input

if nargin<2
    sourceAzimuth = NaN;
end

relativeAzimuth = zeros(length(perceivedAzimuths),1);
score = zeros(length(perceivedAzimuths),1);
for m=1:length(perceivedAzimuths)
    relativeAzimuth(m) = perceivedAzimuths(m).data.relativeAzimuth;
    score(m) = perceivedAzimuths(m).data.score;
end

% Use three time blocks
nBlocks = min(length(perceivedAzimuths)-1, 3);
if nBlocks == 0
    idx = 0;
else
    % Sort, starting with the highest score
    [~, idx] = sort(score(2:end), 'descend');
    % Calculate mean perceived azimuth over those time blocks
    idx = idx(1:nBlocks);
end
predictedAzimuth = angleMean(relativeAzimuth(idx+1));
localisationError = localisationErrors(sourceAzimuth, predictedAzimuth);

% vim: set sw=4 ts=4 et tw=90:
