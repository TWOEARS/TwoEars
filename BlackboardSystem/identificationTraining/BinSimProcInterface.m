classdef (Abstract) BinSimProcInterface < IdProcInterface

    %% --------------------------------------------------------------------
    properties (Access = protected)
        earSout;
        onOffsOut;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = BinSimProcInterface()
            obj = obj@IdProcInterface();
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)

        function out = getOutput( obj )
            out.earSout = obj.earSout;
            out.onOffsOut = obj.onOffsOut;
        end
        %% ----------------------------------------------------------------
       
    end
    %% --------------------------------------------------------------------
    methods (Abstract)
        fs = getDataFs( obj )
        setSceneConfig( obj, sceneConfig )
    end
    
end