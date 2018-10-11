classdef FullFileBlockCreator < BlockCreators.Base
    % 
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = FullFileBlockCreator()
            obj = obj@BlockCreators.Base( inf, 0 );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods (Access = protected)
        
        function outputDeps = getBlockCreatorInternOutputDependencies( obj )
            outputDeps.v = 1;
        end
        %% ------------------------------------------------------------------------------- 

        function [blockAnnots,afeBlocks] = blockify( obj, afeData, annotations )
            currentDependencies = obj.getOutputDependencies();
            sceneConfig = currentDependencies.preceding.preceding.sceneCfg;
            annotations = BlockCreators.StandardBlockCreator.extendAnnotations( ...
                                                               sceneConfig, annotations );
            anyAFEsignal = afeData(1);
            if isa( anyAFEsignal, 'cell' ), anyAFEsignal = anyAFEsignal{1}; end;
            streamLen_s = double( size( anyAFEsignal.Data, 1 ) ) / anyAFEsignal.FsHz;
            if nargout > 1
                afeBlocks = {afeData};
            end
            blockAnnots = annotations;
            blockAnnots.blockOnset = 0;
            blockAnnots.blockOffset = streamLen_s;
        end
        %% ------------------------------------------------------------------------------- 
    
    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        %% ------------------------------------------------------------------------------- 
        %% ------------------------------------------------------------------------------- 
        
    end
    
end

        

