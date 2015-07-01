function [cfHz,nFilters] = createFreqAxisLog(lowFreqHz,highFreqHz,nFilters)

if nargin < 3; nFilters = []; end

if lowFreqHz <= 0
    error('Lower frequency limit must be larger than 0 Hz when using log-spaced filters.')
end

if ~isempty(lowFreqHz) && ~isempty(highFreqHz) && ~isempty(nFilters)
    % 1. Frequency range and number of filters specified
    cfHz = pow2(linspace(log2(lowFreqHz),log2(highFreqHz),nFilters));
elseif ~isempty(lowFreqHz) && ~isempty(highFreqHz) && isempty(nFilters)
    % 2. Only frequency range is specified
    cfHz = pow2(log2(lowFreqHz):log2(highFreqHz));
    nFilters = numel(cfHz);
else
    error('Not enough or incoherent input arguments.')
end



