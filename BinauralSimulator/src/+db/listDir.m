function listDir(directory, bRecursive, nIndent)
% list content of directory in database
%
% USAGE
%   db.listDir(directory, bRecursive, nIndent)
%
% INPUT PARAMETERS
%   directory  - directory in database
%   bRecursive - lists content of subdirectories. Default: 0.
%   nIndent    - indent parameter for better display. Default: 0.
%
% See also: db.getDir db.getFile db.path

narginchk(0,3);
if nargin < 1
  directory='';
else
  isargchar(directory);
end
if nargin < 2
  bRecursive = false;
end
if nargin < 3
  nIndent = 0;
end
sIndent = repmat(' ', [1, nIndent]);

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

% display content
for c = content{1}.'
  fprintf('%s%s\n', sIndent, c{:});
  if bRecursive && c{:}(end) == '/'
    % try to list the files from the subdirectory
    db.listDir(fullfile(directory, c{:}), true, nIndent+2)
  end
end

% vim: set sw=4 ts=4 expandtab textwidth=90 :
