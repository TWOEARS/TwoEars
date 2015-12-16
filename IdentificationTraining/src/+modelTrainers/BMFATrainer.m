classdef BMFATrainer < modelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        model;
        nComp;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = BMFATrainer( varargin )
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
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y )
            obj.model = models.BMFAModel();
            xScaled = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
            gmmOpts.mfaK = obj.nComp;
            [obj.model.model{1}, obj.model.model{2}] = ...
                modelTrainers.BMFATrainer.trainBMFA( y, xScaled, gmmOpts );
            verboseFprintf( obj, '\n' );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Static)
        
        function [model1, model0] = trainBMFA( y, x, esetup )
            % y: labels of x
            % x: matrix of data points (+1 and -1!)
            % esetup: training parameters
            %
            % model: trained gmm
            
            
            x1 = (x(y==1,:,:))';
            if sum(sum(isnan(x1)))>0
                warning('there is some missing data that create NaN which are replaced by zero')
                x1(isnan(x1))=0;
            end
            %  [x1,~] = preprocess(x1);
            model1 = vbmfa(x1,esetup.mfaK);
            x0 = (x(y==-1,:,:))';
            if sum(sum(isnan(x0)))>0
                warning('there is some missing data that create NaN which are replaced by zero')
                x0(isnan(x0))=0;
            end
            % [x0,~] = preprocess(x0);
            model0 = vbmfa(x0,esetup.mfaK);
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