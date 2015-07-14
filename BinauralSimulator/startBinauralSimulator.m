% Workaround for Bug in Matlab R2012b and higher
% 'BLAS loading error: dlopen: cannot load any more object with static TLS'
ones(10)*ones(10);

% Workaround for Bug related to fftw library
fftw('swisdom');

basePath = fileparts(mfilename('fullpath'));

addpath(fullfile(basePath, 'src'));
addpath(fullfile(basePath, 'src', 'mex'));

% Add SOFA HRTF handling
addpath(fullfile(basePath, 'src', 'sofa'));
SOFAstart(0);

% Clear used variables
clear basePath;
