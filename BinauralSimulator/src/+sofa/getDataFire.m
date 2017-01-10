function [impulseResponses,fs] = getDataFire(brir, idxM, idxE)
%getDataFire returns impulse responses from a SOFA file or struct
%
%   USAGE
%       impulseResponses = getDataFire(brir, [idxM, [idxE]])
%
%   INPUT PARAMETERS
%       brir    - impulse response data set (SOFA struct/file)
%       idxM    - index of the measurements for which the single impulse
%                 responses should be returned.
%                 idxM could be a single value, then only one impulse response
%                 will be returned, or it can be a vector then all impulse
%                 responses for the corresponding index positions will be
%                 returned.
%                 If no index is specified all measurements will be returned.
%       idxE    - index of the emitter for which the single impulse
%                 responses should be returned. The rest is identical to idxM.
%
%   OUTPUT PARAMETERS
%       impulseResponses - impulse response (M,2,E,N), where
%                           M ... number of impulse responses
%                           E ... number of emitters (loudspeakers)
%                           N ... samples
%       fs               - sampling rate of impulse response
%
%% argument check
if nargin < 3
    idxE = ':';
end
if nargin < 2
    idxM = ':';
end

%%
% check if SOFA file is already loaded into RAM
if ~sofa.isFile(brir)
    impulseResponses = brir.Data.IR(idxM, :, idxE, :);
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
if ~isnumeric(idxE)
    segE_begin = 1;
    segE_end = header.API.E;
    segE_length = header.API.E;
    ununiqueE = 1:header.API.E;
    sortE = 1:header.API.E;
else
    [idxE, ~, ununiqueE] = unique(idxE, 'stable');
    [idxE, sortE] = sort(idxE, 'ascend');
    [segE_begin, segE_end, segE_length] = sofa.findSegments(idxE);
end
% compute index array to undo the sorting
unsortM(sortM) = 1:length(sortM);
unsortE(sortE) = 1:length(sortE);

% segment wise load of IRs (saves time)
for mdx = 1:length(segM_begin)
    ii = idxM( segM_begin(mdx) );
    for edx = 1:length(segE_begin)
        jj = idxE( segE_begin(edx) );
        tmp = SOFAload(brir, ...
            [ii, segM_length(mdx)], 'M', ...
            [jj, segE_length(edx)], 'E');
        impulseResponses(segM_begin(mdx):segM_end(mdx),:, ...
            segE_begin(edx):segE_end(edx),:) = tmp.Data.IR;
    end
end
% get sampling frequency
fs = tmp.Data.SamplingRate;
% undo sorting of Data + undo unique
impulseResponses = ...
    impulseResponses(unsortM(ununiqueM), :, unsortE(ununiqueE), :);

% vim: sw=4 ts=4 et tw=90:
