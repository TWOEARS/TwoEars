classdef JidoRecInterface < handle
    %JIDOINTERFACE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess = public, SetAccess = private)
        BlockSize               % Block size used by the audio stream 
                                % server in samples.
        SampleRate              % Sample rate of the audio stream server 
                                % in Hz.
        AzimuthMax              % Maximum azimuthal look direction of the 
                                % KEMAR head in degrees.
        AzimuthMin              % Minimum azimuthal look direction of the
                                % KEMAR head in degrees.
        blockIdx
        curTime_s
        endTime_s
        normFactor
    end
    
    properties (Access = public)
        bass                    % Interface to the audio stream server.
        kemar                   % KEMAR control interface.
    end
    
    methods (Access = public)
        function obj = JidoRecInterface(pathToRecording, blockSize)
            % JIDOINTERFACE Constructor...
            if exist(pathToRecording, 'file') ~= 2
                error('Invalid path to recorded data');
            end
            
            % Load BASS module
            obj.bass = load(pathToRecording, 'BASS');
            obj.bass = obj.bass.('BASS');

            sigSorted = sort( abs( [obj.bass(1:obj.bass(1).nChunksOnPort:end).left obj.bass(1:obj.bass(1).nChunksOnPort:end).right] ) );
            sigSorted(sigSorted<=0.1*mean(sigSorted)) = [];
            nUpperSigSorted = round( numel( sigSorted ) * 0.01 );
            obj.normFactor = 0.2 / median( sigSorted(end-nUpperSigSorted:end) ); % ~0.995 percentile

            % Load KEMAR module
            vars = whos('-file', pathToRecording);
            if ismember('JidoCurrentPosition', {vars.name})
                 obj.kemar = load(pathToRecording, 'JidoCurrentPosition');
                % Get KEMAR properties
                obj.kemar = obj.kemar.('JidoCurrentPosition');
            else
                obj.kemar = [];
            end
            
            % Get BASS status info
            obj.blockIdx = 1;
            obj.SampleRate =  obj.bass(obj.blockIdx).sampleRate;
            if nargin > 1
                if mod( blockSize, obj.bass(obj.blockIdx).nFramesPerChunk ) ~= 0
                    error( 'choose blocklengths that are multiples of bass chunk size' );
                end
                obj.BlockSize = blockSize;
            else
                obj.BlockSize = obj.bass(obj.blockIdx).nFramesPerChunk * ...
                    obj.bass(obj.blockIdx).nChunksOnPort;
            end
            obj.seekTime(0);
            obj.setEndTime( obj.calcRelBlockTimeStamp( numel(obj.bass) ) );
            
        end
        
        function t = calcRelBlockTimeStamp(obj, idx)
            t = (idx-1) * obj.bass(idx).nFramesPerChunk / obj.SampleRate;
        end
        
        function seekTime(obj, t)
            % seek to a specific time
            while obj.calcRelBlockTimeStamp(obj.blockIdx) < t && ...
                    obj.blockIdx <= numel(obj.bass)
                obj.blockIdx = obj.blockIdx + 1;
            end
            obj.curTime_s = obj.calcRelBlockTimeStamp(obj.blockIdx);
        end
        
        function setEndTime(obj, t)
            % set maximum timestamp to process
            obj.endTime_s = t;
        end
        
        function configureAudioStreamServer(obj, sampleRate, frameSize, ...
                bufferSizeSec)
            % CONFIGUREAUDIOSTREAMSERVER
            error('Operation not supported.')
        end
        
        function [earSignals, signalLengthSec] = getSignal(obj, ...
                timeDurationSec)
            % GETSIGNAL This function acquires binaural signals from the
            %   robot via the binaural audio stream server.
            % Read audio buffer
            audioBuffer = obj.bass(obj.blockIdx);
            
            % Get binaural signals
            % Sclaing factor estimated empirically
%             earSignals = [audioBuffer.left ./ (2^31); ...
%                 0.7612 .* (audioBuffer.right ./ (2^31))]';
            earSignals = [audioBuffer.left ./ (2^31); ...
                          audioBuffer.right ./ (2^31)]';
%             earSignals = [audioBuffer.left * obj.normFactor; ...
%                           audioBuffer.right * obj.normFactor]';
            
            % Get default buffer size of the audio stream server
            bufferSize = size(earSignals, 1);
            
            % Convert desired chunk length into samples
            if nargin == 2
                chunkLength = round(timeDurationSec * obj.SampleRate);
            else
                chunkLength = bufferSize;
            end
            
            chunkLenSec = obj.bass(obj.blockIdx).nFramesPerChunk / ...
                                                        obj.bass(obj.blockIdx).sampleRate;
            if mod( timeDurationSec, chunkLenSec ) ~= 0
                error( 'choose blocklengths that are multiples of bass chunk size' );
            end
            % Check if chunk length is smaller than buffer length
            if chunkLength > bufferSize
                error(['Desired chunk length exceeds length of the ', ...
                    'audio buffer.']);
            end
            
            % Get corresponding signal chunk
            earSignals = earSignals(1:chunkLength, :);
            
            % Get signal length
            signalLengthSec = length(earSignals) / ...
                audioBuffer.sampleRate;
            
            obj.curTime_s = obj.calcRelBlockTimeStamp(obj.blockIdx);
            obj.blockIdx = obj.blockIdx + (timeDurationSec / chunkLenSec);
        end
        
        function moveRobot(obj, posX, posY, theta, varargin)
            % MOVEROBOT
            error('Operation not supported for this recording.');
        end
        
        function rotateHead(obj, angle, varargin)
            % ROTATEHEAD
            error('Operation not supported for this recording.');
        end
        
        function azimuth = getCurrentHeadOrientation(obj)
            % GETCURRENTHEADORIENTATION
            % TODO proper implementation
            if isempty(obj.kemar)
                azimuth = 0;%error('Operation not supported for this recording.');
            else
                azimuth = 0;%obj.kemar(ceil(obj.blockIdx/2)).pose.orientation.w;
            end
        end
        
        function delete(obj)
            % DELETE Destructor
            
            % Shut down the audio stream
            delete(obj.bass);
            clear obj.bass;
            
            if ~isempty(obj.kemar)
                delete(obj.kemar);
                clear obj.kemar;
            end
        end
        
        function result = isActive(obj)
            result = ~obj.isFinished();
        end
        
        function result = isFinished(obj)
            result = obj.blockIdx >= numel(obj.bass) || obj.curTime_s >= obj.endTime_s;
        end
    end
end