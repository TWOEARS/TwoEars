classdef GatherFeaturesProc < handle
    %% 
    %
    
    %% --------------------------------------------------------------------
    properties (Access = protected, Transient)
        data;
        inputFileNameBuilder;
        confDataUseRatio = 1;
        prioClass = [];
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

        function setConfDataUseRatio( obj, confDataUseRatio, prioClass )
            obj.confDataUseRatio = confDataUseRatio;
            if nargin < 3, prioClass = []; end
            obj.prioClass = prioClass;
        end
        %% ----------------------------------------------------------------

        function connectToOutputFrom( obj, outputtingProc )
            if ~isa( outputtingProc, 'core.DataPipeProc' )
                error( 'outputtingProc must be of type core.DataPipeProc' );
            end
            obj.inputFileNameBuilder = outputtingProc.getOutputFileNameBuilder();
        end
        %% ----------------------------------------------------------------

        function run( obj )
            fprintf( '\nRunning: GatherFeaturesProc\n==========================================\n' );
            for dataFile = obj.data(:)'
                fprintf( '.%s ', dataFile.wavFileName );
                inFileName = obj.inputFileNameBuilder( dataFile.wavFileName );
                in = load( inFileName, 'singleConfFiles' );
                dataFile.x = [];
                dataFile.y = [];
                for ii = 1 : numel( in.singleConfFiles )
                    try
                        xy = load( in.singleConfFiles{ii} );
                    catch err
                        if strcmp( err.identifier, 'MATLAB:load:couldNotReadFile' )
                            fprintf( '\n%s seems corrupt.\nDelete and rerun pipe.\n', ...
                                inFileName );
                        end
                        rethrow( err );
                    end
                    if obj.confDataUseRatio < 1  &&  ...
                       ~strcmp( obj.prioClass, ...
                                IdEvalFrame.readEventClass( dataFile.wavFileName ) )
                        nUsePoints = round( numel( xy.y ) * obj.confDataUseRatio );
                        useIdxs = randperm( numel( xy.y ) );
                        useIdxs(nUsePoints+1:end) = [];
                    else
                        useIdxs = 1 : numel( xy.y );
                    end
                    dataFile.x = [dataFile.x; xy.x(useIdxs,:)];
                    dataFile.y = [dataFile.y; xy.y(useIdxs)];
                    fprintf( '.' );
                end
                fprintf( ';\n' );
            end
            fprintf( ';\n' );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end

