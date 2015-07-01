function signal = normalise(signal)
% normalise(signal) normalises the amplitude of the given signal to the range of
% ]-1:1[.

% AUTHOR: Hagen Wierstorf

narginchk(1,1);
% Scaling the signal to -1<sig<1
signal = signal / (max(abs(signal(:)))+eps);
