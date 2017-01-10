classdef SVMtrainer < ModelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        model;
        epsilon;
        kernel;
        c;
        gamma;
        makeProbModel;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = SVMtrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @PerformanceMeasures.BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'epsilon', ...
                             'default', 0.001, ...
                             'valFun', @(x)(isfloat(x) && x > 0) );
            pds{3} = struct( 'name', 'kernel', ...
                             'default', 0, ...
                             'valFun', @(x)(rem(x,1) == 0 && all(x == 0 | x == 2)) );
            pds{4} = struct( 'name', 'c', ...
                             'default', 1, ...
                             'valFun', @(x)(isfloat(x) && x > 0) );
            pds{5} = struct( 'name', 'gamma', ...
                             'default', 0.1, ...
                             'valFun', @(x)(isfloat(x) && x > 0) );
            pds{6} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            pds{7} = struct( 'name', 'makeProbModel', ...
                             'default', false, ...
                             'valFun', @islogical );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y )
            [x, y, cp] = obj.prepareData( x, y );
            obj.model = Models.SVMmodel();
            obj.model.useProbModel = obj.makeProbModel;
            xScaled = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
            m = ceil( prod( size( x ) ) * 8 / (1024 * 1024) );
            m = min( 2*m, 2000 );
            svmParamStrScheme = '-t %d -g %e -c %e -w-1 1 -w1 %e -e %e -m %d -b %d -h 0';
            svmParamStr = sprintf( svmParamStrScheme, ...
                obj.kernel, obj.gamma, ...
                obj.c, cp, ...
                obj.epsilon, m, obj.makeProbModel );
            if ~obj.verbose, svmParamStr = [svmParamStr, ' -q']; end
            verboseFprintf( obj, 'SVM training with param string\n\t%s\n', svmParamStr );
            verboseFprintf( obj, '\tsize(x) = %dx%d\n', size(x,1), size(x,2) );
            obj.model.model = libsvmtrain( y, xScaled, svmParamStr );
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
        
        function [x,y,cp] = prepareData( obj, x, y )
            ypShare = ( mean( y ) + 1 ) * 0.5;
            cp = ( 1 - ypShare ) / ypShare;
            if isnan( cp ) || isinf( cp )
                warning( 'The share of positive to negative examples is inf or nan.' );
            end
            if obj.makeProbModel
                x = [x(y == -1,:); repmat( x(y == +1,:), round( cp ), 1)];
                y = [y(y == -1); repmat( y(y == +1), round( cp ), 1)];
                cp = 1;
            end
        end
        %% ----------------------------------------------------------------
        
    end
    
end