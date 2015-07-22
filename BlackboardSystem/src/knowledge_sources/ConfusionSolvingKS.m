classdef ConfusionSolvingKS < AbstractKS
    % ConfusionSolvingKS solves a confusion given new features.

    properties (SetAccess = private)
        postThreshold = 0.1;   % Posterior probability threshold for a valid
                               % LocationHypothesis
    end

    methods
        function obj = ConfusionSolvingKS()
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
        end

        function [bExecute, bWait] = canExecute(obj)
            bExecute = false;
            bWait = false;
            % Fire only if there is an unseen confusion
            confHyp = obj.blackboard.getData('confusionHypotheses', ...
                obj.trigger.tmIdx).data;
            if confHyp.seenByConfusionSolvingKS, return; end;
            confHeadOrient = confHyp.headOrientation;
            currentHeadOrientation = obj.blackboard.getLastData('headOrientation');
            % If no new LocationHypothesis has arrived, do nothing
            lastLocHyp = obj.blackboard.getLastData('locationHypotheses');
            if lastLocHyp.sndTmIdx == obj.trigger.tmIdx
                bWait = true;
                return;
            end;
            % If head has not been turned but there's already a new loc
            % hypothesis, don't wait again
            if confHeadOrient == currentHeadOrientation.data, return; end;
            bExecute = true;
        end

        function execute(obj)
            confHyp = obj.blackboard.getData('confusionHypotheses', ...
                obj.trigger.tmIdx).data;
            currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;
            headRotation = currentHeadOrientation - confHyp.headOrientation;
            newLocHyp = obj.blackboard.getLastData('locationHypotheses').data;
            % Changed int16 to round here, which seems to cause problem
            % with circshift in the next line
            idxDelta = round(headRotation / ...
                (newLocHyp.locations(2) - newLocHyp.locations(1)));
            predictedPosteriors = circshift(newLocHyp.posteriors,[0 idxDelta]);
            % Take the average of the posterior distribution before head
            % rotation and predictd distribution from after head rotation
            post = (confHyp.posteriors + predictedPosteriors) / 2;
            post = post ./ sum(post);
%            hold off;
%            plot(obj.confusionHypothesis.locations, ...
%               obj.confusionHypothesis.posteriors, 'o--');
%            hold on;
%            plot(obj.confusionHypothesis.locations, predictedPosteriors, 'go--');
%            plot(obj.confusionHypothesis.locations, post, 'ro--');
%            legend('Dist before rotation', 'Dist after rotation', 'Average dist');
            [m,idx] = max(post);
            if m > obj.postThreshold;
                % Generate Perceived Location
                ploc = PerceivedLocation(...
                    confHyp.headOrientation, ...
                    confHyp.locations(idx), m);
                obj.blackboard.addData('perceivedLocations', ploc, false, ...
                    obj.trigger.tmIdx);
                notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
            end
            confHyp.setSeenByConfusionSolvingKS;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
