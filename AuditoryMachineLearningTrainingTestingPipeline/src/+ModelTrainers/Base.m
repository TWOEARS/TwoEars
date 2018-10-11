classdef (Abstract) Base < handle & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        trainSet;
        testSet;
    end
    
    properties (SetAccess = {?ModelTrainers.Base, ?Parameterized})
        performanceMeasure;
        maxDataSize;
        dataSelector;
        importanceWeighter;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = Base( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @PerformanceMeasures.BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            pds{3} = struct( 'name', 'dataSelector', ...
                             'default', DataSelectors.IgnorantSelector(), ...
                             'valFun', @(x)(isa( x, 'DataSelectors.Base') ) );
            pds{4} = struct( 'name', 'importanceWeighter', ...
                             'default', ImportanceWeighters.IgnorantWeighter(), ...
                             'valFun', @(x)(isa( x, 'ImportanceWeighters.Base') ) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------
        
        function setData( obj, trainSet, testSet )
            obj.trainSet = trainSet;
            if ~exist( 'testSet', 'var' ), testSet = []; end
            obj.testSet = testSet;
        end
        %% ----------------------------------------------------------------
        
        function setPerformanceMeasure( obj, newPerformanceMeasure )
            if ~isa( newPerformanceMeasure, 'function_handle' )
                error( ['newPerformanceMeasure must be a function handle pointing ', ...
                        'to the constructor of a PerformanceMeasure interface.'] );
            end
            obj.performanceMeasure = newPerformanceMeasure;
        end
        %% ----------------------------------------------------------------
        
        function model = getModel( obj )
            model = obj.giveTrainedModel();
            if ~isa( model, 'Models.Base' )
                error( 'giveTrainedModel must produce an Models.Base object.' );
            end
            model.featureMask = ModelTrainers.Base.featureMask;
        end
        %% -------------------------------------------------------------------------------
        
        function v = verbose( obj, newV )
            persistent verb;    % faking a static property
            if isempty( verb ), verb = false; end
            if nargin > 1
                if islogical( newV )
                    verb = newV;
                elseif ischar( newV ) && any( strcmpi( newV, {'true','on','set'} ) )
                    verb = true;
                elseif ischar( newV ) && any( strcmpi( newV, {'false','off','unset'} ) )
                    verb = false;
                else
                    error( 'wrong datatype for newV.' );
                end
            end
            v = verb;
        end
        %% -------------------------------------------------------------------------------
        
        function performance = getPerformance( obj, getDatapointInfo )
            if nargin < 2, getDatapointInfo = false; end
            verboseFprintf( obj, 'Applying model to test set...\n' );
            model = obj.getModel();
            model.verbose( obj.verbose );
            performance = Models.Base.getPerformance( ...
                model, obj.testSet, obj.performanceMeasure, ...
                obj.maxDataSize, obj.dataSelector, obj.importanceWeighter, getDatapointInfo );
        end
        %% ----------------------------------------------------------------

        function run( obj )
            obj.dataSelector.connectData( obj.trainSet );
            obj.importanceWeighter.connectData( obj.trainSet );
            [x,y,sampleIds] = obj.getPermutedTrainingData();
            nanXidxs = any( isnan( x ), 2 );
            infXidxs = any( isinf( x ), 2 );
            if any( nanXidxs ) || any( infXidxs ) 
                warning( 'There are NaNs or INFs in the data -- throwing those vectors away!' );
                x(nanXidxs | infXidxs,:) = [];
                y(nanXidxs | infXidxs,:) = [];
                sampleIds(nanXidxs | infXidxs) = [];
            end
            if size( y, 1 ) > obj.maxDataSize
                selectFilter = obj.dataSelector.getDataSelection( sampleIds, obj.maxDataSize );
                verboseFprintf( obj, obj.dataSelector.verboseOutput );
                x = x(selectFilter,:);
                y = y(selectFilter,:);
                sampleIds = sampleIds(selectFilter);
            end
            iw = obj.importanceWeighter.getImportanceWeights( sampleIds );
            verboseFprintf( obj, obj.importanceWeighter.verboseOutput );
            obj.buildModel( x, y, iw );
        end
        %% ----------------------------------------------------------------

        function [x,y,permutationIdxs] = getPermutedTrainingData( obj )
            x = obj.trainSet(:,'x');
            if isempty( x )
                warning( 'There is no data to train the model.' ); 
                y = [];
                permutationIdxs = [];
                return;
            else
                y = obj.trainSet(:,'y');
            end
            % apply feature mask, if set
            fmask = ModelTrainers.Base.featureMask;
            if ~isempty( fmask )
                p_feat = size( x, 2 );
                p_mask = size( ModelTrainers.Base.featureMask, 1 );
                fmask = fmask( 1 : min( p_feat, p_mask ) );
                x = x(:,fmask);
            end
            % permute data
            permutationIdxs = randperm( size( y, 1 ) )';
            x = x(permutationIdxs,:);
            y = y(permutationIdxs,:);
        end
        %% ----------------------------------------------------------------

        
    end

    %% --------------------------------------------------------------------
    methods (Abstract)
        buildModel( obj, x, y, iw )
    end

    %% --------------------------------------------------------------------
    methods (Abstract, Access = protected)
        model = giveTrainedModel( obj )
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    
        function fm = featureMask( setNewMask, newmask )
            % Set/Reset the featureMask and return it.
            %   featureMask() reset the featurMask
            %   featureMask( setNewMask, newmask ) set the feature mask to 
            %       newmask on the condition that setNewMask is true
            persistent featureMask;
            if isempty( featureMask )
                featureMask = [];
            end
            if nargin > 0  &&  setNewMask
                if ~isempty( newmask ) && size( newmask, 2 ) ~= 1, newmask = newmask'; end;
                if ~islogical( newmask ), newmask = logical( newmask ); end
                featureMask = newmask;
            end
            fm = featureMask;
        end
        
    end

end

