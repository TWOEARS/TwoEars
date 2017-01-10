classdef AzmDistributionLabeler < LabelCreators.EnergyDependentLabeler
    % class for labeling blocks by azm of a specified source
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        angularResolution;
        nAngles;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = AzmDistributionLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'angularResolution', 15 );
            ip.addOptional( 'sourcesMinEnergy', -20 );
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.addOptional( 'sourceIds', ':' );
            ip.parse( varargin{:} );
            obj = obj@LabelCreators.EnergyDependentLabeler( ...
                                      'labelBlockSize_s', ip.Results.labelBlockSize_s, ...
                                      'sourcesMinEnergy', ip.Results.sourcesMinEnergy, ...
                                      'sourceIds', ip.Results.sourceIds );
            obj.angularResolution = ip.Results.angularResolution;
            obj.nAngles = 360 / obj.angularResolution;
            if rem( obj.nAngles, 1 ) ~= 0
                error( 'Choose a divisor of 360 as angularResolution.' );
            end
        end
        %% -------------------------------------------------------------------------------
        
        function y = labelEnergeticBlock( obj, blockAnnotations )
            srcAzms = blockAnnotations.srcAzms(obj.sourceIds,:);
            srcAzmIdxs = LabelCreators.AzmDistributionLabeler.azimToIndex( ...
                            srcAzms, obj.angularResolution, obj.nAngles );
            y = zeros( 1, obj.nAngles );
            y(srcAzmIdxs) = 1;
        end
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        %% -----------------------------------------------------------------------------------
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.angularResolution = obj.angularResolution;
            outputDeps.v = 1;
        end   
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        function azmIdxs = azimToIndex(azimuths, angularResolution, nAngles )
            % Determine Azimuth bin index from azimuth angle(s)
            if nargin < 3
                nAngles = 360 / angularResolution;
            end
            azmIdxs = mod( round( azimuths / angularResolution ), nAngles ) + 1;
        end
    end
    
end

        

