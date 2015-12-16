classdef ConfusionKS < AbstractKS
    % ConfusionKS examines azimuth hypotheses and decides whether
    % there is a front-back confusion. In the case of a confusion, a head
    % rotation will be triggered.

    properties (SetAccess = private)
        postThreshold = 0.1;       % Distribution probability threshold for a valid
                                   % SourcesAzimuthsDistributionHypothesis
        bSolveConfusion = true;    % Invoke ConfusionSolvingKS
    end

    events
        ConfusedLocations
    end

    methods
        function obj = ConfusionKS(bSolveConfusion)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            if nargin > 0
                obj.bSolveConfusion = bSolveConfusion;
            end
        end

        function setPostThreshold(obj, t)
            obj.postThreshold = t;
        end

        function [bExecute, bWait] = canExecute(obj)
            bExecute = ~(obj.blackboard.getData( ...
                'sourcesAzimuthsDistributionHypotheses', ...
                obj.trigger.tmIdx).data.seenByConfusionKS);
            bWait = false;
        end

        function execute(obj)
            aziHyp = obj.blackboard.getData( ...
                'sourcesAzimuthsDistributionHypotheses', obj.trigger.tmIdx).data;
            % Generates location hypotheses if posterior distribution > threshold
            locIdx = aziHyp.sourcesDistribution > obj.postThreshold;
            numLoc = sum(locIdx);
            if numLoc > 1 && obj.bSolveConfusion
                % Assume there is a confusion when there are more than 1
                % valid location
                % cf = ConfusionHypothesis(aziHyp.blockNo, aziHyp.headOrientation, ...
                %         aziHyp.azimuths(locIdx), aziHyp.sourcesDistribution(locIdx));
                obj.blackboard.addData('confusionHypotheses', ...
                    aziHyp, false, obj.trigger.tmIdx);
                notify(obj, 'ConfusedLocations', BlackboardEventData(obj.trigger.tmIdx));
            elseif numLoc > 0
                % Assuming no confusion by using the index with the highest probability
                [~,locIdx] = max(aziHyp.sourcesDistribution);
                % No confusion, generate Perceived Azimuth
                ploc = PerceivedAzimuth(aziHyp.headOrientation, ...
                    aziHyp.azimuths(locIdx), aziHyp.sourcesDistribution(locIdx));
                obj.blackboard.addData('perceivedAzimuths', ploc, false, ...
                    obj.trigger.tmIdx);
                notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
            end
            aziHyp.setSeenByConfusionKS;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
