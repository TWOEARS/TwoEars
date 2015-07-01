function outfile = dbDownloadFile(filename, outfile)
% download file from remote database
%
% Parameters:
%   filename: filename relative to root directory of the database @type char[]
%   outfile: relative or absolute filename where download should be saved, optional @type char[]
%
% Return values:
%   outfile: absolute name of downloaded file
%
% Download file specified by filename relative to root directory of the remote
% database. The root directory is defined via xml.dbURL(). If no output
% file is specified the file will relative to the temporary directory. The
% temporary is via xml.dbTmp();
%
% See also: xml.dbGetFile xml.dbURL xml.getTmp

% split up filename into directories
[dirs, sdx] = regexp(filename, '(\\|\/)', 'split', 'start');

filename(sdx) = '/';  % replace backslashes with slashed for url
url = [xml.dbURL(), '/', filename];

% create directories if necessary
if nargin < 2  
  dir_path = xml.dbTmp();
  for idx=1:length(dirs)-1
    dir_path = [dir_path, filesep, dirs{idx}];
    [~, ~] = mkdir(dir_path);
  end
  outfile = fullfile(dir_path, dirs{end});
end

% start download
fprintf('Downloading file %s\n', url);
[~, status] = urlwrite(url, outfile);

if ~status
  error('Download failed (url=%s)', url);
end
