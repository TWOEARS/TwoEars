classdef DataPipeProc < handle
    %% identification training data creation pipeline processor
    %
    
    %% --------------------------------------------------------------------
    properties (Access = protected, Transient)
        data;
    end
    properties (SetAccess = protected, Transient)
        dataFileProcessor;
        inputFileNameBuilder;
        fileListOverlay;
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

        function init( obj )
            obj.dataFileProcessor.init();
        end
        %% ----------------------------------------------------------------

        function connectData( obj, data )
            obj.data = data;
            obj.fileListOverlay = logical( ones( 1, length( obj.data(:) ) ) );
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

        function checkDataFiles( obj, otherOverlay )
            fprintf( '\nChecking file list: %s\n==========================================\n',...
                obj.dataFileProcessor.procName );
            if (nargin > 1) && ~isempty( otherOverlay ) && (length( otherOverlay ) == length( obj.data(:) ))
                obj.fileListOverlay = otherOverlay;
            else
                obj.fileListOverlay = logical( ones( 1, length( obj.data(:) ) ) );
            end
            data = obj.data(:)';
            for ii = 1 : length( data )
                if ~obj.fileListOverlay(ii), continue; end
                dataFile = data(ii);
                fprintf( '.%s\n', dataFile.wavFileName );
                obj.fileListOverlay(ii) = ...
                    ~obj.dataFileProcessor.hasFileAlreadyBeenProcessed( dataFile.wavFileName, true );
            end
            fprintf( '..' );
            obj.dataFileProcessor.savePreloadedConfigs();
            fprintf( ';\n' );
        end
        %% ----------------------------------------------------------------

        function run( obj )
            fprintf( '\nRunning: %s\n==========================================\n',...
                obj.dataFileProcessor.procName );
            data = obj.data(:);
            data = data(obj.fileListOverlay);
            for dataFile = data(randperm(length(data)))'
                fprintf( '.%s\n', dataFile.wavFileName );
                if ~obj.dataFileProcessor.hasFileAlreadyBeenProcessed( dataFile.wavFileName )
                    inputFileName = obj.inputFileNameBuilder( dataFile.wavFileName );
                    obj.dataFileProcessor.process( inputFileName );
                    obj.dataFileProcessor.saveOutput( dataFile.wavFileName );
                end
            end
            fprintf( '..' );
            obj.dataFileProcessor.savePreloadedConfigs();
            fprintf( ';\n' );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
        
    end
    
end

