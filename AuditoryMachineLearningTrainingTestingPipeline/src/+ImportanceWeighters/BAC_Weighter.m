classdef BAC_Weighter < ImportanceWeighters.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        labelWeights;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = BAC_Weighter( labelWeights )
            obj = obj@ImportanceWeighters.Base();
            if nargin >= 1
                obj.labelWeights = labelWeights;
            end
        end
        % -----------------------------------------------------------------
    
        function [importanceWeights] = getImportanceWeights( obj, sampleIds )
            importanceWeights = ones( size( sampleIds ) );
            y = obj.data(:,'y');
            y = y(sampleIds,:);
            for cc = 1 : size( y, 2 )
                labels = unique( y(:,cc) );
                lw = obj.labelWeights;
                if isempty( lw )
                    lw = ones( size( labels ) );
                elseif numel( lw ) ~= numel( labels )
                    error( 'AMLTTP:usage', 'number of label weights must equal number of unique labels' );
                end
                for ii = 1 : numel( labels )
                    y_label_ii = y(:,cc) == labels(ii);
                    labelWeight(ii) = lw(ii) * numel( sampleIds ) / sum( y_label_ii ); %#ok<AGROW>
                    importanceWeights(y_label_ii,cc) = labelWeight(ii);
                end
            end
            importanceWeights = mean( importanceWeights, 2 );
            importanceWeights = importanceWeights / min( importanceWeights );
            obj.verboseOutput = '\nWeighting samples of \n';
            for ii = 1 : numel( labels )
                obj.verboseOutput = sprintf( ['%s' ...
                                              '  class %d with %f\n'], ...
                                             obj.verboseOutput, ...
                                             labels(ii), labelWeight(ii) );
            end
        end
        % -----------------------------------------------------------------

    end

end

