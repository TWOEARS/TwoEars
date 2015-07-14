function url = dbURL(url)
% defines url of root directory of remote twoears database.
%
% Parameters:
%   url:  url of root directory of remote twoears database, optional @type char[]
%
% Return values:
%   url:  current url
%
% defines root path to local copy of twoears database. Calling this function
% without an argument just returns the current url. Taken from SOFA
% (http://www.sofaconventions.org/). 
%
% See also: http://sourceforge.net/p/sofacoustics/code/HEAD/tree/trunk/API_MO/SOFAdbURL.m

persistent CachedURL;

if exist('url','var')
  CachedURL=url;
elseif isempty(CachedURL)
  CachedURL= 'https://dev.qu.tu-berlin.de/projects/twoears-database/repository/revisions/master/raw/';
end
url=CachedURL;
