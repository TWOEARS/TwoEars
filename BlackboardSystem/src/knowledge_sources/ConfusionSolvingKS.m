classdef ConfusionSolvingKS < AbstractKS
    % ConfusionSolvingKS solves a confusion given new features.

    properties (SetAccess = private)
        postThreshold = 0.1;   % Distribution probability threshold for a valid
                               % SourcesAzimuthsDistributionHypothesis
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
            % If no new SourcesAzimuthsDistributionHypothesis has arrived, do nothing
            lastAziHyp = ...
                obj.blackboard.getLastData('sourcesAzimuthsDistributionHypotheses');
            if lastAziHyp.sndTmIdx == obj.trigger.tmIdx
                bWait = true;
                return;
            end;
            % If head has not been turned but there's already a new azimuths
            % hypothesis, don't wait again
            if confHeadOrient == currentHeadOrientation.data, return; end;
            bExecute = true;
        end

        function execute(obj)
            confHyp = obj.blackboard.getData('confusionHypotheses', ...
                obj.trigger.tmIdx).data;
            currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;
            headRotation = currentHeadOrientation - confHyp.headOrientation;
            newAziHyp = ...
                obj.blackboard.getLastData('sourcesAzimuthsDistributionHypotheses').data;

            [post1, post2] = removeFrontBackConfusion(confHyp.azimuths, ...
                                                      confHyp.sourcesDistribution, ...
                                                      newAziHyp.sourcesDistribution, ...
                                                      headRotation);

            % Changed int16 to round here, which seems to cause problem
            % with circshift in the next line
            idxDelta = round(headRotation / ...
                (newAziHyp.azimuths(2) - newAziHyp.azimuths(1)));
            post2 = circshift(post2, idxDelta);
            % Take the average of the sources distribution before head
            % rotation and predictd distribution from after head rotation
            post = (post1 + post2);
            post = post ./ sum(post);
            %figure
            %hold off;
            %plot(confHyp.azimuths, confHyp.sourcesDistribution, 'o--');
            %hold on;
            %plot(confHyp.azimuths, predictedDistribution, 'go--');
            %plot(confHyp.azimuths, post, 'ro--');
            %legend('Dist before rotation', 'Dist after rotation', 'Average dist');
            [m,idx] = max(post);
            if m > obj.postThreshold;
                % Generate Perceived Azimuth
                ploc = PerceivedAzimuth(...
                    confHyp.headOrientation, ...
                    confHyp.azimuths(idx), m);
                obj.blackboard.addData('perceivedAzimuths', ploc, false, ...
                    obj.trigger.tmIdx);
                notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
            end
            confHyp.setSeenByConfusionSolvingKS;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
