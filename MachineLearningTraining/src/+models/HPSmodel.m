classdef HPSmodel < models.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = ?modelTrainers.HpsTrainer)
        hpsSet;
        model;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = HPSmodel()
        end
        %% -----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function [y,score] = applyModelMasked( obj, x )
            [y,score] = obj.model.applyModelMasked( x );
        end
        %% -----------------------------------------------------------------

    end
    
end

