function header = getHeader(brir)
%getHeader returns the header of a SOFA file or struct
%
%   USAGE
%       header = getHeader(brir)
%
%   INPUT PARAMETERS
%       brir    - impulse response data set (SOFA struct/file)
%
%   OUTPUT PARAMETERS
%       header  - SOFA header

if sofa.isFile(brir)
    header = SOFAload(brir, 'nodata');
else
    header = brir;
    if isfield(brir.Data, 'IR')
        header.Data = rmfield(brir.Data, 'IR');
    end
end
% vim: sw=4 ts=4 et tw=90:
