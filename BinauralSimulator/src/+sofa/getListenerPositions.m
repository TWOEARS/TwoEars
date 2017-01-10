function [listenerPositions, idxM] = getListenerPositions(brir, idx, coordinateSystem)
%getListenerPositions returns the listener position from the given SOFA data set
%
%   USAGE
%       listenerPositions = getListenerPositions(brir, [idx], [coordinateSystem])
%
%   INPUT PARAMETERS
%       brir              - impulse response data set (SOFA struct/file)
%       idx               - index of listener positons (default: all)
%       coordinateSystem  - coordinate system the listener position should be
%                           specified in:
%                             'cartesian' (default)
%                             'spherical'
%
%   OUTPUT PARAMETERS
%       listenerPositions - listener positions
%       idxMeasurements   - logical vector, where 1 indicates the measurement positions
%                           that correspond to the selected listening positions.
%
%% argument check
if nargin == 1
    idx = ':';
    coordinateSystem = 'cartesian';
elseif nargin == 2
    if ischar(idx)
        coordinateSystem = idx;
        idx = ':';
    else
        coordinateSystem = 'cartesian';
    end
end

header = sofa.getHeader(brir);
listenerPositions = SOFAconvertCoordinates(header.ListenerPosition, ...
    header.ListenerPosition_Type, ...
    coordinateSystem);
% get unique listener positions
[listenerPositions, ~, idxUnique] = unique(listenerPositions, 'rows', 'stable');

if idx > size(listenerPositions,1)
    error(['index (%d) of listener positions exceeds number (%d) of unique', ...
      'listener positions'], idx, size(listenerPositions,1));
elseif ischar(idx) || size(listenerPositions,1) == 1
    % if there is only unique measure position, all measurements all including
    idxM = true(1, header.API.M);
else
    % select idx-th unique listener position
    listenerPositions = listenerPositions(idx, :);
    % generate binary mask
    idxM = any(bsxfun(@eq, idx(:), idxUnique(:).'), 1);
end

% vim: sw=4 ts=4 et tw=90:
