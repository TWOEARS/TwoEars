classdef IdentTrainPipeDataElem < handle
    
    %% -----------------------------------------------------------------------------------
    properties
        fileName;
        x;
        y;
        bIdxs;
        bacfIdxs;
        blockAnnotsCacheFile;
        fileAnnotations = struct;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        %% Constructor
        function obj = IdentTrainPipeDataElem( fileName )
            if exist( 'fileName', 'var' ), obj.fileName = fileName; end
        end
        %% -------------------------------------------------------------------------------
        
        function set.fileName( obj, fileName )
            obj.fileName = fileName;
            obj.readFileAnnotations();
        end
        %% -------------------------------------------------------------------------------

        function fa = getFileAnnotation( obj, aLabel )
            if isfield( obj.fileAnnotations, aLabel )
                fa = obj.fileAnnotations.(aLabel);
            else
                fa = [];
            end
        end
        %% -------------------------------------------------------------------------------
        
        function readFileAnnotations( obj )
            obj.fileAnnotations.type = IdEvalFrame.readEventClass( obj.fileName );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
end