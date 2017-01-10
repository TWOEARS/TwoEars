classdef vMFModel < Models.DataScalingModel
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?ModelTrainers.vMFTrainer, ?ModelTrainers.GMMmodelSelectTrainer})
        model;
%         coefsRelStd;
%         lambdasSortedByPerf;
%         nCoefs;
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function [y,score] = applyModelToScaledData( obj, x )
            idFeature = obj.model{3};
            % use apparoch 1 if thraining is done with approach 1
            xTest = x(:,idFeature);
            % use approach 2 if trianing is done with approach 2
%              [~,reconst] = pcares(x,idFeature);
%               xTest= reconst(:,1:idFeature);
            % do prediction
            [y, score] = obj.vMFPredict((normvec(xTest'))' );
       end
        %% -----------------------------------------------------------------

        function [pred, score] = vMFPredict( obj, x )
            % x: matrix of data points
            % y: vector of true labels of x
            %
            % pred: predicted labels (+1, -1)
            % val: Balanced accuracy
            % llh: log-likelihoods of model1 and model0
            % score: probability of existence of the event (between 0 and 1)
            
            xc = x';
            [llh1,~] = likelihoodVMF(xc,obj.model{1});
            [llh0,~] = likelihoodVMF(xc,obj.model{2});
            pred = repmat(-1,size(llh1,1),1);
            pred(llh1'>llh0')=1;
            score = llh1./(llh1+llh0);
        end
        %% -----------------------------------------------------------------
        
    end
    
end

