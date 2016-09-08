function [C, idx] = findNearestNeighbour(A, b, nNeighbours)
%findNearestNeighbour finds the n nearest neighbours
%
%   USAGE
%       [C, idx] = findNearestNeighbour(A, b, [nNeighbours])
%
%   Input parameters:
%       A            - matrix
%       b            - column to search for in A
%       nNeighbours  - number of nearest neighbours to find (default: 1)
%
%   output parameters:
%       C            - found neighbour columns
%       idx          - indices of found columns in matrix

% Default nNeighbours = 1
if nargin == 2
    nNeighbours = 1;
end
% Ensure column vector
if size(b, 2) > 1
    b = b';
end
% Calculate distance between points
distance = sum( abs(bsxfun(@minus,A,b)).^2, 1 ) .^ (1/2);
% Sort the distances in order to find the n lowest once
[~,idx] = sort(distance);
idx = idx(1:min(nNeighbours, length(idx)));
C = A(:, idx);
