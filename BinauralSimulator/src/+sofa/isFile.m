function bSofaFile = isFile(brir)
%isFile returns 1 for a brir file, 0 for a brir struct or an error otherwise
%
%   USAGE
%       bSofaFile = isFile(brir)
%
%   INPUT PARAMETERS
%       brir        - SOFA struct or file name
%
%   OUTPUT PARAMETERS
%       bSofaFile   - true for brir is a file and false for brir is a struct

if ~isstruct(brir) && exist(brir,'file')
    bSofaFile = true;
elseif isstruct(brir) && isfield(brir,'GLOBAL_Conventions') && ...
       strcmp('SOFA',brir.GLOBAL_Conventions)
    bSofaFile = false;
else
    error('%s: brir has to be a file or a SOFA struct.',upper(mfilename));
end
