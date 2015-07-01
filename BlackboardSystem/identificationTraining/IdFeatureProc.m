classdef IdFeatureProc < IdProcInterface

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        shiftSize_s;
        minBlockToEventRatio;
        x;
        y;
        blockSize_s;
        labelBlockSize_s;
    end
    
    %% --------------------------------------------------------------------
    methods (Abstract)
        afeRequests = getAFErequests( obj )
        outputDeps = getFeatureInternOutputDependencies( obj )
        x = makeDataPoint( obj, afeData )
    end

    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdFeatureProc( blockSize_s, shiftsize_s, minBlockToEventRatio, labelBlockSize_s )
            obj = obj@IdProcInterface();
            obj.blockSize_s = blockSize_s;
            obj.shiftSize_s = shiftsize_s;
            obj.minBlockToEventRatio = minBlockToEventRatio;
            obj.labelBlockSize_s = labelBlockSize_s;
        end
        %% ----------------------------------------------------------------
        
        function process( obj, inputFileName )
            in = load( inputFileName );
            [afeBlocks, obj.y] = obj.blockifyAndLabel( in.afeData, in.onOffsOut );
            obj.x = [];
            for afeBlock = afeBlocks
                obj.x(end+1,:) = obj.makeDataPoint( afeBlock{1} );
                fprintf( '.' );
            end
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.blockSize = obj.blockSize_s;
            outputDeps.labelBlockSize = obj.labelBlockSize_s;
            outputDeps.shiftSize = obj.shiftSize_s;
            outputDeps.minBlockEventRatio = obj.minBlockToEventRatio;
            outputDeps.featureProc = obj.getFeatureInternOutputDependencies();
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out.x = obj.x;
            out.y = obj.y;
        end
        %% ----------------------------------------------------------------

        function afeBlock = cutDataBlock( obj, afeData, backOffset_s )
            afeBlock = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
            for afeKey = afeData.keys
                afeSignal = afeData(afeKey{1});
                if isa( afeSignal, 'cell' )
                    afeSignalExtract{1} = afeSignal{1}.cutSignalCopy( obj.blockSize_s, backOffset_s );
                    afeSignalExtract{1}.reduceBufferToArray();
                    afeSignalExtract{2} = afeSignal{2}.cutSignalCopy( obj.blockSize_s, backOffset_s );
                    afeSignalExtract{2}.reduceBufferToArray();
                else
                    afeSignalExtract = afeSignal.cutSignalCopy( obj.blockSize_s, backOffset_s );
                    afeSignalExtract.reduceBufferToArray();
                end
                afeBlock(afeKey{1}) = afeSignalExtract;
                fprintf( '.' );
            end
        end
        %% ----------------------------------------------------------------


        function [afeBlocks, y] = blockifyAndLabel( obj, afeData, onOffs_s )
            afeBlocks = {};
            y = [];
            afeDataNames = afeData.keys;
            anyAFEsignal = afeData(afeDataNames{1});
            if isa( anyAFEsignal, 'cell' ), anyAFEsignal = anyAFEsignal{1}; end;
            sigLen = double( length( anyAFEsignal.Data ) ) / anyAFEsignal.FsHz;
            for backOffset_s = 0.0 : obj.shiftSize_s : sigLen - obj.shiftSize_s
                afeBlocks{end+1} = obj.cutDataBlock( afeData, backOffset_s );
                blockOffset = sigLen - backOffset_s;
                labelBlockOnset = blockOffset - obj.labelBlockSize_s;
                y(end+1) = 0;
                for jj = 1 : size( onOffs_s, 1 )
                    eventOnset = onOffs_s(jj,1);
                    eventOffset = onOffs_s(jj,2);
                    eventBlockOverlapLen = ...
                        min( blockOffset, eventOffset ) - ...
                        max( labelBlockOnset, eventOnset );
                    eventLength = eventOffset - eventOnset;
                    maxBlockEventLen = min( obj.labelBlockSize_s, eventLength );
                    relEventBlockOverlap = eventBlockOverlapLen / maxBlockEventLen;
                    blockIsSoundEvent = relEventBlockOverlap > obj.minBlockToEventRatio;
                    y(end) = y(end) || blockIsSoundEvent;
                    if y(end) == 1, break, end;
                end
            end
            afeBlocks = fliplr( afeBlocks );
            y = fliplr( y );
            y = y';
            %scaling to [-1..1]
            y = (y * 2) - 1;
        end
        %% ----------------------------------------------------------------
        
    end
    
end

        

