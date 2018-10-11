classdef GlmNetTrainer < ModelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        model;
        alpha;
        family;
        nLambda;
        lambda;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = GlmNetTrainer( varargin )
            pds{1} = struct( 'name', 'alpha', ...
                             'default', 1, ...
                             'valFun', @(x)(isfloat(x) && x >= 0 && x <= 1.0) );
            pds{2} = struct( 'name', 'family', ...
                             'default', 'binomial', ...
                             'valFun', @(x)(ischar(x) && any(strcmpi(x, ...
                                                                     {'binomial',...
                                                                      'multinomial',...
                                                                      'multinomialGrouped',...
                                                                      'gaussian',...
                                                                      'poisson'}))) );
            pds{3} = struct( 'name', 'nLambda', ...
                             'default', 100, ...
                             'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            pds{4} = struct( 'name', 'lambda', ...
                             'default', [], ...
                             'valFun', @(x)(isempty(x) || isfloat(x)) );
            obj = obj@Parameterized( pds );
            obj = obj@ModelTrainers.Base( varargin{:} );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y, iw )
            glmOpts.weights = iw;
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
            verboseFprintf( obj, '\nGlmNet training with alpha=%f\n', glmOpts.alpha );
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
        
    end
    
end