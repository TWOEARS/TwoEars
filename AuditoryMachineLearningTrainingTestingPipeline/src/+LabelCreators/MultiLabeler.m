classdef MultiLabeler < LabelCreators.Base
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        individualLabelers;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiLabeler( individualLabelers )
            obj = obj@LabelCreators.Base();
            obj.individualLabelers = individualLabelers;
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function [y,ysi] = label( obj, blockAnnotations )
            y = [];
            ysi = {};
            for ii = 1 : numel( obj.individualLabelers )
                obj.individualLabelers{ii}.labelBlockSize_s = obj.labelBlockSize_s;
                [yii,ysiii] = obj.individualLabelers{ii}.label( blockAnnotations );
                y = [y, yii]; %#ok<AGROW>
                ysi = [ysi, ysiii]; %#ok<AGROW>
            end
        end
        %% -------------------------------------------------------------------------------

        function outputDeps = getLabelInternOutputDependencies( obj )
            for ii = 1 : numel( obj.individualLabelers )
                outDepName = sprintf( 'labeler%d', ii );
                outputDeps.(outDepName) = ...
                              obj.individualLabelers{ii}.getLabelInternOutputDependencies;
            end
            outputDeps.v = 2;
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end
