classdef GmmTrainer < IdTrainerInterface & Parameterized
    
    %% --------------------------------------------------------------------
    properties (Access = protected)
        model;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = GmmTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
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
            obj.model = GmmModel();
            xScaled = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
%             glmOpts.alpha = obj.parameters.alpha;
%             glmOpts.nlambda = obj.parameters.nLambda;
%             if ~isempty( obj.parameters.lambda )
%                 glmOpts.lambda = obj.parameters.lambda;
%             end
%             verboseFprintf( obj, 'GlmNet training with alpha=%f\n', glmOpts.alpha );
%             verboseFprintf( obj, '\tsize(x) = %dx%d\n', size(x,1), size(x,2) );
%             obj.model.model = glmnet( xScaled, y, obj.parameters.family, glmOpts );
            gmmOpts.initComps = 5;
            idFeature = featureSelectionPCA2(xScaled,.93);
            [obj.model.model{1}, obj.model.model{2}] = trainGmms( y, xScaled(:,idFeature), gmmOpts );
            obj.model.model{3}=idFeature;
            % train +1 model
            % call obj.setPositiveClass( 'general' );
            verboseFprintf( obj, '\n' );
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