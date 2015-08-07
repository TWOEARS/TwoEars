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

% Add current folder and the src folders
TwoEarsPath = fileparts(mfilename('fullpath'));
addpath(TwoEarsPath);
addpath(fullfile(TwoEarsPath, 'Tools', 'TwoEarsStartup'));
addpath(fullfile(TwoEarsPath, 'Tools', 'args'));
addpath(fullfile(TwoEarsPath, 'Tools', 'misc'));

% Display version information and finish if asked to do so
if strcmp('info', configFile)
    displayTwoEarsInfo('full');
    return
end

% SOFA work around. The following checks if you have another version of SOFA
% added to your Matlab paths and removes it as the official SOFA version is not
% compatible with the one needed by Two!Ears
if exist('SOFAstart') & ~strcmp('1.0-twoears', SOFAgetVersion('SOFA'))
    warning('off', 'MATLAB:rmpath:DirNotFound');
    sofaPath = fileparts(which('SOFAstart'));
    rmpath(sofaPath);
    rmpath(fullfile(sofaPath, 'helper'));
    rmpath(fullfile(sofaPath, 'coordinates'));
    rmpath(fullfile(sofaPath, 'converters'));
    rmpath(fullfile(sofaPath, 'demos'));
    rmpath(fullfile(sofaPath, 'netcdf'));
    warning('on', 'MATLAB:rmpath:DirNotFound');
    warning(['Your current SOFA installation has been removed from Matlab ', ...
             'paths as the official SOFA version is not compatible with ', ...
             'Two!Ears.']);
end

if exist(configFile,'file')
    setupPartConfig(configFile);
else
    error('Config file %s is not a valid file.',configFile);
end
