function [idx, centers] = ckmeans(angles, nClusters, varargin)
% CKMEANS This function performs circular k-means clustering on a set of
%   one-dimensional circular data. This implementation is based on the
%   spherical k-means clustering algorithm introduced in [1].
%
% REQUIRED INPUTS:
%   angles - Nx1 vector, containing N angular values, ranged between -pi
%       and pi.
%   nClusters - Number clusters that should be estimated.
%
% PARAMETERS:
%   ['MaxIter', maxIter] - Maximum number of iterations for the
%       optimization process (default = 100).
%   ['ErrorThreshold', errorThreshold] - Minimum error that should be used
%       as a stopping-criterion (default = 1E-6).
%   ['Replicates', replicates] - Number of replications of the parameter
%       estimation procedure. If the number of replications is greater than
%       one, the parameters of the replicate that yielded the lowest
%       error will be returned (default = 1).
%   ['FixedCenters', fixedCenters] - This parameter allows to fix a subset
%       of cluster centers during the estimation process. The centers to be
%       fixed have to be specified as a vector containing B elements, where
%       B <= K - 1 is the number of fixed centers.
%
% OUTPUTS:
%   idx - Nx1 vector of cluster indices for each data point.
%   centers - Kx1 vector of cluster centers, where K is the number of
%       clusters.
%
% LITERATURE:
%   [1] K. Hornik et al. (2012): "Spherical k-Means Clustering"
%
% AUTHORS:
%   Christopher Schymura (christopher.schymura@rub.de)
%   Cognitive Signal Processing Group
%   Ruhr-Universitaet Bochum
%   Universitaetsstr. 150, 44801 Bochum

% Check inputs
p = inputParser();
defaultMaxIter = 100;
defaultErrorThreshold = 1E-6;
defaultReplicates = 1;
defaultFixedCenters = [];

p.addRequired('angles', @(x) validateattributes(x, {'numeric'}, ...
    {'real', 'vector', '>=', -pi, '<=', pi}));
p.addRequired('nClusters', @(x) validateattributes(x, {'numeric'}, ...
    {'integer', 'scalar', 'positive'}));
p.addParameter('MaxIter', defaultMaxIter, @(x) validateattributes(x, ...
    {'numeric'}, {'integer', 'scalar', 'positive'}));
p.addParameter('ErrorThreshold', defaultErrorThreshold, ...
    @(x) validateattributes(x, {'numeric'}, ...
    {'real', 'scalar', 'nonnegative'}));
p.addParameter('Replicates', defaultReplicates, ...
    @(x) validateattributes(x, {'numeric'}, ...
    {'integer', 'scalar', 'nonnegative'}));
p.addParameter('FixedCenters', defaultFixedCenters, ...
    @(x) validateattributes(x, {'numeric'}, ...
    {'real', 'vector', '>=', -pi, '<=', pi}));
p.parse(angles, nClusters, varargin{:});

% Get number of data-points
nSamples = length(angles);

% Initialize cluster centers and sample indices for all replicates
rIndices = cell(p.Results.Replicates, 1);
rCenters = cell(p.Results.Replicates, 1);

% Initialize indicator variables for error tracking
minError = realmax;
bestIdx = 1;

% Run clustering
for rIdx = 1 : p.Results.Replicates
    % Initialize cluster centers based on the k-means++ approach. 
    % One cluster center is chosen randomly from the set of input angles:
    centers = zeros(nClusters, 1);
    
    % Check if any fixed centers are specified
    if ~isempty(p.Results.FixedCenters)
        % Get number of fixed centers
        nFixedCenters = length(p.Results.FixedCenters);
        
        % Assign fixed centers to initial estimate
        centers(1 : nFixedCenters) = p.Results.FixedCenters;
    else
        % Set number of fixed centers to zero
        nFixedCenters = 0;
        
        % Randomly choose the first cluster center
        centers(1) = angles(randi(nSamples));
    end
        
    % Add new cluster centers iteratively
    for clusterIdx = nFixedCenters + 1 : nClusters
        % Get the reduced set of cluster centers
        centersReduced = centers(1 : max(clusterIdx - 1, 1));
        
        % Compute circular distances to cluster centers from reduced set
        distances = computeClusterDistances(angles, centersReduced);
        
        % Get distances to closest cluster
        distances = min(distances, [], 2);
        
        % Convert distances into "probabilities"
        dProbs = distances.^2 ./ sum(distances.^2);
        
        % Select next cluster center by this probability distribution
        cumProbs = cumsum(dProbs);
        sampleIdx = 1 + sum(cumProbs < rand());
        centers(clusterIdx) = angles(sampleIdx);
    end
    
    % Initialize "goodness-of-fit"-value
    fitError = realmax;
    
    % Perform circular k-means clustering
    for stepIdx = 1 : p.Results.MaxIter
        % Compute cluster distances for current set of centers
        distances = computeClusterDistances(angles, centers);
        
        % Assign datapoints to clusters with minimum distance
        [~, idx] = min(distances, [], 2);
        
        % Update cluster centers
        for centerIdx = nFixedCenters + 1 : nClusters
            % Get data points of current cluster
            clusterData = angles(idx == clusterIdx);
            
            % Compute circular mean
            centers(clusterIdx) = ...
                atan2(sum(sin(clusterData)) ./ length(clusterData), ...
                sum(cos(clusterData)) ./ length(clusterData));
        end
        
        % Evaluate "goodness-of-fit"
        fitErrorNew = sum(1 - cos(angles - centers(idx)));
        
        % Check for convergence
        if abs(fitError - fitErrorNew) < p.Results.ErrorThreshold
            % Terminate
            break;
        else
            % If not converged, proceed with next iteration.
            fitError = fitErrorNew;
        end
    end
    
    % Append results
    rIndices{rIdx} = idx;
    rCenters{rIdx} = centers;
    
    % Update minimum error
    if fitError < minError
        minError = fitError;
        bestIdx = rIdx;
    end
end

% Return result with minimum error
idx = rIndices{bestIdx};
centers = rCenters{bestIdx};

end

function distances = computeClusterDistances(angles, centers)
% COMPUTECLUSTERDISTANCES Computes circular distances from each angle of an
%   input dataset to each cluster center.
%
% REQUIRED INPUTS:
%   angles - Nx1 vector, containing N angular values, ranged between -pi
%       and pi.
%   centers - Kx1 vector of cluster centers.
%
% OUTPUTS:
%   distances - Nx1 distance vector.

% Check inputs
p = inputParser();

p.addRequired('angles', @(x) validateattributes(x, {'numeric'}, ...
    {'real', 'vector', '>=', -pi, '<=', pi}));
p.addRequired('centers', @(x) validateattributes(x, {'numeric'}, ...
    {'real', 'vector', '>=', -pi, '<=', pi}));
p.parse(angles, centers);

% Get number of data-points and number of clusters
nSamples = length(angles);
nClusters = length(centers);

% Initialize output
distances = zeros(nSamples, nClusters);

% Compute distances to each cluster center
for clusterIdx = 1 : nClusters
    distances(:, clusterIdx) = 1 - cos(angles - centers(clusterIdx));
end

end

