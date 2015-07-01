classdef BlockConcatFeatureSet2 < FeatureProcInterface

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
            obj = obj@FeatureProcInterface( 0.48 );
            obj.freqChannels = 16;
            obj.amFreqChannels = 8;
            obj.freqChannelsStatistics = 32;
            obj.deltasLevels = 1;
            obj.amChannels = 4;
            obj.nConcatBlocks = 2;
        end
        %% ----------------------------------------------------------------

        function afeRequests = getAFErequests( obj )
            afeRequests{1}.name = 'modulation';
            afeRequests{1}.params = genParStruct( ...
                'nChannels', obj.amFreqChannels, ...
                'am_type', 'filter', ...
                'am_nFilters', obj.amChannels ...
                );
            afeRequests{2}.name = 'ratemap_magnitude';
            afeRequests{2}.params = genParStruct( ...
                'nChannels', obj.freqChannels ...
                );
            afeRequests{3}.name = 'spec_features';
            afeRequests{3}.params = genParStruct( ...
                'nChannels', obj.freqChannelsStatistics ...
                );
            afeRequests{4}.name = 'onset_strength';
            afeRequests{4}.params = genParStruct( ...
                'nChannels', obj.freqChannels ...
                );
        end
        %% ----------------------------------------------------------------

        function x = makeDataPoint( obj, afeData )
            rmRL = afeData('ratemap_magnitude');
            rmR = compressAndScale( rmRL{1}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            rmL = compressAndScale( rmRL{2}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            rm = 0.5 * rmR + 0.5 * rmL;
            spfRL = afeData('spec_features');
            spfR = compressAndScale( spfRL{1}.Data, 0.33, @(x)(median( abs(x(abs(x)>0.01)) )), 1 );
            spfL = compressAndScale( spfRL{2}.Data, 0.33, @(x)(median( abs(x(abs(x)>0.01)) )), 1 );
            spf = 0.5 * spfL + 0.5 * spfR;
            onsRL = afeData('onset_strength');
            onsR = compressAndScale( onsRL{1}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            onsL = compressAndScale( onsRL{2}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            ons = 0.5 * onsR + 0.5 * onsL;
            modRL = afeData('modulation');
            modR = compressAndScale( modRL{1}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            modL = compressAndScale( modRL{2}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
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
            x = lMomentAlongDim( xBlock, [1,2,3,4], 1 );
            for ii = 1:obj.deltasLevels
                xBlock = xBlock(2:end,:) - xBlock(1:end-1,:);
                x = [x  lMomentAlongDim( xBlock, [1,2,3,4], 1 )];
            end
            lenOneBlock = length( x ) / obj.nConcatBlocks;
            for ii = 2 : obj.nConcatBlocks
                x = [x, x((ii-1)*lenOneBlock+1:ii*lenOneBlock) - x((ii-2)*lenOneBlock+1:(ii-1)*lenOneBlock)];
            end
            nDividableXLen = size( md, 1 ) - mod( size( md, 1 ), obj.nConcatBlocks );
            concatBlockLen = nDividableXLen / obj.nConcatBlocks;
            md = reshape( md(end-nDividableXLen+1:end,:), concatBlockLen, size( md, 2 ) * obj.nConcatBlocks );
            xm = lMomentAlongDim( md, [1,2,3,4], 1 );
            for ii = 1:obj.deltasLevels
                md = md(2:end,:) - md(1:end-1,:);
                xm = [xm  lMomentAlongDim( md, [1,2,3,4], 1 )];
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
            classname = classInfo.Name;
            outputDeps.featureProc = classname;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

