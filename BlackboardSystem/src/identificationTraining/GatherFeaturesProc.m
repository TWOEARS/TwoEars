classdef GatherFeaturesProc < handle
    %% 
    %
    
    %% --------------------------------------------------------------------
    properties (Access = protected, Transient)
        data;
        inputFileNameBuilder;
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = GatherFeaturesProc()
            obj.inputFileNameBuilder = @(inFileName)(inFileName);
        end
        %% ----------------------------------------------------------------

        function connectData( obj, data )
            obj.data = data;
        end
        %% ----------------------------------------------------------------

        function connectToOutputFrom( obj, outputtingProc )
            if ~isa( outputtingProc, 'DataPipeProc' )
                error( 'outputtingProc must be of type DataPipeProc' );
            end
            obj.inputFileNameBuilder = outputtingProc.getOutputFileNameBuilder();
        end
        %% ----------------------------------------------------------------

        function run( obj )
            fprintf( '\nRunning: GatherFeaturesProc\n==========================================\n' );
            for dataFile = obj.data(:)'
                fprintf( '.%s\n', dataFile.wavFileName );
                xyFileName = obj.inputFileNameBuilder( dataFile.wavFileName );
                xy = load( xyFileName );
                dataFile.x = xy.x;
                dataFile.y = xy.y;
            end
            fprintf( ';\n' );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end

