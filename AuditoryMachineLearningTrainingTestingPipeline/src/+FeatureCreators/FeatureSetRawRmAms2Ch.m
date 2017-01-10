classdef FeatureSetRawRmAms2Ch < FeatureCreators.Base
% FeatureSetRawRmAms2Ch Specifies a feature set consisting of:
%   see FeatureSetRawRmAms2Ch.getAFErequests()
%   uses magnitude ratemap with cubic compression and scaling to a max value
% of one. Binaural channels are kept separated.

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        freqChannels;   % no. of frequency bins for rate maps
        amFreqChannels; % no. of frequency bins for amsFeatures
        amChannels;     % no. of modulation frequencies
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FeatureSetRawRmAms2Ch( )
            obj = obj@FeatureCreators.Base();
            obj.freqChannels = 16;
            obj.amFreqChannels = 8;
            obj.amChannels = 9;
        end
        %% ----------------------------------------------------------------

        function afeRequests = getAFErequests( obj )
            afeRequests{1}.name = 'amsFeatures';
            afeRequests{1}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'fb_nChannels', obj.amFreqChannels, ...
                'ams_fbType', 'log', ...
                'ams_nFilters', obj.amChannels, ...
                'ams_lowFreqHz', 1, ...
                'ams_highFreqHz', 256 ...
                );
            afeRequests{2}.name = 'ratemap';
            afeRequests{2}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'rm_scaling', 'magnitude', ...
                'fb_nChannels', obj.freqChannels ...
                );
        end
        %% ----------------------------------------------------------------

        function x = constructVector( obj )
            % constructVector for each feature: compress, scale, keep
            %   over left and right channels separate, construct individual feature names
            %   returned flattened feature vector for entire block
            %   The AFE data is indexed according to the order in which the requests
            %   where made in the getAFErequests() method
            % 
            %   See getAFErequests
            
            % afeIdx 2: ratemap
            % first the left, then the right channel
            rmL = obj.makeBlockFromAfe( 2, 1, ...
                @(a)(compressAndScale( a.Data, 0.33, @(x)(median( x(x>0.01) )), 0 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            x = obj.reshape2featVec( rmL );
            rmR = obj.makeBlockFromAfe( 2, 2, ...
                @(a)(compressAndScale( a.Data, 0.33, @(x)(median( x(x>0.01) )), 0 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)},...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))},...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            x = obj.concatFeats( x, obj.reshape2featVec( rmR ) );
            % afeIdx 1: amsFeatures and generate corresponding feature names
            % first the left, then the right channel
            modL = obj.makeBlockFromAfe( 1, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))},...
                {@(a)(strcat('mf', arrayfun(@(f)(num2str(f)),a.modCfHz,'UniformOutput',false)))} );
            mod = obj.reshapeBlock( modL, 1 );
            x = obj.concatFeats( x, obj.reshape2featVec( mod ) );
            modR = obj.makeBlockFromAfe( 1, 2, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))},...
                {@(a)(strcat('mf', arrayfun(@(f)(num2str(f)),a.modCfHz,'UniformOutput',false)))} );
            mod = obj.reshapeBlock( modR, 1 );
            x = obj.concatFeats( x, obj.reshape2featVec( mod ) );
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.freqChannels = obj.freqChannels;
            outputDeps.amFreqChannels = obj.amFreqChannels;
            outputDeps.amChannels = obj.amChannels;
            classInfo = metaclass( obj );
            [classname1, classname2] = strtok( classInfo.Name, '.' );
            if isempty( classname2 ), outputDeps.featureProc = classname1;
            else outputDeps.featureProc = classname2(2:end); end
            outputDeps.v = 3;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

