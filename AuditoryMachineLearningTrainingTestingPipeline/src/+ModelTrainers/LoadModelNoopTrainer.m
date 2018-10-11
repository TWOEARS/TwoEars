classdef LoadModelNoopTrainer < ModelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        modelPath;
        modelParams;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = LoadModelNoopTrainer( modelPath, varargin )
            pds{1} = struct( 'name', 'modelParams', ...
                             'default', struct(), ...
                             'valFun', @(x)(isstruct( x )) );
            obj = obj@Parameterized( pds );
            obj = obj@ModelTrainers.Base( varargin{:} );
            obj.setParameters( true, varargin{:} );
            obj.modelPath = modelPath;
        end
        %% ----------------------------------------------------------------

        function buildModel( ~, ~, ~, ~ )
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