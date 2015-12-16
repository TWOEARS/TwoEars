classdef MultiConfigurationsEarSignalProc < dataProcs.BinSimProcInterface
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        sceneConfigurations;
        sceneProc;
        singleScFiles;
        singleSCs;
        outputWavFileName;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiConfigurationsEarSignalProc( sceneProc )
            obj = obj@dataProcs.BinSimProcInterface();
            if ~isa( sceneProc, 'dataProcs.BinSimProcInterface' )
                error( 'sceneProc must implement dataProcs.BinSimProcInterface.' );
            end
            obj.sceneProc = sceneProc;
            obj.sceneConfigurations = sceneConfig.SceneConfiguration.empty;
        end
        %% ----------------------------------------------------------------
        
        function setSceneConfig( obj, sceneConfig )
            obj.configChanged = true;
            obj.sceneConfigurations = sceneConfig;
        end
        %% ----------------------------------------------------------------

        function fs = getDataFs( obj )
            fs = obj.sceneProc.getDataFs();
        end
        %% ----------------------------------------------------------------

        function process( obj, inputFileName )
            obj.makeEarsignalsAndLabels( inputFileName );
            obj.outputWavFileName = inputFileName;
        end
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            for ii = 1 : numel( obj.sceneConfigurations )
                outDepName = sprintf( 'sceneConfig%d', ii );
                obj.sceneProc.setSceneConfig( obj.sceneConfigurations(ii) );
                outputDeps.(outDepName) = obj.sceneProc.getInternOutputDependencies;
            end
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out.singleScFiles = obj.singleScFiles;
            out.singleSCs = obj.singleSCs;
            out.wavFileName = obj.outputWavFileName;
        end
        %% ----------------------------------------------------------------
        
        function makeEarsignalsAndLabels( obj, wavFileName )
            obj.singleScFiles = {};
            obj.singleSCs = [];
            for ii = 1 : numel( obj.sceneConfigurations )
                obj.sceneProc.setSceneConfig( obj.sceneConfigurations(ii) );
                if ~obj.sceneProc.hasFileAlreadyBeenProcessed( wavFileName )
                    obj.sceneProc.process( wavFileName );
                    obj.sceneProc.saveOutput( wavFileName );
                end
                obj.singleScFiles{ii} = obj.sceneProc.getOutputFileName( wavFileName );
                obj.singleSCs{ii} = obj.sceneProc.getInternOutputDependencies;
                fprintf( ';' );
            end
            fprintf( '\n' );
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
    end
    
end
