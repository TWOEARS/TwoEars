classdef MultiConfigurationsEarSignalProc < IdProcInterface
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        sceneConfigurations;
        binauralSim;
        singleConfFiles;
        singleConfs;
        outputWavFileName;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiConfigurationsEarSignalProc( binauralSim )
            obj = obj@IdProcInterface();
            if ~isa( binauralSim, 'BinSimProcInterface' )
                error( 'binauralSim must implement BinSimProcInterface.' );
            end
            obj.binauralSim = binauralSim;
            obj.sceneConfigurations = SceneConfiguration.empty;
        end
        %% ----------------------------------------------------------------
        
        function setSceneConfig( obj, sceneConfig )
            obj.sceneConfigurations = sceneConfig;
        end
        %% ----------------------------------------------------------------

        function process( obj, inputFileName )
            obj.makeEarsignalsAndLabels( inputFileName );
            obj.outputWavFileName = inputFileName;
        end
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            for ii = 1 : length( obj.sceneConfigurations )
                outDepName = sprintf( 'sceneConfig%d', ii );
                obj.binauralSim.setSceneConfig( obj.sceneConfigurations(ii) );
                outputDeps.(outDepName) = obj.binauralSim.getInternOutputDependencies;
            end
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out.singleConfFiles = obj.singleConfFiles;
            out.singleConfs = obj.singleConfs;
            out.wavFileName = obj.outputWavFileName;
        end
        %% ----------------------------------------------------------------
        
        function makeEarsignalsAndLabels( obj, wavFileName )
            obj.singleConfFiles = {};
            obj.singleConfs = [];
            for ii = 1 : numel( obj.sceneConfigurations )
                sceneConf = obj.sceneConfigurations(ii);
                obj.binauralSim.setSceneConfig( sceneConf );
                if ~obj.binauralSim.hasFileAlreadyBeenProcessed( wavFileName )
                    obj.binauralSim.process( wavFileName );
                    obj.binauralSim.saveOutput( wavFileName );
                end
                obj.singleConfFiles{ii} = obj.binauralSim.getOutputFileName( wavFileName );
                obj.singleConfs{ii} = obj.binauralSim.getInternOutputDependencies;
                fprintf( '.' );
            end
            fprintf( '\n' );
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end
