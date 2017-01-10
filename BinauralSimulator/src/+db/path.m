function newpath = path(newpath)
% defines root path to local copy of twoears database.
%
% Parameters:
%   newpath:  path to local copy of twoears database, optional @type char[]
%
% Return values:
%   newpath:  current path to database
%
% defines root path to local copy of twoears database. Calling this function
% without an argument just returns the current path. Taken from SOFA
% (http://www.sofaconventions.org/).
%
% See also: http://sourceforge.net/p/sofacoustics/code/HEAD/tree/trunk/API_MO/SOFAdbPath.m

persistent CachedPath;

if exist('newpath','var')
  CachedPath=fullfile(newpath);
elseif isempty(CachedPath)
  basepath=fileparts(mfilename('fullpath'));
  CachedPath=fullfile(basepath, '..', '..', '..', 'twoears-data', filesep);
end
newpath=CachedPath;
