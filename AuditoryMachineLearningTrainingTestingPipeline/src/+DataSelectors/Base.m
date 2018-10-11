classdef (Abstract) Base < handle
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        data;
        verboseOutput = '';
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = connectData( obj, data )
            obj.data = data;
        end
        % -----------------------------------------------------------------
        
        function d = getData( obj, dataField )
            if isa( obj.data, 'Core.IdentTrainPipeData' )
                d = obj.data(:,dataField);
            elseif isstruct( obj.data ) && isfield( obj.data, dataField )
                d = obj.data.(dataField);
            else
                error( 'AMLTTP:ApiUsage', 'improper usage of DataSelectors API' );
            end
        end
        % -----------------------------------------------------------------
        
    end

    %% --------------------------------------------------------------------
    methods (Abstract)
        [selectFilter] = getDataSelection( obj, sampleIdsIn, maxDataSize )
    end
    
end

