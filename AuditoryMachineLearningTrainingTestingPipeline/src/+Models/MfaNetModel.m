classdef MfaNetModel < Models.DataScalingModel
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?ModelTrainers.MfaNetTrainer, ?ModelTrainers.MFAmodelSelectTrainer})
        model;
        nComp;
        thr;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = MfaNetModel()
            obj.nComp = [1 2 3];
        end
%         %% -----------------------------------------------------------------
% 
        function setnComp( obj, newnComp )
            obj.nComp = newnComp;
        end
        %% -----------------------------------------------------------------

    end
    
    methods (Access = protected)
        
        function [y,score] = applyModelToScaledData( obj, x )
          
                
            model1 = obj.model{1};
            model0 = obj.model{2};
            [y, score] = mfaPredict(x, model1, model0 );
           
       end
        %% -----------------------------------------------------------------

    end
    
end

