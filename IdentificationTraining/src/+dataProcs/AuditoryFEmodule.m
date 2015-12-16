classdef AuditoryFEmodule < core.IdProcInterface
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        managerObject;           % WP2 manager object - holds the signal buffer (data obj)
        afeDataObj;
        afeSignals;
        afeParams;
        output;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = AuditoryFEmodule( fs, afeRequests )
            obj = obj@core.IdProcInterface();
            obj.afeSignals = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
            obj.afeDataObj = dataObject( [], fs, 2, 2 );
            obj.managerObject = manager( obj.afeDataObj );
            for ii = 1:length( afeRequests )
                obj.afeSignals(ii) = obj.managerObject.addProcessor( ...
                    afeRequests{ii}.name, afeRequests{ii}.params );
                obj.afeParams.s(ii) = dataProcs.AuditoryFEmodule.signal2struct( ...
                    obj.afeSignals(ii) );
            end
            obj.afeParams.p = dataProcs.AuditoryFEmodule.parameterSummary2struct( ...
                obj.afeDataObj.getParameterSummary( obj.managerObject ) );
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
            outputDeps.afeParams = obj.afeParams;
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

    %% --------------------------------------------------------------------
    methods (Static)
       
        function s = signal2struct( sig )
            for ii = 1 : length( sig )
                sigschar = char(ii+96);
                if isa( sig{ii}, 'TimeFrequencySignal' )
                    s.(sigschar).cfHz = sig{ii}.cfHz;
                end
                if isa( sig{ii}, 'CorrelationSignal' )
                    s.(sigschar).cfHz = sig{ii}.cfHz;
                    s.(sigschar).lags = sig{ii}.lags;
                end
                if isa( sig{ii}, 'FeatureSignal' ) ...
                   || isa( sig{ii}, 'SpectralFeaturesSignal' )
                    s.(sigschar).flist = sig{ii}.fList;
                end
                if isa( sig{ii}, 'ModulationSignal' )
                    s.(sigschar).cfHz = sig{ii}.cfHz;
                    s.(sigschar).modCfHz = sig{ii}.modCfHz;
                end
                if isa( sig{ii}, 'Signal' )
                    s.(sigschar).name = sig{ii}.Name;
                    s.(sigschar).dim = sig{ii}.Dimensions;
                    s.(sigschar).fsHz = sig{ii}.FsHz;
                end
            end
        end
        %% ----------------------------------------------------------------
        
        function s = parameterSummary2struct( p )
            fnames = fieldnames( p );
            for ii = 1 : length( fnames )
                pfn = p.(fnames{ii});
                if iscell( pfn )
                    for jj = 1 : length( pfn )
                        stmp(jj) = ...
                            dataProcs.AuditoryFEmodule.parameter2struct( pfn{jj} );
                    end
                    s.(fnames{ii}) = stmp;
                    clear stmp;
                elseif isa( pfn, 'Parameters' )
                    s.(fnames{ii}) = ...
                        dataProcs.AuditoryFEmodule.parameter2struct( pfn );
                end
            end
        end
        %% ----------------------------------------------------------------
        
        function s = parameter2struct( p )
            k = p.map.keys;
            v = p.map.values;
            for ii = 1 : p.map.Count
                s.(k{ii}) = v{ii};
            end
        end
        %% ----------------------------------------------------------------
        
    end
    
end
