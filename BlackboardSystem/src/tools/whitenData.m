function [nData, dataMean, whiteningMatrix] = whitenData(data)
% WHITENDATA This function performs a whitening
%   transformation on a matrix containing data points.
%
% REQUIRED INPUTS:
%   data - Input data matrix of dimensions N x D, where N is
%       the number of data samples and D is the data dimension.
%
% OUTPUTS:
%   nData - Normalized data matrix, having zero mean and unit
%       variance.
%   dataMean - D x 1 vector, representing the mean of the data
%              samples.
%   whiteningMatrix - Transformation matrix for performing the
%       whitening transform on the given dataset.

% Check inputs
p = inputParser();

p.addRequired('data', @(x) validateattributes(x, ...
    {'numeric'}, {'real', '2d'}));
p.parse(data);

% Check if data matrix is skinny
[nSamples, nDims] = size(data);
if nDims >= nSamples
    error(['The number of data samples must be ', ...
        'greater than the data dimension.']);
end

% Compute mean and covariance matrix of the input data
dataMean = mean(p.Results.data);
dataCov = cov(p.Results.data);

% Compute whitening matrix
[V, D] = eig(dataCov);
whiteningMatrix = ...
    V * diag(1 ./ (diag(D) + eps).^(1/2)) * V';

% Compute normalized dataset
nData = ...
    bsxfun(@minus, p.Results.data, dataMean) * whiteningMatrix;
end