classdef (Abstract) DataScalingModel < models.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        dataTranslators;
        dataScalors;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = DataScalingModel()
            obj.dataTranslators = 0;
            obj.dataScalors = 1;
        end
        %% -----------------------------------------------------------------
        
        function x = scale2zeroMeanUnitVar( obj, x, saveScalingFactors )
            if isempty( x ), return; end;
            if nargin > 2 && strcmp( saveScalingFactors, 'saveScalingFactors' )
                obj.dataTranslators = mean( x );
                obj.dataScalors = 1 ./ std( x );
            end
            x = x - repmat( obj.dataTranslators, size(x,1), 1 );
            x = x .* repmat( obj.dataScalors, size(x,1), 1 );
        end
        %% -----------------------------------------------------------------
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
            
        function [y,score] = applyModelMasked( obj, x )
            x = obj.scale2zeroMeanUnitVar( x );
            [y, score] = obj.applyModelToScaledData( x );
        end
        %% -----------------------------------------------------------------
    end

    %% --------------------------------------------------------------------
    methods (Abstract, Access = protected)
        [y,score] = applyModelToScaledData( obj, x );
    end
    
end

