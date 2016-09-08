classdef DnnLocationKS < AuditoryFrontEndDepKS
    % DnnLocationKS calculates posterior probabilities for each azimuth angle and
    % generates SourcesAzimuthsDistributionHypothesis when provided with spatial
    % observation

    % TODO: make this KS work with synthesized sound sources, see qoe_localisation folder
    % in TWOEARS/examples repo
    
    properties (SetAccess = private)
        angles;                     % All azimuth angles to be considered
        DNNs;                       % Learned deep neural networks
        normFactors;                % Feature normalisation factors
        nChannels;                  % Number of frequency channels
        dataPath = fullfile('learned_models', 'DnnLocationKS');
        blockSize                   % The size of one data block that
                                    % should be processed by this KS in
                                    % [s].
        energyThreshold = 2E-3;     % ratemap energy threshold (cuberoot 
                                    % compression) for detecting active 
                                    % frames
        freqRange;                  % Frequency range to be considered
        channels = [];              % Frequency channels to be used
    end

    methods
        function obj = DnnLocationKS(preset, highFreq, lowFreq, azRes)
            if nargin < 1
                % Default preset is 'MCT-DIFFUSE'. For localisation in the
                % front hemifield only, use 'MCT-DIFFUSE-FRONT'
                preset = 'MCT-DIFFUSE';
            end
            defaultFreqRange = [80 8000];
            freqRange = defaultFreqRange;
            % Frequency range to be considered
            if exist('highFreq', 'var')   
                freqRange(2) = highFreq;
            end
            if exist('lowFreq', 'var')
                freqRange(1) = lowFreq;
            end
            if nargin < 4
                % Default azimuth resolution is 5 deg.
                azRes = 5;
            end
            nChannels = 32;
            param = genParStruct(...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', defaultFreqRange(1), ...
                'fb_highFreqHz', defaultFreqRange(2), ...
                'fb_nChannels', nChannels, ...
                'ihc_method', 'halfwave', ...
                'ild_wSizeSec', 20E-3, ...
                'ild_hSizeSec', 10E-3, ...
                'rm_wSizeSec', 20E-3, ...
                'rm_hSizeSec', 10E-3, ...
                'rm_scaling', 'power', ...
                'rm_decaySec', 8E-3, ...
                'cc_wSizeSec', 20E-3, ...
                'cc_hSizeSec', 10E-3, ...
                'cc_wname', 'hann');
            requests{1}.name = 'crosscorrelation';
            requests{1}.params = param;
            requests{2}.name = 'ild';
            requests{2}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.blockSize = 0.5;
            obj.invocationMaxFrequency_Hz = 10;
            obj.nChannels = nChannels;
            obj.freqRange = freqRange;
            
            % Load localiastion DNNs
            obj.DNNs = cell(nChannels, 1);
            obj.normFactors = cell(nChannels, 1);

            nHiddenLayers = 2;
            for c = 1:nChannels
                strModels = sprintf( ...
                    '%s/LearnedDNNs_%s_ild-cc_%ddeg_%dchannels/DNN_%s_%ddeg_%dchannels_channel%d_%dlayers.mat', ...
                    obj.dataPath, preset, azRes, nChannels, preset, azRes, nChannels, c, nHiddenLayers);
                % Load localisation module
                load(xml.dbGetFile(strModels));
                obj.DNNs{c} = C.NNs;
                obj.normFactors{c} = C.normFactors;
            end
            obj.angles = C.azimuths;
        end


        function [bExecute, bWait] = canExecute(obj)
            %afeData = obj.getAFEdata();
            %timeSObj = afeData(3);
            %bExecute = hasSignalEnergy(timeSObj, obj.blockSize, obj.timeSinceTrigger);
            
            % Execute KS if a sufficient amount of data for one block has
            % been gathered
            bExecute = obj.hasEnoughNewSignal( obj.blockSize );
            bWait = false;
        end

        function execute(obj)
            cc = obj.getNextSignalBlock( 1, obj.blockSize, obj.blockSize, false );
            nlags = size(cc,3);
            if nlags > 37 % 37 lags when sampled at 16kHz
                error('DnnLocationKS: requires sampling rate to be 16kHz (set in AuditoryFrontEndKS)');
            end
            idx = ceil(nlags/2);
            mlag = 16; % only use -1 ms to 1 ms
            cc = cc(:,:,idx-mlag:idx+mlag);
            ild = obj.getNextSignalBlock( 2, obj.blockSize, obj.blockSize, false );

            % Only consider those channels within obj.freqRange
            if isempty(obj.channels)
                afe = obj.getAFEdata;
                obj.channels = find(afe(1).cfHz >= obj.freqRange(1) & afe(1).cfHz <= obj.freqRange(2));
            end
            
            % Compute posterior distributions for each frequency channel and time frame
            [nFrames] = size(ild,1);
            nAzimuths = numel(obj.angles);
            numChans = length(obj.channels);
            post = zeros(nFrames, nAzimuths, numChans);
            yy = zeros(nFrames, nAzimuths);
            for n = 1:numChans
                ch = obj.channels(n);
                testFeatures = [ild(:,ch) squeeze(cc(:,ch,:))];

                % Normalise features
                testFeatures = testFeatures - ...
                    repmat(obj.normFactors{ch}(1,:),[size(testFeatures,1) 1]);
                testFeatures = testFeatures ./ ...
                    sqrt(repmat(obj.normFactors{ch}(2,:),[size(testFeatures,1) 1]));

                obj.DNNs{ch}.testing = 1;
                obj.DNNs{ch} = nnff(obj.DNNs{ch}, testFeatures, yy);
                post(:,:,n) = obj.DNNs{ch}.a{end} + eps;
                obj.DNNs{ch}.testing = 0;
            end

            % Average posterior distributions over frequency
            prob_AF = exp(squeeze(nanSum(log(post),3)));


            % Normalise each frame such that probabilities sum up to one
            prob_AFN = prob_AF ./ repmat(sum(prob_AF,2),[1 nAzimuths]);

            % Average posterior distributions over time
            prob_AFN_F = nanMean(prob_AFN, 1);

            % Create a new location hypothesis
            currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;
            aziHyp = SourcesAzimuthsDistributionHypothesis( ...
                currentHeadOrientation, obj.angles, prob_AFN_F);
            obj.blackboard.addData( ...
                'sourcesAzimuthsDistributionHypotheses', aziHyp, false, obj.trigger.tmIdx);
            notify(obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ));
        end

    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
