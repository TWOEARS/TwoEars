classdef IdentityHypothesis < Hypothesis
    
    properties (SetAccess = private)
        label;
        p;                      % probability
        d;                      % decision
        loc;                    % location (head-relative azimuth)
        concernsBlocksize_s;
    end
    
    methods
        function obj = IdentityHypothesis( label, p, d, blocksize_s, loc )
            if nargin < 5
                loc = [];
            end
            obj = obj@Hypothesis();
            obj.label = label;
            obj.p = p;
            obj.d = d;
            obj.loc = loc;
            obj.concernsBlocksize_s = blocksize_s;
        end
        
        function idText = getIdentityText( obj )
            idText = obj.label;
        end
    end
    
end
