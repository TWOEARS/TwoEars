function [predictedAzimuth, localisationError] = evaluateLocalisationResults(perceivedLocations, sourceAzimuth)
%displayLocalisationResults will print detailed information to the screen
%
%   USAGE:
%       displayLocalisationResults(perceivedLocations, sourceAzimuth)
%
%   INPUT ARGUMENTS:
%       perceivedLocations   - as returned by Blackboard.getData('perceivedLocations')
%       sourceAzimuth        - actual physical position of sound source

if nargin<2
    sourceAzimuth = NaN;
end

relativeLocation = zeros(length(perceivedLocations),1);
score = zeros(length(perceivedLocations),1);
for m=1:length(perceivedLocations)
    relativeLocation(m) = perceivedLocations(m).data.relativeLocation;
    score(m) = perceivedLocations(m).data.score;
end

% Use three time blocks
nBlocks = min(length(perceivedLocations)-1, 3);
if nBlocks == 0
    idx = 0;
else
    % Sort, starting with the highest score
    [~, idx] = sort(score(2:end), 'descend');
    % Calculate mean perceived location over those time blocks
    idx = idx(1:nBlocks);
end
predictedAzimuth = angleMean(relativeLocation(idx+1));
localisationError = localisationErrors(sourceAzimuth, predictedAzimuth);

% vim: set sw=4 ts=4 et tw=90:
