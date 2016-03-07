classdef GlmGroupTrainer < modelTrainers.Base & Parameterized
    %GLMGROUPTRAINER trainer for a GlmGroupModel, will fit a regression
    % model with L1,0, L1,2 or L1,inf norm regularizeration.
    
    properties (SetAccess = {?Parameterized})
        model;
        family; % todo
        norm;
        groups;
        nlambdas;
        lambda;
    end
    
    methods
        %% CONSTRUCTOR
        function obj = GlmGroupTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                'default', @performanceMeasures.BAC2, ...
                'valFun', @(x)(isa( x, 'function_handle' )), ...
                'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'family', ...
                'default', 'binomial', ...
                'valFun', @(x)(ischar(x) && any(strcmpi(x, {'binomial'}))) );
            pds{3} = struct( 'name', 'norm', ...
                'default', 2, ...
                'valFun', @(x)(x==0 || x==2 || isinf(x)) );
            pds{4} = struct( 'name', 'groups', ...
                'default', ones(10), ...
                'valFun', @(x)(isvector(x)) );
            pds{5} = struct( 'name', 'nlambdas', ...
                'default', 100, ...
                'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            pds{6} = struct( 'name', 'lambda', ...
                'default', [], ...
                'valFun', @(x)(isempty(x) || isfloat(x)) );
            pds{7} = struct( 'name', 'maxDataSize', ...
                'default', inf, ...
                'valFun', @(x)(isinf(x) || rem(x,1) == 0 ) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        
        %% BUILD MODEL
        function buildModel(self, x, y)
            % init
            self.model = models.GlmGroupModel();
            
            % precondition inputs
            x(isinf(x)) = nan;
            colmeans = nanmedian(x,1);
            nan_at = isnan(x);
            for i = 1:length(colmeans)
                if any(nan_at(:,i))
                    x(nan_at(:,i),i) = colmeans(i);
                end
            end
            x = self.model.scale2zeroMeanUnitVar(x, 'saveScalingFactors');
            y = y .* self.getWeights(y);
            
            % fit lambda path
            verboseFprintf(self, 'GlmGroup training\n');
            verboseFprintf(self, '\tsize(x) = %dx%d\n', size(x,1), size(x,2));
            self.model.model = self.fitGlmL1L2( ...
                x, y, self.groups, self.nlambdas, self.norm);
            verboseFprintf( self, '\n' );
            
            % tidy up
            clear x;
        end
    end
    
    methods (Access = protected)
        %% GET MODEL
        function rval = giveTrainedModel(self)
            rval = self.model;
        end
        
        %% GET WEIGHTS (Called set* funny)
        function rval = getWeights(self, y)
            cnt_pos = sum(y==1);
            cnt_neg = sum(y~=1);
            rval = ones( size(y) );
            rval(y==1) = cnt_neg/cnt_pos;
        end
    end
    
    methods (Static)
        %% FIT L1,<norm> REGULARISED MODEL (aka Group LASSO)
        function rval = fitGlmL1L2( X, y, g, nlambdas, norm )
            % static fitting method. solves the L1,L2 regularised
            % logistic regression problem for groups given by the group
            % label vector `g`
            
            % TODO init and checks
            [n,p] = size(X);
            
            % solve for null model
            w_init = zeros(p+1,1);
            bias = log(sum(y==1)/sum(y==-1));
            if ~isinf(bias)
                w_init(1) = bias;
            end
            X = [ones(n,1) X]; % augment X for intercept
            g = [0; g];
            
            % find lambda_max and build a linear path down to zero
            [~,grad] = LogisticLoss(w_init,X,y);
            grad_norms = sqrt(accumarray(g(g~=0),grad(g~=0).^2));
            lambda_max = max(grad_norms);
            lambdas = lambda_max*[1:-(1.0/(nlambdas-1)):0]';
            lambda_path = zeros(p+1,nlambdas);
            
            % solve path using the spectral projected gradient solver by
            % Mark Schmidt, using warm starts
            options.method = 'spg';
            options.norm = norm; % within group norm
            options.verbose = 0; % only print final summary, no step spam
            objective = @(w)(LogisticLoss(w,X,y));
            for i = 1:nlambdas
                lambda_path(:,i) = L1GeneralGroup_Auxiliary( ...
                    objective,w_init,lambdas(i),g,options);
                w_init = lambda_path(:,i);
            end
            
            % build results compatible with GlmNet, so we can use their tools
            rval = struct();
            rval.class = 'lognet';
            rval.call = {'X' 'y' 'binomial' '[]'};
            rval.offset = false;
            rval.jerr = 0;
            rval.npasses = 0;
            rval.label = [-1;1];
            rval.a0 = lambda_path(1,:);
            rval.beta = lambda_path(2:end,:);
            rval.df = sum(rval.beta~=0,1)';
            rval.lambda = lambdas;
            rval.dim = size(rval.beta);
            
            % deviance calculations
            rval.dev = zeros(nlambdas,1);
            ll_sat = -LogisticLoss(lambda_path(:,nlambdas),X,y);
            for i = 1:nlambdas
                rval.dev(i) = 2*(ll_sat+LogisticLoss(lambda_path(:,i),X,y));
            end
            rval.nulldev = rval.dev(1);
            rval.dev = 1 - rval.dev./rval.nulldev;
        end
    end
end