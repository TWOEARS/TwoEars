classdef LoadModelNoopTrainer < modelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        modelPathBuilder;
        modelParams;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = LoadModelNoopTrainer( modelPathBuilder, varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @performanceMeasures.BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'modelParams', ...
                             'default', struct(), ...
                             'valFun', @(x)(isstruct( x )) );
            pds{3} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
            obj.modelPathBuilder = modelPathBuilder;
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y )
            % noop
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            if ~exist( obj.modelPathBuilder( obj.positiveClass ), 'file' )
                error( 'Could not find "%s".', obj.modelPathBuilder( obj.positiveClass ) );
            end
            ms = load( obj.modelPathBuilder( obj.positiveClass ) );
            model = ms.model;
            fieldsModelParams = fieldnames( obj.modelParams );
            for ii = 1: length( fieldsModelParams )
                model.(fieldsModelParams{ii}) = obj.modelParams.(fieldsModelParams{ii});
            end
        end
        %% ----------------------------------------------------------------
        
    end
    
end