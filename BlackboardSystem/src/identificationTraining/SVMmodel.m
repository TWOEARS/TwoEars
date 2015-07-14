classdef SVMmodel < DataScalingModel
    
    %% --------------------------------------------------------------------
    properties (SetAccess = ?SVMtrainer)
        useProbModel;
        model;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = SVMmodel()
        end
        %% -----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function [y,score] = applyModelToScaledData( obj, x )
            yDummy = zeros( size( x, 1 ), 1 );
            [y, ~, score] = libsvmpredict( yDummy, x, obj.model, ...
                                           sprintf( '-q -b %d', obj.useProbModel ) );
            score = score(1);
        end
        %% -----------------------------------------------------------------

    end
    
end

