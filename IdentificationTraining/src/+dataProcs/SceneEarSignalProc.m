classdef SceneEarSignalProc < dataProcs.BinSimProcInterface
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        sceneConfig;
        binauralSim;
        outputWavFileName;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = SceneEarSignalProc( binauralSim )
            obj = obj@dataProcs.BinSimProcInterface();
            if ~isa( binauralSim, 'dataProcs.BinSimProcInterface' )
                error( 'binauralSim must implement dataProcs.BinSimProcInterface.' );
            end
            obj.binauralSim = binauralSim;
            obj.sceneConfig = sceneConfig.SceneConfiguration.empty;
        end
        %% ----------------------------------------------------------------
        
        function setSceneConfig( obj, sceneConfig )
            obj.configChanged = true;
            obj.sceneConfig = sceneConfig;
        end
        %% ----------------------------------------------------------------

        function fs = getDataFs( obj )
            fs = obj.binauralSim.getDataFs();
        end
        %% ----------------------------------------------------------------

        function process( obj, inputFileName )
            obj.makeEarsignalsAndLabels( inputFileName );
            obj.outputWavFileName = inputFileName;
        end
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            obj.binauralSim.setSceneConfig( sceneConfig.SceneConfiguration.empty );
            outputDeps.binSimCfg = obj.binauralSim.getInternOutputDependencies;
            outputDeps.sc = obj.sceneConfig;
        end
        %% ----------------------------------------------------------------
        
        function makeEarsignalsAndLabels( obj, wavFileName )
            sc = obj.sceneConfig.instantiate();
            obj.onOffsOut = [];
            for ii = 1 : numel( sc.sources )
                sceneConf = sc.getSingleConfig(ii);
                if ii == 1
                    sceneConf.sources(1).data = sceneConfig.FileListValGen( wavFileName );
                    srcClass{ii} = IdEvalFrame.readEventClass( wavFileName );
                elseif isa( sceneConf.sources(1).data, 'sceneConfig.FileListValGen' )
                    wavFileName = sceneConf.sources(1).data.value;
                    if isempty( wavFileName )
                        error( 'Empty wav file name through use of FileListValGen!' );
                    end
                    srcClass{ii} = IdEvalFrame.readEventClass( wavFileName );
                else
                    wavFileName = ''; % don't save
                    srcClass{ii} = '';
                end
                obj.binauralSim.setSceneConfig( sceneConf );
                splitOut = obj.binauralSim.processSaveAndGetOutput( wavFileName );
                splitEarSignals{ii} = splitOut.earSout;
                if strcmpi( srcClass{ii}, srcClass{1} )
                    maxLen = length( splitEarSignals{1} ) / obj.getDataFs();
                    splitOnOffs = splitOut.onOffsOut;
                    splitOnOffs( splitOnOffs(:,1) >= maxLen, : ) = [];
                    splitOnOffs( splitOnOffs > maxLen ) = maxLen;
                    obj.onOffsOut = sortAndMergeOnOffs( [obj.onOffsOut; splitOnOffs] );
                end
                fprintf( ':' );
            end
            fprintf( ':' );
            obj.earSout = splitEarSignals{1};
            for ii = 2:length( splitEarSignals )
                onOffs_samples = obj.onOffsOut .* obj.getDataFs();
                if isempty( onOffs_samples ), onOffs_samples = 'energy'; end;
                ovrlSignal = splitEarSignals{ii};
                ovrlSignal = obj.adjustSNR( ...
                    splitEarSignals{1}, onOffs_samples, ovrlSignal, sc.SNRs(ii).value );
                obj.earSout(1:min( length( obj.earSout ), length( ovrlSignal ) ),:) = ...
                    obj.earSout(1:min( length( obj.earSout ), length( ovrlSignal ) ),:) ...
                    + ovrlSignal(1:min( length( obj.earSout ), length( ovrlSignal ) ),:);
                fprintf( '.' );
            end
            fprintf( '\n' );
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
            signal2act = signal2(s2actL | s2actR,:);
            
            if isfinite(snrdB)
                % Multi-channel energy of speech and noise signals
                e_sig1 = sum(sum(signal1.^2));
                e_sig2  = sum(sum(signal2act.^2));
                e_sig1 = e_sig1 / length(signal1);
                e_sig2 = e_sig2 / length(signal2act);
                
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
            blockSize = 2 * round(obj.getDataFs() * blockSec / 2);
            stepSize  = round(obj.getDataFs() * stepSec);
            
            frames = frameData(signal,blockSize,stepSize,'rectwin');
            
            energy = 10 * log10(squeeze(mean(power(frames,2),1) + eps));
            
            nFrames = numel(energy);
            
            % ************************  DETECT VOICE ACTIVITY  ***********************
            % Set maximum to 0 dB
            energy = energy - max(energy);
            
            frameVAD = energy > -abs(thresdB) & energy > noiseFloor;
            
            % Corresponding time vector in seconds
            tFramesSec = (stepSize:stepSize:stepSize*nFrames).'/obj.getDataFs();
            
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
            tSec = (1:length(signal)).'/obj.getDataFs();
            
            % Convert frame-based VAD decision to samples
            vad = interp1(tFramesSec,double(frameVAD),tSec,'nearest','extrap');
            
            % Return logical VAD decision
            vad = logical(vad).';
        end
    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end
