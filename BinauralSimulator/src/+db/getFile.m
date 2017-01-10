function filename = getFile(filename, bVerbose)
% search for file locally and in database
%
% USAGE
%   filename = db.getFile(filename, bVerbose)
%
% INPUT PARAMETERS
%   filename - filename
%   bVerbose - optional boolean verbosity parameter. Default: 0.
%
% OUTPUT PARAMETERS
%   filename - filename of file found locally or in database
%
% DETAILS
%   search for file specified by filename relative to current directory.
%   Filenames starting with '/' will interpreted as absolute paths. If the file
%   is not found, searching will be extended to the local copy of the
%   Two!Ears database (database path defined via db.path()). Again,
%   searching will be extended to the remote database (defined via
%   db.url). If the download was successfull, the file will be cached in
%   'src/tmp'. The cache can be cleared via db.clearTmp()
%
% See also: db.path db.url db.clearTmp

narginchk(1,2);
isargchar(filename);
if nargin < 2
  bVerbose = 0;
end

try
  % try relative path to current working directory
  isargfile(fullfile(pwd,filename));
  if bVerbose
    fprintf(strcat('INFO: relative local file (%s) found, will not ', ...
      'search in database\n'), filename);
  end
  filename = fullfile(pwd,filename);
  return;
catch
  try
    % search inside paths added by addpath
    isargfile(which(filename));
    if bVerbose
      fprintf(strcat('INFO: relative local file (%s) found, will not ', ...
        'search in database\n'), filename);
    end
    filename = which(filename);
    return;
  catch
    try
      % try absolute path
      isargfile(filename);
      if bVerbose
        fprintf(strcat('INFO: absolute local file (%s) found, will not ', ...
          'search in database\n'), filename);
      end
      return;
    catch
      try
        % try local database
        isargfile(fullfile(db.path(),filename));
        if bVerbose
          fprintf('INFO: file (%s) found in local database\n', filename);
        end
        filename = fullfile(db.path(),filename);
        return;
      catch
        if bVerbose
          fprintf(strcat('INFO: file (%s) not found in local database ', ...
            '(dbPath=%s), trying remote database\n'), filename, db.path());
        end
        % try cache of remote database
        try
          tmppath = db.tmp();
          isargfile(fullfile(tmppath,filename));
          if bVerbose
            fprintf('INFO: file (%s) found in cache of remote database\n', ...
              filename);
          end
          filename = fullfile(tmppath,filename);
          return;
        catch
          % try download from remote database
          filename = db.downloadFile(filename, [], bVerbose);
        end
      end
    end
  end
end

% vim: set sw=4 ts=4 expandtab textwidth=90 :
