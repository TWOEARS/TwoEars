classdef MultiConfigurationsFeatureProc < core.IdProcInterface
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        featProc;
        singleConfFiles;
        singleConfs;
        outputWavFileName;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiConfigurationsFeatureProc( featProc )
            obj = obj@core.IdProcInterface();
            if ~isa( featProc, 'core.IdProcInterface' )
                error( 'featProc must implement core.IdProcInterface.' );
            end
            obj.featProc = featProc;
        end
        %% ----------------------------------------------------------------

        function process( obj, inputFileName )
            obj.makeFeatures( inputFileName );
        end
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.featDeps = obj.featProc.getInternOutputDependencies;
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out.singleConfFiles = obj.singleConfFiles;
            out.singleConfs = obj.singleConfs;
            out.wavFileName = obj.outputWavFileName;
        end
        %% ----------------------------------------------------------------
        
        function makeFeatures( obj, inFileName )
            in = load( inFileName );
            obj.outputWavFileName = in.wavFileName;
            obj.singleConfFiles = {};
            obj.singleConfs = [];
            for ii = 1 : numel( in.singleConfFiles )
                conf = in.singleConfs{ii};
                obj.featProc.setExternOutputDependencies( conf );
                if ~obj.featProc.hasFileAlreadyBeenProcessed( in.wavFileName )
                    if ~exist( in.singleConfFiles{ii}, 'file' )
                        error( '%s not found. \n%s corrupt -- delete and restart.', ...
                            in.singleConfFiles{ii}, inFileName );
                    end
                    obj.featProc.process( in.singleConfFiles{ii} );
                    obj.featProc.saveOutput( in.wavFileName );
                end
                obj.singleConfFiles{ii} = obj.featProc.getOutputFileName( in.wavFileName );
                obj.singleConfs{ii} = obj.featProc.getOutputDependencies;
                fprintf( ';' );
            end
            fprintf( '\n' );
        end
        %% ----------------------------------------------------------------
        
    end
    
end
