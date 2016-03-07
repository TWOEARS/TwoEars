classdef MultiConfigurationsFeatureProc < core.IdProcInterface
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        featProc;
        singleConfFiles;
        singleConfs;
        outputWavFileName;
        precollected;
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
            obj.precollected = containers.Map('KeyType','char','ValueType','any');
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
            [p,wavFileName,~] = fileparts( inFileName );
            [~,wavFileName,~] = fileparts( wavFileName );
            soundDir = fileparts( p );
            wavFileName = fullfile( soundDir, wavFileName );
            obj.outputWavFileName = wavFileName;
            precoll = [];
            if obj.precollected.isKey( wavFileName )
                precoll = obj.precollected(wavFileName);
            end
            obj.singleConfFiles = {};
            obj.singleConfs = [];
            multiCfg = obj.getOutputDependencies();
            scFieldNames = fieldnames( multiCfg.extern.extern );
            for ii = 1 : numel( scFieldNames )
                if ~isempty( precoll ) && isfield( precoll, scFieldNames{ii} )
                    obj.singleConfFiles{ii} = precoll.(scFieldNames{ii}).fname;
                    obj.singleConfs{ii} = precoll.(scFieldNames{ii}).cfg;
                else
                    conf = [];
                    conf.afeParams = multiCfg.extern.afeDeps.afeParams;
                    conf.extern = multiCfg.extern.extern.(scFieldNames{ii});
                    obj.featProc.setExternOutputDependencies( conf );
                    if ~obj.featProc.hasFileAlreadyBeenProcessed( wavFileName )
                        in = load( inFileName );
                        if ~exist( in.singleConfFiles{ii}, 'file' )
                            error( '%s not found. \n%s corrupt -- delete and restart.', ...
                                in.singleConfFiles{ii}, inFileName );
                        end
                        obj.featProc.process( in.singleConfFiles{ii} );
                        obj.featProc.saveOutput( wavFileName );
                    end
                    obj.singleConfFiles{ii} = obj.featProc.getOutputFileName( wavFileName );
                    obj.singleConfs{ii} = obj.featProc.getOutputDependencies;
                end
                fprintf( ';' );
            end
            fprintf( '\n' );
        end
        %% ----------------------------------------------------------------
        
        function precProcFileNeeded = needsPrecedingProcResult( obj, wavFileName )
            precProcFileNeeded = false; 
            multiCfg = obj.getOutputDependencies();
            precoll = [];
            scFieldNames = fieldnames( multiCfg.extern.extern );
            fprintf( '#' );
            for ii = 1 : numel( scFieldNames )
                conf = [];
                conf.afeParams = multiCfg.extern.afeDeps.afeParams;
                conf.extern = multiCfg.extern.extern.(scFieldNames{ii});
                obj.featProc.setExternOutputDependencies( conf );
                if ~obj.featProc.hasFileAlreadyBeenProcessed( wavFileName )
                    precProcFileNeeded = true;
                    break;
                end
                precoll.(scFieldNames{ii}).fname = obj.featProc.getOutputFileName( wavFileName );
                precoll.(scFieldNames{ii}).cfg = obj.featProc.getOutputDependencies;
                fprintf( '.' );
            end
            obj.precollected(wavFileName) = precoll;
            fprintf( '\n' );
        end
        %% -----------------------------------------------------------------
        
    end
    
end
