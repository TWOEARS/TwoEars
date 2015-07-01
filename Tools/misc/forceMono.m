function signal = forceMono(signal,method)
%FORCEMONO converts signal into a mono signal
%
%   forceMono(signal) retruns a downmix by averaging the single channels.
%
%   forceMono(signal,method) returns a downmix by applying the given downmix
%   method, which could be one of the following:
%       'downmix'   - average the channels (default)
%       'max'       - use the channel with the maximum energy
%       'first'     - always use the first channel

% AUTHOR: Hagen Wierstorf

narginchk(1,2)
if nargin<2
    method = 'downmix';
end
if size(signal,2)>1
    switch method
        case 'downmix'
            signal = mean(signal,2);
        case 'max'
            [~,idx] = max(rms(signal)); % find the channel with highest energy
            signal = signal(:,idx);
        case 'first'
            signal = signal(:,1);
        otherwise
            error('%s: not a valid downmix method, see `help forceMono`',method)
    end
end
