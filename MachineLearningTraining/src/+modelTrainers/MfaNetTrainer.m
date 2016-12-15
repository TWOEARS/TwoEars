classdef MfaNetTrainer < modelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        model;
        nComp;
        nDim;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = MfaNetTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                'default', @performanceMeasures.BAC2, ...
                'valFun', @(x)(isa( x, 'function_handle' )), ...
                'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'nComp', ...
                'default', [1 2 3], ...
                'valFun', @(x)(sum(x)>=0) );
            pds{3} = struct( 'name', 'nDim', ...
                             'default', [5 6], ...
                             'valFun', @(x)(sum(x) >= 0) );
            pds{4} = struct( 'name', 'maxDataSize', ...
                'default', inf, ...
                'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y )
            obj.model = models.MfaNetModel();
            xScaled = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
            mbfOpts.nComp = obj.nComp;
            mbfOpts.nDim = obj.nDim;
            if ~isempty( obj.nComp )
                mbfOpts.nComp = obj.nComp;
            end
            verboseFprintf( obj, 'MbfNet training with nComp=%f and nDim=%f\n', mbfOpts.nComp, mbfOpts.nDim);
            verboseFprintf( obj, '\tsize(x) = %dx%d\n', size(x,1), size(x,2) );
            mbfOpts.mfaK = mbfOpts.nComp;
            mbfOpts.mfaM = mbfOpts.nDim;
            [obj.model.model{1}, obj.model.model{2}] = ...
                modelTrainers.MFATrainer.trainMFA( y, xScaled, mbfOpts );
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