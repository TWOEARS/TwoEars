classdef (Abstract) HpsTrainer < IdTrainerInterface & Parameterized
    
    %% -----------------------------------------------------------------------------------
    properties (Access = private)
        hpsCVtrainer;
        coreTrainer;
        trainWithBestHps = true;
        hpsSets;
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = HpsTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'buildCoreTrainer', ...
                             'default', [], ...
                             'valFun', @(x)(~isempty( x ) && ...
                                            isa( x, 'function_handle' )) );
            pds{3} = struct( 'name', 'hpsCoreTrainerParams', ...
                             'default', {{}}, ...
                             'valFun', @(x)(iscell( x )) );
            pds{4} = struct( 'name', 'finalCoreTrainerParams', ...
                             'default', {{}}, ...
                             'valFun', @(x)(iscell( x )) );
            pds{5} = struct( 'name', 'hpsMaxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            pds{6} = struct( 'name', 'hpsRefineStages', ...
                             'default', 1, ...
                             'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            pds{7} = struct( 'name', 'hpsSearchBudget', ...
                             'default', 8, ...
                             'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            pds{8} = struct( 'name', 'hpsCvFolds', ...
                              'default', 4, ...
                              'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            pds{9} = struct( 'name', 'hpsMethod', ...
                              'default', 'grid', ...
                              'valFun', @(x)(...
                                       ischar(x) && any(strcmpi(x, {'grid','random'}))) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
        function run( obj )
            obj.buildModel();
        end
        %% ----------------------------------------------------------------
        
        function buildModel( obj, ~, ~ )
            obj.coreTrainer = obj.parameters.buildCoreTrainer();
            obj.createHpsTrainer();
            hps.params = obj.determineHyperparameterSets();
            hps.perfs = zeros( size( hps.params ) );
            verboseFprintf( obj, '\nHyperparameter search CV...\n' );
            for ii = 1 : size( hps.params, 1 )
                verboseFprintf( obj, '\nhps set %d...\n ', ii );
                obj.coreTrainer.setParameters( false, ...
                    'maxDataSize', obj.parameters.hpsMaxDataSize, ...
                    hps.params(ii), ...
                    obj.parameters.hpsCoreTrainerParams{:} );
                obj.hpsCVtrainer.abortPerfMin = max( hps.perfs );
                obj.hpsCVtrainer.run();
                hps.perfs(ii) = obj.hpsCVtrainer.getPerformance().avg;
            end
            verboseFprintf( obj, 'Done\n' );
            if obj.parameters.hpsRefineStages > 0
                verboseFprintf( obj, 'HPS refine stage...\n' );
                refinedHpsTrainer = obj.createRefineGridTrainer( hps );
                refinedHpsTrainer.run();
                hps.params = [hps.params; refinedHpsTrainer.hpsSets.params];
                hps.perfs = [hps.perfs; refinedHpsTrainer.hpsSets.perfs];
            end
            obj.hpsSets = obj.sortHpsSetsByPerformance( hps );
            verboseFprintf( obj, 'Best HPS set performance: %f\n', obj.hpsSets.perfs(end) );
            if obj.trainWithBestHps
                obj.coreTrainer.setParameters( false, ...
                    obj.hpsSets.params(end), ...
                    'maxDataSize', inf, ...
                    obj.parameters.finalCoreTrainerParams{:} );
                obj.coreTrainer.setData( obj.trainSet, obj.testSet );
                verboseFprintf( obj, 'Train with best HPS set on full trainSet...\n' );
                obj.coreTrainer.run();
            end
        end
        %% -------------------------------------------------------------------------------
        
        function performance = getPerformance( obj )
            performance = obj.coreTrainer.getPerformance();
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = obj.coreTrainer.getModel();
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = private)
        
        function createHpsTrainer( obj )
            obj.hpsCVtrainer = CVtrainer( obj.coreTrainer );
            obj.hpsCVtrainer.setPerformanceMeasure( obj.performanceMeasure );
            obj.hpsCVtrainer.setPositiveClass( obj.positiveClass );
            obj.hpsCVtrainer.setData( obj.trainSet, obj.testSet );
            obj.hpsCVtrainer.setNumberOfFolds( obj.parameters.hpsCvFolds );
        end
        %% -------------------------------------------------------------------------------
        
        function hpsSets = determineHyperparameterSets( obj )
            switch( lower( obj.parameters.hpsMethod ) )
                case 'grid'
                    hpsSets = obj.getHpsGridSearchSets();
                case 'random'
                    error( 'not implemented' );
                case 'intelligrid'
                    error( 'not implemented.' );
            end
        end
        %% -------------------------------------------------------------------------------

        function refinedHpsTrainer = createRefineGridTrainer( obj, hps )
            hps = obj.sortHpsSetsByPerformance( hps );
            refinedHpsTrainer = obj.refineGridTrainer( hps );
            refinedHpsTrainer.setPositiveClass( obj.positiveClass );
            refinedHpsTrainer.setData( obj.trainSet, obj.testSet );
            refinedHpsTrainer.trainWithBestHps = false;
            refinedHpsTrainer.setParameters( false, ...
                'hpsRefineStages', obj.parameters.hpsRefineStages - 1 );
        end
        %% -------------------------------------------------------------------------------
        
        function hps = sortHpsSetsByPerformance( obj, hps )
            [hps.perfs,idx] = sort( hps.perfs );
            hps.params = hps.params(idx);
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Abstract, Access = protected)
        hpsSets = getHpsGridSearchSets( obj )
        refinedHpsTrainer = refineGridTrainer( obj, hps )
    end
        
end