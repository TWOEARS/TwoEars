function newpath = tmp(newpath)
% defines root path to temporary directory for files downloaded via dbDownlodFile
%
% Parameters:
%   newpath:  path to temporary directory, optional @type char[]
%
% Return values:
%   newpath:  current path to temporary directory
%
% Defines root path to temporary directory for files downloaded via 
% dbDownlodFile(). Calling this function without an argument just returns the 
% current path. Taken from SOFA (http://www.sofaconventions.org/).
%
% See also: http://sourceforge.net/p/sofacoustics/code/HEAD/tree/trunk/API_MO/SOFAdbPath.m

persistent CachedPath;

if exist('newpath','var')
  CachedPath=fullfile(newpath);
elseif isempty(CachedPath)
  basepath=fileparts(mfilename('fullpath'));
  CachedPath=fullfile(basepath, '..', '..', 'tmp', filesep);
end
newpath=CachedPath;
