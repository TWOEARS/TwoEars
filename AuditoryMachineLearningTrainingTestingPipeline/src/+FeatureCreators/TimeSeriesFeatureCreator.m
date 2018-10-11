classdef TimeSeriesFeatureCreator < FeatureCreators.Base

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        targetFsHz;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        outputDeps = getTSfeatureInternOutputDependencies( obj )
        x = constructTSvector( obj ) % has to return a cell, first item the feature vector, 
                                     % second item the features description.
    end

    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = TimeSeriesFeatureCreator( targetFsHz )
            obj = obj@FeatureCreators.Base();
            obj.targetFsHz = targetFsHz;
        end
        %% ----------------------------------------------------------------

        function x = constructVector( obj )
            x = obj.constructTSvector();
            T = size( x{1}, 1 );
            bas = obj.blockAnnotations;
            aFields = fieldnames( bas );
            isSequenceAnnotation = cellfun( @(af)(...
                                      isstruct( bas.(af) ) && isfield( bas.(af), 't' ) ...
                                                                             ), aFields );
            sequenceAfields = aFields(isSequenceAnnotation);
            for jj = 1 : numel( sequenceAfields )
                fprintf( '.' );
                seqAname = sequenceAfields{jj};
                annot = bas.(seqAname);
                if ~isstruct( annot.t ) % time series
                    if length( annot.t ) == size( annot.(seqAname), 1 )
                        if iscell( annot.(seqAname) )
                            asc_sz = size( annot.(seqAname) );
                            asc_num = cell2mat( annot.(seqAname) );
                            asc_num = interp1( annot.t, asc_num, (1:T)'/obj.targetFsHz, 'pchip' );
                            annot.(seqAname) = mat2cell( asc_num, ones( 1, size( asc_num, 1 ) ), repmat( size( asc_num, 2 )/asc_sz(2), 1, asc_sz(2) ) );
                        else
                            annot.(seqAname) = interp1( annot.t, annot.(seqAname), (1:T)/obj.targetFsHz, 'pchip' );
                        end
                        annot.t = 1:T;
                    else
                        error( 'unexpected annotations sequence structure' );
                    end
                elseif all( isfield( annot.t, {'onset','offset'} ) ) % event series
                    if isequal( size( annot.t.onset ), size( annot.t.offset ) ) && ...
                       length( annot.t.onset ) == size( annot.(seqAname), 1 )
                        annot.t.onset = round( annot.t.onset * obj.targetFsHz );
                        annot.t.onset = min( [annot.t.onset;repmat( T, size( annot.t.onset ) )], [], 1 );
                        annot.t.offset = round( annot.t.offset * obj.targetFsHz );
                        annot.t.offset = min( [annot.t.offset;repmat( T, size( annot.t.offset ) )], [], 1 );
                    else
                        error( 'unexpected annotations sequence structure' );
                    end
                else
                    error( 'unexpected annotations sequence structure' );
                end
                bas.(seqAname) = annot;
            end
            obj.blockAnnotations = bas;
            fprintf( ';' );
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.tsFeatureProc = obj.getTSfeatureInternOutputDependencies();
            outputDeps.targetFsHz = obj.targetFsHz;
            outputDeps.v = 1;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    
        function dataBlockResampled = resampleDataBlock( dataBlock, srcFsHz, targetFsHz, targetNt )
            [nT, ~] = size(dataBlock);
            srcTs = 0 : 1 / srcFsHz : (nT-1) / srcFsHz;
            targetTs = 0 : 1 / targetFsHz : srcTs(end);
            nTargetTsMissing = targetNt - numel( targetTs );
            % pchip interpolation...
            dataBlockResampled = interp1( srcTs, dataBlock, targetTs, 'pchip' );
            % ...with 'last-datapoint' extrapolation.
            dataBlockResampled(end+1:end+nTargetTsMissing,:) = ...
                                 repmat( dataBlockResampled(end,:), nTargetTsMissing, 1 );
        end
            
    end
    
end

