function [impulseResponses, fs] = getDataFir(brir, idxM)
%getDataFir returns impulse responses from a SOFA file or struct
%
%   USAGE
%       impulseResponses = getDataFir(brir, [idxM])
%
%   INPUT PARAMETERS
%       brir    - impulse response data set (SOFA struct/file)
%       idxM    - index of the single impulse responses that should be returned
%                 idxM could be a single value, then only one impulse response
%                 will be returned, or it can be a vector then all impulse
%                 responses for the corresponding index positions will be
%                 returned.
%                 If no index is specified all data will be returned.
%
%   OUTPUT PARAMETERS
%       ir      - impulse response (M,2,N), where
%                   M ... number of impulse responses
%                   N ... samples
%       fs       - sampling rate of impulse response
%
%% argument check
if nargin < 2 || isempty(idxM)
    idxM = ':';
end
%%
% check if SOFA file is already loaded into RAM
if ~sofa.isFile(brir)
    impulseResponses = brir.Data.IR(idxM, :, :);
    fs = brir.Data.SamplingRate;
    return;
end

header = sofa.getHeader(brir);
% create information about connected indices (i.e. segments)
if ~isnumeric(idxM)
    segM_begin = 1;
    segM_end = header.API.M;
    segM_length = header.API.M;
    ununiqueM = 1:header.API.M;
    sortM = 1:header.API.M;
else
    [idxM, ~, ununiqueM] = unique(idxM, 'stable');
    [idxM, sortM] = sort(idxM, 'ascend');
    [segM_begin, segM_end, segM_length] = sofa.findSegments(idxM);
end
% compute index array to undo the sorting
unsortM(sortM) = 1:length(sortM);

% segment wise load of IRs (saves time)
for mdx = 1:length(segM_begin)
    ii = idxM( segM_begin(mdx) );
    tmp = SOFAload(brir, [ii, segM_length(mdx)], 'M');
    impulseResponses(segM_begin(mdx):segM_end(mdx),:,:) = tmp.Data.IR;
end
% get sampling frequency
fs = tmp.Data.SamplingRate;
% undo sorting of Data + undo unique
impulseResponses = impulseResponses(unsortM(ununiqueM),:,:);

% vim: sw=4 ts=4 et tw=90:
