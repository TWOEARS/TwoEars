classdef AuditoryFEmodule < IdProcInterface
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        managerObject;           % WP2 manager object - holds the signal buffer (data obj)
        afeDataObj;
        afeSignals;
        output;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = AuditoryFEmodule( fs, afeRequests )
            obj = obj@IdProcInterface();
            obj.afeSignals = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
            obj.afeDataObj = dataObject( [], fs, 2, 2 );
            obj.managerObject = manager( obj.afeDataObj );
            for ii = 1:length( afeRequests )
                obj.afeSignals(ii) = obj.managerObject.addProcessor( ...
                    afeRequests{ii}.name, afeRequests{ii}.params );
            end
        end
        %% ----------------------------------------------------------------
        
        function process( obj, inputFileName )
            in = load( inputFileName );
            obj.output.afeData = obj.makeAFEdata( in.earSout );
            obj.output.onOffsOut = in.onOffsOut;
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.afeParams = obj.afeDataObj.getParameterSummary( obj.managerObject );
            outputDeps.reqSignals = obj.afeSignals.keys;
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out = obj.output;
        end
        %% ----------------------------------------------------------------

        function afeData = makeAFEdata( obj, earSignals )
            obj.managerObject.reset();
            obj.afeDataObj.clearData();
            fs = obj.afeDataObj.time{1,1}.FsHz;
            for outputSig = obj.afeSignals.values
                for kk = 1:numel( outputSig{1} )
                    if isa( outputSig{1}, 'cell' )
                        os = outputSig{1}{kk};
                    else
                        os = outputSig{1}(kk);
                    end
                    os.setBufferSize( ceil( length( earSignals ) / fs ) );
                end
            end
            % process chunks of 1 second
            for chunkBegin = 1:fs:length(earSignals)
                chunkEnd = min( length( earSignals ), chunkBegin + fs - 1 );
                obj.managerObject.processChunk( earSignals(chunkBegin:chunkEnd,:), 1 );
                fprintf( '.' );
            end
            afeData = obj.afeSignals;
            fprintf( '\n' );
        end
        %% ----------------------------------------------------------------
        
    end
    
end
