classdef MFAmodelSelectTrainer < modelTrainers.Base & Parameterized
    
    %% -----------------------------------------------------------------------------------
    properties (Access = private)
        cvTrainer;
        coreTrainer;
        fullSetModel;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = MFAmodelSelectTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                'default', @performanceMeasures.BAC2, ...
                'valFun', @(x)(isa( x, 'function_handle' )), ...
                'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'maxDataSize', ...
                'default', inf, ...
                'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            pds{3} = struct( 'name', 'nComp', ...
                'default', [1 2 3], ...
                'valFun', @(x)(sum(x)>=0) );
            pds{4} = struct( 'name', 'nDim', ...
                'default', [2 3], ...
                'valFun', @(x)(sum(x)>=0 ) );
            pds{5} = struct( 'name', 'cvFolds', ...
                'default', 4, ...
                'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
        function run( obj )
            obj.buildModel();
        end
        %% ----------------------------------------------------------------
        
        function buildModel( obj, ~, ~ )
            comps =  obj.parameters.nComp;
            nDims =  obj.parameters.nDim;
            for nt=1:numel(nDims)
                obj.parameters.nDim = nDims(nt);
                for nc=1:numel(comps)
                    obj.parameters.nComp = comps(nc);
                    verboseFprintf( obj, '\nRun on full trainSet...\n' );
                    obj.coreTrainer = modelTrainers.MfaNetTrainer( ...
                        'performanceMeasure', obj.parameters.performanceMeasure, ...
                        'maxDataSize', obj.parameters.maxDataSize,...
                        'nComp', obj.parameters.nComp, ...
                        'nDim', obj.parameters.nDim);
                    
                    obj.coreTrainer.setData( obj.trainSet, obj.testSet );
                    obj.coreTrainer.setPositiveClass( obj.positiveClass );
                    obj.coreTrainer.run();
                    obj.fullSetModel = obj.coreTrainer.getModel();
                    
                    verboseFprintf( obj, '\nRun cv to determine best number of components...\n' );
                    obj.cvTrainer = modelTrainers.CVtrainer( obj.coreTrainer );
                    obj.cvTrainer.setPerformanceMeasure( obj.performanceMeasure );
                    obj.cvTrainer.setPositiveClass( obj.positiveClass );
                    obj.cvTrainer.setData( obj.trainSet, obj.testSet );
                    obj.cvTrainer.setNumberOfFolds( obj.parameters.cvFolds );
                    obj.cvTrainer.run();
                    cvModels{nt,nc} = obj.cvTrainer.models;
                    verboseFprintf( obj, 'Calculate Performance for all values of components...\n' );
                end
            end
            for nt=1:numel(nDims)
                lPerfs = zeros( numel( comps ), numel( cvModels{1} ) );
                for nc = 1 : numel( comps )
                    for ii = 1 : numel( cvModels{nt,nc} )
                        lPerfs(nc,ii) = models.Base.getPerformance( ...
                            cvModels{nt,nc}{ii}, obj.cvTrainer.folds{ii}, obj.positiveClass, ...
                            obj.performanceMeasure );
                    end
                end
                nDimCompMatrix(:,nt) = mean(lPerfs,2);
            end
            [bComp, bnDim] = find( nDimCompMatrix==max(max(nDimCompMatrix)));
            % trian the best model
            obj.parameters.nComp = comps(bComp);
            obj.parameters.nDim = nDims(bnDim);
            verboseFprintf( obj, '\nRun on full trainSet...\n' );
            obj.coreTrainer = modelTrainers.MfaNetTrainer( ...
                'performanceMeasure', obj.parameters.performanceMeasure, ...
                'maxDataSize', obj.parameters.maxDataSize,...
                'nComp', obj.parameters.nComp, ...
                'nDim', obj.parameters.nDim);
            
            obj.coreTrainer.setData( obj.trainSet, obj.testSet );
            obj.coreTrainer.setPositiveClass( obj.positiveClass );
            obj.coreTrainer.run();
            obj.fullSetModel = obj.coreTrainer.getModel();
            %             obj.fullSetModel.setnComp( bestnComp );
        end
        %% -------------------------------------------------------------------------------
        
        function performance = getPerformance( obj )
            performance = models.Base.getPerformance( ...
                obj.fullSetModel, obj.testSet, obj.positiveClass, ...
                obj.performanceMeasure );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = obj.fullSetModel;
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
        
    end
    
end