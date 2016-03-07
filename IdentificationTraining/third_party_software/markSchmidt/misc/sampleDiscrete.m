function [y] = sampleDiscrete(p)
% Returns a sample from a discrete probability mass function indexed by p
% (assumes that p is already normalized)
y = find(cumsum(p) > rand,1);