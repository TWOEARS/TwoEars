function filenames = getFilesFromList(flist, bRecursive, bVerbose)
% get files or whole directory listed in a text file
%
% USAGE
%   filenames = db.getFilesFromList(flist, bRecursive, bVerbose)
%
% INPUT PARAMETERS
%   flist      - filename of file/directory list
%   bRecursive - also download content of subdirectories of the directories
%                given in the list. Default: 0.
%   bVerbose   - optional boolean verbosity parameter. Default: 0.
%
% OUTPUT PARAMETERS
%   filenames  - filenames of files found locally or in database
%
% DETAILS
%   The file list is searched by the means of db.getFile(flist). For further
%   information see respective documentation. The flist may contain filenames
%   and directory which again are searched by the means of db.getFile(). The
%   name of a directory has to be terminated by a slash. The bRecursive 
%   specifies, if the content of possible subdirectories should also be 
%   acquired.
%
%   Example List:
%
%   # this is a comment
%   first/file/in/this/list
%   a/directory/
%   second/file/in/blub

% See also: db.getDir db.getFile db.path db.url

narginchk(1,3);
isargchar(flist);
if nargin < 2
  bRecursive = false;
end
if nargin < 3
  bVerbose = false;
end

% get the filelist
flist = db.getFile(flist, false);
fid = fopen(flist, 'r');
content = textscan(fid,'%s','Delimiter','\n','CommentStyle','#');
fclose(fid);

filenames = {};
% get the files/directories
for c = content{1}.'
  if c{:}(end) == '/'
    % try to get the files from the subdirectory
    filenames = [filenames; db.getDir(c{:}, bRecursive, bVerbose)];
  else
    % try to get the file
    filenames = [filenames; {db.getFile(c{:}, bVerbose)}];
  end
end

% vim: set sw=4 ts=4 expandtab textwidth=90 :
