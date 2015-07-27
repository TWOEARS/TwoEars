classdef IdSimConvRoomWrapper < dataProcs.BinSimProcInterface
    
    %% --------------------------------------------------------------------
    properties (Access = protected)
        convRoomSim;
        sceneConfig;
        reverberationMaxOrder = 5;
        silenceLength_s = 0.5; % have some silence before and after sound
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdSimConvRoomWrapper()
            obj = obj@dataProcs.BinSimProcInterface();
            obj.convRoomSim = simulator.SimulatorConvexRoom();
            set(obj.convRoomSim, ...
                'BlockSize', 4096, ...
                'SampleRate', 44100, ...
                'MaximumDelay', 0.05, ... % for distances up to ~15m
                'Renderer', @ssr_binaural, ...
                'HRIRDataset', simulator.DirectionalIR( xml.dbGetFile( ...
                'impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa')) ...
                );
            set(obj.convRoomSim, ...
                'Sinks', simulator.AudioSink(2) ...
                );
            set(obj.convRoomSim.Sinks, ...
                'Position' , [0; 0; 1.75], ...
                'Name', 'Head' ...
                );
        end
        %% ----------------------------------------------------------------
        
        function delete( obj )
            obj.convRoomSim.set('ShutDown',true);
        end
        %% ----------------------------------------------------------------
        
        function setSceneConfig( obj, sceneConfig )
            obj.sceneConfig = sceneConfig;
        end
        %% ----------------------------------------------------------------

        function fs = getDataFs( obj )
            fs = obj.convRoomSim.SampleRate;
        end
        
        %% ----------------------------------------------------------------

        function process( obj, inputFileName )
            [obj.earSout, obj.onOffsOut] = obj.makeEarSignalsAndLabels( inputFileName );
        end
        %% ----------------------------------------------------------------
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.sceneConfig = obj.sceneConfig;
            outputDeps.SampleRate = obj.convRoomSim.SampleRate;
            outputDeps.ReverberationMaxOrder = obj.reverberationMaxOrder;
            rendererFunction = functions( obj.convRoomSim.Renderer );
            rendererName = rendererFunction.function;
            outputDeps.Renderer = rendererName;
            persistent hrirHash;
            persistent hrirFName;
            if isempty( hrirFName )  || ...
                    ~strcmpi( hrirFName, obj.convRoomSim.HRIRDataset.Filename )
                hrirFName = obj.convRoomSim.HRIRDataset.Filename;
                hrirHash = calcDataHash( audioread( hrirFName ) );
            end
            outputDeps.hrir = hrirHash;
            outputDeps.silenceLength_s = obj.silenceLength_s;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
        
        function [earSignals, earsOnOffs] = makeEarSignalsAndLabels( obj, wavFileName )
            sceneConfigInst = obj.sceneConfig.instantiate();
            [sounds, earsOnOffs] = obj.loadSounds( sceneConfigInst, wavFileName );
            obj.setupSceneConfig( sceneConfigInst );
            ovrlEarSignals = cell( length( sounds ), 1 );
            for ii = 1:length( sounds )
                if ii > 1 ... % ii == 1  is the original signal
                   && strcmpi( sceneConfigInst.typeOverlays{ii-1}, 'diffuse' )
                    ovrlEarSignals{ii} = sounds{ii}(1:min( length( sounds{ii} ), length( ovrlEarSignals{1} ) ),:);
                else
                    obj.setSourceData( sounds );
                    obj.setActiveSource( ii );
                    obj.simulate();
                    ovrlEarSignals{ii} = obj.convRoomSim.Sinks.getData();
                end
                fprintf( '\n' );
            end
            orgSignal = ovrlEarSignals{1};
            earSignals = orgSignal;
            for ii = 2:length( ovrlEarSignals )
                onOffs_samples = earsOnOffs .* obj.convRoomSim.SampleRate;
                if isempty( onOffs_samples ), onOffs_samples = 'energy'; end;
                ovrlSignal = ovrlEarSignals{ii};
                ovrlSignal = obj.adjustSNR( ...
                    orgSignal, onOffs_samples, ovrlSignal, sceneConfigInst.SNRs(ii-1).value );
                earSignals(1:min( length( earSignals ), length( ovrlSignal ) ),:) = ...
                    earSignals(1:min( length( earSignals ), length( ovrlSignal ) ),:) ...
                    + ovrlSignal;
            end
            earSignals = earSignals / max( abs( earSignals(:) ) ); % normalize
        end
        %% ----------------------------------------------------------------

        function setSourceData( obj, sounds )
            sigLen_s = length( sounds{1} ) / obj.convRoomSim.SampleRate;
            obj.convRoomSim.set( 'LengthOfSimulation', sigLen_s );
            obj.convRoomSim.Sinks.removeData();
            for m = 1:length(obj.convRoomSim.Sources)
                obj.convRoomSim.Sources{m}.setData( sounds{m} );
            end
        end
        %% ----------------------------------------------------------------
        
        function setActiveSource( obj, actIdx )
            for m = 1:length(obj.convRoomSim.Sources)
                obj.convRoomSim.Sources{m}.set( 'Volume', 0.0 );
                obj.convRoomSim.Sources{m}.set( 'Mute', 1 );
            end
            obj.convRoomSim.Sources{actIdx}.set( 'Mute', 0 );
            obj.convRoomSim.Sources{actIdx}.set( 'Volume', 1.0 );
        end
        %% ----------------------------------------------------------------

        function simulate( obj )
            obj.convRoomSim.set( 'ReInit', true );
            while ~obj.convRoomSim.isFinished()
                obj.convRoomSim.set('Refresh',true);  % refresh all objects
                obj.convRoomSim.set('Process',true);  % processing
                fprintf( '.' );
            end
            fprintf( '\n' );
        end
        %% ----------------------------------------------------------------

        function setupSceneConfig( obj, sceneConfig )
            obj.convRoomSim.set( 'ShutDown', true );
            if ~isempty(obj.convRoomSim.Sources), obj.convRoomSim.Sources(2:end) = []; end;
            useReverb = ~isempty( sceneConfig.room.value );
            if useReverb
                obj.convRoomSim.Room = sceneConfig.room.value; 
                obj.convRoomSim.Room.set( 'ReverberationMaxOrder', ...
                                          obj.reverberationMaxOrder );
            end
            obj.createNewSimSource( 1, useReverb, true, ...
                sceneConfig.distSignal.value, sceneConfig.angleSignal.value );
            for ii = 1:sceneConfig.numOverlays
                isPoint = strcmpi( sceneConfig.typeOverlays{ii}, 'point' );
                obj.createNewSimSource( ...
                    ii+1, useReverb, isPoint, ...
                    sceneConfig.distOverlays(ii).value, sceneConfig.angleOverlays(ii).value...
                    );
            end
            obj.convRoomSim.set('Init',true);
        end
        %% ----------------------------------------------------------------

        function createNewSimSource( obj, idx, useReverb, isPoint, radius, azmth )
            if isPoint 
                if useReverb
                    obj.convRoomSim.Sources{idx} = simulator.source.ISMGroup();
                    obj.convRoomSim.Sources{idx}.set( 'Room', ...
                                                      obj.convRoomSim.Room );
                else
                    obj.convRoomSim.Sources{idx} = simulator.source.Point();
                end
                channelMapping = [1];
                obj.convRoomSim.Sources{idx}.set( 'Radius', radius );
                obj.convRoomSim.Sources{idx}.set( 'Azimuth', azmth );
            else % ~isPoint
                obj.convRoomSim.Sources{idx} = simulator.source.Binaural();
                channelMapping = [1 2];
            end
            obj.convRoomSim.Sources{idx}.AudioBuffer = simulator.buffer.FIFO( channelMapping );
        end
        %% ----------------------------------------------------------------

        function [sounds, sigOnOffs] = loadSounds( obj, sceneConfig, wavFile )
            sounds{1} = getPointSourceSignalFromWav( ...
                wavFile, obj.convRoomSim.SampleRate, obj.silenceLength_s );
            sigOnOffs = ...
                IdEvalFrame.readOnOffAnnotations( wavFile ) + obj.silenceLength_s;
            sigClass = IdEvalFrame.readEventClass( wavFile );
            for kk = 1:sceneConfig.numOverlays
                ovrlFile = sceneConfig.fileOverlays(kk).value;
                ovrlStartOffset = sceneConfig.offsetOverlays(kk).value;
                if strcmpi( sceneConfig.typeOverlays{kk}, 'point' )
                    sounds{1+kk} = ...
                        getPointSourceSignalFromWav( ...
                            ovrlFile, obj.convRoomSim.SampleRate, ...
                            ovrlStartOffset );
                elseif strcmpi( sceneConfig.typeOverlays{kk}, 'diffuse' )
                    diffuseMonoSound = ...
                        getPointSourceSignalFromWav( ...
                            ovrlFile, obj.convRoomSim.SampleRate, ...
                            ovrlStartOffset );
                    sounds{1+kk} = repmat( diffuseMonoSound, 1, 2 );
                end
                ovrlClass = IdEvalFrame.readEventClass( ovrlFile );
                if strcmpi( ovrlClass, sigClass )
                    maxLen = length( sounds{1} ) / obj.convRoomSim.SampleRate;
                    ovrlOnOffs = IdEvalFrame.readOnOffAnnotations( ovrlFile ) ...
                        + ovrlStartOffset;
                    ovrlOnOffs( ovrlOnOffs(:,1) >= maxLen, : ) = [];
                    ovrlOnOffs( ovrlOnOffs > maxLen ) = maxLen;
                    sigOnOffs = sortAndMergeOnOffs( [sigOnOffs; ovrlOnOffs] );
                end
            end
        end
        %% ----------------------------------------------------------------

        function signal2 = adjustSNR( obj, signal1, sig1OnOffs, signal2, snrdB )
            %adjustSNR   Adjust SNR between two signals. Only parts of the
            %signal that actually exhibit energy are factored into the SNR
            %computation.
            %   This function is based on adjustSNR by Tobias May.

            signal1(:,1) = signal1(:,1) - mean( signal1(:,1) );
            signal1(:,2) = signal1(:,2) - mean( signal1(:,2) );
            if isa( sig1OnOffs, 'char' ) && strcmpi( sig1OnOffs, 'energy' )
                s1actL = obj.detectActivity( double(signal1(:,1)), 40, 50e-3, 50e-3, 10e-3 );
                s1actR = obj.detectActivity( double(signal1(:,2)), 40, 50e-3, 50e-3, 10e-3 );
                signal1 = signal1(s1actL | s1actR,:);
            else
                sig1OnOffs(sig1OnOffs>length(signal1)) = length(signal1);
                signal1activePieces = arrayfun( ...
                    @(on, off)(signal1(ceil(on):floor(off),:)) , sig1OnOffs(:,1), sig1OnOffs(:,2), ...
                    'UniformOutput', false );
                signal1 = vertcat( signal1activePieces{:} );
            end
            signal2(:,1) = signal2(:,1) - mean( signal2(:,1) );
            signal2(:,2) = signal2(:,2) - mean( signal2(:,2) );
            s2actL = obj.detectActivity( double(signal2(:,1)), 40, 50e-3, 50e-3, 10e-3 );
            s2actR = obj.detectActivity( double(signal2(:,2)), 40, 50e-3, 50e-3, 10e-3 );
            signal2 = signal2(s2actL | s2actR,:);
            
            if isfinite(snrdB)
                % Multi-channel energy of speech and noise signals
                e_sig1 = sum(sum(signal1.^2));
                e_sig2  = sum(sum(signal2.^2));
                e_sig1 = e_sig1 / length(signal1);
                e_sig2 = e_sig2 / length(signal2);
                
                % Compute scaling factor for noise signal
                gain = sqrt((e_sig1/(10^(snrdB/10)))/e_sig2);
                
                % Adjust the noise level to get required SNR
                signal2 = gain * signal2;
            elseif isequal(snrdB,inf)
                % Set the noise signal to zero
                signal2 = signal2 * 0;
            else
                error('Invalid value of snrdB.')
            end
        end
        %% ----------------------------------------------------------------
        
        function vad = detectActivity( obj, signal, thresdB, hSec, blockSec, stepSec )
            %detectActivity   Energy-based voice activity detection.
            %   This function is based on detectVoiceActivityKinnunen by
            %   Tobias May.
            %INPUT ARGUMENTS
            %           in : input signal [nSamples x 1]
            %      thresdB : energy threshold in dB, defining the dynamic range that is
            %                considered as speech activity (default, thresdB = 40)
            %       format : output format of VAD decision ('samples' or 'frames')
            %                (default, format = 'frames')
            %         hSec : hangover scheme in seconds (default, hSec = 50e-3)
            %     blockSec : blocksize in seconds (default, blockSec = 20e-3)
            %      stepSec : stepsize in seconds  (default, stepSec = 10e-3)
            %
            %OUTPUT ARGUMENTS
            %          vad : voice activity decision [nSamples|nFrames x 1]
            
            noiseFloor = -55;    % Noise floor
            
            % **************************  FRAME-BASED ENERGY  ************************
            blockSize = 2 * round(obj.convRoomSim.SampleRate * blockSec / 2);
            stepSize  = round(obj.convRoomSim.SampleRate * stepSec);
            
            frames = frameData(signal,blockSize,stepSize,'rectwin');
            
            energy = 10 * log10(squeeze(mean(power(frames,2),1) + eps));
            
            nFrames = numel(energy);
            
            % ************************  DETECT VOICE ACTIVITY  ***********************
            % Set maximum to 0 dB
            energy = energy - max(energy);
            
            frameVAD = energy > -abs(thresdB) & energy > noiseFloor;
            
            % Corresponding time vector in seconds
            tFramesSec = (stepSize:stepSize:stepSize*nFrames).'/obj.convRoomSim.SampleRate;
            
            % ***************************  HANGOVER SCHEME  **************************
            % Determine length of hangover scheme
            hangover = max(0,1+floor((hSec - blockSec)/stepSec));
            
            % Check if hangover scheme is active
            if hangover > 0
                % Initialize counter
                hangCtr = 0;
                
                % Loop over number of frames
                for ii = 1 : nFrames
                    % VAD decision
                    if frameVAD(ii) == true
                        % Speech detected, activate hangover scheme
                        hangCtr = hangover;
                    else
                        % Speech pause detected
                        if hangCtr > 0
                            % Delay detection of speech pause
                            frameVAD(ii) = true;
                            % Decrease hangover counter
                            hangCtr = hangCtr - 1;
                        end
                    end
                end
            end
            
            % *************************  RETURN VAD DECISION  ************************
            % Time vector in seconds
            tSec = (1:length(signal)).'/obj.convRoomSim.SampleRate;
            
            % Convert frame-based VAD decision to samples
            vad = interp1(tFramesSec,double(frameVAD),tSec,'nearest','extrap');
            
            % Return logical VAD decision
            vad = logical(vad).';
        end
        
    end
    
    
end
