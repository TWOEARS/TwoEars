classdef (Abstract) Base < handle
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        trainSet;
        testSet;
    end
    
    properties (SetAccess = {?ModelTrainers.Base, ?Parameterized})
        performanceMeasure;
        maxDataSize;
    end
    
    %% --------------------------------------------------------------------
    methods
        
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
            if nargin < 2, getDatapointInfo = 'noInfo'; end
            verboseFprintf( obj, 'Applying model to test set...\n' );
            model = obj.getModel();
            model.verbose( obj.verbose );
            performance = Models.Base.getPerformance( ...
                model, obj.testSet, obj.performanceMeasure, ...
                obj.maxDataSize, true, getDatapointInfo );
        end
        %% ----------------------------------------------------------------

        function run( obj )
            [x,y] = obj.getPermutedTrainingData();
            nanXidxs = any( isnan( x ), 2 );
            infXidxs = any( isinf( x ), 2 );
            if any( nanXidxs ) || any( infXidxs ) 
                warning( 'There are NaNs or INFs in the data -- throwing those vectors away!' );
                x(nanXidxs | infXidxs,:) = [];
                y(nanXidxs | infXidxs,:) = [];
            end
            if numel( y ) > obj.maxDataSize
                if ModelTrainers.Base.balMaxData
                    throwoutIdxs = ModelTrainers.Base.getBalThrowoutIdxs( y, obj.maxDataSize );
                    x(throwoutIdxs,:) = [];
                    y(throwoutIdxs,:) = [];
                else
                    x(obj.maxDataSize+1:end,:) = [];
                    y(obj.maxDataSize+1:end,:) = [];
                end
            end
            obj.buildModel( x, y );
        end
        %% ----------------------------------------------------------------

        function [x,y] = getPermutedTrainingData( obj )
            x = obj.trainSet(:,'x');
            if isempty( x )
                warning( 'There is no data to train the model.' ); 
                y = [];
                return;
            else
                y = obj.trainSet(:,'y');
            end
            % apply the mask
            fmask = ModelTrainers.Base.featureMask;
            if ~isempty( fmask )
                p_feat = size( x, 2 );
                p_mask = size( ModelTrainers.Base.featureMask, 1 );
                fmask = fmask( 1 : min( p_feat, p_mask ) );
                x = x(:,fmask);
            end
            % permute data
            permutationIdxs = randperm( length( y ) );
            x = x(permutationIdxs,:);
            y = y(permutationIdxs,:);
        end
        %% ----------------------------------------------------------------

        
    end

    %% --------------------------------------------------------------------
    methods (Abstract)
        buildModel( obj, x, y )
    end

    %% --------------------------------------------------------------------
    methods (Abstract, Access = protected)
        model = giveTrainedModel( obj )
    end
    
    %% --------------------------------------------------------------------
    methods (Static)

        function throwoutIdxs = getBalThrowoutIdxs( y, maxDataSize )
            labels = unique( y );
            nPerLabel = arrayfun( @(l)(sum( l == y )), labels );
            [~, labelOrder] = sort( nPerLabel );
            nLabels = numel( labels );
            nRemaining = maxDataSize;
            throwoutIdxs = [];
            for ii = labelOrder'
                nKeep = min( int32( nRemaining/nLabels ), nPerLabel(ii) );
                nRemaining = nRemaining - nKeep;
                nLabels = nLabels - 1;
                lIdxs = find( y == labels(ii) );
                lIdxs = lIdxs(randperm(nPerLabel(ii)));
                throwoutIdxs = [throwoutIdxs; lIdxs(nKeep+1:end)];
            end
        end
    
        function b = balMaxData( setNewValue, newValue )
            persistent balMaxD;
            if isempty( balMaxD )
                balMaxD = false;
            end
            if nargin > 0  &&  setNewValue
                balMaxD = newValue;
            end
            b = balMaxD;
        end
        
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

