classdef MFAModel < Models.DataScalingModel
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?ModelTrainers.MFATrainer, ?ModelTrainers.BGMMmodelSelectTrainer})
        model;
%         coefsRelStd;
%         lambdasSortedByPerf;
%         nCoefs;
    end
    
    %% --------------------------------------------------------------------

    methods (Access = protected)
        
        function [y,score] = applyModelToScaledData( obj, x )
            model1 = obj.model{1};
            model0 = obj.model{2};
            [y, score] = mfaPredict(x, model1, model0 );
           
       end
        %% -----------------------------------------------------------------

    end
    
end

