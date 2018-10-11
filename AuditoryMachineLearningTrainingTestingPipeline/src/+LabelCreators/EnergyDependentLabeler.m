classdef EnergyDependentLabeler < LabelCreators.Base
    % abstract class for labeling blocks that exhibit enough energy in specified sources
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        sourcesMinEnergy;
        sourceIds;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        [y, ysi] = labelEnergeticBlock( obj, blockAnnotations )
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = EnergyDependentLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'sourcesMinEnergy', -20 );
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.addOptional( 'sourceIds', 1 );
            ip.parse( varargin{:} );
            obj = obj@LabelCreators.Base( 'labelBlockSize_s', ip.Results.labelBlockSize_s );
            obj.sourcesMinEnergy = ip.Results.sourcesMinEnergy;
            obj.sourceIds = ip.Results.sourceIds;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps = getInternOutputDependencies@LabelCreators.Base( obj );
            outputDeps.sourcesMinEnergy = obj.sourcesMinEnergy;
            outputDeps.sourceIds = obj.sourceIds;
            outputDeps.v = 2;
        end
        %% -------------------------------------------------------------------------------

        function [y, ysi] = label( obj, blockAnnotations )
            rejectBlock = LabelCreators.EnergyDependentLabeler.isEnergyTooLow( ...
                                  blockAnnotations, obj.sourceIds, obj.sourcesMinEnergy );
            if rejectBlock
                y = NaN;
                ysi = {};
            else
                [y, ysi] = obj.labelEnergeticBlock( blockAnnotations );
            end
        end
        %% -------------------------------------------------------------------------------
                
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
        function eTooLow = isEnergyTooLow( blockAnnots, sourceIds, sourcesMinEnergy )
            sourceIds(sourceIds > size( blockAnnots.srcEnergy, 2 )) = [];
            eAvgOverChannels = cellfun( @mean, blockAnnots.srcEnergy(:,sourceIds) );
            eTooLow = sum( log( sourcesMinEnergy ./ eAvgOverChannels ) ) < 0;
        end
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

