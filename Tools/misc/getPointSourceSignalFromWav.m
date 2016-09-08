function sourceWavSignal = getPointSourceSignalFromWav( wavName, targetFs, zeroOffsetLength_s, normalize, downmixMethod )

[sourceWavSignal,wavFs] = audioread( wavName );

% Stereo signals don't make sense. 
if ~isvector( sourceWavSignal )
    if nargin < 5, downmixMethod = 'downmix'; end % power and spectral leakage?
    sourceWavSignal = forceMono( sourceWavSignal, downmixMethod );
end

% Resample source signal if required
if wavFs ~= targetFs
    sourceWavSignal = resample(sourceWavSignal, targetFs, wavFs);
end

% Normalize source signal
if nargin < 4, normalize = true; end
if normalize
    sourceWavSignal = sourceWavSignal ./ max( abs( sourceWavSignal(:) ) );
end

% add some zero-signal to beginning and end
zeroOffset = zeros( floor( targetFs * zeroOffsetLength_s ), 1 ) + mean( sourceWavSignal );
sourceWavSignal = [zeroOffset; sourceWavSignal; zeroOffset];

sourceWavSignal = single( sourceWavSignal );  % single is good enough for wav data