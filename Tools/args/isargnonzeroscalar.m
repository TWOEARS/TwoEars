function isargnonzeroscalar(varargin)
%ISARGNONZEROSCALAR tests if the given arg is a non-zero scalar
%
%   Usage: isargcoord(args)
%
%   Input options:
%       args        - list of args
%
%   %ISARGNONZEROSCALAR tests if all given args are a non-zero
%   scalar and returns an error otherwise.
%
%   see also: isargpositivescalar, isargscalar, isargnegativescalar

%% ===== Checking for scalar =============================================
for ii = 1:nargin
    if ~isnumeric(varargin{ii}) || ~isscalar(varargin{ii}) || varargin{ii} == 0
        error('%s need to be a non-zero scalar.',inputname(ii));
    end
end
