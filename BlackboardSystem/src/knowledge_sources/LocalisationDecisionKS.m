classdef LocalisationDecisionKS < AbstractKS
    % LocalisationDecisionKS examines azimuth hypotheses and decides a
    % source location. In the case of a confusion, a head rotation can be 
    % triggered.

    properties (SetAccess = private)
        postThreshold = 0.1;      % Distribution probability threshold for a valid
                                   % SourcesAzimuthsDistributionHypothesis
        leakItFactor = 0.5;       % Importance of presence [0,1]
        bSolveConfusion = false;    % Invoke ConfusionSolvingKS
        prevTimeIdx = 0;
    end
    
    events
      RotateHead          % Trigger HeadRotationKS
      TopdownSegment      % Indicate topdown models are used, trigger SegmentIdentityKS
    end
    
    methods
        function obj = LocalisationDecisionKS(bSolveConfusion, leakItFactor)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            if nargin > 0
                obj.bSolveConfusion = bSolveConfusion;
            end
            if nargin > 1
                obj.leakItFactor = leakItFactor;
            end
        end

        function setPostThreshold(obj, t)
            obj.postThreshold = t;
        end

        function [bExecute, bWait] = canExecute(obj)
            bExecute = false;
            bWait = false;
            
            aziHyp = obj.blackboard.getData('sourcesAzimuthsDistributionHypotheses', obj.trigger.tmIdx).data;
            if aziHyp.seenByLocalisationDecisionKS
                return;
            end
            
            bExecute = true;
        end

        function execute(obj)
            
            % Get the new azimuth hypothesis
            aziHyp = obj.blackboard.getData( ...
                'sourcesAzimuthsDistributionHypotheses', obj.trigger.tmIdx).data;
            
            % If the first block, make a decision based only on the current block
            if obj.prevTimeIdx == 0
                
                post = aziHyp.sourcesDistribution;
                
            elseif obj.prevTimeIdx < obj.trigger.tmIdx
                
                % New SourcesAzimuthsDistributionHypothesis has arrived,
                % integrate with previous Location Hypothesis
                prevHyp = obj.blackboard.getData( ...
                    'locationHypothesis', obj.prevTimeIdx).data;
                headRotation = wrapTo180(aziHyp.headOrientation-prevHyp.headOrientation);
                prevPost = prevHyp.sourcesDistribution;
                currPost = aziHyp.sourcesDistribution;
                if sum(currPost > obj.postThreshold) > 0
                    if headRotation ~= 0
                        % Only if the new location hypothesis contains strong
                        % directional sources, do the removal
                        [prevPost,currPost] = removeFrontBackConfusion(...
                            prevHyp.azimuths, prevPost, ...
                            currPost, headRotation);
                        % Changed int16 to round here, which seems to cause problem
                        % with circshift in the next line
                        idxDelta = round(headRotation / ...
                            (aziHyp.azimuths(1) - aziHyp.azimuths(2)));
                        prevPost = circshift(prevPost, idxDelta);
                    end
                else
                    if headRotation ~= 0
                        % If a head rotation is done, needs to circshift
                        % previous information
                        idxDelta = round(headRotation / ...
                            (aziHyp.azimuths(1) - aziHyp.azimuths(2)));
                        prevPost = circshift(prevPost, idxDelta);
                    end
                end
                    
                % Take the average of the sources distribution before head
                % rotation and predictd distribution after head rotation
                post = obj.leakItFactor .* currPost + (1-obj.leakItFactor) .* prevPost;
                post = post ./ sum(post);
            end
            
            % Add Location Hypothesis to Blackboard
            ploc = LocationHypothesis(aziHyp.headOrientation, ...
                    aziHyp.azimuths, post);
            obj.blackboard.addData('locationHypothesis', ploc, false, ...
                obj.trigger.tmIdx);
            obj.prevTimeIdx = obj.trigger.tmIdx;
            aziHyp.seenByLocalisationDecisionKS;
            

            % Add segmentation hypothesis to the blackboard for
            % SegmentIdentityKS
            segHyp = obj.blackboard.getData( ...
                'sourceSegregationHypothesis', obj.trigger.tmIdx);
            
            if isempty(segHyp)
                notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
            else
                % Indicate to use top-down segregation masks directly
                %
                % SourceSegregationHypothesis uses masks of [nChannels x nFrames]
                % SegmentationHypothesis uses masks of [nFrames x nChannels]
                segHyp = SegmentationHypothesis(segHyp.data.source, ...
                    'SoundSource', segHyp.data.mask', segHyp.data.cfHz, segHyp.data.hopSize, ploc.relativeAzimuth);
                obj.blackboard.addData('segmentationHypotheses', ...
                    segHyp, false, obj.trigger.tmIdx);
                notify(obj, 'TopdownSegment', BlackboardEventData(obj.trigger.tmIdx));
            end
            
            % Request head rotation to solve front-back confusion
            bRotateHead = false;
            if obj.bSolveConfusion
                % Generates location hypotheses if posterior distribution > threshold
                % Assume a confusion when more than 1 valid location
                if sum(ploc.sourcesDistribution > obj.postThreshold) > 1 ...
                        || (ploc.relativeAzimuth > 150 && ploc.relativeAzimuth < 210)
                    bRotateHead = true;
                end
            end
            if bRotateHead
                notify(obj, 'RotateHead', BlackboardEventData(obj.trigger.tmIdx));
            end
            
        end
        
        function setSolveConfusion(obj, bSolveConfusion)
            obj.bSolveConfusion = bSolveConfusion;
        end
        
        % Visualisation
        function visualise(obj)
            if ~isempty(obj.blackboardSystem.locVis)
                ploc = obj.blackboard.getData( ...
                'locationHypothesis', obj.trigger.tmIdx).data;
                obj.blackboardSystem.locVis.setPosteriors(...
                    ploc.azimuths+ploc.headOrientation, ploc.sourcesDistribution);
            end
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
