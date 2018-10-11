classdef EmergencyDetectionKS < AbstractKS
    % EmergencyDetectionKS Checks for an emergency situation by evaluating
    %   the output of source identification.

    properties (SetAccess = private)
        accumulatedIdProbs = zeros(3, 1);
        smoothingFactor
        forgettingFactor = 0.9;
        emergencyThreshold
        emergencyProbability = 0;
        isEmergencyDetected = false;
    end
    
    methods
        function obj = EmergencyDetectionKS(varargin)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            
            defaultSmoothingFactor = 0.25;
            defaultEmergencyThreshold = 0.5;
            
            p = inputParser();
            p.addOptional('SmoothingFactor', defaultSmoothingFactor, ...
                @(x) validateattributes(x, {'numeric'}, {'scalar', ...
                'real', '>=', 0, '<=', 1}));
            p.addOptional('EmergencyThreshold', ...
                defaultEmergencyThreshold, @(x) validateattributes(x, ...
                {'numeric'}, {'scalar', 'real', '>', 0, '<', 1}));
            p.parse(varargin{:});
            
            obj.smoothingFactor = p.Results.SmoothingFactor;
            obj.emergencyThreshold = p.Results.EmergencyThreshold;            
        end

        function setEmergencyThreshold(obj, emergencyThreshold)
            obj.emergencyThreshold = emergencyThreshold;
        end
        
        function setSmoothingFactor(obj, smoothingFactor)
            obj.smoothingFactor = smoothingFactor;
        end

        function [bExecute, bWait] = canExecute(obj)
            sndTimeIdx = sort(cell2mat(keys(obj.blackboard.data)));
            bExecute = isfield(obj.blackboard.data(sndTimeIdx(end)), ...
                'singleBlockObjectHypotheses');
            bWait = false;
        end

        function execute(obj)
            singleBlockObjHyp = obj.blackboard.getData( ...
                'singleBlockObjectHypotheses', obj.trigger.tmIdx).data;
            
            numHyps = length(singleBlockObjHyp);

            for idx = 1 : numHyps
                % Get class label and detection probability.
                hypLabel = singleBlockObjHyp(idx).label;
                detProb = singleBlockObjHyp(idx).p;
                
                if detProb >= 0.5                    
                    switch hypLabel
                        case 'fire'
                            obj.accumulatedIdProbs(1) = ...
                                obj.smoothingFactor * obj.accumulatedIdProbs(1) + ...
                                (1 - obj.smoothingFactor) * singleBlockObjHyp(idx).p;
                        case 'alarm'
                            obj.accumulatedIdProbs(2) = ...
                                obj.smoothingFactor * obj.accumulatedIdProbs(2) + ...
                                (1 - obj.smoothingFactor) * singleBlockObjHyp(idx).p;
                        case 'femaleScreammaleScream'
                            obj.accumulatedIdProbs(3) = ...
                                obj.smoothingFactor * obj.accumulatedIdProbs(3) + ...
                                (1 - obj.smoothingFactor) * singleBlockObjHyp(idx).p;
                    end
                end
            end
            
            obj.accumulatedIdProbs(1) = ...
                obj.forgettingFactor * obj.accumulatedIdProbs(1);
            obj.accumulatedIdProbs(2) = ...
                obj.forgettingFactor * obj.accumulatedIdProbs(2);
            obj.accumulatedIdProbs(3) = ...
                obj.forgettingFactor * obj.accumulatedIdProbs(3);

            obj.emergencyProbability = ( ...
                obj.accumulatedIdProbs(1) + ...
                5 * obj.accumulatedIdProbs(2) + ...
                4 * obj.accumulatedIdProbs(3)) / 10;
            
            if obj.emergencyProbability >= obj.emergencyThreshold
                obj.isEmergencyDetected = true;
            end
        end
        
        function visualise(obj)
            if ~isempty(obj.blackboardSystem.emDetVis)
                obj.blackboardSystem.emDetVis.draw( ...
                    obj.emergencyProbability, obj.isEmergencyDetected );
            end
        end
    end
end
