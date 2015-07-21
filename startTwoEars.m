function startTwoEars(configFile)
%startTwoEars sets up the whole Two!Ears model parts
%
%   USAGE
%       startTwoEars()
%       startTwoEars(configFile)
%       startTwoEars('info')
%
%   INPUT PARAMETERS
%       configFiles     - xml config file specifying which modules of Two!Ears
%                         should be activated, see http://bit.ly/1Kc1Zuc
%       'info'          - display the version of the Two!Ears Auditory Model and
%                         infos about the involved people

if nargin==0
    configFile = 'TwoEars.xml';
end
if ~ischar(configFile)
    error('configFile needs to be a string');
end

% Add current folder and the startup folder
TwoEarsPath = fileparts(mfilename('fullpath'));
addpath(TwoEarsPath);
addpath(fullfile(TwoEarsPath, 'Tools', 'TwoEarsStartup'));

% Display version information and finish if asked to do so
if strcmp('info', configFile)
    displayTwoEarsInfo('full');
    return
end

% SOFA work around. The following checks if you have another version of SOFA
% added to your Matlab paths and removes it as the official SOFA version is not
% compatible with the one needed by Two!Ears
if exist('SOFAstart')
    warning(['Trying to remove your current SOFA installation from Matlab ', ...
             'paths as the official SOFA version is not compatible with ', ...
             'Two!Ears.']);
    warning('off', 'all');
    sofaPath = fileparts(which('SOFAstart'));
    rmpath(sofaPath);
    rmpath(fullfile(sofaPath, 'helper'));
    rmpath(fullfile(sofaPath, 'coordinates'));
    rmpath(fullfile(sofaPath, 'converters'));
    rmpath(fullfile(sofaPath, 'demos'));
    rmpath(fullfile(sofaPath, 'netcdf'));
    warning('on', 'all');
end

if exist(configFile,'file')
    setupPartConfig(configFile);
else
    error('Config file %s is not a valid file.',configFile);
end
