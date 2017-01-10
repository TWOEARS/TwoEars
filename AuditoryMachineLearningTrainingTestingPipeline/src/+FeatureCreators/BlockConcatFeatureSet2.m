classdef BlockConcatFeatureSet2 < FeatureCreators.Base

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        freqChannels;
        freqChannelsStatistics;
        amFreqChannels;
        deltasLevels;
        amChannels;
        nConcatBlocks;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = BlockConcatFeatureSet2( )
            obj = obj@FeatureCreators.Base( 0.48, 0.24, 0.5, 0.48 );
            obj.freqChannels = 16;
            obj.amFreqChannels = 8;
            obj.freqChannelsStatistics = 32;
            obj.deltasLevels = 1;
            obj.amChannels = 4;
            obj.nConcatBlocks = 2;
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
                'ams_highFreqHz', 256' ...
                );
            afeRequests{2}.name = 'ratemap';
            afeRequests{2}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'rm_scaling', 'magnitude', ...
                'fb_nChannels', obj.freqChannels ...
                );
            afeRequests{3}.name = 'onsetStrength';
            afeRequests{3}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'fb_nChannels', obj.freqChannels ...
                );
            afeRequests{4}.name = 'spectralFeatures';
            afeRequests{4}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'fb_nChannels', obj.freqChannelsStatistics ...
                );
        end
        %% ----------------------------------------------------------------

        function x = makeDataPoint( obj, afeData )
            rmRL = afeData(2);
            rmR = compressAndScale( rmRL{1}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            rmL = compressAndScale( rmRL{2}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            rm = 0.5 * rmR + 0.5 * rmL;
            spfRL = afeData(4);
            spfR = compressAndScale( spfRL{1}.Data, 0.33 );
            spfL = compressAndScale( spfRL{2}.Data, 0.33 );
            spf = 0.5 * spfL + 0.5 * spfR;
            onsRL = afeData(3);
            onsR = compressAndScale( onsRL{1}.Data, 0.33 );
            onsL = compressAndScale( onsRL{2}.Data, 0.33 );
            ons = 0.5 * onsR + 0.5 * onsL;
            modRL = afeData(1);
            modR = compressAndScale( modRL{1}.Data, 0.33 );
            modL = compressAndScale( modRL{2}.Data, 0.33 );
            md = 0.5 * modR + 0.5 * modL;
            md = reshape( md, size( md, 1 ), size( md, 2 ) * size( md, 3 ) );
            mdn = zeros( size( md, 1 ), 0 );
            for ii = 1 : obj.nConcatBlocks
                mdn = [mdn md(:,ii:obj.nConcatBlocks:end)];
            end
            md = mdn;
            xBlock = [rm, spf, ons];
            nDividableXLen = size( xBlock, 1 ) - mod( size( xBlock, 1 ), obj.nConcatBlocks );
            concatBlockLen = nDividableXLen / obj.nConcatBlocks;
            xBlock = reshape( xBlock(end-nDividableXLen+1:end,:), concatBlockLen, size( xBlock, 2 ) * obj.nConcatBlocks );
            xbn = zeros( size( xBlock, 1 ), 0 );
            for ii = 1 : obj.nConcatBlocks
                xbn = [xbn xBlock(:,ii:obj.nConcatBlocks:end)];
            end
            xBlock = xbn;
            x = lMomentAlongDim( xBlock, [1,2,3,4], 1, true );
            for ii = 1:obj.deltasLevels
                xBlock = xBlock(2:end,:) - xBlock(1:end-1,:);
                x = [x  lMomentAlongDim( xBlock, [1,2,3,4], 1, true )];
            end
            lenOneBlock = length( x ) / obj.nConcatBlocks;
            for ii = 2 : obj.nConcatBlocks
                x = [x, x((ii-1)*lenOneBlock+1:ii*lenOneBlock) - x((ii-2)*lenOneBlock+1:(ii-1)*lenOneBlock)];
            end
            nDividableXLen = size( md, 1 ) - mod( size( md, 1 ), obj.nConcatBlocks );
            concatBlockLen = nDividableXLen / obj.nConcatBlocks;
            md = reshape( md(end-nDividableXLen+1:end,:), concatBlockLen, size( md, 2 ) * obj.nConcatBlocks );
            xm = lMomentAlongDim( md, [1,2,3,4], 1, true );
            for ii = 1:obj.deltasLevels
                md = md(2:end,:) - md(1:end-1,:);
                xm = [xm  lMomentAlongDim( md, [1,2,3,4], 1, true )];
            end
            lenOneBlock = length( xm ) / obj.nConcatBlocks;
            for ii = 2 : obj.nConcatBlocks
                xm = [xm, xm((ii-1)*lenOneBlock+1:ii*lenOneBlock) - xm((ii-2)*lenOneBlock+1:(ii-1)*lenOneBlock)];
            end
            x = [x xm];
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.nConcatBlocks = obj.nConcatBlocks;
            outputDeps.freqChannels = obj.freqChannels;
            outputDeps.amFreqChannels = obj.amFreqChannels;
            outputDeps.freqChannelsStatistics = obj.freqChannelsStatistics;
            outputDeps.amChannels = obj.amChannels;
            outputDeps.deltasLevels = obj.deltasLevels;
            classInfo = metaclass( obj );
            [classname1, classname2] = strtok( classInfo.Name, '.' );
            if isempty( classname2 ), outputDeps.featureProc = classname1;
            else outputDeps.featureProc = classname2(2:end); end
            outputDeps.v = 2;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

