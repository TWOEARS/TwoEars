classdef (Abstract) Base < handle
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?modelTrainers.Base})
        featureMask = [];
    end
    
    %% --------------------------------------------------------------------
    methods

        function [y,score] = applyModel( obj, x )
            if ~isempty( obj.featureMask )
                p_feat = size( x, 2 );
                p_mask = size( obj.featureMask, 1 );
                fmask = obj.featureMask( 1 : min( p_feat, p_mask ) );
                x = x(:,fmask);
            end
            verboseFprintf( obj, 'Testing, \tsize(x) = %dx%d\n', size(x,1), size(x,2) );
            [y,score] = obj.applyModelMasked( x );
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

    end

    %% --------------------------------------------------------------------
    methods (Abstract, Access = protected)
        [y,score] = applyModelMasked( obj, x )
    end

    %% --------------------------------------------------------------------
    methods (Static)
        
        function perf = getPerformance( model, testSet, positiveClass, perfMeasure, maxDataSize, balMaxData )
            if isempty( testSet )
                warning( 'There is no testset to test on.' ); 
                perf = 0;
                return;
            end
            if nargin < 5, maxDataSize = inf; end
            if nargin < 6, balMaxData = false; end
            x = testSet(:,:,'x');
            yTrue = testSet(:,:,'y',positiveClass);
            if numel( yTrue ) > maxDataSize
                if balMaxData
                    nPos = min( int32( maxDataSize/2 ), sum( yTrue == +1 ) );
                    nNeg = maxDataSize - nPos;
                    posIdxs = find( yTrue == +1 );
                    posIdxs = posIdxs(randperm(numel(posIdxs)));
                    posIdxs(1:nPos) = [];
                    negIdxs = find( yTrue == -1 );
                    negIdxs = negIdxs(randperm(numel(negIdxs)));
                    negIdxs(1:nNeg) = [];
                    x([posIdxs; negIdxs],:) = [];
                    yTrue([posIdxs; negIdxs]) = [];
                else
                    x(maxDataSize+1:end,:) = [];
                    yTrue(maxDataSize+1:end) = [];
                end
            end
            if isempty( x ), error( 'There is no data to test the model.' ); end
            yModel = model.applyModel( x );
            for ii = 1 : size( yModel, 2 )
                perf(ii) = perfMeasure( yTrue, yModel(:,ii) );
            end
        end
        %% ----------------------------------------------------------------
    
    end
    
end

