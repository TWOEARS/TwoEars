classdef BlockConcatFeatureSet1a < featureCreators.Base

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        freqChannels;
        nConcatBlocks;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = BlockConcatFeatureSet1a( )
            obj = obj@featureCreators.Base( 0.48, 0.24, 0.5, 0.48 );
            obj.freqChannels = 16;
            obj.nConcatBlocks = 4;
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
            nDividableRmLen = size( rm, 1 ) - mod( size( rm, 1 ), obj.nConcatBlocks );
            concatBlockLen = nDividableRmLen / obj.nConcatBlocks;
            rm = reshape( rm(end-nDividableRmLen+1:end,:), concatBlockLen, size( rm, 2 ) * obj.nConcatBlocks );
            rmn = zeros( size( rm, 1 ), 0 );
            for ii = 1 : obj.nConcatBlocks
                rmn = [rmn rm(:,ii:obj.nConcatBlocks:end)];
            end
            rm = rmn;
            x = lMomentAlongDim( rm, [1,2], 1, true );
            lenOneBlock = length( x ) / obj.nConcatBlocks;
            for ii = 2 : obj.nConcatBlocks
                x = [x, x((ii-1)*lenOneBlock+1:ii*lenOneBlock) - x((ii-2)*lenOneBlock+1:(ii-1)*lenOneBlock)];
            end
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.freqChannels = obj.freqChannels;
            outputDeps.nConcatBlocks = obj.nConcatBlocks;
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

