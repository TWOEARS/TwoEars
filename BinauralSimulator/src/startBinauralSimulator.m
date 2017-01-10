%% workaround for bug in Matlab R2012b and higher
% 'BLAS loading error: dlopen: cannot load any more object with static TLS'
ones(10)*ones(10);

%% workaround for bug related to fftw library
fftw('swisdom');

%% search for TwoEarsPaths.xml and get path to local database
warn = false;

if exist('TwoEarsPaths.xml', 'file') == 2
  docNode = xmlread('TwoEarsPaths.xml');
  eleList = docNode.getDocumentElement.getElementsByTagName('data');
  switch eleList.getLength
    case 0
    case 1
      db.path( char( eleList.item(0).getFirstChild.getData ) );
    otherwise
      warning(['%s: Found more than one entry for ''data'' in the ', ...
      '''TwoEarsPaths.xml''.'], upper(mfilename));
  end
end

clear docNode eleList % Clear used variables

%% add necessary paths
basePath = [fileparts(mfilename('fullpath')) filesep];

addpath([basePath 'mex']);

clear basePath;  % Clear used variables
