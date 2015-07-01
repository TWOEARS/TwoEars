function fprintcf(fid, str, varargin)
%fprintcf prints output to file and command window
%
% USAGE: fprintcf(fid, str, varargin)
%
% It works exactly the same as fprintf, but prints the result not only to the
% file fid, but also to the command window
if nargin == 2
    fprintf(1, str);
    fprintf(fid, str);
elseif nargin > 2
    str = sprintf(str, varargin{:});
    fprintf(1, str);
    fprintf(fid, str);
else
    error('not enough inputs');
end
