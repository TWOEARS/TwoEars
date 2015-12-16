function obj = fitmvmdist(angles, nComponents, varargin)
% FITMVMDIST This function estimates the parameters of a mixture of von
%   Mises distributions using an Expectation-Maximization scheme. It uses
%   the corresponding functions provided by the VonMisesMixture class.
%   Please refer to the function headers in the class source file for
%   further information.
%
% REQUIRED INPUTS:
%   angles - Nx1 vector, containing N angular values, ranged between -pi
%       and pi.
%   nComponents - Number of mixture components that should be estimated.
%
% PARAMETERS:
%   ['MaxIter', maxIter] - Maximum number of iterations the EM-algorithm
%       should run (default = 100).
%   ['ErrorThreshold', errorThreshold] - Minimum error to  be used as a
%       stopping-criterion for the EM-algorithm during convergence testing
%       (default = 1E-4).
%   ['Replicates', replicates] - Number of replications of the parameter
%       estimation procedure. If the number of replications is greater than
%       one, the parameters of the replicate that yielded the highest
%       log-likelihood will be returned (default = 1).
%   ['FixedMu', fixedMu] - A vector, containing circular mean
%       parameters that should be fixed during the estimation
%       process.
%   ['FixedKappa', fixedKappa] - A vector, containing
%       concentration parameters that should be fixed during
%       the estimation process. If both fixed circular means
%       and concnetration parameters are defined, keep in mind
%       that the order of the vector elements determines, which
%       concentration parameter is assigned to which mean, e.g.
%       fixedMu(1) -> fixedKappa(1) etc.
%
% DEPENDS ON:
%   VonMisesMixture.m
%
% AUTHORS:
%   Christopher Schymura (christopher.schymura@rub.de)
%   Cognitive Signal Processing Group
%   Ruhr-Universitaet Bochum
%   Universitaetsstr. 150, 44801 Bochum

% Check inputs
p = inputParser();
defaultMaxIter = 100;
defaultErrorThreshold = 1E-4;
defaultReplicates = 1;
defaultFixedMu = [];
defaultFixedKappa = [];

p.addRequired('angles', @(x) validateattributes(x, ...
    {'numeric'}, {'real', 'vector', '>=', -pi, '<=', pi}));
p.addRequired('nComponents', @(x) validateattributes(x, ...
    {'numeric'}, {'integer', 'scalar', 'positive'}));
p.addParameter('MaxIter', defaultMaxIter, ...
    @(x) validateattributes(x, {'numeric'}, ...
    {'integer', 'scalar', 'positive'}));
p.addParameter('ErrorThreshold', defaultErrorThreshold, ...
    @(x) validateattributes(x, {'numeric'}, ...
    {'real', 'scalar', 'nonnegative'}));
p.addParameter('Replicates', defaultReplicates, ...
    @(x) validateattributes(x, {'numeric'}, ...
    {'integer', 'scalar', 'nonnegative'}));
fixedMuExist = ...
    ~isempty(find(cellfun(@(x) strcmpi(x, 'FixedMu') , ...
    varargin), 1));
if fixedMuExist && (isempty(varargin{fixedMuExist + 1}))
    p.addParameter('FixedMu', defaultFixedMu, @isnumeric);
else
    p.addParameter('FixedMu', defaultFixedMu, ...
        @(x) validateattributes(x, {'numeric'}, ...
        {'real', 'vector', '>=', -pi, '<=', pi}));
end
fixedKappaExist = ...
    ~isempty(find(cellfun(@(x) strcmpi(x, 'FixedKappa') , ...
    varargin), 1));
if fixedKappaExist && (isempty(varargin{fixedKappaExist + 1}))
    p.addParameter('FixedKappa', defaultFixedKappa, ...
        @isnumeric);
else
    p.addParameter('FixedKappa', defaultFixedKappa, ...
        @(x) validateattributes(x, {'numeric'}, ...
        {'real', 'vector', 'nonnegative'}));
end
p.parse(angles, nComponents, varargin{:});

% Initialize von Mises mixture models for all replicates
models = cell(p.Results.Replicates, 1);

% Initialize indicator variables for maximum log likelihood tracking
maxLogLik = -realmax;
bestIdx = 1;

% Perform parameter estimation
for rIdx = 1 : p.Results.Replicates
    % Initialize mixture of von Mises distribution
    model = VonMisesMixture();
    
    % Run EM and generate model
    models{rIdx} = model.fit(p.Results.angles, p.Results.nComponents, ...
        'MaxIter', p.Results.MaxIter, ...
        'ErrorThreshold', p.Results.ErrorThreshold, ...
        'FixedMu', p.Results.FixedMu, ...
        'FixedKappa', p.Results.FixedKappa);
    
    % Update maximum log-likelihood
    if models{rIdx}.logLikelihood > maxLogLik
        maxLogLik = models{rIdx}.logLikelihood;
        bestIdx = rIdx;
    end
end

% Select and return best-matching model
obj = models{bestIdx};

end

