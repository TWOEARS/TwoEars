classdef MbfModel < Models.DataScalingModel
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?ModelTrainers.MBFTrainer, ?ModelTrainers.MBFmodelSelectTrainer})
        model;
        nComp;
        thr;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = MbfModel()
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
            xTest = (normvec(x'))';
%             xTest = x;
%             xTest = (preprocess(x'))';
%             xTest = (normvec(xTest'))';
            [y, score] = MbfPredict(xTest, model1, model0 );
           
       end
        %% -----------------------------------------------------------------

    end
    
end

