classdef ConfusionKS < AbstractKS
    % ConfusionKS examines location hypotheses and decides whether
    % there is a front-back confusion. In the case of a confusion, a head
    % rotation will be triggered.

    properties (SetAccess = private)
        postThreshold = 0.1;       % Posterior probability threshold for a valid
                                   % LocationHypothesis
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
            bExecute = ~(obj.blackboard.getData('locationHypotheses', ...
                obj.trigger.tmIdx).data.seenByConfusionKS);
            bWait = false;
        end

        function execute(obj)
            locHyp = obj.blackboard.getData( ...
                'locationHypotheses', obj.trigger.tmIdx).data;
            % Generates location hypotheses if posterior > threshold
            locIdx = locHyp.posteriors > obj.postThreshold;
            numLoc = sum(locIdx);
            if numLoc > 1 && obj.bSolveConfusion
                % Assume there is a confusion when there are more than 1
                % valid location
                % cf = ConfusionHypothesis(locHyp.blockNo, locHyp.headOrientation, ...
                %         locHyp.locations(locIdx), locHyp.posteriors(locIdx));
                obj.blackboard.addData('confusionHypotheses', ...
                    locHyp, false, obj.trigger.tmIdx);
                notify(obj, 'ConfusedLocations', BlackboardEventData(obj.trigger.tmIdx));
            elseif numLoc > 0
                % Assuming no confusion by using the index with the highest probability
                [~,locIdx] = max(locHyp.posteriors);
                % No confusion, generate Perceived Location
                ploc = PerceivedLocation(locHyp.headOrientation, ...
                    locHyp.locations(locIdx), locHyp.posteriors(locIdx));
                obj.blackboard.addData('perceivedLocations', ploc, false, ...
                    obj.trigger.tmIdx);
                notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
            end
            locHyp.setSeenByConfusionKS;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
