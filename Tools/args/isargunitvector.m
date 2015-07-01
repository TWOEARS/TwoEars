function isargunitvector(varargin)
%ISARGVECTOR tests if the given arg is a unit vector and returns an error otherwise
%
%   Usage: sargunitvector(args)
%
%   Input options:
%       args        - list of args
%
%   ISARGVECTOR(args) tests if all given args are a unit vector and returns
%   an error otherwise.
%
%   see also: isargvector

%% ===== Checking for vector =============================================
eps = 1e-5;

for ii = 1:nargin
    if ~isvector(varargin{ii}) || abs(norm(varargin{ii},2) - 1.0) > eps
        error('%s need to be a unit vector.',inputname(ii));
    end
end
