function [humanLabels, stats] = readHumanLabels(labelFile)
% readHumanLabels returns a cell array containing filenames and human labels
%
% USAGE:
%   [humanLabels, stats] = readHumanLabels(labelFile)
%
% INPUT PARAMETERS:
%   labelFile   - csv file storing results from listening tests. ',' is assumed as a
%                 delimiter and '#' as a comment sign, meaning all lines starting
%                 with # will be ignored.
%
% OUTPUT PARAMETERS:
%   humanLabels - cell containing the data from the labelFile
%   stats       - structure, containing:
%                   .rows    - number of rows in humanLabels
%                   .columns - number of columns in humanLabels
%                   .nested  - number of nested cells
%
% DETAILS:
%   Under the experiments/ folder in the Two!Ears database so called human label files are
%   stored containing results from listening experiments. The files should be in the
%   format of csv files using ',' as column delimiters. It can contain numerical as well
%   as string data. The data is returned as a cell array and can be accessed in the form
%   humanLabels{1,2}. The single entries in the data file can also include nested data in
%   the form {4,-2}. The corresponding cell in humanLabels will then contain a vector
%   which can be accsess in the form humanLabels{1,2}(1).

% Checking of input parameters
narginchk(1,1);

% Get labelFile
labelFile = xml.dbGetFile(labelFile);
% Use readtext to get entries from file
[humanLabels, tmp]= readtext(labelFile, ',', '#', '{}', '');
stats.rows = size(humanLabels,1);
stats.columns = size(humanLabels,2);
stats.nested = tmp.quote;
% Look for a string containing '{...}' and convert it to a cell.
% This is needed for nested data. For example, in the case of localization it could be
% that the listener perceived 2 instead of 1 source, then we will have two direction
% nested in a cell.
for ii = 1:length(humanLabels(:))
    entry = humanLabels(ii);
    if iscellstr(entry) && (strcmp(entry{1}(1), '{') && strcmp(entry{1}(end), '}'))
        % Remove {}-brackets, split string at ',' and convert to double
        entry = str2double(strsplit(entry{1}(2:end-1),','));
        humanLabels(ii) = {entry};
    end
end
% vim: set sw=4 ts=4 expandtab textwidth=90 :
