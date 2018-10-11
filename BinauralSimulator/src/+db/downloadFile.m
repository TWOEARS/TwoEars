function outfile = downloadFile(filename, outfile, bVerbose)
% download file from remote database
%
% Parameters:
%   filename: filename relative to root directory of the database @type char[]
%   outfile: relative or absolute filename where download should be saved, optional @type char[]
%   bVerbose: optional boolean verbosity parameter. Default: 0.
%
% Return values:
%   outfile: absolute name of downloaded file
%
% Download file specified by filename relative to root directory of the remote
% database. The root directory is defined via db.url(). If no output
% file is specified the file will relative to the temporary directory. The
% temporary is via db.tmp();
%
% See also: db.getFile db.url db.tmp

% split up filename into directories
[dirs, sdx] = regexp(filename, '(\\|\/)', 'split', 'start');

% create directories if necessary
if nargin < 2 || isempty(outfile)
  dir_path = db.tmp();
  for idx=1:length(dirs)-1
    dir_path = [dir_path, filesep, dirs{idx}];
    [~, ~] = mkdir(dir_path);
  end
  outfile = fullfile(dir_path, dirs{end});
end

filename(sdx) = '/';  % replace backslashes with slashed for url
[dburl, dbalturl] = db.url();  % url of database

% try with URL of database
url = [dburl, '/', filename];
% start download
if nargin == 3 && bVerbose
  fprintf('Downloading file %s\n', url);
end
try
  websave(outfile, url, weboptions('Timeout',Inf));
catch
  warning('Download failed (url=%s), trying alternative database...', url);
  % try with alternative URL of database
  url = [dbalturl, '/', filename];
  % start download
  if nargin == 3 && bVerbose
    fprintf('Downloading file %s\n', url);
  end
  try
    websave(outfile, url, weboptions('Timeout',Inf));
  catch
    error('Download also failed with alternative database (url=%s)', url);
  end
end
