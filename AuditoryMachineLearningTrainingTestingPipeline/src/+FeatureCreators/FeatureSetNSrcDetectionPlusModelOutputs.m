classdef FeatureSetNSrcDetectionPlusModelOutputs < FeatureCreators.Base
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
        
        function obj = FeatureSetNSrcDetectionPlusModelOutputs( )
            obj = obj@FeatureCreators.Base();
            obj.baseFC = FeatureCreators.FeatureSetNSrcDetection();
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
            % propabilities into their respective forward-field propabilities.
            % Azimuts will range from 270 degree on the left, over 0 degree front
            % to 90 degree right.
            azmDist = obj.makeBlockFromAfe( obj.numOrdinaryAFErequests+1, 1, ...
                @(a)(sum([a.Data(1:1+numel(a.Data)/2);[a.Data(1) a.Data(end:-1:1+numel(a.Data)/2)]],1)), ...
                {@(a)([a.Name '-fused']), @(a)([num2str(1+numel(a.azms)/2) '-azms'])}, ...
                {'prop'},...
                {@(a)(strcat('azm_', arrayfun(@(az)(num2str(az)), a.azms(1:1+numel(a.azms)/2), 'UniformOutput', false)))} );
            azmDist = obj.reshape2featVec( azmDist );
            azmDist_summ = obj.baseFC.makePeakSummaryFeatureBlock(...
                azmDist{1},...
                ~obj.descriptionBuilt,...
                7,4);
            azmDist_summ = obj.reshape2featVec(azmDist_summ);
            x = obj.concatFeats(x, azmDist_summ);
        end
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.baseFCdeps = obj.baseFC.getFeatureInternOutputDependencies();
            % classname
            classInfo = metaclass( obj );
            classnames = strsplit( classInfo.Name, '.' );
            outputDeps.featureProc = classnames{end};
            % version
            outputDeps.v = 5;
        end
        
    end
    
    methods (Access = protected)
    end
    
end

