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
            outputDeps.v = 1;
        end
        %% -------------------------------------------------------------------------------

        function y = label( obj, blockAnnotations )
            pointSrcIdxs = ~isnan( blockAnnotations.srcAzms ) ;
            srcsBlockEnergies = cellfun( @mean, blockAnnotations.srcEnergy(pointSrcIdxs) );
            y = sum( srcsBlockEnergies > obj.srcMinEnergy );
        end
        %% -------------------------------------------------------------------------------
                
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

