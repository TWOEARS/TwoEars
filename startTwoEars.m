function startTwoEars(configFile)
%STARTTWOEARS sets up the whole Two!Ears model parts

TwoEarsPath = fileparts(mfilename('fullpath'));
TwoEarsPath = [TwoEarsPath, filesep];

addpath(TwoEarsPath);
addpath([TwoEarsPath, 'Tools']);
addpath([TwoEarsPath, 'Tools', filesep, 'TwoEarsStartup']);

if nargin>0
    if exist(configFile,'file')
        setupPartConfig(configFile);
    else
        error('Config file %s is not a valid file.',configFile);
    end
else
    setupPartConfig([TwoEarsPath, 'TwoEars.xml']);
end
