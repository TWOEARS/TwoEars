classdef LoadModelNoopTrainer < ModelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        modelPath;
        modelParams;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = LoadModelNoopTrainer( modelPath, varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @PerformanceMeasures.BAC2, ...
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
            obj.modelPath = modelPath;
        end
        %% ----------------------------------------------------------------

        function buildModel( ~, ~, ~ )
            % noop
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            if ~exist( obj.modelPath, 'file' )
                error( 'Could not find "%s".', obj.modelPath );
            end
            ms = load( obj.modelPath, 'model' );
            model = ms.model;
            fieldsModelParams = fieldnames( obj.modelParams );
            for ii = 1: length( fieldsModelParams )
                model.(fieldsModelParams{ii}) = obj.modelParams.(fieldsModelParams{ii});
            end
        end
        %% ----------------------------------------------------------------
        
    end
    
end