classdef (Abstract) IdModelInterface < handle
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
    end
    
    %% --------------------------------------------------------------------
    methods
        
        % -----------------------------------------------------------------
        
    end

    %% --------------------------------------------------------------------
    methods (Abstract)
        [y,score] = applyModel( obj, x )
    end

    %% --------------------------------------------------------------------
    methods (Static)
        
        function perf = getPerformance( model, testSet, positiveClass, perfMeasure )
            if isempty( testSet )
                warning( 'There is no testset to test on.' ); 
                perf = 0;
                return;
            end
            x = testSet(:,:,'x');
            yTrue = testSet(:,:,'y',positiveClass);
            if isempty( x ), error( 'There is no data to test the model.' ); end
            yModel = model.applyModel( x );
            for ii = 1 : size( yModel, 2 )
                perf(ii) = perfMeasure( yTrue, yModel(:,ii) );
            end
        end
        %% ----------------------------------------------------------------
    
    end
    
end

