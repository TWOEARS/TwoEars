function fileList = getFiles(folder, extension)
% GETFILES Returns a cell-array, containing a list of files
%   with a specified extension.
%
% REQUIRED INPUTS:
%    folder - Path pointing to the folder that should be
%       searched.
%    extension - String, specifying the file extension that
%       should be searched.
%
% OUTPUTS:
%    fileList - Cell-array containing all files that were found
%       in the folder. If no files with the specified extension
%       were found, an empty cell-array is returned.

% Check inputs
p = inputParser();

p.addRequired('folder', @isdir);
p.addRequired('extension', @ischar);
parse(p, folder, extension);

% Get all files in folder
fileList = dir(fullfile(p.Results.folder, ...
    ['*.', p.Results.extension]));

% Return cell-array of filenames
fileList = {fileList(:).name};
end