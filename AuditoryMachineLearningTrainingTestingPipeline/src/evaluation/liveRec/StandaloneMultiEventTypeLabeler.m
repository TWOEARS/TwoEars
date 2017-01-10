classdef StandaloneMultiEventTypeLabeler < LabelCreators.MultiEventTypeLabeler
    % class for multi-class labeling blocks by event
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = StandaloneMultiEventTypeLabeler( varargin )
            obj = obj@LabelCreators.MultiEventTypeLabeler( varargin{:} );
        end
        
        %% -------------------------------------------------------------------------------
        function y = labelBlock( obj, blockAnnotations )
            [activeTypes, relBlockEventOverlap, ~] = obj.getActiveTypes( blockAnnotations );
            y = single(activeTypes);
            if strcmp( obj.negOut, 'rest' )
                y(~activeTypes & relBlockEventOverlap > obj.maxNegBlockToEventRatio) = NaN;
            end
        end
    end
    %% -----------------------------------------------------------------------------------
end