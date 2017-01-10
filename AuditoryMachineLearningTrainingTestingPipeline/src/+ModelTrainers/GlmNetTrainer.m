classdef GlmNetTrainer < ModelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        model;
        alpha;
        family;
        nLambda;
        lambda;
        labelWeights;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = GlmNetTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @PerformanceMeasures.BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'alpha', ...
                             'default', 1, ...
                             'valFun', @(x)(isfloat(x) && x >= 0 && x <= 1.0) );
            pds{3} = struct( 'name', 'family', ...
                             'default', 'binomial', ...
                             'valFun', @(x)(ischar(x) && any(strcmpi(x, ...
                                                                     {'binomial',...
                                                                      'multinomial',...
                                                                      'multinomialGrouped',...
                                                                      'gaussian',...
                                                                      'poisson'}))) );
            pds{4} = struct( 'name', 'nLambda', ...
                             'default', 100, ...
                             'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            pds{5} = struct( 'name', 'lambda', ...
                             'default', [], ...
                             'valFun', @(x)(isempty(x) || isfloat(x)) );
            pds{6} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            pds{7} = struct( 'name', 'labelWeights', ...
                             'default', [], ...
                             'valFun', @(x)(isempty(x) || isfloat(x)) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y )
            glmOpts.weights = obj.setDataWeights( y );
            obj.model = Models.GlmNetModel();
            x(isnan(x)) = 0;
            x(isinf(x)) = 0;
            xScaled = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
            clear x;
            glmOpts.alpha = obj.alpha;
            glmOpts.nlambda = obj.nLambda;
            if ~isempty( obj.lambda )
                glmOpts.lambda = obj.lambda;
            end
            if strcmpi( obj.family, 'multinomialGrouped' )
                family = 'multinomial';
                glmOpts.mtype = 'grouped';
            else
                family = obj.family;
            end
            verboseFprintf( obj, 'GlmNet training with alpha=%f\n', glmOpts.alpha );
            verboseFprintf( obj, '\tsize(x) = %dx%d\n', size(xScaled,1), size(xScaled,2) );
            obj.model.model = glmnet( xScaled, y, family, glmOpts );
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
            wp = ones( size(y) );
            for cc = 1 : size( y, 2 )
                labels = unique( y(:,cc) );
                lw = obj.labelWeights;
                if numel( lw ) ~= numel( labels )
                    lw = ones( size( labels ) );
                end
                for ii = 1 : numel( labels )
                    labelShare = sum( y(:,cc) == labels(ii) ) / size( y, 1 );
                    labelWeight = lw(ii) / labelShare;
                    wp(y(:,cc)==labels(ii),cc) = labelWeight;
                end
            end
            wp = mean( wp, 2 );
        end
        %% ----------------------------------------------------------------
        
    end
    
end