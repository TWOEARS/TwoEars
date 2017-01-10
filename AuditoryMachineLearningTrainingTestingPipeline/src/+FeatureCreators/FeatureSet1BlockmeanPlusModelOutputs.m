classdef FeatureSet1BlockmeanPlusModelOutputs < FeatureCreators.Base
% FeatureSet1BlockmeanPlusModelOutputs 
%

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        baseFS1creator;
        numOrdinaryAFErequests;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FeatureSet1BlockmeanPlusModelOutputs( )
            obj = obj@FeatureCreators.Base();
            obj.baseFS1creator = FeatureCreators.FeatureSet1Blockmean();
        end
        %% ----------------------------------------------------------------

        function afeRequests = getAFErequests( obj )
            afeRequests = obj.baseFS1creator.getAFErequests();
            obj.numOrdinaryAFErequests = numel( afeRequests );
        end
        %% ----------------------------------------------------------------

        function x = constructVector( obj )
            obj.baseFS1creator.setAfeData( obj.afeData );
            x = obj.baseFS1creator.constructVector();
            if ~obj.baseFS1creator.descriptionBuilt
                obj.baseFS1creator.description = x{2};
                obj.baseFS1creator.descriptionBuilt = true;
            end
            dnnLocFeatures = obj.makeBlockFromAfe( obj.numOrdinaryAFErequests+1, 1, ...
                @(a)(a.Data), ...
                {@(a)(a.Name), @(a)([num2str(numel(a.azms)) '-azms'])}, ...
                {'prob'}, ...
                {@(a)(strcat('azm_', arrayfun(@(az)(num2str(az)), a.azms, 'UniformOutput', false)))} );
            xDnnLoc = obj.block2feat( dnnLocFeatures, ...
                @(b)( mean( b ) ), ...
                1, @(idxs)( idxs ),...
                {{'locDistrMean', @(idxs)(idxs)}}  );
            x = obj.concatFeats( x, xDnnLoc );
            xDnnLoc = obj.block2feat( dnnLocFeatures, ...
                @(b)( sum( b > mean( b ) ) ), ...
                1, @(idxs)( idxs ),...
                {{'peaksAboveMean', @(idxs)(idxs)}}  );
            x = obj.concatFeats( x, xDnnLoc );
            xDnnLoc = obj.block2feat( dnnLocFeatures, ...
                @(b)( b ), ...
                2, @(idxs)( idxs ),...
                {{'locDistr', @(idxs)(idxs)}}  );
            x = obj.concatFeats( x, xDnnLoc );
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.baseFS1deps = obj.baseFS1creator.getFeatureInternOutputDependencies();
            classInfo = metaclass( obj );
            [classname1, classname2] = strtok( classInfo.Name, '.' );
            if isempty( classname2 ), outputDeps.featureProc = classname1;
            else outputDeps.featureProc = classname2(2:end); end
            outputDeps.v = 1;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

