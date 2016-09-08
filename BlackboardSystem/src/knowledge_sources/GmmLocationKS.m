classdef GmmLocationKS < AuditoryFrontEndDepKS
    % DnnLocationKS calculates posterior probabilities for each azimuth angle and
    % generates SourcesAzimuthsDistributionHypothesis when provided with spatial
    % observation

    properties (SetAccess = private)
        angles;                     % All azimuth angles to be considered
        GMMs;                       % Learned localiation GMMs
        normFactors;                % Feature normalisation factors
        nChannels;                  % Number of frequency channels
        dataPath = fullfile('learned_models', 'GmmLocationKS');
        blockSize                   % The size of one data block that
                                    % should be processed by this KS in
                                    % [s].
        energyThreshold = 2E-3;     % ratemap energy threshold (cuberoot 
                                    % compression) for detecting active 
                                    % frames
    end

    methods
        function obj = GmmLocationKS(preset, nChannels, azRes)
            if nargin < 1
                % Default preset is 'MCT-DIFFUSE'. For localisation in the
                % front hemifield only, use 'MCT-DIFFUSE-FRONT'
                preset = 'MCT-DIFFUSE';
            end
            if nargin < 2
                % Default number of frequency channels is 32 for GMM
                % localition KS
                nChannels = 32;
            end
            if nargin < 3
                % Default azimuth resolution is 5 deg.
                azRes = 5;
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
            requests{1}.name = 'itd';
            requests{1}.params = param;
            requests{2}.name = 'ild';
            requests{2}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.blockSize = 0.5;
            obj.invocationMaxFrequency_Hz = 10;

            % Localisation model params
            obj.nChannels = nChannels;
            nMix = 16;
            strModels = fullfile(obj.dataPath, sprintf('GMM_%s_itd-ild_%ddeg_%dchannels_%dmix_Norm.mat', preset, azRes, nChannels, nMix));
            
            % Load localisation models
            load(xml.dbGetFile(strModels));
            obj.GMMs = C.gmmFinal;
            obj.normFactors = C.featNorm;
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
            itd = obj.getNextSignalBlock( 1, obj.blockSize, obj.blockSize, false );
            ild = obj.getNextSignalBlock( 2, obj.blockSize, obj.blockSize, false );

            % Compute posterior distributions for each frequency channel and time frame
            nFrames = size(ild,1);
            nAzimuths = numel(obj.angles);
            post = zeros(nFrames, nAzimuths, obj.nChannels);
            for c = 1:obj.nChannels
                testFeatures = [itd(:,c) ild(:,c)];

                % Normalise features
                testFeatures = testFeatures - ...
                    repmat(obj.normFactors{c}(1,:),[size(testFeatures,1) 1]);
                testFeatures = testFeatures ./ ...
                    sqrt(repmat(obj.normFactors{c}(2,:),[size(testFeatures,1) 1]));

                prob = zeros(nFrames, nAzimuths);
                for jj = 1 : nAzimuths
                    % Conventional recognition using the complete feature space
                    prob(:,jj) = gmmprob(obj.GMMs{c}(jj),testFeatures);
                end
                post(:,:,c) = prob + eps;
                
                % Normalize across all azimuth directions
                post(:,:,c) = post(:,:,c) ./ repmat(sum(post(:,:,c),2),[1 size(post(:,:,c),2) 1]);
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
