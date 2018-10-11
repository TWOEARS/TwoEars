classdef IdAzmDistributionLabeler < LabelCreators.MultiEventTypeLabeler
    % class for labeling blocks by azimuth distributions for a specified set of
    % types
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        angularResolution;
        nAzimuthBins;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        function obj = IdAzmDistributionLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.addOptional( 'angularResolution', 5 );
            % MultiEventTypeLabeler parameters
            ip.addOptional( 'types', {{'Type1'},{'Type2'}} );
            ip.addOptional( 'minBlockToEventRatio', 0.75 );
            ip.addOptional( 'maxNegBlockToEventRatio', 0 );
            ip.addOptional( 'sourcesMinEnergy', -20 );
            ip.parse( varargin{:} );
            obj@LabelCreators.MultiEventTypeLabeler( ...
                                      'labelBlockSize_s', ip.Results.labelBlockSize_s, ...
                                      'minBlockToEventRatio', ip.Results.minBlockToEventRatio, ...
                                      'maxNegBlockToEventRatio', ip.Results.maxNegBlockToEventRatio, ...
                                      'types', ip.Results.types, ...
                                      'sourcesMinEnergy', ip.Results.sourcesMinEnergy);
            obj.angularResolution = ip.Results.angularResolution;
            obj.nAzimuthBins = 360 / obj.angularResolution;
        end
        
        %% -------------------------------------------------------------------------------
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function [y,ysi] = label( obj, blockAnnotations )
            [activeTypes, ~, activeSrcIdxs] = getActiveTypes( obj, blockAnnotations );
            if ~isempty(obj.nrgSrcsFilter)
                srcAzms = blockAnnotations.srcAzms(obj.nrgSrcsFilter, :);
                srcAzmIdxs = LabelCreators.AzmDistributionLabeler.azimToIndex( srcAzms, ...
                    obj.angularResolution, obj.nAzimuthBins );
            else
                srcAzmIdxs = LabelCreators.AzmDistributionLabeler.azimToIndex( blockAnnotations.srcAzms, ...
                    obj.angularResolution, obj.nAzimuthBins );
            end
            % initialize output
            y = zeros( numel(obj.types), obj.nAzimuthBins+1 );
            y(:, end) = ~activeTypes'; % set void bin to inverse of active types
            % mark azimuths of active types for each source
            for activeTypeIdx = find(activeTypes)
                activeSrcs = activeSrcIdxs{activeTypeIdx};
                % no azimuth for diffuse sounds
                if ~isnan(srcAzmIdxs(activeSrcs))
                    y(activeTypeIdx, srcAzmIdxs(activeSrcs)) = 1;
                end
            end
            y = reshape(y, 1, numel(obj.types) * (obj.nAzimuthBins + 1));
            ysi = {};
        end
        
        %% -----------------------------------------------------------------------------------
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps = getLabelInternOutputDependencies@LabelCreators.MultiEventTypeLabeler(obj);
            outputDeps.nAzimuthBins = obj.nAzimuthBins;
            outputDeps.angularResolution = obj.angularResolution;
            outputDeps.v = 3;
        end
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

