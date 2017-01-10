classdef HPSmodel < Models.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = ?ModelTrainers.HpsTrainer)
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

