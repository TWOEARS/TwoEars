classdef DataPipeProc < handle
    %% identification training data creation pipeline processor
    %
    
    %% --------------------------------------------------------------------
    properties (Access = protected, Transient)
        data;
        inputFileNameBuilder;
        dataFileProcessor;
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = DataPipeProc( dataFileProc )
            if ~isa( dataFileProc, 'core.IdProcInterface' )
                error( 'dataFileProc must be of type core.IdProcInterface.' );
            end
            obj.dataFileProcessor = dataFileProc;
            obj.inputFileNameBuilder = @(inFileName)(inFileName);
        end
        %% ----------------------------------------------------------------

        function connectData( obj, data )
            obj.data = data;
        end
        %% ----------------------------------------------------------------

        function connectToOutputFrom( obj, outputtingProc )
            if ~isa( outputtingProc, 'core.DataPipeProc' )
                error( 'outputtingProc must be of type core.DataPipeProc' );
            end
            obj.inputFileNameBuilder = outputtingProc.getOutputFileNameBuilder();
            obj.dataFileProcessor.setExternOutputDependencies( ...
                outputtingProc.getOutputDependencies() );
        end
        %% ----------------------------------------------------------------

        function outFileNameBuilder = getOutputFileNameBuilder( obj )
            outFileNameBuilder = @(inFileName)(obj.dataFileProcessor.getOutputFileName( inFileName ));
        end
        %% ----------------------------------------------------------------

        function outDeps = getOutputDependencies( obj )
            outDeps = obj.dataFileProcessor.getOutputDependencies();
        end
        %% ----------------------------------------------------------------

        function run( obj )
            fprintf( '\nRunning: %s\n==========================================\n',...
                obj.dataFileProcessor.procName );
            for dataFile = obj.data(:)'
                fprintf( '.%s\n', dataFile.wavFileName );
                if ~obj.dataFileProcessor.hasFileAlreadyBeenProcessed( dataFile.wavFileName )
                    inputFileName = obj.inputFileNameBuilder( dataFile.wavFileName );
                    obj.dataFileProcessor.process( inputFileName );
                    obj.dataFileProcessor.saveOutput( dataFile.wavFileName );
                end
            end
            fprintf( ';\n' );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
        
    end
    
end

