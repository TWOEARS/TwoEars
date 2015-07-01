classdef IdDecisionKS < AbstractKS

    properties (SetAccess = private)
        minSources = 0;
        maxSources = 1;
    end

    methods
        function obj = IdDecisionKS(minSources, maxSources)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            obj.minSources = minSources;
            obj.maxSources = maxSources;
        end

        function delete(obj)
        end

        function [b, wait] = canExecute(obj)
            b = true;
            wait = false;
        end

        function execute(obj)
            idHyps = obj.blackboard.getData( ...
                'identityHypotheses', obj.trigger.tmIdx).data;
            [~,idx] = max([idHyps.p]);
            maxProbHyp = idHyps(idx);

            if maxProbHyp.p > 0.5
                if obj.blackboard.verbosity > 0
                    fprintf('Identity Decision: %s with %i%% probability.\n', ...
                        maxProbHyp.label, int16(maxProbHyp.p*100));
                end
                obj.blackboard.addData('identityDecision', ...
                    maxProbHyp, false, obj.trigger.tmIdx);
                notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
            end
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
