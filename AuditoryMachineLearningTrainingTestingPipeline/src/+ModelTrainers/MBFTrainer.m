classdef MBFTrainer < ModelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        model;
        nComp;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = MBFTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @PerformanceMeasures.BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            pds{3} = struct( 'name', 'nComp', ...
                'default', [1 2 3], ...
                'valFun', @(x)(sum(x)>=0) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y )
            obj.model = Models.MbfModel();
            xScaled = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
             gmmOpts.nComp = obj.nComp;
             xTrain = (normvec(xScaled'))';
%             xTrain = xScaled;
%             xTrain = (preprocess(xScaled'))';
%             xTrain = (normvec(xTrain'))';
            [obj.model.model{1}, obj.model.model{2}] = ...
                ModelTrainers.MBFTrainer.trainMbfs( y, xTrain, gmmOpts );
            verboseFprintf( obj, '\n' );

        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Static)
        
        function [model1, model0] = trainMbfs( y, x, esetup )
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
            x0 = real((x(y~=1,:,:))');
            if sum(sum(isnan(x0)))>0
                warning('there is some missing data that create NaN which are replaced by zero')
                x0(isnan(x0))=0;
            end
            factorDim = 1;
            mySetup.nIter = 10;
            mySetup.minLLstep = 1E-3;
            mySetup.TOLERANCE = 1E-1;
            % x1 = preprocess(x1);
            pDprior1 = init(MixtureFactorAnalysers(esetup.nComp),x1 ,factorDim);
            [model1,LL1,r1] = adapt(pDprior1, x1 ,mySetup);
            % x0 = preprocess(x0);
            pDprior0 = init(MixtureFactorAnalysers(esetup.nComp),x0 ,factorDim);
            [model0,LL0,r0] = adapt(pDprior0, x0 ,mySetup);
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