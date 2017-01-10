function filenames = getDir(directory, bRecursive, bVerbose)
% get content of directory from hard disk or database
%
% USAGE
%   filenames = db.getDir(directory, bRecursive, bVerbose)
%
% INPUT PARAMETERS
%   directory  - directory in database
%   bRecursive - also download content of subdirectories. Default: 0.
%   bVerbose   - optional boolean verbosity parameter. Default: 0.
%
% OUTPUT PARAMETERS
%   filenames  - filenames of files found locally or in database
%
% See also: db.listDir db.getFile db.path

narginchk(1,3);
isargchar(directory);
if nargin < 2
  bRecursive = false;
end
if nargin < 3
  bVerbose = false;
end

% get the filelist
try 
  flist = db.getFile(fullfile(directory, '.dir.flist'), false);
catch
  fprintf('Download of filelist failed / No filelist found!\n');
  return;
end
fid = fopen(flist, 'r');
content = textscan(fid,'%s','Delimiter','\n','CommentStyle','#');
fclose(fid);

filenames = {};
% get the files
for c = content{1}.'
  if bRecursive && c{:}(end) == '/'
    % try to get the files from the subdirectory
    filenames = [filenames; ...
      db.getDir(fullfile(directory, c{:}), 1, bVerbose)];
  elseif c{:}(end) ~= '/'
    % try to get the file
    try
      filenames = [filenames; ...
        {db.getFile(fullfile(directory, c{:}), bVerbose)}];
    catch
      fprintf('Download of %s failed!\n', fullfile(directory, c{:}));
    end
  end
end

% vim: set sw=4 ts=4 expandtab textwidth=90 :
