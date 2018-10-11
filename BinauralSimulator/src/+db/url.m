function [url, alturl] = url(url, alturl)
% defines url of root directory of remote twoears database.
%
% Parameters:
%   url:      url of root directory of remote twoears database, optional @type 
%             char[]
%   alturl:   alternative url 
%
% Return values:
%   url:      current url
%   alturl:   current alternative url
%
% defines root path to local copy of twoears database. Calling this function
% without an argument just returns the current url. Inspired from SOFA
% (http://www.sofaconventions.org/). 
%
% See also: http://sourceforge.net/p/sofacoustics/code/HEAD/tree/trunk/API_MO/SOFAdbURL.m

persistent CachedURL;
persistent CachedAltURL;

% URL
if exist('url','var')
  CachedURL=url;
elseif isempty(CachedURL)
  CachedURL= 'https://avtshare01.rz.tu-ilmenau.de/two-ears/database/';
end
url=CachedURL;

% Alternative URL
if exist('alturl','var')
  CachedAltURL=alturl;
elseif isempty(CachedAltURL)
  CachedAltURL= 'https://dev.qu.tu-berlin.de/projects/twoears-getdata/repository/raw/';
end
alturl=CachedAltURL;