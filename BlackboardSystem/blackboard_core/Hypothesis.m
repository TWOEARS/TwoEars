% A class representing a hypothesis on the blackboard
% All hypotheses have a score (but this is not used in the current demo)

classdef Hypothesis < handle
    
    properties (SetAccess = private)
        score = 0;
    end
    
    methods
        function setScore(obj,score)
            obj.score = score;
        end
    end
    
end
