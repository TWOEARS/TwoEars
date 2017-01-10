classdef MBFmodelSelectTrainer < modelTrainers.Base & Parameterized
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        cvTrainer;
        coreTrainer;
        fullSetModel;
        nComp;
        thr;
        cvFolds;
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = MBFmodelSelectTrainer( varargin )
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
           pds{4} = struct( 'name', 'thr', ...
                             'default', [0.5 0.6], ...
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
             comps =  obj.nComp;
             thrs =  obj.thr;
         for nt=1:numel(thrs)
             obj.thr = thrs(nt);
             for nc=1:numel(comps)
                 obj.nComp = comps(nc);
                 verboseFprintf( obj, '\nRun on full trainSet...\n' );
                 obj.coreTrainer = modelTrainers.MbfNetTrainer( ...
                     'performanceMeasure', obj.performanceMeasure, ...
                     'maxDataSize', obj.maxDataSize,...
                     'nComp', obj.nComp, ...
                     'thr', obj.thr);
                 
                 obj.coreTrainer.setData( obj.trainSet, obj.testSet );
                 obj.coreTrainer.setPositiveClass( obj.positiveClass );
                 obj.coreTrainer.run();
                 obj.fullSetModel = obj.coreTrainer.getModel();
                 
                 verboseFprintf( obj, '\nRun cv to determine best number of components...\n' );
                 obj.cvTrainer = modelTrainers.CVtrainer( obj.coreTrainer );
                 obj.cvTrainer.setPerformanceMeasure( obj.performanceMeasure );
                 obj.cvTrainer.setPositiveClass( obj.positiveClass );
                 obj.cvTrainer.setData( obj.trainSet, obj.testSet );
                 obj.cvTrainer.setNumberOfFolds( obj.cvFolds );
                 obj.cvTrainer.run();
                 cvModels{nt,nc} = obj.cvTrainer.models;
                 verboseFprintf( obj, 'Calculate Performance for all values of components...\n' );
             end
         end
         for nt=1:numel(thrs)
            lPerfs = zeros( numel( comps ), numel( cvModels{1} ) );
            for nc = 1 : numel( comps )
                for ii = 1 : numel( cvModels{nt,nc} )
                    %                     cvModels{ii}.setLambda( lambdas(ll) );
                    %                   cvModels{ii}.setnComp( comps(ll) );
                    lPerfs(nc,ii) = models.Base.getPerformance( ...
                        cvModels{nt,nc}{ii}, obj.cvTrainer.folds{ii}, obj.positiveClass, ...
                        obj.performanceMeasure );
                end
            end
            thrCompMatrix(:,nt) = mean(lPerfs,2);
         end
            [bComp, bThr] = find( thrCompMatrix==max(max(thrCompMatrix)));
            % trian the best model
            obj.nComp = comps(bComp);
            obj.thr = thrs(bThr);
            verboseFprintf( obj, '\nRun on full trainSet...\n' );
            obj.coreTrainer = modelTrainers.MbfNetTrainer( ...
                'performanceMeasure', obj.performanceMeasure, ...
                'maxDataSize', obj.maxDataSize,...
                'nComp', obj.nComp, ...
                'thr', obj.thr);
            
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