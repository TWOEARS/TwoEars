function varargout = readAudioFiles(audioFiles,varargin)
%READAUDIOFILES returns a matrix containing mono signals as columns
%
%   readAudioFiles(audioFiles) reads all signals from the files specified in the
%   audioFiles cell array and returns a matrix with each signal as a column.
%   Note, that all files that have more than one channel are automatically
%   down-mixed into a mono file.
%
%   Possible options and its default values:
%
%       'Samplingrate' - Desired samplingrate of output signals, default: 44100
%       'Normalize'    - Normalize output signals to -1..1, default: false
%       'Zeropadding'  - Adds nSamples of zeros at the beginning and end, default: 0
%       'Length'       - Specifies length of output signals, default: maximum of
%                        input signals. In samples.
%       'Method'       - Specifies downmix method for mono downmix. See
%                        `help forceMono` for available options, default: 'downmix'

% AUTHOR: Hagen Wierstorf


%% === Parse input arguments ===
parser = inputParser;
% Set default values for optional arguments
parser.addOptional('Samplingrate',44100);
parser.addOptional('Normalize',false);
parser.addOptional('Zeropadding',0);
parser.addOptional('Length',[]);
parser.addOptional('Method','downmix');
% Parse input arguments
parser.parse(varargin{:});
fsDesired = parser.Results.Samplingrate;
doNormalization = parser.Results.Normalize;
nZeros = parser.Results.Zeropadding;
sigLength = parser.Results.Length;
downmixMethod = parser.Results.Method;
if ~iscell(audioFiles), audioFiles = {audioFiles}; end
if nargout>1, doLabels=true; else doLabels=false; end


%% === Read audio files ===
% Number of audio files
nFiles = numel(audioFiles);
% Get information about all signals
for ii = 1:nFiles
    info(ii) = audioinfo(xml.dbGetFile(audioFiles{ii}));
end
% Set length of signal in samples if not specified
if isempty(sigLength)
    sigLength = round(max(info.Duration)*fsDesired) + 2*nZeros;
end
% Allocate memory for signals
signals = zeros(sigLength,nFiles);
% Loop over number of audio files
for ii = 1:nFiles
    % Read ii-th signal, usingthe same precission as the original file
    [currSig,fs] = audioread(xml.dbGetFile(audioFiles{ii}),'double');
    % Mono downsampling and resampling, if required
    currSig = forceMono(resample(currSig,fsDesired,fs),downmixMethod);
    % Add zeros at the end to match longest signal
    signals(:,ii) = [zeros(nZeros,1); currSig(1:min(end,sigLength-2*nZeros)); zeros(sigLength-size(currSig,1)-nZeros,1)];
    if doNormalization
        % Normalize signal by its maximum value
        signals(:,ii) = signals(:,ii) ./ (max(abs(signals(:,ii)))+eps);
    end
end
varargout{1} = signals;

%% === Read label files if desired ===
if nargout>1
    % Check if function is loaded
    if ~which('IdEvalFrame')
        error('The Two!Ears Blackboard System module needs to be loaded.');
    end
    for ii = 1:nFiles
        labels(ii).filename = audioFiles{ii};
        labels(ii).class = IdEvalFrame.readEventClass( audioFiles{ii} );
        labels(ii).onsetsOffsets = ...
            IdEvalFrame.readOnOffAnnotations(audioFiles{ii}) + nZeros/fsDesired;
        labels(ii).onsetsOffsets(labels(ii).onsetsOffsets(:,1) == inf,:) = [];
        labels(ii).onsetsOffsets(labels(ii).onsetsOffsets(:,2) == inf,:) = [];
    end
    varargout{2} = labels;
end
