function [loudspeakerPositions, nLoudspeaker] = ...
            getLoudspeakerPositions(brir, idx, coordinateSystem)
%getLoudspeakerPositions returns loudspeaker positions from the given SOFA data set
%
%   USAGE
%       [loudspeakerPositions, nLoudspeaker] = ...
%           getLoudspeakerPositions(brir, [idx], [coordinateSystem])
%
%   INPUT PARAMETERS
%       brir              - impulse response data set (SOFA struct/file)
%       idx               - index of secondary sources that should be returned.
%                           If no index is specified all sources will be
%                           returned.
%       coordinateSystem  - coordinate system the position and direction of the
%                           secondary sources should be specified in:
%                             'cartesian' (default)
%                             'spherical'
%
%   OUTPUT PARAMETERS
%       loudspeakerPositions - loudspeaker positions [n 7]
%       nLoudspeaker         - number of loudpseakers
%
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

switch header.GLOBAL_SOFAConventions
case 'SimpleFreeFieldHRIR'
    % For free field HRTFs the source positions are equivalent to the apparent
    % positons of the sources
    apparentDirections = SOFAcalculateAPV(header);
    loudspeakerPositions = SOFAconvertCoordinates(apparentDirections, ...
                                                  'spherical', 'cartesian');
    %
case {'MultiSpeakerBRIR', 'SingleRoomDRIR'}
    sourcePosition = SOFAconvertCoordinates(header.SourcePosition, ...
                                            header.SourcePosition_Type, 'cartesian');
    emitterPositions = SOFAconvertCoordinates(header.EmitterPosition, ...
                                              header.EmitterPosition_Type, 'cartesian');
    loudspeakerPositions = bsxfun(@plus, emitterPositions(idx, :), sourcePosition);
    %
otherwise
    error('%s: %s convention currently not supported.', ...
        upper(mfilename), header.GLOBAL_SOFAConventions);
end

nLoudspeaker = size(loudspeakerPositions, 1);

switch coordinateSystem
case 'cartesian'
    return;
case 'spherical'
    loudspeakerPositions = SOFAconvertCoordinates(loudspeakerPositions, ...
                                                  'cartesian', 'spherical');
otherwise
    error('%s: %s is not a supported coordinate system.', ...
        upper(mfilename), coordinateSystem);
end
% vim: sw=4 ts=4 et tw=90:
