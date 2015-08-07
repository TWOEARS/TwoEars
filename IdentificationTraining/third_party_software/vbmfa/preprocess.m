function [Y,ppp] = preprocess(Y,ppp,shrinkQ);

%[Yout,ppp] = preprocess(Yraw);          OR
%      Yraw = preprocess(Yout,ppp,shrinkQ);
%
% Yraw - p x N matrix of raw observations
% Yout - p x N matrix of processed observations
% ppp - p x 2 matrix, the columns being the sample mean and
%  sample standard deviation of each output dimension in Yraw.
% shrinkQ - 1: shrinks similarly according to ppp
%           0: expands to invert shrinking according to ppp
%
%Matthew J. Beal GCNU 10/10/00

n = size(Y,2);
if nargin == 1
  ppp = [mean(Y,2) std(Y,1,2)];
  Y = Y - repmat(ppp(:,1),[1 n]);
  Y = diag(sparse(1./ppp(:,2)))*Y;
end

if nargin == 3
  % ppp is specified, but how to use it?
  if shrinkQ == 0
    % want to INVERT a shrinking
    Y = diag(sparse(ppp(:,2)))*Y;
    Y = Y + repmat(ppp(:,1),[1 n]);
  else
    % want to do a SIMILAR shrinking (on test data perhaps)
    Y = Y - repmat(ppp(:,1),[1 n]);
    Y = diag(sparse(1./ppp(:,2)))*Y;
  end
end