classdef GlmNetModelSelectTrainer < modelTrainers.HpsTrainer & Parameterized
    
    %% -----------------------------------------------------------------------------------
    properties (Access = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = GlmNetModelSelectTrainer( varargin )
            pds{1} = struct( 'name', 'hpsAlphaRange', ...
                             'default', [0.5 1], ...
                             'valFun', @(x)(isfloat(x) && length(x)==2 && x(1) < x(2)) );
            obj = obj@Parameterized( pds );
            obj = obj@modelTrainers.HpsTrainer( varargin{:} );
            obj.setParameters( true, ...
                'buildCoreTrainer', @GlmNetLambdaSelectTrainer, ...
               'hpsCoreTrainerParams', {'cvFolds', 2,}, ...
                varargin{:} );
            obj.setParameters( false, ...
                'finalCoreTrainerParams', ...
                    {'cvFolds', 2,} );
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function hpsSets = getHpsGridSearchSets( obj )
            hpsAlphas = linspace( obj.parameters.hpsAlphaRange(1), ...
                                  obj.parameters.hpsAlphaRange(2), ...
                                  obj.parameters.hpsSearchBudget );
            [aGrid] = ndgrid( hpsAlphas );
            hpsSets = [aGrid(:)];
            hpsSets = unique( hpsSets, 'rows' );
            hpsSets = cell2struct( num2cell(hpsSets), {'alpha'}, 2 );
        end
        %% -------------------------------------------------------------------------------
        
        function refinedHpsTrainer = refineGridTrainer( obj, hps )
            refinedHpsTrainer = GlmNetModelSelectTrainer( obj.parameters );
            best3LogMean = @(fn)(mean( log10( [hps.params(end-2:end).(fn)] ) ));
            aRefinedRange = 10.^getCenteredHalfRange( ...
                log10(obj.parameters.hpsAlphaRange), best3LogMean('alpha') );
            refinedHpsTrainer.setParameters( false, ...
                'hpsAlphaRange', aRefinedRange );
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = private)
        
    end
    
end