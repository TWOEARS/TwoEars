classdef RatemapPlusDeltasBlockmean < FeatureCreators.Base
% uses magnitude ratemap with cubic compression and scaling to a max value
% of one. Reduces each freq channel to its mean and std + mean and std of
% finite differences.

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        freqChannels;
        deltasLevels;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = RatemapPlusDeltasBlockmean()
            obj = obj@FeatureCreators.Base( 0.5, 0.5/3, 0.5, 0.5 );
            obj.freqChannels = 16;
            obj.deltasLevels = 1;
        end
        %% ----------------------------------------------------------------

        function afeRequests = getAFErequests( obj )
            afeRequests{1}.name = 'ratemap';
            afeRequests{1}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'rm_scaling', 'magnitude', ...
                'fb_nChannels', obj.freqChannels ...
                );
        end
        %% ----------------------------------------------------------------

        function x = makeDataPoint( obj, afeData )
            rmRL = afeData(1);
            rmR = compressAndScale( rmRL{1}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            rmL = compressAndScale( rmRL{2}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            rm = 0.5 * rmR + 0.5 * rmL;
            x = [mean( rm, 1 )  std( rm, 0, 1 )];
            for i = 1:obj.deltasLevels
                rm = rm(2:end,:) - rm(1:end-1,:);
                x = [x  mean( rm, 1 )  std( rm, 0, 1 )];
            end
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.freqChannels = obj.freqChannels;
            outputDeps.deltasLevels = obj.deltasLevels;
            classInfo = metaclass( obj );
            [classname1, classname2] = strtok( classInfo.Name, '.' );
            if isempty( classname2 ), outputDeps.featureProc = classname1;
            else outputDeps.featureProc = classname2(2:end); end
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

