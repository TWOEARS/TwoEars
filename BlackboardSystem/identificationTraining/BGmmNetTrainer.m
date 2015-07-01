classdef BGmmNetTrainer < IdTrainerInterface & Parameterized
    
    %% --------------------------------------------------------------------
    properties (Access = protected)
        model;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = BGmmNetTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                'default', @BAC2, ...
                'valFun', @(x)(isa( x, 'function_handle' )), ...
                'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'nComp', ...
                'default', [1 2 3], ...
                'valFun', @(x)(sum(x)>=0) );
            pds{3} = struct( 'name', 'thr', ...
                             'default', [0.5 0.6], ...
                             'valFun', @(x)(x<=1 && x >= 0) );
            pds{4} = struct( 'name', 'maxDataSize', ...
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
            obj.model = BGmmNetModel();
            xScaled = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
            gmmOpts.nComp = obj.parameters.nComp;
            gmmOpts.thr = obj.parameters.thr;
            if ~isempty( obj.parameters.nComp )
                gmmOpts.nComp = obj.parameters.nComp;
            end
            verboseFprintf( obj, 'GmmNet training with nComp=%f and thr=%f\n', gmmOpts.nComp, gmmOpts.thr);
            verboseFprintf( obj, '\tsize(x) = %dx%d\n', size(x,1), size(x,2) );
%             obj.model.model = glmnet( xScaled, y, obj.parameters.family, glmOpts );
            gmmOpts.initComps = gmmOpts.nComp;
          idFeature = featureSelectionPCA2(xScaled,gmmOpts.thr);
            [obj.model.model{1}, obj.model.model{2}] = trainBGMMs( y, xScaled(:,idFeature), gmmOpts );
            obj.model.model{3}=idFeature;            % train +1 model
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