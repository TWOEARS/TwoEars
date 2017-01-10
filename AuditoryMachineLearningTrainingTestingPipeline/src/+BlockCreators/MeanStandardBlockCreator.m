classdef MeanStandardBlockCreator < BlockCreators.StandardBlockCreator
    % 
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = MeanStandardBlockCreator( blockSize_s, shiftSize_s, varargin )
            obj = obj@BlockCreators.StandardBlockCreator( blockSize_s, shiftSize_s );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods (Access = protected)
        
        function outputDeps = getBlockCreatorInternOutputDependencies( obj )
            outputDeps.sbc = getBlockCreatorInternOutputDependencies@...
                                                BlockCreators.StandardBlockCreator( obj );
            outputDeps.v = 1;
        end
        %% ------------------------------------------------------------------------------- 

        function [blockAnnots,afeBlocks] = blockify( obj, afeData, annotations )
            if nargout > 1
                [blockAnnots,afeBlocks] = blockify@BlockCreators.StandardBlockCreator( ...
                                                              obj, afeData, annotations );
            else
                blockAnnots = blockify@BlockCreators.StandardBlockCreator( ...
                                                              obj, afeData, annotations );
            end
            aFields = fieldnames( blockAnnots );
            isSequenceAnnotation = cellfun( @(af)(...
                                            isstruct( blockAnnots(1).(af) ) && ...
                                            isfield( blockAnnots(1).(af), 't' ) && ...
                                            ~isstruct( blockAnnots(1).(af).t ) ...
                                                                             ), aFields );
            sequenceAfields = aFields(isSequenceAnnotation);
            for ii = 1 : numel( blockAnnots )
                for jj = 1 : numel( sequenceAfields )
                    seqAname = sequenceAfields{jj};
                    annot = blockAnnots(ii).(seqAname);
                    if length( annot.t ) == size( annot.(seqAname), 1 )
                        if iscell( annot.(seqAname) )
                            blockAnnots(ii).(seqAname) = ...
                                       cellSqueezeFun( @mean, annot.(seqAname), 1, true );
                        else
                            blockAnnots(ii).(seqAname) = mean( annot.(seqAname), 1 );
                        end
                    else
                        error( 'unexpected annotations sequence structure' );
                    end
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        %% ------------------------------------------------------------------------------- 
        %% ------------------------------------------------------------------------------- 
        
    end
    
end

        

