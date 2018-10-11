classdef NumberOfSourcesLabeler < LabelCreators.Base
    % class for labeling number of sources in block
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        srcMinEnergy;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = NumberOfSourcesLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.addOptional( 'srcMinEnergy', -30 );
            ip.parse( varargin{:} );
            obj = obj@LabelCreators.Base( 'labelBlockSize_s', ip.Results.labelBlockSize_s );
            obj.srcMinEnergy = ip.Results.srcMinEnergy;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.srcMinEnergy = obj.srcMinEnergy;
            outputDeps.v = 2;
        end
        %% -------------------------------------------------------------------------------

        function [y,ysi] = label( obj, blockAnnotations )
            pointSrcIdxs = ~isnan( blockAnnotations.srcAzms ) ;
            srcsBlockEnergies = cellfun( @mean, blockAnnotations.globalSrcEnergy(pointSrcIdxs) );
            activeSources = srcsBlockEnergies > obj.srcMinEnergy;
            y = sum( activeSources );
            ysi = {find( activeSources )};
        end
        %% -------------------------------------------------------------------------------
                
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

