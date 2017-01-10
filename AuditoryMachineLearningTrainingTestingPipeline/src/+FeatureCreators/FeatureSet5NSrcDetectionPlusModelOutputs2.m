classdef FeatureSet5NSrcDetectionPlusModelOutputs2 < FeatureCreators.Base
% FeatureSetNSrcDetectionPlusModelOutputs
%
% class that attaches localisation knowledge source output to the afe-features
%

    properties (SetAccess = private)
        baseFC;
        numOrdinaryAFErequests;
    end
    
    methods (Static)
    end
    
    methods (Access = public)
        
        function obj = FeatureSet5NSrcDetectionPlusModelOutputs2( )
            obj = obj@FeatureCreators.Base();
            obj.baseFC = FeatureCreators.FeatureSet5NSrcDetection();
        end
    
        function afeRequests = getAFErequests( obj )
            afeRequests = obj.baseFC.getAFErequests();
            obj.numOrdinaryAFErequests = numel( afeRequests );
        end

        function x = constructVector( obj )
            % emulate super call by delegation
            obj.baseFC.descriptionBuilt = obj.descriptionBuilt;
            obj.baseFC.setAfeData( obj.afeData );
            x = obj.baseFC.constructVector();
            if ~obj.baseFC.descriptionBuilt
                obj.baseFC.description = x{2};
                obj.baseFC.descriptionBuilt = true;
            end
            % additional features from the injected KS (azimut distribution)
            % due to median plane symmetric confusion, we fuse the backward-field
            % probabilities into their respective forward-field probabilities.
            % Azimuts will range from 270 degree on the left, over 0 degree front
            % to 90 degree right.
            azmDist = obj.makeBlockFromAfe( obj.numOrdinaryAFErequests+1, 1, ...
                @(a)(a.Data), ...
                {@(a)(a.Name), @(a)([num2str(numel(a.azms)) '-azms'])}, ...
                {'prob'},...
                {@(a)(strcat('azm_', arrayfun(@(az)(num2str(az)), a.azms, 'UniformOutput', false)))} );
            azmDist = obj.reshape2featVec( azmDist );
            azmDist_summ = obj.baseFC.makePeakSummaryFeatureBlock(...
                azmDist{1},...
                ~obj.descriptionBuilt,...
                10,4);
            azmDist_summ = obj.reshape2featVec(azmDist_summ);
            x = obj.concatFeats(x, azmDist_summ);
            idDist = obj.makeBlockFromAfe( obj.numOrdinaryAFErequests+2, 1, ...
                @(a)(a.Data), ...
                {@(a)(a.Name)}, ...
                {'prob'},...
                {@(a)(a.Types)} );
            idf = obj.reshape2featVec( idDist );
            x = obj.concatFeats( x, idf );
        end
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.baseFCdeps = obj.baseFC.getFeatureInternOutputDependencies();
            % classname
            classInfo = metaclass( obj );
            classnames = strsplit( classInfo.Name, '.' );
            outputDeps.featureProc = classnames{end};
            % version
            outputDeps.v = 6;
        end
        
    end
    
    methods (Access = protected)
    end
    
end

