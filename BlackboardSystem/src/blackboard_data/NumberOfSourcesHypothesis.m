classdef NumberOfSourcesHypothesis < Hypothesis
    
    properties (SetAccess = private)
        label;
        p;                      % probability
        n;                      % number of sources
        concernsBlocksize_s;
    end
    
    methods
        function obj = NumberOfSourcesHypothesis( label, p, n, blocksize_s )
            obj = obj@Hypothesis();
            obj.label = label;
            obj.p = p;
            obj.n = n;
            obj.concernsBlocksize_s = blocksize_s;
        end
    end
    
end
