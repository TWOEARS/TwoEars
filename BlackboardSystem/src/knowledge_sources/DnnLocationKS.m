classdef DnnLocationKS < AuditoryFrontEndDepKS
    % DnnLocationKS calculates posterior probabilities for each azimuth angle and
    % generates SourcesAzimuthsDistributionHypothesis when provided with spatial
    % observation

    properties (SetAccess = private)
        angles;                     % All azimuth angles to be considered
        DNNs;                       % Learned deep neural networks
        normFactors;                % Feature normalisation factors
        nChannels;                  % Number of frequency channels
        dataPath = fullfile('learned_models', 'DnnLocationKS');
        blockSize                   % The size of one data block that
                                    % should be processed by this KS in
                                    % [s].
    end

    methods
        function obj = DnnLocationKS(nChannels)
            if nargin < 1
                % Default number of frequency channels is 16 for DNN
                % localition KS
                nChannels = 16;
            end
            param = genParStruct(...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 8000, ...
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
            requests{3}.name = 'time';
            requests{3}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.blockSize = 0.5;

            % Load localiastion DNNs
            obj.nChannels = nChannels;
            obj.DNNs = cell(nChannels, 1);
            obj.normFactors = cell(nChannels, 1);

            preset = 'MCT_DIFFUSE';
            nHiddenLayers = 4;
            nHiddenNodes = 128;
            for c = 1:nChannels
                strModels = sprintf( ...
                    '%s/%dchannels/DNN_%s_channel%d_%dlayers_%dnodes.mat', ...
                    obj.dataPath, nChannels, preset, c, nHiddenLayers, nHiddenNodes);
                % Load localisation module
                load(xml.dbGetFile(strModels));
                obj.DNNs{c} = C.NNs;
                obj.normFactors{c} = C.normFactors;
            end
            obj.angles = C.azimuths;
        end


        function [bExecute, bWait] = canExecute(obj)
            afeData = obj.getAFEdata();
            timeSObj = afeData(3);
            bExecute = hasSignalEnergy(timeSObj, obj.blockSize, obj.timeSinceTrigger);
            bWait = false;
        end

        function execute(obj)
            afeData = obj.getAFEdata();
            ccSObj = afeData(1);
            cc = ccSObj.getSignalBlock(obj.blockSize, obj.timeSinceTrigger);
            ildSObj = afeData(2);
            ild = ildSObj.getSignalBlock(obj.blockSize, obj.timeSinceTrigger);

            % Compute posterior distributions for each frequency channel and time frame
            nFrames = size(ild,1);
            nAzimuths = numel(obj.angles);
            post = zeros(nFrames, nAzimuths, obj.nChannels);
            yy = zeros(nFrames, nAzimuths);
            for c = 1:obj.nChannels
                testFeatures = [squeeze(cc(:,c,:)) ild(:,c)];

                % Normalise features
                testFeatures = testFeatures - ...
                    repmat(obj.normFactors{c}(1,:),[size(testFeatures,1) 1]);
                testFeatures = testFeatures ./ ...
                    sqrt(repmat(obj.normFactors{c}(2,:),[size(testFeatures,1) 1]));

                obj.DNNs{c}.testing = 1;
                obj.DNNs{c} = nnff(obj.DNNs{c}, testFeatures, yy);
                p = obj.DNNs{c}.a{end};
                post(:,:,c) = p + eps;
                obj.DNNs{c}.testing = 0;
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
