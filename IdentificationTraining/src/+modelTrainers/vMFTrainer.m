classdef vMFTrainer < modelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (Access = protected)
        model;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = vMFTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @performanceMeasures.BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            pds{3} = struct( 'name', 'nComp', ...
                'default', [1 2 3], ...
                'valFun', @(x)(sum(x)>=0) );
            pds{4} = struct( 'name', 'thr', ...
                             'default', [0.5 0.6], ...
                             'valFun', @(x)(x<=1 && x >= 0) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y )
%             glmOpts.weights = obj.setDataWeights( y );
            if length( y ) > obj.parameters.maxDataSize
                x(obj.parameters.maxDataSize+1:end,:) = [];
                y(obj.parameters.maxDataSize+1:end) = [];
            end
            obj.model = models.vMFModel();
            xScaled = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
            gmmOpts.nComp = obj.parameters.nComp;
            gmmOpts.thr = obj.parameters.thr;
            %....... approach 1: explicit dimension reduction using PCA
            idFeature = modelTrainers.featureSelectionPCA2(xScaled,gmmOpts.thr);
            xTrain = xScaled(:,idFeature);
            %....... approach 2: uncorrelate feature variables using PCA 
%             dataDim = size(xScaled,2);
%             ndims = floor(gmmOpts.thr*dataDim);
%             [~,reconst] = pcares(xScaled,ndims);
%             xTrain = reconst(:,1:ndims);
%             idFeature = ndims;
            
            gmmOpts.initComps = gmmOpts.nComp;
            [obj.model.model{1}, obj.model.model{2}] = ...
                modelTrainers.vMFTrainer.trainVMF( y, (normvec(xTrain'))', gmmOpts );
            obj.model.model{3}=idFeature;
            verboseFprintf( obj, '\n' );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Static)
        
        function [model1, model0] = trainVMF( y, x, esetup )
            % y: labels of x
            % x: matrix of data points (+1 and -1!)
            % esetup: training parameters
            %
            % model: trained gmm
            % trVal: performance of trained model on training data
            
            x1 = (x(y==1,:,:))';
            if sum(sum(isnan(x1)))>0
                warning('there is some missing data that create NaN which are replaced by zero')
                x1(isnan(x1))=0;
            end
            
            pDprior=init(vMFMMB(esetup.initComps),x1);
            [model1]=adapt(pDprior,x1,50, 'fixed',0.1);
            
            x0 = real((x(y~=1,:,:))');
            if sum(sum(isnan(x0)))>0
                warning('there is some missing data that create NaN which are replaced by zero')
                x0(isnan(x0))=0;
            end
            
            pDprior=init(vMFMMB(esetup.initComps),x0);
            [model0]=adapt(pDprior,x0, 50, 'fixed',0.1);
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = obj.model;
        end
        %% ----------------------------------------------------------------
        
        function wp = setDataWeights( obj, y )
            ypShare = ( mean( y ) + 1 ) * 0.5;
            cp = ( 1 - ypShare ) / ypShare;
            if isnan( cp ) || isinf( cp )
                warning( 'The share of positive to negative examples is inf or nan.' );
            end
            wp = ones( size(y) );
            wp(y==1) = cp;
        end
        %% ----------------------------------------------------------------
        
    end
    
end