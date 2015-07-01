classdef MultiConfigurationsFeatureProc < IdProcInterface
    
    %% --------------------------------------------------------------------
    properties (Access = private)
        featProc;
        x;
        y;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiConfigurationsFeatureProc( featProc )
            obj = obj@IdProcInterface();
            if ~isa( featProc, 'IdProcInterface' )
                error( 'featProc must implement IdProcInterface.' );
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
            out.x = obj.x;
            out.y = obj.y;
        end
        %% ----------------------------------------------------------------
        
        function makeFeatures( obj, inFileName )
            in = load( inFileName );
            obj.x = [];
            obj.y = [];
            for ii = 1 : numel( in.singleConfFiles )
                conf = in.singleConfs{ii};
                obj.featProc.setExternOutputDependencies( conf );
                if ~obj.featProc.hasFileAlreadyBeenProcessed( in.wavFileName )
                    obj.featProc.process( in.singleConfFiles{ii} );
                    xy = obj.featProc.saveOutput( in.wavFileName );
                else
                    xy = load( obj.featProc.getOutputFileName( in.wavFileName ) );
                end
                obj.x = [obj.x; xy.x];
                obj.y = [obj.y; xy.y];
                fprintf( '.' );
            end
            fprintf( '\n' );
        end
        %% ----------------------------------------------------------------
        
    end
    
end
