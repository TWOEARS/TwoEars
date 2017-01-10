classdef SceneEarSignalProc < DataProcs.IdProcWrapper
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        sceneConfig;
        binauralSim;        % binaural simulator
%        ratemapAFE;
        earSout;
        annotsOut;
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = SceneEarSignalProc( binauralSim )
%            ratemapAfeRequest{1}.name = 'ratemap';
%            ratemapAfeRequest{1}.params = genParStruct( ...
%                'pp_bNormalizeRMS', false, ...
%                'rm_scaling', 'power', ...
%                'fb_nChannels', 64 );
%            afe = DataProcs.AuditoryFEmodule( binauralSim.getDataFs(), ratemapAfeRequest );
%            obj = obj@DataProcs.IdProcWrapper( {binauralSim,afe}, false );
            obj = obj@DataProcs.IdProcWrapper( binauralSim, false );
            obj.binauralSim = obj.wrappedProcs{1};
%            obj.ratemapAFE = obj.wrappedProcs{2};
            obj.sceneConfig = SceneConfig.SceneConfiguration.empty;
%            obj.ratemapAFE.setInputProc( obj.binauralSim );
        end
        %% ----------------------------------------------------------------

        function setSceneConfig( obj, sceneConfig )
            obj.sceneConfig = sceneConfig;
        end
        %% ----------------------------------------------------------------

        function fs = getDataFs( obj )
            fs = obj.binauralSim.getDataFs();
        end
        %% ----------------------------------------------------------------

        function process( obj, pipeWavFilepath )
            numSrcs = numel( obj.sceneConfig.sources );
            obj.annotsOut.srcType = struct( 't', struct( 'onset', {[]}, 'offset', {[]} ), ...
                                            'srcType', {cell(0,2)} );
            obj.annotsOut.srcFile = struct( 't', struct( 'onset', {[]}, 'offset', {[]} ), ...
                                            'srcFile', {cell(0,2)} );
            
            switch obj.sceneConfig.lenRefType
                case 'time'
                    targetSignalLen = ...
                                 max( obj.sceneConfig.lenRefArg, obj.sceneConfig.minLen );
                    targetLenSourceRef = 1;
                    adaptTargetLen = false;
                case 'source'
                    targetSignalLen = obj.sceneConfig.minLen;
                    targetLenSourceRef = obj.sceneConfig.lenRefArg;
                    adaptTargetLen = true;
                otherwise
                    error( 'Unknown SceneConfig.lenRefType' );
            end
            srcIndexes = 1 : numSrcs;
            srcIndexes(targetLenSourceRef) = [];
            srcIndexes = [targetLenSourceRef srcIndexes];
            
            splitEarSignals = cell( numSrcs, 1 );
            tSplitAzms = cell(numSrcs,1);
            splitAzms = cell(numSrcs,1);
%            splitRms = cell(numSrcs,2);
            for srcIdx = srcIndexes
                splitSignalLen = 0;
                while (splitSignalLen == 0) || (splitSignalLen < targetSignalLen - 0.01)
                    if (splitSignalLen == 0) || ...
                                  strcmpi( obj.sceneConfig.loopSrcs{srcIdx}, 'randomSeq' )
                        sc = obj.sceneConfig.getSingleConfig( srcIdx );
                        scInst = sc.instantiate(); % TODO: problem: this not only creates
                                                   % loop variations in the files, but
                                                   % in all ValGens, so maybe azm etc...
                        if isa( scInst.sources(1).data, 'SceneConfig.FileListValGen' )
                            if strcmp( scInst.sources(1).data.value, 'pipeInput' )
                                scInst.sources(1).data = ...
                                    SceneConfig.FileListValGen( pipeWavFilepath );
                            end
                            splitWavFilepath = scInst.sources(1).data.value;
                        else % data through ValGen like NoiseValGen
                            splitWavFilepath = ''; % don't cache in binauralSim
                        end
                        obj.binauralSim.setSceneConfig( scInst );
                        splitOut = ...
                              obj.binauralSim.processSaveAndGetOutput( splitWavFilepath );
%                        splitOutRm = ...
%                               obj.ratemapAFE.processSaveAndGetOutput( splitWavFilepath );
                    end
                    if ~isempty( splitEarSignals{srcIdx} )
                        splitOut.earSout = DataProcs.SceneEarSignalProc.adjustSNR( ...
                                             obj.getDataFs(), splitEarSignals{srcIdx}, ...
                                                          'energy', splitOut.earSout, 0 );
                    end
                    tSoFar = size( splitEarSignals{srcIdx}, 1 ) / obj.getDataFs();
                    splitEarSignals{srcIdx} = [splitEarSignals{srcIdx}; splitOut.earSout];
                    tSplitAzms{srcIdx} = ...
                             [tSplitAzms{srcIdx} (tSoFar+splitOut.annotations.srcAzms.t)];
                    splitAzms{srcIdx} = ...
                                 [splitAzms{srcIdx}; splitOut.annotations.srcAzms.srcAzms];
 %                   rm = splitOutRm.afeData(1);
 %                   splitRms{srcIdx,1} = [splitRms{srcIdx,1}; [rm{1}.Data(:); rm{1}.Data(end,:)]];
 %                   splitRms{srcIdx,2} = [splitRms{srcIdx,2}; [rm{2}.Data(:); rm{2}.Data(end,:)]];
                    obj.annotsOut.srcType.t.onset = [obj.annotsOut.srcType.t.onset ...
                                           (tSoFar+splitOut.annotations.srcType.t.onset)];
                    obj.annotsOut.srcType.t.offset = [obj.annotsOut.srcType.t.offset ...
                                          (tSoFar+splitOut.annotations.srcType.t.offset)];
                    if ~isempty( splitOut.annotations.srcType.srcType )                  
                        splitOut.annotations.srcType.srcType(:,2) = ...
                             repmat( {srcIdx}, ...
                                     size( splitOut.annotations.srcType.srcType, 1 ), 1 );
                    end
                    obj.annotsOut.srcType.srcType = [obj.annotsOut.srcType.srcType; ...
                                                    splitOut.annotations.srcType.srcType];
                    obj.annotsOut.srcFile.t.onset = [obj.annotsOut.srcFile.t.onset ...
                                           (tSoFar+splitOut.annotations.srcFile.t.onset)];
                    obj.annotsOut.srcFile.t.offset = [obj.annotsOut.srcFile.t.offset ...
                                          (tSoFar+splitOut.annotations.srcFile.t.offset)];
                    if ~isempty( splitOut.annotations.srcFile.srcFile )                  
                        splitOut.annotations.srcFile.srcFile(:,2) = ...
                            repmat( {srcIdx}, ...
                                     size( splitOut.annotations.srcFile.srcFile, 1 ), 1 );
                    end
                    obj.annotsOut.srcFile.srcFile = [obj.annotsOut.srcFile.srcFile; ...
                                                    splitOut.annotations.srcFile.srcFile];
                    
                    splitSignalLen = size( splitEarSignals{srcIdx}, 1 ) / obj.getDataFs();
                    if adaptTargetLen && (srcIdx == targetLenSourceRef)
                        targetSignalLen = max( splitSignalLen, targetSignalLen );
                    elseif strcmp( obj.sceneConfig.loopSrcs{srcIdx}, 'no' ) ...
                                             && (splitSignalLen >= obj.sceneConfig.minLen)
                        break;
                    end
                end
                fprintf( ':' );
            end
            if strcmp( obj.sceneConfig.lenRefType, 'source' )
                mixLen = size( splitEarSignals{srcIndexes(1)}, 1 );
            else
                mixLen = min( cellfun( @(s)(size( s, 1 )), splitEarSignals ) );
            end
            for ss = 1 : numSrcs
                if size( splitEarSignals{ss}, 1 ) > mixLen
                    splitEarSignals{ss}(mixLen+1:end,:) = [];
                elseif size( splitEarSignals{ss}, 1 ) < mixLen
                    splitEarSignals{ss}(end+1:mixLen,:) = ...
                                     repmat( mean( splitEarSignals{ss} ), ...
                                             mixLen - size( splitEarSignals{ss}, 1 ), 1 );
                end
            end
            onsetOutside = obj.annotsOut.srcType.t.onset > (mixLen / obj.getDataFs());
            obj.annotsOut.srcType.t.onset(onsetOutside) = [];
            obj.annotsOut.srcType.t.offset(onsetOutside) = [];
            obj.annotsOut.srcType.srcType(onsetOutside,:) = [];
            fprintf( '::' );
            
            obj.annotsOut.srcAzms = struct( 't', {[]}, 'srcAzms', {[]} );
            obj.annotsOut.srcAzms.t = unique( single( [tSplitAzms{:}] ) );
            tAzmOutside = obj.annotsOut.srcAzms.t > (mixLen / obj.getDataFs());
            obj.annotsOut.srcAzms.t(tAzmOutside) = [];
            for ii = 1 : numSrcs
                obj.annotsOut.srcAzms.srcAzms(:,ii) = single( interp1( tSplitAzms{ii}, ...
                             splitAzms{ii}, obj.annotsOut.srcAzms.t, 'next', 'extrap' ) );
            end

            obj.annotsOut.srcEnergy = struct( 't', {[]} );
            for ss = 1 : numSrcs
                [energy1, tEnergy] = DataProcs.SceneEarSignalProc.runningEnergy( ...
                                                     obj.getDataFs(), ...
                                                     double(splitEarSignals{ss}(:,1)), ...
                                                     20e-3, 10e-3 );
                [energy2, ~] = DataProcs.SceneEarSignalProc.runningEnergy( ...
                                                     obj.getDataFs(), ...
                                                     double(splitEarSignals{ss}(:,2)), ...
                                                     20e-3, 10e-3 );
                if numel( tEnergy ) > numel( obj.annotsOut.srcEnergy.t )
                    obj.annotsOut.srcEnergy.t = single( tEnergy );
                end
                obj.annotsOut.srcEnergy.srcEnergy(:,ss) = ...
                          arrayfun( @(e1,e2)( {single( [e1,e2] )} ), energy1', energy2' );
            end
            
            obj.earSout = zeros( mixLen, 2 );
            for srcIdx = 1 : numel( splitEarSignals )
                srcNsignal = splitEarSignals{srcIdx};
                srcSidx = obj.sceneConfig.snrRefs(srcIdx);
                if srcSidx == srcIdx
                    srcNsignal = splitEarSignals{srcSidx};
                else
                    srcSsignal = splitEarSignals{srcSidx};
                    srcNsignal = DataProcs.SceneEarSignalProc.adjustSNR( ...
                                                     obj.getDataFs(), ...
                                                     srcSsignal, ...
                                                    'energy', ...
                                                     srcNsignal, ...
                                                     obj.sceneConfig.SNRs(srcIdx).value );
                end
                maxSignalsLen = min( mixLen, length( srcNsignal ) );
                obj.earSout(1:maxSignalsLen,:) = ...
                    obj.earSout(1:maxSignalsLen,:) + srcNsignal(1:maxSignalsLen,:);
                fprintf( '.' );
            end
            if obj.sceneConfig.normalize
                earSoutRMS = max( rms( obj.earSout ) );
                obj.earSout = obj.earSout * obj.sceneConfig.normalizeLevel / earSoutRMS;
            end
            obj.earSout = single( obj.earSout );
            
            [energy1, tEnergy] = DataProcs.SceneEarSignalProc.runningEnergy( ...
                                                             obj.getDataFs(), ...
                                                             double(obj.earSout(:,1)), ...
                                                             20e-3, 10e-3 );
            [energy2, ~] = DataProcs.SceneEarSignalProc.runningEnergy( ...
                                                             obj.getDataFs(), ...
                                                             double(obj.earSout(:,2)), ...
                                                             20e-3, 10e-3 );
            obj.annotsOut.mixEnergy.t = single( tEnergy );
            obj.annotsOut.mixEnergy.mixEnergy = single( [energy1',energy2'] );
        end
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.sceneCfg = obj.sceneConfig;
            % SceneEarSignalProc doesn't (/must not) depend on the binSim's sceneConfig
            obj.binauralSim.setSceneConfig( SceneConfig.SceneConfiguration.empty );
            outputDeps.wrapDeps = getInternOutputDependencies@DataProcs.IdProcWrapper( obj );
            outputDeps.v = 2;
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj, varargin )
            out.earSout = obj.earSout;
            out.annotations = obj.annotsOut;
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Static)
        function signal2 = adjustSNR( fs, signal1, sig1OnOffs, signal2, snrdB )
            %adjustSNR   Adjust SNR between two signals. Only parts of the
            %signal that actually exhibit energy are factored into the SNR
            %computation.
            %   This function is based on adjustSNR by Tobias May.

            signal1(:,1) = signal1(:,1) - mean( signal1(:,1) );
            if size( signal1, 2 ) == 1
                signal1(:,2) = signal1(:,1);
            else
                signal1(:,2) = signal1(:,2) - mean( signal1(:,2) );
            end
            if isa( sig1OnOffs, 'char' ) && strcmpi( sig1OnOffs, 'energy' )
                s1actL = DataProcs.SceneEarSignalProc.detectActivity( fs, double(signal1(:,1)), 40, 50e-3, 50e-3, 10e-3 );
                s1actR = DataProcs.SceneEarSignalProc.detectActivity( fs, double(signal1(:,2)), 40, 50e-3, 50e-3, 10e-3 );
                signal1 = signal1(s1actL | s1actR,:);
            else
                sig1OnOffs(sig1OnOffs>length(signal1)) = length(signal1);
                signal1activePieces = arrayfun( ...
                    @(on, off)(signal1(ceil(on):floor(off),:)) , sig1OnOffs(:,1), sig1OnOffs(:,2), ...
                    'UniformOutput', false );
                signal1 = vertcat( signal1activePieces{:} );
            end
            signal2(:,1) = signal2(:,1) - mean( signal2(:,1) );
            s2actL = DataProcs.SceneEarSignalProc.detectActivity( fs, double(signal2(:,1)), 40, 50e-3, 50e-3, 10e-3 );
            if size( signal2, 2 ) > 1
                signal2(:,2) = signal2(:,2) - mean( signal2(:,2) );
                s2actR = DataProcs.SceneEarSignalProc.detectActivity( fs, double(signal2(:,2)), 40, 50e-3, 50e-3, 10e-3 );
            else
                s2actR = zeros( size( s2actL ) );
                signal2(:,2) = signal2(:,1);
            end
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
        
        function [energy, tFramesSec] = runningEnergy( fs, signal, blockSec, stepSec )
            blockSize = 2 * round(fs * blockSec / 2);
            stepSize  = round(fs * stepSec);
            frames = frameData(signal,blockSize,stepSize,'rectwin');
            energy = 10 * log10(squeeze(mean(power(frames,2),1) + eps));
            cp = 0.98; % cumulative probability for quantile computation
            energySorted = sort(energy');
            nEnergy = numel(energy);
            q = interp1q([0 (0.5:(nEnergy-0.5))./nEnergy 1]',...
                         energySorted([1 1:nEnergy nEnergy],:),cp);
            energy = energy - q;
            tFramesSec = (stepSize:stepSize:stepSize*numel(energy)).'/fs;
        end
        %% ----------------------------------------------------------------
        
        function vad = detectActivity( fs, signal, thresdB, hSec, blockSec, stepSec )
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
            
            % ************************  DETECT VOICE ACTIVITY  ***********************
            [energy, tFramesSec] = DataProcs.SceneEarSignalProc.runningEnergy( fs, signal, blockSec, stepSec );
            frameVAD = energy > -abs(thresdB) & energy > noiseFloor;
            % ***************************  HANGOVER SCHEME  **************************
            % Determine length of hangover scheme
            hangover = max(0,1+floor((hSec - blockSec)/stepSec));
            
            % Check if hangover scheme is active
            if hangover > 0
                % Initialize counter
                hangCtr = 0;
                
                % Loop over number of frames
                for ii = 1 : numel(energy)
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
            tSec = (1:length(signal)).'/fs;
            
            % Convert frame-based VAD decision to samples
            if numel( tFramesSec == 1 )
                tFramesSec(2,1) = tFramesSec(1,1)*2;
                frameVAD(2) = frameVAD(1);
            end
            vad = interp1(tFramesSec,double(frameVAD),tSec,'nearest','extrap');
            
            % Return logical VAD decision
            vad = logical(vad).';
        end
    end
    
end
