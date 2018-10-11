classdef MFAmodelSelectTrainer < ModelTrainers.Base & Parameterized
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        cvTrainer;
        coreTrainer;
        fullSetModel;
        nComp;
        nDim;
        cvFolds;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = MFAmodelSelectTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                'default', @PerformanceMeasures.BAC2, ...
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
        
        function buildModel( obj, ~, ~, ~ )
            comps =  obj.nComp;
            nDims =  obj.nDim;
            for nt=1:numel(nDims)
                obj.nDim = nDims(nt);
                for nc=1:numel(comps)
                    obj.nComp = comps(nc);
                    verboseFprintf( obj, '\nRun on full trainSet...\n' );
                    obj.coreTrainer = ModelTrainers.MfaNetTrainer( ...
                        'performanceMeasure', obj.performanceMeasure, ...
                        'maxDataSize', obj.maxDataSize,...
                        'nComp', obj.nComp, ...
                        'nDim', obj.nDim);
                    
                    obj.coreTrainer.setData( obj.trainSet, obj.testSet );
                    obj.coreTrainer.run();
                    obj.fullSetModel = obj.coreTrainer.getModel();
                    
                    verboseFprintf( obj, '\nRun cv to determine best number of components...\n' );
                    obj.cvTrainer = ModelTrainers.CVtrainer( obj.coreTrainer );
                    obj.cvTrainer.setPerformanceMeasure( obj.performanceMeasure );
                    obj.cvTrainer.setData( obj.trainSet, obj.testSet );
                    obj.cvTrainer.setNumberOfFolds( obj.cvFolds );
                    obj.cvTrainer.run();
                    cvModels{nt,nc} = obj.cvTrainer.models;
                    verboseFprintf( obj, 'Calculate Performance for all values of components...\n' );
                end
            end
            for nt=1:numel(nDims)
                lPerfs = zeros( numel( comps ), numel( cvModels{1} ) );
                for nc = 1 : numel( comps )
                    for ii = 1 : numel( cvModels{nt,nc} )
                        lPerfs(nc,ii) = Models.Base.getPerformance( ...
                            cvModels{nt,nc}{ii}, obj.cvTrainer.folds{ii}, ...
                            obj.performanceMeasure );
                    end
                end
                nDimCompMatrix(:,nt) = mean(lPerfs,2);
            end
            [bComp, bnDim] = find( nDimCompMatrix==max(max(nDimCompMatrix)));
            % trian the best model
            obj.nComp = comps(bComp);
            obj.nDim = nDims(bnDim);
            verboseFprintf( obj, '\nRun on full trainSet...\n' );
            obj.coreTrainer = ModelTrainers.MfaNetTrainer( ...
                'performanceMeasure', obj.performanceMeasure, ...
                'maxDataSize', obj.maxDataSize,...
                'nComp', obj.nComp, ...
                'nDim', obj.nDim);
            
            obj.coreTrainer.setData( obj.trainSet, obj.testSet );
            obj.coreTrainer.run();
            obj.fullSetModel = obj.coreTrainer.getModel();
            %             obj.fullSetModel.setnComp( bestnComp );
        end
        %% -------------------------------------------------------------------------------
        
        function performance = getPerformance( obj )
            performance = Models.Base.getPerformance( ...
                obj.fullSetModel, obj.testSet, ...
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