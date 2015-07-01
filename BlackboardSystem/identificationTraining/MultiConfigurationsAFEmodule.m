classdef MultiConfigurationsAFEmodule < IdProcInterface
    
    %% --------------------------------------------------------------------
    properties (Access = private)
        afeProc;
        singleConfFiles;
        singleConfs;
        outputWavFileName;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiConfigurationsAFEmodule( afeProc )
            obj = obj@IdProcInterface();
            if ~isa( afeProc, 'IdProcInterface' )
                error( 'afeProc must implement IdProcInterface.' );
            end
            obj.afeProc = afeProc;
        end
        %% ----------------------------------------------------------------

        function process( obj, inputFileName )
            obj.makeAFEdata( inputFileName );
        end
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.afeDeps = obj.afeProc.getInternOutputDependencies;
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out.singleConfFiles = obj.singleConfFiles;
            out.singleConfs = obj.singleConfs;
            out.wavFileName = obj.outputWavFileName;
        end
        %% ----------------------------------------------------------------
        
        function makeAFEdata( obj, inFileName )
            in = load( inFileName );
            obj.outputWavFileName = in.wavFileName;
            obj.singleConfFiles = {};
            obj.singleConfs = [];
            for ii = 1 : numel( in.singleConfFiles )
                conf = in.singleConfs{ii};
                obj.afeProc.setExternOutputDependencies( conf );
                if ~obj.afeProc.hasFileAlreadyBeenProcessed( in.wavFileName )
                    obj.afeProc.process( in.singleConfFiles{ii} );
                    obj.afeProc.saveOutput( in.wavFileName );
                end
                obj.singleConfFiles{ii} = obj.afeProc.getOutputFileName( in.wavFileName );
                obj.singleConfs{ii} = obj.afeProc.getOutputDependencies;
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
