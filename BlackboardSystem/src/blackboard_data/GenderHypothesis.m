classdef GenderHypothesis < Hypothesis
    
    properties (SetAccess = private)
        predictedGender
        predictionProbabilities
    end
    
    methods
        function obj = GenderHypothesis( predictedClassLabel, ...
                predictionProbabilities )
            
            % Add parameters to object properties.
            if predictedClassLabel == 0
                obj.predictedGender = 'male';
            elseif predictedClassLabel == 1
                obj.predictedGender = 'female';
            else
                error('Invalid label.');
            end
            
            obj.predictionProbabilities = predictionProbabilities;
        end
    end
end
